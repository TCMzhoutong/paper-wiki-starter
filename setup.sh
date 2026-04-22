#!/bin/bash
# setup.sh — 新电脑首次初始化
# 在 paper_wiki/ 目录下运行：./setup.sh
# 前提：已安装 conda, node.js, ollama

set -e
WIKI_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Paper Wiki 环境初始化 ==="
echo "Wiki 目录: $WIKI_DIR"

# 1. MinerU 环境
echo ""
echo "--- [1/6] 创建 MinerU conda 环境 ---"
if conda env list | grep -q "mineru"; then
    echo "mineru 环境已存在，跳过"
else
    conda create -n mineru python=3.12 -y
fi
conda run -n mineru pip install uv
conda run -n mineru uv pip install -U "mineru[all]"
# 安装 CUDA 版 PyTorch（覆盖默认 CPU 版）
conda run -n mineru pip install torch torchvision --force-reinstall --index-url https://download.pytorch.org/whl/cu128

# 2. MinerU 配置（符号链接到 home）
echo ""
echo "--- [2/6] 配置 MinerU ---"
if [ -f "$HOME/mineru.json" ]; then
    echo "~/mineru.json 已存在，备份为 ~/mineru.json.bak"
    cp "$HOME/mineru.json" "$HOME/mineru.json.bak"
fi
cp "$WIKI_DIR/mineru.json" "$HOME/mineru.json"
echo "已复制 mineru.json 到 ~/"

# 3. Ollama 模型
echo ""
echo "--- [3/6] 拉取 Ollama 模型 ---"
ollama pull gemma4 || echo "WARNING: ollama pull 失败，请手动运行 ollama pull gemma4"

# 4. qmd (MinerU Document Explorer)
echo ""
echo "--- [4/6] 安装 qmd ---"
npm install -g mineru-document-explorer

# 5. qmd 索引重建
echo ""
echo "--- [5/6] 重建 qmd 索引 ---"
cd "$WIKI_DIR"
qmd collection add "$WIKI_DIR/raw/md"
# 尝试重命名为 papers（如果已有同名则跳过）
qmd collection rename "$WIKI_DIR/raw/md" papers 2>/dev/null || true
qmd embed

# 6. NotebookLM
echo ""
echo "--- [6/6] 安装 NotebookLM CLI ---"
pip install notebooklm-py
echo "请运行 'notebooklm login' 完成 Google 认证"

echo ""
echo "=== 初始化完成 ==="
echo "接下来："
echo "  1. 运行 'notebooklm login' 完成认证"
echo "  2. 启动 qmd MCP: qmd mcp --http --daemon"
echo "  3. 从此目录启动 Claude Code: claude"
