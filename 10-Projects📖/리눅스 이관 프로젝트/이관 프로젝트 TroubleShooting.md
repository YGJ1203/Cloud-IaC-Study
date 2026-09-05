# 2026-09-05 Linux Web/DNS Project Troubleshooting Note

> **Project:** Windows Server 서비스 종료 → CentOS Stream 9 기반 Linux 서버 전환  
> **Web/DNS Server:** `10.1.101.200`  
> **Domain:** `kaist.com`  
> **Focus:** 이번 프로젝트에서 실제로 발생한 문제를 **증상 → 원인 → 해결 → 검증 → 교훈** 순서로 정리

---

## 0. 이번 프로젝트의 핵심 점검 흐름

장애가 발생했을 때 무작정 설정 파일부터 수정하지 않고 다음 순서로 계층을 좁힌다.

```text
[1] NIC / IP
      ↓
[2] Gateway / Routing
      ↓
[3] DNS Resolver
      ↓
[4] Service Process
      ↓
[5] Listening Port
      ↓
[6] Firewall
      ↓
[7] Apache VirtualHost / DocumentRoot
      ↓
[8] NAT / HSRP-NAT
      ↓
[9] Client 실제 접속
```

Linux 측 기본 점검:

```bash
ip addr
ip route
ping <gateway>
cat /etc/resolv.conf
nslookup <domain>

systemctl status httpd
ss -lntp
firewall-cmd --list-all

curl http://localhost
curl http://10.1.101.200
```

Gateway 측 기본 점검:

```text
show ip interface brief
show ip route
show arp
show standby brief
show ip nat translations
show ip nat statistics
show access-lists
```

---

# 1. `dnf/yum` 패키지 설치 실패 — DNS 이름 해석 문제

## 증상

CentOS Stream 9에서 패키지를 설치하려고 했지만 repository 접근 과정에서
`mirrors.centos.org` 이름을 해석하지 못했다.

반면 외부 IP인 `8.8.8.8`로의 ping은 정상적으로 응답했다.

```bash
ping 8.8.8.8
ping mirrors.centos.org
```

첫 번째는 성공하지만 두 번째는 실패하는 형태였다.

## 원인

외부 네트워크 자체가 끊어진 것이 아니라 **DNS Resolver 설정 문제**였다.

즉,

```text
IP 통신 가능
   ↓
Routing은 대체로 정상
   ↓
도메인 이름만 해석 실패
   ↓
DNS 문제 의심
```

## 해결

패키지 설치가 필요한 시점에 KT DNS를 임시로 사용했다.

```text
168.126.63.1
```

NetworkManager 환경에서는 DNS 설정을 적용한 뒤 연결을 다시 활성화하거나
NetworkManager를 재시작하여 적용 여부를 확인한다.

```bash
systemctl restart NetworkManager
cat /etc/resolv.conf
```

## 검증

```bash
ping mirrors.centos.org
dnf repolist
dnf install <package>
```

## 교훈

> **IP ping 성공 + Domain ping 실패 = DNS부터 확인한다.**

`dnf` 오류가 발생했다고 해서 곧바로 repository 서버 자체의 문제라고 판단하면 안 된다.

---

# 2. `nslookup` NXDOMAIN — 단순 오타도 DNS 장애처럼 보인다

## 증상

DNS 테스트 과정에서 잘못 입력한 도메인에 대해 `NXDOMAIN`이 반환되었다.

예:

```bash
nslookup mirros...
```

## 원인

DNS 서버 장애가 아니라 **조회할 이름 자체의 오타**였다.

`NXDOMAIN`은 기본적으로 DNS 서버가

> "해당 이름은 존재하지 않는다."

라고 응답한 것이다.

## 해결 / 검증

조회 문자열을 먼저 다시 확인한다.

```bash
nslookup mirrors.centos.org
```

필요하면 사용할 DNS 서버를 명시하여 비교한다.

```bash
nslookup <name> 10.1.101.200
nslookup <name> 168.126.63.1
```

## 교훈

DNS 장애 분석 시 다음을 구분한다.

```text
timeout
  → DNS 서버에 도달하지 못했을 가능성

SERVFAIL
  → DNS 서버 처리/설정 문제 가능성

NXDOMAIN
  → 해당 이름이 없거나 입력값이 잘못되었을 가능성
```

