# 2026-11-10 보안 실습 총정리

> **주제:** Kali Linux + bWAPP 공격 재현 → Snort IDS 탐지 → Apache 로그 분석 → FortiWeb 8.0.5 Reverse Proxy WAF 구축 및 방어 검증  
> **환경:** 교육용 격리 VM 실습. 실습에 사용한 사설 IP만 기재하며 세션 쿠키와 실제 인증정보는 기록하지 않음.

---

## 1. 오늘의 핵심 요약

오늘은 공격자 관점에서 bWAPP의 취약점을 재현하고, 방어자 관점에서 Snort의 탐지 결과 및 FortiWeb의 차단 결과를 비교했다.

1. **Kali**에서 웹 취약점 테스트 요청을 전송했다.
2. **Snort** 로컬 시그니처 및 임계값 규칙을 통해 네트워크 트래픽을 탐지했다.
3. **Apache access.log**에서 웹 서버가 받은 요청의 URI, 메서드, 상태 코드를 확인했다.
4. **FortiWeb**을 Reverse Proxy로 구성해 Kali가 WAF 주소로 접속해도 bWAPP 페이지가 제공되는 것을 확인했다.
5. 기본 `Inline Standard Protection`에서 OS Command Injection, SQL Injection, XSS, CGI Shellshock 테스트는 차단되는 반면, 일부 Path Traversal 및 LFI/RFI 요청은 통과하여 실제 내용이 표시되는 것을 관찰했다.
6. **Path Traversal 사용자 정의 시그니처**와 새 보호 프로필을 적용한 뒤 관련 차단 이벤트가 Attack Log에 표시되는 것을 확인했다.

**중요:** 이번 결과는 테스트한 요청·정책·환경에 한정된다. 특정 공격 종류 전체에 대한 완전한 차단 능력을 입증하지는 않는다.

---

## 2. 실습 네트워크와 각 구성 요소

| 구성 요소 | 실습 주소 | 역할 |
|---|---|---|
| Kali Linux | `192.168.2.50` | 테스트 요청을 보내는 클라이언트 |
| bee-box / bWAPP | `192.168.20.205` | 취약한 교육용 웹 애플리케이션 |
| FortiWeb VM | `192.168.20.105` | Reverse Proxy 기반 WAF |
| 게이트웨이 | `192.168.20.100` | 다른 네트워크와의 통신 경로 |
| Snort | 실습 IDS | 패킷 및 HTTP 요청의 탐지 규칙 적용 |

### FortiWeb 적용 전후 요청 흐름

**WAF 경유 전:** `Kali → bWAPP (192.168.20.205:80)`  
**WAF 경유 후:** `Kali → FortiWeb (192.168.20.105:80) → bWAPP (192.168.20.205:80)`

- **Reverse Proxy:** 클라이언트 요청을 대신 수신하고 실제 웹 서버로 전달한다.
- **Snort IDS:** 트래픽에서 규칙과 일치하는 패턴을 탐지한다. IDS 탐지와 WAF 차단은 구분해야 한다.
- **Apache access.log:** 웹 서버가 받은 요청 기록. POST 본문이나 전체 HTTP 헤더는 일반적인 access.log만으로 확인하기 어렵다.
- **FortiWeb Attack Log:** 적용 정책, 탐지 규칙, 일치 패턴, 조치(Action) 등을 확인한다.

---

## 3. bWAPP 웹 공격 유형 정리

