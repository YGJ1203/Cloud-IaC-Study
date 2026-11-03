# 2026-11-03 보안 실습 총정리

> KDT 클라우드·보안 과정 | Kali Linux · Metasploit · Wireshark · Windows · Burp Suite · SET · Ettercap  
> **범위:** 대화에서 제공된 명령어·출력·스크린샷 기준. 확인되지 않은 성공 여부는 추정하지 않음.  
> **주의:** 승인된 격리 실습 환경 전용. 실제 호스트에 대한 원격 세션 및 피싱/랜섬웨어 실습은 별도의 위험이 있으므로 추가 실행보다 증거 보존·정리를 우선한다. 비밀번호·인증 토큰·활성화 코드는 마스킹했다.

## 0. 오늘의 핵심 요약

| 영역 | 실습 내용 | 확인된 결과 |
|---|---|---|
| Nessus | Docker Compose 기반 취약점 스캐너 실행 시도 | `License already in use` 오류; 해결 미완료 |
| IPID | Metasploit `ipidseq` 및 Wireshark Identification 확인 | 일부 호스트에서 순차 증가형 IPID 관찰 |
| 포트 스캔 | SYN 스캐너 및 Nmap Idle Scan | 대상 CentOS의 다수 열린 포트 식별 |
| SMB | SMB 버전 탐지와 MS17-010 점검 | Windows 2008 R2 / Windows 7에 `likely VULNERABLE` 결과 |
| Meterpreter | Windows 7 실습 VM 원격 세션 | 세션 연결, 프로세스·화면·키 입력·파일 조작 등 실습 |
| 지속성 | 시작프로그램 경로에 테스트 EXE 배치 후 재부팅 | 재부팅 후 역방향 세션 재연결 관찰 |
| 랜섬웨어 모의 | 테스트 프로그램 실행 | 금전 요구 문구 및 `.smile` 확장자 파일 발견; 실제 암호화는 미확인 |
| Windows 10 호스트 | 호스트에서 테스트 EXE 직접 실행 | Kali에서 호스트로부터의 Meterpreter 세션 확인 |
| 웹 보안 | Burp Suite와 bWAPP | 취약 웹 앱 초기 페이지 접근; Intercept는 off |
| 사회공학 | SET Google·GitHub·Netflix 로그인 양식 실습 | 테스트 POST 입력값이 Harvester 로그에 기록 |
| DNS | Ettercap `dns_spoof` | `www.netflix.co.kr`에 대한 위조 A 응답 로그 관찰 |

---

## 1. 실습 환경과 주소 체계

| 호스트 | 주소 | 확인 근거 / 역할 |
|---|---|---|
| Kali Linux | `192.168.20.50` | 스캐너, SET 웹 서버, 역방향 세션 수신 |
| CentOS | `192.168.20.200` | SYN/Idle Scan 대상 |
| Windows Server 2008 R2 | `192.168.20.201` | SMB 버전·MS17-010 점검 |
| Windows 7 Ultimate SP1 | `192.168.20.202` | SMB 점검, Idle Scan의 Zombie, Meterpreter 실습 대상 |
| Metasploitable2 | `192.168.20.204` | SMB 및 서비스 탐지 대상 |
| bWAPP | `192.168.20.205` | 웹 취약점 학습용 애플리케이션 |
| Windows 10 호스트 | `192.168.20.1` | VMware 실행 호스트; 사용자 직접 테스트 EXE 실행 |

**주의:** IP는 당시 로컬 실습망 주소이며, 실제 외부 서비스 주소가 아니다. 서로 다른 실습 시점의 결과를 한 번의 동시 실행 상태로 오해하지 않는다.

## 2. Nessus Docker 실행 문제