---

# 3. 내부 `kaist.com` 대신 외부 공개 사이트로 접속되는 문제

## 증상

Web 서버 자체는 정상처럼 보였다.

```bash
curl http://localhost
curl http://10.1.101.200
```

두 명령은 정상 응답했지만,

```bash
curl http://www.kaist.com
```

으로 접근하면 프로젝트 내부 Web 서버가 아니라 **인터넷상의 실제 공개 도메인**으로 연결되었다.

## 원인

서버/클라이언트 Resolver가 프로젝트 DNS인

```text
10.1.101.200
```

이 아니라 외부 DNS인

```text
168.126.63.1
```

을 사용하고 있었다.

프로젝트에서 사용하는 `kaist.com`은 실제 인터넷에도 존재하는 도메인이므로,
외부 DNS에 질의하면 외부의 실제 IP가 반환된다.

```text
Client
  │
  ├─ DNS = 168.126.63.1
  │       └─ 실제 인터넷 kaist.com IP 반환
  │
  └─ DNS = 10.1.101.200
          └─ 프로젝트 내부 10.1.x.x IP 반환
```

## 해결

각 서버의 DNS Resolver를 프로젝트 DNS 서버로 변경했다.

```text
DNS Server = 10.1.101.200
```

설정 적용 후:

```bash
systemctl restart NetworkManager
```

## 검증

```bash
cat /etc/resolv.conf
nslookup www.kaist.com
```

정상 결과:

```text
www.kaist.com
→ 10.1.101.200
```

그리고:

```bash
curl http://www.kaist.com
```

으로 내부 페이지가 표시되는지 확인한다.

## 교훈

> **DNS 서버 구축 완료와 Client가 그 DNS를 실제로 사용하는 것은 별개의 문제다.**

Zone 파일이 완벽해도 Resolver가 다른 DNS를 바라보면 아무 소용이 없다.

또한 실습용 도메인과 실제 공개 도메인이 겹치면 **Split DNS와 비슷한 상황**이 발생하므로
어느 DNS 서버가 응답했는지를 반드시 확인해야 한다.

---

# 4. Apache 시작 시 `AH00558` FQDN Warning

## 증상

Apache 실행/검증 과정에서 다음 계열의 경고가 나타났다.

```text
AH00558: Could not reliably determine the server's fully qualified domain name ...
```

## 원인

Apache가 서버 전체에서 사용할 `ServerName`을 명확하게 결정하지 못했기 때문이다.

중요한 점은 이것이 보통 **Apache 실행 자체를 막는 Fatal Error가 아니라 Warning**이라는 것이다.

## 점검

```bash
httpd -t
systemctl status httpd
```

`Syntax OK`이며 서비스가 `active (running)`이면 우선 웹 서비스 자체의 동작 여부를 별도로 확인한다.

```bash
curl http://localhost
```

## 개선

필요하다면 Apache 전역 설정에 서버 이름을 명시한다.

예:

```apache
ServerName www.kaist.com
```

변경 후:

```bash
httpd -t
systemctl restart httpd
```

## 교훈

> 로그에 메시지가 나타났다고 해서 모든 메시지가 서비스 장애의 직접 원인은 아니다.

**Warning과 Error를 구분**하고 실제 서비스 상태와 함께 판단한다.

---

# 5. VirtualHost 설정 후 `DocumentRoot does not exist`

## 증상

Port-based VirtualHost를 구성한 뒤 Apache 설정 검사에서 다음 경고가 발생했다.

```text
AH00112: Warning: DocumentRoot [/var/www/www1] does not exist
AH00112: Warning: DocumentRoot [/var/www/www2] does not exist
AH00112: Warning: DocumentRoot [/var/www/www3] does not exist
Syntax OK
```

## 원인

`vhost.conf`에서 DocumentRoot를 먼저 지정했지만 실제 디렉토리를 아직 만들지 않았다.

예:

```apache
DocumentRoot "/var/www/www1"
```

하지만:

```text
/var/www/www1
```

이 존재하지 않았다.

## 해결

```bash
mkdir -p /var/www/www1
mkdir -p /var/www/www2
mkdir -p /var/www/www3
```

또는:

