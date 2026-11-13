# dbq

Claude Code가 DB를 조회 전용으로 직접 조회하게 해 주는 명령어와 스킬. MySQL, Postgres, MSSQL.

## 설치

Node 22 이상이 필요하다. `install.sh`를 실행할 때의 node로 고정되므로 프로젝트의 `.nvmrc`와 상관없이 동작한다. 그 node 버전을 지우거나 바꾸면 `install.sh`를 다시 실행한다.

```bash
git clone https://github.com/gidul0491/dbq.git ~/git/dbq
~/git/dbq/install.sh
```

`~/.local/bin`이 PATH에 없으면 셸 설정 파일(zsh는 `~/.zshrc`, bash는 `~/.bashrc`)에 추가한다. 새 터미널부터 `dbq`로 실행된다.

1. `~/git/dbq/dbq.json`에 본인 접속정보를 입력한다. 별칭마다 하나씩, 형식은 `dbq.example.json` 참고.
2. `~/.claude/settings.json`의 `permissions`에 추가한다.

```json
"allow": [ "Bash(dbq *)" ],
"ask":   [ "Bash(dbq remove *)" ],
"deny":  [ "Read(~/git/dbq/dbq.json)", "Edit(~/git/dbq/dbq.json)", "Bash(dbq set-auth *)", "Bash(dbq show-secret *)" ]
```

`allow`는 Claude가 묻지 않고 조회하게 하고, `ask`는 별칭 지우기만 사용자 승인을 받게 하고, `deny`는 Claude가 접속정보 파일을 열거나 접속정보를 바꾸거나 비밀번호를 보지 못하게 한다. `set-auth`·`show-secret`은 사람이 직접 실행하는 명령이라 `deny`에 둔다. `~/git/dbq`가 아닌 곳에 받았다면 경로를 바꾼다.

### Windows

[Git for Windows](https://git-scm.com/download/win)의 Git Bash에서 `install.sh`를 실행한다. nvm-windows를 쓰면 `nvm use 22` 후에 실행한다.

```bash
git clone https://github.com/gidul0491/dbq.git /c/git/dbq
/c/git/dbq/install.sh
```

- `~/.local/bin`에 Git Bash용 `dbq`와 PowerShell·cmd용 `dbq.cmd`가 생긴다. PATH에 없으면 설치가 안내하는 PowerShell 명령으로 사용자 PATH에 추가하고 터미널·VS Code를 다시 연다.
- `~/.claude/skills/dbq`는 junction으로 링크된다.
- `dbq.json`, `backup/`·`log/` 폴더, `--out` 파일은 상속 권한을 끊고 본인만 접근하게 설정된다.
- `settings.json`의 경로는 `/c/...` 형태로 쓰고, 절대 경로는 `//`로 시작한다. Claude Code가 PowerShell로 실행할 때를 위해 같은 규칙을 `PowerShell(...)`로도 넣는다.

```json
"allow": [ "Bash(dbq *)", "PowerShell(dbq *)" ],
"ask":   [ "Bash(dbq remove *)", "PowerShell(dbq remove *)" ],
"deny":  [ "Read(//c/git/dbq/dbq.json)", "Edit(//c/git/dbq/dbq.json)", "Bash(dbq set-auth *)", "Bash(dbq show-secret *)", "PowerShell(dbq set-auth *)", "PowerShell(dbq show-secret *)" ]
```

## 사용

```bash
dbq                                      # 별칭 목록 (현재 프로젝트를 쓰는 별칭에 *)
dbq <별칭> "SELECT ..."                  # 조회
dbq <별칭> "SELECT ..." --out <파일>     # 결과를 화면 대신 파일(TSV)로 저장, 행 수 제한 없음
dbq set <별칭> projects +<프로젝트>      # 이 별칭을 쓰는 프로젝트 추가 (-<프로젝트>는 제거)
dbq set <별칭> <type|database|desc> <값> # 수정, 빈 값("")이면 삭제
dbq new <별칭> <mysql|postgres|mssql> [database] [설명]  # 새 DB 양식 추가
dbq show [별칭]                          # 별칭 정보를 JSON으로 (비밀번호는 있는지만)
dbq show-secret <별칭>                   # 비밀번호까지 보기 (본인 확인용)
dbq set-auth <별칭> < 접속정보.json      # host·port·user·password를 표준 입력으로 바꾸기
dbq remove <별칭>                        # 별칭 지우기, 지우기 전 dbq.json은 backup/_dbq_json/에 (승인)
dbq version                              # 설치된 버전과 새 버전 확인
dbq update                               # 새 버전으로 업데이트
```

- 별칭 목록은 별칭마다 항목을 한 줄에 하나씩 보여 주고 빈 항목은 뺀다. 프로그램에서 읽을 때는 `dbq show`(JSON)를 쓴다.
- `projects`에는 프로젝트 이름을 넣는다. git `origin` 저장소 이름 → git 최상위 폴더 이름 → 현재 폴더 이름 순으로 정해지고, `dbq` 첫 줄에 나온다.
- `SELECT`, `SHOW`, `DESC`, `EXPLAIN`, `WITH`로 시작하는 한 문장만 실행된다. 쿼리는 읽기 전용 트랜잭션에서 실행하고 항상 롤백한다. MSSQL은 읽기 전용 트랜잭션이 없어 롤백만 하므로, 실행 전에 `INTO`, `EXEC`·`sp_executesql`·`xp_cmdshell`, `OPENQUERY`·`OPENROWSET`·`OPENDATASOURCE`, `WITH` 안의 쓰기 문장을 거부한다(문자열·주석·`[이름]` 안의 단어는 보지 않는다).
- `set-auth`는 접속정보를 명령줄이 아닌 표준 입력의 JSON으로 받는다(프로세스 목록에 남지 않게). 들어온 항목만 바꾸고, `password`는 빈 문자열이면 그대로 두고 `null`이면 지운다. `port`가 비어 있으면 종류의 기본 포트를 쓴다. 예: `dbq set-auth db-myservice-prod < auth.json` (`{"host":"1.2.3.4","user":"reader","password":"..."}`)
- `set-auth`·`remove`는 바꾸기 전 dbq.json을 `backup/_dbq_json/dbq.json.bak_<시각>`에 백업하고, 바꾼 항목 이름(값은 빼고)을 `log/<별칭>.log`에 남긴다.
- `set-auth`·`remove`·`show-secret`은 Claude Code 설정에 그 명령의 `ask` 또는 `deny` 규칙이 없으면 실행되지 않는다. AI가 승인 없이 실행하지 못하게 하려는 것이다.
- 명령 이름(`show`, `remove` 등)은 별칭으로 쓸 수 없다.
- `--out`은 결과를 본인만 읽을 수 있는 파일로 저장하고 행 수만 출력한다. 개인정보를 뽑을 때 대화에 값을 남기지 않기 위해 쓴다.
- 가능하면 읽기 전용 DB 계정을 쓴다.

## 업데이트

```bash
dbq version
dbq update
```

`update`는 새 커밋을 받은 뒤 지금 쓰는 node로 `install.sh`를 다시 실행한다. 로컬에서 고친 파일이나 올리지 않은 커밋이 있으면 멈춘다.
