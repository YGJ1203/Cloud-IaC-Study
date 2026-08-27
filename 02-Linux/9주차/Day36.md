# 2026-08-27 Linux Network Service & iptables Study

> 실습 환경: CentOS Stream 9 / Server1 / Client1 / Client2  
> 핵심 주제: DHCP, 네트워크 서비스, iptables, Stateful Firewall, 서비스 포트 허용/차단, 통신 검증

---

## 1. 오늘 실습의 전체 흐름

오늘 실습은 단순히 `iptables` 명령어만 학습한 것이 아니라, 네트워크 서비스를 실제로 구동한 뒤 방화벽 정책을 적용하고 Client에서 통신 가능 여부를 확인하는 흐름으로 진행되었다.

```text
DHCP 및 서비스 패키지 설치
        ↓
DHCP Server(dhcpd) 구성
        ↓
DNS / NTP / FTP / SSH / Telnet / HTTP 등 서비스 준비
        ↓
iptables 규칙 확인 및 기본 정책 변경
        ↓
필요한 프로토콜 / 포트만 ACCEPT
        ↓
Stateful 규칙 적용
        ↓
ping / nslookup / telnet / nmap 등으로 검증
```

핵심은 다음 한 문장으로 정리할 수 있다.

> **기본적으로 통신을 차단하고, 서버 운영에 필요한 서비스만 명시적으로 허용한 뒤 실제 통신 결과를 확인한다.**

---

# 2. 실습 시스템 구성

실습에서 확인한 주요 시스템 주소는 다음과 같다.

```text
Client1 : 192.168.2.201
Client2 : 192.168.2.202
Server1 : 192.168.2.203/24
```

전체 구조를 단순화하면 다음과 같다.

```text
 Client1 (.201)             Client2 (.202)
       │                         │
       │      서비스 테스트      │
       └──────────┬──────────────┘
                  │
                  ▼
            Server1 (.203)
                  │
          ┌───────┴────────┐
          │                │
        DHCP             iptables
        dhcpd            Firewall
          │                │
          └───────┬────────┘
                  │
        DNS / NTP / FTP / SSH
        Telnet / HTTP / Samba
        NFS / MariaDB / Tomcat
```

---

# 3. DHCP 핵심 개념

## 3.1 DHCP란?

DHCP(Dynamic Host Configuration Protocol)는 Client에게 네트워크 설정을 자동으로 제공하는 프로토콜이다.

일반적으로 Client가 DHCP를 통해 얻을 수 있는 정보에는 다음과 같은 항목이 있다.

- IP 주소
- Subnet Mask
- Default Gateway
- DNS Server
- Lease Time

이번 실습 로그에서는 DHCP Server 패키지 및 설정 파일 위치, 서비스 실행 과정까지 직접 확인하였다.

---

## 3.2 DHCP 관련 패키지

실습에서 다음과 같은 DHCP 관련 패키지를 설치하였다.

```bash
yum -y install dhcp*
```

주요 패키지 예시는 다음과 같다.

```text
dhcp-client
dhcp-common
dhcp-relay
dhcp-server
```

특히 DHCP Server를 구성할 때 핵심이 되는 패키지는 `dhcp-server`이다.

---

## 3.3 DHCP Server 주요 파일

`rpm -ql dhcp-server` 명령을 이용해 DHCP Server 패키지에 포함된 주요 파일을 확인하였다.

```text
/etc/dhcp/dhcpd.conf
/etc/dhcp/dhcpd6.conf
/usr/lib/systemd/system/dhcpd.service
/var/lib/dhcpd/dhcpd.leases
```

### 주요 파일 역할

| 파일 | 역할 |
|---|---|
| `/etc/dhcp/dhcpd.conf` | DHCPv4 Server 환경 설정 |
| `/etc/dhcp/dhcpd6.conf` | DHCPv6 Server 환경 설정 |
| `/var/lib/dhcpd/dhcpd.leases` | Client에게 임대한 주소 정보 저장 |
| `dhcpd.service` | systemd 기반 DHCP Server 서비스 |

---

# 4. DHCP 서비스 실행과 트러블슈팅

## 4.1 잘못된 서비스 이름

처음 다음 명령을 실행하였다.

```bash
systemctl enable --now dhcp
```

하지만 `dhcp.service`라는 Unit은 존재하지 않아 실패하였다.

