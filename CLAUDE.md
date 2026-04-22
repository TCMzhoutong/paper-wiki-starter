# Paper Wiki — Claude Code 工作流规则

## 环境初始化

新电脑首次使用：运行 `./setup.sh`，然后 `notebooklm login` 完成认证。

## 项目结构

```
paper_wiki/
├── raw/pdf/         ← 原始 PDF（只读）
├── raw/md/          ← MinerU 转的高质量 MD（只读，qmd 索引此目录）
├── wiki/papers/     ← 论文精读卡片
├── wiki/concepts/   ← 概念页
├── wiki/reports/    ← 研究报告（跨论文综合分析）
├── wiki/ideas/      ← idea 卡片（主动产出的研究方向）
├── wiki/experiments/ ← experiment 卡片（可照抄的实验方案）
├── papers-draft/    ← 论文写作工作区（每个项目一子目录，input/notes/figures/output）
├── schema/prompts/  ← 各类模板（NotebookLM / Claude）
├── CLAUDE.md        ← 本文件
└── architecture.md  ← 架构说明
```

## 意图识别与流程触发

根据用户输入自动判断并执行对应流程。不确定时，优先询问用户意图。

| 触发信号 | 执行流程 |
|---|---|
| 精读、新增论文、add paper、批量精读、继续精读 | → 新增论文流程 |
| 跨论文综合分析、对比、总结、哪些论文提到了 X、写 report、`/report` | → 研究查询流程（用 `paper-report` skill） |
| 找 idea、找研究方向、找新点子、帮我想 idea、`/idea`、`/paper-idea` | → 找 idea 流程（用 `paper-idea` skill） |
| 实验方案、实验设计、复现 X、baseline 配置、metric 选型、`/experiment` | → 实验方案借鉴流程（用 `paper-experiment` skill） |
| 写论文、起草、把实验结果整理成 paper、`/write`、`/paper-write` | → 论文写作流程（用 `paper-write` skill） |
| 删除论文、移除、remove paper | → 删除论文流程 |
| 检查wiki、校验、lint、死链、健康检查 | → 校验维护流程 |

## 新增论文流程

1. PDF 放入 `raw/pdf/`
2. `./add-paper.sh raw/pdf/论文.pdf` — MinerU 转 MD + qmd 索引
3. **endnote-cli 提取元数据** — `endnote-cli search quick "<论文标题关键词>"` 或 `endnote-cli item get <id>` 获取 title、authors、year、venue、doi、reference_type、type_of_work
4. **NotebookLM 精读** — 按 `schema/prompts/notebooklm/paper-review.md` 四步提问。优先使用 NotebookLM（读原始 PDF 更完整、Gemini 免费省 token）。**Fallback**：认证过期时 Claude 直接读 `raw/md/` 生成卡片，提醒用户图表信息可能不完整
5. **Claude 阶段 A** — 加载 `wiki/concepts/` 全部规范名和 aliases 到上下文
6. **Claude 阶段 B** — 生成论文精读卡片到 `wiki/papers/`，`[[X]]` 按保守策略规范化
7. **Claude 阶段 C** — 扫尾：alias 回写已有概念页 + stub 创建新概念页
8. **清理 NotebookLM** — `notebooklm delete -n <notebook-id> -y` 删除本次精读创建的 notebook（`-y` 跳过交互式确认）

三阶段详细规则见 `schema/prompts/claude/paper-card.md`。

> **前置条件**：论文须先在 EndNote 库中有题录。新论文先在 EndNote 中导入，关闭 EndNote 后再执行流程。

> **wiki 不手动维护"相关论文"章节**（无论论文卡片还是概念页）。所有论文↔概念的关联由 Obsidian 双链自动追踪。

## 研究查询流程

**由 `paper-report` skill 负责**（`~/.claude/skills/paper-report/`）。

Skill 内置 3 阶段流程：
1. **检索** — obsidian backlinks（高精度）+ qmd query（高召回）的缓存金字塔 + 综述论文优先深读 + 意图歧义检查 + 强制人机校验闸门
2. **分析** — 意图识别（GAP_FINDING / LANDSCAPE / RESOURCE_COMPARE / METHOD_COMPARE / EVOLUTION / ATTRIBUTION / TAXONOMY / OTHER）+ 积木装配（matrix / timeline / gap-ranking / tradeoff / attribution）
3. **写入** — 按 `report-template.md` 套骨架写入 `wiki/reports/<主题>_<日期>.md`

