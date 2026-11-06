# agent-skills

Cross-platform agent skills for software-engineering and desktop-environment workflows. Works with **Cursor**, **Claude Code**, **OpenAI Codex**, and **MiMo-Code / OpenCode**.

## Skills

| Name | What it does |
|------|-------------|
| [`navigate-change`](./navigate-change/) | Before a concept-described multi-file edit, locate the right files via sparse grep anchors, git co-change signals, and on-demand structure analysis (LSP when available, grep fallback otherwise). Detects parallel implementations that drift and produces a divergence matrix. |
| [`xfce-whitesur-desktop`](./xfce-whitesur-desktop/) | Audits and recreates a macOS-like Xfce desktop with WhiteSur, Inter, Labwc Wayland, and native top/bottom Xfce panels. Includes a cloud-desktop baseline and read-only environment audit script. |

### Why `navigate-change` (not `codebase`)?

The skill is about **navigating to the right edit sites before you change code** — not about understanding the whole codebase. The name matches the trigger ("refactor the auth token flow") and the deliverable (a change navigation artifact), and avoids the generic/overloaded word "codebase".

## Install

Copy only the skill folders you need. The install examples use
`<skill-name>` as a placeholder.

### Cursor

Copy or symlink the skill directory:

```bash
# project-scoped (recommended for teams)
mkdir -p .cursor/skills
cp -r <skill-name> .cursor/skills/

# or global
mkdir -p ~/.cursor/skills
cp -r <skill-name> ~/.cursor/skills/
```

Restart the agent session. The skill auto-triggers from its `description`, or
invoke it explicitly by name.

### Claude Code

```bash
# project-scoped
mkdir -p .claude/skills
cp -r <skill-name> .claude/skills/

# or global
mkdir -p ~/.claude/skills
cp -r <skill-name> ~/.claude/skills/
```

Restart the session. Invoke with `/<skill-name>` or let Claude auto-trigger from
the description.

### OpenAI Codex

```bash
# project-scoped
mkdir -p .agents/skills
cp -r <skill-name> .agents/skills/

# or global
mkdir -p ~/.agents/skills
cp -r <skill-name> ~/.agents/skills/
```

Restart Codex. Invoke explicitly with `$<skill-name>`, or let Codex match
implicitly from the description.

### MiMo-Code / OpenCode (URL install)

Add the repo URL to your config (`.mimocode/mimocode.json` for project scope, or `~/.config/mimocode/mimocode.json` for global):

```jsonc
{
  "skills": {
    "urls": ["https://raw.githubusercontent.com/<your-user>/agent-skills/main/"]
  }
}
```

MiMo-Code fetches `index.json` from the URL root, downloads listed files into a local cache, and registers them as available skills. Restart the session (or run `/skills reload` if available).

## Skill format

Each skill is a directory whose name matches the `name` field in its `SKILL.md` frontmatter:

```
agent-skills/
├── index.json                    # registry for URL-based installs (MiMo-Code)
├── navigate-change/
│   ├── SKILL.md                  # YAML frontmatter (name, description) + Markdown body
│   └── reference/
│       ├── tools.md              # per-phase commands + per-runtime Phase 3 mappings
│       └── signals.md            # how to interpret git & structure signals
└── <next-skill>/
    └── SKILL.md
```

Reference files are linked from `SKILL.md` with standard Markdown links. The agent should read them **when reaching the relevant phase**, not at skill start.

To add a skill:
1. Create `<skill-name>/SKILL.md` with `name: <skill-name>` in frontmatter.
2. Add any `reference/` files and link them from `SKILL.md`.
3. Append an entry to `index.json` `skills[]` listing all files (paths relative to the skill directory, must include `SKILL.md`).

## Cross-platform notes

| Concern | How this repo handles it |
|---------|--------------------------|
| `description` length | Unified description ≤500 chars (Codex limit); works on all platforms |
| Phase 3 structure analysis | LSP when available (MiMo-Code); grep/read fallback for Cursor, Codex, Claude Code — see `reference/tools.md` |
| Reference loading | Markdown links, not `@reference/` syntax |
| Install | Per-platform paths documented above; `index.json` only for URL installs |

## License

MIT
