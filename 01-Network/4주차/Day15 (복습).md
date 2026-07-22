# 📚 Routing Protocol Quiz

> Packet Tracer & 네트워크 기초 복습용

---

# Q1. Static Route(정적 경로)란?

### A.

관리자가 목적지까지의 경로를 직접 설정하는 방식이다.

- 장점
  - CPU 사용량이 적다.
  - 가장 단순하고 안정적이다.

- 단점
  - 장애 발생 시 자동으로 우회하지 못한다.
  - 네트워크가 커질수록 관리가 어렵다.

**핵심 키워드**
> 직접 입력 (Manual Routing)

---

# Q2. Static Route는 언제 사용하는가?

### A.

- 소규모 네트워크
- 기본 경로(Default Route)
- 방화벽 연결
- 인터넷 연결

실무에서도 매우 많이 사용된다.

---

# Q3. RIP의 라우팅 기준은?

### A.

Hop Count(거쳐가는 라우터 개수)

Hop 수가 가장 적은 경로를 선택한다.

---

# Q4. RIP의 최대 Hop 수는?

### A.

15 Hop

16 Hop은 목적지에 도달할 수 없는 네트워크로 판단한다.

---

# Q5. RIPv1의 단점은?

### A.

- VLSM 지원 불가
- Classful Routing
- 확장성이 낮다.
- 수렴 속도가 느리다.

---

# Q6. RIPv2에서 추가된 기능은?

### A.

- VLSM 지원
- CIDR 지원
- Multicast 사용
- 인증(Authentication)

즉, RIPv1의 업그레이드 버전이다.

---

# Q7. OSPF는 어떤 방식의 라우팅 프로토콜인가?

### A.

Link State Routing Protocol

라우터들이 네트워크 전체 정보를 공유하여 최적의 경로를 계산한다.

---

# Q8. OSPF에서 사용하는 알고리즘은?

### A.

SPF(Shortest Path First)

Dijkstra 알고리즘을 사용한다.

---

# Q9. OSPF의 Metric은?

### A.

Cost

Bandwidth를 기준으로 Cost를 계산한다.

---

# Q10. OSPF의 장점은?

### A.

- 수렴 속도가 빠르다.
- 대규모 네트워크에 적합하다.
- 장애 발생 시 빠르게 우회한다.
- 현재 가장 많이 사용되는 IGP 중 하나이다.

---

# Q11. EIGRP는 어떤 프로토콜인가?

### A.

Cisco에서 개발한 고성능 라우팅 프로토콜이다.

---

# Q12. EIGRP가 사용하는 알고리즘은?

### A.

DUAL(Diffusing Update Algorithm)

매우 빠른 수렴 속도를 제공한다.

---

# Q13. EIGRP의 Metric은?

### A.

다음 요소들을 종합하여 계산한다.

- Bandwidth
- Delay
- Reliability
- Load

(기본적으로는 Bandwidth + Delay를 가장 많이 사용)

---

# Q14. 실무에서 가장 많이 사용되는 라우팅 프로토콜은?

### A.

① OSPF ⭐⭐⭐⭐⭐

② Static Route ⭐⭐⭐⭐☆

③ EIGRP ⭐⭐⭐⭐☆

④ RIPv2 ⭐⭐☆☆☆

⑤ RIPv1 ⭐☆☆☆☆

---

# Q15. Packet Tracer 학습 순서는?

### A.

Static Route

↓

RIPv1

↓

RIPv2

↓

OSPF

↓

EIGRP

---

# 🔥 초압축 암기

| 프로토콜 | 핵심 키워드 |
|-----------|-------------|
| Static | 직접 입력 |
| RIP | Hop Count |
| RIPv2 | VLSM 지원 |
| OSPF | Link State + SPF + Cost |
| EIGRP | Cisco + DUAL + Bandwidth + Delay |

---

# 💀 시험 한 줄 암기

✔ Static → 직접 입력

✔ RIP → Hop Count

✔ RIPv2 → RIP + VLSM

✔ OSPF → Link State + Cost + Dijkstra

✔ EIGRP → Cisco + DUAL