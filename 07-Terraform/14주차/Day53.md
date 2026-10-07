# AWS Terraform 종합 아키텍처 핵심 정리

> VPC · NAT Gateway · NLB · VPC Endpoint · Endpoint Service · AWS
> PrivateLink · ALB · Auto Scaling · Aurora MySQL · Terraform Dependency

------------------------------------------------------------------------

## 1. 오늘의 전체 학습 흐름

``` text
Terraform
   │
   ├─ MyVPC05
   │   └─ Public / Private Subnet + NAT Gateway
   │
   ├─ MyVPC06 / MyVPC07
   │   └─ NLB + Target Group + EC2
   │
   ├─ VPC Endpoint / Endpoint Service
   │   └─ AWS PrivateLink 기반 사설 서비스 연결
   │
   └─ MyVPC08
       ├─ Multi-AZ Public / Private Subnet
       ├─ NAT Gateway × 2
       ├─ ALB
       ├─ Launch Template
       ├─ Auto Scaling Group
       └─ Aurora MySQL Cluster
```

핵심은 **AWS 리소스를 단순히 하나씩 생성하는 것에서 끝나는 것이 아니라,
Terraform의 리소스 참조를 통해 전체 인프라의 관계를 코드로 선언하는
것**이다.

------------------------------------------------------------------------

# 2. MyVPC05 --- Public / Private Subnet + NAT Gateway

## 구성

  리소스           설정
  ---------------- ----------------------------------
  VPC              `10.0.0.0/16`
  Public Subnet    `10.0.1.0/24`, ap-northeast-2a
  Private Subnet   `10.0.100.0/24`, ap-northeast-2a
  Public EC2       `10.0.1.101`
  Private EC2      `10.0.100.101`
  IGW              Public 인터넷 연결
  NAT Gateway      Private Subnet의 외부 통신
  Public Route     `0.0.0.0/0 → IGW`
  Private Route    `0.0.0.0/0 → NAT Gateway`

## 구조

``` text
Internet
   │
   ▼
Internet Gateway
   │
   ▼
Public Subnet (10.0.1.0/24)
   ├─ Public EC2
   └─ NAT Gateway + EIP
             │
             ▼
      Private Route Table
             │
             ▼
Private Subnet (10.0.100.0/24)
             │
             └─ Private EC2
```

## 핵심

-   Public Subnet은 `0.0.0.0/0 → IGW` 경로를 가진다.
-   Public EC2는 Public IP를 이용해 인터넷과 직접 통신할 수 있다.
-   Private EC2는 Public IP를 갖지 않는다.
-   Private Subnet에서 인터넷으로 **나가는 통신**이 필요하면 NAT
    Gateway를 이용할 수 있다.
-   NAT Gateway는 Public Subnet에 배치하고 EIP를 연결한다.
-   NAT Gateway는 외부에서 Private EC2로 직접 들어오기 위한 장치가
    아니다.

------------------------------------------------------------------------

# 3. MyVPC06 / MyVPC07 --- 다중 VPC와 NLB

## MyVPC06

``` text
VPC       : 10.0.0.0/16
Subnet    : 10.0.1.0/24
AZ        : ap-northeast-2a
MyWeb1    : 10.0.1.101
```

## MyVPC07

``` text
VPC       : 172.16.0.0/16
Subnet    : 172.16.1.0/24
AZ        : ap-northeast-2a
MyWeb2    : 172.16.1.102
MyWeb3    : 172.16.1.103
```

MyVPC07의 MyWeb2/MyWeb3를 NLB Target으로 구성한다.

``` text
               NLB
                │
          Target Group
           ┌────┴────┐
           ▼         ▼
        MyWeb2     MyWeb3
         .102       .103
```

## NLB 주요 Terraform 리소스

``` text
aws_lb_target_group
aws_lb_target_group_attachment
aws_lb
aws_lb_listener
```

역할:

-   **Target Group**: 실제 요청을 받을 대상 집합
-   **Target Group Attachment**: EC2 등의 Target을 Target Group에 등록
-   **NLB**: 클라이언트 트래픽을 수신
-   **Listener**: 특정 포트/프로토콜의 요청을 Target Group으로 전달

------------------------------------------------------------------------

