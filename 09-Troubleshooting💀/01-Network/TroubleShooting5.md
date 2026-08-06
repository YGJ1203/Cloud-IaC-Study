# HSRP Troubleshooting - e0/0 장애와 e0/1 장애의 차이

## 개요

HSRP(Hot Standby Router Protocol)는 장애 발생 시 게이트웨이 이중화를 제공하는 프로토콜이다.

이번 실습에서는 GW1 라우터의 **외부 인터페이스(Ethernet0/0)** 와 **내부 트렁크 인터페이스(Ethernet0/1)** 를 각각 Shutdown하여 HSRP의 상태(State)가 어떻게 변화하는지 비교하였다.

---

# 테스트 환경

- GW1 (Primary)
- GW2 (Secondary)
- HSRP 적용
- Tracking 설정

```cisco
track 1 interface e0/0 line-protocol

interface e0/1.11
 standby 11 priority 120
 standby 11 preempt
 standby 11 track 1 decrement 30
```

---

# Case 1. GW1 외부 인터페이스(e0/0) Shutdown

## 인위적 장애 유발

GW1 라우터의 외부 인터페이스인 **Ethernet0/0** 을 Shutdown하여 인터넷 회선 장애를 강제로 발생시켰다.

```cisco
conf t
interface e0/0
 shutdown
```

---

## HSRP 상태 변화

Tracking 기능이 외부 회선 장애를 감지하여 Priority를 자동 감소시켰다.

```
120
 ↓
90
```

Priority가 더 높은 GW2가 Active 역할을 자동으로 인계받았다.

---

## GW1

```
State : Standby
Priority : 90
Standby : local
```

---

## GW2

```
State : Active
Priority : 100
Active : local
```

---

## 원인 분석

e0/0은 인터넷 방향 인터페이스이므로 Shutdown되더라도

- VLAN 인터페이스는 정상
- HSRP Hello Packet 정상 송수신

따라서

HSRP 자체는 정상 동작하며

Tracking에 의해 Priority만 감소하여 Active Router가 변경된다.

---

# Case 2. GW1 내부 인터페이스(e0/1) Shutdown

## 인위적 장애 유발

GW1 라우터의 내부 트렁크 인터페이스인 **Ethernet0/1** 을 Shutdown하여 내부망 연결 장애를 강제로 발생시켰다.

```cisco
conf t
interface e0/1
 shutdown
```

---

## HSRP 상태 변화

e0/1은 모든 Sub Interface의 부모 인터페이스이다.

```
e0/1
 ├── e0/1.11
 ├── e0/1.12
 ├── e0/1.13
 └── ...
```

부모 인터페이스가 Down되면서 모든 VLAN Sub Interface도 함께 Down되었다.

결과적으로 HSRP Hello Packet 송수신이 불가능해졌다.

---

## GW1

```
State : Init
Active : unknown
Standby : unknown
```

---

## GW2

```
State : Active
Active : local
Standby : unknown
```

---

## 원인 분석

HSRP는 VLAN Sub Interface를 통해 Hello Packet을 주고받는다.

그러나 e0/1이 Shutdown되면서

- VLAN Interface Down
- Hello Packet 송수신 불가

상대 Router(GW2)는 Standby Router를 찾을 수 없어

```
Standby unknown
```

상태가 된다.

GW1 역시 HSRP를 수행할 인터페이스 자체가 사라져

```
State Init
```

으로 변경된다.

---

# e0/0 장애와 e0/1 장애 비교

| 구분 | e0/0 Shutdown | e0/1 Shutdown |
|------|---------------|---------------|
| 장애 위치 | 외부 회선 | 내부 트렁크 |
| Tracking 동작 | O | X |
| Priority 감소 | O | X |
| HSRP Hello | 정상 | 불가능 |
| GW1 상태 | Standby | Init |
| GW2 상태 | Active | Active |
| Active Router 변경 | Priority 감소에 의해 변경 | 상대 Router가 사라져 Active 유지 |

---

# 핵심 정리

- e0/0 장애는 Tracking에 의해 Priority가 감소하며 Active Router가 변경된다.
- e0/0 장애에서도 HSRP Hello Packet은 정상적으로 송수신된다.
- e0/1 장애는 VLAN Sub Interface 전체가 Down되므로 HSRP Hello Packet 자체가 송수신되지 않는다.
- 따라서 GW1은 **Init**, GW2는 **Standby unknown** 상태를 출력한다.
- HSRP는 **Tracking 대상 인터페이스**와 **HSRP가 실제 동작하는 인터페이스**를 구분하여 이해해야 한다.

---

# 배운 점

이번 실습을 통해 단순히 HSRP의 Active/Standby 전환뿐 아니라,

- Tracking의 동작 원리
- Priority 감소 과정
- HSRP Hello Packet의 역할
- Init / Standby / Active 상태 변화
- Standby unknown이 출력되는 이유

까지 실제 장애 상황을 통해 확인할 수 있었다.