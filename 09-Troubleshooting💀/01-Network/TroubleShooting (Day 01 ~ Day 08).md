# 🛠️ Troubleshooting Collection

> Cloud & IaC 학습 과정에서 직접 경험한 문제와 해결 과정을 기록한 문서입니다.
>
> 단순히 해결 방법을 기록하는 것이 아니라 **원인 분석 → 해결 과정 → 배운 점(Lessons Learned)** 을 함께 정리하여 동일한 문제가 발생했을 때 빠르게 대응할 수 있도록 작성했습니다.

---

# 📌 Troubleshooting Templates

모든 문제는 아래 형식으로 기록합니다.

```text
문제 발생

↓

원인 분석

↓

해결 방법

↓

배운 점 (Lessons Learned)
```

---

# 1. PC IP 대신 Gateway IP를 설정한 실수 💀

## 문제

Packet Tracer에서 PC와 Router가 연결되어 있었지만 Ping이 실패했다.

Interface 상태는 모두 **up/up** 으로 정상 표시되었다.

## 원인

PC 자신의 IP 대신 Router Interface(Gateway) 주소를 입력하였다.

```text
PC IP : 192.168.10.1 ❌
Gateway : 192.168.10.1
```

정상 설정

```text
PC IP : 192.168.10.10
Gateway : 192.168.10.1
```

## 해결

* PC IP 수정
* Gateway는 Router Interface 주소로 설정

## Lessons Learned

* Interface Up ≠ 정상 통신
* IP Address와 Gateway는 서로 다른 역할을 가진다.

---

# 2. Default Gateway 개념 혼동

## 문제

같은 네트워크에서도 반드시 Gateway를 거쳐 통신한다고 생각했다.

## 원인

Gateway의 역할을 정확히 이해하지 못했다.

## 해결

같은 네트워크

→ ARP를 통해 직접 통신

다른 네트워크

→ Default Gateway로 전달

## Lessons Learned

Gateway는 **다른 네트워크로 나갈 때만 사용**된다.

---

# 3. 첫 Ping Timeout

## 문제

첫 번째 Ping만 Timeout이 발생하고 이후에는 정상 응답했다.

## 원인

ARP Cache가 존재하지 않아 먼저 ARP Request / Reply가 수행되었다.

## 해결

```bash
arp -a
```

명령으로 ARP Cache 생성 여부 확인

## Lessons Learned

첫 Ping Timeout은 장애가 아니라 ARP 과정일 수 있다.

---

# 4. 목적지 PC MAC을 찾는다고 생각한 실수

## 문제

다른 네트워크에서도 목적지 PC의 MAC 주소를 찾는다고 생각했다.

## 원인

ARP 동작 원리를 정확히 이해하지 못했다.

## 해결

같은 Network

→ 상대 PC MAC 조회

다른 Network

→ Gateway MAC 조회

## Lessons Learned

ARP는 항상 **현재 전송 대상**의 MAC 주소를 찾는다.

---

# 5. Static Route 누락

## 문제

A → B는 Ping 성공

B → A는 Timeout

## 원인

Forward Path만 존재하고 Return Path가 없었다.

## 해결

반대 방향 Static Route 추가

```bash
ip route <Destination> <Mask> <Next-Hop>
```

## Lessons Learned

네트워크는 왕복 통신이다.

Return Route도 반드시 존재해야 한다.

---

# 6. Routing보다 Interface만 확인한 실수

## 문제

Interface가 Up이라서 Routing에는 문제가 없다고 생각했다.

## 원인

Routing Table을 확인하지 않았다.

## 해결

```bash
show ip route
```

먼저 확인하는 습관을 만들었다.

## Lessons Learned

Interface보다 Routing 문제인 경우가 훨씬 많다.

---

# 7. Serial Interface 문제

## 문제

Serial 연결이 정상적으로 동작하지 않았다.

## 원인

DCE 장비의 Clock Rate를 확인하지 않았다.

## 해결

```bash
show controllers serial
```

명령으로 DCE 여부 확인

Clock Rate 설정

## Lessons Learned