올바른 DHCPv4 Server 서비스 이름은 다음과 같다.

```bash
systemctl enable --now dhcpd
```

즉 다음과 같이 기억하면 된다.

```text
패키지 이름 : dhcp-server
서비스 이름 : dhcpd
설정 파일   : /etc/dhcp/dhcpd.conf
```

---

## 4.2 dhcpd.conf 설정 부족으로 서비스 실패

초기 `/etc/dhcp/dhcpd.conf`는 기본 주석만 존재하는 상태였다.

```bash
cat /etc/dhcp/dhcpd.conf
```

이 상태에서 `dhcpd`를 시작했을 때 서비스가 실패하였다.

상태 확인:

```bash
systemctl status dhcpd
```

실습에서는 예제 설정 파일을 복사한 뒤 수정하여 서비스를 정상적으로 실행하였다.

```bash
cd /etc/dhcp
cp /usr/share/doc/dhcp-server/dhcpd.conf.example dhcpd.conf
vi dhcpd.conf
systemctl enable --now dhcpd
systemctl status dhcpd
```

정상 실행 시 다음과 같은 상태를 확인할 수 있다.

```text
Active: active (running)
Status: "Dispatching packets..."
```

### 핵심 트러블슈팅 순서

```text
서비스 실행 실패
      ↓
systemctl status dhcpd
      ↓
설정 파일 확인
      ↓
/etc/dhcp/dhcpd.conf 수정
      ↓
서비스 재시작
      ↓
상태 재확인
```

---

# 5. DHCP 포트 번호

실습에서 `/etc/services`를 통해 DHCP/BOOTP 포트를 확인하였다.

```bash
cat /etc/services | grep bootp
```

확인되는 핵심 포트는 다음과 같다.

```text
bootps  67/udp   # DHCP/BOOTP Server
bootpc  68/udp   # DHCP/BOOTP Client
```

따라서 DHCP 기본 통신 구조는 다음과 같다.

```text
Client                          DHCP Server
UDP 68                            UDP 67
  │                                 │
  │ DHCP 요청                       │
  ├────────────────────────────────►│
  │                                 │
  │          DHCP 응답              │
  │◄────────────────────────────────┤
```

---

# 6. DHCP DORA 과정

DHCP Client가 주소를 얻는 대표적인 과정은 DORA이다.

```text
Client                         DHCP Server

DHCPDISCOVER
"DHCP 서버 있나요?"
    ─────────────────────────►

                    DHCPOFFER
                 "이 주소를 사용하세요"
    ◄─────────────────────────

DHCPREQUEST
"그 주소를 사용하겠습니다"
    ─────────────────────────►

                    DHCPACK
                 "사용해도 됩니다"
    ◄─────────────────────────
```

정리:

```text
D = Discover
O = Offer
R = Request
A = ACK
```

DHCP는 Client가 아직 정상적인 IP 설정을 갖기 전부터 통신해야 하므로 UDP와 Broadcast가 중요하게 사용된다.

---

# 7. iptables란?

`iptables`는 Linux에서 네트워크 패킷을 조건에 따라 허용하거나 차단하기 위한 방화벽 관리 명령어이다.

기본적인 동작 흐름은 다음과 같다.

```text
네트워크 패킷
      ↓
iptables Rule 검사
      ↓
조건 일치 여부
   ┌──┴──┐
  YES    NO
   │      │
 Target  다음 Rule
   │
ACCEPT / DROP / REJECT
```

---

# 8. INPUT / OUTPUT / FORWARD Chain

iptables의 대표적인 기본 Chain은 세 가지이다.

## INPUT

서버 자신을 목적지로 하는 패킷.

```text
Client ─────► Server1
               ↑
             INPUT
```

예:

- Client → Server SSH
- Client → Server HTTP
- Client → Server Telnet
- Client → Server ping 요청

---

## OUTPUT

서버가 직접 생성하여 외부로 보내는 패킷.

```text
Server1 ─────► Internet
   ↓
 OUTPUT
```

예:

- Server → DNS 질의
- Server → 외부 ping
- Server → 웹사이트 접속

---

## FORWARD

서버가 최종 목적지가 아니라 다른 네트워크로 전달하는 패킷.

```text
Client ─────► Linux Router ─────► Other Network
                   ↓
                FORWARD
```

