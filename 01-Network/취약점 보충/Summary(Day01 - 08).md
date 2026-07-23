# 📚 Cloud & IaC Study Summary

> Cloud & IaC 과정에서 학습한 네트워크 및 Git 기초 내용을 요약한 문서입니다.

---

# 🎯 학습 목표

Cloud 환경에서는 단순히 서버를 다루는 것뿐 아니라, 네트워크와 자동화에 대한 이해가 필수적입니다.

이번 학습에서는 TCP/IP 네트워크의 기본 원리부터 서브넷팅, 정적 라우팅, Packet Tracer 실습, Git/GitHub 활용까지 단계적으로 학습했습니다.

---

# 🌐 Network Fundamentals

## OSI 7 Layer

* Physical
* Data Link
* Network
* Transport
* Session
* Presentation
* Application

### 핵심

OSI 모델은 데이터가 송수신되는 과정을 계층별로 설명하는 참조 모델입니다.

---

## TCP/IP Model

* Network Access
* Internet
* Transport
* Application

### 핵심

실제 인터넷 통신에서 사용되는 프로토콜 구조입니다.

---

# 📦 TCP / UDP

## TCP

* Connection Oriented
* Reliable
* Flow Control
* Error Recovery
* 3-Way Handshake

사용 예시

* HTTP
* HTTPS
* SSH
* FTP

---

## UDP

* Connectionless
* Fast
* Lightweight

사용 예시

* DNS
* VoIP
* Streaming

---

# 📡 ICMP

학습 내용

* ping
* tracert
* TTL
* Echo Request
* Echo Reply

### 핵심

ICMP는 네트워크 연결 상태를 확인하고 장애를 분석하는 데 사용됩니다.

---

# 🔍 ARP

학습 내용

* ARP Request
* ARP Reply
* ARP Cache

### 동작 과정

Destination IP 확인

↓

동일 네트워크 여부 확인

↓

목적지 MAC 주소 조회

↓

Ethernet Frame 생성

### 실습

* arp -a
* ipconfig /all

---

# 🌍 DNS

학습 내용

* Domain Name
* DNS Query
* Name Resolution

### 흐름

[www.google.com](http://www.google.com)

↓

DNS Server

↓

IP Address 반환

↓

통신 시작

---

# ⚡ DHCP

학습 내용

DORA Process

* Discover
* Offer
* Request
* Acknowledge

---

# 🚪 Default Gateway

### 핵심 개념

동일 네트워크가 아닌 목적지로 패킷을 전달할 때 사용하는 출입구입니다.

---

# 🧮 Subnetting

학습 내용

* Prefix
* Network Address
* Broadcast Address
* Host Range
* CIDR

### 예제

141.160.7.148/27

Network

141.160.7.128

Broadcast

141.160.7.159

---

# 🧩 VLSM

학습 내용

* Variable Length Subnet Mask
* Host 수에 따른 효율적인 IP 할당
* 주소 낭비 최소화

---

# 🛣️ Static Routing

주요 명령어

```bash
ip route
```

### 핵심

라우터가 목적지 네트워크를 찾기 위한 경로를 직접 설정합니다.

---

# 🌍 Default Route

```bash
0.0.0.0/0
```

### 핵심

목적지를 모를 경우 사용하는 기본 경로입니다.

---

# 🗺️ Routing Table

주요 명령어

```bash
show ip route
```

학습 내용

* Longest Prefix Match
* Administrative Distance
* Static Route
* Connected Route

---

# 🖥️ Cisco Packet Tracer

실습 내용

* Router
* Switch
* PC
* Server 구성

주요 명령어

```bash
show ip interface brief

show ip route

show controllers serial

ping

tracert
```

---

# 🌱 Git & GitHub

학습 내용

```bash
git clone

git add

git commit

git push

git pull

git fetch
```

추가로 Git Pull 과정에서 발생한 Ref Lock 오류를 해결하며 원격 추적 브랜치(origin/main)의 개념도 학습했습니다.

---

# 💀 Troubleshooting

## 1. PC에 Gateway 주소를 IP로 설정

### 원인

PC IP 대신 Gateway 주소를 설정

### 결과

인터페이스는 Up

하지만 Ping 실패

### 배운 점

Link Up과 정상 통신은 서로 다른 개념이다.

---

## 2. Default Gateway 설정 오류

### 원인

Gateway를 잘못 설정

### 해결

Router Interface 주소를 Gateway로 수정

---

## 3. ARP로 인한 첫 Ping Timeout

### 원인

ARP Cache 생성 과정

### 해결

MAC 주소 학습 이후 정상 통신

---

## 4. Static Route 누락

### 원인

Return Path 미설정

### 해결

반대 방향 Static Route 추가

---

## 5. Serial Interface 설정

확인 명령어

```bash
show controllers serial
```

DCE 장비에서 Clock Rate 설정 여부 확인

---

## 6. Git Pull Ref Lock 오류

### 오류

```
cannot lock ref 'refs/remotes/origin/main'
```

### 원인

Local Remote Tracking Reference 충돌

### 해결

```bash
git update-ref -d refs/remotes/origin/main

git fetch origin

git pull origin main
```

---

# 🚀 앞으로 학습할 내용

* Dynamic Routing (RIP, OSPF)
* VLAN
* ACL
* NAT
* SSH
* Ansible
* YAML
* Docker
* Kubernetes
* AWS
* Terraform

---

# 💡 느낀 점

이번 학습을 통해 단순히 명령어를 암기하는 것이 아니라, 패킷이 이동하는 원리와 네트워크의 동작 방식을 이해하는 데 집중했습니다.

Packet Tracer 실습과 다양한 트러블슈팅을 경험하면서 문제를 단계적으로 분석하고 해결하는 사고방식을 익힐 수 있었습니다.

앞으로는 이러한 네트워크 기초를 바탕으로 IaC와 Cloud 환경에서의 자동화 기술을 학습하며 운영 역량을 더욱 발전시키는 것을 목표로 합니다.