| 유형 | 입력값이 영향을 주는 곳 | 핵심 원리 | 오늘 실습에서 확인한 내용 |
|---|---|---|---|
| HTML / iframe Injection | 브라우저의 HTML 구조 | 입력값이 HTML 태그·속성으로 해석됨 | iframe 관련 요청과 차단 로그 분석 |
| OS Command Injection | 서버 운영체제 셸 | 웹 입력값이 셸 명령으로 결합됨 | DNS 조회 입력값에 셸 연산자 사용 |
| SQL Injection (GET/POST) | 데이터베이스 쿼리 | 입력값이 SQL 조건 또는 구문을 바꿈 | 조건 우회·UNION 형태 테스트 |
| Reflected XSS (GET/POST) | 클라이언트 브라우저 | 출력된 입력값이 JavaScript로 해석됨 | `alert` 및 쿠키 출력 동작 테스트 |
| Path Traversal | 서버 파일 경로 | `../` 등을 이용해 허용된 경로 밖으로 이동 | `/etc` 디렉터리 및 파일 접근 테스트 |
| Shellshock (CGI) | 취약한 Bash/CGI 처리 | HTTP 헤더가 Bash 환경 변수 처리에 영향을 줄 수 있음 | 특수 헤더 요청에 대한 탐지·차단 검증 |
| LFI / RFI | 애플리케이션의 파일 포함 기능 | 로컬 또는 원격 파일을 포함하도록 경로를 조작 | 파일 내용 출력과 WAF 통과/차단 비교 |

### 공격 구분 암기법

- **SQLi:** 데이터베이스에 어떤 SQL이 실행되는가?
- **OS Command Injection:** 서버 셸에서 어떤 명령이 실행되는가?
- **XSS:** 브라우저가 어떤 스크립트를 실행하는가?
- **HTML Injection:** 브라우저가 어떤 HTML 구조를 생성하는가?
- **Path Traversal:** 서버가 어떤 경로에 접근하는가?
- **LFI/RFI:** 애플리케이션이 어떤 파일을 포함하는가?
- **Shellshock:** 취약한 Bash가 외부 입력을 명령으로 처리하는가?

### 학습용 예시

**SQL Injection**

```sql
1' or 1=1 #
```

- `OR 1=1`은 조건을 항상 참으로 만들 수 있다.
- 실제 영향은 서버 측 SQL 조립 방식에 따라 달라진다.
- 방어: 파라미터 바인딩(Prepared Statement), 최소 권한, 적절한 오류 처리.

**OS Command Injection**

```text
www.google.com ; cat /etc/passwd | head -3
```

- `;`는 셸에서 명령을 분리할 수 있다.
- 입력값을 셸에 직접 결합하는 구현이 위험하다.
- 방어: 셸 실행 회피, 안전한 API, 입력값 허용 목록, 최소 권한.

**Reflected XSS**

```html
<script>alert("test1")</script>
```

- 웹 응답에 입력값이 적절한 인코딩 없이 포함되면 브라우저에서 스크립트가 실행될 수 있다.
- 방어: 출력 문맥별 인코딩, 안전한 DOM API, CSP 보조 적용.

**Path Traversal**

```text
../../../../etc
```

- `../`는 상위 디렉터리 이동을 나타낸다.
- 방어: 경로 정규화, 허용된 기본 디렉터리 내부인지 검증, 파일 접근 권한 제한.

**Shellshock**

- HTTP 헤더가 CGI 환경 변수로 전달되고 취약한 Bash가 이를 처리할 때 문제가 발생할 수 있다.
- **주의:** Snort 경고나 HTTP 오류 코드만으로 원격 명령 실행 성공을 단정하지 않는다. 실제 실행 증거가 필요하다.

**LFI/RFI**

- LFI: 로컬 파일을 포함하려는 시도.
- RFI: 외부 위치의 파일을 포함하려는 시도.
- 원격 파일 내용 표시와 원격 코드 실행은 별도로 검증해야 한다.
- 외부 단축 URL이나 출처가 불명확한 PHP 파일을 직접 실행하지 않는다.

---

## 4. Snort IDS 탐지 실습

### 탐지 대상

- HTTP URI의 `union`, `or`, `and` 같은 문자열 탐지
- ICMP Echo Request (`itype:8`) / Echo Reply (`itype:0`)
- FTP의 `USER`, `ProFTPD` 관련 문자열
- Telnet 및 HTTP 트래픽 탐지
- bWAPP 공격별 HTTP URI·요청 본문·헤더 시그니처

### Snort threshold 비교

