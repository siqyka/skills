# skills

个人 skill 集合，按「一个目录一个 skill」组织，可直接被 DeepSeek Harness / Claude Code / Codex 等支持 `SKILL.md` 的工具加载。

> A small collection of agent skills. Each skill is a directory containing a `SKILL.md`, plus optional reference files. Give an agent the repo URL and it can install everything by itself.

## 让 AI 安装（只需要仓库地址）

把下面这段原样丢给任何**能执行命令**的 AI：

```text
把 https://github.com/siqyka/skills 装上（私有仓库，用你有权限的凭证 clone）。

安装规则：
1. 一个 skill = 一个目录 skills/<分类>/<名称>/，判断依据是该目录里存在 SKILL.md；其余文件忽略
2. 每个 skill 装到用户级 skill 根目录：~/.agents/skills/<名称>/
   （Windows 是 %USERPROFILE%\.agents\skills\<名称>\）
3. 整个 skill 目录一起装（含 references/、agents/），不要只拷 SKILL.md，不要再套一层目录
4. 装完逐个确认 <根目录>/<名称>/SKILL.md 存在，报告：发现几个、装了几个、跳过几个
5. 全部做完再回我一句话总结，不要边装边问
```

这段提示词对**以后新增的 skill 同样有效**：AI 靠 `skills/*/*/SKILL.md` 自动枚举，不需要你更新名单。仓库里现在有 1 个 skill，将来有 10 个，同一个提示词照样能用。

AI 需要知道的三条硬规则（也是它最容易装错的地方）：

| 规则 | 装错的样子 |
|---|---|
| 一个 skill 一个目录，不比仓库根 | 把整个仓库塞进 skill 目录 → 扫不到 |
| 只能一层：`<根>/<名称>/SKILL.md` | 多套一层 `<根>/<名称>/<名称>/SKILL.md` → 扫不到 |
| 目录整体安装 | 只拷 `SKILL.md`，`references/` 丢失 → 引用断链、skill 残废 |

## 手动安装

```powershell
# Windows
git clone git@github.com:siqyka/skills.git
# 复制每个 skill 目录（示例：只有 session-handoff）
xcopy /E /I "%CD%\skills\skills\productivity\session-handoff" "%USERPROFILE%\.agents\skills\session-handoff"
```

```bash
# macOS / Linux
git clone git@github.com:siqyka/skills.git
cp -R skills/skills/productivity/session-handoff ~/.agents/skills/session-handoff
```

想省掉以后每次的复制，就把目录换成软链（仓库即正本，改完立即生效）：

```powershell
mklink /D "%USERPROFILE%\.agents\skills\session-handoff" "%CD%\skills\skills\productivity\session-handoff"
```

```bash
ln -s "$PWD/skills/skills/productivity/session-handoff" ~/.agents/skills/session-handoff
```

Windows 软链需要开发者模式或管理员权限，失败就退回复制——两条路都行，区别只是「要不要手动同步」。

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

- 仓库是正本；装成软链可以让仓库直接就是本地生效的那份，不会有「仓库一份、本地一份」的漂移。
- 新增 skill：建 `skills/<分类>/<name>/`，写 `SKILL.md`，在 Skills 表格加一行即可；上面的 AI 提示词不需要改（它按 `skills/*/*/SKILL.md` 自动发现）。
- 提交信息用 Conventional Commits，如 `feat(session-handoff): add cleanup prompt`。

## License

MIT，见 [LICENSE](LICENSE)。
