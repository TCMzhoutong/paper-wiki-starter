# 元提示词：意图识别 + 积木选择

本文件由 SKILL.md 阶段 2 触发加载。按以下步骤执行。

## 步骤 1 — 识别问题意图

读用户的原始问题，归类到下表中一种或多种意图（多选时按主次排序）：

| 意图代码 | 含义 | 典型问句信号 |
|---|---|---|
| GAP_FINDING | 找科研空白 / 未做过的方向 | "还有什么没人做" / "研究空白" / "未来方向" / "找 gap" |
| LANDSCAPE | 领域全景 / 进展概览 | "X 领域研究进展" / "现状综述" / "目前都有哪些路径" |
| RESOURCE_COMPARE | 工具 / 数据集 / baseline 对比 | "数据集优劣" / "哪个 baseline 更合适" / "工具选型" |
| METHOD_COMPARE | 方法学横向对比 | "对比这几种方法" / "X 方法 vs Y 方法" / "方法异同" |
| EVOLUTION | 时间脉络 / 技术演进 | "X 是怎么演变的" / "几年来的发展" / "代际变化" |
| ATTRIBUTION | 因果 / 驱动因素归因 | "为什么 X 成为主流" / "是什么推动了 Y" |
| TAXONOMY | 代表工作分类 | "X 类工作可分几种流派" / "如何归类这些方法" |
| OTHER | 不属于上述 | 自由形式 + 文末必须标记 `block: uncategorized: <一句话描述>` |

**意图识别的判断原则**：
- 看动词，不看名词。"对比" → COMPARE；"演变" → EVOLUTION；"找/有什么没人做" → GAP_FINDING
- 多意图时主意图决定积木骨干，副意图增加 1 个积木
- 不强行归类：信号弱时归 OTHER，让积木库自然生长

## 步骤 2 — 选积木

Read `blocks/_index.md` 看积木库现状。选择规则：

1. **必选**：至少 1 个"陈列型"积木（matrix / timeline / resource-table / taxonomy）—— 提供事实底盘
2. **可选**：1-2 个"提炼型"积木（gap-ranking / tradeoff / attribution）—— 提供洞察
3. **总数控制**：2-4 个，超过 4 个会让 report 散乱
4. **意图 → 积木的推荐起点映射**（仅作起点，可调整）：

| 意图 | 推荐积木组合 | 当前状态 |
|---|---|---|
| GAP_FINDING | matrix + gap-ranking | ✅ 全可用 |
| LANDSCAPE | timeline + taxonomy | ⚠️ taxonomy 缺，临时用 matrix |
| RESOURCE_COMPARE | resource-table + tradeoff | ⚠️ resource-table 缺用 matrix；tradeoff ✅ |
| METHOD_COMPARE | matrix + tradeoff | ✅ 全可用 |
| EVOLUTION | timeline + attribution | ✅ 全可用（注意 timeline 的跨度自约束） |
| ATTRIBUTION | timeline + attribution | ✅ 全可用 |
| TAXONOMY | taxonomy | ⚠️ 缺，临时用 matrix（行=类别，列=代表工作） |
| OTHER | 自由形式 + 必须文末标记 | — |

⚠️ **缺失积木的处理铁律**：临时替代必须在 report 末尾"积木使用记录"段落显式标注"原本应用 X 积木，因缺失改用 Y"。**这个标注就是积木库扩充的需求来源，不要静默吞掉**。

## 步骤 3 — 装配

依次 Read 选中的积木文件 `blocks/<name>.md`，按其 micro-template 填充内容。

每个积木 = report "分析"一节中的一个 **h3 子节**。

装配顺序：陈列型在前，提炼型在后（让"事实"先于"洞察"）。

## 步骤 4 — 套骨架写入

Read `report-template.md`，把"分析"一节替换为装配好的积木块序列，写入：

```
wiki/reports/<主题简称>_<YYYY-MM-DD>.md
```

⚠️ **NotebookLM 路径下的差异**：若阶段 2 走的是 NotebookLM（论文数 ≥ 4），积木块由 NotebookLM 单独查询返回。装配前需按 `notebooklm-flow.md` 步骤 4 完成 citation 转换（[N] → [[wikilink]]）。

## 输出强制要求

写完后必须在对话中报告（不写进 report 文件，写进对话）：
- 识别的意图代码
- 选用的积木列表
- 是否有缺失积木被替代（具体替代关系）
- 是否触发了 OTHER 自由形式
- 候选论文确认闸门是否走过（YES / NO 跳过）

这是 skill 自审，便于用户审计 skill 行为是否符合预期。
