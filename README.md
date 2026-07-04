# agent-skills

A collection of agent skills for MiMo-Code / OpenCode (and compatible runtimes). URL-installable, language-agnostic.

## Skills

| Name | What it does |
|------|-------------|
| [`codebase`](./codebase/) | Navigate legacy / debt-laden codebases before multi-file changes — sparse anchors, git co-change signals, on-demand LSP. Detects parallel implementations (N near-duplicate files that drift) and produces a divergence matrix. |

## Install

Add the repo URL to your MiMo-Code / OpenCode config (`.mimocode/mimocode.json` for project scope, or `~/.config/mimocode/mimocode.json` for global):

```jsonc
{
  "skills": {
    "urls": ["https://raw.githubusercontent.com/<your-user>/agent-skills/main/"]
  }
}
```

MiMo-Code fetches `index.json` from the URL root, then downloads each skill's listed files into a local cache and registers them as available skills. Restart the session (or run `/skills reload` if available) to pick them up.

Trigger a skill by describing your task in concept terms (e.g. "refactor the login auth token flow") or explicitly ("use the codebase skill").

## Skill format

Each skill is a directory whose name matches the `name` field in its `SKILL.md` frontmatter:

```
agent-skills/
├── index.json              # registry — lists every skill + its files
├── codebase/
│   ├── SKILL.md            # YAML frontmatter (name, description) + Markdown body
│   └── reference/
│       ├── tools.md        # @reference files loaded on demand
│       └── signals.md
└── <next-skill>/
    └── SKILL.md
```

To add a skill:
1. Create `<skill-name>/SKILL.md` with `name: <skill-name>` in frontmatter.
2. Add any `reference/` files and reference them from SKILL.md via `@reference/<file>.md`.
3. Append an entry to `index.json` `skills[]` listing all files (paths relative to the skill directory, must include `SKILL.md`).

## License

MIT