### 초간단 암기

```text
INPUT   = 나에게 들어옴
OUTPUT  = 내가 내보냄
FORWARD = 나를 거쳐감
```

---

# 9. iptables 규칙 기본 구조

대표적인 예제:

```bash
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
```

해석:

```text
iptables        방화벽 제어
-A INPUT        INPUT Chain 끝에 Rule 추가
-p tcp          TCP Protocol
--dport 22      목적지 Port 22
-j ACCEPT       허용
```

한글로 해석하면 다음과 같다.

> **Server1의 TCP 22번 SSH 포트로 들어오는 패킷을 허용한다.**

---

# 10. 주요 iptables 옵션

| 옵션 | 의미 |
|---|---|
| `-A` | Append, Rule 추가 |
| `-I` | Insert, 특정 위치에 Rule 삽입 |
| `-D` | Delete, Rule 삭제 |
| `-L` | List, Rule 목록 확인 |
| `-P` | 기본 Policy 지정 |
| `-N` | 사용자 정의 Chain 생성 |
| `-X` | 사용자 정의 Chain 삭제 |
| `-p` | Protocol 지정 |
| `-s` | Source IP 지정 |
| `-d` | Destination IP 지정 |
| `--sport` | Source Port 지정 |
| `--dport` | Destination Port 지정 |
| `-i` | 입력 Interface 지정 |
| `-j` | 최종 처리 Target 지정 |

---

# 11. ACCEPT / DROP / REJECT

## ACCEPT

패킷 허용.

```bash
-j ACCEPT
```

## DROP

패킷을 조용히 버린다.

```bash
-j DROP
```

상대방에게 명시적인 거절 응답을 보내지 않는다.

## REJECT

패킷을 거부하면서 상대방에게 거절 사실을 알려준다.

```bash
-j REJECT
```

---

# 12. 기본 정책 변경

실습에서 중요한 명령:

```bash
iptables -P INPUT DROP
```

의미:

> INPUT Chain의 어떠한 Rule에도 일치하지 않는 패킷은 기본적으로 DROP한다.

적용 전:

```text
INPUT Policy ACCEPT
→ 별도 Rule이 없어도 통신 가능
```

적용 후:

```text
INPUT Policy DROP
→ ACCEPT Rule에 명시된 통신만 가능
```

방화벽 정책의 대표적인 사고방식은 다음과 같다.

> **기본 차단 후 필요한 서비스만 허용한다.**

---

# 13. Loopback 허용

INPUT Policy를 DROP으로 설정한 뒤 Server1에서 다음 통신이 실패하였다.

```bash
ping -c 3 127.0.0.1
telnet 127.0.0.1
```

원인은 Loopback(`lo`) Interface로 들어오는 통신 역시 INPUT Chain을 통과하기 때문이다.

따라서 다음 Rule을 추가하였다.

```bash
iptables -A INPUT -i lo -j ACCEPT
```

해석:

```text
INPUT으로 들어온 패킷 중
입력 Interface가 lo이면
모두 ACCEPT
```

이후 `127.0.0.1` ping과 Telnet 접속이 정상적으로 동작하였다.

### 핵심

```text
INPUT 기본 정책 DROP
        ↓
Loopback까지 차단될 수 있음
        ↓
-i lo -j ACCEPT 추가
```

---

# 14. DNS와 Source/Destination Port

실습에서 DNS 통신을 위해 다음 Rule을 추가하였다.

```bash
iptables -A INPUT -p udp --dport 53 -j ACCEPT
iptables -A INPUT -p tcp --dport 53 -j ACCEPT
```

하지만 외부 DNS Server를 이용한 질의에서 응답 수신 문제가 발생하였다.

```bash
nslookup www.google.com
```

이후 다음 Rule을 추가하였다.

```bash
iptables -A INPUT -p udp --sport 53 -j ACCEPT
```

이 과정을 이해하려면 Source Port와 Destination Port를 구분해야 한다.

```text
Server1                         DNS Server
   │                              │
   │ Query                        │
   │ Destination Port = 53        │
   ├─────────────────────────────►│
   │                              │
   │ Reply                        │
   │ Source Port = 53             │
   │◄─────────────────────────────┤
```

### 암기

```text
--sport = Source Port      = 출발지 Port
--dport = Destination Port = 목적지 Port
```

---

