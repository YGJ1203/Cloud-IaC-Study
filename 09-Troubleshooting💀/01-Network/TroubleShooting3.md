# Troubleshooting (NAT ~ VLAN/STP)

> 실제 Cisco Packet Tracer, EVE-NG, VMware 실습을 진행하면서 발생했던 문제와 해결 과정을 기록하였다.

---

# 1. NAT 설정 후 외부망 통신 불가

## 증상

- 내부 PC → Gateway Ping 성공
- 외부 네트워크 Ping 실패
- NAT Translation 생성되지 않음

## 원인

NAT Inside / Outside 인터페이스를 지정하지 않았거나 ACL이 내부 네트워크를 허용하지 않았다.

## 해결

### ACL 확인

```cisco
access-list 10 permit 10.1.0.0 0.0.255.255
```

### Inside / Outside 지정

```cisco
interface e0/0
 ip nat inside

interface e0/1
 ip nat outside
```

## 배운 점

NAT는

- ACL
- Inside
- Outside

세 가지가 모두 올바르게 설정되어야 정상 동작한다.

---

# 2. Default Route 누락

## 증상

NAT는 정상인데 인터넷 통신이 되지 않았다.

## 원인

Default Route가 존재하지 않았다.

## 해결

```cisco
ip route 0.0.0.0 0.0.0.0 192.168.2.254
```

## 배운 점

NAT는 주소만 변환한다.

패킷이 어디로 갈지는 Routing Table이 결정한다.

---

# 3. ACL 번호를 특별한 번호라고 착각

## 증상

ACL 번호 10만 사용할 수 있는 줄 알았다.

## 원인

ACL 번호의 의미를 잘못 이해하였다.

## 해결

```cisco
access-list 10 permit ...
access-list 15 permit ...
access-list 99 permit ...
```

모두 사용 가능하다.

## 배운 점

ACL 번호는 단순한 식별 번호이다.

---

# 4. Trunk 초기화를 Access Mode로만 수행

## 증상

Trunk를 제거할 때마다

```cisco
switchport mode access
```

를 반복하였다.

## 원인

Dynamic Trunk(DTP)를 이해하지 못하였다.

## 해결

상대 포트 설정과 Operational Mode를 함께 확인하였다.

## 배운 점

Trunk 상태는 상대 장비의 설정에도 영향을 받는다.

---

# 5. n-802.1q 의미를 잘못 이해

## 증상

show interface trunk 출력에서

```
n-802.1q
```

를

```
non-802.1q
```

라고 착각하였다.

## 원인

n이 Negotiated라는 사실을 몰랐다.

## 해결

Negotiated Dot1Q 상태라는 것을 이해하였다.

## 배운 점

Cisco show 명령의 약어도 정확하게 알아야 한다.

---

# 6. 잘못 생성한 Subinterface 삭제

## 증상

실수로

```cisco
interface Ethernet0/0.1
```

를 생성하였다.

## 해결

```cisco
no interface Ethernet0/0.1
```

## 배운 점

Subinterface는 Global Configuration Mode에서 삭제한다.

---

# 7. EVE-NG 종료 방법

## 증상

VMware에서 Power Off를 눌러도 되는지 고민하였다.

## 해결

가능하면

```
Shut Down Guest
```

를 사용하였다.

## 배운 점

실제 서버처럼 정상 종료하는 습관이 중요하다.

---

# 8. EtherChannel 잘못 구성

## 증상

잘못된 인터페이스에

```cisco
channel-group 3 mode active
```

를 입력하였다.

## 해결

```cisco
interface e3/0

no channel-group
```

필요하면

```cisco
no interface port-channel 3
```

도 수행하였다.

## 배운 점

EtherChannel은 양쪽 장비 설정이 반드시 동일해야 한다.

---

# 9. PortFast 적용 위치 혼동

## 증상

모든 포트에 PortFast를 적용하려고 하였다.

## 원인

Trunk Port에도 사용하는 것으로 착각하였다.

## 해결

PC가 연결되는 Access Port에만 적용하였다.

```cisco
spanning-tree portfast
```

(실습 조건상 Gateway 연결 포트는 예외)

## 배운 점

실무에서는 Access Port에만 사용하는 것이 일반적이다.

---

# 10. VTP 동기화 실패

## 증상

SW2~SW4에서 VLAN이 생성되지 않았다.

## 원인

확인 결과

- Trunk 미구성
- Domain 불일치
- Password 불일치
- Transparent Mode

였다.

## 해결

모든 스위치의 설정을 동일하게 수정하였다.

## 배운 점

VTP 확인 순서

1. Trunk
2. Domain
3. Password
4. Version
5. Mode(Server / Client)

---

# 11. Trunk가 올라오지 않음

## 증상

Trunk Interface가 Access 상태였다.

## 원인

한쪽 장비만 Trunk였다.

## 해결

양쪽 모두

```cisco
switchport mode trunk
```

설정하였다.

## 배운 점

Trunk는 양방향 설정이다.

---

# 12. 첫 Ping만 Timeout 발생

## 증상

첫 Ping만 실패하고 이후에는 정상 통신하였다.

## 원인

ARP Cache가 아직 생성되지 않았다.

## 해결

정상적인 ARP 학습 과정임을 확인하였다.

## 배운 점

첫 Ping Timeout은 대부분 ARP 때문이다.

---

# 최종 체크리스트

실습 중 문제가 발생하면 아래 순서대로 확인한다.

- Interface 상태 (up / down)
- IP 주소
- Default Gateway
- Routing Table
- Default Route
- NAT Inside / Outside
- ACL
- Trunk
- VLAN
- EtherChannel
- STP
- VTP
- ARP 여부
- Ping / Traceroute

---

# 느낀 점

이번 NAT 이후 실습부터는 단순히 명령어를 외우는 것이 아니라,

**패킷이 어디에서 어디까지 이동하는지를 추적하는 사고 방식**이 훨씬 중요하다는 것을 느꼈다.

명령어 암기보다

> "패킷이 지금 어디에서 막히고 있는가?"

를 찾는 것이 트러블슈팅의 핵심이라는 점을 배웠다.