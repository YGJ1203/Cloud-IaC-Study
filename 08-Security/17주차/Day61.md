# 2026-10-28 네트워크·보안 실습 총정리

> **주제:** 네트워크 공격 트래픽 관찰, ARP 스푸핑, Scapy 패킷 생성, Nmap/Zenmap 스캔, NSE 취약점 진단  
> **환경:** Kali Linux / CentOS(192.168.20.200) / 실습용 추가 호스트(.201, .202, .204) / VMware / Wireshark  
> **정리 원칙:** 2026-10-28 대화의 터미널 출력·스크린샷과 제공된 로그 3개를 우선 근거로 사용. 이론·방어 권고는 별도 설명.  
> **안전 범위:** 공격성 트래픽·인증 시도는 허가된 격리 실습망에서만 수행. 공개 서비스에는 허가 없이 스캔하지 않는다.

---

## 목차
1. 실습 환경 및 전체 흐름
2. 네트워크 확인과 Nmap 기본 서비스 탐색
3. hping3 / Metasploit SYN Flood와 UDP Flood
4. Wireshark·netstat·GNOME System Monitor 분석
5. ARP Spoofing 및 Telnet 평문 통신
6. Scapy ICMP Flood와 ICMP LAND
7. Nmap TCP 스캔 6종 비교
8. Nmap UDP 스캔과 ARP Ping Scan
9. Zenmap 종합 스캔 `-T4 -A -v`
10. NSE 보안 진단: MS17-010, MySQL, POODLE, WAF
11. 결과 판정 시 주의사항
12. 실무 대응 및 점검 체크리스트
13. 면접·시험 Q&A
14. 복습 치트시트 및 캡처 자료

---

## 1. 실습 환경 및 전체 흐름

| 역할 | 확인된 주소/정보 | 비고 |
|---|---|---|
| Kali Linux | `192.168.20.50` | 스캔·패킷 실습 수행, `eth1` 캡처 |
| CentOS 서버 | `192.168.20.200` | HTTP 80, SSH 22, Telnet 23, DNS 53, MySQL 3306 등 |
| 실습 호스트 | `192.168.20.201` | Telnet 통신 관찰, SMBv1 진단 대상 |
| 실습 호스트 | `192.168.20.202` | SMBv1 진단 대상 |
| 실습 호스트 | `192.168.20.204` | MySQL 빈 비밀번호 확인 |
| 실습 도구 | Wireshark, Nmap 7.91, Zenmap, hping3, Metasploit 6.1.4-dev, Scapy | 버전은 관찰된 출력 기준 |

**오늘의 학습 흐름**

```text
기본 연결 확인 → 포트/서비스 탐색 → 대량 패킷 실습 및 상태 관찰
   → ARP 스푸핑/Telnet 분석 → Scapy 패킷 구조 분석
   → TCP/UDP/ARP 스캔 비교 → Zenmap 종합 정보 수집
   → NSE 취약점 탐지 → 보안 진단 결과 해석
```

**주의:** 이 문서는 학습용 실습 기록이다. 패킷 송신 로그와 도구 판정만으로 서비스 장애, 실제 정보 유출 또는 원격 코드 실행까지 입증되었다고 간주하지 않는다.

## 2. 네트워크 확인과 서비스 탐색

### 2.1 ping·traceroute

- `ping -c 168.126.63.1`은 `-c` 뒤에 횟수가 없어 문법 오류. `ping -c 1 168.126.63.1`은 정상 수행.
- `traceroute 168.126.63.1`에서 초반 홉 `192.168.20.100` → `192.168.2.254` 확인, 이후 `*` 표시. 이는 후속 홉의 응답 미수신을 의미하며 목적지 완전 불통의 확정 증거는 아님.
- `192.168.20.200`, `.201` 등 일부 내부 대상에 대한 ping 응답 확인.
- `192.168.2.200`에는 `From 192.168.2.50 Destination Host Unreachable` 관찰. ICMP 오류를 발생시킨 장비와 실제 목적지를 구분해야 함.

### 2.2 서비스 버전 탐지

```bash
nmap -sS -sV 192.168.20.200
```

- `-sS`: SYN 기반 TCP 포트 스캔
- `-sV`: 서비스 및 버전 추정
- CentOS 서버에서 총 **13개 열린 TCP 포트** 확인. 상세 목록은 9장 참고.
- 버전 탐지 정보는 **취약점 조사 단서**이지, 해당 버전이라는 이유만으로 모든 CVE가 악용 가능하다는 증거는 아니다.