- 사용 이미지: `tenableofficial/nessus:10.6.3`.
- Docker Compose에서 Nessus와 CentOS/Metasploitable2 관련 환경을 구성한 것으로 기록됨.
- Nessus 시작 과정에서 **`License already in use`** 오류 발생.
- 새 Tenable 계정과 새 활성화 코드를 사용했지만 해결되지 않았음.
- **최종 상태:** 강사와 함께 추후 점검하기로 결정. 성공적으로 기동되었다고 기록하지 말 것.
- 확인할 항목: 라이선스 유형 및 등록 상태, 이전 활성화 여부, 컨테이너 데이터 볼륨과 등록 상태. 실제 활성화 코드는 문서에 저장하지 않음.

## 3. IPID 패턴과 Idle Scan

### 3.1 IP Identification 개념

IPv4 헤더의 **Identification(IPID)** 필드는 단편화된 패킷을 재조립할 때 사용되는 식별값이다. 운영체제/네트워크 스택에 따라 값의 생성 패턴이 다르며, 일부 시스템에서는 패킷 전송에 따라 순차적으로 증가한다.

- `Incremental`: 관측한 IPID 값이 순차적으로 증가하는 패턴.
- `All zeros`: 관측한 응답에서 IPID가 0으로 나타난 패턴.
- **주의:** `Incremental`이라는 결과만으로 항상 신뢰할 수 있는 Idle Scan Zombie라는 뜻은 아니다. 다른 통신에 의한 IPID 변화, 호스트별·연결별 IPID 할당 방식, 방화벽 등에 영향을 받는다.

### 3.2 IPID 탐지 기록

Metasploit 모듈: `auxiliary/scanner/ip/ipidseq`  
스캔 범위: `192.168.20.0/24`, 인터페이스 `eth1`, 스레드 16.

| 탐지 결과 | 호스트 |
|---|---|
| Incremental | `.1`, `.201`, `.202` |
| All zeros | `.100`, `.200`, `.204` |

Wireshark에서는 Windows 7(`.202`)이 Kali(`.50`)로 보내는 패킷들의 **IPv4 Identification** 값을 비교하여 서서히 증가하는 모습을 확인했다.

### 3.3 Idle Scan 관찰

실습에서 사용한 Nmap 명령 기록:

```bash
# 승인된 실습망에서 수행한 기록
 db_nmap -Pn -sI 192.168.20.202 192.168.20.200
```

- Zombie: Windows 7 `192.168.20.202`.
- 스캔 대상: CentOS `192.168.20.200`.
- 관찰: Nmap이 13개 열린 TCP 포트를 보고했고, 987개 포트를 `closed|filtered`로 보고함.
- **원리:** 스캔 측이 Zombie의 주소를 출발지로 위장한 패킷을 보내고, Zombie의 IPID 변화로 대상 포트의 상태를 간접 추론한다.
- **해석 주의:** 대상의 패킷 캡처에 `.202 → .200`으로 보이는 SYN이 있더라도 실제 전송 주체가 `.202`라고 단정하면 안 된다. 위조된 출발지 주소일 수 있다.

Wireshark 사례:

| 프레임 | 출발지 → 목적지 | 요약 |
|---|---|---|
| 481 | `.50 → .202` | TCP SYN/ACK 탐침 |
| 482 | `.202 → .50` | TCP RST 응답, IPID `0x0f40` = **3904** |
| 483 | `.202 → .200` | 출발지 위장 가능성이 있는 SYN |
| 484 | `.200 → .202` | SYN/ACK |
| 485 | `.202 → .200` | RST |

**분석 포인트:** IPID 증가 여부는 **동일 호스트가 발신한 여러 패킷**을 비교해야 한다. Kali가 발신한 481번과 Windows 7이 발신한 482번의 IPID를 서로 비교하는 것은 적절하지 않다.

## 4. 포트 스캔과 SMB 취약점 점검

### 4.1 Metasploit SYN 스캐너

사용 모듈: `auxiliary/scanner/portscan/syn`.

```text
INTERFACE = eth1
PORTS     = 1-1000
RHOSTS    = 192.168.20.200
THREADS   = 16
```

