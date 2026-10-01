# AWS Day 02 - S3, VPC, ALB, Auto Scaling, RDS & Aurora

## 1. 오늘의 핵심

오늘은 AWS에서 단순히 개별 서비스를 생성하는 것을 넘어, **VPC 내부에 Public/Private Subnet을 구성하고 EC2, NAT Gateway, ALB, Auto Scaling, RDS/Aurora를 연결하는 전체적인 웹 서비스 인프라 구조**를 실습했다.

주요 학습 내용은 다음과 같다.

- Amazon S3 / Bucket / Object
- AWS CLI를 이용한 S3 접근
- VPC 및 Subnet 구성
- Internet Gateway
- Route Table
- Security Group
- NAT Gateway / Elastic IP
- EC2
- Application Load Balancer
- Target Group
- Launch Template
- Auto Scaling Group
- RDS / Aurora
- DB Subnet Group
- AWS 실습 후 과금 리소스 정리

---

# 2. Amazon S3

## S3란?

**Amazon S3(Simple Storage Service)** 는 AWS의 Object Storage 서비스이다.

```text
Amazon S3
    │
    └── Bucket
          ├── index.html
          ├── test.txt
          └── images/logo.png
```

S3에 저장되는 실제 데이터 단위를 **Object**라고 한다.

### 핵심 용어

| 용어 | 의미 |
|---|---|
| S3 | AWS Object Storage 서비스 |
| Bucket | Object를 저장하는 논리적 공간 |
| Object | S3에 저장되는 데이터 |
| Key | Bucket 내부 Object를 식별하는 이름 |

> S3는 NFS와 같은 일반적인 파일시스템이 아니라 **Object Storage**이다.

---

# 3. AWS CLI

Windows 환경에 AWS CLI를 설치하여 CMD에서 AWS 리소스에 접근했다.

## 버전 확인

```bash
aws --version
```

## AWS CLI 초기 설정

```bash
aws configure
```

설정 항목:

```text
AWS Access Key ID
AWS Secret Access Key
Default region
Default output format
```

> Access Key와 Secret Access Key는 절대 GitHub, 문서, 스크린샷 등에 공개하지 않는다.

서울 Region:

```text
ap-northeast-2
```

## S3 Bucket 확인

전체 Bucket 목록:

```bash
aws s3 ls
```

특정 Bucket 내부 Object 확인:

```bash
aws s3 ls s3://ray589-mybucket-1
```

### 개념

```text
aws s3 ls
    ↓
Bucket 목록 확인

aws s3 ls s3://BucketName
    ↓
해당 Bucket 내부 Object 확인
```

---

# 4. 기본 VPC 구성

## MyVPC01

```text
VPC Name     : MyVPC01
IPv4 CIDR    : 10.0.0.0/16
IPv6         : 사용하지 않음
Tenancy      : Default
```

VPC는 AWS에서 사용하는 **논리적으로 격리된 가상 네트워크 공간**이다.

```text
MyVPC01
10.0.0.0/16
    │
    └── Subnet
```

---

# 5. Internet Gateway

## MyIGW

Internet Gateway를 생성하고 `MyVPC01`에 연결하였다.

```text
Internet
   │
 MyIGW
   │
MyVPC01
```

Internet Gateway는 **VPC와 인터넷을 연결하는 Gateway**이다.

단, IGW를 VPC에 연결했다고 해서 Subnet이 자동으로 Public Subnet이 되는 것은 아니다.

Route Table에 Internet Gateway를 대상으로 하는 경로가 필요하다.

---

# 6. Public Subnet

## MyPublicSubnet

```text
VPC      : MyVPC01
Subnet   : MyPublicSubnet
AZ       : ap-northeast-2a
CIDR     : 10.0.1.0/24
```

구조:

```text
MyVPC01
10.0.0.0/16
    │
    └── MyPublicSubnet
        10.0.1.0/24
```