```bash
mkdir -p /var/www/www{1..3}
```

이후 각 DocumentRoot에 `index.html`을 배치한다.

## 검증

```bash
ls -ld /var/www/www{1..3}
httpd -t
systemctl restart httpd
```

## 교훈

VirtualHost는 설정 파일만 만든다고 완성되는 것이 아니다.

```text
Listen
+ VirtualHost
+ DocumentRoot
+ 실제 Directory
+ index 파일
+ Firewall
```

이 모두 맞아야 한다.

---

# 6. `8081~8083` 페이지 접속 — DNS와 Port의 역할 혼동

## 구성

이번 Web 서버는 학과별 페이지를 TCP Port로 구분했다.

```text
www.kaist.com:8081 → 학과 1
www.kaist.com:8082 → 학과 2
www.kaist.com:8083 → 학과 3
```

영문 페이지는 별도 VirtualHost가 아니라 각 DocumentRoot 아래의 `/en/` 경로로 구성했다.

예:

```text
http://www.kaist.com:8081/en/
```

## 핵심

DNS는 다음까지만 담당한다.

```text
www.kaist.com
      ↓
10.1.101.200
```

DNS가 `8081`, `8082`, `8083`을 선택하는 것이 아니다.

실제 서비스 선택은:

```text
TCP Destination Port
```

와 Apache VirtualHost가 담당한다.

## 검증

```bash
nslookup www.kaist.com

curl http://www.kaist.com:8081/
curl http://www.kaist.com:8082/
curl http://www.kaist.com:8083/

curl http://www.kaist.com:8081/en/
curl http://www.kaist.com:8082/en/
curl http://www.kaist.com:8083/en/
```

## 교훈

```text
DNS       = 어느 IP로 갈 것인가?
TCP Port  = 그 서버의 어느 서비스로 갈 것인가?
URL Path  = 그 서비스 안에서 어느 Resource를 요청할 것인가?
```

---

# 7. 방화벽 때문에 VirtualHost Port가 막힐 가능성

## 문제 포인트

Apache에서 `8081~8083`을 Listen하도록 설정해도 firewalld가 해당 포트를 허용하지 않으면
다른 호스트에서는 접속할 수 없다.

## 최종 프로젝트 설정 확인

Web/DNS 서버에서 다음 서비스/포트를 허용했다.

```text
http
https
dns
8081/tcp
8082/tcp
8083/tcp
```

## 검증

```bash
firewall-cmd --list-all
```

Apache Listen 상태도 함께 확인한다.

```bash
ss -lntp | egrep ':80|:443|:8081|:8082|:8083'
```

## 장애 분석 포인트

```text
localhost 접속 성공
+
원격 Client 접속 실패
```

라면 다음 후보를 확인한다.

```text
Routing
Firewall
ACL
NAT
Listening Address
```

## 교훈

> `httpd active`는 "프로세스가 살아 있다"는 뜻이지, Client가 접속 가능하다는 뜻은 아니다.

---

# 8. `192.168.2.253:80` 외부 접속 실패 — End-to-End로 추적하기

## 증상

내부 Web 서버와 Apache 설정은 정상인데 외부에서

```text
192.168.2.253:80
```

으로 접속되지 않는 상황이 발생했다.

이런 문제는 Web 서버 하나만 확인해서는 원인을 찾기 어렵다.

## 점검 순서

### 1) Web 서버 자체 확인

```bash
systemctl status httpd
ss -lntp | grep ':80'
curl http://localhost
curl http://10.1.101.200
```

### 2) Web 서버 방화벽 확인

```bash
firewall-cmd --list-all
```

### 3) Gateway / HSRP 상태 확인

```text
show standby brief
show ip interface brief
```

### 4) NAT 설정 및 Translation 확인

```text
show ip nat translations
show ip nat statistics
```

Static PAT가 설정되어 있다면 외부 주소/포트가 내부 Web 서버의 올바른 주소/포트로 매핑되는지 확인한다.

### 5) NAT inside / outside 확인

Gateway 인터페이스의 역할도 확인한다.

```text
ip nat inside
ip nat outside
```

### 6) ACL 존재 시 확인

```text
show access-lists
```

## 프로젝트에서 확인된 포인트