## 3. hping3 / Metasploit: 대량 패킷 실습

### 3.1 hping3 실습 기록

| 실습 유형 | 제공된 명령·조건 | 전송 기록 | 해석 |
|---|---|---:|---|
| 출발지 IP 위조 | `hping3 --interface eth1 192.168.20.200 --flood --spoof 1.2.3.4` | 113,055 | 기본 TCP 모드에서 출발지 IP 위조. ICMP 모드가 아님 |
| SYN Flood 1차 | `hping3 --interface eth1 --syn -p 80 192.168.20.200 --flood` | 362,434 | TCP 80 대상 SYN 전송 |
| SYN Flood 2차 | 위와 동일 | 309,662 | 반복 실습 |
| SYN Flood 3차 | 위와 동일 | 347,002 | 반복 실습 |
| UDP Flood | `hping3 --interface eth1 --udp -p 53 192.168.20.200 --flood` | **719,480** | UDP 53 대상 대량 전송 |

**중요한 해석:** hping3의 `--flood` 출력에 표시되는 `0 packets received`, `100% packet loss`는 flood 모드가 응답을 표시하지 않는 특성과 관련된다. 이것만으로 실제 패킷 손실률이 100%라거나 서비스가 중단되었다고 결론 내릴 수 없다.

### 3.2 Metasploit SYN Flood 모듈

실습에 등장한 흐름:

```text
msfconsole
search synflood
use 0
show options
set rhosts 192.168.20.200
set interface eth1
```

- 모듈: `auxiliary/dos/tcp/synflood`
- 대상: `192.168.20.200:80`
- `RHOSTS`: 대상 호스트, `RPORT`: 대상 포트, `INTERFACE`: 송신 인터페이스
- 첫 실행에서 `SYN flooding ...` 후 모듈 완료 메시지 관찰.
- 인터페이스 지정 후 재실행에서는 `Ctrl+C`로 중단.
- **완료 메시지는 서버 장애 발생의 증거가 아니다.**

### 3.3 SYN Flood 원리

```text
정상 TCP:   SYN → SYN/ACK → ACK → ESTABLISHED
SYN Flood: SYN → SYN/ACK → (마지막 ACK 미완료) → SYN_RECV 누적 가능
```

- 서버는 연결 수립 전 단계의 상태를 일정 시간 유지할 수 있다.
- 대량의 미완료 연결은 연결 대기 자원에 부담을 줄 수 있다.
- 다만 운영체제의 SYN cookie, backlog, 타임아웃 등의 설정에 따라 영향이 다르다.

## 4. Wireshark·netstat·GNOME System Monitor

### 4.1 CentOS `netstat` 기록

```bash
netstat -nt
netstat -ntp
```

관찰된 상태:

| 상태 | 의미 | 실습 연결 |
|---|---|---|
| `ESTABLISHED` | TCP 연결 확립 | `.200:23` ↔ `.201:49161` Telnet 연결 |
| `TIME_WAIT` | 연결 종료 후 대기 | 종료된 TCP 연결 |
| `SYN_RECV` | SYN 수신 후 연결 완료 대기 | `.200:80`에 다수의 미완료 연결 |

제공된 CentOS 로그 2개에는 `SYN_RECV` 행이 매우 많이 나타난다. 두 번째 로그에서는 위조되거나 비정상적인 출발지로 보이는 주소의 TCP 80 연결 대기 기록도 확인된다. **`SYN_RECV` 증가 자체는 공격성 트래픽과 일치하지만, 단독으로 서비스 거부 성공을 증명하지 않는다.**

### 4.2 GNOME System Monitor 해석

- CPU, 메모리/스왑, 네트워크 송수신 그래프를 관찰.
- 일부 스크린샷에서 CPU 사용률은 낮고 네트워크 사용률은 실시간 0B/s로 표시됨.
- **누적 전송량**과 **현재 초당 전송량**은 서로 다르다. 실습이 종료된 뒤 찍은 화면은 부하 최고점을 반영하지 않을 수 있다.
- 실습별 전후 CPU/메모리, 인터페이스 PPS/BPS, 웹 응답시간, 연결 대기 수를 함께 비교해야 영향도를 판정할 수 있다.

