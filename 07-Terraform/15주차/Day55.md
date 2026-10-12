# 2026-10-12 AWS 보안 실습 통합 복습

> **주제:** CloudFormation 기반 VPN · Security Group · ALB/DVWA · AWS WAF 공격 탐지 및 차단  
> **실습 근거:** 사용자가 제공한 CloudFormation YAML 3종 및 DVWA 공격 문자열, 콘솔 실습 설명, `403 Forbidden` 관찰 결과  
> **학습 목표:** 네트워크 연결부터 접근 제어, 웹 애플리케이션 계층 방어까지 하나의 흐름으로 설명하기

---

## 0. 오늘의 핵심 요약

| 실습 | 템플릿의 주요 구성 | 확인/학습 내용 |
|---|---|---|
| **① VPN 준비 환경** | MyVPC17(10.0.0.0/16), MyVPC18(172.16.0.0/16), MyCGW, MyWeb11, MyWeb2 | Libreswan 기반 VPN 게이트웨이 준비, IKE/IPsec 관련 포트, IP forwarding |
| **② Security Group** | MyVPC23, 동일 Public Subnet의 MyWeb1(10.0.1.101)·MyWeb2(10.0.1.102), 서로 다른 SG | 인바운드 규칙 변경에 따른 SSH·HTTP·ICMP 통신 비교 |
| **③ DVWA + ALB + WAF** | MyVPC24, Public Subnet 2개, DVWA EC2 2대, Target Group, ALB | OS Command Injection, SQL Injection, Reflected XSS 요청과 WAF 규칙 차단 실습 |

**관찰된 결과:** 사용자는 AWS WAF & Shield 콘솔에서 규칙을 구성하면서 DVWA 공격을 실습했고, **`403 Forbidden` 응답을 직접 확인**했다. 단, 어떤 규칙이 차단했는지는 WAF Sampled Requests/로그에서 확인해야 최종 입증된다.

**한 줄 핵심:** **Security Group은 주로 IP·프로토콜·포트**, **AWS WAF는 HTTP 요청의 내용**을 검사한다. **AWS Shield는 DDoS 방어**에 초점을 둔다.

---

## 1. 전체 학습 흐름

```text
[CloudFormation 템플릿 업로드]
              |
              +--> MyVPC17 / MyVPC18 : VPN 실습 기반
              |
              +--> MyVPC23 : Security Group 규칙 변경 실습
              |
              +--> MyVPC24 : ALB + DVWA 웹 취약점 실습 기반
                                      |
                                 [AWS WAF Web ACL]
                                      |
                          Command Injection / SQLi / XSS
                                      |
                           탐지·차단 결과 비교
                                      |
                             HTTP 403 관찰
```

**중요:** 제공된 CloudFormation 템플릿은 **실습 시작 시점의 인프라 정의**다. 콘솔에서 이후 수정한 Security Group, VPN, WAF 설정은 원본 YAML에 자동 반영되지 않는다(드리프트 가능).

---

## 2. CloudFormation 기본 문법 복습

```yaml
Parameters:
  KeyName:
    Type: AWS::EC2::KeyPair::KeyName
  LatestAmiId:
    Type: 'AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>'
    Default: '/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2'

Resources:
  MyVPC23:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
```

| 구문 | 의미 |
|---|---|
| `Parameters` | 스택 생성 시 전달할 입력값 |
| `Resources` | 생성할 AWS 리소스 정의 |
| `Type` | 리소스 종류 (`AWS::EC2::VPC` 등) |
| `Properties` | 리소스 설정값 |
| `!Ref` | 파라미터/리소스 참조(반환값은 리소스 유형별로 다름) |
| `!GetAZs ''` | 현재 리전의 가용 영역 목록 조회 |
| `!Select [0, ...]` | 목록 첫 번째 항목 선택(0부터 시작) |
| `!Sub` | 문자열 치환/보간 |
| `Fn::Base64` | EC2 UserData 인코딩 |
| `DependsOn` | 명시적인 리소스 생성 의존 관계 지정 |

