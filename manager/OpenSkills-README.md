# OpenSkills 全方位指南 (Universal Skills Loader)

> **核心提示**：本工具是 **OpenSkills** (`npx openskills`)，由 **numman-ali** 开发。
> 请勿与 **Vercel Skills** (`npx skills`) 混淆。两者虽然都用于管理 AI 技能，但设计哲学截然不同。
>
> *   **OpenSkills**: 侧重 **"按需加载 (On-Demand Loading)"** 和 **"通用性"**。它通过生成菜单 (`AGENTS.md`) 让 AI 动态读取技能，极大地节省 Context Token。
> *   **Vercel Skills**: 侧重 **"静态分发 (Static Distribution)"**。它将技能文件直接安装到 Agent 的配置目录，依赖 Agent 原生扫描加载。

---

## 1. 什么是 OpenSkills？

OpenSkills 是一个通用的 AI 技能加载器（Universal Loader）。它的目标是将 Anthropic 定义的 `SKILL.md` 标准带给所有的 AI 编程助手 —— 无论是 **Claude Code**、**Cursor**、**Windsurf**、**Trae** 还是 **Aider**。

### 核心优势：渐进式披露 (Progressive Disclosure)
传统的 Agent 往往会在启动时将所有工具的 Prompt 一次性塞入上下文（Context Window）。当技能数量达到几十个时，这会消耗大量 Token 并导致模型“变笨”。

OpenSkills 采用**渐进式**策略：
1.  **只提供菜单**：仅向 AI 展示一个轻量级的技能列表（包含名称和简介）。
2.  **按需读取**：当 AI 决定使用某个技能时，它会执行 CLI 命令 (`openskills read <name>`) 来获取该技能的详细指令和完整 Prompt。
3.  **保持清洁**：未使用的技能永远不会占用宝贵的上下文空间。

---

## 2. 快速开始

### 安装
你可以选择全局安装，或者直接使用 `npx` 运行（推荐）。

```bash
# 全局安装 (可选)
npm install -g openskills

# 验证安装
npx openskills --version
```

### 核心工作流 (The Loop)

使用 OpenSkills 通常遵循以下三个步骤：

#### 第一步：安装技能 (Install)
从官方市场、GitHub 仓库或本地路径安装技能。
```bash
# 安装 Anthropic 官方标准技能库
npx openskills install anthropics/skills
```

#### 第二步：同步索引 (Sync)
在项目根目录生成 `AGENTS.md` 文件。这个文件就是给 AI 看的“菜单”。
```bash
npx openskills sync
```

#### 第三步：AI 调用 (Read)
在你的 AI 编辑器（Cursor/Trae/Windsurf）中打开 `AGENTS.md`，或者将其添加到系统提示词中。
当 AI 需要使用工具（例如处理 PDF）时，它会运行：
```bash
npx openskills read pdf
```
系统会返回完整的 PDF 处理指南，AI 随即开始执行任务。

---

## 3. 命令详解

### `install` - 安装技能
支持多种来源的安装方式。

**基本用法**：
```bash
npx openskills install <source> [options]
```

**示例**：
*   **官方/GitHub 仓库**：
    ```bash
    # 安装 Anthropic 官方技能
    npx openskills install anthropics/skills
    
    # 安装任何 GitHub 仓库的技能
    npx openskills install vercel-labs/agent-skills
    ```
*   **本地路径**：
    ```bash
    npx openskills install ./my-local-skills/data-analysis
    ```
*   **私有仓库** (支持 SSH)：
    ```bash
    npx openskills install git@github.com:my-org/private-skills.git
    ```

**关键参数**：
*   `--global` (`-g`)：安装到用户全局目录 `~/.claude/skills`。默认是安装到当前项目的 `.claude/skills`。
*   `--universal` (`-u`)：**强烈推荐**。安装到 `.agent/skills` 目录。这是为了兼容多 Agent 环境，避免与 Claude Code 原生插件冲突。
*   `-y`：非交互模式，自动确认覆盖，适合 CI/CD。

### `sync` - 生成索引
扫描已安装的技能，生成 AI 可读的索引文件。

```bash
npx openskills sync [options]
```

**关键参数**：
*   `--output <path>` (`-o`)：指定输出文件路径。
    ```bash
    # 例如，生成到 Cursor 的规则目录
    npx openskills sync -o .cursorrules
    ```
*   `-y`：非交互模式。

### `read` - 读取技能 (AI 专用)
这是 Agent 与 OpenSkills 交互的桥梁。人类通常不需要手动运行此命令。

```bash
npx openskills read <skill-name>
# 支持一次读取多个
npx openskills read skill1,skill2
```
**输出内容**：
*   技能的完整 System Prompt。
*   技能所需的依赖说明。
*   技能包含的脚本路径（自动解析为绝对路径）。

### `list` - 查看列表
列出当前环境下已安装的所有技能。
```bash
npx openskills list
```

