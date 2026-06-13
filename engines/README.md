# engines/ — Local document engines

This folder holds **portable binaries** used by the document-skills (LibreOffice,
optionally Poppler) so they can live inside the project and travel with your backup
zip — no per-machine install needed.

Everything here except this README is **gitignored** (binaries are too large for git
and are platform-specific).

## How it gets populated

```powershell
# Windows — extracts the official LibreOffice MSI into engines/ (no system install)
scripts\fetch-libreoffice-local.ps1
```

This runs an *administrative install* (`msiexec /a`) — pure file extraction, no
registry changes, no admin rights to the system. The result is a self-contained
LibreOffice at `engines/LibreOffice/program/soffice.exe`.

## Resolution order

The patched `get_soffice_cmd()` in the document-skills checks, in order:

1. **`engines/`** (this folder) — project-local portable copy
2. **PATH** — `soffice` on the system PATH
3. **System install dir** — `C:\Program Files\LibreOffice\...`

So whichever exists wins, and you never have to re-point anything.

## Cross-machine

`engines/` is included in `scripts/backup.ps1`. Restore the backup zip on a new
Windows machine and LibreOffice is already there — zero install. On a fresh machine
without a backup, run `scripts/setup.ps1` (it installs system-wide) or
`scripts/fetch-libreoffice-local.ps1` (it fills this folder).

> Windows-only. On Mac/Linux the setup script installs LibreOffice via brew/apt
> instead — this folder stays empty there.