**실무 주의:** `!Select [2, !GetAZs '']`는 세 번째 AZ를 선택한다. 해당 리전/계정에서 반환되는 AZ가 3개 미만이면 실패할 수 있다.

---

## 3. 실습 ① MyVPC17 / MyVPC18 — VPN 환경

### 3.1 템플릿 기반 아키텍처

```text
VPC17 10.0.0.0/16                         VPC18 172.16.0.0/16
+--------------------------------+        +--------------------------+
| Public 10.0.1.0/24             |        | Public 172.16.1.0/24   |
|  MyCGW 10.0.1.101 (Public IP)   |        |  MyWeb2 172.16.1.101    |
|  Libreswan + tcpdump           |        |  Apache HTTP Server     |
|                                |        +--------------------------+
| Private 10.0.100.0/24          |
|  MyWeb11 10.0.100.101          |
+--------------------------------+

       [VPN 터널 및 AWS 측 게이트웨이/라우팅은 YAML에 미정의]
```

### 3.2 생성되는 주요 리소스

- VPC 2개: `MyVPC17`과 `MyVPC18`
- Internet Gateway 각 1개, Public Route Table 및 IGW 기본 경로 각 1개
- VPC17: Public Subnet `10.0.1.0/24`, Private Subnet `10.0.100.0/24`
- VPC18: Public Subnet `172.16.1.0/24`
- EC2: `MyCGW`, `MyWeb11`, `MyWeb2`
- Security Group: Public 2개, Private 1개

### 3.3 MyCGW UserData 핵심

```bash
yum -y install tcpdump libreswan

# 주요 sysctl 설정(발췌)
net.ipv4.ip_forward=1
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.all.rp_filter=0

sysctl -p /etc/sysctl.conf
```

- **Libreswan:** Linux IPsec VPN 소프트웨어
- **tcpdump:** 네트워크 패킷 캡처/분석 도구
- **`ip_forward=1`:** 호스트가 다른 네트워크 사이에서 IPv4 패킷을 전달할 수 있도록 활성화
- **`accept_redirects/send_redirects=0`:** ICMP Redirect 수신/전송 억제
- **`rp_filter=0`:** 비대칭 경로 등의 상황에서 역방향 경로 검사로 패킷이 버려지는 문제를 피하도록 조정(보안상 영향 검토 필요)

템플릿은 외부 URL의 `14_vpnconfig.sh`를 다운로드하고 실행 권한을 부여하지만, **이 YAML만으로는 스크립트 내용이나 VPN 연결 완료 여부를 알 수 없다.** 또한 **다운로드 후 자동 실행하는 명령은 보이지 않는다.**

### 3.4 VPN 관련 Security Group 포트

| 프로토콜/포트 | 역할 |
|---|---|
| UDP 500 | IKE 협상 |
| UDP 4500 | IPsec NAT Traversal (NAT-T) |
| ICMP | Ping 등 ICMP 테스트 |
| TCP 22 | SSH 접속 |
| TCP 80 | HTTP 테스트 |

**추가 구분:** ESP는 IP 프로토콜 번호 **50**으로, TCP/UDP 포트가 아니다. IPsec 방식 및 NAT-T 사용 여부에 따라 필요한 허용 항목이 달라질 수 있다. 제공된 SG에는 별도의 ESP 허용 규칙이 없다.

### 3.5 VPN이 실제 통신되려면 추가 확인할 사항

1. AWS VPN 게이트웨이/연결 리소스 또는 상대 측 터널 구성
2. 터널 설정(IKE/IPsec 파라미터, PSK 등)과 양 끝단 IP
3. 양방향 경로: `10.0.0.0/16` ↔ `172.16.0.0/16`
4. MyCGW EC2의 **Source/Destination Check 비활성화** 여부(라우터 역할 시 중요)
5. OS 방화벽, IP forwarding, 보안 그룹, NACL
6. `ipsec status`, `ip route`, `tcpdump` 등으로 실제 통신 검증

> **구분:** YAML은 VPN *준비 인프라*를 정의한다. AWS VPN 연결, VGW/TGW, VPN 경로 자체는 여기 포함되어 있지 않다.

---

