#!/bin/bash
# dbq 설치: 드라이버 설치, dbq 명령·Claude 스킬 링크, 접속정보 양식 생성
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$DIR" && npm ci --silent

mkdir -p ~/.local/bin ~/.claude/skills
ln -sfn "$DIR/dbq" ~/.local/bin/dbq
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