실행 출력에 TCP `21`, `22`, `23`, `25` OPEN이 표시되었으며, **Ctrl+C로 중단**했다. 따라서 이 SYN 스캔 출력만으로 1~1000번 전체 포트 탐지가 완료되었다고 주장할 수 없다.

별도의 Nmap/Idle Scan 결과에서 CentOS의 열린 TCP 포트 13개가 확인되었다.

```text
21 ftp       22 ssh       23 telnet     25 smtp
53 dns       80 http      110 pop3     111 rpcbind
143 imap     443 https    993 imaps    995 pop3s
3306 mysql
```

### 4.2 SMB 버전 탐지

모듈: `auxiliary/scanner/smb/smb_version`  
범위: `192.168.20.0/24`.

| 호스트 | 탐지 결과 | SMB 프로토콜 |
|---|---|---|
| `.1` | SMB 서버 응답, 인증 도메인 `501-11` | 2, 3 (선호 3.1.1) |
| `.50` | Kali, 인증 도메인 `KALI` | 2, 3 (선호 3.1.1) |
| `.201` | Windows Server 2008 R2 Enterprise SP1, `WIN2008` | 1, 2 (선호 2.1) |
| `.202` | Windows 7 Ultimate SP1, `MSDN-SPECIAL` | 1, 2 (선호 2.1) |
| `.204` | Unix / Samba 3.0.20-Debian | 1 |

**SMBv1**은 오래된 프로토콜로, 운영 환경에서는 사용 중지·대체 여부를 우선 검토한다. SMB 서명 `optional`은 서명이 필수가 아니라는 탐지 결과이며, 해당 호스트가 반드시 공격에 성공한다는 의미는 아니다.

### 4.3 MS17-010 진단

모듈: `auxiliary/scanner/smb/smb_ms17_010`.

| 호스트 | 스캐너 출력 | 해석 |
|---|---|---|
| `.201` | `Host is likely VULNERABLE` | 취약 가능성 높음, Windows Server 2008 R2 SP1 x64 |
| `.202` | `Host is likely VULNERABLE` | 취약 가능성 높음, Windows 7 SP1 x64 |
| `.204` | `Host does NOT appear vulnerable` | 해당 점검에서 취약 징후 미발견 |
| `.1` | `SMB Login Error ... IPC$ tree` | 인증/접속 오류, 취약 여부 판정 불가 |
| `.0` | `HostUnreachable` | 입력 주소 파싱 또는 범위 지정 확인 필요 |

**중요:** `likely VULNERABLE`은 진단 도구의 판정이지 실제 원격 코드 실행 성공을 증명하지 않는다. 패치·SMB 설정·보안 장비·정확한 대상 범위를 추가 확인해야 한다.

## 5. Meterpreter: Windows 7 원격 세션 실습

### 5.1 역방향 세션 생성 관찰

Kali 측 수신: `192.168.20.50:4444`.  
Windows 7 측: `192.168.20.202`.

```text
Meterpreter session 1 opened
192.168.20.50:4444 -> 192.168.20.202:49174
```

- 페이로드 유형: `windows/x64/meterpreter/reverse_tcp`.
- 테스트 실행 파일은 `ZoomInstallerFull.exe`라는 이름과 Zoom 유사 아이콘으로 구성했다고 설명함.
- 실제 Zoom 설치 프로그램이 아니라 **사용자가 실습용으로 만든 EXE**임.
- Windows 7에서 해당 파일을 실행한 후 세션 생성 및 `netstat -ntp`의 `ESTABLISHED` 연결을 관찰함.
- 실행 파일 아이콘과 파일명만으로 프로그램의 신뢰성을 판단할 수 없다는 사례.

### 5.2 원격 기능 관찰

