# 示例（虚构数据，只示范结构）

> 文中 `X:` 与 `acme-cli` 均为占位，不是真实工作区；照抄时替换成自己的绝对路径。

一份「任务做到一半、上下文快满」时产出的交接文档，以及随后回复用户的形态。

---

```markdown
# Handoff — acme-cli 导出改为流式写盘

> 生成时间：2026-11-13T14:41+08:00　｜　来源会话：当前会话 / lead　｜　交接目的：把 export 命令的内存攒批改成流式，避免 200 万行 OOM

## 0. 元信息

| 字段 | 值 |
|---|---|
| 工作区绝对路径 | `X:\repo\acme-cli` |
| git 分支 / HEAD | `feat/stream-export` @ `a1b2c3d` |
| 未提交改动 | 3 个文件：`src/export/writer.ts`、`test/export.test.ts`、`package.json`（未提交，勿回滚） |
| 权限模式 | `workspace-write`，无需审批 |
| 目标 id / 状态 | `goal g-7f21`（active） |
| 后台作业 | 无 |
| 端口转发 / 远端挂载 | 无 |
| 环境依赖 | Node 22.9、pnpm 9；`pnpm test` 已可用 |
| 临时文件（待清理） | `X:\repo\acme-cli\_handoffs\20261113_stream-export-01.md`（本文件）；`X:\repo\acme-cli\bench\rows-2m.tmp.csv`（压测中间导出） |

## 1. 目标

- **要达成什么**：`acme export --format csv` 在 200 万行数据集上常驻内存 < 200 MB 并正常退出。
- **为什么**：线上导出任务在 1.8M 行左右被 OOM kill，运维每天手动重跑。
- **明确不做**：不改 CLI 参数接口、不换输出格式、不碰 `src/import/`。
- **目标演进**：最初想「调大 JSON 里的 chunk 数」压内存 → 查到分页接口后改成流式写盘 — 因为前者只是把峰值挪后，2M 行仍会炸。

## 2. 已确认事实

| 段 | 需求或目标变化 | 确认的事实 | 决策 + 理由 | 排除 / 失败 |
|---|---|---|---|---|
| 开头 | 要止血 OOM | 崩溃点固定在 1.8M 行附近，非数据异常 | — | 调 JVM/Node 堆上限：只把崩溃点往后挪 |
| 中段 | 改成「少占内存」 | 分页接口支持 cursor，每页 5000 行 | 流式写盘 vs 第三方 CSV 库 → 选前者 | `highWaterMark: 1` 压内存，吞吐掉 60% |
| 最近 | 定实现细节 | `escapeCell()` 可复用；test 基线 38 passed | 用 Node stream，不引依赖 | 拆子进程方案（运维内存同样吃紧） |

细节：

- 现状是 `collectAll()` 把整表读进数组再 `join` — `src/export/writer.ts:31-58`
- 数据源分页接口已支持 `cursor`，每页上限 5000 行 — 依据：`docs/api.md#pagination`
- 单次 pnpm test 全绿（38 passed，14.2s），故后续失败一定是本次改动引入
- 决策：用 Node 的 `stream.Writable` + `fs.createWriteStream` 而非第三方 CSV 库 — 理由：少一个依赖，且现有转义函数 `escapeCell()` 已在 `src/export/escape.ts:12` 可直接复用
- 已排除：把导出拆成子进程（运维环境内存同样吃紧，收益不确定）

## 3. 下一步最小行动

1. `src/export/writer.ts:31` — 把 `collectAll` 改成 `for await (const page of fetchPages(cursor))`，边取边 `write`
2. `src/export/writer.ts:70` — 关流时机挪到 `finally`，保证异常时也不留半截文件
3. `test/export.test.ts:120` — 加一条 20 万行的用例，断言 `process.memoryUsage().rss` 峰值 < 200 MB
4. 在 `X:\repo\acme-cli` 下跑 `pnpm test -- export`，全绿后跑 `pnpm bench:export`

