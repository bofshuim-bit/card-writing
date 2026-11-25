# 代码写法（旧页三件套）

> 平台：MMD 当前版旧页。字段上限、DOM 类名截至 2026-11 验证。
> 这一章只给「够用、能抄」的模板；更深的边界以 `tavern-mmd` / `mmd-card-dev` 为准。

---

## 一、先记住：一张卡 = 状态栏 + 若干条正则

```
statusbar 里放 token   →   每条 token 对应一条正则   →   替换成 <style> / HTML / <script>
【美化】               →   findRegex: 【美化】         →   <style>…</style>
<GC_UI>                →   findRegex: <GC_UI>          →   <style>…</style><gc-live-widget></gc-live-widget>
<GC_SCRIPT>            →   findRegex: <GC_SCRIPT>      →   <script>…</script>
```

**关键点**

- `findRegex` 就是**字符串**。写 token 就直接写 `【美化】`；要正则才写成 `/.../gi` 形式
- token 必须出现在 `statusbar` 里，否则那条规则永远不触发
- 一条正则只能替换一个 token；一个组件通常拆成 3 条（样式 / 结构 / 脚本）
- `<GC_SCRIPT>` 会被平台抽出并**整卡只跑一次**，所以脚本要自己保证幂等

真实卡的 statusbar 长这样：

```
【美化】【美化1】【美化2】【地图】【地图1】【地图2】【指南】<GC_SCRIPT>【建设】【游玩一】
```

---

## 二、数据层正则（必须一字不差）

这条是所有卡的公共基础，作用是**把 `[#键=值#]` 藏起来**：

**findRegex**

```
/\[#([^=\[\]#]+)=([^\[\]#]+)#\](?:\s|<br\s*\/?>)*/gi
```

**replaceString**

```html
<span class="z-live-data" style="display:none">[#$1=$2#]</span>
```

拆开看：

| 片段 | 作用 |
|---|---|
| `\[#` | 匹配 `[#` 开头 |
| `([^=\[\]#]+)` | 捕获键名，排除 `=` `[` `]` `#` |
| `=` | 等号 |
| `([^\[\]#]+)` | 捕获键值，排除 `[` `]` `#` |
| `#\]` | `#]` 结尾 |
| `(?:\s\|<br\s*\/?>)*` | 吞掉行尾换行或 `<br>` |
| `gi` | 全局 + 忽略大小写 |

**为什么必须这么写**

- 值里一旦出现 `[` `]` `#`，正则断在半截，页面就会残留 `[#xx=xx#]`
- 用 `*` 而不是 `+` 会让空值也匹配，容易误吞相邻行；这条用 `+` 是对的
- 忘了 `(?:\s|<br>)*`，数据行之间的换行会留在气泡里，变成一大片空白

---

## 三、锚点规则（GC_UI）

**findRegex**：`<GC_UI>`

**replaceString**

```html
<style>
gc-live-widget{display:block;width:100%;margin:0;padding:0}
.content:has(gc-live-widget){height:auto!important;min-height:0!important;max-height:none!important}
</style>
<gc-live-widget></gc-live-widget>
```

那两行兜底 CSS 不是装饰：平台会把气泡高度锁死，不撑开的话卡片底部会被裁掉。
`:has()` 在部分内核不支持，可以再加一条兜底：

```css
.content{height:auto!important;max-height:none!important}
```

---

## 四、引擎骨架（GC_SCRIPT）

最小可跑版本，抄了就能用：

```html
<script>
if (!window.__MyCardDefined) {
  window.__MyCardDefined = true;

  const STYLE = `