VPC의 `/16` 주소 공간 내부에서 `/24` Subnet을 생성하였다.

---

# 7. Public Route Table

## MyPublicRouting

```text
Name : MyPublicRouting
VPC  : MyVPC01
```

`MyPublicSubnet`을 Route Table에 연결하였다.

주요 Routing 정보:

```text
Destination       Target

10.0.0.0/16       local
0.0.0.0/0         MyIGW
```

### 핵심

```text
0.0.0.0/0 → Internet Gateway
```

는 VPC 내부 목적지가 아닌 IPv4 트래픽을 Internet Gateway로 전달하는 **Default Route**이다.

기존 네트워크에서 학습한 Default Route와 개념적으로 연결된다.

```text
Public Subnet
     │
Route Table
     │
0.0.0.0/0
     │
Internet Gateway
     │
 Internet
```

---

# 8. Security Group

## MyPublicSecugroup

```text
Name        : MyPublicSecugroup
Description : Permit http, https, ssh and icmp
VPC         : MyVPC01
```

실습용 Inbound Rule:

| Type | Port | Source |
|---|---:|---|
| HTTP | 80 | Anywhere IPv4 |
| HTTPS | 443 | Anywhere IPv4 |
| SSH | 22 | Anywhere IPv4 |
| ICMP | All | Anywhere IPv4 |

Security Group은 AWS 리소스에 적용하는 **Stateful 가상 방화벽**이다.

> 실습에서는 SSH를 Anywhere로 허용했지만 실제 환경에서는 관리자 IP 등 필요한 Source로 제한하는 것이 안전하다.

---

# 9. Public / Private Subnet 구조

두 번째 실습에서는 다음과 같이 Public/Private Subnet을 분리하였다.

```text
VPC
10.0.0.0/16

├── Public1
│   10.0.1.0/24
│
├── Public2
│   10.0.2.0/24
│
├── Private1
│   10.0.100.0/24
│
└── Private2
    10.0.200.0/24
```

Public Subnet에는 외부 연결을 위한 AWS 리소스를 배치하고, Web EC2 및 DB 등은 Private 영역에 배치하는 구조를 실습하였다.

---

# 10. NAT Gateway

Private Subnet의 EC2는 Public IPv4 주소가 없어도 외부 인터넷 접근이 필요할 수 있다.

예:

```bash
yum update
yum install
curl
```

이때 NAT Gateway를 사용할 수 있다.

```text
Private EC2
10.0.100.x
      │
      ▼
NAT Gateway
      │
 Elastic IP
      │
      ▼
Internet Gateway
      │
      ▼
Internet
```

Private Route Table:

```text
Destination       Target

10.0.0.0/16       local
0.0.0.0/0         NAT Gateway
```

### 중요

```text
Private EC2 → Internet
```

은 가능하지만 NAT Gateway를 통해 인터넷에서 Private EC2로 임의의 신규 연결을 시작하는 구조는 아니다.

---

# 11. Elastic IP

Elastic IP(EIP)는 AWS에서 할당받아 사용하는 **고정 Public IPv4 주소**이다.

Public NAT Gateway가 인터넷과 통신할 때 EIP를 사용할 수 있다.

```text
Private EC2
    ↓
NAT Gateway
    ↓
Elastic IP
    ↓
Internet
```

---

# 12. Application Load Balancer

ALB를 생성하고 Target Group을 이용해 여러 EC2에 HTTP 트래픽을 분산하였다.

```text
             Internet
                │
                ▼
               ALB
                │
          Target Group
           ┌────┴────┐
           ▼         ▼
         Web1       Web2
```

ALB는 DNS 이름을 통해 접근할 수 있다.

```text
xxxx.ap-northeast-2.elb.amazonaws.com
```

AWS에서는 IP 주소뿐만 아니라 **Endpoint/DNS Name을 이용한 접근**이 매우 중요하다.

---

