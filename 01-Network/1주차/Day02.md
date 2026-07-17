# 🌐 Packet Flow & TCP/IP Model

## 📌 IP 주소와 MAC 주소 역할

네트워크 통신에서는 IP 주소와 MAC 주소가 함께 사용된다.

두 주소는 담당 범위가 다르다.

|구분|역할|계층|
|-|-|-|
|IP Address|최종 목적지까지 전달|Layer 3|
|MAC Address|현재 네트워크 구간 전달|Layer 2|

---

# 🚚 Packet 이동 과정

예:

A → J 통신

## IP Header

처음부터 끝까지 유지된다.

```
Source IP : A
Destination IP : J
```

목적지는 최종 통신 대상이기 때문이다.

---

## Ethernet Header

구간마다 변경된다.

이유:

Ethernet은 현재 연결된 다음 장비까지만 전달하기 때문

---

# 예시 Flow

## 1) A → Gateway(B)

Layer 3

```
IP Header

SA : A
DA : J
```

Layer 2

```
Ethernet Header

SA : A MAC
DA : Gateway MAC
```

Gateway 도착 후:

```
Ethernet Decapsulation
```

---

## 2) Router → Router 구간

IP 유지

```
SA : A
DA : J
```

Ethernet 변경

```
SA : Router Interface MAC
DA : Next Router MAC
```

---

## 3) 최종 목적지 J

Ethernet 확인

↓

IP Header 확인

↓

DA = J

↓

IP Decapsulation 진행

---

# 📌 Same Network vs Different Network

## 같은 네트워크

PC1

```
192.168.1.1
```

↓

PC11

```
192.168.1.11
```

IP

```
SA 192.168.1.1
DA 192.168.1.11
```

Ethernet

```
SA PC1 MAC
DA PC11 MAC
```

---

# 다른 네트워크

PC1

```
192.168.1.1
```

↓

PC2

```
10.1.1.1
```

IP

```
SA 192.168.1.1
DA 10.1.1.1
```

Ethernet

```
SA PC1 MAC
DA Gateway MAC
```

다른 네트워크는 Gateway를 통해 이동한다.

---

# 🖥 주요 서버 종류

## DHCP Server

Dynamic Host Configuration Protocol

역할:

IP 설정 자동 제공

제공 정보:

- IP Address
- Subnet Mask
- Gateway
- DNS Server


확인 명령어:

```bash
ipconfig /all
```

---

# Web Server

대표 프로그램:

Windows

- IIS

Linux

- Apache
- Nginx


---

# FTP Server

역할:

파일 송수신

Linux:

- vsftpd
- proftpd

---

# DNS Server

Domain → IP 변환

Linux:

- bind(named)

---

# Email Server

송신:

SMTP

수신:

POP3 / IMAP

---

# 📡 SNMP

Simple Network Management Protocol

네트워크 장비 모니터링 프로토콜

NMS(Network Management System)가 장비 상태 확인

Monitoring:

- CPU
- Memory
- Traffic
- Temperature

---

# 🚦 TCP

Transmission Control Protocol

Layer 4 Protocol

특징:

- 연결 지향
- 신뢰성 제공
- 데이터 순서 보장

---

# 🤝 TCP 3-Way Handshake

통신 전 연결 과정


Client → Server

```
SYN
```

Server → Client

```
SYN + ACK
```

Client → Server

```
ACK
```

결과:

```
ESTABLISHED
```

통신 가능 상태

---

# TCP Port Closed 상황

Server TCP 80 Closed


Client

```
SYN →
```

Server

```
← RST + ACK
```

연결 거부

---

# TCP Segment

전송 계층 데이터 단위

Application Data

↓

분할

↓

TCP Header 추가

↓

Segment 생성

---

# Sliding Window

현재 TCP에서 사용하는 흐름 제어 방식

특징:

- 여러 Segment 연속 전송 가능
- ACK 기반 확인

Stop & Wait보다 효율적

---

# TCP Header

기본 크기:

20 Byte

주요 Field:

|Field|Size|
|-|-|
|Source Port|2 Byte|
|Destination Port|2 Byte|
|Sequence Number|4 Byte|
|ACK Number|4 Byte|
|Flag|2 Byte|
|Window Size|2 Byte|
|Checksum|2 Byte|

---

# ⚠️ Telnet 보안 문제

Telnet은 평문 전송

Packet Capture 시:

```
username : admin
password : cisco
```

노출 가능

따라서 SSH 사용 권장

---

# UDP

User Datagram Protocol

Layer 4 Protocol

특징:

- 비연결 방식
- 빠른 처리
- Header 8 Byte

사용:

- DNS
- DHCP
- TFTP
- NTP
- SNMP

---

# TCP vs UDP

|기능|TCP|UDP|
|-|-|-|
|연결 과정|O|X|
|3-Way Handshake|O|X|
|흐름 제어|O|X|
|혼잡 제어|O|X|
|재전송|O|X|
|오류 검사|O|O|

---

# 🌎 IP Protocol

Layer 3 Protocol

Header:

20 Byte

역할:

다른 Network까지 데이터 전달

장비:

Router

---

# TTL(Time To Live)

목적:

Routing Loop 방지

Router 통과 시:

```
TTL -1
```

초기값 예:

Cisco : 255

Windows : 128

Linux : 64

---

# MTU & Fragmentation

Ethernet MTU:

```
1500 Byte
```

큰 데이터는 Fragment 처리

예:

4000 Byte

↓

```
1500
1500
1000
```

---

# Ethernet

Layer 2 Protocol

Header:

```
14 Byte
+
FCS 4 Byte
```

역할:

Local Network 데이터 전달

주소:

MAC Address

장비:

Switch

---

# Layer 정리

## Layer 4

Protocol:

TCP / UDP

주소:

Port Number

장비:

L4 Switch

---

## Layer 3

Protocol:

IP

주소:

IP Address

장비:

Router

---

## Layer 2

Protocol:

Ethernet

주소:

MAC Address

장비:

Switch

---

## Layer 1

역할:

전기 신호 전달

장비:

Cable
Hub

---

# 정리

✔ IP는 End-to-End 주소이다.  
✔ MAC은 Hop-to-Hop 주소이다.  
✔ Router 통과 시 Ethernet Header는 변경된다.  
✔ TCP는 안정성, UDP는 속도가 목적이다.  
✔ 네트워크 장애 분석은 Layer별 접근이 중요하다.