| 기능 | 관찰 내용 | 보안상 의미 |
|---|---|---|
| `ps` | 실행 중인 프로세스 목록 조회 | 프로세스 가시성 |
| `screenshot` | Windows 7 바탕화면 이미지 생성 | 화면 정보 노출 |
| `getdesktop` / `setdesktop` | `WinSta0\Default` 확인 | 대화형 데스크톱 접근 |
| `keyscan_start` / `keyscan_dump` | 메모장에 입력한 테스트 문자열 수집 | 키 입력 정보 노출 |
| `kill` | `notepad.exe` 종료 | 원격 프로세스 제어 |
| `shell` | Windows 명령 셸 실행 | OS 명령 실행 가능성 |
| `reboot` | 재부팅 후 세션 종료 | 시스템 가용성 영향 |
| `ls` / `upload` / `rm` | 파일 목록·전송·삭제 확인 | 파일 무결성·기밀성 위험 |

키 입력 테스트에는 `notepad`, `abcd`, 숫자, `LeBron James is GOAT` 등 실습 문자열이 사용되었다. 실제 비밀번호를 수집했다는 근거는 없다.

### 5.3 권한과 프로세스 이동

```text
getsystem
...got system via technique 1 (Named Pipe Impersonation (In Memory/Admin)).

ps explorer.exe
PID 2300 ... explorer.exe ... MSDN-SPECIAL\Administrator

migrate 2300
[*] Migration completed successfully.
```

- `getsystem` 출력은 **SYSTEM 권한 획득 성공**을 표시한다.
- `migrate`는 Meterpreter 실행 컨텍스트를 다른 프로세스로 옮기는 기능이며, 출력상 `explorer.exe`로 이동 성공.
- **구분:** 프로세스 이동 자체가 새로운 권한 상승을 의미하지는 않는다. 현재 토큰·프로세스 무결성 수준·실제 권한은 별도 검증해야 한다.

### 5.4 파일 전송 및 삭제

Windows 7 `Administrator\Desktop`에서 `password.txt` 등 기존 파일 목록 확인. 실습에서는 Kali의 `/etc/issue`를 `issue`라는 파일로 전송해 30바이트 생성 후 삭제했다.

- `upload` → `ls`에서 새 파일 확인.
- `rm` → `ls`에서 해당 파일 사라짐 확인.
- 기존 `password.txt`는 **목록에서 확인되었을 뿐 내용 열람이나 탈취가 입증되지 않음**.

## 6. 시작프로그램과 재부팅 후 연결: 지속성 관찰

Windows 7의 사용자 시작프로그램 폴더에서 실습용 EXE 파일 존재를 확인했다.

```text
C:\Users\Administrator\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup
ZoomInstallerFull.exe (7168 bytes)
```

이후 재부팅했을 때:

```text
192.168.20.50:4444 -> 192.168.20.202:49158
Meterpreter session 1 opened ... 2026-11-03 15:10:26 +0900
```

**해석:** 시작프로그램 위치에 파일이 배치되어 있고 재부팅 후 세션이 재생성된 정황이 일치한다. 지속성(Persistence)의 대표적 개념을 보여준다. 단, 자동 실행 원인을 완전히 확정하려면 Windows의 실행 기록과 시작프로그램 항목을 함께 검증해야 한다.

- 관련 MITRE ATT&CK: **T1547.001 — Registry Run Keys / Startup Folder**.
- 방어 관점: 시작프로그램 폴더, Run 키, 예약 작업, 새 프로세스 생성 및 외부 연결 이벤트 점검.

## 7. 랜섬웨어 모의 프로그램과 `.smile` 파일

Windows 7 실습 VM에 `wanna_smile.exe`라는 테스트 파일이 존재했고, 실행 화면에 다음과 같은 문구가 관찰되었다.

```text
0 I need bitcoin
1 I need bitcoin
2 I need bitcoin
```

또한 Windows 탐색기의 `smile` 검색 결과에 **32개 항목**이 표시되었다. 예:

```text
FXSAPIDebugLogFile.txt.smile
FXSTIFFDebugLogFile.txt.smile
ReAgent.xml.smile
Ultimate.xml.smile
```

