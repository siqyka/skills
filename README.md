# skills

个人 skill 集合，按「一个目录一个 skill」组织，可直接被 DeepSeek Harness / Claude Code / Codex 等支持 `SKILL.md` 的工具加载。

> A small collection of agent skills. Each skill is a directory containing a `SKILL.md` plus optional reference files.

## 目录约定

```
skills/
└── <分类>/
    └── <skill-name>/
        ├── SKILL.md          # 必需：YAML frontmatter + 指令正文
        ├── agents/
        │   └── openai.yaml   # 可选：Codex / OpenAI 侧的展示与触发策略
        └── references/       # 可选：按需加载的长文档（模板、样例、子协议）
```

- **目录名 = skill 名 = frontmatter 里的 `name`**，三者必须一致，用小写英文和连字符。
- **发现深度只有一层**：`<分类>/<skill-name>/SKILL.md`。不要再往 skill 目录里嵌套第二层 `SKILL.md`，工具扫不到。
- **frontmatter 至少两行**：`name`、`description`。description 是唯一用于「要不要自动触发」的信号，把触发词写进去（中英都写能提高命中率）。
- **长内容放 `references/`**，SKILL.md 只留主干与索引——正文每次触发都会进上下文，越短越好。

## Skills

| Skill | 分类 | 用途 |
|---|---|---|
| [session-handoff](skills/productivity/session-handoff/SKILL.md) | productivity | 把当前会话压缩成一份可独立启动的交接文档；接手方按接收协议定向执行，并在读完文档后用选择弹窗询问清理临时文件 |

## 安装

复制或软链到工具的 skill 根目录。**推荐软链**，这样仓库里的改动立即生效，不会出现「仓库一份、本地一份」的漂移。

**DeepSeek Harness（用户级，全局生效）**

```powershell
# Windows：软链（需要管理员或开发者模式）
mklink /D "%USERPROFILE%\.agents\skills\session-handoff" "E:\GIT\skills\skills\productivity\session-handoff"
```

```bash
# macOS / Linux
ln -s "$PWD/skills/productivity/session-handoff" ~/.agents/skills/session-handoff
```

不想用软链就整目录复制到 `~/.agents/skills/<skill-name>/`——之后两边要手动保持同步。

**Claude Code**：`~/.claude/skills/<skill-name>/`
**Codex**：`~/.codex/skills/<skill-name>/`

## 使用

**生成交接文档**（在当前会话里说）：

```text
生成 handoff，交接给下一个会话
```

产出：`<工作区>/_handoffs/<日期>_<主题>-01.md`，外加一段可直接粘贴的 resume 提示词。

**接手**（在新会话里粘贴）：

```text
读取并接手以下交接文档：
<交接文档的完整绝对路径>

按文档「下一步最小行动」继续，不要重新探索。
```

接手方读完文档、动手之前，会用选择弹窗问一次「这些临时文件要不要删」——不删就先留着，不会自作主张。

## 维护

- 仓库是正本；本地安装用软链，或改完两边同步。
- 新增 skill：建 `skills/<分类>/<name>/`，写 `SKILL.md`，在本文件表格加一行。
- 提交信息用 Conventional Commits，如 `feat(session-handoff): add cleanup prompt`。

## License

MIT，见 [LICENSE](LICENSE)。