.root{color:#c8c0b8;font-family:sans-serif;box-sizing:border-box;padding:4px}
.card{background:#2a2724;border:1px solid rgba(200,150,120,.4);border-radius:12px;padding:14px}
.sec{font-size:11px;color:#c89578;font-weight:bold;margin:8px 0 6px;
     border-bottom:1px solid rgba(200,150,120,.25);padding-bottom:4px}
.line{font-size:11px;line-height:1.7}
.bar{height:7px;background:rgba(200,150,120,.15);border-radius:3px;overflow:hidden}
.fill{height:100%;background:linear-gradient(90deg,#5a4035,#c89578)}
.opts{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-top:10px}
.opt{padding:9px 6px;background:rgba(200,150,120,.08);
     border:1px solid rgba(200,150,120,.3);border-radius:10px;
     font-size:10px;color:#c8c0b8;cursor:pointer;text-align:center}
`;

  // 写进输入框（旧页：.chatMsgTextarea 里的 textarea）
  function getComposer() {
    return document.querySelector('.chatMsgTextarea textarea')
        || document.querySelector('.chat-input-scope textarea')
        || document.querySelector('textarea');
  }

  function appendToInput(text) {
    const el = getComposer();
    if (!el) return;
    const proto = el.tagName === 'TEXTAREA'
      ? HTMLTextAreaElement.prototype
      : HTMLInputElement.prototype;
    const setter = Object.getOwnPropertyDescriptor(proto, 'value').set;
    const old = String(el.value || '');
    setter.call(el, old.trim() ? old.replace(/\s+$/, '') + '\n' + text : text);
    el.dispatchEvent(new Event('input', { bubbles: true }));
    el.dispatchEvent(new Event('change', { bubbles: true }));
  }

  class MyCard extends HTMLElement {
    constructor() {
      super();
      this.attachShadow({ mode: 'open' });
    }

    connectedCallback() {
      if (this.rendered) return;      // 幂等：预览会重跑整卡
      this.rendered = true;
      const kv = this.extract();
      this.render(kv);
      this.clean();
    }

    // 1. 取数据
    extract() {
      const kv = {};
      const re = /\[#([^=\[\]#]+)=([^\[\]#]+)#\]/g;
      const box = this.closest('.item,.content,uni-view.content') || this.parentElement;
      if (!box) return kv;
      box.querySelectorAll('.z-live-data').forEach(n => {
        re.lastIndex = 0;
        const m = re.exec(n.textContent || '');
        if (m) kv[m[1].trim()] = m[2].trim();
      });
      // 兜底：span 被清空时从容器文本里捞
      if (!Object.keys(kv).length) {
        const t = box.innerText || box.textContent || '';
        let m2;
        re.lastIndex = 0;
        while ((m2 = re.exec(t))) kv[m2[1].trim()] = m2[2].trim();
        re.lastIndex = 0;
      }
      return kv;
    }

    // 2. 渲染
    render(kv) {
      const sr = this.shadowRoot;
      sr.innerHTML = '';
      const s = document.createElement('style');
      s.textContent = STYLE;
      sr.appendChild(s);

      const mk = (tag, cls, text) => {
        const e = document.createElement(tag);
        if (cls) e.className = cls;
        if (text != null) e.textContent = text;   // 数据一律 textContent
        return e;
      };

      const root = mk('div', 'root');
      const card = mk('div', 'card');

      if (kv['名']) {
        const h = mk('div', 'sec', kv['名']);
        if (kv['身份']) h.appendChild(mk('span', 'line', '　' + kv['身份']));
        card.appendChild(h);
      }

      // 进度条
      if (kv['炁'] !== undefined && kv['炁'] !== '') {
        const v = Math.max(0, Math.min(100, parseInt(kv['炁'], 10) || 0));
        card.appendChild(mk('div', 'line', '炁 ' + v + '/100'));
        const bar = mk('div', 'bar');
        const fill = mk('div', 'fill');
        fill.style.width = v + '%';
        bar.appendChild(fill);
        card.appendChild(bar);
      }

      // 竖线分隔的标签组
      if (kv['物']) {
        const wrap = mk('div', 'line');
        String(kv['物']).split('|').forEach(t => {
          t = t.trim();
          if (t) wrap.appendChild(mk('span', 'line', '「' + t + '」'));
        });
        card.appendChild(wrap);
      }

      // 选项：竖线前是按钮文字，竖线后是写进输入框的内容
      const opts = [];
      for (let i = 1; i <= 4; i++) {
        if (kv['选项' + String.fromCharCode(64 + i)]) opts.push(kv['选项' + String.fromCharCode(64 + i)]);
      }
      if (opts.length) {
        const grid = mk('div', 'opts');
        opts.forEach(o => {
          const parts = String(o).split('|');
          const label = (parts[0] || o).trim();
          const send = (parts[1] || o).trim();
          const b = mk('button', 'opt', label);
          b.onclick = ev => {
            ev.stopPropagation();
            appendToInput(send);
          };
          grid.appendChild(b);
        });
        card.appendChild(grid);
      }

      root.appendChild(card);
      sr.appendChild(root);

      window.__MyCardData = kv;   // 给侧边栏/其它规则读
    }

    // 3. 清残留
    clean() {
      const box = this.closest('.item,.content,uni-view.content') || this.parentElement;
      if (!box) return;
      const w = document.createTreeWalker(box, NodeFilter.SHOW_TEXT);
      const ns = [];
      while (w.nextNode()) ns.push(w.currentNode);
      ns.forEach(n => {
        if (!n.textContent) return;
        const p = n.parentElement;
        if (p && String(p.className).indexOf('z-live-data') >= 0) return;  // 别把数据擦掉
        if (/\[#[^\]]+#\]/.test(n.textContent)) {
          n.textContent = n.textContent.replace(/\[#[^\]]+#\]/g, '');
        }
      });
    }
  }

  customElements.define('my-card', MyCard);
}
</script>
```

---

## 五、写进输入框（最容易错的一步）

旧页的输入框是 **`.chatMsgTextarea` 里的 textarea**，`value=` 直接赋值发不出去。
上面骨架里已经有 `getComposer` / `appendToInput`，这里单独拆开讲清楚：

```js
function getComposer() {
  return document.querySelector('.chatMsgTextarea textarea')
      || document.querySelector('.chat-input-scope textarea')
      || document.querySelector('textarea');
}

function appendToInput(text) {
  const el = getComposer();
  if (!el) return;
  const proto = el.tagName === 'TEXTAREA'
    ? HTMLTextAreaElement.prototype
    : HTMLInputElement.prototype;
  const setter = Object.getOwnPropertyDescriptor(proto, 'value').set;
  const old = String(el.value || '');
  setter.call(el, old.trim() ? old.replace(/\s+$/, '') + '\n' + text : text);
  el.dispatchEvent(new Event('input', { bubbles: true }));   // 让框架同步
  el.dispatchEvent(new Event('change', { bubbles: true }));
}
```

三点：

1. **取到容器就废了**：`.chatMsgTextarea` 本身是 DIV，`value` 是 undefined
2. **必须派发 `input` 事件**，否则界面显示了、框架状态没变，点发送还是空的
3. 用原生 setter 而不是 `el.value =`，才能绕过受控组件

---

## 六、侧边栏 / 悬浮按钮

固定定位 + 竖排文字 + 滑出面板，这是所有侧栏的通用结构：

```css
.sb-trigger{
  position:fixed; right:0; top:38%; z-index:99999;   /* 旧页用 99999 没问题 */
  writing-mode:vertical-rl; letter-spacing:2px;
  padding:10px 6px; background:#5a4035; color:#d4a878;
  border-radius:6px 0 0 6px; cursor:pointer; font-size:12px;
}
.sb-panel{
  position:fixed; right:0; top:38%; z-index:99998;
  width:230px; max-height:70vh; overflow-y:auto;
  transform:translateX(105%); transition:transform .28s ease;
  background:rgba(30,28,26,.97); border-radius:8px 0 0 8px; padding:12px;
}
.sb-panel.open{ transform:translateX(0); }
```

```js
document.querySelector('.sb-trigger').onclick = function (e) {
  e.stopPropagation();
  document.querySelector('.sb-panel').classList.toggle('open');
};
```

- 面板和按钮 **z-index 差 1**，避免面板盖住按钮
- 竖排用 `writing-mode:vertical-rl`，不要去算 transform
- 点击事件一律 `stopPropagation()`，不然会冒泡到聊天气泡触发别的行为

---

## 七、全局美化

改的是这几个选择器（平台没有 `data-chat` 时就用它们）：

| 目标 | 选择器 |
|---|---|
| 页面背景 | `.chat` |
| AI 气泡 | `.chat .item .touch-scope .content.left` |
| 用户气泡 | `.chat .item .touch-scope .content.right` |
| 底部栏 | `.chat-bottom` |
| 输入框外壳 | `.chat-input-scope` |
| 发送按钮 | `.chat-bottom button` |

```css
.chat{ background:#1f1a14 !important; }
.content.left{
  background:linear-gradient(180deg,#2a2724,#221f1d) !important;
  color:#c8c0b8 !important;
  border:1px solid rgba(200,150,120,.35) !important;
  border-radius:12px !important;
}
.chat-bottom{ background:rgba(24,21,18,.98) !important; }
```

**规则**

- **颜色、背景、边框、圆角、阴影全部加 `!important`**；布局和尺寸尽量不加
- 用 CSS 变量集中管理配色，换肤只改一处：
  ```css
  :root{ --ink:#c8c0b8; --paper:#2a2724; --gold:#c89578; }
  ```
- 一个组件一条 `<style>` 规则，别把十几种美化塞进同一条（会顶到 20000 上限）

---

## 八、正则 JSON 的结构

导入文件只有这几个键：

```json
{
  "pageDepth": 2,
  "statusbar": "【美化】<GC_SCRIPT>",
  "beginning": "开场白",
  "personality": "人设",
  "regex_scripts": [
    {
      "id": 1,
      "scriptName": "美化",
      "findRegex": "【美化】",
      "replaceString": "<style>…</style>"
    }
  ]
}
```

**硬上限**

| 项 | 上限 | 超了会怎样 |
|---|---|---|
| `replaceString` | 20000 字符 | 编辑器静默拒存 |
| `findRegex` | 1000 字符 | —— |
| 规则数 | 130 条 | —— |
| `scriptName` | 20 字 | —— |
| `statusbar` | 200 字 | —— |
| `beginning` | 4000 字 | —— |
| `personality` | 10000 字 | —— |

**拆分原则**：一条替换超过 18000 就拆成两条，用不同 token（`【美化】` / `【美化1】`）。

---

## 九、常见 BUG 对照

| 现象 | 原因 | 修法 |
|---|---|---|
| 卡片完全不出现 | AI 没输出 `<GC_UI>`，或 token 不在 statusbar | 查 AI 输出 + 查 statusbar |
| 数据全是空 | 数据层正则没匹配 | 检查 `[#键=值#]` 是否紧贴、值里有没有 `[]#` |
| 页面残留 `[#xx=xx#]` | 同上 | 同上 |
| 卡片被裁一半 | 少了气泡高度兜底 CSS | 加 `.content:has(gc-live-widget)` 那段 |
| 点选项输入框没反应 | 直接用 `value=` 赋值 | 用原生 setter + `input` 事件 |
| 刷新后组件重复 | 没有幂等哨兵 | `if(!window.__X){window.__X=1;…}` |
| 预览时出现两个卡 | 没判 `this.rendered` | `connectedCallback` 开头 return |
| 头像撑满面板 | 平台全局 `img{width:100%}` | `width:30px!important` 等 |
| 侧栏点一下就没 | 事件冒泡到气泡 | `ev.stopPropagation()` |
| 台面文字变源码 | 反引号里放了 HTML | 反引号只包 CSS 字符串 |

---

## 十、自检清单

- [ ] 每个 token 都在 statusbar 里，且都有对应规则
- [ ] 数据层正则与第二节一字不差
- [ ] `<GC_UI>` 那条带气泡高度兜底
- [ ] 脚本有 `window.__X` 幂等哨兵
- [ ] `connectedCallback` 有 `this.rendered` 判断
- [ ] 数据只用 `textContent`，不用 `innerHTML`
- [ ] 输入框走原生 setter + `input` 事件
- [ ] 所有可点元素 `stopPropagation()`
- [ ] 单条 replaceString < 18000
- [ ] 规则总数 < 130
- [ ] 清理残留时跳过 `.z-live-data`
