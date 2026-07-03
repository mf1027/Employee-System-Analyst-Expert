#!/usr/bin/env python3
"""
generate-board-xlsx.py — Task-board xlsx report generator (GENERAL-PURPOSE).

Reads a project's board.md (the canonical tracker managed by the `task-board` skill)
plus its user-level QA test plans, and emits a timestamped 4-sheet workbook:
    Dashboard · BE · FE · QA
into the project's deliverables/reports/.

Conventions (spec: ai-sa-employee/skills/task-board.md → "xlsx report"):
  - Plain sheets — NO Excel table objects, NO autofilter, NO cell borders.
  - Manual date columns (Start Date, Actual End / Planned, Executed) are true
    date-typed cells with date Data Validation (calendar picker appears in
    Excel-web / Google Sheets; desktop Excel enforces valid dates).
  - End Date  = WORKDAY(Start, Days, Holidays)   — skips weekends + holiday list.
  - Days      = VLOOKUP(Est, Dashboard config)   — S/M/L mapping editable in ONE place.
  - Variance  = NETWORKDAYS(planned End, Actual) − 1 — red when late.
  - Status dropdown with monday-style color fills; overdue rows highlighted.
  - Workbook recalculates on open (fullCalcOnLoad).
  - The xlsx is ALWAYS a snapshot of the confirmed board — never a source of truth.

Usage:
    python3 scripts/generate-board-xlsx.py --project memory/clients/myps/myps-system
    python3 scripts/generate-board-xlsx.py --project <dir> --out custom-name.xlsx
"""
import argparse
import os
import re
import sys
from datetime import datetime

from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment
from openpyxl.worksheet.datavalidation import DataValidation
from openpyxl.formatting.rule import CellIsRule, FormulaRule

# ─── constants ──────────────────────────────────────────────────────────────
STATUSES = ["Backlog", "To Do", "In Progress", "In Review", "QA", "Blocked", "Done"]
STATUS_FILL = {"Backlog": "D9D9D9", "To Do": "BDD7EE", "In Progress": "F4B183",
               "In Review": "C9A0DC", "QA": "FFF2CC", "Blocked": "FF9999", "Done": "C6EFCE"}
QA_RESULTS = ["Pass", "Fail", "Blocked", "Pass-with-issue"]
EST_DAYS = [("S", 1), ("M", 2), ("L", 5)]
# Edit on the Dashboard sheet after generation if the holiday set changes.
HOLIDAYS = ["2026-08-21", "2026-08-31", "2026-11-30", "2026-12-08", "2026-12-25", "2026-12-30"]
# Dashboard config anchors (formulas on BE/FE reference these fixed addresses)
CFG_EST = "Dashboard!$M$2:$N$4"
CFG_HOL = "Dashboard!$M$8:$M$20"

HDR_FILL = PatternFill("solid", fgColor="1F4E78")
HDR_FONT = Font(bold=True, color="FFFFFF", size=10)
BODY_FONT = Font(size=10)
SEC_FONT = Font(bold=True, size=11, color="1F4E78")

TASK_HEADERS = ["Task ID", "Parent Card", "Module", "Task", "Est", "Days", "Start Date",
                "End Date", "Actual End", "Variance", "Status", "Sprint", "Depends On",
                "Priority", "Assignee", "Spec Link", "Notes"]
QA_HEADERS = ["TC ID", "Module", "Area", "Steps", "Expected", "Planned Date",
              "Executed Date", "Result", "Severity", "Tester", "Bug Ref", "Notes"]

# ─── board.md parsing ───────────────────────────────────────────────────────
RE_EPIC = re.compile(r"^## Epic: (.+?) \((DEV-[^)]*)\)(.*)$")
RE_CARD = re.compile(r"^### (DEV-\d+) · (.*?) — `([^`]+)` · (P\d) · ([SML])\s*$")
RE_SUB = re.compile(r"^- \[( |x)\] ([A-Z]+-[\d.]+) \(([SML])\) (.*)$")
RE_SPRINT_ROW = re.compile(r"^\| (S\d+|[^|]+?) \| ([^|]*) \| ([^|]*) \| ([^|]*) \|$")