# 4. NLB 동작 검증

NLB DNS로 반복 요청:

``` bash
for i in {1..100}; \
do curl http://<NLB-DNS> \
| grep MyWeb ; done | sort | uniq -c
```

목적:

``` text
Client
  │
  ├─ Request 1 ─→ NLB ─→ MyWeb2
  ├─ Request 2 ─→ NLB ─→ MyWeb3
  └─ ...
```

100회의 요청 결과에서 MyWeb2/MyWeb3 응답 횟수를 확인하여 실제 Target
전달 동작을 검증할 수 있다.

> 단, 요청 횟수가 반드시 정확히 50:50으로 분배된다는 의미는 아니다.

------------------------------------------------------------------------

# 5. VPC Endpoint란?

VPC Endpoint는 VPC의 리소스가 특정 AWS 서비스 또는 Endpoint Service에
**인터넷 경로 없이 사설 연결**할 수 있도록 제공되는 기능이다.

대표 유형:

1.  **Interface Endpoint**
2.  **Gateway Endpoint**
3.  기타 서비스별 Endpoint 유형

오늘 실습에서 중요한 것은 **Interface Endpoint와 Endpoint
Service(PrivateLink)**이다.

------------------------------------------------------------------------

# 6. Interface VPC Endpoint

Interface Endpoint는 VPC의 Subnet에 ENI(Elastic Network Interface)를
생성하여 대상 서비스로 연결한다.

개념 구조:

``` text
Client EC2
   │
   ▼
Interface VPC Endpoint
   │
   ▼
AWS PrivateLink
   │
   ▼
AWS Service 또는 Endpoint Service
```

특징:

-   사설 IP 기반 접근 가능
-   인터넷 Gateway/NAT Gateway를 통하지 않고 서비스에 접근 가능
-   Endpoint에 Security Group을 적용할 수 있음
-   DNS 이름을 통해 접근 가능

------------------------------------------------------------------------

# 7. AWS 서비스용 Interface Endpoint

CloudFormation Endpoint DNS 확인 예:

``` bash
dig +short vpce-xxxxxxxx.cloudformation.ap-northeast-2.vpce.amazonaws.com

dig +short vpce-xxxxxxxx-ap-northeast-2a.cloudformation.ap-northeast-2.vpce.amazonaws.com

dig +short vpce-xxxxxxxx-ap-northeast-2c.cloudformation.ap-northeast-2.vpce.amazonaws.com
```

공용 서비스 DNS와 비교:

``` bash
dig +short cloudformation.ap-northeast-2.amazonaws.com
dig +short cloudformation.ap-northeast-2.api.aws
```

### 핵심

`dig`를 이용하면 DNS 이름이 실제 어떤 IP로 해석되는지 확인할 수 있다.

Interface Endpoint 사용 시 Endpoint의 DNS 이름과 AZ별 DNS 이름을
확인하면서 **Private Endpoint가 생성한 네트워크 인터페이스와 DNS
Resolution**을 이해하는 것이 중요하다.

------------------------------------------------------------------------

# 8. Endpoint Service란?

Endpoint Service는 **내가 제공하는 서비스를 다른 VPC에서 PrivateLink를
통해 사설로 이용할 수 있도록 공개하는 기능**이다.

핵심 구조:

``` text
서비스 제공자 VPC
─────────────────────────

MyWeb2 ─┐
        ├─ Target Group
MyWeb3 ─┘
          │
          ▼
         NLB
          │
          ▼
   Endpoint Service
          │
==========│================ AWS PrivateLink
          │
          ▼
 Interface Endpoint
          │
          ▼
       Client VPC
```

### 매우 중요한 관계

``` text
Endpoint Service
      │
      ▼
     NLB
      │
      ▼
 Target Group
      │
   ┌──┴──┐
   ▼     ▼
 Web2   Web3
```

Endpoint Service 자체가 웹 서버로 트래픽을 직접 보내는 것이 아니다.

**Endpoint Service → NLB → Target Group → Target** 구조로 이해한다.

------------------------------------------------------------------------