| 유형 | 핵심 동작 | 실습 관찰 |
|---|---|---|
| `type threshold` | 지정 시간 동안 일정 횟수 발생 시 알림 | `ping -c 10`에서 두 번 알림 관찰 |
| `type both` | 임계값 도달과 이후 억제를 함께 적용 | 한 번 알림 관찰 |
| `type limit` | 지정 기간 내 알림 개수를 제한 | 다섯 번 알림 관찰 |

예시 규칙의 주요 요소:

```text
threshold: type threshold, track by_dst, count 5, seconds 10;
```

- `track by_dst`: 목적지 기준으로 카운트
- `count 5`: 5회 기준
- `seconds 10`: 10초 구간

**유의:** `content:"or"`처럼 짧고 흔한 문자열을 탐지하면 정상 요청까지 걸리는 **False Positive**가 발생할 수 있다.

### 패킷 및 로그 확인

```bash
tcpdump -nn -r /var/log/snort/<snort-packet-log>
```

- Snort 경고는 **규칙에 일치했다는 증거**다.
- 실제 공격 성공 여부는 웹 응답, 애플리케이션 동작, 서버 측 로그 등을 추가로 확인해야 한다.

---

## 5. Apache access.log 상관 분석

오늘 살펴본 Apache access.log에는 다음 종류의 요청 흔적이 있었다.

| 실습 | 로그에서 확인할 단서 | 해석상 주의점 |
|---|---|---|
| iframe Injection | `iframei.php` URI 및 후속 페이지 요청 | 요청이 기록됐다고 HTML 삽입 성공이 자동 입증되지는 않음 |
| OS Command Injection | `commandi.php` POST | 일반 access.log에는 POST 본문이 없을 수 있음 |
| SQL Injection | `sqli_1.php` 및 URL 인코딩된 입력값 | HTTP 200은 공격 성공의 충분조건이 아님 |
| XSS | `xss_get.php` 및 인코딩된 `<script>` | 브라우저 실행 여부는 별도 증거 필요 |
| Path Traversal | `directory_traversal_*.php` URI | 실제 파일·디렉터리 출력과 함께 판단 |
| Shellshock | CGI 요청 및 헤더 관련 기록 | HTTP 500만으로 명령 실행·역방향 셸 성공 단정 불가 |

### 로그 상관 분석 흐름

```text
Kali/Burp 요청 생성
        ↓
Snort Alert (시그니처 탐지)
        ↓
FortiWeb Attack Log (WAF 조치)
        ↓
Apache access.log / error.log (백엔드 관찰)
        ↓
브라우저 응답과 서버 동작 비교
```

**중요:** FortiWeb이 앞단에서 차단한 요청은 Apache 백엔드에 도달하지 않을 수 있다. 로그가 없다는 사실만으로 로그 수집 실패라고 단정하지 않는다. 로그 타임존도 서로 다를 수 있다.

---

## 6. FortiWeb 8.0.5 VM 초기 구축 (교재 1~10번)

### VM 및 관리 환경

- 제품: FortiWeb VM 8.0.5
- 플랫폼: VMware용 OVF 배포
- 네트워크 어댑터: 교재에 따라 3개 유지, Host-Only로 설정
- 관리 계정: `admin`
- 초기 비밀번호: 교재의 교육용 비밀번호 사용. **실제 비밀번호는 보고서에 기록하지 않음**
- Operation Mode: **Reverse Proxy** (대시보드에서 확인)

### CLI 핵심 설정

**관리 인터페이스**

```text
config system interface
    edit "port1"
        set mode static
        set ip 192.168.20.105 255.255.255.0
        set allowaccess http https ping ssh
    next
end
```

**관리 포트**

```text
config system global
    set admin-sport 8443
    set admin-port 8000
end
```

**DNS**

```text
config system dns
    set primary 8.8.8.8
    set secondary 8.8.4.4
end
```

**기본 경로**

```text
config router static
    edit 1
        set gateway 192.168.20.100
        set device "port1"
    next
end
```

**연결 확인**

```text
execute ping 8.8.8.8
execute ping www.google.com
execute ping 192.168.2.50
execute ping 192.168.20.205
```