## 4. 실습 ② MyVPC23 — Security Group 인바운드

### 4.1 네트워크 구조

```text
MyVPC23: 10.0.0.0/16
  |
  +-- MyPublicSubnet: 10.0.1.0/24
       |
       +-- MyWeb1: 10.0.1.101 / MyPublicSecugroup1
       |
       +-- MyWeb2: 10.0.1.102 / MyPublicSecugroup2

IGW + Public Route Table: 0.0.0.0/0 -> IGW
```

초기 SG 설정은 두 인스턴스 모두 **TCP 22(SSH) 인바운드만 허용**한다. HTTP 80 및 ICMP는 초기 인바운드 허용 목록에 없다.

### 4.2 실습 테스트와 해석

```bash
# SSH 접속 테스트
ssh <사용자>@10.0.1.102

# HTTP 테스트
curl http://10.0.1.101
curl http://10.0.1.102

# ICMP 테스트
ping -c 4 10.0.1.101
ping -c 4 10.0.1.102
```

| 요청 방향/종류 | 상대 대상 SG에서 필요한 인바운드 규칙 |
|---|---|
| MyWeb1 → MyWeb2 SSH | MyWeb2 SG의 TCP 22 허용 |
| MyWeb1 → MyWeb2 HTTP | MyWeb2 SG의 TCP 80 허용 |
| MyWeb1 → MyWeb2 Ping | MyWeb2 SG의 ICMP Echo Request 허용(또는 해당 ICMP 범위 허용) |

**Stateful 핵심:** Security Group이 허용한 연결에 대한 응답 트래픽은 자동 허용된다. EC2가 아웃바운드로 시작한 HTTP/Ping의 응답을 위해 같은 SG의 인바운드 규칙을 따로 열 필요는 없다(해당 아웃바운드 허용을 전제). 따라서 외부로 시작한 요청의 실패를 **인바운드 SG 변경만으로 단정하지 않는다.**

**NACL 비교:** NACL은 Stateless이므로 요청과 응답 방향 모두 규칙을 검토해야 한다. TCP 응답의 임시 포트(ephemeral ports)도 중요하다.

### 4.3 SG vs NACL vs WAF

| 항목 | Security Group | Network ACL | AWS WAF |
|---|---|---|---|
| 적용 위치 | ENI/리소스 수준 | 서브넷 수준 | 지원되는 웹 리소스(ALB 등)에 연결 |
| 상태 추적 | Stateful | Stateless | HTTP 요청 평가 |
| 규칙 | Allow 중심 | Allow/Deny | Allow/Block/Count 등 |
| 검사 기준 | IP·프로토콜·포트 | IP·프로토콜·포트 | URI·Query String·Header·Body 등 |
| SQLi/XSS 검사 | 불가 | 불가 | 가능 |

---

## 5. 실습 ③ MyVPC24 — ALB + DVWA

### 5.1 구성도

```text
Internet
   |
   v
[ALB: MyALB, HTTP 80, internet-facing]
   |
   v
[Target Group: MyALBtargetgroup, HTTP 80]
   |                                    |
   +-- MyWeb1 10.0.1.101               +-- MyWeb2 10.0.2.101
       Public Subnet 1                     Public Subnet 2
       Apache + PHP + MariaDB + DVWA       Apache + PHP + MariaDB + DVWA

VPC: MyVPC24 10.0.0.0/16
IGW 및 각 Public Subnet 기본 경로 설정

[WAF Web ACL] --(콘솔에서 별도로 ALB에 연결하는 실습)
```

### 5.2 핵심 설정

```yaml
MyALBtargetgroup:
  Type: AWS::ElasticLoadBalancingV2::TargetGroup
  Properties:
    Port: 80
    Protocol: HTTP
    HealthCheckPath: '/login.php'
    Targets:
      - Id: !Ref MyWeb1
        Port: 80
      - Id: !Ref MyWeb2
        Port: 80
    TargetGroupAttributes:
      - Key: stickiness.enabled
        Value: true
```