# 9. VPC Endpoint vs Endpoint Service

  구분          VPC Endpoint             Endpoint Service
  ------------- ------------------------ ------------------------
  관점          서비스 소비자            서비스 제공자
  목적          Private 서비스에 접속    Private 서비스를 제공
  핵심 리소스   Interface Endpoint/ENI   Endpoint Service + NLB
  PrivateLink   이용                     서비스 제공
  대표 흐름     Client → Endpoint        Endpoint Service → NLB

암기:

> **Endpoint = 서비스를 사용하는 쪽**
>
> **Endpoint Service = 서비스를 제공하는 쪽**

------------------------------------------------------------------------

# 10. PrivateLink 핵심

AWS PrivateLink를 사용하면 서로 다른 VPC 사이에서 서비스를 사설 네트워크
방식으로 제공/소비할 수 있다.

``` text
Consumer VPC
     │
Interface Endpoint
     │
     │ AWS PrivateLink
     ▼
Endpoint Service
     │
    NLB
     │
 Target Group
     │
 Application
```

장점:

-   서비스 제공자의 전체 VPC 네트워크를 직접 노출할 필요가 없음
-   인터넷을 통하지 않는 사설 연결 가능
-   서비스 단위 연결에 적합
-   VPC 간 CIDR 중복 문제를 피해야 하는 일반적인 라우팅 연결과 다른
    서비스 지향 접근 방식

------------------------------------------------------------------------

# 11. Endpoint를 통한 NLB 서비스 검증

Endpoint DNS로 반복 요청:

``` bash
for i in {1..100}; \
do curl <VPC-ENDPOINT-DNS> \
| grep MyWeb ; done | sort | uniq -c
```

AZ 전용 Endpoint DNS 테스트:

``` bash
for i in {1..100}; \
do curl <AZ-SPECIFIC-VPC-ENDPOINT-DNS> \
| grep MyWeb ; done | sort | uniq -c
```

이 실습의 의미:

``` text
Client
  │
  ▼
VPC Endpoint
  │
  ▼
PrivateLink
  │
  ▼
Endpoint Service
  │
  ▼
NLB
  │
 ┌┴┐
 ▼ ▼
W2 W3
```

즉 단순히 NLB가 동작하는 것뿐 아니라 **PrivateLink 경로를 통해 실제
서비스에 도달하는지 확인**하는 테스트이다.

------------------------------------------------------------------------

# 12. ping 테스트에서 주의할 점

Endpoint DNS에 대해:

``` bash
ping -c 1 <endpoint-dns>
```

를 실행했다고 해서 ping 성공 여부만으로 Endpoint 서비스의 정상/비정상을
판단하면 안 된다.

ICMP 응답이 허용되지 않는 서비스도 있기 때문이다.

따라서 실제 서비스 검증은 서비스 프로토콜에 맞게 진행한다.

예:

``` bash
curl http://...
curl https://...
```

DNS 확인은:

``` bash
dig +short ...
```

로 수행한다.

------------------------------------------------------------------------

# 13. MyVPC08 --- Multi-AZ 종합 아키텍처

``` text
                         Internet
                            │
                           IGW
                            │
                  ┌─────────┴─────────┐
                  ▼                   ▼
           Public Subnet 1      Public Subnet 2
              2a                    2c
                  │                   │
              NAT GW1             NAT GW2
                  │                   │
                  ▼                   ▼
          Private Subnet 1     Private Subnet 2
                  │                   │
                  └────────┬──────────┘
                           │
                      ASG Instances
                           ▲
                           │
Internet ────────→ ALB ────┘

                           │
                           ▼
                     Aurora MySQL
                    ┌────────────┐
                    ▼            ▼
                  MyDB1        MyDB2
                   2a           2c
```

------------------------------------------------------------------------

# 14. ALB 구성

Terraform 주요 리소스:

``` text
aws_lb_target_group
aws_lb
aws_lb_listener
```

흐름:

``` text
Client
  │
  ▼
 ALB
  │
Listener
  │
  ▼
Target Group
  │
  ▼
EC2 / ASG
```

ALB는 HTTP/HTTPS 기반 L7 Load Balancing에 적합하다.

------------------------------------------------------------------------

# 15. Launch Template + Auto Scaling Group

Launch Template:

``` text
AMI
Instance Type
Key Pair
Security Group
User Data
```