### 4.3 UDP 53 대량 전송의 Wireshark 표시

- `.50 → .200`, UDP 목적지 53 패킷이 대량 관찰됨.
- 일부가 Wireshark에서 `DNS [Malformed Packet]`으로 표시됨.
- 이유: UDP 53을 사용했다고 해서 페이로드가 정상 DNS 메시지인 것은 아니다. 해당 hping3 실행은 `0 data bytes`였으므로 DNS 디섹터가 해석할 구조가 부족할 수 있다.
- 따라서 **Malformed = DNS 서버 침해 성공**이 아니다.

## 5. ARP Spoofing과 Telnet 평문 통신

### 5.1 실습 코드의 핵심 구조

제공된 `arp_spoof.py`는 Scapy를 이용하여:

1. `srp(Ether(...)/ARP(pdst=ip))`로 대상 MAC 주소를 조회.
2. 두 대상 IP/MAC 관계에 대해 `ARP(op=2, ...)` 응답 패킷을 반복 송신.
3. `keyboard.is_pressed('q')`로 중단.

대상 입력값:

```text
타겟1: 192.168.20.200
타겟2: 192.168.20.201
```

**실습 관찰:** Wireshark에서 `arp`, `icmp`, `telnet` 필터를 사용하여 ARP, ICMP Redirect, Telnet 데이터를 분석했다. Telnet 흐름에서 **Follow → TCP Stream**으로 입력값이 보였다고 확인했다.

### 5.2 핵심 개념

- **ARP Spoofing:** 동일 LAN에서 IP와 MAC의 매핑을 거짓으로 알리는 기법.
- **MITM(중간자 공격):** 공격자가 통신 경로에 개입하는 상황. ARP 위조만으로 실제 패킷 중계 성공이 항상 보장되는 것은 아님.
- **Telnet:** 전송 내용이 기본적으로 암호화되지 않으므로 패킷을 읽을 수 있는 위치에서는 입력 데이터가 노출될 수 있음.
- **ICMP Redirect:** 라우팅 경로 변경을 알리는 메시지. 캡처에서 보였다고 해서 ARP Spoofing만으로 생성되었다고 단정하지 말 것.

### 5.3 실행 과정의 오류와 해결

```bash
mkdir -p attack_code & cd attack_code   # 백그라운드 실행으로 순서가 보장되지 않음
mkdir -p attack_code && cd attack_code  # 앞 명령 성공 후 디렉터리 이동
```

```text
python arp_spoof.py  → Non-ASCII character ... no encoding declared
python3 arp_spoof.py → 정상 실행
```

- 구형 `python`이 Python 2로 연결되어 비ASCII 한글 문자열에서 오류가 난 것으로 해석 가능.
- Python 3에서는 UTF-8 소스 사용이 일반적이며, 환경에 따라 인코딩 설정을 확인해야 한다.

### 5.4 방어

- Telnet 대신 SSH 사용.
- 네트워크 장비의 Dynamic ARP Inspection, DHCP Snooping 등 검토.
- 중요 서버 간 통신은 암호화하고, ARP 캐시 및 스위치 MAC 학습 정보 이상 여부를 점검.

## 6. Scapy: ICMP Flood 및 ICMP LAND

### 6.1 ICMP Flood 실습

- 파일: `icmp_flood.py`
- 목적지: `192.168.20.200`
- 입력한 전송 개수: **100개**
- `random.randint(0,255)`를 네 번 결합해 임의의 출발지 IP 생성.
- `IP(src=..., dst=...) / ICMP()` 형태로 Echo Request 패킷 구성.
- 터미널에 `1번 ... 100번 ICMP 전송 완료` 출력.
- Wireshark에서 다양한 출발지 IP와 ICMP Echo Request/Reply 관찰.

**구분:** 터미널의 전송 완료는 Scapy 송신 호출이 끝났다는 뜻이며 모든 패킷이 목적지에서 정상 처리되었다는 증거는 아니다. 임의의 출발지 IP를 사용하면 응답이 실제 Kali로 돌아오지 않을 수 있다.

### 6.2 ICMP LAND 실습

