# Router-on-a-Stick (Inter-VLAN Routing) 실습

## 실습 목표

- VLAN 생성
- Access Port 설정
- Trunk 설정
- Router-on-a-Stick 구성
- VLAN 간 통신 확인

---

# 네트워크 구성

Router (R1)
│
│ Fa0/0
│
SW1 (Core Switch)
├── SW2 (VLAN11)
├── SW3 (VLAN12)
├── ...
└── SW15 (VLAN24)

각 Access Switch에는 PC가 연결되어 있으며,
Router가 각 VLAN의 Default Gateway 역할을 수행한다.

---

# 1. VLAN 생성

각 Access Switch에서 VLAN 생성

예시

```cisco
vlan 11
name VLAN_A
```

VLAN 번호

| VLAN | 네트워크 |
|-------|----------|
|11|172.16.11.0/24|
|12|172.16.12.0/24|
|...|...|
|24|172.16.24.0/24|

---

# 2. Access Port 설정

예시 (SW2)

```cisco
interface fa0/1
switchport mode access
switchport access vlan 11

interface fa0/2
switchport mode access
switchport access vlan 11
```

확인

```cisco
show vlan brief
```

결과

```
11 VLAN_A active Fa0/1 Fa0/2
```

---

# 3. Trunk 설정

## Access Switch

```cisco
interface fa0/3
switchport trunk encapsulation dot1q
switchport mode trunk
```

---

## SW1

```cisco
interface range fa0/2-15
switchport trunk encapsulation dot1q
switchport mode trunk
```

라우터 연결 포트

```cisco
interface fa0/1
switchport trunk encapsulation dot1q
switchport mode trunk
```

확인

```cisco
show interfaces trunk
```

---

# 4. Router-on-a-Stick

먼저 인터페이스 활성화

```cisco
interface fa0/0
no shutdown
```

---

## Sub Interface

예시

```cisco
interface fa0/0.11
encapsulation dot1Q 11
ip address 172.16.11.254 255.255.255.0

interface fa0/0.12
encapsulation dot1Q 12
ip address 172.16.12.254 255.255.255.0

...

interface fa0/0.24
encapsulation dot1Q 24
ip address 172.16.24.254 255.255.255.0
```

확인

```cisco
show ip interface brief
```

결과

```
Fa0/0.11 up/up
Fa0/0.12 up/up
...
Fa0/0.24 up/up
```

---

# 5. PC 설정

예시 (PC1)

```
IP Address
172.16.11.1

Subnet Mask
255.255.255.0

Default Gateway
172.16.11.254
```

---

# 6. Ping 테스트

PC

```
ping 172.16.11.254
```

처음에는

```
Request timed out.
```

이 발생할 수 있다.

이후

```
Reply from ...
Reply from ...
Reply from ...
```

정상적으로 통신된다.

### 이유

첫 Ping에서는 ARP(Address Resolution Protocol)를 통해
Gateway의 MAC 주소를 학습하기 때문이다.

---

# 사용한 주요 명령어

## VLAN 확인

```cisco
show vlan brief
```

## Trunk 확인

```cisco
show interfaces trunk
```

## CDP 확인

```cisco
show cdp neighbors
```

## Interface 확인

```cisco
show ip interface brief
```

---

# 트러블슈팅

## 1. Access Switch 연결 순서 오류

### 문제

SW들의 연결 순서를 잘못 연결하여
토폴로지 확인이 어려웠다.

### 원인

케이블 연결 순서 실수

### 해결

CDP를 이용하여 연결 상태를 확인하고
케이블을 다시 연결하였다.

---

## 2. Router Interface Shutdown

### 문제

```
administratively down
```

### 원인

Router Interface가 shutdown 상태

### 해결

```cisco
interface fa0/0
no shutdown
```

---

## 3. Router Sub Interface를 Switch에서 생성

### 문제

Router-on-a-Stick 설정을
Switch에서 진행하려고 했다.

### 원인

L2 Switch와 Router의 역할을 혼동

### 해결

Sub Interface는 Router에서 생성해야 한다.

---

## 4. SW1 Router 연결 포트 Trunk 누락 (가장 오래 걸린 문제)

### 증상

Gateway Ping 실패

```
Request timed out.
```

### 원인

SW1의 Router 연결 포트(Fa0/1)가
Trunk가 아니었다.

기존 설정

```
Fa0/2 ~ Fa0/15
```

만 Trunk 설정되어 있었다.

Router와 연결된

```
Fa0/1
```

은 일반 Access Port 상태였다.

### 해결

```cisco
interface fa0/1
switchport trunk encapsulation dot1q
switchport mode trunk
```

확인

```cisco
show interfaces trunk
```

결과

```
Fa0/1 trunking
```

이후 Gateway Ping 성공.

---

# 이번 실습에서 배운 점

- Router-on-a-Stick의 원리
- Sub Interface 구성 방법
- VLAN과 Gateway의 관계
- Trunk의 중요성
- ARP 때문에 첫 Ping이 실패할 수 있다는 점
- 문제 발생 시 확인 순서

```
Physical
↓

CDP

↓

VLAN

↓

Trunk

↓

Router Interface

↓

Sub Interface

↓

Gateway

↓

Ping
```

---

# 회고

이번 실습은 단순한 Router-on-a-Stick 설정보다
트러블슈팅을 통해 더욱 많은 것을 배울 수 있었다.

특히 Router 연결 포트(Fa0/1)가 Trunk로 설정되지 않아
Gateway Ping이 실패했던 문제를 해결하면서

L2(VLAN/Trunk)와
L3(Router/Sub Interface)의 관계를
명확하게 이해할 수 있었다.

또한 문제 발생 시

- show cdp neighbors
- show vlan brief
- show interfaces trunk
- show ip interface brief

등의 확인 명령어를 이용하여
원인을 단계적으로 좁혀가는 과정이
가장 중요한 학습 포인트였다.