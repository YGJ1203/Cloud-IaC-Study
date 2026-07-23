# 📘 EIGRP 핵심 개념 정리

> CCNA / Cisco Packet Tracer / Dynamic Routing

---

# 📖 EIGRP란?

EIGRP(Enhanced Interior Gateway Routing Protocol)는 Cisco에서 개발한 Dynamic Routing Protocol이다.

RIP의 단점(Hop Count만 사용하는 방식)을 보완하기 위해 만들어졌으며,

- Bandwidth
- Delay

등의 Metric을 계산하여 최적의 경로를 선택한다.

---

# RIP와 EIGRP 차이

| RIP | EIGRP |
|------|--------|
| Hop Count만 사용 | Bandwidth + Delay 등을 이용한 Metric 계산 |
| 30초마다 Routing Table 전송 | 변경 사항이 있을 때만 Update |
| 최대 Hop Count 15 | Hop Count 제한 사실상 없음 |
| 느린 장애 복구 | 매우 빠른 장애 복구(DUAL) |

---

# Hello Packet

Hello Packet은

**Route를 전달하는 Packet이 아니다.**

목적은

> Neighbor(친구)를 만드는 것

이다.

동작 순서

Hello

↓

Neighbor 생성

↓

Update

↓

Routing Table 생성

---

## 핵심

Hello Packet = "안녕하세요. 같은 EIGRP 쓰시나요?"

---

# Neighbor

Neighbor는

EIGRP 라우터끼리 서로 통신 가능한 상태를 의미한다.

확인 명령어

```bash
show ip eigrp neighbors
```

아무것도 출력되지 않는다면

다음을 확인해야 한다.

- Hello Packet
- AS 번호
- network 설정
- Interface 상태

---

# Update Packet

Update Packet은

라우팅 정보를 Neighbor에게 전달하는 Packet이다.

예)

```
192.168.10.0

10.0.0.0

172.16.0.0
```

---

# Query Packet

현재 사용 중인 Route가 사라졌을 때

Neighbor에게

> "혹시 다른 길 알고 있나요?"

라고 묻는 Packet이다.

---

# Reply Packet

Query에 대한 응답 Packet이다.

```
있습니다.
```

또는

```
없습니다.
```

를 전달한다.

---

# Successor

현재 사용 중인

**최적의 경로**

이다.

---

# Feasible Successor

Successor가 장애가 발생했을 때

즉시 사용할 수 있도록

미리 계산되어 있는

백업 경로이다.

---

## 장점

장애 발생

↓

즉시 백업 경로 사용

↓

빠른 장애 복구

---

# DUAL

EIGRP의 핵심 알고리즘

역할

- 최적 경로 선택
- 백업 경로 관리
- Routing Loop 방지

---

# FD (Feasible Distance)

내 라우터에서 목적지까지의

최종 Metric

---

# RD (Reported Distance)

= Advertised Distance(교재에 따라 AD로 표기)

Neighbor가 알려주는 Metric

---

## 주의

Advertised Distance(AD)

와

Administrative Distance(AD)

는

전혀 다른 개념이다.

---

# Routing Loop

잘못된 경로 선택 시

패킷이

```
R1

↓

R2

↓

R1

↓

R2
```

처럼

무한 반복된다.

결국

TTL이 감소하여

```
TTL Expired
```

가 발생한다.

---

# 주요 명령어

EIGRP 활성화

```bash
router eigrp 100
```

Network 등록

```bash
network 192.168.1.0
```

Auto Summary 비활성화

```bash
no auto-summary
```

Neighbor 확인

```bash
show ip eigrp neighbors
```

Routing Table 확인

```bash
show ip route
```

---

# 핵심 흐름

```
Hello

↓

Neighbor

↓

Update

↓

Routing Table 생성

↓

Route 장애 발생

↓

Query

↓

Reply

↓

Successor 변경
```

---

# 핵심 요약

- Hello Packet → Neighbor 생성
- Update Packet → Route 전달
- Query Packet → 다른 경로 탐색
- Reply Packet → Query 응답
- Successor → 현재 사용하는 최적 경로
- Feasible Successor → 검증된 백업 경로
- DUAL → 최적 경로 계산 및 Routing Loop 방지

---

# 💀 NBA 비유

## Hello Packet

르브론

> "루카? Hello?"

루카

> "네 형."

→ Neighbor 생성

---

## Neighbor Down

포포비치

> "카와이 있나?"

🍁

토론토...

→ Neighbor Down

---

## Query

포포비치

> "알드리지! 다른 작전 있냐?"

→ Query Packet

---

## Successor

주전 선수

---

## Feasible Successor

벤치 에이스

---

## Routing Loop

르브론

> "루카가 해."

루카

> "형이 하세요."

르브론

> "아니 네가."

루카

> "형이."

↓

TTL 감소 💀

---

# 오늘 배운 내용

- RIP는 Hop Count만 사용하기 때문에 비효율적인 경로를 선택할 수 있다.
- EIGRP는 Metric(Bandwidth, Delay)을 계산하여 최적 경로를 선택한다.
- Hello Packet은 Route를 전달하는 것이 아니라 Neighbor를 생성하는 Packet이다.
- Query와 Reply는 장애 발생 시 새로운 경로를 찾기 위해 사용된다.
- Successor와 Feasible Successor 덕분에 EIGRP는 매우 빠르게 장애를 복구할 수 있다.
- DUAL 알고리즘은 Routing Loop를 방지하면서 최적의 경로를 계산한다.

---

# 💡 한 줄 정리

> **EIGRP는 먼저 Neighbor를 형성한 후(DUAL을 통해) 가장 빠르고 안전한 경로를 선택하는 Dynamic Routing Protocol이다.**