ASG:

``` text
desired_capacity = 4
min_size         = 4
max_size         = 6
```

Private Subnet 두 개에 인스턴스를 배치:

``` text
ASG
 ├─ Private Subnet 1 (2a)
 └─ Private Subnet 2 (2c)
```

ALB Target Group과 ASG를 Attachment로 연결한다.

``` text
ALB
 ↓
Target Group
 ↓
ASG
 ↓
EC2 Instances
```

------------------------------------------------------------------------

# 16. NAT Gateway와 ASG

Private Subnet의 EC2가 User Data 실행 과정에서 인터넷 패키지 저장소 등에
접근해야 한다면 NAT Gateway 경로가 필요할 수 있다.

예:

``` text
Private EC2
    │
Private Route Table
    │
NAT Gateway
    │
Internet Gateway
    │
Internet
```

Multi-AZ 구조에서는 각 AZ에 NAT Gateway를 두어 AZ 독립성을 높이는 구성이
가능하다.

> NAT Gateway는 비용이 발생하므로 실습 종료 후 반드시 삭제 상태를
> 확인한다.

------------------------------------------------------------------------

# 17. Aurora MySQL 구성

구조:

``` text
DB Subnet Group
      │
      ▼
Aurora Cluster
   ┌───────┐
   ▼       ▼
 MyDB1   MyDB2
  2a      2c
```

Cluster:

``` hcl
engine         = "aurora-mysql"
engine_version = "8.0.mysql_aurora.3.10.3"
database_name  = "testdb"
master_username = "dbadmin"
```

Instance:

``` hcl
instance_class = "db.t3.medium"
```

### 매우 중요

`db.t3.medium`은 일반적인 Provisioned Aurora 구성에서 **DB Cluster
Instance의 클래스**이다.

``` text
aws_rds_cluster
     │
     ├─ aws_rds_cluster_instance MyDB1
     │       └─ db.t3.medium
     │
     └─ aws_rds_cluster_instance MyDB2
             └─ db.t3.medium
```

------------------------------------------------------------------------

# 18. 오늘 발생한 Aurora 오류

오류:

``` text
InvalidParameterCombination:
DBClusterInstanceClass isn't supported for DB engine aurora-mysql
```

원인:

Cluster에 다음 설정을 넣어 발생:

``` hcl
db_cluster_instance_class = "db.t3.medium"
```

해결:

Cluster와 Instance를 분리한다.

``` hcl
resource "aws_rds_cluster" "MyDBCluster" {
  engine = "aurora-mysql"
  ...
}

resource "aws_rds_cluster_instance" "MyDB1" {
  cluster_identifier = aws_rds_cluster.MyDBCluster.id
  instance_class     = "db.t3.medium"
  ...
}
```

------------------------------------------------------------------------

# 19. RDS Destroy가 오래 걸린 이유

실제 경험:

``` text
mydb-1 / mydb-2
      │
      ▼
Deleting...
      │
   약 9분
      │
      ▼
Instance 삭제 완료
      │
      ▼
Cluster 삭제 시작
```

Terraform 출력:

``` text
Still destroying...
Still destroying...
Still destroying...
```

이 메시지가 반복되어도 AWS Console에서 리소스 상태가 `Deleting`이라면
실제 AWS 작업이 진행 중일 수 있다.

### 핵심

> Terraform이 멈춘 것처럼 보여도 AWS의 실제 리소스 상태를 함께 확인한다.

RDS/Aurora는 EC2보다 생성/삭제에 시간이 오래 걸릴 수 있다.

------------------------------------------------------------------------

# 20. Terraform 의존성 핵심

Terraform에는 크게 두 종류의 의존성이 있다.

## ① Implicit Dependency --- 암시적 의존성

다른 리소스의 값을 직접 참조하면 Terraform이 자동으로 의존성을 파악한다.

``` hcl
vpc_id = aws_vpc.MyVPC08.id
```

``` text
MyVPC08
   ↓
Resource
```

또는:

``` hcl
cluster_identifier = aws_rds_cluster.MyDBCluster.id
```

``` text
MyDBCluster
     ↓
MyDB1
```

이 경우 일반적으로 `depends_on`은 필요 없다.