- 파일: `icmp_land.py`
- 목적지: `192.168.20.200`
- 전송 개수: **50개**
- 핵심 구성: `ip_packet.src = dstIP`, `ip_packet.dst = dstIP`
- Wireshark에서 `192.168.20.200 → 192.168.20.200` ICMP Echo Request 관찰.
- GNOME System Monitor에서 CPU/네트워크 그래프가 크게 요동치지 않았음.

**왜 부하가 적어 보였을까?** 50개 패킷은 짧은 부하이며, 대상 OS가 비정상 패킷을 처리·폐기할 수 있다. 고전적 LAND 공격은 출발지와 목적지가 같은 패킷의 처리 문제와 관련되지만, 이번 코드는 **ICMP 자기 자신 주소 패킷을 생성한 실습**이다. 이를 곧바로 고전적 TCP LAND 취약점 악용 성공으로 해석하면 안 된다.

## 7. Nmap TCP 스캔 6종 비교

### 7.1 실습 결과

| 옵션 | 스캔 유형 | TCP 22 | TCP 24 | 특징 |
|---|---|---|---|---|
| `-sT` | TCP Connect | `open` | `closed` | 3-Way Handshake 완성 |
| `-sS` | TCP SYN | `open` | `closed` | SYN/ACK로 열린 포트 판별 |
| `-sF` | FIN | `open\|filtered` | `closed` | FIN만 설정 |
| `-sN` | NULL | `open\|filtered` | 미실행 | TCP 플래그 없음 |
| `-sX` | Xmas | `open\|filtered` | 미실행 | FIN·PSH·URG |
| `-sW` | Window | `closed` | `closed` | RST의 Window 필드 특성 이용 |

### 7.2 TCP Connect 패킷 캡처

```text
38924 → 22 [SYN]
22 → 38924 [SYN, ACK]
38924 → 22 [ACK]
38924 → 22 [RST, ACK]
```

- 3-Way Handshake가 완성되므로 `-sT`의 연결 확인을 이해하는 데 좋은 자료.
- 포트 24는 SYN에 대해 RST/ACK가 관찰되어 닫힌 포트로 판정.

### 7.3 왜 FIN/NULL/Xmas는 `open|filtered`인가?

- 특정 TCP 구현에서는 닫힌 포트가 RST를 보내고 열린 포트는 비정상 플래그 패킷에 응답하지 않을 수 있다.
- 무응답만으로 열린 포트와 방화벽 차단을 구분할 수 없어 `open|filtered`로 표기.
- 실제 결과는 운영체제·방화벽·네트워크 환경에 따라 달라진다.

### 7.4 왜 Window Scan에서 SSH가 `closed`였나?

- `-sW`는 RST 패킷의 Window 값 차이를 이용해 상태를 추론하는 방식.
- 일부 OS는 열린/닫힌 포트에 구별 가능한 Window 값을 주지 않아 잘못 분류할 수 있음.
- 이 실습에서는 `-sT`, `-sS`가 SSH 22를 `open`으로 확인했으므로 **`-sW closed`만으로 SSH가 닫혔다고 단정하지 않는다.**

## 8. Nmap UDP 스캔 및 ARP Ping Scan

### 8.1 UDP 스캔

```bash
nmap -sU -p 53 192.168.20.200
nmap -sU -p 54 192.168.20.200
```

| 포트 | 결과 | Wireshark 증거 |
|---|---|---|
| UDP 53 | `open` | DNS Server status request에 대한 `Not implemented` 응답 |
| UDP 54 | `closed` | ICMP Destination Unreachable (Port unreachable) |

- UDP 53의 DNS `Not implemented`는 요청한 DNS 기능을 지원하지 않는다는 뜻. **서비스가 응답했으므로 포트는 open으로 판별 가능.**
- UDP 54의 ICMP 오류는 **Type 3 / Code 3 (Port Unreachable)**.
- UDP 스캔에서 응답이 없으면 `open|filtered`일 수 있음. 무응답을 곧바로 `open`으로 해석하지 않는다.

### 8.2 Ping Scan (`-sP`, `-sn`)

```bash
nmap -sP 192.168.20.200
nmap -sP 192.168.20.206
# 현재 권장 표기: -sn
```

| 대상 | 결과 | 관찰 |
|---|---|---|
| `.200` | Host is up | MAC `00:0C:29:14:3B:A5`, ARP 응답 관찰 |
| `.206` | Host seems down | `.50`에서 `Who has 192.168.20.206?` ARP 요청 관찰 |