# 13. Auto Scaling

두 번째 구성에서는 Launch Template과 Auto Scaling Group을 사용하였다.

```text
Launch Template
       │
       ▼
Auto Scaling Group
       │
       ├── EC2
       ├── EC2
       └── EC2
```

## Launch Template

EC2를 생성할 때 사용할 설정을 Template 형태로 정의한다.

## Auto Scaling Group

설정된 정책과 Desired Capacity 등을 기준으로 EC2 인스턴스 수를 관리한다.

부하 테스트:

```bash
yum -y install stress
stress -c 2
```

개념적인 Scale-out 과정:

```text
CPU 부하 증가
     ↓
Metric 확인
     ↓
Scaling 조건 충족
     ↓
Auto Scaling Group
     ↓
EC2 추가 생성
     ↓
Target Group 등록
     ↓
ALB 트래픽 분산
```

### 주의

Auto Scaling Group이 유지되고 Desired Capacity가 설정되어 있다면 EC2를 직접 종료하더라도 ASG가 새로운 EC2를 생성할 수 있다.

---

# 14. Amazon RDS

Amazon RDS는 AWS에서 제공하는 **관리형 관계형 데이터베이스 서비스**이다.

직접 EC2에 DB를 구축하는 경우:

```text
EC2
 ↓
Linux
 ↓
MariaDB / MySQL 설치
 ↓
DB 관리
 ↓
Backup / Patch / HA 관리
```

RDS를 사용하면 AWS가 DB 운영의 여러 관리 작업을 제공한다.

대표적인 엔진:

- MySQL
- PostgreSQL
- MariaDB
- Oracle
- SQL Server
- Aurora

---

# 15. Amazon Aurora

Aurora는 AWS가 개발한 관계형 데이터베이스 엔진으로 MySQL 또는 PostgreSQL 호환 옵션을 제공한다.

```text
Amazon RDS
    │
    └── Aurora
         ├── MySQL Compatible
         └── PostgreSQL Compatible
```

Aurora Cluster 접속 시 Endpoint를 사용할 수 있다.

```bash
mysql -h <AURORA_CLUSTER_ENDPOINT> -u dbadmin -p
```

구조:

```text
Application / EC2
        │
        ▼
Aurora Endpoint
        │
        ▼
Aurora Cluster
```

DB의 IP 주소를 직접 사용하는 것보다 AWS에서 제공하는 Endpoint를 이용하는 구조를 이해하는 것이 중요하다.

---

# 16. DB Subnet Group

RDS/Aurora를 배치할 Subnet들을 묶어 DB Subnet Group을 구성하였다.

```text
DB Subnet Group
     │
     ├── Private Subnet 1
     │
     └── Private Subnet 2
```

일반적으로 서로 다른 Availability Zone의 Subnet을 활용하여 구성한다.

---

# 17. Web SG와 DB SG 분리

웹 서버와 DB에 서로 다른 Security Group을 적용할 수 있다.

```text
Internet
    │
    ▼
   ALB
    │
    ▼
Web Security Group
    │
    │ DB Port
    ▼
DB Security Group
    │
    ▼
RDS / Aurora
```

실제 환경에서는 DB Port를 인터넷 전체에 개방하기보다 **필요한 Application/Web Security Group을 Source로 지정**하는 방식이 유용하다.

---

# 18. 전체 Architecture

```text
                         Internet
                            │
                            ▼
                    Internet Gateway
                            │
                            ▼
                    Public Subnets
                            │
                           ALB
                            │
                      Target Group
                            │
                ┌───────────┴───────────┐
                ▼                       ▼
          Private Subnet 1        Private Subnet 2
               EC2                     EC2
                │                       │
                └───────────┬───────────┘
                            │
                       RDS / Aurora
                            │
                          testdb


Private EC2
    │
    └── NAT Gateway
             │
         Elastic IP
             │
             ▼
          Internet
```