- 사용자는 VM 가져오기, 설정, Ping 테스트까지 성공했다고 확인했다.
- Host-Only만으로 인터넷이 제공되는 것은 아니며 외부 통신에는 별도의 라우팅/NAT 환경이 필요하다.
- 웹 관리 주소: `https://192.168.20.105:8443`
- 대시보드에서 `Reverse Proxy`, `Standalone` 확인.
- 대시보드에 `FVM00UNLICENSED` 및 라이선스 관련 빨간 표시가 관찰되었다. **평가판 기능 활성화 여부는 별도 확인이 필요**하며, 모든 기능이 라이선스 없이 정상 동작한다고 단정하지 않는다.

---

## 7. FortiWeb 웹 서비스 구성 (교재 11~13번)

### 11. Server Pool: `MyWebPool`

경로: `Server Objects → Server → Server Pool`

| 항목 | 값 |
|---|---|
| Name | `MyWebPool` |
| Protocol | HTTP |
| Type | Reverse Proxy |
| Single Server / Server Balance | Single Server |
| Backend IP | `192.168.20.205` |
| Backend Port | `80` |
| Status | Enable |
| Connection Limit | 0 |
| Proxy Protocol / HTTP2 / SSL | off |

### 12. Virtual Server: `MyVS`

경로: `Server Objects → Server → Virtual Server`

- Name: `MyVS`
- Use Interface IP: on
- Interface: `port1`
- Status: on

### 13. Server Policy: `MyWAF`

경로: `Policy → Server Policy`

| 항목 | 값 |
|---|---|
| Name | `MyWAF` |
| Deployment Mode | Single Server/Server Balance |
| Virtual Server | `MyVS` |
| Server Pool | `MyWebPool` |
| HTTP Service | HTTP |
| Web Protection Profile | `Inline Standard Protection` |

**확인된 결과:** Kali 브라우저에서 `http://192.168.20.105`로 접속하자 bWAPP 페이지가 표시되었다. 이는 Reverse Proxy 경로가 동작한다는 강력한 증거다. 다만 **정상 웹페이지 표시와 공격 차단 능력은 별개**다.

---

## 8. 기본 WAF 정책 공격 테스트 (교재 14번)

**적용 프로필:** `Inline Standard Protection`

| 실습 요청 | 사용자가 확인한 결과 | 해석 |
|---|---|---|
| OS Command Injection | 차단 | 해당 테스트 요청에 대해 방어 확인 |
| SQL Injection (GET/POST Search) | 차단 | 해당 테스트 요청에 대해 방어 확인 |
| Reflected XSS (GET/POST) | 차단 | 해당 테스트 요청에 대해 방어 확인 |
| CGI Shellshock | 차단 | 요청 차단 확인; 코드 실행 성공 여부와 별개 |
| Path Traversal | **미차단, 내용 출력** | 해당 경로 조작 요청이 통과함 |
| LFI/RFI | **미차단, 내용 출력** | 해당 파일 포함 요청이 통과함; RFI 코드 실행 여부는 별개 |
| iframe 기본 페이지 요청 | **차단** | 정상 요청 오탐 가능성 |

### 핵심 사례 A — `robots.txt` 오탐 가능성

**정상 요청:**

```http
GET /bWAPP/iframei.php?ParamUrl=robots.txt&ParamWidth=250&ParamHeight=250 HTTP/1.1
Host: 192.168.20.105
```

FortiWeb 상세 로그에서 확인한 값:

| 항목 | 값 |
|---|---|
| Policy | `MyWAF` |
| Action | `Alert_Deny` |
| OWASP Top 10 | `A03:2021-Injection` |
| Main Type | Signature Detection |
| Sub Type | Generic Attacks |
| Signature Subclass | File Injection |
| Signature ID | `050070012` |
| Matched Parameter | `ParamUrl` |
| Matched Pattern | `robots.txt` |
| Signatures Policy | Standard Protection |