GW1/GW2에는 Web 서비스용 HSRP-NAT Static PAT 구성이 존재했고,
`80/443/8081/8082/8083` 포트가 내부 Web 서버로 전달되도록 구성했다.

따라서 장애 분석 시 단순히

> "Apache가 안 된다"

라고 판단하지 않고,

```text
External Client
   ↓
HSRP Virtual/Public Address
   ↓
Gateway Active Router
   ↓
Static PAT
   ↓
10.1.101.200
   ↓
firewalld
   ↓
httpd
   ↓
DocumentRoot
```

순서로 패킷 경로를 따라가야 한다.

## 교훈

> 외부 접속 장애는 **End-to-End Path**로 분석한다.

서비스가 정상이어도 NAT 앞단에서 패킷이 끊길 수 있고,
NAT가 정상이어도 서버 방화벽에서 끊길 수 있다.

---

# 9. 메인 페이지 `:80`과 학과 페이지 `:8081~8083` 구조 정리

프로젝트 후반에 메인 학부 홈페이지도 추가했다.

```text
/var/www/html/index.html
/var/www/html/en/index.html
```

학과별 페이지는:

```text
/var/www/www1/
/var/www/www2/
/var/www/www3/
```

형태로 유지한다.

즉 최종 구조는 다음과 같다.

```text
www.kaist.com:80
└─ /var/www/html
   ├─ index.html
   └─ en/index.html

www.kaist.com:8081
└─ /var/www/www1
   ├─ index.html
   └─ en/index.html

www.kaist.com:8082
└─ /var/www/www2
   ├─ index.html
   └─ en/index.html

www.kaist.com:8083
└─ /var/www/www3
   ├─ index.html
   └─ en/index.html
```

## 교훈

Port-based VirtualHost를 추가하더라도 Apache 기본 `:80` 사이트를 별도로 사용할 수 있다.

기본 페이지와 VirtualHost 페이지의 역할을 구분하면 설정이 훨씬 명확해진다.

---

# 10. 트러블슈팅용 명령어 Cheat Sheet

## Network

```bash
ip addr
ip route
ping <gateway>
ping 8.8.8.8
```

## DNS

```bash
cat /etc/resolv.conf
nslookup www.kaist.com
nslookup www.kaist.com 10.1.101.200
```

DNS Zone 검사:

```bash
named-checkzone kaist.com /var/named/kaist.com.zone
named-checkzone 1.10.in-addr.arpa /var/named/10.1.rev
```

## Apache

```bash
rpm -qa | grep httpd
systemctl status httpd
ps -ef | grep '[h]ttpd'
httpd -t
ss -lntp | grep httpd
```

## HTTP Test

```bash
curl http://localhost
curl http://10.1.101.200
curl http://www.kaist.com

curl http://www.kaist.com:8081/
curl http://www.kaist.com:8082/
curl http://www.kaist.com:8083/
```

## Firewall

```bash
firewall-cmd --list-all
```

## Cisco Gateway / HSRP / NAT

```text
show ip interface brief
show ip route
show arp
show standby brief
show ip nat translations
show ip nat statistics
show access-lists
```

---

# 11. 장애 유형별 빠른 판단표

| 증상 | 가장 먼저 볼 것 | 대표 원인 |
|---|---|---|
| `8.8.8.8`도 ping 실패 | IP/Route/Gateway | NIC, Gateway, Routing |
| IP ping 성공, Domain 실패 | DNS | Resolver 설정 |
| `NXDOMAIN` | 조회 이름/Zone | 오타, Record 없음 |
| `localhost` 성공, IP 실패 | Listen/Firewall | Bind 주소, Firewall |
| Server 내부 접속 성공, Client 실패 | Firewall/Route/ACL | 네트워크 경로 차단 |
| 내부 접속 성공, 외부 접속 실패 | NAT/HSRP/ACL | Static PAT, Active GW |
| `httpd -t` Warning | Warning 내용 확인 | ServerName, DocumentRoot |
| `DocumentRoot does not exist` | 실제 Directory | mkdir 누락 |
| `:80` 성공, `:8081` 실패 | Listen/VHost/Firewall | 포트 설정 누락 |
| 내부 도메인이 외부 사이트로 감 | Resolver | 외부 DNS 사용 |

---