- **Health Check `/login.php`:** ALB가 DVWA 로그인 페이지 경로로 대상 상태 확인
- **Stickiness:** 동일 클라이언트의 요청이 가급적 동일 타깃으로 전달되도록 함. 두 EC2는 각자 독립 DB/세션 환경이므로 로그인 실습에서 의미가 있다.
- **ALB Listener:** HTTP 80 요청을 Target Group으로 전달
- **인터넷 노출:** ALB뿐 아니라 두 EC2도 공인 IP가 할당되고, 공통 SG가 TCP 80/443/22를 인터넷 전체에 허용

### 5.3 DVWA UserData 자동 설치(발췌)

```bash
yum install -y httpd mariadb-server mariadb
yum install -y php php-mysqlnd php-gd
systemctl enable --now mariadb httpd

# DVWA용 DB 생성 및 권한 부여(실습용 고정 암호 사용)
# 외부 ZIP 다운로드 후 /var/www/html/로 이동
# PHP 설정 및 디렉터리 권한 변경
systemctl restart httpd
```

**주의:** 실제 템플릿에는 고정 DB 암호, 외부 ZIP 다운로드, `allow_url_include = on`, `chmod 777` 등이 있다. 모두 운영 환경에서는 피해야 할 취약한 설정이다. 또한 외부 저장소 ZIP 내용은 이 YAML만으로 검증할 수 없다.

### 5.4 CloudFormation에 WAF가 있나?

**없다.** 제공된 MyVPC24 YAML에는 `AWS::WAFv2::WebACL`, `AWS::WAFv2::WebACLAssociation` 리소스가 없다. 따라서 사용자가 수행한 **WAF & Shield 콘솔 설정은 별도 단계**다.

---

## 6. DVWA 공격 유형 및 문자열 분석

> **범위:** 아래 예시는 사용자가 제시한 **본인 소유/허가된 DVWA 교육 환경**의 실습 문자열이다. 실제 외부 서비스에는 사용하지 않는다.

### 6.1 OS Command Injection

- **경로:** `/vulnerabilities/exec/`
- **HTTP 메서드:** POST
- **핵심:** 웹 애플리케이션이 입력값을 운영체제 셸 명령에 안전하지 않게 연결할 때 추가 명령이 실행될 수 있음

```text
168.126.63.1 ; cat /etc/passwd | head
168.126.63.1 && cat /etc/passwd | head
168.126.63.1 ; uname -a
168.126.63.1 && uname -a
168.126.63.1 ; ls /etc
168.126.63.1 && ls /etc
```

| 메타문자 | 의미 |
|---|---|
| `;` | 앞 명령의 성공 여부와 무관하게 다음 명령 실행 |
| `&&` | 앞 명령이 성공한 경우 다음 명령 실행 |
| `||` | 앞 명령이 실패한 경우 다음 명령 실행 |
| `\|` | 앞 명령의 표준 출력을 다음 명령의 표준 입력으로 연결 |

`cat /etc/passwd | head`는 `/etc/passwd`의 처음 부분을 출력하는 예시다. 현대 Linux에서 `/etc/passwd`는 일반적으로 암호 해시를 담는 파일이 아니며, 계정 메타데이터가 담긴다.

**제공된 WAF 실습 탐지 문자열:** `;`, `&&`, `/`, `exec`  
**제공된 규칙명:** `OS_Command_check_1`, `OS_Command_check_2`, `OS_Command_check_3`

> **주의:** 탐지 문자열이 4개인데 규칙 이름은 3개이므로, 정확히 어떤 규칙이 어떤 문자열을 검사했는지는 **콘솔 설정/로그 없이는 단정할 수 없다.**

### 6.2 SQL Injection

- **경로:** `/vulnerabilities/sqli/`
- **HTTP 메서드:** GET
- **핵심:** 사용자 입력이 SQL 쿼리 구문으로 해석되면 조회 조건이나 반환 데이터를 조작할 수 있음

```sql
' or 1=1 #
' union select user,password from users #
```

- `' or 1=1 #`: 조건식 변조 시도 (`#`는 해당 SQL 문맥에서 주석 역할 가능)
- `' union select user,password from users #`: 다른 테이블의 값을 기존 결과에 결합하려는 시도
- 실제 성공 여부는 원래 쿼리, DBMS, 컬럼 수/타입, 권한 등에 좌우된다.

