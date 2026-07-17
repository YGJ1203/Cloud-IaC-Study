# 🌐 Network Basic

## 📌 네트워크(Network)

네트워크란 여러 시스템(System) 간 연결을 통해 데이터를 공유하기 위한 구조이다.

초기 네트워크는 미국 군사 목적의 정보 공유 시스템에서 시작되었으며,
현재는 기업, 인터넷, 클라우드 환경의 핵심 기반 기술이다.

## 네트워크 사용 목적

- 시스템 간 정보 공유
- 데이터 전달 시간 감소
- 비용 절감
- 중앙 집중 운영 및 관리 가능

클라우드 환경 역시 네트워크의 장점을 기반으로 한다.

기존 방식:
- 직접 서버 구매
- 전산실 구축
- 직접 운영 관리 필요

클라우드 방식:
- 필요한 만큼 자원 사용
- 물리 인프라 구축 비용 감소
- 통합 운영 관리 가능

---

# 📦 Protocol

## 프로토콜(Protocol)이란?

데이터 통신을 위한 약속된 절차와 규칙이다.

예시:
택배를 보낼 때 송장 정보가 필요한 것처럼  
네트워크 데이터 역시 전달을 위해 여러 프로토콜 정보를 포함한다.

---

# 📌 Encapsulation & Decapsulation

## Encapsulation (캡슐화)

송신자가 데이터를 전송하기 위해 필요한 프로토콜 정보를 순서대로 추가하는 과정.

예시 HTTP 데이터 전송

```
Ethernet Header
        |
        ↓
IP Header
        |
        ↓
TCP Header
        |
        ↓
HTTP Data
```

실제 구조

```
Ethernet | IP | TCP | HTTP
 14B      20B  20B
```

각 계층에서 추가되는 정보를 Header라고 한다.

---

## 주요 프로토콜 구조

### HTTP

```
Ethernet | IP | TCP | HTTP

Ethernet : 14 Byte
IP       : 20 Byte
TCP      : 20 Byte(Default)
```

---

### DNS

```
Ethernet | IP | UDP | DNS

Ethernet : 14 Byte
IP       : 20 Byte
UDP      : 8 Byte
```

---

### ICMP

```
Ethernet | IP | ICMP
```

---

### ARP

```
Ethernet | ARP | Padding
```

ARP는 최소 Ethernet Frame 크기를 맞추기 위해 Padding 사용

---

## Decapsulation (역캡슐화)

수신자가 받은 데이터를 하나씩 해석하는 과정.

Encapsulation의 반대 순서로 진행된다.

```
Ethernet 확인
      ↓
IP 확인
      ↓
TCP/UDP 확인
      ↓
Application Data 확인
```

목적지가 자신이 아니면 폐기한다.

---

# 🏢 LAN (Local Area Network)

## LAN이란?

제한된 공간에서 사용하는 내부 네트워크

예:
- 회사 내부망
- 학교 네트워크
- 가정 네트워크

## 사용 장비

### Switch

현재 LAN 환경에서 가장 많이 사용하는 장비

역할:
- 목적지 기반 데이터 전달
- 효율적인 내부 통신

### Hub

과거 사용 방식

특징:
- 받은 데이터를 모든 포트로 전달
- 비효율적
- 현재 거의 사용하지 않음

---

## Cable

### UTP Cable

일반적으로 사용하는 LAN Cable

특징:
- 내부 선이 꼬여있는 구조
- 노이즈 감소 목적

### STP Cable

Shield 처리된 Cable

사용:
- 대형 데이터센터
- 높은 안정성이 필요한 환경

---

# 📌 Network Topology

## Bus Topology

초창기 방식

단점:
- 장애 영향 범위 큼
- 안정성 낮음


## Star Topology ⭐

현재 권장 방식

장점:
- 관리 편의
- 장애 대응 용이


실무 구성:

```
Star Topology
+
장비 이중화
+
Link 이중화

=
HA (High Availability)
```

---

# ⭐ 네트워크 설계 3요소

## 1. 확장성 (Scalability)

서비스 증가 시 쉽게 확장 가능해야 함

## 2. 이중성 (Redundancy)

장애 대비 구조 필요

## 3. 가용성 (Availability)

서비스 지속 운영 가능

---

# 🔐 보안 3요소 CIA

## Confidentiality (기밀성)

인가된 사용자만 접근 가능

## Integrity (무결성)

데이터가 변경되지 않아야 함