# 15. HTTP / HTTPS 허용

웹 서비스를 허용하기 위해 다음 Rule을 사용하였다.

```bash
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
```

```text
80/TCP  = HTTP
443/TCP = HTTPS
```

패킷 흐름:

```text
Client1
   │
   │ TCP Destination Port 80
   ▼
iptables INPUT
   │
   │ Rule Match
   ▼
ACCEPT
   │
   ▼
Apache HTTP Server
```

---

# 16. ICMP Ping과 Echo Request / Echo Reply

`ping`은 ICMP를 이용한다.

기본 흐름:

```text
Server1
   │
   │ ICMP Echo Request
   ├────────────────────► Remote Host
   │
   │ ICMP Echo Reply
   │◄────────────────────┤
```

실습에서는 외부로 ping을 보낸 뒤 응답을 받지 못한 상태에서 다음 Rule을 추가하였다.

```bash
iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT
```

이후 ping 응답이 정상적으로 수신되었다.

### 핵심

> ping 성공 여부는 요청 패킷을 보내는 것뿐만 아니라 응답 패킷이 INPUT Chain을 통과할 수 있는지도 중요하다.

---

# 17. Stateful Firewall

오늘 실습의 핵심 개념 중 하나이다.

```bash
iptables -A INPUT -m state --state ESTABLISHED,RELATED -p all -j ACCEPT
```

## ESTABLISHED

이미 정상적으로 연결이 형성되어 통신 중인 Connection의 패킷.

## RELATED

기존 Connection과 관련되어 새롭게 만들어진 통신.

개념적으로 다음처럼 생각할 수 있다.

```text
Server1이 먼저 통신 시작
        ↓
외부에서 응답 패킷 도착
        ↓
기존 Connection과 관련된 패킷인가?
        ↓
ESTABLISHED / RELATED
        ↓
ACCEPT
```

이렇게 연결 상태까지 기억하고 판단하는 방식을 Stateful Firewall이라고 한다.

---

# 18. Stateless vs Stateful

## Stateless

각 패킷의 IP, Protocol, Port 등만 독립적으로 검사한다.

```text
Source IP
Destination IP
Protocol
Port
```

## Stateful

현재 Connection의 상태까지 추적한다.

```text
NEW
ESTABLISHED
RELATED
INVALID
```

대표적인 의미:

| 상태 | 의미 |
|---|---|
| `NEW` | 새로운 연결 |
| `ESTABLISHED` | 이미 성립된 연결 |
| `RELATED` | 기존 연결과 관련된 연결 |
| `INVALID` | 정상적인 연결 상태로 판단하기 어려운 패킷 |

---

# 19. multiport 사용

여러 서비스 Port를 하나씩 등록하면 Rule 수가 많아진다.

예:

```bash
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 23 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
```

이를 `multiport`로 묶을 수 있다.

실습 예시:

```bash
iptables -A INPUT -m multiport -p tcp \
--dports 23,22,21,20,2049,111,139,445,80,443,3306,8080,53 \
-j ACCEPT
```

UDP 서비스도 다음과 같이 묶었다.

```bash
iptables -A INPUT -m multiport -p udp \
--dports 53,67,123,137,138 \
-j ACCEPT
```

### 장점

```text
Rule 수 감소
가독성 증가
서비스 Port 관리 편리
```

---

# 20. DHCP와 iptables 연결

DHCP Server는 UDP 67번 Port를 사용한다.

따라서 다음 Rule에 DHCP Server 허용이 포함되어 있다.

```bash
iptables -A INPUT -m multiport -p udp \
--dports 53,67,123,137,138 \
-j ACCEPT
```

포트 의미:

| Port | Service |
|---:|---|
| 53 | DNS |
| 67 | DHCP Server |
| 123 | NTP |
| 137 | NetBIOS Name Service |
| 138 | NetBIOS Datagram |

즉 위 Rule은 Server1이 운영하는 여러 UDP 기반 서비스에 대한 요청을 한 번에 허용하는 것이다.

---

# 21. 주요 TCP 서비스 포트

실습 후반부에서 Server1은 여러 서비스를 활성화하였다.

```bash
systemctl enable --now telnet.socket vsftpd nfs-server smb nmb mariadb httpd named
```

Client1의 `nmap -sS -sV 192.168.2.203` 결과에서는 다음과 같은 서비스가 확인되었다.