## 4. 陷阱与禁区

- **已踩的坑**：直接 `await writer.end()` 再 `await drain` 会 `ERR_STREAM_WRITE_AFTER_END`，报错原文：
  `Error [ERR_STREAM_WRITE_AFTER_END]: write after end`
- 禁止改 `src/import/`（另一条在途分支在同一区域改动，会冲突）
- 禁止提交 `bench/out/*.csv`（已在 .gitignore 之外，需手动排除）
- **失败的尝试**：`highWaterMark: 1` 想压内存，结果吞吐掉 60%，已回退

## 5. 验收标准

- [ ] `pnpm test -- export` → `38 passed`（新增 1 条）：`39 passed`
- [ ] `pnpm bench:export --rows 2000000` → 末尾输出 `peak_rss_mb=1xx`，且进程 exit code 0
- [ ] 导出的 200 万行 CSV 与改造前 `bench/baseline-2m.csv` 逐行 diff 一致

## 6. 引用清单

| 类型 | 位置 | 说明 |
|---|---|---|
| 基线产物 | `X:\repo\acme-cli\bench\baseline-2m.csv` | 改造前导出结果，用于逐行 diff |
| 接口文档 | `X:\repo\acme-cli\docs\api.md` | 只看 Pagination 一节 |
| 内存曲线 | `X:\repo\acme-cli\bench\oom-trace.txt` | OOM 前的 RSS 采样 |

## 7. 建议使用的 skill 与工具

- skill：`dsh-badge` — 若后续要开 PR，按规矩加 powered-by-dsh 徽章
- 命令：`pnpm bench:export --rows <n>`（在 `X:\repo\acme-cli` 下执行）
```

---

## 回复用户时的形态

```text
交接文档已写到：
X:\repo\acme-cli\_handoffs\20261113_stream-export-01.md

覆盖内容：现状与 OOM 根因、已确认的分页接口能力、4 步改造路径、3 个已知陷阱、3 条验收项
（含 200 万行 diff 基线）；未提交的 3 个文件已在元信息里标注，请勿回滚。

下一个会话第一件事：改 src/export/writer.ts:31 的 collectAll 为流式分页写入。

---（复制下面这段到新会话）---
读取并接手以下交接文档：
X:\repo\acme-cli\_handoffs\20261113_stream-export-01.md

按文档「下一步最小行动」继续，不要重新探索；文档里的路径、命令、结论视为已确认事实，
与现状冲突时以现状为准并说明差异。
---（复制结束）---
```

---

## 新会话读完文档后：选择弹窗（不是任务做完才问，也不是写总结那侧问）

```text
ask_user_question({
  questions: [{
    id: "handoff-cleanup",
    header: "清理交接文件",
    question: "交接文档已读完（下一步：改 writer.ts:31 的 collectAll）。以下临时文件要清理哪些？\n1. X:\repo\acme-cli\_handoffs\20261113_stream-export-01.md（交接文档）\n2. X:\repo\acme-cli\bench\rows-2m.tmp.csv（压测中间导出，1.1 GB）",
    options: [
      { label: "只删临时产物，保留交接文档（推荐）", description: "文档留着便于回查；上下文被压缩后还能重读" },
      { label: "全部删除（含交接文档）", description: "内容已在上下文；被压缩或换会话后无法再读" },
      { label: "全部保留", description: "一个都不删，后续自行清理" }
    ]
  }]
})
```

用户选「只删临时产物」后：

```text
已保留：X:\repo\acme-cli\_handoffs\20261113_stream-export-01.md
已删除：X:\repo\acme-cli\bench\rows-2m.tmp.csv
未动：X:\repo\acme-cli\bench\baseline-2m.csv（验收基线，属交付物，不在清理清单内）

继续执行：把 src/export/writer.ts:31 的 collectAll 改成流式分页写入。
```