------------------------------------------------------------------------

## ② Explicit Dependency --- 명시적 의존성

코드상 직접적인 값 참조는 없지만 실제 동작상 특정 리소스가 먼저
준비되어야 할 때 사용한다.

``` hcl
depends_on = [
  aws_xxx.example
]
```

핵심:

> **참조하면 Terraform이 자동으로 판단한다.**
>
> **참조가 없지만 순서가 반드시 필요할 때 `depends_on`을 고려한다.**

------------------------------------------------------------------------

# 21. 오늘 코드의 depends_on 판단

  -----------------------------------------------------------------------
  위치                    의존 대상               판단
  ----------------------- ----------------------- -----------------------
  Public Route Table      IGW                     직접 `gateway_id` 참조
                                                  → 중복

  Private Route Table     NAT GW                  직접 참조 → 중복

  Launch Template         SG                      SG ID 직접 참조 → 중복

  ASG                     Launch Template         LT ID/Version 직접 참조
                                                  → 중복

  RDS Cluster             DB SG                   SG ID 직접 참조 → 중복

  RDS Cluster             DB Subnet Group         이름 직접 참조 → 중복

  MyDB1                   Cluster                 Cluster ID 직접 참조 →
                                                  중복

  MyDB2                   MyDB1                   실제 explicit
                                                  dependency이나 순차
                                                  생성이 필요 없다면
                                                  불필요

  ASG                     NAT Gateway             User Data 인터넷 의존
                                                  등을 강제하려는
                                                  의도라면 고려 가능
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# 22. Terraform Dependency Graph

전체 구조를 단순화하면:

``` text
VPC
 │
 ├─ IGW
 │   └─ Public Route
 │
 ├─ Public Subnet
 │   └─ NAT Gateway
 │       └─ Private Route
 │
 ├─ Security Group
 │
 ├─ ALB
 │   └─ Listener
 │
 ├─ Launch Template
 │   └─ ASG
 │       └─ Target Group Attachment
 │
 └─ DB Subnet Group
     └─ Aurora Cluster
         ├─ MyDB1
         └─ MyDB2
```

Terraform은 이런 관계를 분석해 생성 순서를 결정한다.

삭제 시에는 대체로 반대 방향으로 처리한다.

``` text
생성:
Cluster → Instance

삭제:
Instance → Cluster
```

------------------------------------------------------------------------

# 23. DB Security Group 개선 포인트

실습 코드:

``` hcl
ingress {
  from_port   = 3306
  to_port     = 3306
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
```

학습 환경에서는 동작 확인을 위해 사용할 수 있지만 실제 설계에서는 DB를
모든 IPv4에 열기보다 Application EC2의 Security Group만 허용하는 것이
좋다.

예:

``` hcl
ingress {
  from_port       = 3306
  to_port         = 3306
  protocol        = "tcp"
  security_groups = [aws_security_group.MySecugroup.id]
}
```

구조:

``` text
Internet
   │
   ▼
 ALB
   │
   ▼
Application EC2
   │
   │ SG → SG 허용
   ▼
Aurora :3306
```

------------------------------------------------------------------------

# 24. 실무 관점 보안 체크

## SSH

``` text
22/tcp → 0.0.0.0/0
```

은 실습에서는 편하지만 운영 환경에서는 관리 IP, VPN, Bastion, SSM
Session Manager 등의 방식으로 제한하는 것이 좋다.

## DB

``` text
3306/tcp → 0.0.0.0/0
```

보다 Application Security Group을 Source로 제한한다.

## DB Password

다음처럼 `.tf`에 비밀번호를 직접 작성한 뒤 GitHub에 올리지 않는다.

``` hcl
master_password = "..."
```

실무에서는 Terraform 변수의 민감값 처리, AWS Secrets Manager 등 적절한
비밀정보 관리 방식을 사용한다.

------------------------------------------------------------------------

# 25. NLB vs ALB

  -----------------------------------------------------------------------
  항목                    NLB                     ALB
  ----------------------- ----------------------- -----------------------
  계층                    L4                      L7

  주요 프로토콜           TCP/TLS/UDP 계열        HTTP/HTTPS

  판단 기준               IP/Port 중심            HTTP 요청 정보 중심

  PrivateLink Endpoint    대표적으로 사용         일반적인 웹
  Service                                         애플리케이션 LB에 적합

  오늘 실습               Endpoint Service        ASG Web Frontend
                          Backend                 
  -----------------------------------------------------------------------