| Port | Service | 설명 |
|---:|---|---|
| 20 | FTP-DATA | FTP Data |
| 21 | FTP | File Transfer |
| 22 | SSH | Secure Remote Login |
| 23 | Telnet | Remote Login |
| 53 | DNS | Domain Name Service |
| 80 | HTTP | Web |
| 111 | RPC | Remote Procedure Call |
| 139 | NetBIOS-SSN | Samba |
| 443 | HTTPS | Encrypted Web |
| 445 | Microsoft-DS | Samba |
| 2049 | NFS | Network File System |
| 3306 | MySQL/MariaDB | Database |
| 8080 | HTTP Alternate | Tomcat |

---

# 22. iptables Rule 조회

## 기본 조회

```bash
iptables -L
```

## 상세 조회

```bash
iptables -vL
```

`-v`를 사용하면 다음 정보 등을 추가로 볼 수 있다.

```text
pkts   해당 Rule과 일치한 Packet 수
bytes  해당 Rule과 일치한 Byte 수
```

## 숫자 기반 조회

```bash
iptables -nvL INPUT
```

`-n`은 Hostname이나 Service 이름으로 변환하지 않고 IP와 Port를 숫자로 표시한다.

## Rule 번호 표시

```bash
iptables -nvL INPUT --line-numbers
```

Rule 삭제 시 매우 유용하다.

---

# 23. Rule 추가 / 삽입 / 삭제

## Append

```bash
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
```

Chain의 마지막에 Rule 추가.

## Insert

```bash
iptables -I INPUT 2 -p tcp --dport 443
```

INPUT Chain의 2번 위치에 Rule 삽입.

## Delete

```bash
iptables -D INPUT 2
```

INPUT Chain의 2번 Rule 삭제.

### 중요

iptables는 Rule을 위에서 아래 순서대로 검사하므로 Rule의 순서 역시 중요하다.

---

# 24. 사용자 정의 Chain

실습에서는 다음 명령으로 `TEST` Chain을 생성하였다.

```bash
iptables -N TEST
```

삭제 명령:

```bash
iptables -X TEST
```

사용자 정의 Chain은 복잡한 Rule을 논리적으로 분리하여 관리할 때 사용할 수 있다.

---

# 25. iptables 서비스와 설정 파일

`iptables-services` 패키지에서 다음 파일을 확인하였다.

```text
/etc/sysconfig/iptables
/etc/sysconfig/iptables-config
/usr/lib/systemd/system/iptables.service
```

서비스 활성화:

```bash
systemctl enable --now iptables
```

상태 확인:

```bash
systemctl status iptables
```

---

# 26. Rule 저장

현재 적용된 Rule을 저장하기 위해 다음 명령을 사용하였다.

```bash
service iptables save
```

저장 위치:

```text
/etc/sysconfig/iptables
```

저장 후 다음 명령으로 확인할 수 있다.

```bash
cat /etc/sysconfig/iptables
```

예시 구조:

```text
*filter
:INPUT ACCEPT
:FORWARD ACCEPT
:OUTPUT ACCEPT

-A INPUT -p tcp -m tcp --dport 22 -j ACCEPT

COMMIT
```

---

# 27. Client에서 방화벽 검증

iptables 설정이 올바른지는 Server에서 Rule만 보는 것으로 끝나지 않는다.

Client에서 실제 통신을 시도해야 한다.

## ping

```bash
ping -c 3 192.168.2.203
```

ICMP 허용 여부 확인.

## Telnet

```bash
telnet 192.168.2.203
```

TCP 23번 서비스 접근 가능 여부 확인.

## nmap

```bash
nmap -sS -sV 192.168.2.203
```

### 주요 옵션

```text
-sS  TCP SYN Scan
-sV  Service Version Detection
```

이 명령을 통해 Server1에서 실제로 어떤 Port가 `open`, `closed`, `filtered` 상태인지 확인할 수 있다.

---

# 28. nmap 상태 해석

## open

해당 Port에서 서비스가 실행 중이며 접근 가능.

## closed

Host에는 접근 가능하지만 해당 Port에서 서비스가 Listening하지 않음.

## filtered

Firewall 등에 의해 Packet이 차단되어 Port 상태를 명확히 판단하기 어려움.