def parse_board(path):
    text = open(path, encoding="utf-8").read()
    board = {"title": "", "sprints": [], "epics": []}
    m = re.search(r"^# Board — (.+)$", text, re.M)
    board["title"] = m.group(1).strip() if m else os.path.basename(os.path.dirname(path))

    epic = card = None
    in_sprints = False
    for line in text.splitlines():
        if line.startswith("## Sprints"):
            in_sprints = True
            continue
        if line.startswith("## ") and not line.startswith("## Sprints"):
            in_sprints = False
        if in_sprints:
            sm = RE_SPRINT_ROW.match(line.strip())
            if sm and sm.group(1).strip() not in ("Sprint", "---", ""):
                cells = [c.strip() for c in sm.groups()]
                if not set(cells[0]) <= set("-—: "):
                    board["sprints"].append(cells)
            continue

        em = RE_EPIC.match(line)
        if em:
            epic = {"name": em.group(1).strip(), "range": em.group(2).strip(),
                    "flags": em.group(3).strip(), "cards": []}
            board["epics"].append(epic)
            card = None
            continue
        cm = RE_CARD.match(line)
        if cm and epic is not None:
            card = {"id": cm.group(1), "title": cm.group(2).strip(), "status": cm.group(3).strip(),
                    "priority": cm.group(4), "est": cm.group(5),
                    "deps": "", "sprint": "", "assignee": "", "start": "", "spec": "",
                    "notes": "", "subs": []}
            epic["cards"].append(card)
            continue
        if card is not None and line.startswith("> "):
            extras = []
            for part in [p.strip() for p in line[2:].split(" · ")]:
                for key, field in (("Deps:", "deps"), ("Sprint:", "sprint"),
                                   ("Assignee:", "assignee"), ("Start:", "start"), ("Spec:", "spec")):
                    if part.startswith(key):
                        card[field] = part[len(key):].strip()
                        break
                else:
                    extras.append(part)
            if extras:
                card["notes"] = " · ".join(extras)
            continue
        sm = RE_SUB.match(line)
        if sm and card is not None:
            card["subs"].append({"done": sm.group(1) == "x", "id": sm.group(2),
                                 "disc": sm.group(2).split("-")[0], "est": sm.group(3),
                                 "title": sm.group(4).strip()})
    return board


# ─── QA plan parsing ────────────────────────────────────────────────────────
RE_TC = re.compile(r"^\| ([A-Z]{2,6}-[A-Z]*\d+[a-z]?) \|")


def module_from_qa_filename(fname):
    stem = os.path.basename(fname).replace("-qa-user-level-test-plan.md", "")
    return stem.replace("-module", "").replace("-", " ").title()


def parse_qa_plans(docs_dir):
    rows = []
    if not os.path.isdir(docs_dir):
        return rows
    for fname in sorted(os.listdir(docs_dir)):
        if not fname.endswith("-qa-user-level-test-plan.md"):
            continue
        module = module_from_qa_filename(fname)
        area = ""
        for line in open(os.path.join(docs_dir, fname), encoding="utf-8"):
            hm = re.match(r"^## AREA \d+ — (.+)$", line.strip())
            if hm:
                area = hm.group(1).strip()
                continue
            if RE_TC.match(line.strip()):
                cells = [c.strip() for c in line.strip().strip("|").split("|")]
                if len(cells) >= 4:
                    tc, steps, expected = cells[0], cells[1], cells[2]
                    sev = cells[-1] if len(cells) >= 5 else ""
                    rows.append({"tc": tc, "module": module, "area": area,
                                 "steps": steps, "expected": expected, "sev": sev})
    return rows


# ─── sheet builders ─────────────────────────────────────────────────────────
def style_header(ws, headers):
    for c, h in enumerate(headers, 1):
        cell = ws.cell(1, c, h)
        cell.fill, cell.font = HDR_FILL, HDR_FONT
        cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
    ws.row_dimensions[1].height = 26
    ws.freeze_panes = "A2"