- `-sP`는 구형 표기, `-sn`이 현재 사용되는 호스트 탐색 옵션.
- 같은 LAN의 권한 있는 스캔에서는 ICMP Echo 대신 **ARP 탐색**을 사용할 수 있음.
- `Host seems down`은 응답을 확인하지 못했다는 뜻이며 전원이 꺼졌다는 확정 판정은 아님.

## 9. Zenmap 종합 스캔

### 9.1 실제 실행 명령

```bash
nmap -T4 -A -v 192.168.20.200
```

| 옵션 | 기능 |
|---|---|
| `-T4` | 빠른 타이밍 템플릿(aggressive timing) |
| `-A` | OS 탐지, 버전 탐지, 기본 NSE, traceroute 활성화 |
| `-v` | 상세 진행 로그 출력 |
| 대상 IP | CentOS `192.168.20.200` |

**중요:** `-A`는 SYN Scan 자체를 뜻하지 않는다. 이번 로그의 `SYN Stealth Scan`은 실행 권한 및 기본 스캔 선택과 관련 있다.

### 9.2 실제 실행 순서

```text
NSE 사전 처리
→ ARP Ping Scan
→ SYN Stealth Scan (상위 1000개 TCP 포트)
→ Service scan (열린 13개 서비스)
→ OS detection
→ NSE script scanning
→ Traceroute
→ NSE 사후 처리
```

- **총 1,000개 포트 검사: 13 open / 987 closed**
- **23.54초** 소요
- OS 추정: **Linux 2.6.18–2.6.32**
- 네트워크 거리: **1 hop**
- `Loaded 153 scripts`: 스크립트 로드 수이며, 153개 모두가 취약점을 발견했다는 뜻은 아님.

### 9.3 열린 TCP 서비스 13개

| 포트 | 서비스 | 탐지 정보 |
|---:|---|---|
| 21 | FTP | vsftpd 2.0.5 |
| 22 | SSH | OpenSSH 4.3 |
| 23 | Telnet | BSD-derived telnetd |
| 25 | SMTP | Sendmail 8.13.8 |
| 53 | DNS | ISC BIND 9.3.6-P1 |
| 80 | HTTP | Apache 2.2.3 |
| 110 | POP3 | Dovecot |
| 111 | RPC | rpcbind 2 |
| 143 | IMAP | Dovecot |
| 443 | HTTPS | Apache 2.2.3 |
| 993 | IMAPS | Dovecot |
| 995 | POP3S | Dovecot |
| 3306 | MySQL | `unauthorized` |

### 9.4 종합 스캔에서 식별한 점검 항목

1. `ftp-anon`: 익명 FTP 로그인 허용, `pub` 디렉터리 노출. 읽기/쓰기 권한 및 운영 의도 확인 필요.
2. Telnet 23 활성화: 암호화되지 않는 통신에 대한 노출 위험.
3. Apache `TRACE` 메서드 허용: 불필요하면 차단 검토. 허용만으로 악용 성공을 뜻하지 않음.
4. SSL 인증서 유효기간 **2015~2016년**으로 표시: 만료 및 RSA 1024비트·SHA-1 서명 등 구형 설정 점검.
5. MySQL 3306 접근 가능: `unauthorized`는 인증 없이 접근에 성공했다는 의미가 아님.
6. 서비스 버전과 OS는 오래된 것으로 추정되나, 실제 패치 적용 여부·백포트 여부는 별도 확인 필요.

## 10. NSE 취약점 진단

> 이 장은 제공된 `붙여넣은 텍스트(1)(20261028-073331).txt`의 실제 터미널 로그를 기반으로 정리.

### 10.1 MS17-010 (SMBv1)

```bash
nmap -p 445 192.168.20.201 --script=smb-vuln-ms17-010.nse
nmap -p 445 192.168.20.0/24 --script=smb-vuln-ms17-010.nse
```

| 호스트 | TCP 445 | 스크립트 결과 |
|---|---|---|
| `.201` | open | **VULNERABLE** (CVE-2017-0143) |
| `.202` | open | **VULNERABLE** (CVE-2017-0143) |
| `.200` | closed | MS17-010 탐지 결과 없음 |
| `.100` | closed | MS17-010 탐지 결과 없음 |
| `.1` | open | 해당 스크립트의 취약 판정 출력 없음 |
| `.50` | open | 해당 스크립트의 취약 판정 출력 없음 |

