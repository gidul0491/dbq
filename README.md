# dbq

Claude Code가 DB를 조회 전용으로 직접 조회하게 해 주는 명령어와 스킬. MySQL, Postgres, MSSQL.

## 설치

Node 22 이상이 필요하다. `dbq`는 실행한 위치의 PATH에 잡힌 node로 돌기 때문에, 프로젝트별로 nvm 버전을 바꿔 쓴다면 기본 버전(`nvm alias default`)을 22 이상으로 둔다.

```bash
git clone https://github.com/gidul0491/dbq.git ~/git/dbq
~/git/dbq/install.sh
```

1. `~/git/dbq/dbq.json`에 본인 접속정보를 입력한다. 별칭마다 하나씩, 형식은 `dbq.example.json` 참고.
2. `~/.claude/settings.json`의 `permissions`에 추가한다.

```json
"allow": [ "Bash(dbq *)" ],
"deny":  [ "Read(~/git/dbq/dbq.json)", "Edit(~/git/dbq/dbq.json)" ]
```

`allow`는 Claude가 묻지 않고 조회하게 하고, `deny`는 Claude가 접속정보 파일을 열지 못하게 한다. `~/git/dbq`가 아닌 곳에 받았다면 경로를 바꾼다.

## 사용

```bash
dbq                                      # 별칭 목록 (현재 저장소를 쓰는 별칭에 *)
dbq <별칭> "SELECT ..."                  # 조회
dbq set <별칭> projects +<저장소>        # 이 별칭을 쓰는 저장소 추가 (-<저장소>는 제거)
dbq set <별칭> <type|database|desc> <값> # 수정, 빈 값("")이면 삭제
dbq new <별칭> <mysql|postgres|mssql> [database] [설명]  # 새 DB 양식 추가
```

- `projects`는 git 저장소 이름(`origin` 주소의 마지막 부분)이다.
- `SELECT`, `SHOW`, `DESC`, `EXPLAIN`, `WITH`로 시작하는 한 문장만 실행된다. 쿼리는 읽기 전용 트랜잭션에서 실행하고 항상 롤백한다. MSSQL은 읽기 전용 트랜잭션이 없어 롤백만 한다.
- 가능하면 읽기 전용 DB 계정을 쓴다.

## 업데이트

```bash
cd ~/git/dbq && git pull && npm ci
```