**분석:** HTML 인젝션 페이로드를 넣기 전의 정상적인 iframe 실습 페이지 요청이 `robots.txt` 문자열에 매칭되어 차단되었다. 따라서 실습 맥락에서 **False Positive 가능성이 높다**. 시그니처의 상세 정의를 보지 않고 확정적인 제품 버그라고 단정하지 않는다.

### 핵심 사례 B — Path Traversal 미차단

교재의 테스트 예시:

```text
http://192.168.20.105/bWAPP/directory_traversal_2.php?directory=../../../../etc
http://192.168.20.105/bWAPP/directory_traversal_2.php?directory=/etc
http://192.168.20.105/bWAPP/directory_traversal_1.php?page=../../../../etc/passwd
```

**사용자 관찰:** 기본 프로필에서는 차단되지 않았고 디렉터리 또는 파일 내용이 실제로 표시되었다.

**교훈:** WAF가 일부 공격을 차단한다는 사실이 다른 공격도 모두 차단한다는 뜻은 아니다.

---

## 9. Path Traversal Custom Signature 추가 (교재 15번)

### 9-1. 사용자 정의 시그니처 생성

경로: `Web Protection → Known Attacks → Custom Signature → Custom Signature`

| 항목 | 값 |
|---|---|
| Name | `Path Traversal` |
| Direction | Request |
| Action | Alert & Deny |
| Block Period | 600 |
| Match Operator | Regular expression match |
| Case Sensitive | off |
| Target | Request URI, Request Body |

교재 정규표현식:

```regex
(?:\.\.[\\\/]|%2e%2e|\/(?:etc|windows|proc|var|bin|sbin|root)(?:\/|$)|\b[a-zA-Z]:[\\\/])
```

**주요 탐지 의도:**