### `update` - 更新技能
从源头（Git 仓库）更新已安装的技能。
```bash
# 更新所有技能
npx openskills update

# 更新指定技能
npx openskills update pdf-tool
```

### `manage` / `remove` - 管理与删除
```bash
# 交互式管理界面
npx openskills manage

# 直接删除
npx openskills remove <skill-name>
```

---

## 4. 高级用法与原理

### 通用模式 (Universal Mode)
如果你同时使用 Claude Code 和其他编辑器（如 Cursor），建议使用通用模式：

```bash
# 安装到 .agent/skills 目录，这是所有 Agent 的通用标准
npx openskills install anthropics/skills --universal
```

OpenSkills 在查找技能时遵循以下**优先级**（由高到低）：
1.  `./.agent/skills/` (项目级通用)
2.  `~/.agent/skills/` (全局通用)
3.  `./.claude/skills/` (项目级 Claude)
4.  `~/.claude/skills/` (全局 Claude)

### 自定义技能开发 (SKILL.md)
OpenSkills 完美支持 Anthropic 的 `SKILL.md` 规范。

一个标准的技能目录结构：
```text
my-skill/
├── SKILL.md          # 核心定义文件 (包含 Frontmatter 元数据)
├── scripts/          # Python/Bash 脚本
│   └── process.py
├── references/       # API 文档或参考资料
└── assets/           # 静态资源
```

**SKILL.md 示例**：
```markdown
---
name: data-analyzer
description: 用于分析 CSV 数据并生成图表的工具。
---

# Data Analyzer Instructions

当用户请求分析数据时：
1. 读取数据文件。
2. 运行 `python scripts/analyze.py`。
3. ...
```

### 本地开发与软链接 (Symlinks)
对于开发者，可以使用软链接进行调试，无需反复安装：
```bash
# 将本地开发的技能链接到项目技能库
ln -s ~/dev/my-new-skill .agent/skills/my-new-skill
# 然后运行 sync 更新菜单
npx openskills sync
```

---

## 5. 各大编辑器集成指南

### VS Code / Cursor / Windsurf / Trae

这些编辑器目前大多没有内置对 OpenSkills 的原生“自动”支持，但可以通过以下方式完美集成：

1.  **生成规则文件**：
    将 `AGENTS.md` 的内容作为项目规则（Project Rules）。
    ```bash
    # 针对 Cursor
    npx openskills sync -o .cursorrules
    
    # 针对 Windsurf/Trae (生成普通文件，需手动引用)
    npx openskills sync -o AGENTS.md
    ```

2.  **配置系统提示词 (System Prompt)**：
    在编辑器的设置或项目的 `.cursorrules` / `.windsurfrules` 中，添加以下核心指令：

    > **System Instruction**:
    > 本项目集成了 OpenSkills 技能库。
    > 所有的可用技能列表请参考项目根目录下的 `AGENTS.md` (或 `.cursorrules`)。
    > 
    > **如何使用技能**：
    > 当你需要执行特定任务且 `AGENTS.md` 中有对应技能时，请**务必**先运行以下命令来加载技能详情：
    > `npx openskills read <skill-name>`
    > 
    > 读取命令输出的内容后，请严格按照其中的步骤执行任务。

3.  **使用流程**：
    *   用户：“帮我把这个 PDF 转成图片。”
    *   Agent (读取 `AGENTS.md`)：“我看到了 `pdf` 技能，我需要先加载它。”
    *   Agent (执行命令)：“`npx openskills read pdf`”
    *   Agent (获取上下文)：“已获取 PDF 处理工具的详细指令，现在开始转换...”

---

## 6. 常见问题 (FAQ)

**Q: 为什么运行 `npx openskills read` 没有任何反应？**
A: 请检查你的终端是否有权限运行 `npx` 命令。另外，确保你拼写的技能名称与 `npx openskills list` 中显示的一致。

**Q: Windows 下安装报错 "Security error: Installation path outside target directory"？**
A: 这是一个已知问题，已在 `v1.3.1` 版本修复。请确保使用最新版：`npx openskills@latest ...`。

**Q: 它可以和 Vercel Skills 混用吗？**
A: 可以。你可以用 Vercel Skills 下载技能文件，然后用 OpenSkills 的 `sync` 命令生成索引，从而利用 OpenSkills 的“按需加载”特性。

---

## 参考资料

*   **官方仓库**: [https://github.com/numman-ali/openskills](https://github.com/numman-ali/openskills)
*   **Anthropic Skills 规范**: [https://github.com/anthropics/anthropic-quickstarts](https://github.com/anthropics/anthropic-quickstarts)
*   **其他教程**:
    *   [OpenSkills: Universal Skills Loader](https://www.vibesparking.com/zh-cn/blog/ai/openskills/2025-12-24-openskills-universal-skills-loader-ai-coding-agents/)
    *   [Claude Code Skills and OpenSkills](https://lzw.me/a/claude-code-skills-and-openskills.html)
