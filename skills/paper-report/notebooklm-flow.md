# NotebookLM 路径：≥ 4 篇论文的跨文档综合

本文件由 SKILL.md 阶段 2 在论文数 ≥ 4 时触发加载。

## 触发条件

- 阶段 1 确认后的候选论文集合规模 **≥ 4 篇**
- 用户未在闸门明确要求"强制走 Claude 直读"

## 设计原则

- paper-report skill 负责**编排**（什么时候做什么、积木怎么装配）
- `notebooklm` skill 负责**执行**（API 调用、CLI 命令）
- 二者通过 Skill 工具组合，paper-report **不**复制 notebooklm 的 CLI 知识

## 工作流

### 步骤 1：路径前置确认 + 环境检查 + 创建 Notebook

1. 在对话中向用户报告："候选 N 篇论文 ≥ 4，将走 NotebookLM 路径（预计 5-15 分钟，需上传 PDF）。回复 `OK` 继续，回复 `直读` 退回 Claude 卡片直读"
2. 用户回 `OK` 后，**按此顺序检查环境**：
   - **不要用 `notebooklm status`** —— 它只显示本地 cached context，即使 auth 失效也返回成功（实测陷阱）
   - 真正的 auth 检查：`notebooklm auth check --test`（含网络测试）
   - 或尝试一次轻量 API 调用：`notebooklm list --json`；失败则 auth 失效
3. 若中文输出需求明确：`notebooklm language set zh_Hans`（全局设置，只需首次）
4. 创建 notebook，命名 `paper-report-<主题简称>-<YYYYMMDD>`
   - ⚠️ **debug 时不要加 `--json`** —— 实测 create 命令在 `--json` 模式下错误信息会被吞成空串，先不带 `--json` 跑能看到真实 stderr
   - 成功后记录 `notebook-id` 用于后续清理
5. 用户回 `直读`：跳过 NotebookLM，按 Claude 直读路径继续，在 report 末尾标注"用户主动选择直读"

### 步骤 2：上传 PDF + 等待索引（**不要跳过 source wait**）

调用 `notebooklm` skill 上传 `raw/pdf/<论文文件名>.pdf`：

| 上传哪个 | 理由 |
|---|---|
| ✅ `raw/pdf/*.pdf` | PDF 含图表、公式、原始版面，NotebookLM 可解析 |
| ❌ `wiki/papers/*.md` | 卡片是已浓缩的二手提炼，丢图表，会让 NotebookLM 的优势消失 |

**关键要求**：每个 PDF 上传完**必须显式等待索引完成**：

```bash
notebooklm source add <pdf-path> -n <notebook-id> --json    # 返回 source_id
notebooklm source wait <source_id> -n <notebook-id> --timeout 600
```

不等 wait 直接进 ask 会导致 "source not ready" 错误。批量上传时可用子 agent 并行 wait（参考 notebooklm skill 的"Bulk Import with Source Waiting"模式）。

⚠️ **wait 误报处理**：`source wait` 可能返回 `RPC GET_NOTEBOOK failed / Connection timed out` 但**索引其实已完成**（网络抖动常见）。**不要立即 Fallback A**——先用 `notebooklm source list --json -n <notebook-id>` 复核：若对应 source 的 `status` 字段是 `"ready"` 即可继续，只有确认 `status != "ready"` 超过 600s 才触发 Fallback A。

索引超时 > 600s（list 复核仍非 ready） → 触发 Fallback A。

### 步骤 3：按积木分别发送查询

**关键设计**：不是一次发"请综合分析这 N 篇论文"，而是**为每个选中的积木独立发送 1 次查询**。这样能保证：
- NotebookLM 的 citation 直接对齐到具体积木
- 每个积木内容专注，避免一次响应过长导致质量下滑
- 失败可重试单个积木，不必整轮重跑

发送命令：`notebooklm ask "<query>" --json -n <id> 2>/dev/null > <file>`。`2>/dev/null` 分离 stderr，避免污染 JSON。

查询模板：