- 관련 주제: SMBv1 원격 코드 실행 취약점, MS17-010, WannaCry 연관 역사.
- **스크립트의 VULNERABLE 판정은 보안 점검상 중요하지만 실제 RCE 성공을 입증하지는 않음.**
- 대응: 보안 업데이트, SMBv1 비활성화, TCP 445 접근 통제, 자산 관리.

### 10.2 MySQL 인증 점검

```text
nmap -p 3306 192.168.20.0/24 --script=mysql-brute.nse
nmap -p 3306 192.168.20.204 --script=mysql-empty-password.nse
```

**첫 번째 범위 검사:**

- `.200`: 3306 open, 354 guesses / 10초, 유효 계정 미발견, 서비스 실패 또는 방화벽 관련 오류 메시지.
- `.1`: 3306 open, 0 guesses, 유효 계정 미발견, 오류 메시지.

**두 번째 범위 검사:**

- `.1`: 50,009 guesses / 27초, 유효 계정 미발견.
- `.200`: 4,177 guesses / 23초, 유효 계정 미발견 및 오류 메시지.
- `.204`: 3306 open, **`root:<empty>` / `guest:<empty>` Valid credentials**.

**추가 확인:**

```text
mysql-empty-password:
  root account has empty password

mysql -h 192.168.20.204 -u root -p
Enter password:
Welcome to the MariaDB monitor.
Server version: 5.0.51a-3ubuntu5 (Ubuntu)
```

**판정:** `.204`에서는 빈 비밀번호 root 인증이 실제 클라이언트 접속으로 확인되었다. `.200`과 `.1`의 `No valid accounts found`는 안전성 입증이 아니다. 인증 시도 횟수가 많아 서비스 부하 및 계정 잠금 가능성에 주의해야 한다.

**대응:** 빈 비밀번호 제거, 원격 root 접근 제한, 최소 권한, 접근 IP 제한, 감사 로그 확인, 계정 정책 강화.

### 10.3 SSL POODLE

```bash
nmap -p 443 192.168.20.0/24 --script=ssl-poodle.nse
```

| 호스트 | HTTPS 443 | 결과 | 검사 출력의 암호군 |
|---|---|---|---|
| `.200` | open | **VULNERABLE** | `TLS_RSA_WITH_AES_128_CBC_SHA` |
| `.201` | open | **VULNERABLE** | `TLS_RSA_WITH_3DES_EDE_CBC_SHA` |
| `.202` | closed | 해당 없음 | — |
| `.204` | closed | 해당 없음 | — |
| `.1` | open | 취약 판정 출력 없음 | — |

- 스크립트는 **CVE-2014-3566** 관련 취약 판정을 출력.
- POODLE은 SSL 3.0 CBC 패딩 처리와 관련된 정보 노출 위험.
- **스크립트 결과는 취약 구성의 탐지이지 실제 평문 복호화 성공의 증거가 아니다.**
- 대응: SSL 3.0 비활성화, 지원되는 안전한 TLS 버전/암호군 적용, 구성 재검증.

### 10.4 HTTP WAF 탐지

```bash
nmap -p 80,443 www.imperva.com --script=http-waf-detect.nse
nmap -p 80,443 www.imperva.com --script=http-waf-fingerprint.nse
```

- 첫 실행: 대상 주소 해석 및 TCP 80/443 `open` 확인. **별도 WAF 탐지 결과는 출력되지 않음.**
- 두 번째 실행: `Failed to resolve "www.imperva.com"`으로 실제 대상 스캔 실패.
- **WAF 미탐지 ≠ WAF 부재.** DNS 해석 실패 ≠ 서비스 장애 확정.
- 공개 도메인에 대한 보안 테스트는 사전 허가 및 범위 확인이 필요하다.

## 11. 판정 오류를 피하는 10가지 원칙