**제공된 WAF 탐지 문자열:** `'`, `or`, `union`, `select`, `#`  
**제공된 규칙명:** `SQL_check`

### 6.3 Reflected XSS

- **경로:** `/vulnerabilities/xss_r/`
- **HTTP 메서드:** GET
- **핵심:** 사용자 입력이 적절한 출력 인코딩 없이 HTML 응답에 반영되면 브라우저가 스크립트로 실행할 수 있음

```html
<script>alert("test")</script>
```

**제공된 WAF 탐지 문자열:** `<script>`, `</script>`

**참고:** 이 예제는 `alert` 팝업으로 동작을 관찰하는 교육용 페이로드이며, XSS 방어의 근본은 **문맥별 출력 인코딩**, 안전한 DOM API 사용, 필요시 CSP 등의 방어 심층화다.

---

## 7. AWS WAF 규칙 설계 핵심

### 7.1 실습 방식

```text
[DVWA 공격 요청]
       |
       v
[WAF Web ACL]
       |
       +-- 규칙 일치 --> Block --> 기본적으로 HTTP 403
       |
       +-- 불일치 ----> 기본 동작/다음 규칙 평가 --> ALB --> DVWA
```

**규칙 평가:** WAF 규칙의 우선순위, 액션, Web ACL 기본 동작에 따라 결과가 달라진다. `Count`는 관찰용이며 일반적으로 요청을 즉시 차단하지 않는다.

### 7.2 요청 구성요소별 검사

| 공격 | 주요 검사 대상 예시 |
|---|---|
| Command Injection | **Body(POST)**, 필요시 URI Path |
| SQL Injection | **Query String / 특정 Query Argument(GET)** |
| Reflected XSS | **Query String / 특정 Query Argument(GET)** |

**중요:** HTTP 메서드가 POST라고 해서 공격 문자열이 항상 Body에 있는 것은 아니다. 실제 요청에서 어디에 실렸는지 개발자 도구나 WAF 로그로 확인해야 한다.

### 7.3 단순 문자열 탐지의 한계

| 문자열 | 잠재 문제 |
|---|---|
| `/` | 정상 URI에 매우 흔함. URI 전체 검사 시 오탐 위험 매우 큼 |
| `or` | 일반 영단어 일부와도 일치할 수 있음 |
| `select` | 정상 검색어/업무 데이터에도 존재 가능 |
| `;`, `&&` | 정상 데이터·코드 문맥에서도 사용 가능 |
| `<script>` | 인코딩·대소문자·변형 등으로 단순 비교를 회피할 수 있음 |

**실무 권장 방향:**

1. 처음에는 **Count**로 매칭/오탐을 관찰
2. 검사 대상(URI Path, Query String, Body)을 좁혀 적용
3. 필요한 Text Transformation(디코딩, 소문자화 등)을 고려
4. AWS WAF의 **SQLi Match / XSS Match**, 적절한 **Managed Rule Group** 검토
5. 차단 후에도 정상 트래픽이 동작하는지 회귀 테스트
6. WAF는 보조 방어선이며 안전한 애플리케이션 구현을 대체하지 않음

### 7.4 WAF vs Shield

| 구분 | AWS WAF | AWS Shield |
|---|---|---|
| 주요 목적 | HTTP(S) 요청 기반 웹 공격 필터링 | DDoS 방어 |
| 주요 예 | SQLi, XSS, 요청 패턴 기반 차단 | 네트워크/전송 계층 중심 DDoS 대응 등 |
| 구성 방식 | Web ACL, Rule, ALB 등 연결 | Shield Standard 기본 보호, Advanced 별도 서비스 |

**주의:** 'WAF & Shield 콘솔'에서 WAF 규칙을 생성했다고 해서 Shield Advanced에 가입하거나 별도 Shield 보호 구성을 완료했다는 뜻은 아니다.

---

## 8. 실습 검증 — 403 Forbidden의 의미

