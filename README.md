# 写卡手艺（card-writing）

写 AI 角色卡时，人设、世界书、状态栏协议、文风该怎么写。只做**魅魔岛（MMD）**——新页沙盒与当前版旧页；世界书格式通用，人设结构与平台无关。

## 三种用法

### 1. 直接给 AI（最省事，推荐）

打开 [`ALL-IN-ONE.md`](ALL-IN-ONE.md)，全选复制，粘给任何 AI，然后说：

> 按这份规范，帮我写一张「XX 题材」的卡，带状态栏。

### 2. 给能读网页的 AI

仓库设为 public 后，把下面 URL 里的 `bofshuim-bit` 换成你的 GitHub 用户名，发给 AI：

```
https://raw.githubusercontent.com/bofshuim-bit/card-writing/main/ALL-IN-ONE.md
```

> 链接已按本仓库填好；fork 或改名后要把用户名和仓库名一起换。

### 3. 当 skill 安装

把整个目录放进 `skills/card-writing/`（`SKILL.md` 在根目录，`references/` 与它同级），
AI 按 `references/xxx.md` 的相对路径读取，装完即可用。

## 目录结构

```
SKILL.md               入口：开写前六问、流程、自检
README.md              本文件
LICENSE                MIT
ALL-IN-ONE.md          全部合并（脚本生成，给 AI 直接读）
references/
  de-novelization.md   去小说化六法 + 符号洁癖
  persona-template.md  十一模块人设模板
  worldbook-blueprint.md  蓝绿灯真值、字数预算、关键词索引
  statusbar-protocol.md   协议设计、键表、轮次、界面映射
  style-presets.md     十种题材文风 + 治 AI 腔
  pitfalls.md          12 个技术坑
  code-recipes.md      三件套代码模板（引擎/注入/侧栏/美化/JSON）
  review-checklist.md  送审清单（平台三条退回标准）
tools/
  build-all.sh         按顺序拼出 ALL-IN-ONE.md
```

## 改了 references 之后

```bash
bash tools/build-all.sh
```

会重新生成 `ALL-IN-ONE.md`，不用手工合并。

## 三条最容易踩的

- 蓝灯不是 `role:1`，是 `constant:true` + `key:"[]"`
- 绿灯的关键词必须先被 AI 说出来，所以蓝灯要放名录
- 关系用文字档位，别写"好感 87"

被拒的卡基本只有三类：

1. **有效设定不足 3000 字**（美化、状态栏、规则、示例不算）
2. **长段连续叙述 / 小说化**——换行不等于拆开，一段只讲一件事
3. **缺少成年声明**——标题或简介写「所有角色均已成年」

另外符号太多（`#` `*` `-` `>`）也会被判格式问题。详见 `references/review-checklist.md`。

## License

MIT
