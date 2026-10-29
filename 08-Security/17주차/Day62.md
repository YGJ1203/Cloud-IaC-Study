# 2026-10-29 네트워크 보안 방어 실습 총정리

> Cisco IOS ACL · Reflexive ACL · CBAC · Lock-and-Key · TCP Intercept · Rate Limiting · Port Security · DAI
>
> **기록 범위:** 사용자가 제공한 토폴로지와 Cisco 명령어 기준. Kali Linux 명령 로그 및 Wireshark 캡처는 이번 자료에 제공되지 않아 결과를 추정하지 않았습니다.

## 1. 학습 목표

1. 확장 ACL로 출발지/목적지 및 프로토콜 기반 통신 제어
2. 방화벽의 인바운드 정책과 상태 기반 반환 트래픽 허용
3. TCP SYN Flood 및 UDP 대량 트래픽 완화 기법 이해
4. 스위치 포트의 MAC 제한 및 ARP 위조 방어
5. `show` 명령, 통신 시험, 패킷 캡처를 이용한 정책 검증

## 2. 네트워크 토폴로지

```text
                     Internet (192.168.2.254)
                              |
                       ISP e0/0 .2.253
                              |
             ISP e0/1 192.168.100.254
                              |
                  Internet_Switch
                     |          |
     External Kali   |          | Cisco Firewall e0/0
     192.168.100.50  |          | 192.168.100.1
                                |
                       Firewall e0/1
                       192.168.20.100
                                |
                         Secure_Switch
                    /       |       |        \
      Internal Kali       CentOS   Win2008   Win7
      192.168.20.50      .20.200   .20.201   .20.202
```

| 구간 | 네트워크 | 역할 |
|---|---|---|
| 외부/DMZ 측 실습망 | 192.168.100.0/24 | 외부 Kali, 방화벽 외부 인터페이스 |
| 내부 실습망 | 192.168.20.0/24 | 서버, 내부 Kali, 보안 스위치 |
| 상위 ISP 구간 | 192.168.2.0/24 | 인터넷 연결 실습 |

- 방화벽 `e0/0`: 외부 방향, `192.168.100.1`
- 방화벽 `e0/1`: 내부 방향, `192.168.20.100`
- `in`/`out`은 **장비 인터페이스 기준**이다. `e0/1 in`은 내부에서 방화벽으로 들어오는 패킷, `e0/0 in`은 외부에서 방화벽으로 들어오는 패킷이다.

## 3. 5-튜플(5-Tuple)

| 요소 | 의미 | 예시 |
|---|---|---|
| 출발지 IP | 송신 호스트 | 192.168.20.50 |
| 목적지 IP | 수신 호스트 | 192.168.20.200 |
| 프로토콜 | TCP / UDP / ICMP 등 | TCP |
| 출발지 포트 | 송신 프로세스 포트 | 49152 |
| 목적지 포트 | 서비스 포트 | 80 |

TCP/UDP 흐름 구분에 주로 사용하는 다섯 값이다. ICMP는 TCP/UDP 포트가 없으므로 유형/코드 등 다른 필드로 구분한다. 확장 ACL의 `permit ip`/`deny ip`는 포트 조건 없이 IP 프로토콜 전체에 적용한다.

## 4. 확장 ACL: 특정 외부 목적지 차단

### 실습 입력의 비식별화 버전

```cisco
conf t
ip access-list extended In-Filter
 deny ip 192.168.20.0 0.0.0.255 host BLOCKED_IP_1 log-input
 deny ip 192.168.20.0 0.0.0.255 host BLOCKED_IP_2 log-input
 deny ip 192.168.20.0 0.0.0.255 host BLOCKED_IP_3 log-input
 deny ip 192.168.20.0 0.0.0.255 host BLOCKED_IP_4 log-input
 500 permit ip any any
!
interface e0/1
 ip access-group In-Filter in
end
```

- `192.168.20.0 0.0.0.255`: 내부 /24 대역의 와일드카드 마스크
- `host`: 목적지 단일 IP 지정
- `log-input`: 일치한 패킷의 로깅(플랫폼별 지원 및 출력 차이 확인)
- `500 permit ip any any`: 앞선 차단 조건 이외의 IP 통신 허용. ACL은 기본적으로 끝에 암묵적 `deny`가 있다.
- **주의:** `BLOCKED_IP_n`은 비식별화 토큰. 실습 환경에서 유효한 테스트 주소로 치환해야 실행된다.
- CDN/공유 호스팅 IP를 통째로 차단하면 무관한 정상 서비스까지 차단할 수 있다. DNS 기반 필터링, 프록시 정책 등과 비교한다.