### 8.1 관찰한 사실

- 사용자는 AWS WAF & Shield 콘솔에서 탐지/차단 규칙을 만들면서 DVWA 공격 실습을 수행함.
- **`403 Forbidden` 화면을 직접 확인함.**

### 8.2 확인을 강화하는 절차

1. **WAF 적용 전:** 허가된 DVWA 테스트 요청의 응답/동작 기록
2. **WAF 적용 후:** 동일한 입력으로 재시험, 응답 코드 비교
3. **WAF Sampled Requests 또는 로그:** `action=BLOCK`, 매칭 규칙, 요청 URI/인수 확인
4. **정상 요청:** `/login.php` 등 정상 경로가 불필요하게 차단되지 않는지 확인
5. **ALB Target Group:** 대상 Healthy 상태와 애플리케이션 정상 작동 확인

```text
예상되는 WAF 기본 차단 응답: HTTP 403 Forbidden
단, 사용자 지정 응답이 설정되면 다른 상태 코드도 가능.
```

**정확한 표현:** “403을 관찰했다”는 **확인된 사실**이다. “특정 WAF 규칙이 차단했다”는 **WAF 로그/샘플 요청에서 매칭 규칙을 확인했을 때** 더 확실하게 주장할 수 있다. 웹 서버나 다른 계층에서도 403을 반환할 수 있기 때문이다.

---

## 9. 실습 템플릿의 보안 리스크와 실무 개선

| 실습용 설정(제공 YAML) | 위험/한계 | 운영 환경 개선 방향 |
|---|---|---|
| SSH `0.0.0.0/0` | 무차별 접속 시도 노출 | 신뢰 IP 제한, SSM Session Manager 검토 |
| 고정된 root 암호 및 root 로그인 허용 | 자격 증명 유출·공격 위험 | root SSH 차단, 키/역할 기반 접근 |
| EC2에 공인 IP + HTTP 직접 허용 | ALB/WAF 우회 가능 | EC2 Private Subnet, SG에서 ALB SG만 허용 |
| DB 암호가 UserData에 평문 | 자격 증명 노출 위험 | Secrets Manager/SSM Parameter Store 및 IAM 권한 설계 |
| `chmod 777` | 과도한 파일 쓰기 권한 | 최소 권한, 필요한 소유자/권한만 부여 |
| `allow_url_include=on` | 위험한 PHP 기능 허용 | 운영 환경에서는 비활성화 |
| HTTP 80 | 평문 전송 | HTTPS 443 + 인증서(ACM 등) |
| 외부 ZIP/스크립트 무검증 다운로드 | 공급망/무결성 위험 | 검증된 버전·해시·출처 고정 |
| Amazon Linux 2 AMI | 2026-06-30 지원 종료 | 지원 중인 OS/런타임으로 마이그레이션 |
| VPN용 EC2 라우터 | Source/Dest Check, 경로 설정 필요 | 체크 비활성화 여부 및 양방향 경로 검증 |

### 가장 중요한 WAF 우회 구조

```text
[클라이언트] ---> [ALB + WAF] ---> [DVWA EC2]   (WAF 검사 경로)
       |
       +-------------------------> [EC2 Public IP] (직접 접근 시 WAF 우회)
```

**핵심:** ALB에 WAF를 붙였더라도 **웹 서버 자체가 인터넷에 직접 열려 있으면** ALB를 거치지 않는 경로가 존재할 수 있다. 실무에서는 웹 서버 접근을 ALB Security Group으로 제한하고 가능하면 Private Subnet에 배치한다.

> **비용/안전:** 실습 종료 후 ALB, EC2, 관련 유료 리소스와 WAF Web ACL 등의 잔존 여부를 확인한다. DVWA는 의도적으로 취약하므로 인터넷에 장기간 노출하지 않는다. 스택 삭제 전 콘솔에서 별도로 생성한 리소스의 연결 관계를 확인한다.

---

## 10. 자주 나오는 실무·면접 Q&A