```
[本次查询目标积木]：{{积木名}}
[积木执行规则]：{{blocks/<name>.md 的 micro-prompt 全文}}
[用户原始问题]：{{Q}}
[输出要求]：
  1. 严格按积木的 micro-template 输出 markdown
  2. 表格类积木（matrix / resource-table / taxonomy）行首列填**论文短名**（如 `Li_2026`），步骤 4 会转 wikilink
  3. 不写导言、总结、寒暄
```

按积木装配顺序依次发送：陈列型在前，提炼型在后。

单次 query 瞬时失败（返回 `{"error":true}` 或 timeout）→ 重试 1 次；第 2 次仍失败 → 触发 Fallback B（该积木单独退回 Claude 直读）。

### 步骤 4：整合输出 + Citation 处理

`notebooklm ask --json` 返回 `{answer, references[{source_id, citation_number, cited_text}]}`。NotebookLM 的 `[N]` 可能与行归属错配，不可信赖做 per-cell attribution。按积木类型分流处理：

| 积木类型 | citation 处理 |
|---|---|
| 表格类（matrix / resource-table / taxonomy） | **剥离所有 `[N]`**（regex `\s*\[[\d,\s\-]+\]`）；表格首列短名经 `pdf_path ↔ source_id ↔ 卡片名` 映射转 `[[wikilink]]`。归属由行语义承担 |
| 提炼型（gap-ranking / tradeoff / attribution） | 尝试 `[N]→[[wikilink]]`（`citation_number → source_id` 取 refs 列表首次命中），人工审阅一遍；若"依据出处"与描述逻辑不符，改引 matrix 行归属（"见上文 X 表 Y 行"） |

Python 解析（稳健跳过可能的 stderr 前缀）：

```python
import json
content = open(path, encoding='utf-8').read()
data = json.loads(content[content.find('{'):])
```

**积木使用记录段必须声明 citation 策略**：剥离 / 转换 / 降级到行归属，三选一并标明涉及条数。

### 步骤 5：清理

⚠️ **正确的删除命令**：

| 命令 | 状态 |
|---|---|
| `notebooklm delete -n <id> -y` | ✅ 正确（`notebooklm delete --help` 实测确认） |
| `notebooklm notebook delete <id>` | ❌ 不存在（实测报 `No such command 'notebook'`）|

执行：
```bash
notebooklm delete -n <notebook-id> -y
```

`-y` 跳过交互式确认；不带 `-y` 时 CLI 会提示确认。

**触发时机（无论成功失败都要 cleanup，CLAUDE.md 核心约束）**：
- 步骤 3-4 全部成功 → cleanup ✓
- 单积木查询失败（Fallback B）→ 已完成的部分用 NB，整体仍 cleanup ✓
- 用户中途取消（Fallback C）→ 立即 cleanup ✓
- **Fallback A 但 create 已成功**（认证仍有效但 source 上传失败 / 索引超时等）→ 仍 cleanup ✓
   ⚠️ 这是最易漏的场景：LLM 看到错误倾向直接走 fallback，忘了已经 create 出 notebook
- 进程异常 / 网络断开 → 下次会话发现遗留 notebook 时手动 cleanup

**清理验证（推荐）**：
```bash
notebooklm delete -n <notebook-id> -y
notebooklm list --json | grep -q '"id": "<notebook-id>"' && echo "CLEANUP_FAILED" || echo "CLEANUP_OK"
```

**清理失败的处置**：
1. 重试一次 `notebooklm delete -n <notebook-id> -y`
2. 仍失败 → 在 report 末尾"积木使用记录"段**显式标注**：
   > ⚠️ NotebookLM cleanup 失败：notebook-id `xxx`，请用户手动 `notebooklm delete -n xxx -y` 清理
3. **绝不静默吞掉**——这是 CLAUDE.md 核心约束的兜底

## Fallback 策略