### 검증

```cisco
show ip access-lists In-Filter
show ip interface e0/1
show logging
```

차단 대상과 허용 대상의 통신을 각각 테스트하고 ACL hit count 및 로그를 확인한다. 차단/허용 성공은 **실측 결과가 제공되지 않아 미확인**이다.

## 5. 기본 인바운드 방화벽 ACL (In-FW)

### 초기 전면 차단

```cisco
conf t
ip access-list extended In-FW
 100 deny ip any any
!
interface e0/0
 ip access-group In-FW in
end
```

외부에서 들어오는 트래픽을 기본 차단한다. 이후 허용 규칙을 추가할 때는 **ACL 시퀀스 순서**를 반드시 확인한다.

### 서버별 필요한 서비스 허용

```cisco
conf t
ip access-list extended In-FW
 10 permit tcp any host 192.168.20.200 eq 80
 20 permit tcp any host 192.168.20.200 eq 443
 30 permit udp any host 192.168.20.200 eq 53
end
```

- TCP 80: HTTP, TCP 443: HTTPS, UDP 53: DNS
- DNS는 TCP 53도 사용하므로 실제 DNS 서비스 정책에는 필요 여부를 별도로 판단한다.
- `100 deny ip any any`가 뒤에 남아 있다면, 허용 규칙과 다른 트래픽은 차단된다.
- 외부에서 내부 서버로 실제 접근하려면 **라우팅/NAT/서버 서비스/호스트 방화벽** 조건도 충족해야 한다.

## 6. Reflexive ACL: 요청에 대한 응답 허용

```cisco
conf t
ip access-list extended Out-FW
 permit tcp 192.168.20.0 0.0.0.255 any reflect RACL
 permit udp 192.168.20.0 0.0.0.255 any reflect RACL
 permit icmp 192.168.20.0 0.0.0.255 any reflect RACL
!
ip access-list extended In-FW
 40 evaluate RACL
!
interface e0/0
 ip access-group Out-FW out
end
```

- `reflect RACL`: 해당 트래픽에 대한 임시 반사 ACL 항목 생성
- `evaluate RACL`: 외부에서 들어오는 반환 패킷을 임시 항목과 대조
- 외부 인터페이스 `e0/0 out`에 내부발 트래픽이 나갈 때 반사 항목을 만들고, `e0/0 in`에서 반환을 검사하는 구조
- **중요한 순서 문제:** `In-FW`에 `100 deny ip any any`가 존재하고 `40 evaluate RACL`이 앞에 있다면 순서는 적절하다. 반대로 차단이 먼저 나오면 반환 트래픽이 막힌다.

### 프로토콜 전체 허용 형태로 수정한 실습

```cisco
conf t
no ip access-list extended Out-FW
ip access-list extended Out-FW
 permit ip 192.168.20.0 0.0.0.255 any reflect RACL
end
```

`permit ip ... reflect`는 플랫폼/IOS 이미지에 따라 지원 및 반사 동작이 다를 수 있다. TCP/UDP/ICMP별 규칙과 동일하다고 가정하지 말고 CLI 수락 여부 및 반환 트래픽을 검증한다.

### 정리 명령에서 확인할 점

```cisco
conf t
no ip access-list extended Out-FW
!
ip access-list extended Out-FW
 no 40
!
interface e0/0
 no ip access-group Out-FW out
end
```

**원본 기록의 `no 40`은 `Out-FW` 아래에서 실행하도록 적혀 있으나, 앞서 `40 evaluate RACL`은 `In-FW`에 추가했다.** 따라서 의도가 `evaluate` 제거라면 다음과 같이 해당 ACL에서 삭제해야 한다.

```cisco
conf t
ip access-list extended In-FW
 no 40
end
```

이미 `Out-FW`를 삭제했다면 `Out-FW`를 다시 만들 필요가 없다. 변경 후 `show run`으로 잔여 정책을 확인한다.

## 7. CBAC (Context-Based Access Control)