**Q1. CloudFormation과 Terraform은 어떤 공통점이 있나요?**  
A. 둘 다 IaC(Infrastructure as Code)로 인프라를 선언적으로 정의하고 재현 가능하게 배포한다. CloudFormation은 AWS 네이티브 서비스이며 Terraform은 여러 공급자를 지원한다.

**Q2. SG 인바운드 80을 열면 SQL Injection을 막을 수 있나요?**  
A. 아니다. SG는 L3/L4 수준의 접근 제어이며 SQL 구문 내용을 분석하지 않는다. WAF 또는 애플리케이션에서 처리해야 한다.

**Q3. SG와 NACL의 가장 큰 차이는?**  
A. SG는 Stateful, NACL은 Stateless이며, 적용 범위와 규칙 처리 방식도 다르다.

**Q4. WAF가 403을 반환하면 무조건 WAF가 막은 건가요?**  
A. 아니다. 기본 Block 응답이 403일 수 있지만 다른 계층도 403을 반환한다. WAF 로그에서 `BLOCK` 및 매칭 규칙을 확인한다.

**Q5. Command Injection의 `;`와 `&&` 차이는?**  
A. `;`는 앞 명령 성공 여부와 관계없이 다음 명령을 실행하고, `&&`는 앞 명령이 성공했을 때만 실행한다.

**Q6. SQL Injection과 XSS의 차이는?**  
A. SQLi는 DB 쿼리 처리 로직을 악용하고, XSS는 웹페이지를 보는 사용자의 브라우저에서 스크립트가 실행되도록 악용한다.

**Q7. ALB Target Group의 Stickiness가 왜 필요한가요?**  
A. 서버별 세션 저장소가 독립적일 때 동일 클라이언트를 가급적 같은 서버로 보내 로그인 상태 유지에 도움이 된다. 장기적으로는 공유 세션 저장소 등도 검토한다.

**Q8. WAF를 ALB에 연결했는데도 EC2에 직접 접근할 수 있다면?**  
A. ALB/WAF 우회 경로가 될 수 있다. EC2의 인터넷 직접 접근을 막고 ALB를 통해서만 트래픽을 허용해야 한다.

**Q9. VPN 구성에서 UDP 500과 4500은?**  
A. UDP 500은 IKE, UDP 4500은 IPsec NAT-T에서 사용된다. ESP는 별도의 IP 프로토콜 번호 50이다.

**Q10. CloudFormation 스택 생성 후 콘솔에서 SG 규칙을 수정하면 YAML도 바뀌나요?**  
A. 아니다. 템플릿과 실제 리소스 사이에 드리프트가 발생할 수 있으므로 Drift Detection 등을 활용해 차이를 확인한다.

**Q11. AWS Shield와 AWS WAF는 같은 서비스인가요?**  
A. 아니다. Shield는 DDoS 보호, WAF는 웹 요청 검사 및 필터링에 초점을 둔다.

**Q12. 왜 WAF 규칙을 처음에는 Count로 운영하나요?**  
A. 정상 요청의 오탐 가능성을 먼저 관찰하여 서비스 장애를 줄이기 위해서다.

---

## 11. 트러블슈팅 치트시트

| 증상 | 우선 확인할 것 |
|---|---|
| EC2 간 Ping 실패 | 대상 SG ICMP 인바운드, NACL, OS 방화벽, 경로 |
| SSH 실패 | 대상 SG TCP 22, 인증 방식, SSHD, 네트워크 경로 |
| `curl` HTTP 실패 | 대상 SG TCP 80, Apache 상태, 경로, ALB/타깃 상태 |
| ALB에서 5xx | Target Group Healthy, EC2 웹 서비스, 헬스 체크, 타깃 포트 |
| DVWA 로그인 유지 안 됨 | ALB Stickiness, 세션 쿠키, 서버별 세션/DB 상태 |
| WAF 규칙이 안 먹음 | Web ACL과 ALB 연결, Rule 우선순위/Action, 검사 위치, 인코딩/변환 |
| 정상 요청도 403 | 너무 광범위한 문자열(`/`, `or` 등), WAF Sampled Requests |
| VPN 터널 미연결 | IKE/PSK, UDP 500/4500, 상대 IP, 로그, 방화벽 |
| VPN 터널은 연결됐지만 통신 불가 | 라우트, Source/Dest Check, SG/NACL, OS forwarding |

