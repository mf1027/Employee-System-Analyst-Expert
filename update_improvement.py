import re

file_path = 'memory/improvement-backlog.md'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Generate new Breadcrumb/Proposal
date_str = '2026-09-24'  # using a current date string
new_entry = f"""- {date_str} · skill-fell-short · `[→ SKL-060, applied {date_str}]` **plan-analysis lacks explicit integration of bloat-reduction and specific review adapters.** Phase 4 of `.claude/skills/plan-analysis/SKILL.md` mentions DX and engineering lenses but doesn't explicitly invoke the `office-hours`, `/plan-devex-review`, `/plan-eng-review`, or `/design-review` adapters, leaving them unused unless manually triggered. Furthermore, it lacks the `ponytail-audit` discipline (eliminating dead code, YAGNI, and preferring stdlib/native methods) which should be applied during gap analysis to prevent over-engineering. · [system] -> candidate: Update Phase 3 to include a ponytail-audit/simplification check (delete before build) and Update Phase 4 to explicitly list the specific review adapter commands."""

# Insert after NEXT-ID block
# We need to increment Next-ID to SKL-061
content = re.sub(r'Next-ID: SKL-060', r'Next-ID: SKL-061', content)

# Insert the new entry into the breadcrumbs section (under the most recent entry)
# Let's find the first breadcrumb line "- 2026-" and insert it before that.
match = re.search(r'(- \d{4}-\d{2}-\d{2} · )', content)
if match:
    parts = content.split(match.group(1), 1)
    content = parts[0] + new_entry + "\n" + match.group(1) + parts[1]

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

