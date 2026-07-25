# Packet Tracer & GitHub Troubleshooting Part 2 💀

> 기존 트러블슈팅 모음 이후 추가로 경험한 GitHub, OSPF, Static Routing, EIGRP, ACL 관련 문제를 정리한 문서입니다.

## 목차

1. [GitHub에 커밋했지만 잔디가 심어지지 않는 문제](#1-github에-커밋했지만-잔디가-심어지지-않는-문제)
2. [OSPF network 명령에 이웃 라우터의 주소를 입력한 문제](#2-ospf-network-명령에-이웃-라우터의-주소를-입력한-문제)
3. [잘못 설정한 OSPF를 삭제하고 다시 구성하는 방법](#3-잘못-설정한-ospf를-삭제하고-다시-구성하는-방법)
4. [정적 경로에서 목적지 또는 Return Route를 누락한 문제](#4-정적-경로에서-목적지-또는-return-route를-누락한-문제)
5. [passive-interface의 적용 대상을 혼동한 문제](#5-passive-interface의-적용-대상을-혼동한-문제)
6. [Standard ACL로 목적지 네트워크까지 구분하려고 한 문제](#6-standard-acl로-목적지-네트워크까지-구분하려고-한-문제)
7. [ICMP 전체를 차단하여 정상적인 Ping 응답까지 막는 문제](#7-icmp-전체를-차단하여-정상적인-ping-응답까지-막는-문제)
8. [통합 점검 순서](#8-통합-점검-순서)

---

## 1. GitHub에 커밋했지만 잔디가 심어지지 않는 문제

### 증상

- 로컬에서 정상적으로 커밋했다.
- GitHub 원격 저장소로 `push`도 완료했다.
- 저장소에는 커밋이 표시되지만 Contribution Graph에는 잔디가 생기지 않았다.

### 원인

현재 컴퓨터의 Git `user.email`에 예전에 사용하던 다른 GitHub 계정의 이메일이 설정되어 있었다.

GitHub Contribution은 현재 로그인한 계정이 아니라 **각 커밋에 기록된 작성자 이메일**을 기준으로 계정과 연결된다.

### 점검 방법

```bash
git config --global user.name
git config --global user.email
git config --global --list
```

최근 커밋에 실제로 기록된 이름과 이메일은 다음 명령으로 확인한다.

```bash
git log --format="%h %an <%ae>"
```

특정 저장소에만 별도의 설정이 적용되었는지도 확인한다.

```bash
git config --local user.name
git config --local user.email
```

### 해결 방법

현재 GitHub 계정에 등록된 이메일로 변경한다.

```bash
git config --global user.name "GitHub 사용자 이름"
git config --global user.email "GitHub에 등록된 이메일"
```

설정 변경 후 다시 확인한다.

```bash
git config --global --list
```

> 설정을 변경해도 이미 생성된 과거 커밋의 작성자 정보는 자동으로 바뀌지 않는다. 이후 생성하는 커밋부터 새로운 이메일이 기록된다.

### 배운 점

- GitHub 잔디는 단순히 `push` 여부만으로 결정되지 않는다.
- 새로운 컴퓨터에서 Git을 사용하기 전 `user.name`과 `user.email`을 먼저 확인해야 한다.
- 여러 GitHub 계정을 사용했다면 전역 설정과 저장소별 설정을 함께 확인해야 한다.

---

## 2. OSPF `network` 명령에 이웃 라우터의 주소를 입력한 문제

### 증상

- 라우터 인터페이스는 `up/up` 상태였다.
- 그러나 OSPF Neighbor가 정상적으로 형성되지 않거나 OSPF 경로가 라우팅 테이블에 등록되지 않았다.

### 잘못 이해한 부분

OSPF 설정에서 자신의 주소가 아닌 이웃 라우터의 IP 주소를 `network` 명령에 입력했다.

```cisco
router ospf 1
 network <이웃 라우터 IP> <wildcard-mask> area 0
```

### 원인

OSPF의 `network` 명령은 이웃 라우터를 직접 등록하는 명령이 아니다.

이 명령은 **현재 라우터에서 어떤 인터페이스를 OSPF에 참여시킬지 선택**하고, 해당 인터페이스가 속한 네트워크를 광고하기 위해 사용한다.

```text
OSPF network 명령
→ 이웃 라우터의 주소 입력 X
→ 자신의 OSPF 참여 인터페이스를 찾을 수 있는 주소 범위 입력 O
```

### 점검 방법

```cisco
show ip interface brief
show ip protocols
show ip ospf interface brief
show ip ospf neighbor
show ip route ospf
```

먼저 `show ip interface brief`에서 자신의 인터페이스 주소를 확인한 후, 해당 주소가 `network` 명령의 주소와 와일드카드 마스크 범위에 포함되는지 확인한다.

### 해결 예시

R1의 인터페이스가 다음과 같다고 가정한다.

```text
FastEthernet0/0  13.13.12.1/24
Loopback1        13.13.13.1/24
```

OSPF 설정 예시는 다음과 같다.

```cisco
conf t
router ospf 1
 network 13.13.12.0 0.0.0.255 area 0
 network 13.13.13.0 0.0.0.255 area 0
end
```

정확한 인터페이스 주소만 지정하는 방식도 가능하다.

```cisco
conf t
router ospf 1
 network 13.13.12.1 0.0.0.0 area 0
 network 13.13.13.1 0.0.0.0 area 0
end
```

### 배운 점

- OSPF Neighbor는 `network` 명령에 이웃 IP를 직접 입력해서 만드는 것이 아니다.
- 자신의 인터페이스가 OSPF에 참여해야 Hello Packet을 전송하고 이웃 관계를 형성할 수 있다.
- OSPF 설정 전에는 반드시 자신의 인터페이스 IP부터 확인해야 한다.

---

## 3. 잘못 설정한 OSPF를 삭제하고 다시 구성하는 방법

### 상황

OSPF의 `network` 주소, 와일드카드 마스크, Area 또는 Process ID를 잘못 입력했을 때 기존 설정을 삭제해야 했다.

### 특정 `network` 명령만 삭제

한 줄만 잘못 입력했다면 전체 OSPF 프로세스를 삭제할 필요가 없다. 기존 명령 앞에 `no`를 붙여 해당 설정만 제거한다.

```cisco
conf t
router ospf 1
 no network <network-address> <wildcard-mask> area <area-id>
end
```

예시:

```cisco
conf t
router ospf 1
 no network 13.13.23.0 0.0.0.255 area 0
 network 13.13.12.0 0.0.0.255 area 0
end
```

### OSPF 프로세스 전체 삭제

설정 전체를 처음부터 다시 구성해야 한다면 다음과 같이 OSPF 프로세스를 삭제한다.

```cisco
conf t
no router ospf 1
end
```

이후 필요한 설정을 다시 입력한다.

```cisco
conf t
router ospf 1
 network <network-address> <wildcard-mask> area <area-id>
end
```

### 주의사항

- `no router ospf 1`은 Process ID가 `1`인 OSPF 설정 전체를 삭제한다.
- 한 줄만 틀렸다면 해당 명령만 삭제하는 편이 안전하다.
- 삭제 전 `show running-config | section router ospf`로 현재 설정을 확인한다.

### 재검증

```cisco
show running-config | section router ospf
show ip protocols
show ip ospf neighbor
show ip route ospf
```

### 배운 점

- 일부 설정 오류와 전체 프로세스 오류를 구분해야 한다.
- 설정을 무조건 처음부터 다시 입력하기보다 잘못된 한 줄을 정확하게 찾아 수정하는 습관이 중요하다.

---

## 4. 정적 경로에서 목적지 또는 Return Route를 누락한 문제

### 증상

- 자신의 게이트웨이 또는 인접 라우터까지는 Ping이 성공했다.
- 멀리 떨어진 최종 목적지 네트워크로는 `Request timed out`이 발생했다.
- 한쪽에서 시작한 Ping만 실패하거나 특정 구간까지만 통신되었다.

### 원인 후보

1. 목적지 네트워크로 가는 Static Route가 누락되었다.
2. `13.13.23.0/24`와 같은 라우터 사이 네트워크를 빠뜨렸다.
3. Next-Hop 주소 또는 Exit Interface를 잘못 지정했다.
4. 요청 패킷이 목적지까지 도착했지만 응답 패킷이 돌아올 Return Route가 없었다.

### 핵심 원리

Ping 통신에는 두 방향의 경로가 모두 필요하다.

```text
요청 경로: 출발지 → 목적지
응답 경로: 목적지 → 출발지
```

목적지까지 가는 경로만 설정되어 있어도 Ping은 실패할 수 있다.

### 점검 방법

```cisco
show ip interface brief
show ip route
show running-config | include ip route
```

PC와 라우터에서는 가까운 장비부터 한 단계씩 Ping한다.

```text
1. PC → 자신의 Default Gateway
2. 첫 번째 라우터 → 인접 라우터
3. 인접 라우터 → 다음 라우터
4. 마지막 라우터 → 목적지 PC
5. 목적지 측 → 출발지 방향으로 역방향 확인
```

### 설정 형식

Next-Hop 주소를 사용하는 경우:

```cisco
ip route <destination-network> <subnet-mask> <next-hop-ip>
```

Exit Interface를 사용하는 경우:

```cisco
ip route <destination-network> <subnet-mask> <exit-interface>
```

예시:

```cisco
conf t
ip route 13.13.30.0 255.255.255.0 13.13.23.3
end
```

반대편 라우터에도 출발지 네트워크로 돌아오는 경로가 있어야 한다.

```cisco
conf t
ip route 13.13.10.0 255.255.255.0 13.13.23.2
end
```

### 재검증

```cisco
show ip route
ping <next-hop-ip>
ping <destination-ip>
traceroute <destination-ip>
```

### 배운 점

- 마지막 성공 지점과 최초 실패 지점 사이에 원인이 있다.
- 한 라우터의 설정만 보고 끝내지 말고 목적지와 Return Route를 함께 확인해야 한다.
- Static Route의 목적지는 원격 네트워크이고 Next-Hop은 바로 다음 라우터의 주소다.

---

## 5. `passive-interface`의 적용 대상을 혼동한 문제

### 궁금했던 점

`passive-interface`를 어느 인터페이스에 적용해야 하는지, LAN 방향의 `G0/0`에 적용해도 되는지 혼동했다.

### 핵심 원리

`passive-interface`는 해당 인터페이스를 통해 라우팅 프로토콜의 Update 또는 Hello Packet이 전송되지 않도록 한다.

다만 해당 인터페이스의 연결 네트워크 자체가 라우팅 프로토콜에서 사라지는 것은 아니다. 네트워크는 다른 라우터에 계속 광고될 수 있다.

### 적용하기 적합한 인터페이스

- PC가 연결된 LAN
- 서버가 연결된 LAN
- 스위치만 연결되어 있고 라우팅 이웃이 없는 구간
- 라우팅 업데이트를 받을 필요가 없는 인터페이스

예시:

```cisco
conf t
router eigrp 100
 passive-interface g0/0
end
```

### 적용하면 안 되는 인터페이스

- 다른 EIGRP 라우터와 연결된 인터페이스
- OSPF Neighbor를 형성해야 하는 인터페이스
- RIP Update를 전달해야 하는 라우터 간 링크

라우터 간 연결 인터페이스를 Passive로 설정하면 이웃 관계 또는 라우팅 정보 교환이 중단될 수 있다.

### 점검 명령

```cisco
show ip protocols
show running-config | section router
show ip eigrp neighbors
show ip ospf neighbor
show ip route
```

### 배운 점

- `passive-interface`는 네트워크 광고 자체를 삭제하는 명령이 아니다.
- 핵심 판단 기준은 해당 인터페이스 너머에 라우팅 정보를 교환할 이웃 라우터가 있는지 여부다.
- `G0/0`이라는 인터페이스 이름만 보고 결정하지 말고 실제 연결 대상을 확인해야 한다.

---

## 6. Standard ACL로 목적지 네트워크까지 구분하려고 한 문제

### 요구사항

출발지가 `13.13.30.0/24`인 패킷만 `13.13.10.0/24` 네트워크에 접근하지 못하도록 차단하려고 했다.

처음 생각한 명령은 다음과 같았다.

```cisco
access-list 10 deny 13.13.30.0 0.0.0.255
```

### 실제 의미

Standard ACL은 출발지 IP 주소만 검사한다.

따라서 위 명령은 목적지가 `13.13.10.0/24`인지 확인하지 않고, ACL을 통과하는 패킷 중 출발지가 `13.13.30.0/24`인 모든 패킷을 거부한다.

### 추가 문제: Implicit Deny

ACL 마지막에는 보이지 않는 다음 명령이 존재한다.

```cisco
deny any
```

따라서 특정 출발지만 차단하고 나머지를 허용하려면 명시적인 허용문이 필요하다.

```cisco
access-list 10 deny 13.13.30.0 0.0.0.255
access-list 10 permit any
```

### 해결 방법 1: Standard ACL을 목적지 가까이에 배치

Standard ACL은 목적지를 직접 구분하지 못하므로 일반적으로 차단하려는 목적지 네트워크 가까이에 적용한다.

```cisco
conf t
access-list 10 deny 13.13.30.0 0.0.0.255
access-list 10 permit any
interface <13.13.10.0/24 방향 인터페이스>
 ip access-group 10 out
end
```

이렇게 배치하면 해당 인터페이스를 통해 `13.13.10.0/24`로 나가는 트래픽에만 ACL을 적용할 수 있다.

### 해결 방법 2: Extended ACL 사용

출발지와 목적지를 명령 자체에서 정확히 구분하려면 Extended ACL을 사용한다.

```cisco
conf t
access-list 110 deny ip 13.13.30.0 0.0.0.255 13.13.10.0 0.0.0.255
access-list 110 permit ip any any
end
```

Extended ACL은 일반적으로 차단할 출발지 가까이에 배치한다.

### 점검 명령

```cisco
show access-lists
show ip interface
show running-config | include access-group
```

### 배운 점

- Standard ACL은 출발지만 검사한다.
- Extended ACL은 출발지, 목적지, 프로토콜과 포트까지 검사할 수 있다.
- ACL 명령 자체뿐 아니라 적용 인터페이스와 `in/out` 방향이 결과를 결정한다.
- 마지막의 Implicit Deny를 항상 고려해야 한다.

---

## 7. ICMP 전체를 차단하여 정상적인 Ping 응답까지 막는 문제

### 요구사항

- `13.13.20.0/24`, `13.13.30.0/24`만 `13.13.10.100` 서버의 Web과 FTP에 접근할 수 있어야 한다.
- 외부에서 `13.13.10.100`으로 보내는 Ping 요청은 차단해야 한다.
- 그러나 `13.13.10.100` 서버는 `13.13.20.0/24`, `13.13.30.0/24`로 Ping할 수 있어야 한다.

### 혼동한 부분

다음과 같이 서버로 향하는 ICMP 전체를 차단하면 요구사항을 만족할 것처럼 보였다.

```cisco
access-list 120 deny icmp any host 13.13.10.100
```

그러나 ICMP 전체를 차단하면 외부 PC의 Ping 요청뿐 아니라 서버가 먼저 보낸 Ping에 대한 응답도 차단될 수 있다.

### 핵심 원리

Ping은 ICMP의 서로 다른 메시지 타입을 사용한다.

```text
echo       = Ping 요청
echo-reply = Ping 응답
```

서버로 들어오는 `echo`는 차단하되 서버가 보낸 요청에 대한 `echo-reply`는 허용해야 한다.

### ACL 구성 예시

다음 예시는 ACL이 서버 방향으로 이동하는 패킷을 검사하도록 배치되었다는 가정의 논리 예시다. 실제 적용 인터페이스와 방향은 토폴로지에 맞게 결정해야 한다.

```cisco
conf t
access-list 120 permit tcp 13.13.20.0 0.0.0.255 host 13.13.10.100 eq 80
access-list 120 permit tcp 13.13.20.0 0.0.0.255 host 13.13.10.100 eq 443
access-list 120 permit tcp 13.13.20.0 0.0.0.255 host 13.13.10.100 range 20 21

access-list 120 permit tcp 13.13.30.0 0.0.0.255 host 13.13.10.100 eq 80
access-list 120 permit tcp 13.13.30.0 0.0.0.255 host 13.13.10.100 eq 443
access-list 120 permit tcp 13.13.30.0 0.0.0.255 host 13.13.10.100 range 20 21

access-list 120 permit icmp 13.13.20.0 0.0.0.255 host 13.13.10.100 echo-reply
access-list 120 permit icmp 13.13.30.0 0.0.0.255 host 13.13.10.100 echo-reply
access-list 120 deny icmp any host 13.13.10.100 echo
access-list 120 permit ip any any
end
```

> FTP는 제어 연결과 데이터 연결을 사용하므로 실습 장비와 동작 모드에 따라 필요한 포트가 달라질 수 있다. 위 예시는 문제에서 제시된 TCP 20~21번 범위를 따른다.

### 적용 방향 확인

```cisco
interface <ACL 적용 인터페이스>
 ip access-group 120 in
```

또는 토폴로지에 따라 다음처럼 적용할 수도 있다.

```cisco
interface <ACL 적용 인터페이스>
 ip access-group 120 out
```

`in/out`은 라우터 전체가 아니라 **해당 인터페이스를 기준**으로 판단한다.

```text
in  = 패킷이 해당 인터페이스를 통해 라우터 내부로 들어옴
out = 패킷이 라우터에서 해당 인터페이스를 통해 나감
```

### 점검 및 재검증

```cisco
show access-lists
show ip interface
show running-config | include access-group
```

다음 통신을 각각 테스트한다.

1. 허용된 PC → 서버 HTTP/HTTPS
2. 허용된 PC → 서버 FTP
3. 외부 PC → 서버 Ping: 실패해야 정상
4. 서버 → 허용된 PC Ping: 성공해야 정상
5. 허용 대상이 아닌 PC → 서버 Web/FTP: 실패해야 정상

### 배운 점

- ICMP를 하나의 기능으로만 생각하지 말고 메시지 타입을 구분해야 한다.
- Ping 요청을 막는 것과 Ping 응답을 막는 것은 서로 다른 정책이다.
- ACL은 위에서 아래로 검사하며 처음 일치한 항목에서 처리를 종료한다.
- ACL 정책과 적용 위치·방향을 하나의 세트로 분석해야 한다.

---

## 8. 통합 점검 순서

Packet Tracer에서 통신 장애가 발생하면 설정을 무작정 다시 입력하지 않고 다음 순서로 범위를 좁힌다.

### 1단계: 예상 경로 확인

```text
출발지 PC
→ Default Gateway
→ 중간 라우터
→ 목적지 라우터
→ 목적지 PC 또는 서버
→ Return Route
```

### 2단계: 인터페이스 상태 확인

```cisco
show ip interface brief
```

- IP 주소가 올바른가?
- `Status`와 `Protocol`이 모두 `up`인가?
- 필요한 인터페이스에 `no shutdown`이 적용되었는가?

### 3단계: 라우팅 확인

```cisco
show ip route
show ip protocols
show running-config
```

- 목적지 네트워크가 라우팅 테이블에 있는가?
- Next-Hop이 실제 인접 라우터인가?
- Return Route가 존재하는가?
- OSPF/EIGRP/RIP의 `network`와 `passive-interface`가 올바른가?

### 4단계: 한 홉씩 Ping

가까운 대상부터 순서대로 Ping하여 마지막 성공 지점과 최초 실패 지점을 찾는다.

```cisco
ping <default-gateway>
ping <next-hop>
ping <remote-router>
ping <destination-host>
```

### 5단계: ACL 확인

```cisco
show access-lists
show ip interface
```

- Standard ACL과 Extended ACL 중 적절한 종류를 사용했는가?
- ACL 순서가 올바른가?
- `permit` 문이 빠져 Implicit Deny에 걸리지 않는가?
- 올바른 인터페이스와 방향에 적용했는가?
- ICMP `echo`와 `echo-reply`를 구분했는가?

### 6단계: 경로 추적

```cisco
traceroute <destination-ip>
```

PC에서는 다음 명령을 사용한다.

```text
tracert <destination-ip>
```

### 7단계: 수정 후 재검증

설정 변경 후 같은 테스트를 다시 수행하고 다음 항목을 기록한다.

```text
증상 → 관찰 결과 → 원인 → 수정 명령 → 재검증 결과 → 배운 점
```

---

## 최종 정리

이번 트러블슈팅에서 공통적으로 확인한 핵심은 다음과 같다.

| 구분 | 핵심 내용 |
|---|---|
| GitHub | 커밋 이메일과 GitHub 계정 이메일이 연결되어야 한다. |
| OSPF | `network` 명령에는 이웃 IP가 아니라 자신의 참여 인터페이스 범위를 지정한다. |
| Static Route | 목적지 경로와 Return Route를 함께 확인한다. |
| Passive Interface | 라우팅 이웃이 없는 LAN 인터페이스에 적용한다. |
| Standard ACL | 출발지만 검사하므로 목적지 가까이에 배치한다. |
| Extended ACL | 출발지, 목적지, 프로토콜과 포트를 구분할 수 있다. |
| ICMP ACL | `echo`와 `echo-reply`를 구분하고 적용 방향을 확인한다. |

> **한 줄 결론:** 어디까지 통신되고 어디서 처음 끊기는지 확인한 뒤, 마지막 성공 지점과 최초 실패 지점 사이에서 원인을 찾는다.