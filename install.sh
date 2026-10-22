#!/bin/bash
# dbq 설치: 드라이버 설치, dbq 명령·Claude 스킬 링크, 접속정보 양식 생성
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"

NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"
if [ "$NODE_MAJOR" -lt 22 ]; then
  echo "Node 22 이상이 필요합니다. (현재: $(node -v 2>/dev/null || echo 없음))"
  exit 1
fi

# 드라이버 목록(package-lock.json)이 바뀌었을 때만 다시 설치
cd "$DIR"
if [ ! -d node_modules ] || [ package-lock.json -nt node_modules/.package-lock.json ]; then
  npm ci --silent
fi

mkdir -p ~/.local/bin ~/.claude/skills
# 프로젝트마다 .nvmrc로 node가 바뀌어도 설치할 때의 node로 실행되게 고정
rm -f ~/.local/bin/dbq
printf '#!/bin/sh\nexec "%s" "%s/dbq" "$@"\n' "$(command -v node)" "$DIR" > ~/.local/bin/dbq
chmod +x ~/.local/bin/dbq
ln -sfn "$DIR/skill" ~/.claude/skills/dbq

if [ ! -f "$DIR/dbq.json" ]; then
  cp "$DIR/dbq.example.json" "$DIR/dbq.json"
fi
chmod 600 "$DIR/dbq.json"

case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) echo "~/.local/bin을 PATH에 추가하세요: echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc" ;;
esac

echo "설치 완료. $DIR/dbq.json에 접속정보를 입력하세요."
