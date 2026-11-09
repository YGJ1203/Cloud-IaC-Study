# 2026-11-09 bWAPP 보안 실습 간략 정리

## 1. bWAPP / bee-box / Burp Suite 역할
- **bWAPP**: 취약점 실습용 웹 애플리케이션. 메뉴마다 실습 시나리오와 PHP 처리 로직이 다름.
- **bee-box**: Apache, PHP, MySQL, bWAPP이 구성된 실습 가상머신.
- **Kali Firefox**: 웹페이지 접속 및 입력값 테스트.
- **Burp Suite**: 브라우저와 서버 사이의 HTTP Request / Response 확인.
- **bee-box의 `vi`**: 교재에서 PHP 소스 **확인** 후 `:q`로 종료했다면 일반적으로 열람 목적. 별도 지시 없이 수정할 필요 없음.

## 2. Blind SQL Injection
- **Boolean-based**: SQL 조건이 참/거짓일 때 달라지는 화면 반응으로 정보를 추론.
- **Time-based**: 조건에 따라 `sleep()` 등으로 응답 시간이 달라지는지 관찰. 지연은 서버 상태와 SQL 실행 방식의 영향도 받음.
- 주요 함수: `length()`(길이), `substring()`(부분 문자열), `ascii()`(문자 코드).
- 실습 예: `length(database()) = 5` 및 `substring(database(),1,1) = 'b'` 등으로 `bWAPP` 이름 추론.
- `information_schema`를 통해 테이블 이름 등을 조회하는 구조도 학습함.

## 3. XSS 및 AJAX/JSON
- **Reflected XSS**: 입력값이 서버 응답에 반영되어 브라우저에서 위험하게 해석될 때 발생할 수 있음.
- **AJAX**: 페이지 전체를 새로고침하지 않고 서버와 HTTP 통신.
- **JSON**: 응답 데이터 형식. JSON 자체가 XSS는 아님.
- `JSON.parse()`는 JSON 문자열을 객체로 변환; `eval()`은 문자열을 코드로 평가하므로 위험할 수 있음.
- `innerHTML`은 문자열을 HTML로 해석하므로 주의; 일반 텍스트 출력에는 `textContent`가 적합.
- `innerHTML`로 삽입한 `<script>` 태그는 일반적으로 실행되지 않으므로 팝업이 안 뜬다는 사실만으로 XSS 방어 여부를 판단할 수 없음.

## 4. 실제 HTTP 비교 (`xss_ajax_1-2.php`, `iron man`)
| 항목 | Low (0) | Medium (1) | High (2) |
|---|---|---|---|
| 상태 | 200 OK | 200 OK | 200 OK |
| Content-Type | `text/html` | `text/json; charset=utf-8` | `text/json; charset=utf-8` |
| Content-Length | 54 | 54 | 54 |
| 응답 본문 | 동일 | 동일 | 동일 |

공통 응답:
```json
{"movies":[{"response":"Yes! We have that movie..."}]}
```
- `security_level=0/1/2` 쿠키가 난이도 설정을 나타냄.
- 정상 입력에서는 세 레벨 모두 같은 결과를 반환했으며, **Medium/High가 완전히 동일한 방어 로직이라는 뜻은 아님**.
- `Content-Type`만으로 XSS 방어 성공을 확정할 수 없음. 서버 응답과 JavaScript 출력 방식도 확인해야 함.

## 5. bee-box PHP 파일 확인
- 교재 예시: `vi xxe-2.php`로 XXE 관련 PHP 소스 확인 후 `:q`로 종료.
- `:q`: 변경 없이 종료 / `:wq`: 저장 후 종료 / `:q!`: 변경사항 폐기 후 종료.
- **실습 메뉴를 바꿀 때마다 PHP 파일을 추가 설정할 필요는 일반적으로 없음.** 교재에서 명시적으로 수정·주석 해제를 지시할 때만 변경.

## 6. 다음 실습 체크 포인트
1. bWAPP 메뉴 및 보안 레벨 선택.
2. Firefox에서 정상 입력 테스트.
3. Burp Suite `Proxy → HTTP history`에서 Request와 Response 비교.
4. 필요할 때 bee-box에서 해당 PHP 파일을 **읽기만** 하며 처리 흐름 확인.
5. 입력값 → HTTP 요청 → PHP 처리 → HTTP 응답 → JavaScript → 화면 출력 순서로 정리.

> **오늘의 핵심:** bWAPP은 웹 실습, Burp는 통신 관찰, bee-box PHP 열람은 내부 동작 분석이다. 취약점의 성공 여부는 요청뿐 아니라 **응답과 브라우저 처리**까지 봐야 한다.
