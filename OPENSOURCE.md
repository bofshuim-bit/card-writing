# 怎么把这个 skill 发到 GitHub

手机也能做，全程十几分钟。

## 第 0 步：准备

需要一个 GitHub 账号。没有就去 github.com 注册。

## 第 1 步：建一个空仓库

1. 手机浏览器打开 `https://github.com/new`
2. **Repository name** 填 `card-writing`
   （名字要一致，README 里的 raw 链接写的就是它）
3. 选 **Public**
4. 下面三个勾选框**全部不勾**（README、.gitignore、license 都不要，我们有自己的）
5. 点 **Create repository**

建完会看到一个空仓库页面，先放着。

## 第 2 步：生成访问令牌（Token）

GitHub 不接受账号密码推送，要用 token。

1. 打开 `https://github.com/settings/tokens`
2. 点 **Generate new token** → 选 **Generate new token (classic)**
3. **Note** 随便写，比如 `card-writing push`
4. **Expiration** 选 90 days
5. 勾选 **repo**（这一项就够）
6. 拉到最下面点 **Generate token**
7. 复制那串 `ghp_...`

> 这串只显示一次，关掉页面就看不到了。丢了就重新生成一个。
> 它等于密码，**不要发给任何人，也不要提交到仓库里**。

## 第 3 步：推送

在手机的终端里（DSH 的侧边栏 Shell 或者 Termux）执行：

```bash
cd ~/skills/card-writing
GITHUB_TOKEN=把刚才的token粘在这里 bash tools/push-to-github.sh 你的GitHub用户名
```

例：

```bash
cd ~/skills/card-writing
GITHUB_TOKEN=ghp_abc123 bash tools/push-to-github.sh zhangsan
```

看到 `branch 'main' set up to track 'origin/main'` 就是成功了。

> 脚本里的 token 只用于这一次推送，不会写进 `.git/config`。
> 如果你用的终端不支持交互输入，就用这种环境变量的方式。

## 第 4 步：验证

浏览器打开：

```
https://github.com/你的用户名/card-writing
```

应该能看到 `SKILL.md`、`references/`、`ALL-IN-ONE.md`。

再验证 AI 直读链接（把用户名换掉）：

```
https://raw.githubusercontent.com/你的用户名/card-writing/main/ALL-IN-ONE.md
```

能打开就是成了。这个链接可以直接发给任何能读网页的 AI。

## 第 5 步：以后更新

改了 `references/` 里的东西之后：

```bash
cd ~/skills/card-writing
bash tools/build-all.sh          # 重新生成 ALL-IN-ONE.md
git add -A
git commit -m "update"
git push
```

第一次推送时如果没存凭据，push 会再问一次 token。

或者直接再跑一遍第 3 步的脚本，它会自动提交并推送。

## 常见问题

**Q：push 报 `Authentication failed`**
Token 错了、过期了，或者没勾 `repo`。重新生成一个。

**Q：push 报 `remote contains work that you do not have`**
建仓库时勾了 README。先 `git pull --rebase origin main` 再 push；
或者删掉仓库重建（不勾任何选项最省事）。

**Q：想让国内访问快一点**
Gitee 一样的命令，只把地址换成 `https://gitee.com/用户名/card-writing.git`。
但 Gitee 的 raw 链接格式不同，README 里那段要改成
`https://gitee.com/用户名/card-writing/raw/main/ALL-IN-ONE.md`。

**Q：token 泄露了**
去 `https://github.com/settings/tokens` 点 Delete 删掉，重新生成。仓库本身不受影响。

## 发出去之后

别人怎么用，README 里已经写了三种：

1. 打开 `ALL-IN-ONE.md` 复制粘贴给 AI
2. 发 raw 链接给能读网页的 AI
3. 整个目录丢进 `skills/card-writing/` 当 skill 用