def add_date_validation(ws, col_letters, last_row):
    dv = DataValidation(type="date", operator="between",
                        formula1="DATE(2026,1,1)", formula2="DATE(2031,12,31)",
                        allow_blank=True, showInputMessage=True, showErrorMessage=True,
                        promptTitle="Date", prompt="Enter a date (YYYY-MM-DD). Calendar picker in Excel web / Google Sheets.",
                        errorTitle="Invalid date", error="Enter a valid date between 2026 and 2031.")
    ws.add_data_validation(dv)
    for col in col_letters:
        dv.add(f"{col}2:{col}{last_row}")


def build_task_sheet(wb, name, rows):
    """rows: dicts — one per BE-/FE- sub-task."""
    ws = wb.create_sheet(name)
    style_header(ws, TASK_HEADERS)
    for r, t in enumerate(rows, start=2):
        ws.cell(r, 1, t["id"]); ws.cell(r, 2, t["parent"]); ws.cell(r, 3, t["module"])
        ws.cell(r, 4, t["title"]); ws.cell(r, 5, t["est"])
        ws.cell(r, 6).value = f'=IFERROR(VLOOKUP($E{r},{CFG_EST},2,FALSE),"")'
        ws.cell(r, 8).value = f'=IF(AND($G{r}<>"",$F{r}<>""),WORKDAY($G{r},$F{r},{CFG_HOL}),"")'
        ws.cell(r, 10).value = f'=IF(AND($I{r}<>"",$H{r}<>""),NETWORKDAYS($H{r},$I{r},{CFG_HOL})-1,"")'
        ws.cell(r, 11, t["status"]); ws.cell(r, 12, t["sprint"]); ws.cell(r, 13, t["deps"])
        ws.cell(r, 14, t["priority"]); ws.cell(r, 15, t["assignee"])
        ws.cell(r, 16, t["spec"]); ws.cell(r, 17, t["notes"])
        for c in range(1, 18):
            cell = ws.cell(r, c)
            cell.font = BODY_FONT
            cell.alignment = Alignment(vertical="center", wrap_text=(c in (2, 4, 16, 17)))
        for c in (7, 8, 9):
            ws.cell(r, c).number_format = "yyyy-mm-dd"
    n = max(len(rows) + 1, 2)
    add_date_validation(ws, ("G", "I"), n)                       # manual date columns
    dv = DataValidation(type="list", formula1='"%s"' % ",".join(STATUSES), allow_blank=True)
    ws.add_data_validation(dv); dv.add(f"K2:K{n}")
    for st, fill in STATUS_FILL.items():
        ws.conditional_formatting.add(f"K2:K{n}", CellIsRule(
            operator="equal", formula=[f'"{st}"'], fill=PatternFill("solid", fgColor=fill)))
    for pr, fill in {"P1": "FF9999", "P3": "D9D9D9"}.items():
        ws.conditional_formatting.add(f"N2:N{n}", CellIsRule(
            operator="equal", formula=[f'"{pr}"'], fill=PatternFill("solid", fgColor=fill)))
    ws.conditional_formatting.add(f"J2:J{n}", CellIsRule(
        operator="greaterThan", formula=["0"],
        fill=PatternFill("solid", fgColor="FF9999"), font=Font(color="9C0006", bold=True)))
    ws.conditional_formatting.add(f"A2:Q{n}", FormulaRule(
        formula=['AND($H2<>"",$H2<TODAY(),$K2<>"Done")'],
        fill=PatternFill("solid", fgColor="FFEB9C")))
    widths = {"A": 10, "B": 32, "C": 16, "D": 46, "E": 5, "F": 5, "G": 12, "H": 12, "I": 12,
              "J": 9, "K": 12, "L": 8, "M": 16, "N": 7, "O": 11, "P": 34, "Q": 24}
    for col, w in widths.items():
        ws.column_dimensions[col].width = w
    return ws