오늘 아키텍처에서 기억할 흐름:

``` text
PrivateLink
   ↓
Endpoint Service
   ↓
NLB
```

그리고:

``` text
Internet
   ↓
ALB
   ↓
ASG
```

------------------------------------------------------------------------

# 26. 면접 핵심 Q&A

### Q1. Terraform에서 `depends_on`은 언제 사용합니까?

Terraform이 리소스 참조를 통해 의존성을 자동으로 추론할 수 없는 상황에서
명시적으로 생성/삭제 순서를 표현할 때 사용합니다. 다른 리소스의 ID, ARN,
Name 등을 직접 참조한다면 일반적으로 암시적 의존성이 이미 생성되므로
불필요한 `depends_on`은 피합니다.

### Q2. NAT Gateway의 목적은?

Private Subnet의 인스턴스가 Public IP 없이 외부 인터넷으로 나가는 통신을
할 수 있도록 합니다. NAT Gateway는 Public Subnet에 배치하고 일반적으로
EIP와 연결합니다.

### Q3. VPC Endpoint를 사용하는 이유는?

인터넷 Gateway나 NAT Gateway를 통한 인터넷 경로 대신 AWS 네트워크 내부의
사설 연결을 통해 지원되는 AWS 서비스 또는 Endpoint Service에 접근하기
위해 사용합니다.

### Q4. Endpoint와 Endpoint Service의 차이는?

Endpoint는 서비스를 **소비하는 쪽**, Endpoint Service는 PrivateLink를
통해 서비스를 **제공하는 쪽**입니다.

### Q5. Endpoint Service 뒤에 NLB를 사용하는 이유는?

PrivateLink Endpoint Service의 서비스 제공 구조에서 NLB를 통해 Backend
Target으로 트래픽을 전달할 수 있습니다.

### Q6. Interface Endpoint란?

Subnet에 Endpoint ENI를 생성하고 사설 IP를 통해 지원 서비스 또는
Endpoint Service에 접근할 수 있도록 하는 VPC Endpoint 유형입니다.

### Q7. ALB와 NLB의 차이는?

ALB는 HTTP/HTTPS 기반 L7 처리에 적합하고, NLB는 TCP/TLS/UDP 등 L4 트래픽
처리에 적합합니다. 서비스 목적과 프로토콜에 따라 선택합니다.

### Q8. Aurora Cluster와 Cluster Instance의 차이는?

Cluster는 Aurora DB의 논리적 클러스터 설정을 관리하고, Cluster
Instance는 실제 DB 연산을 수행하는 인스턴스입니다. `db.t3.medium` 같은
Instance Class는 Cluster Instance에 지정합니다.

### Q9. Terraform에서 RDS 삭제가 오래 걸릴 때 어떻게 확인합니까?

Terraform의 `Still destroying...` 메시지만 보지 않고 AWS Console의 RDS
상태도 확인합니다. 실제 상태가 `Deleting`이라면 AWS에서 삭제 작업이 진행
중일 수 있으므로 완료를 기다립니다.

### Q10. Security Group에서 다른 Security Group을 Source로 사용할 수 있습니까?

가능합니다. 예를 들어 Aurora DB의 3306 포트를 `0.0.0.0/0`에 개방하는
대신 Application EC2가 사용하는 Security Group을 Source로 지정하여 접근
범위를 제한할 수 있습니다.

------------------------------------------------------------------------

# 27. 시험 / 면접 초압축 암기

``` text
Public Subnet
→ IGW Route 필요

Private Subnet 인터넷 Outbound
→ NAT Gateway

NAT Gateway
→ Public Subnet + EIP

ALB
→ L7 / HTTP·HTTPS

NLB
→ L4 / TCP·TLS·UDP

VPC Endpoint
→ Private 접근점 / 소비자

Endpoint Service
→ Private 서비스 제공자

PrivateLink
→ Endpoint ↔ Endpoint Service 사설 연결

Endpoint Service Backend
→ NLB → Target Group → Target

ASG
→ 자동 인스턴스 수 관리

Launch Template
→ EC2 생성 설정 Template

Aurora Cluster
→ 논리적 DB Cluster

Aurora Cluster Instance
→ 실제 DB Instance / Instance Class

Terraform 직접 리소스 참조
→ Implicit Dependency

depends_on
→ Explicit Dependency
```