Auto Scaling 적용 시:

```text
Launch Template
       │
       ▼
Auto Scaling Group
       │
       ▼
      EC2
       │
       ▼
Target Group
       │
       ▼
      ALB
```

---

# 19. 기존 학습 내용과 AWS 연결

| 기존 학습 | AWS |
|---|---|
| VMware VM | EC2 |
| 네트워크 | VPC |
| Subnetting | Subnet |
| Routing Table | Route Table |
| Default Route | `0.0.0.0/0` |
| NAT/PAT | NAT Gateway |
| 고정 공인 IP | Elastic IP |
| 방화벽 | Security Group |
| HAProxy | ALB |
| Backend Server | Target Group |
| MariaDB/MySQL | RDS / Aurora |
| 파일 저장 | S3(Object Storage) |
| 서버 확장 개념 | Auto Scaling |

> S3는 NFS와 동일한 파일시스템이 아니라 Object Storage라는 차이에 주의한다.

---

# 20. AWS 비용 및 실습 종료 후 리소스 정리

AWS에서는 리소스를 단순히 생성해 놓는 것만으로도 종류에 따라 비용이 발생할 수 있으므로 실습 후 반드시 확인한다.

## 특히 확인할 리소스

```text
EC2 Instance
NAT Gateway
Elastic IP / Public IPv4
Application Load Balancer
RDS / Aurora
EBS Volume
Snapshot
Auto Scaling Group
```

이번 실습 종료 후 확인:

```text
EC2 Auto Scaling Instances → Terminated
NAT Gateway × 2            → Deleted
Auto Scaling Group         → 삭제 확인
Launch Template            → 삭제 확인
Load Balancer              → 리소스 없음
RDS / Aurora               → 리소스 없음
```

추가로 Elastic IP와 EBS Volume이 불필요하게 남아 있지 않은지 확인한다.

VPC, Subnet, Route Table, Security Group 등과 달리 NAT Gateway, ALB, 실행 중인 EC2, RDS/Aurora 등의 리소스는 비용 측면에서 특히 주의한다.

---

# 21. 오늘의 핵심 흐름

```text
S3
 ↓
AWS CLI
 ↓
VPC
 ↓
Subnet
 ↓
Route Table
 ↓
Internet Gateway
 ↓
Security Group
 ↓
EC2
 ↓
NAT Gateway
 ↓
ALB / Target Group
 ↓
Launch Template
 ↓
Auto Scaling
 ↓
RDS / Aurora
```

오늘의 핵심은 AWS 서비스를 각각 암기하는 것이 아니라,

> **각 서비스가 전체 Architecture에서 어떤 역할을 담당하며 서로 어떻게 연결되는가**

를 이해하는 것이다.

---

# 22. 핵심 암기

```text
VPC
= AWS 가상 네트워크

Subnet
= VPC 내부 네트워크 분할

IGW
= VPC와 인터넷의 Gateway

Route Table
= 트래픽의 이동 경로 결정

Security Group
= Stateful 가상 방화벽

NAT Gateway
= Private Subnet의 Internet Outbound 지원

Elastic IP
= 고정 Public IPv4

EC2
= 가상 서버

ALB
= Application Layer Load Balancer

Target Group
= ALB가 트래픽을 전달할 대상

Launch Template
= EC2 생성 설정 Template

Auto Scaling Group
= EC2 수 자동 관리

S3
= Object Storage

Bucket
= S3 Object 저장 공간

RDS
= 관리형 관계형 Database Service

Aurora
= AWS의 MySQL/PostgreSQL 호환 관계형 DB Engine
```

---

## 한 줄 정리

> **오늘은 VPC의 Public/Private Network를 기반으로 ALB → EC2 → RDS/Aurora 구조를 구성하고, NAT Gateway를 통한 Private Network의 외부 통신 및 Auto Scaling을 통한 EC2 자동 확장까지 실습하였다.**