- 다수 파일의 수정 시각: **2026-11-03 오후 3:14**.
- 일부 경로: `C:\Windows\Temp`, `C:\Windows\System32`, `C:\Windows\SysWOW64` 등.
- `C:\wanna_smile` 폴더도 검색 결과에 보임.
- **확인된 사실:** 확장자 변경 또는 파일명 변조 정황, 금전 요구 문자열.
- **미확인:** 실제 암호화 알고리즘 사용 여부, 파일 원본 복구 가능성, 전체 영향 범위.

검증 시에는 원본·변조 파일의 해시, 파일 헤더, 내용, 생성/수정 시각, 이벤트 로그를 비교한다. 추가 실행하지 말고 VM 스냅샷을 보존한다.

관련 ATT&CK: 실제 암호화가 확인되면 **T1486 — Data Encrypted for Impact**에 해당할 수 있다. 현재 기록만으로 T1486 성공을 단정하지 않는다.

## 8. 실제 Windows 10 호스트에서의 실행 실습

사용자가 VMware를 실행하는 **실제 Windows 10 호스트에서 테스트 EXE를 직접 더블클릭**했다고 명시했다.

```text
Meterpreter session 1 opened
192.168.20.50:4444 -> 192.168.20.1:52702

Computer      : 501-11
OS            : Windows 10 (10.0 Build 19045)
Architecture  : x64
Meterpreter   : x64/windows
```

**해석:** 취약점 익스플로잇 성공이 아니라, 호스트에서 사용자가 실행한 프로그램이 Kali VM의 리스너로 역방향 연결한 사례다. 게스트 VM의 네트워크 접근 가능 범위에 호스트가 포함될 수 있음을 보여준다.

**안전 조치:** 실제 호스트에서 테스트 프로세스·세션 종료, 시작프로그램/예약 작업 점검, 보안 검사, 비의도적 연결 여부 확인. 랜섬웨어 및 지속성 실습은 격리 VM에서만 진행한다.

## 9. Burp Suite + bWAPP 웹 보안 기초

- 도구: **Burp Suite Community Edition v2021.8.2**.
- 웹 앱: **bWAPP** (`192.168.20.205`).
- Firefox에서 bWAPP 초기 페이지 표시.
- 페이지에 `bWAPP`, `Drupalgeddon`, `Evil folder`, `phpMyAdmin`, `SQLiteManager` 링크가 보임.
- Burp 화면은 **Proxy → Intercept**, 상태는 `Intercept is off`.

| 개념 | 설명 |
|---|---|
| Proxy | 브라우저와 서버 사이에서 HTTP(S) 트래픽 관찰·분석 |
| Intercept on | 요청/응답을 중간에 멈춰 검토할 수 있음 |
| Intercept off | 요청을 붙잡지 않음. 프록시를 경유한다면 HTTP history에 남을 수 있음 |
| bWAPP | 취약점 학습용으로 의도적으로 취약하게 구성된 웹 앱 |

**확인 범위:** 초기 페이지 접근까지. 실제 SQL Injection, XSS, 인증 우회 등의 취약점 성공은 이번 스크린샷에서 확인되지 않는다.

## 10. SET: 웹 로그인 양식과 POST 데이터 분석

도구: **Social-Engineer Toolkit (SET) v8.0.3**. 실습에서 Google 템플릿, GitHub 로그인 양식, Netflix 로그인 양식의 **테스트용** 입력 데이터를 관찰했다.

> 이 절은 관찰된 동작과 방어 분석만 정리한다. 실제 서비스 이용자를 속이기 위한 배포 절차, 자격 증명 탈취 자동화 또는 외부 전파 방법은 포함하지 않는다.

### 10.1 Google 템플릿

- Windows 7 브라우저 주소창: `192.168.20.50`.
- 화면은 Google 로그인 양식과 유사하게 표시.
- SET 콘솔에 `Email`, `Passwd`, `signIn` 등의 POST 필드가 출력됨.
- 테스트 계정 입력값이 기록되었으나 **Google 로그인 성공을 의미하지 않음**.