def build_qa_sheet(wb, rows):
    ws = wb.create_sheet("QA")
    style_header(ws, QA_HEADERS)
    for r, t in enumerate(rows, start=2):
        ws.cell(r, 1, t["tc"]); ws.cell(r, 2, t["module"]); ws.cell(r, 3, t["area"])
        ws.cell(r, 4, t["steps"]); ws.cell(r, 5, t["expected"]); ws.cell(r, 9, t["sev"])
        for c in range(1, 13):
            cell = ws.cell(r, c)
            cell.font = BODY_FONT
            cell.alignment = Alignment(vertical="center", wrap_text=(c in (3, 4, 5, 12)))
        for c in (6, 7):
            ws.cell(r, c).number_format = "yyyy-mm-dd"
    n = max(len(rows) + 1, 2)
    add_date_validation(ws, ("F", "G"), n)                       # Planned / Executed dates
    dv = DataValidation(type="list", formula1='"%s"' % ",".join(QA_RESULTS), allow_blank=True)
    ws.add_data_validation(dv); dv.add(f"H2:H{n}")
    for res, fill in {"Pass": "C6EFCE", "Fail": "FF9999", "Blocked": "D9D9D9",
                      "Pass-with-issue": "FFF2CC"}.items():
        ws.conditional_formatting.add(f"H2:H{n}", CellIsRule(
            operator="equal", formula=[f'"{res}"'], fill=PatternFill("solid", fgColor=fill)))
    widths = {"A": 11, "B": 18, "C": 26, "D": 52, "E": 46, "F": 12, "G": 12, "H": 14,
              "I": 8, "J": 11, "K": 10, "L": 26}
    for col, w in widths.items():
        ws.column_dimensions[col].width = w
    return ws


def build_dashboard(wb, board, task_rows, qa_count, src_path):
    ws = wb.active
    ws.title = "Dashboard"
    ws["A1"] = f"{board['title']} — Task Board Report"
    ws["A1"].font = Font(bold=True, size=14, color="1F4E78")
    ws["A2"] = f"Generated {datetime.now():%Y-%m-%d %H:%M} · source: {src_path} · SNAPSHOT — edits flow chat → board.md → regenerate"
    ws["A2"].font = Font(italic=True, size=9, color="808080")

    r = 4
    ws.cell(r, 1, "Sprints").font = SEC_FONT; r += 1
    for c, h in enumerate(["Sprint", "Dates", "Goal", "Status"], 1):
        cell = ws.cell(r, c, h); cell.fill, cell.font = HDR_FILL, HDR_FONT
    for sp in board["sprints"]:
        r += 1
        for c, v in enumerate(sp, 1):
            ws.cell(r, c, v).font = BODY_FONT
    r += 2

    ws.cell(r, 1, "Epic progress").font = SEC_FONT; r += 1
    for c, h in enumerate(["Epic", "Cards", "Done", "BE tasks", "FE tasks", "Other", "Blocked"], 1):
        cell = ws.cell(r, c, h); cell.fill, cell.font = HDR_FILL, HDR_FONT
    for e in board["epics"]:
        r += 1
        subs = [s for c_ in e["cards"] for s in c_["subs"]]
        ws.cell(r, 1, f'{e["name"]} ({e["range"]})').font = BODY_FONT
        ws.cell(r, 2, len(e["cards"])).font = BODY_FONT
        ws.cell(r, 3, sum(1 for c_ in e["cards"] if c_["status"] == "Done")).font = BODY_FONT
        ws.cell(r, 4, sum(1 for s in subs if s["disc"] == "BE")).font = BODY_FONT
        ws.cell(r, 5, sum(1 for s in subs if s["disc"] == "FE")).font = BODY_FONT
        ws.cell(r, 6, sum(1 for s in subs if s["disc"] not in ("BE", "FE"))).font = BODY_FONT
        ws.cell(r, 7, sum(1 for c_ in e["cards"] if c_["status"] == "Blocked")).font = BODY_FONT
    r += 2

    ws.cell(r, 1, "Cards by status").font = SEC_FONT; r += 1
    all_cards = [c_ for e in board["epics"] for c_ in e["cards"]]
    for c, st in enumerate(STATUSES, 1):
        cell = ws.cell(r, c, st); cell.fill = PatternFill("solid", fgColor=STATUS_FILL[st])
        cell.font = Font(bold=True, size=10)
    r += 1
    for c, st in enumerate(STATUSES, 1):
        ws.cell(r, c, sum(1 for x in all_cards if x["status"] == st)).font = BODY_FONT
    r += 2
    ws.cell(r, 1, f"Totals: {len(all_cards)} cards · "
                  f"{sum(1 for t in task_rows if t['sheet']=='BE')} BE tasks · "
                  f"{sum(1 for t in task_rows if t['sheet']=='FE')} FE tasks · "
                  f"{qa_count} QA test cases").font = Font(bold=True, size=10)

    # config block (fixed anchors referenced by BE/FE formulas)
    ws["M1"] = "Est→Days (edit HERE — all sheets follow)"; ws["M1"].font = Font(bold=True, italic=True, size=9)
    for i, (e, d) in enumerate(EST_DAYS, start=2):
        ws.cell(i, 13, e); ws.cell(i, 14, d)
    ws["M7"] = "Holidays (WORKDAY skips — edit as needed)"; ws["M7"].font = Font(bold=True, italic=True, size=9)
    for i, h in enumerate(HOLIDAYS, start=8):
        cell = ws.cell(i, 13, datetime.strptime(h, "%Y-%m-%d"))
        cell.number_format = "yyyy-mm-dd"
    for col, w in {"A": 42, "B": 10, "C": 10, "D": 10, "E": 10, "F": 8, "G": 9, "M": 24, "N": 7}.items():
        ws.column_dimensions[col].width = w