## Availability (가용성)

필요할 때 서비스 이용 가능

---

# 🔥 Zero Trust

"아무도 신뢰하지 않는다"

기존 방식:
```
내부 사용자 = 신뢰
외부 사용자 = 차단
```

Zero Trust:

```
내부 / 외부 관계없이
항상 인증 + 검증
```

---

# 🌎 WAN (Wide Area Network)

LAN과 LAN을 연결하는 외부 네트워크

## 주요 장비

Router

## 사용 방식

기업은 ISP 업체로부터 회선을 임대한다.

ISP 예:

- KT
- SKT
- LG U+

---

# 📌 관련 기업 유형

## ISP

Internet Service Provider

역할:
- 인터넷 회선 제공
- 전용망 제공


## SI / NI

역할:

- 시스템 구축
- 네트워크 구축
- 운영 유지보수


## Vendor

제품 연구/개발/판매 기업

예:

- Cisco
- Juniper
- Fortinet

---

# 🌐 Internet

전 세계적으로 연결된 네트워크

사용 Protocol

```
TCP/IP
```

주요 연결 방식:

- 해저 케이블
- ISP Backbone Network

---

# 🏢 Intranet

기업 내부 전용 네트워크

용도:

- 사내 게시판
- 업무 시스템
- 기록 조회

보안상 외부 접근 제한

---

# 🔁 데이터 통신 구조

네트워크는 항상 양방향 구조이다.

```
Client                Server

Request  -------->

         <-------- Response
```

---

# 📡 데이터 전송 방식

## Unicast

1 : 1 통신

사용:
- 웹 접속
- VOD 서비스


## Broadcast

1 : 전체 통신

사용:
- ARP 요청
- DHCP 요청


## Multicast

1 : 특정 그룹

사용:
- IPTV
- 실시간 방송

---

# 🔥 공격 유형

## Brute Force Attack

ID/PW 무차별 대입 공격

방식:

```
Attacker -----> Target
```

Unicast 기반


---

## Flooding Attack

대량 Packet 전송으로 서버 부하 발생

예:

- 초당 수십만 Packet 요청

---

# 🚪 Port Number

Port는 서비스 구분 번호이다.

관리 기관:

IANA

---

# Well Known Port (0 ~ 1023)

| Protocol | Port |
|---|---|
| HTTP | 80 |
| HTTPS | 443 |
| SSH | 22 |
| Telnet | 23 |
| FTP | 21 |
| FTP-DATA | 20 |
| SMTP | 25 |
| POP3 | 110 |
| IMAP | 143 |
| DNS | 53 |
| DHCP Server | 67 |
| DHCP Client | 68 |
| TFTP | 69 |
| NTP | 123 |
| SNMP | 161 |
| Syslog | 514 |
| MySQL | 3306 |

---

# 🔐 보안 관점 Protocol 비교

## Telnet

문제:
- 평문 전송
- 계정 정보 노출 가능

대체:

SSH 사용

---

## FTP

문제:
- 인증 정보 암호화 X

---

## SMTP / POP3

메일 관련 프로토콜

SMTP:
메일 송신

POP3:
메일 수신

하지만 기본 방식은 암호화되지 않아 보안 취약

---

# 🌍 DNS

Domain Name → IP 변환 서비스

예:

```
www.naver.com

↓

223.xxx.xxx.xxx
```

---

# ⚙️ DHCP

Dynamic Host Configuration Protocol

역할:

IP 주소 자동 할당

예:

500대 PC 환경에서 DHCP 서버가 자동 관리

---

# 📌 IP Address

IP Header 내부 주소

역할:

다른 네트워크까지 데이터 전달

IPv4

```
32bit
2^32 개 주소
```

IPv6

```
128bit
2^128 개 주소
```

---

# 📌 MAC Address

Ethernet Header 내부 주소

특징:

- 48bit
- 16진수 사용
- Local Network 내부 통신 담당

PC/Host 식별에서는 MAC 주소가 더 고유하다.

---

# 📝 정리

✔ Network는 클라우드 인프라의 기반이다.  
✔ 데이터 전송 과정은 Encapsulation / Decapsulation 구조이다.  
✔ LAN 내부는 MAC 기반, Network 간 이동은 IP 기반이다.  
✔ 보안을 위해 암호화 Protocol 사용이 중요하다.  
✔ Cloud Engineer는 Network 흐름 이해가 필수이다.