```cisco
conf t
ip inspect name CBAC tcp
ip inspect name CBAC udp
ip inspect name CBAC icmp
!
interface e0/0
 ip inspect CBAC out
end
show run
```

- CBAC는 트래픽의 상태를 검사하고 반환 트래픽을 위한 임시 허용을 관리하는 구형 IOS 상태 기반 방화벽 기능이다.
- `e0/0 out` 방향의 내부발 통신을 검사하는 구도이다.
- Reflexive ACL과 기능상 겹치는 부분이 있어 **전환 실습 시 기존 반사 ACL을 정리**하고 비교한다.
- 최신 운영 환경에서는 Zone-Based Policy Firewall(ZBFW), NGFW 등과 구별해 이해한다.

## 8. Lock-and-Key (동적 ACL)

```cisco
conf t
username admin password cisco
username admin autocommand access-enable host timeout 10
!
line vty 0 4
 login local
!
ip access-list extended In-FW
 40 permit tcp any host 192.168.100.1 eq 23
 50 dynamic NAC permit ip any host 192.168.20.200 0.0.0.255
end
```

**목적:** 사용자가 인증한 뒤 제한된 시간 동안 동적 ACL 허용 항목을 활성화하는 레거시 기능.

**실습 주의사항**

1. `username admin password cisco`는 평문/취약 비밀번호를 사용하는 **교재형 실습 설정**이다. 실제 운영에는 적용하지 않는다.
2. TCP 23은 Telnet이며 암호화되지 않는다. 실습 격리망에서만 사용하고 운영 환경에서는 SSH/AAA 기반 접근 제어를 권장한다.
3. `host 192.168.20.200 0.0.0.255`는 단일 호스트와 와일드카드 마스크를 혼용한 표기로 **IOS 문법 오류 가능성**이 있다. 단일 서버라면 `host 192.168.20.200`, 전체 /24라면 `192.168.20.0 0.0.0.255`를 의도에 맞게 선택한다.
4. 동적 ACL의 시퀀스와 기존 `In-FW`의 `40 evaluate RACL`은 **충돌할 수 있다**. 같은 ACL에 동시 추가할 때 기존 시퀀스를 확인해야 한다.
5. 동적 ACL은 IOS 플랫폼별 제약이 있으므로 `?`, `show ip access-lists`로 검증한다.

## 9. Fragment Filtering

```cisco
conf t
ip access-list extended In-FW
 5 deny ip any host 192.168.20.200 fragments
end
```

- `fragments`는 비초기(non-initial) IP 조각에 대한 ACL 조건이다.
- 첫 조각과 비초기 조각은 포함하는 헤더가 다르므로 ACL 동작을 구분해야 한다.
- 모든 IP 단편화 공격을 차단하는 만능 기능은 아니다. 정상 조각 트래픽도 영향을 받을 수 있다.

## 10. TCP Intercept: SYN Flood 완화

```cisco
conf t
access-list 110 permit tcp any 192.168.20.0 0.0.0.255
!
ip tcp intercept list 110
ip tcp intercept mode intercept
ip tcp intercept connection-timeout 30
end
```

- `access-list 110`: 보호할 TCP 트래픽 범위 정의
- `mode intercept`: 라우터가 TCP 연결 수립 과정을 중개하여 비정상적인 연결 시도를 완화하는 레거시 기능
- `connection-timeout 30`: 해당 기능의 연결 타임아웃 설정(정확한 적용 단계는 IOS 버전별 명령 도움말 확인)
- 실제 운영에서는 SYN cookies, 방화벽 세션 보호, DDoS 방어 및 모니터링을 함께 고려한다.

## 11. UDP Rate Limiting

```cisco
conf t
access-list 120 permit udp any 192.168.20.0 0.0.0.255
!
interface e0/0
 rate-limit input access-group 120 8000 1500 2000 conform-action transmit exceed-action drop
end
```

| 값 | 의미 |
|---|---|
| `input` | 외부 인터페이스로 유입되는 패킷 |
| `access-group 120` | ACL 120에 매칭되는 UDP 트래픽 |
| `8000` | 평균 속도 8,000 bits/sec |
| `1500` | 정상 버스트 크기(바이트) |
| `2000` | 최대 버스트 크기(바이트) |
| `conform-action transmit` | 기준 내 트래픽 전달 |
| `exceed-action drop` | 기준 초과 트래픽 폐기 |