### 검증용 기본 명령어

```bash
ip addr
ip route
sudo systemctl status httpd
sudo systemctl status mariadb
curl -I http://<실습-ALB-DNS>/login.php
ping -c 4 <실습-대상-IP>
sudo tcpdump -ni any 'udp port 500 or udp port 4500'
```

> 명령어는 상황별 예시다. VPN 소프트웨어/OS 버전, 실제 설치 상태에 따라 결과와 명령이 달라질 수 있다.

---

## 12. 실습 경험을 면접에서 설명하는 예시

> “CloudFormation 템플릿을 이용해 VPC, Public/Private Subnet, EC2, ALB 기반 실습 환경을 배포했습니다. Security Group의 인바운드 규칙을 바꿔가며 SSH, HTTP, ICMP 통신 차이를 관찰했고, Libreswan 기반 VPN 구성에 필요한 게이트웨이 설정도 학습했습니다. 이후 DVWA를 이용해 OS Command Injection, SQL Injection, Reflected XSS를 실습하고 AWS WAF & Shield 콘솔에서 웹 공격 탐지·차단 규칙을 구성했습니다. 재시험 과정에서 HTTP 403 Forbidden 응답을 직접 확인했습니다. 이를 통해 네트워크 접근 제어와 애플리케이션 계층 보안의 차이를 이해했습니다.”

※ VPN 터널의 최종 연결 성공 여부, WAF에서 정확히 어떤 규칙이 403을 반환했는지는 제공된 템플릿과 대화만으로는 확인할 수 없으므로 위 진술에 단정적으로 넣지 않았다.

---

## 13. 오늘의 복습 체크리스트

- [ ] MyVPC17·18, MyVPC23, MyVPC24의 역할을 각각 설명할 수 있다.
- [ ] `!Ref`, `!Sub`, `DependsOn`, `Fn::Base64`의 역할을 설명할 수 있다.
- [ ] VPN에서 UDP 500/4500, IP forwarding, Source/Dest Check가 중요한 이유를 안다.
- [ ] SG의 Stateful과 NACL의 Stateless 차이를 설명할 수 있다.
- [ ] ALB, Target Group, Listener, Health Check, Stickiness를 구분할 수 있다.
- [ ] Command Injection의 `;`, `&&`, `||`, `|`를 구분할 수 있다.
- [ ] SQLi와 XSS가 각각 어디에서 문제가 발생하는지 설명할 수 있다.
- [ ] WAF의 검사 위치(URI, Query String, Body)를 구분할 수 있다.
- [ ] 단순 문자열 규칙의 오탐 위험을 설명할 수 있다.
- [ ] `403 Forbidden`과 WAF 로그의 `BLOCK` 확인을 구분할 수 있다.
- [ ] EC2 공인 IP가 ALB/WAF 우회 경로가 될 수 있음을 설명할 수 있다.
- [ ] 실습 종료 후 취약한 DVWA와 유료 AWS 리소스를 정리할 수 있다.

---

## 14. 다음 복습 때 보강하면 좋은 증빙

1. **VPN:** 실제 터널 상태, AWS VPN 연결 및 라우팅 설정 화면
2. **Security Group:** 인바운드 규칙 변경 전/후 화면과 각 `curl`·`ping` 결과
3. **WAF:** Web ACL 이름, 각 규칙의 검사 대상/우선순위/액션, ALB 연결 화면
4. **WAF 차단:** Sampled Requests 또는 로그의 `BLOCK`/매칭 규칙, 정상 요청 결과
5. **ALB:** Target Group Healthy 및 Stickiness 설정 화면

이 항목들이 추가되면 단순 복습 노트에서 **실습 증빙 기반 포트폴리오 문서**로 발전시킬 수 있다.

---

**최종 암기 문장**  
**“CloudFormation으로 만들고, VPN으로 연결하고, Security Group으로 접근을 제어하며, ALB로 분산하고, WAF로 웹 공격을 검사한다.”**