따라서 방화벽 실습에서는 `filtered`가 특히 중요한 의미를 가진다.

---

# 29. 오늘 실습의 서비스 흐름 정리

```text
DHCP
 ↓
Client가 네트워크 설정을 획득

DNS
 ↓
이름 ↔ IP 변환

NTP / chrony
 ↓
시스템 시간 동기화

FTP / SSH / Telnet / HTTP / NFS / Samba / DB
 ↓
각종 서버 서비스 운영

iptables
 ↓
서비스별 Protocol / Port 허용·차단

Client Test
 ↓
ping / nslookup / telnet / nmap
```

즉 각각 별도의 내용처럼 보였던 서비스들이 iptables를 기준으로 하나의 흐름으로 연결된다.

---

# 30. iptables 명령어 읽는 공식

긴 명령어가 등장하면 다음 순서로 해석한다.

```text
1. 어느 Chain인가?
   INPUT / OUTPUT / FORWARD

2. 어떤 Protocol인가?
   TCP / UDP / ICMP

3. Source / Destination은 어디인가?
   -s / -d

4. 어떤 Port인가?
   --sport / --dport

5. Connection 상태는 무엇인가?
   NEW / ESTABLISHED / RELATED

6. 최종 처리는 무엇인가?
   ACCEPT / DROP / REJECT
```

예:

```bash
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
```

해석:

> INPUT으로 들어오는 TCP 패킷 중 Destination Port가 22번이면 허용한다.

예:

```bash
iptables -A INPUT -m state --state ESTABLISHED,RELATED -p all -j ACCEPT
```

해석:

> 이미 성립된 연결 또는 기존 연결과 관련된 응답 패킷은 허용한다.

---

# 31. 오늘 실습에서 중요했던 트러블슈팅

## CASE 1. DHCP 서비스 이름 오류

### 문제

```bash
systemctl enable --now dhcp
```

### 원인

`dhcp.service` Unit이 존재하지 않음.

### 해결

```bash
systemctl enable --now dhcpd
```

---

## CASE 2. DHCP Server 시작 실패

### 현상

```text
Active: failed
```

### 확인

```bash
systemctl status dhcpd
```

### 원인

`dhcpd.conf`가 Server 구성을 위한 충분한 설정을 갖추지 못한 상태.

### 해결 흐름

```bash
cp /usr/share/doc/dhcp-server/dhcpd.conf.example /etc/dhcp/dhcpd.conf
vi /etc/dhcp/dhcpd.conf
systemctl enable --now dhcpd
systemctl status dhcpd
```

---

## CASE 3. INPUT DROP 후 localhost 통신 불가

### 현상

```bash
ping 127.0.0.1
```

실패.

### 원인

Loopback Traffic도 INPUT Chain에서 DROP됨.

### 해결

```bash
iptables -A INPUT -i lo -j ACCEPT
```

---

## CASE 4. DNS 질의 응답 문제

### 현상

```bash
nslookup www.google.com
```

Timeout.

### 원인 이해

요청의 Destination Port와 응답의 Source Port는 방향에 따라 달라진다.

### 실습 Rule

```bash
iptables -A INPUT -p udp --sport 53 -j ACCEPT
```

Stateful Rule을 사용하면 이러한 응답 패킷 관리가 훨씬 편해진다.

---

## CASE 5. Ping 응답 불가

### 원인

외부 Host에서 돌아오는 ICMP Echo Reply가 INPUT에서 허용되지 않음.

### 해결

```bash
iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT
```

---

# 32. 실무적인 방화벽 사고방식

초보 단계에서는 다음 순서로 생각하면 이해하기 쉽다.

```text
1. 서버가 어떤 서비스를 운영하는가?
        ↓
2. 해당 서비스가 어떤 Protocol / Port를 사용하는가?
        ↓
3. 누가 접속해야 하는가?
        ↓
4. 어느 방향의 Packet인가?
        ↓
5. 필요한 Traffic만 ACCEPT
        ↓
6. 나머지는 DROP 또는 REJECT
        ↓
7. Client에서 실제 통신 검증
```

---

# 33. 핵심 포트 암기표

