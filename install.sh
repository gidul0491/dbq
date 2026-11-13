#!/bin/bash
# dbq 설치: 드라이버 설치, dbq 명령·Claude 스킬 링크, 접속정보 양식 생성
# Windows는 Git Bash에서 실행한다
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) WIN=1 ;; *) WIN= ;; esac

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

# 본인만 읽고 쓸 수 있게 한다 (Windows는 상속 권한을 끊고 본인만 남긴다)
# owner_only <경로> <chmod 모드> <icacls 권한>: 폴더는 안에 생길 파일까지 물려주도록 (OI)(CI)F를 준다
owner_only() {
  if [ -n "$WIN" ]; then
    icacls "$(cygpath -w "$1")" //inheritance:r //grant:r "$USERDOMAIN\\$USERNAME:$3" >/dev/null
  else
    chmod "$2" "$1"
  fi
}

mkdir -p ~/.local/bin ~/.claude/skills
# 프로젝트마다 .nvmrc로 node가 바뀌어도 설치할 때의 node로 실행되게 고정
rm -f ~/.local/bin/dbq ~/.local/bin/dbq.cmd
if [ -n "$WIN" ]; then
  # nvm-windows의 node는 nvm use마다 바뀌는 링크라 실제 버전 폴더의 node.exe로 고정한다
  NODE="$(node -p 'require("fs").realpathSync(process.execPath)')"
  printf '#!/bin/sh\nexec "%s" "%s/dbq" "$@"\n' "$(cygpath -u "$NODE")" "$DIR" > ~/.local/bin/dbq
  # PowerShell·cmd용
  printf '@"%s" "%s\\dbq" %%*\r\n' "$NODE" "$(cygpath -w "$DIR")" > ~/.local/bin/dbq.cmd
  # Git Bash의 ln -s는 폴더를 복사하므로 junction으로 링크한다 (예전 복사본·링크는 지우고 다시 만든다)
  node -e 'const fs = require("fs"), [t, l] = process.argv.slice(1); fs.rmSync(l, { recursive: true, force: true }); fs.symlinkSync(t, l, "junction")' \
    "$(cygpath -w "$DIR/skill")" "$(cygpath -w ~/.claude/skills/dbq)"
else
  printf '#!/bin/sh\nexec "%s" "%s/dbq" "$@"\n' "$(command -v node)" "$DIR" > ~/.local/bin/dbq
  ln -sfn "$DIR/skill" ~/.claude/skills/dbq
fi
chmod +x ~/.local/bin/dbq

if [ ! -f "$DIR/dbq.json" ]; then
  cp "$DIR/dbq.example.json" "$DIR/dbq.json"
fi
owner_only "$DIR/dbq.json" 600 F
# set-auth·remove 전 dbq.json 백업(backup)과 설정 변경 기록(log)
mkdir -p "$DIR/backup" "$DIR/log"
owner_only "$DIR/backup" 700 "(OI)(CI)F"
owner_only "$DIR/log" 700 "(OI)(CI)F"

case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *)
    if [ -n "$WIN" ]; then
      # 사용자 PATH에 넣으면 Git Bash·PowerShell·cmd·Claude Code 모두에서 보인다 (새로 연 창부터)
      echo "~/.local/bin을 PATH에 추가하세요 (PowerShell에서 실행 후 터미널·VS Code 재시작):"
      echo "  [Environment]::SetEnvironmentVariable('Path', [Environment]::GetEnvironmentVariable('Path', 'User') + ';' + \"\$HOME\\.local\\bin\", 'User')"
    else
      # 새로 여는 터미널과 Claude Code가 읽는 셸 설정 파일에 한 번만 넣는다
      case "$(basename "${SHELL:-}")" in
        zsh) SHELL_RC=~/.zshrc ;;
        bash) SHELL_RC=~/.bashrc ;;
        *) SHELL_RC=~/.profile ;;
      esac
      PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'
      if ! grep -qsF "$PATH_LINE" "$SHELL_RC"; then
        printf '\n%s\n' "$PATH_LINE" >> "$SHELL_RC"
        echo "$SHELL_RC에 ~/.local/bin을 PATH로 추가했습니다. 새 터미널부터 적용됩니다."
      fi
    fi
    ;;
esac

echo "설치 완료. $DIR/dbq.json에 접속정보를 입력하세요."
