# 更新概念页 — Claude 格式化模板

## 调用场景

1. **Stub 创建**（被 paper-card.md 阶段 C 调用）：为新论文引入的新概念创建最小概念页
2. **Alias 回写**（被 paper-card.md 阶段 C 调用）：为语义等价的新变体追加 alias 到已有概念页

## 输入

NotebookLM 返回的单行概念记录，格式为：
```
概念名: 中文名 | 英文: 英文全称 | 缩写: X, Y | 定义: ... | 角色: ... | 关联: 概念2, 概念3
```
（由 `paper-review.md` 第 4 步生成）

## 输出

`wiki/concepts/概念名.md`（新建或更新 aliases）

## Stub 模板（新概念首次创建）

frontmatter 见 `schema/prompts/wikilink-format.md` 的"概念页"章节。`aliases` 必须包含从 NotebookLM 返回的英文全称和缩写。正文结构（最小字段）：

```markdown
# {{中文规范名}}

## 定义

{{NotebookLM 返回的"一句话定义"}}

## 相关概念

- [[相关概念1]] — {{从 NotebookLM "关联" 字段提取的关系描述}}
- [[相关概念2]] — {{同上}}
```

> 不含"相关论文"章节——论文与概念的关联由 Obsidian 双链自动追踪，无需手动维护。

## 回写 Alias（新变体发现）

若在处理新论文时发现某个新变体（如第一篇论文创建了 `大型语言模型`，aliases=[LLM]；第二篇论文出现 `Large Language Model`），Edit 已有概念页的 frontmatter，将新变体追加到 aliases 数组：

```yaml
# 改前
aliases: [LLM]

# 改后
aliases: [LLM, Large Language Model]
```

只追加，不删除已有别名。

## 执行规则

1. 先检查 `wiki/concepts/` 中是否已存在该概念页（按规范名精确匹配，再按 aliases 匹配）
2. 命中 → 仅做 alias 回写（如有新变体）
3. 未命中 → 按 Stub 模板新建
4. 概念名优先用中文作为文件名，英文和缩写放 aliases
5. 每个概念页至少链接 1 个相关概念
6. 参考 `schema/prompts/wikilink-format.md` 确保 frontmatter、双链、命名合规
