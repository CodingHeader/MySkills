# npx skills 权威中文指南

本文档基于官方 [vercel-labs/skills](https://github.com/vercel-labs/skills) 仓库的完整 README 内容及相关教程进行了**全方位的翻译与扩展**。不仅涵盖了基础用法，还深入解析了所有高级功能、配置细节、开发规范及故障排除指南，旨在成为最详尽的中文参考手册。

---

## 目录

1.  [简介](#1-简介)
2.  [快速开始](#2-快速开始)
3.  [核心命令详解 (Install, Find, Update)](#3-核心命令详解)
4.  [安装范围与模式](#4-安装范围与模式)
5.  [支持的 AI Agent 完整列表](#5-支持的-ai-agent-完整列表)
6.  [自定义技能开发 (Creating Skills)](#6-自定义技能开发-creating-skills)
    *   [SKILL.md 规范](#skillmd-规范)
    *   [元数据与内部技能](#元数据与内部技能)
    *   [技能发现机制](#技能发现机制)
7.  [高级兼容性矩阵](#7-高级兼容性矩阵)
8.  [环境变量与遥测](#8-环境变量与遥测)
9.  [故障排除 (Troubleshooting)](#9-故障排除-troubleshooting)
10. [相关资源](#10-相关资源)

---

## 1. 简介

`skills` 是开放 Agent 技能生态系统的官方命令行工具（CLI）。它作为一个通用的包管理器，允许开发者将标准化的“技能（Skills）”安装到各种 AI 编程助手中。

**什么是 Agent Skill？**
Agent Skill 是一组可复用的指令集，用于扩展编程 Agent 的能力。它们定义在 `SKILL.md` 文件中，包含 YAML 头部元数据（名称、描述）和具体的 Markdown 指令。
通过安装技能，Agent 可以获得如下能力：
*   根据 Git 历史生成发布说明
*   遵循团队规范创建 Pull Request
*   集成外部工具（如 Linear, Notion 等）

---

## 2. 快速开始

无需安装，直接使用 `npx` 运行：

```bash
npx skills [command] [options]
```

最基础的安装命令：

```bash
npx skills add vercel-labs/agent-skills
```

---

## 3. 核心命令详解

### 3.1 安装技能 (`add`)

用于从远程仓库或本地路径安装技能。

**基本语法**:
```bash
npx skills add <source> [options]
```

**支持的源格式 (Source Formats)**:

| 格式类型 | 示例 | 说明 |
| :--- | :--- | :--- |
| **GitHub 简写** | `vercel-labs/agent-skills` | 最常用，自动指向 GitHub 仓库 |
| **完整 URL** | `https://github.com/vercel-labs/agent-skills` | 支持 GitHub/GitLab 等 |
| **Git URL** | `git@github.com:vercel-labs/agent-skills.git` | SSH 协议 |
| **子目录深链** | `.../tree/main/skills/frontend-design` | 仅安装仓库中特定目录下的技能 |
| **本地路径** | `./my-local-skills` | 用于本地调试或私有技能库 |

**选项 (Options)**:

| 选项 | 缩写 | 描述 |
| :--- | :--- | :--- |
| `--global` | `-g` | **全局安装**。安装到用户主目录，对所有项目生效。 |
| `--agent <names...>` | `-a` | **指定目标 Agent**。例如 `-a cursor -a trae`。如果不指定，CLI 会自动检测已安装的 Agent，若未检测到则提示选择。 |
| `--skill <names...>` | `-s` | **指定技能名称**。直接安装特定技能，跳过交互式选择列表。 |
| `--list` | `-l` | **仅列出**。查看远程仓库中有哪些技能可用，不执行安装。 |
| `--yes` | `-y` | **自动确认**。跳过所有确认提示（默认选择 Yes）。 |
| `--all` | 无 | **安装所有**。自动将源仓库中的**所有**技能安装到**所有**检测到的 Agent 中（隐含 `-y`）。 |

**常用示例**:

```bash
# 列出仓库中的技能
npx skills add vercel-labs/agent-skills --list

# 交互式选择安装到 Claude Code 和 OpenCode
npx skills add vercel-labs/agent-skills -a claude-code -a opencode

# CI/CD 模式：全局安装特定技能，无需交互
npx skills add vercel-labs/agent-skills --skill frontend-design -g -a claude-code -y
```

### 3.2 查找技能 (`find`)

交互式或关键词搜索技能。

```bash
# 启动交互式搜索界面 (类似 fzf)
npx skills find

# 直接按关键词搜索
npx skills find typescript
```

### 3.3 维护命令 (`check`, `update`, `generate-lock`)

*   **检查更新**:
    ```bash
    npx skills check
    ```
    检查当前已安装的技能是否有新版本。

*   **更新所有**:
    ```bash
    npx skills update
    ```
    将所有已安装技能更新到最新版本。

*   **生成锁定文件**:
    ```bash
    npx skills generate-lock
    # 预览而不写入
    npx skills generate-lock --dry-run
    ```
    生成 `skills.lock` 文件，记录已安装技能的源和版本，用于确保团队成员环境一致（类似 `package-lock.json`）。

### 3.4 初始化技能 (`init`)

快速创建技能模板。

```bash
# 在当前目录生成 SKILL.md
npx skills init

# 在指定子目录生成
npx skills init my-new-skill
```

---

## 4. 安装范围与模式

### 安装范围 (Installation Scope)

| 范围 | 标识 | 路径示例 | 适用场景 |
| :--- | :--- | :--- | :--- |
| **项目级** (默认) | 无 | `./<agent>/skills/` | 随项目代码提交到 Git，团队共享，针对特定项目的技能。 |
| **全局级** | `-g` | `~/<agent>/skills/` | 个人工具箱，跨所有项目可用。 |

### 安装模式 (Installation Methods)

在交互式安装时，CLI 会询问链接方式：

1.  **Symlink (软链) —— [推荐]**
    *   **原理**: 在 Agent 技能目录下创建指向源文件的符号链接。
    *   **优点**: **单一数据源**。更新源文件后，所有链接该源的 Agent 立即生效，无需重复复制；节省磁盘空间。
    *   **适用**: 本地开发技能库，或希望集中管理技能时。

2.  **Copy (复制)**
    *   **原理**: 将文件物理复制到 Agent 目录。
    *   **优点**: **完全独立**。删除源文件不影响已安装的技能；适用于不支持软链的环境。
    *   **缺点**: 更新繁琐，需要手动同步。

---

## 5. 支持的 AI Agent 完整列表

`npx skills` 支持将技能安装到以下所有 AI 编程环境中。表格列出了各 Agent 对应的 CLI 参数及安装路径。

<!-- agent-list:start -->
| Agent名称 | CLI参数 (`--agent`) | 项目级路径 | 全局路径 (`-g`) |
| :--- | :--- | :--- | :--- |
| **Trae** | `trae` | `.trae/skills/` | `~/.trae/skills/` |
| **Windsurf** | `windsurf` | `.windsurf/skills/` | `~/.codeium/windsurf/skills/` |
| **Cursor** | `cursor` | `.cursor/skills/` | `~/.cursor/skills/` |
| **Claude Code** | `claude-code` | `.claude/skills/` | `~/.claude/skills/` |
| **GitHub Copilot** | `github-copilot` | `.github/skills/` | `~/.copilot/skills/` |
| **VS Code (OpenCode)**| `opencode` | `.opencode/skills/`| `~/.config/opencode/skills/`|
| Amp / Kimi Code | `amp`, `kimi-cli` | `.agents/skills/` | `~/.config/agents/skills/` |
| Antigravity | `antigravity` | `.agent/skills/` | `~/.gemini/antigravity/global_skills/` |
| Cline | `cline` | `.cline/skills/` | `~/.cline/skills/` |
| CodeBuddy | `codebuddy` | `.codebuddy/skills/` | `~/.codebuddy/skills/` |
| Codex | `codex` | `.codex/skills/` | `~/.codex/skills/` |
| Command Code | `command-code` | `.commandcode/skills/` | `~/.commandcode/skills/` |
| Continue | `continue` | `.continue/skills/` | `~/.continue/skills/` |
| Crush | `crush` | `.crush/skills/` | `~/.config/crush/skills/` |
| Droid | `droid` | `.factory/skills/` | `~/.factory/skills/` |
| Gemini CLI | `gemini-cli` | `.gemini/skills/` | `~/.gemini/skills/` |
| Goose | `goose` | `.goose/skills/` | `~/.config/goose/skills/` |
| Junie | `junie` | `.junie/skills/` | `~/.junie/skills/` |
| Kilo Code | `kilo` | `.kilocode/skills/` | `~/.kilocode/skills/` |
| Kiro CLI | `kiro-cli` | `.kiro/skills/` | `~/.kiro/skills/` |
| Kode | `kode` | `.kode/skills/` | `~/.kode/skills/` |
| MCPJam | `mcpjam` | `.mcpjam/skills/` | `~/.mcpjam/skills/` |
| Moltbot | `moltbot` | `skills/` | `~/.moltbot/skills/` |
| Mux | `mux` | `.mux/skills/` | `~/.mux/skills/` |
| Neovate | `neovate` | `.neovate/skills/` | `~/.neovate/skills/` |
| OpenHands | `openhands` | `.openhands/skills/` | `~/.openhands/skills/` |
| Pi | `pi` | `.pi/skills/` | `~/.pi/agent/skills/` |
| Pochi | `pochi` | `.pochi/skills/` | `~/.pochi/skills/` |
| Qoder | `qoder` | `.qoder/skills/` | `~/.qoder/skills/` |
| Qwen Code | `qwen-code` | `.qwen/skills/` | `~/.qwen/skills/` |
| Roo Code | `roo` | `.roo/skills/` | `~/.roo/skills/` |
| Zencoder | `zencoder` | `.zencoder/skills/` | `~/.zencoder/skills/` |
<!-- agent-list:end -->

> **注意 (Kiro CLI 用户)**:
> Kiro CLI 需要手动配置。安装技能后，需编辑 `.kiro/agents/<agent>.json` 添加资源路径：
> ```json
> {
>   "resources": ["skill://.kiro/skills/**/SKILL.md"]
> }
> ```

---

## 6. 自定义技能开发 (Creating Skills)

技能本质上是一个包含 YAML Frontmatter 的 Markdown 文件。

### SKILL.md 规范

文件结构示例：

```markdown
---
name: my-skill
description: 这里简述技能的功能和触发场景
---

# My Skill (技能标题)

这里编写 Agent 遵循的详细指令。

## When to Use (何时使用)

描述该技能适用的具体场景。

## Steps (执行步骤)

1. 第一步做什么
2. 第二步做什么
```

**必填字段**:
*   `name`: 唯一标识符（建议小写，允许连字符）。
*   `description`: 技能功能的简短摘要。

### 元数据与内部技能

可以在 Frontmatter 中添加 `metadata` 字段。例如，标记一个技能为“内部使用”：

```markdown
---
name: my-internal-skill
description: 这是一个内部测试技能
metadata:
  internal: true
---
```

**效果**: 标记为 `internal: true` 的技能默认是**隐藏**的，不会在 `list` 或 `add` 命令中显示，除非设置了环境变量 `INSTALL_INTERNAL_SKILLS=1`。这非常适合正在开发中或仅供内部团队使用的工具。

### 技能发现机制

当你指定一个 Git 仓库作为源时，CLI 会按照以下顺序递归查找技能文件：

1.  **根目录** (如果包含 `SKILL.md`)
2.  `skills/`
3.  `skills/.curated/`
4.  `skills/.experimental/`
5.  `skills/.system/`
6.  以及所有支持 Agent 的默认技能目录 (如 `.trae/skills/`, `.cursor/skills/` 等，共计 30+ 个路径)

如果上述标准位置未找到，CLI 会执行全仓库递归搜索。

---

## 7. 高级兼容性矩阵

虽然大部分技能遵循通用的 [Agent Skills Specification](https://agentskills.io)，但不同 Agent 对高级特性的支持度不同。

| 特性 | 说明 | 广泛支持 | 不支持/部分支持 |
| :--- | :--- | :--- | :--- |
| **Basic Skills** | 基础指令遵循 | ✅ 所有 Agent | - |
| **`allowed-tools`** | 限制技能可调用的工具 | ✅ 绝大多数 (OpenCode, Claude, Trae, Windsurf 等) | ❌ Kiro CLI, Zencoder |
| **`context: fork`** | 允许技能在独立上下文中运行 | ❌ 仅 Claude Code 支持 | ❌ 其他所有 Agent |
| **Hooks** | 生命周期钩子 | ❌ 仅 Claude Code, Cline 支持 | ❌ 其他所有 Agent |

*注：此矩阵基于官方文档数据，随着 Agent 版本更新可能会有变化。*

---

## 8. 环境变量与遥测

你可以通过环境变量配置 CLI 的行为：

| 变量名 | 描述 |
| :--- | :--- |
| `INSTALL_INTERNAL_SKILLS` | 设置为 `1` 或 `true` 以显示和安装标记为 `internal: true` 的技能。 |
| `DISABLE_TELEMETRY` | 设置为任意非空值以禁用匿名使用数据收集。 |
| `DO_NOT_TRACK` | 同上，禁用遥测的另一种标准方式。 |

**示例**:
```bash
# 查看包含内部技能的列表
INSTALL_INTERNAL_SKILLS=1 npx skills add vercel-labs/agent-skills --list
```

**关于遥测**:
CLI 会收集匿名的使用数据以改进工具（不包含个人信息）。**在 CI/CD 环境中，遥测会自动禁用。**

---

## 9. 故障排除 (Troubleshooting)

### Q: 提示 "No skills found" (未找到技能)
*   **检查点**: 确保目标仓库中的 `SKILL.md` 文件包含有效的 YAML Frontmatter，且必须有 `name` 和 `description` 字段。

### Q: 技能已安装但在 Agent 中不生效
*   **检查路径**: 确认技能是否安装到了该 Agent 预期的目录（参考 [Agent 列表](#5-支持的-ai-agent-完整列表)）。
*   **检查文档**: 部分 Agent 可能需要手动重载配置或重启。
*   **YAML 格式**: 确保 Frontmatter 格式正确，缩进无误。

### Q: Permission errors (权限错误)
*   **解决**: 确保你对安装目标目录（特别是全局安装时的用户目录）拥有写入权限。

---

## 10. 相关资源

*   [Agent Skills 规范官网](https://agentskills.io)
*   [Skills.sh 技能目录](https://skills.sh)
*   [Vercel Agent Skills 官方仓库](https://github.com/vercel-labs/agent-skills)
*   各大 Agent 官方文档 (见官方 README 底部链接)

---
*文档生成日期: 2026-01-28 | 基于 vercel-labs/skills v1.0+ 版本*