### 10.2 GitHub 로그인 양식

- 복제 대상으로 지정한 URL: `https://github.com/login`.
- SET 로그에서 파일이 `/var/www/html`에 배치되었다고 출력.
- POST 로그에 `login`, `password`, `authenticity_token`, `webauthn-*`, `return_to`, `timestamp`, `commit` 필드가 포함됨.
- 예시 테스트 계정: `lebron@goat.com`; 비밀번호는 **[마스킹]**.
- `authenticity_token`은 일반적으로 CSRF 방어용 필드지만, **복제 페이지에서 수집된 값의 유효성이나 실제 GitHub 인증 성공은 입증되지 않음**.

### 10.3 Netflix 로그인 양식

로그에서 관찰한 주요 POST 필드:

| 필드 | 의미 / 해석 |
|---|---|
| `userLoginId` | 로그인 식별자; 테스트 값 `kd@burner.com` |
| `password` | 입력된 테스트 비밀번호 **[마스킹]** |
| `rememberMe` | 로그인 유지 선택값 (`true`) |
| `flow`, `mode`, `action` | 로그인 폼 처리 흐름 관련 값 |
| `countryCode`, `countryIsoCode` | `+82`, `KR` |
| `authURL` | 인증 흐름 관련 값으로 보이나 정확한 검증 의미는 불명 |
| `recaptchaResponseToken` | reCAPTCHA 관련 필드 **[토큰 생략]** |
| `recaptchaResponseTime` | 응답 시간 관련 값 (`24`) |

`recaptchaResponseToken`이 존재한다고 해서 CAPTCHA 검증을 통과한 것은 아니다.

### 10.4 PHP 저장 로직 읽기

제공된 `post.php`에서 확인된 PHP 함수의 역할:

| 구성 요소 | 설명 |
|---|---|
| `$_POST` | HTTP POST 폼 필드 배열 |
| `print_r(..., true)` | 배열 내용을 문자열로 변환 |
| `file_put_contents(...)` | 파일에 문자열 기록 |
| `FILE_APPEND` | 기존 파일 뒤에 이어서 기록 |
| `meta refresh` | 브라우저에 다른 페이지로 이동하라는 지시 |

관찰된 파일 구조:

```text
/var/www/html/
├── index.html
├── post.php
└── harvester_2026-11-03_*.txt
```

**핵심:** 로그인 성공 여부와 무관하게 제출된 폼 데이터가 **평문 텍스트 로그**로 기록되었다. 이후 정상 사이트로 이동하는 화면이 나타나더라도 그 이전에 정보가 수집되었을 가능성을 배제할 수 없다.

**위험:** 웹 루트(`/var/www/html`)에 수집 로그를 두면 HTTP를 통한 파일 노출 가능성도 점검해야 한다. 실습 종료 후 테스트 데이터를 정리하고 실제 계정·토큰을 절대 사용하지 않는다.

### 10.5 관련 MITRE ATT&CK

- **T1056.003 — Input Capture: Web Portal Capture:** 위장 웹 포털을 통한 입력 정보 수집.
- **T1036 — Masquerading:** 정상 서비스와 유사한 외관을 이용한 위장.
- **T1566 — Phishing:** 실제 피싱 메시지/유인 단계가 있었다면 관련될 수 있으나, 이번 기록에는 외부 사용자에게 피싱 메시지를 보냈다는 근거가 없음.
- **T1204.002 — User Execution: Malicious File:** 테스트 EXE를 사용자가 직접 실행한 실습과 관련.

## 11. Ettercap DNS Spoofing과 SET 연계 원리

Ettercap **v0.8.3.1 (EB)** 화면에서 `dns_spoof` 플러그인(v1.3)이 선택되어 있었고, 다음 로그가 반복적으로 보였다.

```text
dns_spoof: A [www.netflix.co.kr] spoofed to [192.168.20.50] TTL [3600 s]
```

