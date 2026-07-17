1. 기본 설정

2. 정적 경로 -> 삭제

3. RIPv2 -> 삭제

4. EIGRP 100 -> 삭제

5. OSPF Area 0 -> 삭제

@ R1
conf t
access-list 10 deny 13.13.30.0 0.0.0.255
access-list 10 permit any
!
int s1/0 
 ip access-group 10 in
 end

show run
show ip access-lists

1.출발지 '13.13.10.1'호스트가 웹 서버 '172.16.1.1'로 접근하는 것을 차단한다.
2.출발지 '13.13.10.0/24' 서브넷이 웹-서버 '172.16.1.1'로 접근하는 것은 허용한다.
3. 외부 사용자가 인터넷을 통하여 '172.16.1.1' 서버로 전송하는 ICMP 패킷을 차단한다.
4. 단, '172.16.1.1' 서버는 외부로 ping이 되어야한다.
5. 나머지 패킷들은 접근이 가능하도록 허용한다.

access-list 110 deny tcp host 13.13.10.1 host 172.16.1.1 eq 80
access-list 110 permit tcp 13.13.10.0 0.0.0.255 host 172.16.1.1 eq 80 // 마지막에 전체 허용이 있기 때문에 설정할 필요 X
access-list 110 deny icmp any host 172.16.1.1 echo
access-list 110 permit ip any any
!
int fa0/1
 ip access-group 110 out

ex9)
- 출발지 13.13.30.0/24인 패킷이 내부 로컬 네트워크 13.13.0.1로 Telnet 접속되는 것을 차단한다.
- 외부에서 내부 서버 13.13.10.100으로 ping 되는 것을 차단해라, 단 서버는 외부로 ping이 되어야 한다.
- 출발지 13.13.20.0/24 인 패킷이 내부 웹서버 13.13.10.100 으로 접근하는 것을 차단해라.
- 나머지 패킷은 허용한다.


access-list 110 deny tcp 13.13.30.0 0.0.0.255 host 13.13.10.1 eq 23
access-list 110 deny icmp any host 13.13.10.100 echo
access-list 110 deny tcp 13.13.20.0 0.0.0.255 host 13.13.10.100 eq 80
access-list 110 permit ip any any
!
int s1/0
 ip access-group 110 in

ip access-list extended 110
 no 30
 35 deny tcp 13.13.20.0 0.0.0.255 host 13.13.10.1 eq 23


=========================================================================================

# Cisco ACL (Access Control List) 핵심 정리

## 1. ACL 종류

| 종류 | 번호 | 특징 |
|------|------|------|
| Standard ACL | 1~99, 1300~1999 | 출발지(Source)만 검사 |
| Extended ACL | 100~199, 2000~2699 | 출발지, 목적지, 프로토콜, 포트까지 검사 |

---

# 2. Standard ACL

### 기본 문법

```cisco
access-list [번호] permit|deny [출발지] [Wildcard]
```

예시)

```cisco
access-list 10 deny 13.13.30.0 0.0.0.255
access-list 10 permit any
```

---

# 3. Extended ACL

### 기본 문법

```cisco
access-list [번호] permit|deny
protocol
source wildcard
destination wildcard
[port]
```

형태

```cisco
access-list 100 permit tcp source wildcard destination wildcard eq 80
```

---

# 4. 프로토콜 종류

| 프로토콜 | 의미 |
|-----------|------|
| ip | 모든 IP 트래픽 |
| tcp | TCP |
| udp | UDP |
| icmp | Ping |

예)

```cisco
deny ip
deny tcp
deny udp
deny icmp
```

---

# 5. host / any

특정 PC

```cisco
host 13.13.30.3
```

=

```cisco
13.13.30.3 0.0.0.0
```

모든 주소

```cisco
any
```

=

```cisco
0.0.0.0 255.255.255.255
```

---

# 6. 자주 사용하는 포트

| 서비스 | 포트 |
|---------|------|
| Telnet | 23 |
| FTP | 21 |
| HTTP | 80 |
| HTTPS | 443 |
| SSH | 22 |
| DNS | 53 |

예)

```cisco
eq telnet
eq ftp
eq www
eq 80
eq 443
```

---

# 7. ICMP

Ping 요청 차단

```cisco
deny icmp any host 13.13.30.3 echo
```

Ping 응답 차단

```cisco
deny icmp any host 13.13.30.3 echo-reply
```

---

# 8. ACL 적용

인터페이스에서 적용

```cisco
interface s1/0
 ip access-group 100 in
```

또는

```cisco
interface f0/0
 ip access-group 100 out
```

---

# 9. In / Out

```
패킷 → Router → 목적지

들어오면
IN

나가면
OUT
```

---

# 10. ACL 확인

ACL 확인

```cisco
show access-lists
```

인터페이스 확인

```cisco
show running-config
```

ACL 적용 여부

```cisco
show ip interface
```

---

# 11. ACL 삭제

ACL 삭제

```cisco
no access-list 100
```

인터페이스 해제

```cisco
interface s1/0
no ip access-group 100 in
```

---

# 12. ACL 작성 순서

① Source 확인

② Destination 확인

③ Protocol 확인

④ Port 확인

⑤ permit / deny 결정

---

# 13. 마지막 규칙

ACL 마지막에는 항상

```
implicit deny
```

가 숨어 있다.

따라서 대부분 마지막에

```cisco
permit ip any any
```

를 추가한다.

---

# 14. Extended ACL 권장 위치

가급적 **출발지(Source) 가까이** 배치

```
Source ----- ACL ----- Network ----- Destination
```

---

# 15. Standard ACL 권장 위치

가급적 **목적지(Destination) 가까이** 배치

```
Source ----- Network ----- ACL ----- Destination
```

---

# 16. 시험에서 가장 많이 나오는 명령어

```cisco
access-list
permit
deny
host
any
eq
ip
tcp
udp
icmp
echo
show access-lists
show ip interface
ip access-group
no access-list
permit ip any any
```

---

# ★ ACL 풀이 공식

문제를 보면 항상 아래 순서대로 해석한다.

```
① 누가? (Source)

↓

② 어디로? (Destination)

↓

③ 어떤 프로토콜? (IP/TCP/UDP/ICMP)

↓

④ 어떤 서비스? (FTP/Telnet/HTTP...)

↓

⑤ 허용(permit) / 차단(deny)
```

이 다섯 가지만 찾으면 대부분의 ACL 문제를 해결할 수 있다.