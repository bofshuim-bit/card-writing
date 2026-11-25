# 技术落地与常见坑（MMD 新旧页）

> 平台细节（字段上限、DOM 类名、注入行为）截至 **2026-11** 验证。平台会更新，遇到对不上的以真机为准。

## 一、先分新旧页

| | 旧页（当前版） | 新页沙盒 |
|---|---|---|
| 标识 | `chatVersion` 缺省/0 | `chatVersion: 1` |
| 脚本来源 | 状态栏 token → 正则替换成 `<style>`/`<script>` | 规则同样注入，但有 sdk |
| 数据通道 | `[#键=值#]` → 隐藏 span → 自定义元素读 | 同左，或 sdk |
| DOM | `.chat .item .content.left`、`.chatMsgTextarea textarea` | `[data-chat]`、不同类名 |
| CSS | 常规 | 有 `!important` 与净化差异 |

**拿旧页经验写新页必爆**，反之亦然。动手前先确认是哪一代。

## 二、硬上限

| 字段 | 上限 |
|---|---|
| 单条 `replaceString` | 20000 字符（超了整次静默拒存） |
| `findRegex` | 1000 |
| 规则数 | 130 |
| `scriptName` | 20 字 |
| statusbar | 200 字 |
| beginning | 4000 字（官方写 10240 是错的） |
| personality | 10000 字 |
| 人设 + 100% 触发条目 | 15000 字符 |

## 三、常见坑（按出现频率）

### 1. 写了但没生效：卡片不出现 / 美化没上

现象：侧边栏脚本生效了，但状态卡不出现、美化没应用。
原因：注入依赖锚点（`<GC_UI>`）或状态栏里的 `<style>`，只要一处没被替换，整条链就断。
（不同平台/版本对消息正文的正则处理不一样，别假设它一定生效。）

解法：
- 美化用**脚本注入** `<style>`（`document.createElement('style')` + append 到 head），别放在状态栏 replacement 里
- 状态卡**自动挂载**：MutationObserver 监听聊天区，把卡 append 到最后一条 AI 消息末尾，不依赖锚点

### 2. 写进输入框发不出去

原因：直接 `textarea.value = text` 只改界面，没通知 React/Vue 的内部状态。

解法：原生 setter + 派发事件
```js
var proto = (el.tagName==='TEXTAREA') ? HTMLTextAreaElement.prototype : HTMLInputElement.prototype;
var d = Object.getOwnPropertyDescriptor(proto,'value');
d.set.call(el, text);
el.dispatchEvent(new InputEvent('input',{bubbles:true,inputType:'insertText',data:text}));
el.dispatchEvent(new Event('change',{bubbles:true}));
```

### 3. 取输入框取到了容器

`.chatMsgTextarea` 是**外层容器**，里面的 textarea 才是输入框。
```js
// 对
'.chatMsgTextarea textarea'
// 错
'.chatMsgTextarea'
```
取到 DIV 后 `value` 是 undefined，代码会静默失败。

### 4. 隐藏数据的 span 被自己清空

清理正文里的 `[#...#]` 时，别把 `.z-live-data` 里的隐藏数据也清掉：
```js
if (node.parentElement.className.indexOf('z-live-data') >= 0) return;
```

### 5. 卡片读到空数据

锚点在数据行之前时，自定义元素 `connectedCallback` 可能比数据 span 先执行。
解法：延迟 30ms 渲染，再补一次 420ms 后的重读。

### 6. 图片撑爆面板

平台常有 `img{width:100%}` 之类的全局样式。头像必须钉死：
```css
width:30px!important;height:30px!important;max-width:30px!important;max-height:30px!important;
flex:0 0 30px;object-fit:cover;object-position:center top;
```

### 7. 轮次算错

不要按 DOM 里的消息数量算（平台会插入系统消息、重发会复用节点）。
以 AI 输出的 `[#轮次=]` 为准，只在缺失时用位置兜底。

### 8. 世界书全是绿灯

`constant: false` 写成了默认值 → 全部变成关键词触发 → 固定传输只有一千多字。
蓝灯必须 `"constant": true` 且 `"key": "[]"`。

### 9. 绿灯光写了却没触发

蓝灯里没有点名绿灯的关键词。解法：蓝灯放一份名录。

### 10. `probability` 写成数字

必须是字符串 `"100.00"`，写 `100` 直接报错。

### 11. 卡片重复挂载

自动挂载前先查重：
```js
if (host.querySelector('gc-live-widget')) return;
```

### 12. 清理残渣把正文删了

`clean()` 的正则要限定在 `[#...#]` 内，别用宽泛的 `\[.*\]`。

## 四、验证方法

> 以下三项需要外部工具，**本 skill 不自带脚本**。没有工具就跳过，直接看第 4 条真机验证。

1. 若有校验脚本（如 `generating-role-card` 技能里的 `validate.mjs` / `validate-worldbook.mjs`）：
   跑一遍，目标 0 error（纯文本类 warn 可忽略）。
2. 若有 jsdom：模拟平台 DOM 跑一遍——卡片挂载、字段读取、点击写入、无报错。
3. **真机导入，只看三件事**：卡在不在、美化上没上、选项能不能写进输入框。这一条最准。

---

## 五、写卡时最容易踩的四个格式坑（真机验证）

### 1. 中文尖括号会被剥掉

平台会先剥 `<标签>` 再渲染。协议标记写成中文尖括号会整段消失：

```
✅ [#名=沈砚#]        ← 方括号
❌ <名=沈砚>          ← 会被当标签删掉
```

人设正文里的 `<世界观>…</世界观>` 是**给平台的章节标签**，可以写；
但**模型输出的数据行**必须用 `[#键=值#]`，两者别搞混。

### 2. 反引号里的 HTML 会变成页面文字

模板字符串、代码块用的 `` ` `` 在剥壳阶段会被占位保护、还原时不做解析，
症状是「源码直接印在页面上」。规则里写脚本时，反引号只用于模板字符串，别包 HTML。

### 3. 属性值里有 `]>` 会整条属性被删

```
❌ onclick="if(a[0]>1)"
✅ onclick="if(a[0] > 1)"     ← 比较运算符两侧留空格
```

### 4. 正则不能匹配空串

`/a*/` 这种会在每个字符位置插一次，瞬间炸掉输出预算（真机实测）。
写信标正则时用 `+` 不用 `*`。

---

## 六、世界书两个硬约束

- **条目标题 ≤ 20 字**（MMD 当前版超限 ERROR，沙盒 WARN）
- **新页沙盒的世界书必须独立交付**：根对象只留 `entries`，
  不能并进 6 键导入 JSON（顶层出现 `entries` 会判 ERROR）

---

## 七、参考来源

本文的技术结论整理自三个开源 skill，遇到冲突以这几个为准：

- `mmd-card-dev`（醉猫 / 黑洞猫雷达法）：三代平台分层、1100 行安全规则 v2.4
- `tavern-mmd`：源码逆向 + 真机探针、世界书工具链、platforms 文档
- `mmd-generating-role-card`：官方 authoring 四章 + persona-format + 校验脚本