# 12. 이번 프로젝트에서 가장 중요했던 사고방식

이번 프로젝트의 핵심은 단순히 명령어를 외우는 것이 아니라
**문제가 어느 계층에서 발생했는지 범위를 줄이는 것**이었다.

예를 들어:

```text
웹페이지가 안 열린다.
```

라는 하나의 증상에도 원인은 매우 많다.

```text
DNS?
Routing?
Apache?
VirtualHost?
DocumentRoot?
Firewall?
ACL?
NAT?
HSRP?
```

따라서 다음처럼 확인한다.

```text
① IP로 접속되는가?
        ↓ YES
② Domain으로 접속되는가?
        ↓ NO
   → DNS 문제

① localhost는 되는가?
        ↓ YES
② 다른 Client에서는 되는가?
        ↓ NO
   → Firewall / Network 문제

① 내부에서는 되는가?
        ↓ YES
② 외부에서는 되는가?
        ↓ NO
   → NAT / ACL / HSRP 경로 문제
```

이 방식은 Linux뿐 아니라 실제 인프라 장애 분석에서도 그대로 사용할 수 있다.

---

# 13. 면접에서 설명한다면

### Q. Web Server 접속이 안 될 때 어떤 순서로 점검하시겠습니까?

**A.**

먼저 서버의 IP와 Routing 상태를 확인하고 Gateway까지 통신되는지 확인합니다.
그다음 DNS를 사용하는 접속이라면 Resolver와 DNS Record를 확인합니다.

서버에서는 `systemctl status`, `ss` 등을 이용해 서비스 프로세스와 Listening Port를 확인하고,
firewalld가 해당 포트를 허용하는지 점검합니다.

내부에서는 정상인데 외부에서만 접속되지 않는 경우에는
Gateway의 HSRP 상태와 NAT Translation, ACL을 확인하여
Client에서 Server까지 패킷 경로를 단계적으로 추적하겠습니다.

---

### Q. `ping 8.8.8.8`은 되는데 `ping google.com`은 안 됩니다. 무엇을 의심하시겠습니까?

**A.**

IP 기반 외부 통신은 가능하므로 기본 Routing은 정상일 가능성이 높습니다.
반면 Domain Name만 해석되지 않기 때문에 DNS Resolver 설정이나 DNS 서버 접근성을 우선 확인하겠습니다.

---

### Q. Apache가 `active (running)`인데 웹페이지 접속이 안 될 수도 있습니까?

**A.**

네. Apache 프로세스가 실행 중이라는 것과 Client가 서비스에 접근할 수 있다는 것은 별개입니다.
Listening Port, firewalld, Routing, ACL, NAT, VirtualHost와 DocumentRoot까지 추가로 확인해야 합니다.

---

# 14. 최종 체크리스트

- [ ] `ip addr`에서 서버 IP 확인
- [ ] `ip route`에서 Default Gateway 확인
- [ ] Gateway ping 확인
- [ ] `cat /etc/resolv.conf`에서 DNS 확인
- [ ] `nslookup`으로 내부 Record 확인
- [ ] `named-checkzone`으로 Zone 문법 확인
- [ ] `systemctl status httpd` 확인
- [ ] `httpd -t` 확인
- [ ] `ss -lntp`에서 80/443/8081~8083 확인
- [ ] `firewall-cmd --list-all` 확인
- [ ] DocumentRoot 실제 존재 여부 확인
- [ ] `/en/index.html` 경로 확인
- [ ] 내부 IP 직접 접속 확인
- [ ] FQDN 접속 확인
- [ ] `show standby brief` 확인
- [ ] `show ip nat translations` 확인
- [ ] `show ip nat statistics` 확인
- [ ] ACL 확인
- [ ] 외부 → NAT → Server End-to-End 접속 확인

---

# 15. 한 줄 총정리

> **서비스 장애는 "안 된다"에서 멈추지 말고, IP → DNS → Port → Firewall → Application → NAT 순으로 범위를 좁혀 원인을 증명한다.**

이번 프로젝트에서 가장 큰 수확은 Apache나 DNS 명령어 자체보다도,
**여러 계층이 연결된 환경에서 장애 지점을 하나씩 제거해 나가는 Troubleshooting 사고방식**이었다.