| Fallback | 触发条件 | 退化路径 |
|---|---|---|
| **A** | 任一 NB 基础设施不可用：<br>• 认证失效（auth check 失败）<br>• `create` / `source add` 空错误（`--json` 吞错；先重试不带 `--json`）<br>• 索引超时（> 600s）<br>• **网络阻断**（GFW 等环境下 Playwright 无法访问 `accounts.google.com`；HTTP_PROXY 环境变量通常不被 Playwright Chromium 继承） | 退回 Claude 直读卡片 + report 末尾标注"NotebookLM 不可用，原因 X" |
| **B** | 单积木查询失败（NotebookLM 报错 / `GENERATION_FAILED` / 响应质量劣化） | 该积木单独退回 Claude 直读，其他积木仍走 NB |
| **C** | 用户中途取消 | 已上传的 notebook 立即清理；若已部分查询，按现有内容写 report 并标注"用户中断" |

### Fallback A 的网络阻断子类型（基于 GFW 地区实测）

**症状**：`notebooklm login` 报错 `playwright._impl._errors.TimeoutError: Page.goto: Timeout 30000ms exceeded` 在访问 `accounts.google.com` 时。

**诊断**：
1. 先测代理本身是否工作：`curl -x http://<proxy-ip>:<port> https://www.google.com --max-time 10 -I`
2. 代理 OK 但 notebooklm login 仍 timeout → Playwright Chromium 没继承系统代理（即使设置 `HTTP_PROXY` / `HTTPS_PROXY` 环境变量也可能无效——这是 notebooklm CLI 的 playwright launch 不显式传 proxy 参数导致）

**解决顺序**：
1. 尝试 `NOTEBOOKLM_AUTH_JSON` 注入（从有代理环境的浏览器导出 cookies 后写入环境变量，绕开 login 步骤）—— 最稳但最繁琐
2. 或修改 notebooklm 源码在 playwright launch 加 `proxy={server: ...}` —— 需读代码
3. **实际推荐**：直接 **Fallback A → Claude 直读**，不在 skill 层修 playwright 代理问题。这是运行环境问题，修它不会让 skill 更可靠

Fallback 触发后不暴力中断流程，**always** 完成 report 写入并诚实标注降级。

## 与 Claude 直读路径的差异

| 维度 | NotebookLM 路径 | Claude 直读路径 |
|---|---|---|
| 数据源 | PDF 全文（含图表） | MD 卡片（已结构化提取） |
| 信息完整度 | 高（图表数据可识别） | 中（卡片提炼时丢图表） |
| 跨论文比较深度 | 高（NotebookLM 多文档检索） | 中（卡片是已浓缩二手） |
| Citation 精度 | 高（页/段落级 `references` 带 `cited_text`） | 中（论文级） |
| 时间成本 | 高（5-15 分钟） | 低（秒级） |
| 用户操作成本 | 中（需确认 + 等待） | 零 |
| 环境依赖 | 网络可达 Google + Playwright 代理配置 | 无 |
| 适用 | ≥ 4 篇 / 需图表数据 / 需精确 citation / 能连 Google | 2-3 篇 / 卡片信息已足 / 快速验证 / GFW 环境 |

## 在 report `积木使用记录` 段的标注规范

`路径` 行根据实际情况写：

| 实际情况 | 标注 |
|---|---|
| NB 完整跑完 + 清理成功 | `NotebookLM (notebook-id: xxx, 已清理)` |
| NB 跑完但清理失败 | `NotebookLM (notebook-id: xxx, ⚠️ 清理失败请手动清)` |
| Fallback A（认证失效）| `NotebookLM 不可用 (auth check 失败) → 退回 Claude 直读` |
| Fallback A（网络阻断）| `NotebookLM 不可用 (GFW 阻断 Playwright 访问 Google; HTTP_PROXY 未被继承) → 退回 Claude 直读` |
| Fallback A（其他）| `NotebookLM 不可用 (原因: X) → 退回 Claude 直读` |
| Fallback B | `NotebookLM 部分可用：积木 [X, Y] 走 NB；积木 [Z] 退回 Claude 直读` |
| Fallback C | `用户中断 NotebookLM 流程；已完成积木: [...]；剩余积木未填充` |
| 用户主动选直读 | `用户主动选择 Claude 直读路径（论文数 N ≥ 4 但跳过 NB）` |
