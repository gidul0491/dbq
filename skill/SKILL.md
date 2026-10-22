---
name: dbq
description: DB 데이터를 조회해야 할 때(건수 확인, 데이터 확인, 테이블·프로시저 구조 확인 등) 사용자에게 쿼리 실행을 부탁하지 말고 dbq로 직접 조회한다. 사용자가 "이 프로젝트는 ○○ DB를 쓴다", "새 DB 추가해줘"라고 하면 dbq 설정도 직접 고친다. MySQL/Postgres/MSSQL, 모든 프로젝트 공통.
---

# dbq: 조회 전용 DB 쿼리

DB 조회가 필요하면 사용자에게 쿼리를 실행해 달라고 하지 말고 직접 실행한다.

```bash
dbq                                      # 별칭 목록 (현재 프로젝트를 쓰는 별칭에 *)
dbq <별칭> "SELECT ..."                  # 조회
dbq <별칭> "SELECT ..." --out <파일>     # 결과를 화면 대신 파일(TSV)로 저장, 행 수 제한 없음
dbq set <별칭> projects +<프로젝트>      # 이 별칭을 쓰는 프로젝트 추가 (-<프로젝트>는 제거)
dbq set <별칭> <type|database|desc> <값> # 수정, 빈 값("")이면 삭제
dbq new <별칭> <mysql|postgres|mssql> [database] [설명]  # 새 DB 양식 추가 (접속정보는 빈칸)
dbq version                              # 설치된 버전과 새 버전 확인
dbq update                               # 새 버전으로 업데이트
```

## 버전 확인
- 세션에서 dbq를 처음 쓸 때 `dbq version`을 먼저 실행한다.
- 새 버전이 있으면 사용자에게 바뀐 내용(출력의 커밋 목록)을 한 줄로 알리고 `dbq update`로 업데이트한 뒤 작업을 계속한다.
- update가 로컬 수정이나 올리지 않은 커밋 때문에 멈추면 그 내용을 사용자에게 알리고, 직접 정리하지 않는다.

## 별칭 고르기
- 작업 중인 프로젝트 폴더에서 `dbq`를 실행해 `*` 붙은 별칭을 쓴다. 프로젝트 이름은 첫 줄 `현재 프로젝트:`에 나온다(git `origin` 저장소 이름 → git 최상위 폴더 이름 → 현재 폴더 이름 순).
- `*`가 없거나 여러 개면 추측하지 말고 사용자에게 묻는다.
- 테이블 위치는 `information_schema.tables`로 찾는다. 한 서버에 스키마가 여러 개면 `` `스키마`.테이블 ``로 명시한다.

## 설정을 직접 고치는 경우
- 사용자가 "여기는 ○○ DB 쓰는 거야"라고 하면 `dbq` 첫 줄의 현재 프로젝트 이름으로 `dbq set <별칭> projects +<프로젝트>`를 실행한다. projects 전체를 덮어쓰는 `,` 형식은 쓰지 않는다.
- 사용자가 DB 용도를 설명하면 `desc`를 채운다. 사용자 말이나 코드 같은 근거 없이 추측으로 채우지 않는다.
- 사용자가 새 DB를 추가하라고 하면 `dbq new`로 양식만 만들고, 사용자에게 `dbq.json`에서 해당 별칭의 host·user·password를 채워 달라고 한다. 별칭 이름은 기존 별칭처럼 `용도-환경`(예: `db-myservice-prod`) 형태로 짓되, 애매하면 묻는다.
- host·port·user·password는 사용자만 수정한다. 이 값을 대화로 받아도 직접 넣지 말고 사용자가 파일에 넣게 한다.
- 고친 뒤에는 출력된 결과를 사용자에게 한 줄로 알린다.

## 조회 규칙
- `dbq ...`는 단독 명령으로 실행한다. 파이프·`&&`·`;`로 다른 명령과 묶으면 허용 규칙에 걸리지 않아 막힌다.
- 허용: `SELECT`, `SHOW`, `DESC`, `EXPLAIN`, `WITH`로 시작하는 한 문장. 나머지는 거부되고, 읽기 전용 트랜잭션이라 DB도 쓰기를 거부한다.
- 결과는 탭 구분, 최대 500행. 운영 DB에서는 큰 테이블 전체 조회 대신 `COUNT(*)`, `LIMIT`, 인덱스 조건을 쓴다.
- 개인정보(이름·연락처·주민번호 등)를 백업·엑셀용으로 뽑을 때는 `--out <파일>`로 파일에만 저장하고 값을 화면에 띄우지 않는다. 확인은 행 수와 형식 검사로만 한다. 파일은 본인만 읽을 수 있는 권한으로 만들어진다.
- 프로시저 내용은 `SHOW CREATE PROCEDURE <이름>`(mysql), `SELECT OBJECT_DEFINITION(OBJECT_ID('<이름>'))`(mssql)로 본다. 프로시저를 `CALL`/`EXEC`하지 않는다.
- 조회 가능한 종류는 mysql, postgres, mssql.
- mssql: `LIMIT` 대신 `SELECT TOP n`. `SHOW`/`DESC`가 없으니 `sys.objects`, `INFORMATION_SCHEMA.COLUMNS`로 구조를 본다. `INTO`가 들어간 쿼리, `EXEC`·`sp_executesql`·`xp_cmdshell`(`sp_helptext` 포함), `OPENQUERY`·`OPENROWSET`·`OPENDATASOURCE`, `WITH` 안의 INSERT·UPDATE·DELETE·MERGE 등은 거부된다.
- mssql은 읽기 전용 트랜잭션이 없어 롤백으로만 되돌린다. 쓰기처럼 보이는 쿼리는 시도하지 않는다.

## 하지 않는 것
- 접속정보 파일 `dbq.json`을 직접 읽거나 편집하지 않는다. 프로젝트 `.env`의 접속정보도 읽지 말고 dbq 별칭을 쓴다.
- 접속 오류(Access denied, ETIMEDOUT, 접속정보 미입력 등)는 추측으로 고치지 말고 그대로 사용자에게 알린다.

## 파일 위치
dbq 저장소 폴더(보통 `~/git/dbq`) 하나에 전부 있다. `~/.local/bin/dbq`는 이 폴더의 스크립트를 실행하는 런처, `~/.claude/skills/dbq`는 `skill` 폴더 링크다.
- `dbq`: 스크립트
- `dbq.json`: 접속정보 (git 제외, 각자 입력)
- `skill/SKILL.md`: 이 스킬
