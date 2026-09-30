# Day01 - AWS 기초: IAM · VPC · EC2

> AWS 첫날 실습 핵심 정리\
> **계정/IAM → VPC 네트워크 → Security Group → Key Pair → EC2**

------------------------------------------------------------------------

## 1. 오늘의 핵심

오늘은 AWS의 기본 구조를 확인하고 직접 계정을 생성한 뒤, **IAM / VPC /
EC2를 이용하여 첫 AWS 인프라를 구성**했다.

기존에 학습한 네트워크와 Linux/VMware 개념이 AWS에서는 어떤 서비스로
구현되는지 연결해서 이해하는 것이 핵심이다.

``` text
기존 인프라 개념                 AWS
------------------------------------------------
가상 네트워크                   VPC
서브넷                          Subnet
라우팅 테이블                   Route Table
인터넷 연결 관문                Internet Gateway
방화벽/접근 제어                Security Group
가상 머신                       EC2
SSH 인증키                      Key Pair
사용자/권한 관리                IAM
```

------------------------------------------------------------------------

## 2. draw.io와 AWS Architecture

draw.io(diagrams.net)의 AWS 아이콘을 이용하면 클라우드 아키텍처를
시각적으로 표현할 수 있다.

오늘 확인한 주요 구성 요소:

-   AWS Cloud
-   Region
-   Availability Zone(AZ)
-   VPC
-   Public / Private Subnet
-   Internet Gateway
-   Route Table
-   Security Group
-   EC2
-   Database 계층

### 구조 예시

``` text
AWS Cloud
└─ Region: ap-northeast-2
   └─ VPC: 10.0.0.0/16
      ├─ Availability Zone A
      │  ├─ Public Subnet
      │  └─ Private Subnet
      │
      └─ Availability Zone C
         ├─ Public Subnet
         └─ Private Subnet
```

**포인트:** 실제 구축 전에 draw.io로 아키텍처를 설계하면 IP 대역, AZ
분리, Public/Private 영역 및 서비스 간 관계를 한눈에 파악할 수 있다.

------------------------------------------------------------------------

## 3. AWS 계정과 IAM

### Root Account

AWS 계정을 생성할 때 만들어지는 계정 자체의 최고 권한 계정이다.

-   매우 강력한 권한 보유
-   일반적인 관리 작업에 상시 사용하는 방식은 피한다.
-   MFA 설정 권장
-   일상적인 AWS 작업은 적절한 IAM 사용자 또는 Role을 활용

### IAM

**Identity and Access Management**

AWS 리소스에 접근할 수 있는 사용자 및 권한을 관리한다.

핵심 개념:

``` text
IAM User
   ↓
Permission / Policy
   ↓
AWS Resource
```

앞으로 기억할 키워드:

-   인증(Authentication): 누구인가?
-   인가(Authorization): 무엇을 할 수 있는가?
-   최소 권한 원칙(Least Privilege): 필요한 권한만 부여

------------------------------------------------------------------------

## 4. VPC

**Virtual Private Cloud**

AWS 내부에 사용자가 구성하는 논리적으로 격리된 가상 네트워크이다.

### 오늘 구성

``` text
MyVPC01
CIDR: 10.0.0.0/16
```

`/16` VPC 내부를 여러 `/24` Subnet 등으로 분할하여 사용할 수 있다.

예:

``` text
10.0.0.0/16
├─ 10.0.1.0/24    Public
├─ 10.0.2.0/24    Public
├─ 10.0.100.0/24  Private
└─ 10.0.200.0/24  Private
```

기존 네트워크에서 배운 **CIDR/Subnetting 지식이 그대로 활용된다.**

------------------------------------------------------------------------

## 5. Internet Gateway

### MyIGW

Internet Gateway(IGW)는 VPC와 인터넷 사이의 통신을 가능하게 하는 VPC
구성 요소이다.

개념 구조:

``` text
Internet
   │
  IGW
   │
  VPC
   │
Public Subnet
   │
  EC2
```

단, **IGW를 VPC에 연결했다는 사실만으로 EC2 인터넷 통신이 자동 완성되는
것은 아니다.**

Route Table의 경로와 EC2의 Public IPv4, Security Group 등의 조건도 함께
확인해야 한다.

------------------------------------------------------------------------

## 6. Public Subnet

### 오늘 구성

``` text
MyPublicSubnet
10.0.1.0/24
```

Public Subnet의 핵심은 이름이 `Public`이라서가 아니라, 연결된 Route
Table에 인터넷으로 향하는 경로가 존재하는지 여부이다.

대표적인 경로:

``` text
Destination     Target
10.0.0.0/16    local
0.0.0.0/0      igw-xxxxxxxx
```

-   `local` : VPC 내부 통신
-   `0.0.0.0/0 → IGW` : 목적지를 더 구체적으로 매칭하지 못한 인터넷 방향
    IPv4 트래픽

------------------------------------------------------------------------

## 7. Route Table

### MyPublicRouting

Subnet에서 발생한 패킷을 어느 방향으로 전달할지 결정하는 라우팅
정보이다.

기존 네트워크 학습과 연결:

``` text
Cisco/Linux Routing Table
          ↕
AWS Route Table
```

AWS에서도 결국 핵심 질문은 같다.

> **목적지 네트워크로 가려면 어디로 보내야 하는가?**

------------------------------------------------------------------------

## 8. Security Group

### MyPublicSecugroup

EC2 같은 리소스의 트래픽을 제어하는 **상태 기반(Stateful) 가상
방화벽**이다.

오늘 허용한 주요 트래픽:

``` text
HTTP    TCP 80
HTTPS   TCP 443
SSH     TCP 22
ICMP
```

