#!/usr/bin/env bash
# 把当前目录推送到 GitHub
# 用法：bash tools/push-to-github.sh <GitHub用户名> [仓库名]
#   仓库名默认 card-writing
set -euo pipefail

USER_NAME="${1:-}"
REPO="${2:-card-writing}"

if [ -z "$USER_NAME" ]; then
  echo "用法：bash tools/push-to-github.sh <GitHub用户名> [仓库名]"
  exit 1
fi

cd "$(dirname "$0")/.."

echo "== 1/5 初始化仓库"
git init -q 2>/dev/null || true
git branch -M main 2>/dev/null || true

echo "== 2/5 提交文件"
git add -A
if git -c user.email="$USER_NAME@users.noreply.github.com" \
       -c user.name="$USER_NAME" \
       commit -qm "update $(date +%F)" 2>/dev/null; then
  echo "   已提交"
else
  echo "   没有新改动，跳过提交"
fi

echo "== 3/5 确保远程仓库存在"
if [ -n "${GITHUB_TOKEN:-}" ]; then
  node - "$GITHUB_TOKEN" "$REPO" <<'NODE'
const https=require('https');
const [token,repo]=process.argv.slice(2);
const body=JSON.stringify({name:repo,private:false,
  description:'写卡手艺：人设/世界书/状态栏协议/文风/去小说化（MMD）'});
const req=https.request({hostname:'api.github.com',path:'/user/repos',method:'POST',
  headers:{'Authorization':'Bearer '+token,'User-Agent':'card-writing',
           'Accept':'application/vnd.github+json','Content-Type':'application/json',
           'Content-Length':Buffer.byteLength(body)}},r=>{
  let b='';r.on('data',c=>b+=c);r.on('end',()=>{
    if(r.statusCode===201)console.log('   已创建仓库');
    else if(r.statusCode===422)console.log('   仓库已存在，直接推送');
    else if(r.statusCode===401){console.log('   Token 无效（401）');process.exit(1);}
    else console.log('   创建返回 '+r.statusCode+'，继续尝试推送');
  });
});
req.on('error',e=>console.log('   网络错误：'+e.message+'（继续尝试推送）'));
req.write(body);req.end();
NODE
  [ $? -ne 0 ] && exit 1
fi

echo "== 3/5 设置远程地址"
git remote remove origin 2>/dev/null || true
git remote add origin "https://github.com/$USER_NAME/$REPO.git"
echo "   https://github.com/$USER_NAME/$REPO"

echo "== 4/5 推送"
if [ -n "${GITHUB_TOKEN:-}" ]; then
  # 用环境变量里的 token，不写进 .git/config
  git push "https://$USER_NAME:$GITHUB_TOKEN@github.com/$USER_NAME/$REPO.git" main:main
else
  echo "   没检测到 GITHUB_TOKEN，改用交互输入："
  echo "   用户名 = $USER_NAME"
  echo "   密码   = 你的 Personal Access Token（粘贴后不显示，回车即可）"
  git push -u origin main
fi

echo "== 5/5 完成"
echo "仓库：https://github.com/$USER_NAME/$REPO"
echo "AI 直读：https://raw.githubusercontent.com/$USER_NAME/$REPO/main/ALL-IN-ONE.md"