| 항목 | 해석 |
|---|---|
| 도메인 | `www.netflix.co.kr` |
| DNS 레코드 | A (IPv4 주소) |
| 위조 응답 주소 | `192.168.20.50` (Kali) |
| TTL | 3600초 |

**역할 구분**

1. DNS 위조: 도메인에 대한 응답 IP를 바꾸도록 시도.
2. 웹 서버: 요청을 받은 서버에서 웹 콘텐츠 제공.
3. HTTP POST: 폼 제출 데이터가 서버에 전달됨.
4. 서버 로그: 전달된 입력값이 기록됨.

**중요한 검증 한계**

- Ettercap 로그는 **위조 DNS 응답이 생성되었다는 증거**이지, 클라이언트가 반드시 이를 수용했다는 증거는 아니다.
- `www.netflix.co.kr`과 `www.netflix.com`은 **서로 다른 호스트명**이다.
- DNS 응답 변경만으로 **HTTPS 인증서 검증이 우회되지 않는다**. 인증서 오류, HSTS, 브라우저 정책 등에 의해 접속이 차단될 수 있다.
- DNS 위조와 SET의 POST 수집이 모두 관찰되었지만, 두 사건이 실제로 동일 브라우저 세션에서 연속적으로 연결되었는지는 패킷 캡처/브라우저 기록이 추가로 필요하다.

## 12. 네트워크·웹·시스템 보안의 연결

| 단계 | 관찰 기술 | 핵심 보안 관점 |
|---|---|---|
| 자산 식별 | Nmap, Metasploit 스캐너 | 공격 표면·노출 서비스 |
| 취약점 점검 | SMB 버전, MS17-010 | 패치 및 레거시 프로토콜 |
| 트래픽 분석 | Wireshark IPID, TCP | 패킷 수준 근거 |
| 원격 세션 | Meterpreter | 실행 권한·원격 접근 위험 |
| 지속성 | Startup 폴더 | 재부팅 후 자동 실행 탐지 |
| 영향 | `.smile` 파일·금전 요구 문구 | 파일 무결성·가용성 |
| 웹 요청 | Burp Suite, bWAPP | HTTP 헤더·폼·세션 |
| 사회공학 | 위장 로그인 페이지 | 사용자 신뢰·자격 증명 노출 |
| 네트워크 변조 | Ettercap DNS Spoofing | DNS 무결성·HTTPS 검증 |

## 13. 실무 대응 체크리스트

- [ ] 실습 VM 스냅샷과 스크린샷/로그의 시각 보존.
- [ ] 실제 Windows 10 호스트의 테스트 프로세스와 원격 세션 종료.
- [ ] Windows 시작프로그램, Run 키, 예약 작업의 의도치 않은 항목 점검.
- [ ] 실제 호스트에서 Microsoft Defender 검사 수행.
- [ ] Windows 7 VM의 `.smile` 파일은 추가 실행 없이 증거 보존 후 원본과 비교.
- [ ] `harvester_*.txt` 및 보고서에서 비밀번호·토큰 마스킹.
- [ ] Apache 웹 루트에 민감한 로그가 노출되지 않는지 확인.
- [ ] 실습 종료 후 웹 서버/리스너/위조 응답 기능을 종료하고 격리망을 원복.
- [ ] Nessus 라이선스 오류는 강사와 함께 추후 해결; 코드 재노출 금지.

## 14. 면접 대비 핵심 Q&A

**Q1. TCP SYN Scan과 Idle Scan의 차이는?**  
A. SYN Scan은 스캐너가 대상에 SYN을 보내 응답을 분석한다. Idle Scan은 별도 Zombie 호스트의 IPID 변화를 활용해 대상 포트 상태를 간접 추론한다. Idle Scan에는 적절한 IPID 패턴과 낮은 외부 트래픽 등 조건이 필요하다.

**Q2. IPID가 순차적으로 증가하면 무조건 Idle Scan이 가능한가?**  
A. 아니다. IPID 생성 방식, 다른 트래픽, NAT·방화벽 등으로 결과가 달라질 수 있다.