> 8 kbps는 실습용으로도 매우 낮은 값이다. 실제 UDP 서비스의 정상 트래픽이 차단될 수 있으므로 패킷 손실과 서비스 영향 측정이 필요하다. IOS 이미지의 레거시 `rate-limit` 지원 여부도 확인한다.

## 12. Switch Port Security

```cisco
conf t
interface e1/0
 shutdown
 switchport mode access
 switchport port-security
 switchport port-security maximum 2
 switchport port-security mac-address 000c.29b0.67ba
 switchport port-security mac-address 0050.56C0.0003
 switchport port-security violation shutdown
 no shutdown
end
```

- 액세스 포트에 최대 2개 MAC 주소 허용
- 허용 목록에 없는 MAC 주소가 감지되면 `shutdown` 위반 모드로 포트를 오류 비활성화할 수 있음
- 포트 보안은 MAC 기반 접근 제한이며 MAC Spoofing을 완전히 방지하는 인증 기능은 아니다.

검증:

```cisco
show port-security
show port-security interface e1/0
show interfaces status
```

## 13. Dynamic ARP Inspection (DAI)

```cisco
conf t
ip arp inspection vlan 1
!
arp access-list STATIC
 permit ip host 192.168.20.50 mac host 000c.29b0.67ba
 permit ip host 192.168.20.100 mac host aabb.cc00.2001
 permit ip host 192.168.20.200 mac host 000C.2914.3BA5
 permit ip host 192.168.20.201 mac host 000C.29F1.F27E
!
ip arp inspection filter STATIC vlan 1
!
interface e1/0
 ip arp inspection limit none
end
```

- DAI는 ARP 패킷의 IP/MAC 매핑을 검증해 ARP Spoofing을 완화한다.
- 정적 ARP ACL에 내부 Kali, 방화벽, CentOS, Windows Server의 IP/MAC 쌍이 등록되어 있다.
- **중요:** `ip arp inspection filter STATIC vlan 1`만 사용할 경우 플랫폼에 따라 ACL에 매칭되지 않는 ARP가 DHCP Snooping 바인딩을 통해 검사될 수 있다. 정적 ACL만으로 미등록 ARP를 거부하려는 의도라면 지원 플랫폼에서 `static` 옵션 여부를 확인한다.
- `ip arp inspection limit none`은 해당 포트의 ARP 검사 속도 제한을 해제하는 설정이다. DAI 검증 자체를 비활성화한다는 뜻은 아니다.
- 신뢰(`trust`)/비신뢰 포트, DHCP Snooping 연계, 스위치의 기능 지원 여부를 점검한다.

검증:

```cisco
show ip arp inspection
show ip arp inspection vlan 1
show ip arp inspection statistics
show arp access-list
```

## 14. 공격과 방어 연결

| 공격/위험 | 오늘 다룬 방어 | 한계 및 추가 고려 |
|---|---|---|
| 불필요한 외부 서비스 접근 | Extended ACL | NAT/라우팅/호스트 방화벽과 함께 확인 |
| 외부의 무단 신규 연결 | In-FW | 허용 서비스만 열고 기본 거부 |
| 내부 요청의 응답 차단 문제 | Reflexive ACL / CBAC | 상태 관리 방식이 서로 다름 |
| SYN Flood | TCP Intercept | 장비 자원 고갈 및 대규모 DDoS에는 추가 방어 필요 |
| UDP Flood | Rate Limiting | 정상 UDP 서비스도 제한 가능 |
| 허가되지 않은 MAC 사용 | Port Security | MAC 위조 자체를 근본적으로 차단하지 못함 |
| ARP Spoofing | DAI | 정확한 바인딩/신뢰 포트 설정 필요 |
| IP 조각 악용 | Fragment ACL | 정상 조각 통신과 구별 필요 |

## 15. 검증 체크리스트