### 핵심

Security Group은 **Allow 규칙 중심**으로 구성한다.

Stateful이므로 허용된 요청 트래픽에 대한 응답 트래픽을 별도의 반대 방향
규칙으로 일일이 허용할 필요가 없는 특성이 있다.

향후 **NACL(Network ACL)**을 배우면 차이를 비교할 것.

``` text
Security Group → 주로 리소스/ENI 수준, Stateful
NACL           → Subnet 수준, Stateless
```

------------------------------------------------------------------------

## 9. EC2

**Elastic Compute Cloud**

AWS에서 가상 서버를 제공하는 핵심 컴퓨팅 서비스이다.

기존 VMware 경험과 연결하면:

``` text
VMware VM
   ≈
AWS EC2 Instance
```

EC2 생성 시 앞으로 반복해서 확인할 항목:

-   AMI
-   Instance Type
-   VPC
-   Subnet
-   Public IP
-   Security Group
-   Storage(EBS)
-   Key Pair

### IP 주소

EC2에서는 다음 정보를 구분해서 보는 것이 중요하다.

``` text
Private IPv4
Public IPv4
Public DNS
```

Private IP는 VPC 내부 통신에 사용되고, Public IPv4/Public DNS는
인터넷에서 인스턴스로 접근할 때 사용될 수 있다.

------------------------------------------------------------------------

## 10. Key Pair

EC2 Linux 인스턴스 SSH 접속 등에 사용하는 공개키 기반 인증 구성이다.

``` text
Client
  │
Private Key (.pem)
  │
  ↓
EC2
Public Key
```

### 보안 주의

다음 정보는 절대 GitHub 등에 업로드하지 않는다.

``` text
*.pem
AWS Access Key
AWS Secret Access Key
계정 비밀번호
Windows Administrator Password
민감한 인증정보가 포함된 설정 파일
```

`.gitignore` 활용 및 커밋 전 `git status`, `git diff` 확인 습관을
들인다.

> 이미 외부에 노출한 실제 비밀번호나 키가 있다면 재사용하지 말고 즉시
> 변경/폐기한다.

------------------------------------------------------------------------

## 11. 오늘 구축 흐름

``` text
AWS 계정 생성
     ↓
Root / IAM 개념 확인
     ↓
VPC 생성
10.0.0.0/16
     ↓
Internet Gateway 생성 및 연결
     ↓
Public Subnet 생성
10.0.1.0/24
     ↓
Route Table 구성
     ↓
Security Group 구성
HTTP / HTTPS / SSH / ICMP
     ↓
Key Pair 생성
     ↓
EC2 생성
     ↓
Private IP / Public IP / DNS 확인
```

------------------------------------------------------------------------

## 12. 기존 학습 내용과 연결

### Network → AWS

``` text
Subnetting  ─────→ VPC / Subnet
Routing     ─────→ Route Table
Default GW ─────→ AWS 네트워크 경로 개념
ACL/FW     ─────→ Security Group / NACL
NAT        ─────→ NAT Gateway 등
```

### Linux / VMware → AWS

``` text
VM 생성       → EC2
Disk          → EBS
SSH           → EC2 + Key Pair
Firewall      → Security Group
```

### Docker / Kubernetes → 향후 AWS

``` text
Docker        → ECR / ECS 등
Kubernetes    → EKS
Load Balancer → ELB 계열 서비스
Storage       → EBS / EFS / S3 등
```

------------------------------------------------------------------------

## 13. 꼭 기억할 면접/복습 포인트

**Q. VPC란?**\
AWS에서 사용자가 구성할 수 있는 논리적으로 격리된 가상 네트워크이다.

**Q. Public Subnet을 결정하는 핵심 요소는?**\
연결된 Route Table에서 인터넷 게이트웨이로 향하는 경로가 구성되어
있는지를 확인해야 한다. 실제 인터넷 통신에는 Public IP 등 추가 조건도
필요하다.

**Q. Internet Gateway의 역할은?**\
VPC와 인터넷 사이의 통신을 지원한다.

**Q. Security Group의 특징은?**\
AWS 리소스의 인바운드/아웃바운드 트래픽을 제어하는 Stateful 가상
방화벽이다.

**Q. IAM은 왜 사용하는가?**\
AWS 사용자와 권한을 관리하고 필요한 대상에게 필요한 권한만 부여하기 위해
사용한다.

**Q. Root 계정을 평소 작업에 사용하지 않는 이유는?**\
계정 전체에 영향을 줄 수 있는 매우 강력한 권한을 가지므로 노출 및 오작동
위험을 줄이기 위해 일상적인 작업에서는 적절한 IAM 권한을 사용하는 것이
좋다.

------------------------------------------------------------------------

## 14. Day01 한 줄 정리

> **AWS의 시작은 서비스를 외우는 것이 아니라, VPC 안에서 네트워크와
> 권한, 컴퓨팅 리소스가 어떻게 연결되는지를 이해하는 것이다.**

``` text
IAM
 │
AWS Cloud
 └─ Region
    └─ VPC
       ├─ IGW
       ├─ Subnet
       ├─ Route Table
       ├─ Security Group
       └─ EC2
```

------------------------------------------------------------------------

## 다음 학습에서 주목할 내용

-   Public / Private Subnet 차이
-   NAT Gateway
-   Elastic IP
-   NACL
-   EBS
-   ALB / ELB
-   Multi-AZ
-   IAM Policy / Role

**Network → Linux → Docker → Kubernetes → AWS ☁️**

이제 기존에 배운 인프라 지식이 AWS 서비스와 본격적으로 연결되기
시작한다.
