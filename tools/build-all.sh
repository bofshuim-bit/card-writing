#!/usr/bin/env bash
# 把 references/ 按固定顺序拼成 ALL-IN-ONE.md
# 用法：bash tools/build-all.sh
set -euo pipefail
cd "$(dirname "$0")/.."

OUT='ALL-IN-ONE.md'

files=(
  'references/de-novelization.md'
  'references/persona-template.md'
  'references/worldbook-blueprint.md'
  'references/statusbar-protocol.md'
  'references/style-presets.md'
  'references/pitfalls.md'
  'references/code-recipes.md'
  'references/review-checklist.md'
)
titles=(
  '大原则：去小说化'
  '人设模板：十一模块'
  '世界书：蓝绿灯与预算'
  '状态栏协议设计'
  '文风预设：按题材换'
  '技术落地与常见坑'
  '代码写法：三件套模板'
  '送审清单：平台三条退回标准'
)

{
  cat <<'HEADER'
# 写卡手艺 · 全量单文件版（card-writing）

> 本文件由 `tools/build-all.sh` 自动生成，请勿手改。改 `references/` 后重新构建。
> 平台：魅魔岛（MMD）新页沙盒 / 当前版旧页。世界书格式通用，人设结构与平台无关。
> 字段上限与 DOM 细节截至 2026-11 验证。许可：MIT。

## 目录

1. 大原则：去小说化
2. 人设模板：十一模块
3. 世界书：蓝绿灯与预算
4. 状态栏协议设计
5. 文风预设：按题材换
6. 技术落地与常见坑
7. 代码写法：三件套模板
8. 送审清单：平台三条退回标准
9. 交付前自检

---
HEADER

  for i in "${!files[@]}"; do
    n=$((i+1))
    printf '\n---\n\n# %d. %s\n\n' "$n" "${titles[$i]}"
    # 降级标题：## → ###，避免与外层 # 冲突
    sed -e 's/^## /### /' -e 's/^# /## /' "${files[$i]}"
    printf '\n'
  done

  cat <<'FOOTER'
---

# 9. 交付前自检

- [ ] 人设条目化，不是散文
- [ ] 去过小说化：叙述拆条目、形容词换行为、情绪换动作
- [ ] 无 Markdown 符号（协议里的 `[#键=值#]` 例外）
- [ ] 行为准则在最后，编号，每条一句
- [ ] 蓝灯 `constant:true` + `key:"[]"`，绿灯带具体关键词
- [ ] 蓝灯里有绿灯关键词名录
- [ ] 人设 + 蓝灯 ≤ 15000（超了过不了审核）
- [ ] 协议键名与界面读取一致
- [ ] 关系用文字档位
- [ ] 选项方向不同
- [ ] 文风规则与该题材匹配
- [ ] 每条设定只讲一件事
FOOTER
} > "$OUT"

echo "built $OUT ($(wc -c < "$OUT") bytes)"