Serial 연결에서는 DCE가 Clock을 제공한다.

---

# 8. DNS Server 설정 혼동

## 문제

DNS Server 장비에도 DNS Server Address를 입력해야 한다고 생각했다.

## 원인

Server와 Client 설정을 혼동했다.

## 해결

Server

→ DNS Service 활성화

Client

→ DNS Server IP 입력

## Lessons Learned

Server와 Client의 DNS 설정 목적은 다르다.

---

# 9. Packet Tracer Simulation Mode 오해

## 문제

CLI에서는 Ping 성공

Simulation에서는 아무것도 보이지 않았다.

## 원인

Realtime과 Simulation Mode 차이를 이해하지 못했다.

## 해결

Capture/Forward

Auto Capture 사용

## Lessons Learned

Simulation Mode는 패킷 흐름을 분석하는 도구이다.

---

# 10. Prefix 계산 실수

## 문제

Subnetting에서 Network Address를 잘못 계산했다.

## 원인

Host Bit 계산 실수

## 해결

항상

1. Prefix 확인
2. Increment 계산
3. Network
4. Broadcast
5. Host Range

순으로 계산

## Lessons Learned

Subnetting은 암기가 아니라 Bit를 이해해야 한다.

---

# 11. Router Interface 개념 혼동

## 문제

Router Interface 여러 개가 같은 Network라고 생각했다.

## 원인

Layer3 장비의 역할을 이해하지 못했다.

## 해결

각 Interface마다 다른 Network를 구성

## Lessons Learned

Router Interface 하나가 하나의 Network이다.

---

# 12. Git Pull Ref Lock 오류

## 문제

```text
cannot lock ref 'refs/remotes/origin/main'
```

## 원인

Remote Tracking Branch 정보 충돌

## 해결

```bash
git update-ref -d refs/remotes/origin/main

git fetch origin

git pull origin main
```

## Lessons Learned

Git Pull은

* Fetch
* Reference Update
* Merge

과정을 수행한다.

---

# 13. Ping만 보고 장애라고 판단한 실수

## 문제

Ping Timeout만 보고 네트워크 장애라고 생각했다.

## 원인

ARP, Routing, Gateway 등을 확인하지 않았다.

## 해결

다음 순서대로 점검하는 습관을 만들었다.

1. Interface
2. IP
3. Gateway
4. Routing
5. ARP
6. ICMP

## Lessons Learned

문제 해결은 추측보다 확인이 우선이다.

---

# 📖 Network Troubleshooting Checklist

## PC

```bash
ipconfig
ipconfig /all
arp -a
ping
tracert
```

## Router

```bash
show ip interface brief

show ip route

show controllers serial
```

## Git

```bash
git status

git fetch

git pull

git log
```

---

# 💡 Lessons Learned

이번 학습에서 가장 크게 얻은 것은 명령어보다 **문제를 분석하는 사고방식**이었다.

특히 다음 내용을 반복해서 경험했다.

* Interface Up ≠ 정상 통신
* Ping 하나만으로 장애를 판단하지 않는다.
* Gateway는 다른 Network로 나갈 때만 사용한다.
* ARP를 이해하면 Ping의 동작 원리를 이해할 수 있다.
* Network는 왕복 경로(Forward + Return)가 모두 존재해야 한다.
* Router Interface 하나가 하나의 Network이다.
* Routing Table은 반드시 확인한다.
* Subnetting은 Bit 단위로 이해한다.
* Git 오류도 내부 동작 원리를 이해하면 해결할 수 있다.
* 대부분의 문제는 단계적으로 확인하면 해결할 수 있다.

---

# 🚀 앞으로 추가할 예정인 Troubleshooting

* Dynamic Routing (RIP / OSPF)
* VLAN
* Trunk
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

> **"좋은 엔지니어는 문제를 한 번도 겪지 않은 사람이 아니라, 같은 문제를 두 번 반복하지 않는 사람이다."**

이 문서는 앞으로 학습 과정에서 경험하는 모든 트러블슈팅을 지속적으로 기록하고 업데이트할 예정이다.