------------------------------------------------------------------------

# 28. 오늘의 트러블슈팅 총정리

## Case 1 --- Aurora Cluster Instance Class 오류

``` text
DBClusterInstanceClass isn't supported for DB engine aurora-mysql
```

### 원인

Cluster와 Cluster Instance의 역할 혼동.

### 해결

`db.t3.medium` 등의 Instance Class를 `aws_rds_cluster_instance`에 지정.

------------------------------------------------------------------------

## Case 2 --- RDS Creating 중 Destroy

``` text
InvalidDBInstanceState:
Instance mydb-1 is currently creating
```

### 원인

AWS에서 DB Instance 생성 작업이 끝나지 않은 상태에서 삭제 작업이 요청됨.

### 대응

AWS Console에서 실제 DB 상태 확인 후 상태 전환을 기다린다.

------------------------------------------------------------------------

## Case 3 --- Still destroying 반복

``` text
Still destroying... [XmXs elapsed]
```

### 확인 결과

DB Instance 삭제에 약 9분이 소요된 뒤 Cluster 삭제 단계로 진행.

### 교훈

> Terraform의 출력과 AWS Console의 실제 리소스 상태를 함께 확인한다.

------------------------------------------------------------------------

# 29. 오늘의 최종 아키텍처 키워드

``` text
Terraform
│
├─ Provider / Data Source / Key Pair
├─ VPC
├─ IGW
├─ Public / Private Subnet
├─ Route Table
├─ NAT Gateway
├─ Security Group
├─ NLB
├─ Target Group
├─ VPC Endpoint
├─ Endpoint Service
├─ AWS PrivateLink
├─ ALB
├─ Launch Template
├─ Auto Scaling Group
├─ DB Subnet Group
├─ Aurora Cluster
├─ Aurora Cluster Instance
└─ Dependency Graph
```

------------------------------------------------------------------------

# 30. 한 문장 총정리

> **Terraform으로 Multi-AZ VPC 네트워크를 구성하고, NAT Gateway를 통한
> Private Subnet의 Outbound 통신, NLB와 PrivateLink 기반
> Endpoint/Endpoint Service의 사설 서비스 연결, ALB와 Auto Scaling 기반
> 애플리케이션 계층, Aurora MySQL 기반 데이터베이스 계층까지 구축하면서
> Terraform의 암시적·명시적 의존성과 AWS 리소스의 생성/삭제 상태를 함께
> 학습했다.**

------------------------------------------------------------------------

## 최종 복습 포인트 ⭐

1.  **VPC → Subnet → Route → Gateway** 흐름을 먼저 그린다.
2.  Public과 Private Subnet의 차이를 **Route 관점**에서 설명한다.
3.  NAT Gateway의 위치와 역할을 설명할 수 있어야 한다.
4.  **Endpoint = 소비자 / Endpoint Service = 제공자**를 구분한다.
5.  **PrivateLink → Endpoint Service → NLB → Target** 흐름을 외운다.
6.  ALB와 NLB의 계층 및 사용 목적을 구분한다.
7.  Launch Template과 ASG의 관계를 설명한다.
8.  Aurora Cluster와 Cluster Instance를 구분한다.
9.  직접 참조가 있으면 Terraform이 의존성을 자동 생성한다.
10. `depends_on`은 자동 추론이 안 되는 의존관계에 제한적으로 사용한다.
11. `Still creating/destroying` 발생 시 AWS Console의 실제 상태를 함께
    확인한다.
12. 실습 종료 후 **NAT Gateway, ALB/NLB, Aurora 등 과금 리소스가 실제로
    삭제되었는지 확인한다.**

> **핵심 흐름:**\
> `Network → Routing → Private Connectivity → Load Balancing → Auto Scaling → Database → Dependency → Troubleshooting`