# ─── main ───────────────────────────────────────────────────────────────────
def main():
    ap = argparse.ArgumentParser(description="Generate the 4-sheet task-board xlsx from board.md")
    ap.add_argument("--project", required=True, help="project dir containing board.md")
    ap.add_argument("--out", help="output filename (default: <project>-board-<date>.xlsx)")
    args = ap.parse_args()

    board_path = os.path.join(args.project, "board.md")
    if not os.path.isfile(board_path):
        sys.exit(f"ERROR: no board.md at {board_path} — run the task-board skill migration first.")
    board = parse_board(board_path)
    qa_rows = parse_qa_plans(os.path.join(args.project, "deliverables", "documents"))

    task_rows = []
    for e in board["epics"]:
        for c in e["cards"]:
            parent = f'{c["id"]} {c["title"]}'
            for s in c["subs"]:
                sheet = s["disc"] if s["disc"] in ("BE", "FE") else None
                task_rows.append({
                    "sheet": sheet or "OTHER", "id": s["id"], "parent": parent,
                    "module": e["name"], "title": s["title"], "est": s["est"],
                    "status": "Done" if s["done"] else c["status"],
                    "sprint": c["sprint"] if c["sprint"] not in ("—", "-") else "",
                    "deps": c["deps"] if c["deps"] not in ("—", "-") else "",
                    "priority": c["priority"],
                    "assignee": c["assignee"] if c["assignee"] not in ("—", "-") else "",
                    "spec": c["spec"], "notes": c["notes"]})

    wb = Workbook()
    wb.calculation.fullCalcOnLoad = True
    build_dashboard(wb, board, task_rows, len(qa_rows), board_path)
    build_task_sheet(wb, "BE", [t for t in task_rows if t["sheet"] == "BE"])
    build_task_sheet(wb, "FE", [t for t in task_rows if t["sheet"] == "FE"])
    build_qa_sheet(wb, qa_rows)

    out_dir = os.path.join(args.project, "deliverables", "reports")
    os.makedirs(out_dir, exist_ok=True)
    slug = os.path.basename(os.path.normpath(args.project))
    out = os.path.join(out_dir, args.out or f"{slug}-board-{datetime.now():%Y-%m-%d}.xlsx")
    wb.save(out)
    print(f"WROTE: {out}")
    print(f"  cards: {sum(len(e['cards']) for e in board['epics'])} across {len(board['epics'])} epics"
          f" | BE rows: {sum(1 for t in task_rows if t['sheet']=='BE')}"
          f" | FE rows: {sum(1 for t in task_rows if t['sheet']=='FE')}"
          f" | other: {sum(1 for t in task_rows if t['sheet']=='OTHER')}"
          f" | QA cases: {len(qa_rows)}")


if __name__ == "__main__":
    main()