1. `--flood`의 `100% packet loss`를 실제 네트워크 손실률로 단정하지 않는다.
2. `SYN_RECV` 다수를 확인해도 실제 서비스 거부 여부는 별도 측정한다.
3. `DNS [Malformed Packet]`을 DNS 취약점 악용 성공으로 오해하지 않는다.
4. ARP Spoofing 패킷 송신과 실제 MITM 통신 중계 성공을 구분한다.
5. `Follow TCP Stream`에서 Telnet 입력값 노출은 평문 통신 위험을 직접 보여준다.
6. ICMP LAND 50개 전송에서 부하가 없었던 관찰은 충분히 가능한 결과다.
7. FIN/NULL/Xmas의 `open|filtered`는 `open` 확정이 아니다.
8. Window Scan의 `closed`는 다른 스캔과 교차 검증한다.
9. UDP의 DNS 오류 응답도 포트가 `open`임을 보여줄 수 있다.
10. NSE `VULNERABLE`은 중요한 경고이지만 실제 침해 성공을 자동으로 의미하지 않는다.

## 12. 실무 대응 및 점검 체크리스트

### 탐지 및 모니터링

- [ ] Wireshark에서 `tcp.flags.syn == 1 && tcp.flags.ack == 0` 등으로 SYN 패킷 경향 확인
- [ ] `netstat`/`ss`에서 `SYN_RECV` 변화 추적
- [ ] CPU·메모리·PPS/BPS·응답시간·오류율을 **동일 시간대**에 비교
- [ ] ICMP Type 3 Code 3과 UDP 포트 상태 연관성 확인
- [ ] ARP 테이블 변경과 비정상 MAC 매핑 감시
- [ ] Telnet·FTP 등 평문 서비스 사용 여부 확인

### 예방 및 조치

- [ ] 불필요한 Telnet·FTP 서비스 제거 또는 암호화 대안 사용
- [ ] MS17-010 보안 패치 및 SMBv1 사용 현황 점검
- [ ] MySQL 빈 비밀번호·원격 root 로그인 제거
- [ ] SSL 3.0 및 취약 암호군 비활성화
- [ ] 만료 인증서 교체 및 TLS 재점검
- [ ] Apache TRACE 필요성 검토
- [ ] 방화벽/ACL로 SMB·DB 등 관리 서비스 노출 최소화
- [ ] 스캔 승인 범위·실행 시간·결과·영향을 기록

## 13. 면접·시험 Q&A

**Q1. SYN Flood의 핵심 원리는?**  
A. TCP 연결 수립의 SYN 이후 최종 ACK가 완료되지 않는 상태를 다량 유발하여 연결 대기 자원을 압박하는 것이다.

**Q2. `SYN_RECV`가 많으면 DoS 성공인가?**  
A. 아니다. 연결 대기 상태의 증가를 보여주지만 서비스 가용성은 응답시간, 실패율 등으로 확인해야 한다.

**Q3. ARP Spoofing과 IP Spoofing의 차이는?**  
A. ARP Spoofing은 LAN의 IP↔MAC 매핑을 속이고, IP Spoofing은 IP 헤더의 출발지 주소를 위조한다.

**Q4. Telnet 입력값이 Wireshark에서 보이는 이유는?**  
A. Telnet은 기본적으로 애플리케이션 데이터를 암호화하지 않기 때문이다.

**Q5. `-sT`와 `-sS`의 차이는?**  
A. `-sT`는 TCP 연결을 완료하고, `-sS`는 SYN/ACK로 상태를 판단한 뒤 일반적으로 연결을 완성하지 않는다.

**Q6. FIN/NULL/Xmas가 `open|filtered`를 반환하는 이유는?**  
A. 무응답만으로 열린 포트와 필터링된 포트를 구분할 수 없기 때문이다.

**Q7. UDP 54번을 `closed`로 판단한 증거는?**  
A. ICMP Destination Unreachable, Type 3 Code 3(Port Unreachable) 응답이다.

**Q8. 같은 LAN의 Ping Scan에서 ARP가 등장하는 이유는?**  
A. Nmap이 로컬 호스트 탐색에 ARP 요청/응답을 사용할 수 있기 때문이다.

**Q9. `nmap -T4 -A -v`의 의미는?**  
A. 빠른 타이밍으로 OS·서비스 버전·기본 NSE·경로 추적을 수행하며 진행 과정을 상세히 출력한다.

**Q10. MS17-010과 WannaCry의 관계는?**  
A. SMBv1의 취약점 악용이 WannaCry 확산과 연관되며, 보안 패치와 SMBv1 비활성화가 중요하다.

**Q11. `root:<empty>`와 `No valid accounts found`는 어떻게 다른가?**  
A. 전자는 빈 비밀번호 인증 성공 증거이고, 후자는 스크립트가 유효한 계정을 찾지 못했다는 제한된 결과다.