| Service | Protocol / Port |
|---|---|
| DHCP Server | UDP 67 |
| DHCP Client | UDP 68 |
| DNS | UDP/TCP 53 |
| NTP | UDP 123 |
| FTP | TCP 20/21 |
| SSH | TCP 22 |
| Telnet | TCP 23 |
| HTTP | TCP 80 |
| HTTPS | TCP 443 |
| RPC | TCP/UDP 111 |
| NetBIOS | TCP/UDP 137~139 |
| SMB | TCP 445 |
| NFS | TCP/UDP 2049 |
| MariaDB/MySQL | TCP 3306 |
| Tomcat | TCP 8080 |

---

# 34. 시험 / 면접 대비 핵심 질문

## Q1. INPUT / OUTPUT / FORWARD의 차이는?

**INPUT**은 Linux Host 자신에게 들어오는 Packet, **OUTPUT**은 Host가 직접 생성해 내보내는 Packet, **FORWARD**는 Host를 경유해 다른 곳으로 전달되는 Packet이다.

---

## Q2. `iptables -P INPUT DROP`의 의미는?

INPUT Chain에 등록된 Rule과 일치하지 않는 Packet을 기본적으로 DROP하도록 설정하는 것이다.

---

## Q3. Stateful Firewall이란?

개별 Packet 정보뿐 아니라 현재 Connection의 상태까지 추적하여 NEW, ESTABLISHED, RELATED 등의 상태를 기반으로 Packet을 제어하는 Firewall 방식이다.

---

## Q4. `--sport`와 `--dport`의 차이는?

```text
--sport = Source Port
--dport = Destination Port
```

Packet이 어느 방향으로 이동하는지에 따라 동일한 서비스라도 Source/Destination Port의 의미가 달라질 수 있다.

---

## Q5. DHCP Server와 Client의 Port는?

```text
Server : UDP 67
Client : UDP 68
```

---

## Q6. DHCP의 DORA 과정은?

```text
Discover → Offer → Request → ACK
```

---

## Q7. Loopback Interface를 방화벽에서 허용하는 이유는?

서버 내부 Process 간 통신도 `lo` Interface를 이용하므로 이를 차단하면 `127.0.0.1`을 이용하는 내부 서비스 통신까지 영향을 받을 수 있기 때문이다.

---

## Q8. `nmap -sS -sV`의 의미는?

`-sS`는 TCP SYN Scan, `-sV`는 열린 Port에서 동작하는 Service Version을 탐지하는 옵션이다.

---

# 35. 최종 핵심 요약

```text
[ DHCP ]
Client에게 네트워크 설정 제공
Server UDP 67 / Client UDP 68
DORA = Discover → Offer → Request → ACK

        ↓

[ Network Services ]
DNS / NTP / FTP / SSH / Telnet
HTTP / Samba / NFS / MariaDB / Tomcat

        ↓

[ iptables ]
INPUT   = 나에게 들어오는 Packet
OUTPUT  = 내가 내보내는 Packet
FORWARD = 나를 거쳐가는 Packet

        ↓

Protocol / IP / Port / State 검사

        ↓

ACCEPT / DROP / REJECT

        ↓

[ Stateful ]
NEW / ESTABLISHED / RELATED

        ↓

[ Client Verification ]
ping / nslookup / telnet / nmap
```

### 오늘 실습의 핵심 한 문장

> **DHCP와 여러 네트워크 서비스를 실제로 구성한 뒤, iptables의 기본 정책을 DROP으로 변경하고 서비스별 TCP/UDP Port와 Stateful Rule을 이용하여 필요한 통신만 허용한 후 Client에서 실제 연결 여부를 검증하였다.**

---

## 마지막 암기 포인트

```text
DHCP        → UDP 67/68
DNS         → TCP/UDP 53
NTP         → UDP 123
SSH         → TCP 22
Telnet      → TCP 23
HTTP/HTTPS  → TCP 80/443

INPUT   → 나에게 들어옴
OUTPUT  → 내가 내보냄
FORWARD → 나를 거쳐감

-s       → Source IP
-d       → Destination IP
--sport  → Source Port
--dport  → Destination Port

-j ACCEPT → 허용
-j DROP   → 폐기
-j REJECT → 거부 응답 후 폐기

Stateful 핵심
ESTABLISHED / RELATED
```

> 💀 처음에는 옵션이 많아 복잡해 보이지만, 결국 **“어디서 온 어떤 패킷을 어떤 조건으로 허용하거나 막을 것인가”**를 작성하는 것이 iptables의 핵심이다.