**Q3. MS17-010 스캐너의 `likely VULNERABLE`은 무엇을 의미하나?**  
A. 취약 가능성이 높다는 탐지 결과이며, 실제 익스플로잇 성공이나 모든 조건의 충족을 보증하지 않는다.

**Q4. Reverse TCP는 무엇인가?**  
A. 대상 시스템에서 수신 측으로 TCP 연결을 먼저 개설하는 방식이다. 실습에서 Windows가 Kali `:4444`로 연결했다.

**Q5. 프로세스 마이그레이션과 권한 상승은 같은가?**  
A. 아니다. 마이그레이션은 실행 컨텍스트 이동이고, 권한 상승은 더 높은 권한 확보다. 실제 권한은 별도 확인해야 한다.

**Q6. Startup 폴더는 왜 위험한가?**  
A. 해당 사용자 로그인 시 프로그램 자동 실행에 사용될 수 있어 악성 프로그램의 지속성 수단으로 악용될 수 있다.

**Q7. 확장자가 `.smile`로 바뀌면 암호화된 것인가?**  
A. 반드시 그렇지 않다. 파일명 변경과 실제 내용 암호화는 구분해야 하며 해시·헤더·내용 비교가 필요하다.

**Q8. Burp의 `Intercept is off`는 트래픽 기록도 꺼졌다는 뜻인가?**  
A. 아니다. 프록시를 경유하는 경우 HTTP history에는 기록될 수 있다.

**Q9. `$_POST`와 `FILE_APPEND`는 무엇인가?**  
A. `$_POST`는 폼 제출 데이터 배열, `FILE_APPEND`는 파일 끝에 내용을 추가하는 옵션이다. 인증 정보를 평문 로그에 남기는 것은 보안 위험이다.

**Q10. CSRF 토큰이 보이면 정상 사이트인가?**  
A. 아니다. 복제 HTML에도 숨겨진 토큰 필드가 포함될 수 있으며, 실제 서버 검증 여부는 별개다.

**Q11. DNS Spoofing만으로 HTTPS도 우회할 수 있는가?**  
A. 아니다. DNS 주소 변경과 TLS 인증서의 신뢰성 검증은 다른 보안 계층이다.

**Q12. 가상머신에서 수행한 실습은 호스트 PC에 영향을 주지 않는가?**  
A. 아니다. 네트워크 연결, 공유 폴더, 호스트에서의 직접 실행 등에 따라 호스트에도 영향이 발생할 수 있다.

## 15. GitHub README용 한 문단 요약

2026-11-03에는 Kali Linux 기반의 IPID 패턴 분석과 Idle Scan, TCP SYN 포트 스캔, SMB 버전 및 MS17-010 취약점 점검을 수행했다. Windows 7 실습 VM에서는 Meterpreter 원격 세션의 프로세스·화면·파일 조작 기능과 시작프로그램 기반 재실행 정황을 관찰했고, 랜섬웨어 모의 실행에서 `.smile` 확장자 파일과 금전 요구 문구를 확인했다. 또한 Burp Suite와 bWAPP의 웹 분석 환경, SET을 이용한 테스트 로그인 폼 POST 데이터 기록, Ettercap의 DNS 위조 응답 로그를 분석했다. 각 결과는 관찰 사실과 미확인 사항을 구분하여 기록했으며 실제 계정·비밀번호·토큰은 공개하지 않았다.

---

### 오늘의 한 줄 결론

> **스캐닝은 노출을 보여주고, 패킷은 원리를 보여주며, 로그는 발생한 일을 증명한다. 단, 관찰된 정황과 검증된 사실을 구분하는 것이 보안 분석의 핵심이다.**

*부록: NBA 테마 테스트 문자열은 학습용 가상 데이터로만 취급. 르브론·KD 관련 계정/비밀번호는 실제 계정으로 간주하지 않으며, 문서에는 비밀번호를 기록하지 않음.* 🏀