- `../` 및 `..\` 같은 상위 디렉터리 이동 표현
- `%2e%2e`처럼 인코딩된 점 두 개
- `/etc`, `/proc`, `/var` 등 민감 경로
- `C:\` 같은 Windows 드라이브 경로

**한계:** 정규표현식 하나로 모든 인코딩 변형, 경로 정규화 차이, RFI 패턴을 완전히 막을 수는 없다. `/etc` 같은 문자열이 합법적 데이터로 사용될 경우 오탐 가능성도 있다.

### 9-2. 시그니처 그룹 및 정책 연결

1. `Custom Signature Group` 생성: **Path Traversal**
2. 그룹 멤버로 `Path Traversal` 시그니처 추가
3. `Extended Protection` Signature Policy 복제
4. 복제한 정책 이름: **MyWAFPolicy**
5. `Custom Signature Group = Path Traversal`, `Sensitivity Level = 4`
6. `Policy → Web Protection Profile`에서 **Inline MyProtection** 생성
7. Signatures = **MyWAFPolicy**
8. HTTP Protocol Constraints = **Extended Protection**
9. Custom Policy = **Predefined - Advanced Protection**
10. File Security / Web Shell Detection = **WebShell-Uploading** (교재 설정)
11. Bot Mitigation Policy = **Predefined - Bot Mitigation**
12. `Policy → Server Policy → MyWAF`의 Web Protection Profile을 **Inline MyProtection**으로 변경

### 9-3. 적용 후 확인한 Attack Log Widget

화면에 다음 메시지들이 표시되었다.

```text
Parameter triggered custom signature rule Path Traversal
Invalid HTTP Header triggered signature ID 080200004 of Signatures policy MyWAFPolicy
Invalid URL triggered signature ID 050140004 of Signatures policy MyWAFPolicy
```

**해석:**

- `Parameter triggered custom signature rule Path Traversal`: 사용자 정의 시그니처의 탐지 이벤트가 발생했다는 직접적인 증거.
- `Invalid HTTP Header`: 별도 HTTP 헤더 관련 시그니처 이벤트.
- `Invalid URL`: 별도 URL 관련 시그니처 이벤트.
- **서로 다른 이벤트를 모두 Path Traversal 탐지라고 합쳐 해석하면 안 된다.**
- 사용자는 Custom Signature 적용 이후 테스트를 모두 마쳤다고 보고했다. 실제 조치(Action)와 요청별 매칭 패턴은 개별 상세 로그를 기준으로 기록하는 것이 가장 정확하다.

### 적용 전후 비교

| 구분 | 기본 정책 | 사용자 정의 정책 적용 후 |
|---|---|---|
| 적용 프로필 | Inline Standard Protection | Inline MyProtection |
| Path Traversal 요청 | 통과 및 내용 출력 관찰 | Custom Signature 탐지 이벤트 확인; 차단 검증 완료 보고 |
| 확인할 로그 | 탐지 누락 여부 | 규칙명, Action, Matched Pattern, URL |
| 운영상 고려 | 미탐 가능성 | 오탐·정상 서비스 영향도 함께 확인 |

---

## 10. FortiWeb 로그 분석 (교재 16~17번)

**대시보드:** `Dashboard → Status → Attack Log Widget`  
**상세 로그:** `Log&Report → Log Access → Attack`  
**이벤트 로그:** `Log&Report → Log Access → Event`

### 분석 순서

1. 요청 시각과 Client IP가 테스트와 일치하는지 확인한다.
2. `Policy`가 `MyWAF`인지 확인한다.
3. `Main Type`, `Sub Type`, `Signature ID` 또는 Custom Signature 이름을 확인한다.
4. `Matched Pattern`과 `Parameter`를 확인한다.
5. `Action`이 `Alert_Deny`, `Alert`, `Erase` 등 무엇인지 확인한다.
6. 브라우저에서 실제 차단 화면 또는 서버 내용 출력 여부를 대조한다.
7. 필요하면 백엔드 Apache 로그와 시간대 차이를 보정하여 상관 분석한다.

### IDS / WAF / 웹 서버 로그의 차이

| 로그 | 잘 알려주는 것 | 단독으로 입증하기 어려운 것 |
|---|---|---|
| Snort Alert | 어떤 탐지 규칙에 일치했는가 | 실제 공격 성공 여부 |
| FortiWeb Attack Log | 어떤 WAF 정책과 조치가 적용되었는가 | 애플리케이션의 모든 내부 동작 |
| Apache access.log | 서버가 어떤 HTTP 요청을 받았는가 | POST 본문, 헤더 전체, 실제 코드 실행 여부 |
| Apache error.log | 웹 서버 오류 및 일부 실행 단서 | 공격 전체 과정의 완전한 재구성 |
| 브라우저 결과 | 사용자에게 어떤 응답이 보였는가 | 서버 내부의 모든 상태 변화 |

---

## 11. 오늘 배운 보안 엔지니어 관점의 교훈

### ① 탐지 ≠ 차단 ≠ 공격 성공

- 탐지: 규칙이 요청과 일치함.
- 차단: 보안 정책이 요청을 거부하거나 변경함.
- 공격 성공: 목표한 비정상 동작이 실제로 발생함.

세 가지는 서로 다른 증거가 필요하다.

### ② False Positive와 False Negative를 함께 관리

- **False Positive(오탐):** 정상 `ParamUrl=robots.txt` 요청이 차단된 사례.
- **False Negative(미탐):** 기본 정책에서 Path Traversal 요청이 통과한 사례.

운영 환경에서는 무조건 차단 수를 늘리는 것보다 **정상 사용자 영향과 실제 위험을 균형 있게 평가**해야 한다.

### ③ 정책을 적용한 뒤 반드시 재시험

`정상 동작 확인 → 취약 요청 테스트 → 로그 확인 → 정책 수정 → 동일 요청 재시험 → 정상 요청 재시험`

이 순서를 반복하면 탐지 정책 개선의 효과와 부작용을 모두 평가할 수 있다.

### ④ WAF는 애플리케이션 수정의 대체재가 아님

FortiWeb의 차단은 방어 계층 하나를 추가하는 것이다. SQL 파라미터 바인딩, 안전한 파일 경로 처리, 출력 인코딩, Bash 업데이트 등 **근본적인 취약점 수정도 필요**하다.

---

## 12. 면접 대비 Q&A

**Q1. Reverse Proxy 방식의 WAF란?**  
A. 클라이언트 요청을 WAF가 먼저 수신해 검사한 뒤 허용된 요청을 실제 웹 서버로 전달하는 방식이다.

**Q2. FortiWeb에서 Server Pool, Virtual Server, Server Policy의 차이는?**  
A. Server Pool은 실제 백엔드 서버, Virtual Server는 WAF가 요청을 받는 논리적 수신 지점, Server Policy는 둘을 연결하고 보호 프로필을 적용하는 정책이다.

**Q3. `Alert_Deny`가 의미하는 것은?**  
A. 해당 요청이 탐지되어 차단 조치를 받았음을 뜻한다. 실제 상세 로그의 Action을 확인해야 한다.

**Q4. `robots.txt`가 탐지된 이유는?**  
A. `ParamUrl`의 `robots.txt`가 File Injection 시그니처 `050070012`에 일치했다. 실습 맥락에서는 정상 요청 오탐 가능성이 높다.

**Q5. 기본 WAF 정책에서 Path Traversal이 통과한 이유는?**  
A. 해당 테스트 패턴이 당시 적용된 탐지·차단 규칙에 걸리지 않았기 때문이다. 정확한 제품 내부 판단 이유는 정책 및 상세 로그 확인이 필요하다.

**Q6. Custom Signature를 적용하면 모든 Path Traversal이 차단되는가?**  
A. 아니다. 정의된 패턴과 검사 대상에 맞는 요청만 탐지하며, 인코딩·정규화·예외 처리에 따라 결과가 달라질 수 있다.

**Q7. XSS와 OS Command Injection의 가장 큰 차이는?**  
A. XSS는 일반적으로 사용자의 브라우저에서 스크립트가 실행되고, OS Command Injection은 서버 운영체제에서 명령이 실행될 수 있다는 점이다.

**Q8. HTTP 200이나 500만 보고 공격 성공 여부를 판단할 수 있는가?**  
A. 아니다. 실제 응답 내용, 서버 로그, 애플리케이션 동작 등을 함께 확인해야 한다.

**Q9. WAF와 Snort IDS의 차이는?**  
A. Snort IDS는 패킷·트래픽 탐지에 초점을 두고, Reverse Proxy WAF는 웹 요청을 중간에서 검사하고 정책에 따라 차단할 수 있다.

**Q10. 오늘 실습을 면접에서 어떻게 설명할 것인가?**  
A. “교육용 취약 웹 서버에 대해 웹 공격을 재현하고 Snort 및 Apache 로그를 분석했습니다. 이후 FortiWeb을 Reverse Proxy로 배치해 기본 보호 정책을 검증했고, 기본 정책에서 통과한 Path Traversal 요청에 사용자 정의 시그니처를 적용하여 탐지·차단 결과를 비교했습니다. 정상 요청 오탐 사례도 함께 분석했습니다.”

---

## 13. 집에서 복습할 때의 추천 루틴

**반드시 격리된 개인 교육용 VM에서만 진행한다.**

- [ ] ① SQLi: 정상 검색과 조작된 검색 결과 비교
- [ ] ② XSS: 출력 인코딩 유무에 따른 브라우저 동작 비교
- [ ] ③ OS Command Injection: 셸 메타문자가 위험해지는 조건 설명
- [ ] ④ Path Traversal: 경로 정규화 및 허용 경로 검증 이해
- [ ] ⑤ HTML Injection: HTML 구조가 바뀌는 과정 확인
- [ ] ⑥ LFI/RFI: 파일 참조·파일 포함·코드 실행의 차이 정리
- [ ] ⑦ Shellshock: CGI와 Bash 환경 변수 전달 구조 복습
- [ ] ⑧ Snort 탐지 로그와 FortiWeb 차단 로그를 나란히 비교
- [ ] ⑨ 정상 요청 오탐 여부 재검증
- [ ] ⑩ 모든 실습에 대해 “원인 → 관찰 → 로그 → 방어” 4줄 요약 작성


---