- [ ] `show run`으로 ACL/CBAC/인터페이스 적용 방향 확인
- [ ] `show ip access-lists`로 시퀀스 및 hit count 확인
- [ ] 외부에서 허용 서비스 HTTP/HTTPS/DNS 접근 여부 확인
- [ ] 외부에서 비허용 포트 접근 차단 여부 확인
- [ ] 내부에서 시작한 통신의 응답 수신 여부 확인
- [ ] Reflexive ACL 또는 CBAC 중 현재 적용 방식 확인
- [ ] TCP Intercept 적용 전후 TCP 연결 관측
- [ ] UDP Rate Limiting 전후 손실/속도 비교
- [ ] Port Security 허용/미허용 MAC 시험 및 위반 상태 확인
- [ ] DAI에서 정상/위조 ARP 처리 차이 확인
- [ ] Wireshark에서 TCP SYN/SYN-ACK/ACK, ARP, UDP, ICMP 확인
- [ ] 테스트 종료 후 의도치 않은 잔여 ACL/설정 정리

> 위 체크리스트는 **권장 검증 항목**이지, 이번에 성공했다고 확인된 결과가 아니다.

## 16. 면접 예상 질문 & 답변

**Q1. Standard ACL과 Extended ACL의 차이는?**  
A. Standard ACL은 주로 출발지 IPv4 주소 기준으로 필터링하고, Extended ACL은 출발지·목적지 IP, 프로토콜, TCP/UDP 포트 등 세부 조건을 사용할 수 있다.

**Q2. `in`과 `out`은 어떻게 판단하나요?**  
A. 사용자 관점이 아닌 해당 네트워크 장비의 **인터페이스 기준**이다. 장비로 들어오면 `in`, 장비에서 나가면 `out`이다.

**Q3. ACL에 허용 규칙이 있어도 접속이 안 되는 이유는?**  
A. 시퀀스 순서, 암묵적 거부, NAT, 왕복 라우팅, 서버 리스닝 상태, 호스트 방화벽, 인터페이스 방향 등을 점검한다.

**Q4. Reflexive ACL과 CBAC의 차이는?**  
A. Reflexive ACL은 요청 트래픽을 바탕으로 임시 반환 허용 항목을 만들고, CBAC는 프로토콜별 세션 상태 검사 기능을 제공한다.

**Q5. TCP Intercept는 무엇을 방어하나요?**  
A. TCP 연결 수립 과정에서 발생하는 SYN Flood 유형의 자원 고갈 공격을 완화한다.

**Q6. Port Security와 DAI는 어떤 계층의 방어인가요?**  
A. 주로 스위치의 L2 보안 기능이다. Port Security는 포트의 MAC 허용 정책, DAI는 ARP IP/MAC 매핑 검증을 담당한다.

**Q7. DAI를 켜면 ARP Spoofing이 무조건 차단되나요?**  
A. 아니다. 신뢰 포트와 비신뢰 포트, DHCP Snooping 바인딩 또는 정적 ARP ACL, 스위치 기능 지원 여부가 올바르게 구성돼야 한다.

**Q8. IP 기반 차단의 부작용은?**  
A. IP 변경이나 CDN 공유 주소 때문에 차단 우회 또는 정상 사이트의 과잉 차단이 발생할 수 있다.

## 17. 핵심 암기 치트시트

```text
5-Tuple         = SRC IP + DST IP + Protocol + SRC Port + DST Port
Extended ACL    = IP/Protocol/Port 조건으로 접근 제어
Reflexive ACL   = reflect / evaluate
CBAC            = ip inspect name / ip inspect ... out
Lock-and-Key    = access-enable / dynamic ACL (레거시)
TCP Intercept   = SYN Flood 완화
Rate Limiting   = 트래픽 속도 제한
Port Security   = 포트별 허용 MAC 제한
DAI             = ARP IP-MAC 매핑 검증
ACL Direction   = 장비 인터페이스 기준 in/out
Implicit Deny   = ACL 끝의 기본 거부
```

## 18. 추후 보강할 증적

- Kali Linux: 실제 실행 명령어, 타깃/출발지, 패킷 송신 및 결과 로그
- Wireshark: 필터식, 캡처 화면, 공격 전후 패킷 비교
- EVE-NG: `show run`, ACL hit count, Port Security/DAI 상태 출력
- 모든 공개 자료에서 실제 불법 사이트 도메인과 관련 공인 IP는 `***` 또는 `BLOCKED_IP_n`으로 마스킹

---

**한 줄 정리:** 오늘은 공격 패킷을 이해하는 수준에서 나아가, Cisco IOS 방화벽과 스위치의 L3/L4 접근 제어·상태 추적·L2 보안 정책을 직접 구성하는 실습이었다.