**Q12. POODLE 탐지 결과가 의미하는 것은?**  
A. 구형 SSL/TLS 구성에서 관련 취약점이 의심·탐지되었다는 뜻이며, 실제 정보 유출 성공과는 구분해야 한다.

**Q13. `MySQL (unauthorized)`는 무슨 뜻인가?**  
A. 포트와 서비스는 확인했지만 인증되지 않은 상태라는 의미다. 인증 우회 성공이 아니다.

**Q14. Nmap NSE는 무엇인가?**  
A. Nmap Scripting Engine으로, 서비스 정보 수집 및 특정 보안 설정·취약점 점검 등을 자동화하는 스크립트 기능이다.

**Q15. WAF 스크립트에서 결과가 없으면 WAF가 없다는 뜻인가?**  
A. 아니다. 탐지 방식의 한계, 응답 조건, 네트워크 문제 등이 있을 수 있다.

## 14. 복습 치트시트 및 증빙 캡처

### 핵심 필터

```text
arp
icmp
telnet
ip.addr == 192.168.20.200 && tcp
ip.addr == 192.168.20.200 && udp
tcp.port == 22
tcp.port == 80
udp.port == 53
icmp.type == 3 && icmp.code == 3
```

### Nmap 명령어 요약

```bash
# 서비스 탐색
nmap -sS -sV 192.168.20.200

# TCP 스캔 방식 비교
nmap -sT -p 22 192.168.20.200
nmap -sS -p 22 192.168.20.200
nmap -sF -p 22 192.168.20.200
nmap -sN -p 22 192.168.20.200
nmap -sX -p 22 192.168.20.200
nmap -sW -p 22 192.168.20.200

# UDP 및 호스트 탐색
nmap -sU -p 53 192.168.20.200
nmap -sU -p 54 192.168.20.200
nmap -sn 192.168.20.200

# Zenmap 종합 스캔에서 실행한 명령
nmap -T4 -A -v 192.168.20.200
```

### PPT/포트폴리오 스크린샷 추천 순서

| 순서 | 자료 | 강조할 포인트 |
|---:|---|---|
| 1 | CentOS `netstat -ntp` | `SYN_RECV` 다수 발생 |
| 2 | UDP Flood Wireshark | UDP 53 대량 트래픽 및 `Malformed`의 정확한 해석 |
| 3 | ARP Spoofing + Telnet Follow TCP Stream | 평문 입력값 노출 |
| 4 | ICMP Flood 캡처 | 출발지 IP가 여러 주소로 보이는 이유 |
| 5 | ICMP LAND 캡처 | 출발지·목적지 IP 동일, 부하 관찰 |
| 6 | TCP Connect Wireshark | SYN → SYN/ACK → ACK → RST |
| 7 | UDP 53/54 Wireshark | DNS 응답 vs ICMP Port Unreachable |
| 8 | ARP Ping Scan 캡처 | `.200` 응답 vs `.206` 무응답 |
| 9 | Zenmap 결과 | 열린 13개 TCP 서비스, OS·버전 정보 |
| 10 | NSE 로그 | MS17-010, 빈 비밀번호 MySQL, POODLE 탐지 |

---

## 최종 한 페이지 요약

> **공격/이상 트래픽 분석:** SYN/UDP/ICMP Flood와 ARP Spoofing의 패킷 특징을 Wireshark·netstat로 관찰했다.  
> **스캔 이해:** TCP Connect/SYN/FIN/NULL/Xmas/Window와 UDP·ARP Ping Scan의 판정 차이를 비교했다.  
> **서비스 탐지:** Zenmap의 `-T4 -A -v`로 CentOS 서버의 13개 열린 TCP 서비스, 버전, OS 추정 정보를 확인했다.  
> **취약점 점검:** NSE에서 MS17-010(.201/.202), MySQL 빈 비밀번호(.204), POODLE(.200/.201)을 탐지했다.  
> **가장 중요한 교훈:** **패킷 전송 성공 ≠ 서비스 장애 성공, 스캐너 취약 판정 ≠ 실제 침해 성공.** 근거 수준을 구분하는 것이 보안 분석의 핵심이다.

*2026-10-28 실습 기록을 바탕으로 작성 · 복습 및 면접 대비용*
