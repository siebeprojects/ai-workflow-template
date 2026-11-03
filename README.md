# AI agent workflow starter

Agent instructions, skills, and change templates for AI-assisted development. This starter contains only documentation; it never installs or overwrites application source code.

## Contents

- `AGENTS.md`: the primary, agent-agnostic engineering rules (Codex, Claude Code, and other compatible agents).
- `CLAUDE.md`: only imports `AGENTS.md` (`@AGENTS.md`) for Claude Code. Put shared rules in `AGENTS.md`, not here.
- `.agents/skills/`: canonical reusable skill definitions.
- `.claude/skills/`: symbolic links exposing those skills to Claude Code.
- `changes/_templates/`: `spec.md` (requirements), `plan.md` (technical plan), and `qa.md` (verification) templates.
- `install.sh`: installs the above into another repository. `install.sh` and this README stay here and are not copied.

## Installing into a repository

Clone this starter anywhere, then run the script from the clone, passing the target repository:

```bash
./install.sh /path/to/repo               # install, ask on conflicts
./install.sh --dry-run /path/to/repo     # preview, change nothing
./install.sh --force /path/to/repo       # overwrite conflicts without asking
./install.sh --no-exclude /path/to/repo  # do not ignore the files (to commit them)
```

The script:

- Copies `AGENTS.md`, `.agents/skills/`, and `changes/_templates/`. Files that are already identical are left alone.
- Creates `CLAUDE.md` if missing; if one exists, it prepends `@AGENTS.md` and keeps the existing content.
- Links each skill into `.claude/skills/<name>` (relative symlinks to `../../.agents/skills/<name>`), so new skills are picked up automatically.
- Asks for each existing file that differs: `[y]es / [n]o / [d]iff / [a]ll / [q]uit` (default: no). Without a terminal (e.g. CI), conflicts are skipped.
- Moves replaced originals to `.ai-workflow-backup/<timestamp>/` in the target repository. Review and then delete that folder. Old skill symlinks are removed instead of backed up.
- Privately ignores the installed files (and the backup folder) by adding root-anchored paths to the target's `.git/info/exclude`. That file is never committed, and `.gitignore` is not touched. Only the exact installed paths are excluded, so the repository's own `.claude/` files and `changes/<id>-*/` folders remain visible to git. Use `--no-exclude` if the workflow files should be committed and shared.
- Warns when an installed path is already tracked by git (for example a committed `CLAUDE.md`): ignore rules do not apply to tracked files. Untrack it with `git rm --cached <file>` if it should become private.

Run it again at any time to update a repository to the latest templates.

## Starting a change

A change can be a new feature, a bug fix, a refactoring, or other work. Create `changes/001-short-name/` and copy the templates into it. Keep `changes/_templates/` unchanged.

## Notes

- `.claude/skills/` contains symbolic links; preserve symlinks if you copy files manually.
- Check skill discovery in your installed versions of Claude Code and Codex.