论文数 ≥ 4 时自动走 NotebookLM 路径（详见 skill 内 `notebooklm-flow.md`；Fallback 策略完整覆盖认证失效、网络阻断、索引超时等场景）。

**规则单一来源**：以 skill 的 `SKILL.md` / `meta-prompt.md` / `blocks/` / `notebooklm-flow.md` 为准。CLAUDE.md 不重复 skill 规则，避免双源漂移。

## 找 idea 流程

**由 `paper-idea` skill 负责**（`~/.claude/skills/paper-idea/`）。

Skill 内置 5 阶段流程：
1-2. **调用 paper-report** 产出支撑 report（强制 GAP_FINDING + matrix/gap-ranking/tradeoff 积木）
3. **信号扫描** — 按 `signal-scanner.md` 的 7 类信号抽取候选
4. **用户挑选** — 候选清单 ≠ idea 卡；必须由用户从候选中挑选（绝不自动落盘）
5. **写入** — 前置回读 `raw/md/` 取细节，再按 `ideas-template.md` 写入 `wiki/ideas/<短标题>_<日期>.md`

**规则单一来源**：以 skill 的 `SKILL.md` / `signal-scanner.md` / `ideas-template.md` 为准。CLAUDE.md 不重复 skill 规则。

## 实验方案借鉴流程

**由 `paper-experiment` skill 负责**（`~/.claude/skills/paper-experiment/`）。

Skill 内置 5 阶段流程：
1-2. **调用 paper-report** 产出支撑 report（强制 METHOD_COMPARE + matrix/tradeoff 积木）
3. **信号扫描** — 按 `experiment-scanner.md` 的 6 类"可抄素材"信号抽取候选
4. **用户挑选** — 多选时可显式 `合并` 或 `分开`
5. **写入** — 5.0 实验类型识别（computational/animal/clinical/in-vitro/omics/mixed/other）→ 5.1 qmd 前置回读 raw/md → 5.2 按 `experiment-template.md` 的通用骨架 + 类型变体写入 `wiki/experiments/<短标题>_<日期>.md` → 5.3 若衍生自某 idea 卡，回写该 idea 的 `linked_experiments` 字段

**规则单一来源**：以 skill 的 `SKILL.md` / `experiment-scanner.md` / `experiment-template.md` 为准。CLAUDE.md 不重复 skill 规则。

## 论文写作流程

**由 `paper-write` skill 负责**（`~/.claude/skills/paper-write/`）。

Skill 内置 5 阶段流程：
0. **立项意图识别** — 从 wiki/ideas/ 或 wiki/experiments/ 衍生，或独立项目
1. **Bootstrap + Wiki 注入** — 调 `paper-bootstrap`，project_truth 追加 Wiki Context 段
2. **结果翻译** — 调 `results-analysis` 填 result_summary.md（只翻译真实实验结果）
3. **起草** — 调 `scientific-writing`，三级级联检索 reports → papers → raw/md；冷启动自动调 paper-report
4. **优化 + 验证** — 调 `manuscript-optimizer`（术语挂 wiki/concepts/）+ `citation-verifier`（引用挂 wiki/papers/）
5. **投稿预检** — 调 `submission-audit` + 内置 unlink → `submission.md` + `submission.bib`；返修调 `rebuttal-response`

工作区：`papers-draft/<slug>/`，不进 qmd 索引；双链单向 draft → wiki，投稿前 Phase 5 unlink 全部 strip。

**消歧**：整篇端到端走 paper-write；单点改图/改引用/改 rebuttal/投稿预检直接用对应 Nature skill。

**规则单一来源**：以 skill 的 `SKILL.md` 及其子文件为准。项目内速查见 `schema/prompts/claude/paper-write-fusion.md`。CLAUDE.md 不重复 skill 规则。

## 删除论文流程

