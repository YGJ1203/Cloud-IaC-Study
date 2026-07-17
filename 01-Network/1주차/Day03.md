# 📡 ICMP, ARP & Wireshark Packet Analysis

## 📌 ICMP (Internet Control Message Protocol)

ICMP는 IP 통신 상태 확인 및 오류 메시지 전달을 위한 Layer 3 보조 프로토콜이다.

주요 용도:

- 목적지와 통신 가능 여부 확인
- 네트워크 장애 분석
- 경로 추적

---

# Ping 동작 구조

Ping 명령은 ICMP Echo Request와 Echo Reply를 이용한다.


Client

```
ping 10.1.1.1
```


## Echo Request

ICMP Type

```
Type 8
```

Packet:

```
SA : 192.168.1.1
DA : 10.1.1.1
```

---

## Echo Reply

ICMP Type

```
Type 0
```

Packet:

```
SA : 10.1.1.1
DA : 192.168.1.1
```

---

# Ping 결과 분석

Example:

```bash
Reply from 10.1.1.1: bytes=32 time=1ms TTL=126
```

의미:

|항목|설명|
|-|-|
|bytes|ICMP 데이터 크기|
|time|응답 시간|
|TTL|Time To Live 값|

시간 단위:

```
sec
↓
ms (millisecond)
↓
us (microsecond)
```

---

# ⚠️ Ping 실패 원인

예:

```bash
Request Timed Out
```

가능 원인:

- 대상 시스템 Down
- Routing 문제
- 방화벽에서 ICMP 차단

---

# Tracert 동작 원리

목적지까지 지나가는 Router 경로 확인 명령어

```bash
tracert 8.8.8.8
```


동작 방식:

처음 Packet:

```
TTL = 1
```

Router 통과:

```
TTL -1
```

TTL 값이 0이면:

```
ICMP Time Exceeded
```

응답 발생


TTL 값을 증가시키며 목적지까지 경로 확인

---

# 🔎 TCP Port 상태 확인

## Port Open 상태


Client

```
SYN
---------->

        <----------
        SYN + ACK
```

TCP 연결 성공


---

## Port Closed 상태

Client

```
SYN
---------->

        <----------
        RST + ACK
```

연결 거부

---

# UDP Port Closed

UDP는 연결 과정이 없다.

따라서 Port 사용 불가 시 ICMP 응답 발생


```
ICMP Type 3
Code 3

Destination Unreachable
Port Unreachable
```

---

# 🔍 ARP

Address Resolution Protocol

역할:

IP 주소에 대응되는 MAC 주소 확인


---

# ARP가 필요한 이유

IP 주소만 알고 있으면 Ethernet Frame 생성 불가

예:

C → D 통신


IP Header

```
SA 10.1.1.1
DA 10.1.1.2
```


Ethernet Header

```
SA C MAC
DA ???
```

목적지 MAC 필요


---

# ARP Request

Broadcast 방식


질문:

```
10.1.1.2 사용하는 장비 누구야?
MAC 주소 알려줘
```


Ethernet

```
SA 내 MAC

DA FF:FF:FF:FF:FF:FF
```

---

# ARP Reply

Unicast 방식


응답:

```
내 MAC 주소는 xxxx 입니다.
```


Ethernet

```
SA 목적지 MAC

DA 요청자 MAC
```

---

# 다른 Network 통신 ARP

다른 Network 목적지:

```
10.1.1.1

↓

192.168.1.200
```

목적지 MAC을 찾지 않는다.

Gateway MAC을 찾는다.

이유:

다른 Network 이동은 Router 담당

---

# 📌 TCP vs UDP

|기능|TCP|UDP|
|-|-|-|
|Connection|O|X|
|3-Way Handshake|O|X|
|Reliability|O|X|
|Flow Control|O|X|
|Retransmission|O|X|
|Speed|느림|빠름|

---

# OSI 7 Layer

|Layer|Name|Protocol|
|-|-|-|
|7|Application|HTTP, DNS, FTP|
|6|Presentation|Data Format|
|5|Session|Connection|
|4|Transport|TCP, UDP|
|3|Network|IP|
|2|Data Link|Ethernet|
|1|Physical|Cable, Signal|

---

# 🦈 Wireshark Filter

## IP

Source IP

```
ip.src
```

Destination IP

```
ip.dst
```

---

## MAC

Source MAC

```
eth.src
```

Destination MAC

```
eth.dst
```

---

## TCP

Source Port

```
tcp.srcport
```

Destination Port

```
tcp.dstport
```

---

# TCP Flag Filter

## SYN 확인

```wireshark
tcp.flags.syn == 1
```


SYN만 확인:

```wireshark
tcp.flags == 0x02
```

---

## SYN ACK 확인

Binary:

```
ACK SYN

1   1
```

Value:

```
16 + 2 = 18

Hex = 0x12
```


Filter:

```wireshark
tcp.flags == 0x12
```

---

## ACK 확인

```wireshark
tcp.flags == 0x10
```

---

# 3-Way Handshake Filter

```wireshark
tcp.flags == 0x10
&&
tcp.seq == 1
&&
tcp.ack == 1
```

---

# HTTP 분석

```wireshark
http
```

확인 가능:

- Request
- Response
- Header

---

# FTP / Telnet 보안 분석

평문 Protocol

Wireshark에서 확인 가능:

- ID
- Password

보안 대체:

FTP → SFTP

Telnet → SSH

---

# 정리

✔ ICMP는 네트워크 상태 확인 목적  
✔ Ping은 Echo Request / Reply 구조  
✔ Tracert는 TTL 값을 이용한 경로 추적  
✔ ARP는 IP → MAC 변환 역할  
✔ TCP 상태는 Flag 분석으로 확인 가능  
✔ Wireshark Filter 활용은 장애 분석 핵심 기술이다.