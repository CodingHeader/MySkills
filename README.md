# Skills Repository

Aligned with patterns from `vercel-labs/agent-skills` and `anthropics/skills`:
- All skills live under `skills/`.
- Each skill has a `SKILL.md` manifest and colocated scripts.
- `skills/registry.json` lists skills for discovery.

## Skills
| Name | Description | Path | Entry |
| --- | --- | --- | --- |
| multi-agent-thinker | Heavy-lifting multi-agent reasoning patterns | `skills/multi-agent-thinker/` | `skills/multi-agent-thinker/SKILL.md` |
| instruction-repeater | Repeat user instructions by length; always available | `skills/instruction_repeater/` | `skills/instruction_repeater/SKILL.md` |
| project-steward | Project orchestration (planning, navigation, memory) | `skills/project-steward/` | `skills/project-steward/SKILL.md` |
| project-structure-creator | Enforce standardized project structure | `skills/project-structure-creator/` | `skills/project-structure-creator/SKILL.md` |
| ui-ux-pro-max | UI/UX design helper | `skills/ui-ux-pro-max/` | `skills/ui-ux-pro-max/SKILL.md` |

## Usage
Import or reference skills by their paths above. See each `SKILL.md` for trigger logic and scripts for execution. Adjust PYTHONPATH or tooling to include `skills/` when importing modules.

## Manager
1. Use **Vercel Skills** (`npx skills`) as the downloader to manage sources and lock versions; see `manager/VercelLabs-Skills-README.md`.
2. Use **OpenSkills** to point to the downloaded directories, generate the `AGENTS.md` index, and leverage on-demand loading for better context efficiency; see `manager/OpenSkills-README.md`.