1. **影响清单** — 列出要删的卡片、引用该论文的 reports、引用该论文的 ideas、引用该论文的 experiments（`related_papers` 字段），用户确认后执行
2. **删除卡片和源文件** — 删 `wiki/papers/` 卡片、`raw/pdf/` PDF、`raw/md/` MD 及其 images
3. **检测孤页** — `obsidian orphans` 检查删除后是否产生无入链的概念页或悬空 idea / experiment
4. **清理孤页** — 删除孤页概念文件；清理其他文件中指向孤页的 `related` / `related_papers` 引用；idea / experiment 卡的 `related_papers` 悬空时由用户决定是否归档（idea 改 `status: shelved`；experiment 改 `status: abandoned`）

操作前列出完整影响清单，用户确认后执行。

## 校验维护流程

**触发条件**：用户主动触发（"检查wiki"/"校验"），或满足以下任一自动提醒条件：
- 每新增 20 篇精读卡片后
- 批量导入论文后
- concept 数量超过 200 且距上次审计超过 30 天

**成功标准**：全部步骤完成后，`audit` 输出 0 个 ERROR，`obsidian unresolved` 输出 0 个悬空链接。WARNING 和 REVIEW 级别由用户确认后标记为"已审查、保留"即可。

1. `obsidian orphans` — 列出无入链的孤页（含 idea 卡是否被 report / 实验笔记反向引用）
2. `obsidian unresolved` — 列出悬空的 `[[X]]`（链接目标不存在）
3. `obsidian deadends` — 列出无出链的死端页
4. **概念健康审计** — 三步走：
   - `python scripts/concept-audit.py audit`（规则检测。概念数 ≥200 时加 `--semantic`）
   - Claude 审查候选清单，逐对做语义判断（同义→合并 / 上下位→保留 / 不相关→保留）
   - 确认后 `python scripts/concept-audit.py merge <保留> <删除>`（批量用 `merge --batch plan.json`，先 `--dry-run` 预览）
5. **Idea 健康盘点**：
   - Grep `wiki/ideas/` 找 `status: brainstorm` 且 date 超过 30 天的 idea → 提示用户重评或改 `shelved`
   - Grep 找 `status: shortlisted` 但 `novelty: unchecked` 的 idea → 提示必须先做 novelty 检查
6. **Experiment 健康盘点**：
   - Grep `wiki/experiments/` 找 `status: planned` 且 date 超过 60 天的 experiment → 提示用户启动或改 `abandoned`
   - Grep 找 `status: running` 且末更新超 30 天的 → 提示补"进度日志"段
   - 检查 `source_idea` 字段指向的 idea 卡是否存在，且 idea 卡的 `linked_experiments` 字段是否对称包含本 experiment（双向链接一致性）
7. 输出问题清单，用户确认后修复

## 格式规范

写 `wiki/` 下任何文件时，frontmatter、双链、命名规则见 `schema/prompts/wikilink-format.md`。

### 核心约束

- **禁止通过 Claude 重命名或移动 `wiki/` 下的文件**。重命名由用户在 Obsidian 操作，让 Obsidian 自动更新引用
- 写 `[[X]]` 前必须先加载现有规范名和 aliases 映射
- **Skill 优先**：研究查询和找 idea 两类流程，必须通过 `paper-report` / `paper-idea` skill 执行，不要绕开 skill 手动跑。skill 内置的意图识别、积木装配、Fallback 策略是可审计可追溯的，手动跑等于丢失这些保障
- **NotebookLM 笔记必须 create → 用 → delete 完整闭环**：任何 `notebooklm create` 之后**必须**配对 `notebooklm delete -n <id> -y`。即使中途流程出错（用户中断 / 单步失败 / 异常退出），也要尝试清理。原因：保持 NotebookLM 账户干净，避免临时 notebook 累积占用配额。Cleanup 失败时必须显式记录 notebook-id 让用户手动清，不可静默吞掉
- **endnote-cli 是 frontmatter 元数据的权威源**，不从 LLM 推测。写入操作须在 EndNote 关闭状态下执行。通过 Bash 调用（CLI 模式）
- **任何命令首次使用前必须 `--help` 实测**：CLI / MCP / 第三方 skill 提供的命令，文档里写的 syntax 不可盲信（包括 skill 自身的 quick reference table）。LLM 看到不确定 syntax 倾向走 fallback，结果是 skill 名义主路径从未被使用。详见 `~/.claude/skills/paper-report/SKILL.md` "命令使用铁律"段
