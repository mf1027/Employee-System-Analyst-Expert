# pdf-source/

Drop your **raw client PDFs** here. This is the default location `pdf2md` reads from,
so you can convert without typing paths.

> Everything in this folder except this README is **gitignored** — client PDFs are
> confidential and never pushed.

## Convert

```powershell
# Windows
scripts\pdf2md.ps1                       # convert EVERY *.pdf in this folder
scripts\pdf2md.ps1 -InputFile sample.pdf # convert one by name (this folder is checked first)
```

```bash
# Linux / Mac
bash scripts/pdf2md.sh                    # convert every *.pdf in this folder
bash scripts/pdf2md.sh sample.pdf         # convert one by name
```

Each PDF produces a `<name>.md` **next to it** in this folder.

## How `pdf2md` finds your PDF

| You pass… | What it does |
|---|---|
| nothing | converts every `*.pdf` in `pdf-source/` |
| a bare name (`sample.pdf`) | checks `pdf-source/` first → then the current dir → else error |
| a path (`reference\x.pdf`) | uses it as given |
| a folder | converts every `*.pdf` in that folder |
| add `-Recurse` / `RECURSE=1` | also descends into subfolders when batching |

## After converting

Put the `.md` in `reference/` (or point ingestion here), then run **`ingest-reference`**
in Claude Code — the employee reads it once and distils it into memory as `KB-` entries.
