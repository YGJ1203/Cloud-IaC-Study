# AWS CloudFormation + Terraform 실습 총정리

> **오늘의 핵심:** CloudFormation으로 NLB 및 고가용성 3-Tier 아키텍처를
> 구성하고, Terraform으로 VPC부터 EC2까지 직접 선언하여
> `init → plan → apply → destroy` 전체 IaC 생명주기를 실습했다.

------------------------------------------------------------------------

## 1. 오늘의 전체 흐름

``` text
CloudFormation
├─ VPC06 / VPC07
│  └─ NLB + EC2 Web Server
│
└─ VPC08
   ├─ Multi-AZ Public / Private Subnet
   ├─ NAT Gateway
   ├─ ALB
   ├─ Launch Template
   ├─ Auto Scaling Group
   └─ Aurora MySQL

Terraform
├─ AWS Provider / Key Pair / AMI Data Source
├─ VPC
├─ Internet Gateway
├─ Public Subnet
├─ Route Table
├─ Security Group
├─ ENI
├─ EC2 + User Data
└─ init → plan → apply → destroy
```

------------------------------------------------------------------------

# Part 1. CloudFormation

## 2. VPC06 / VPC07 + NLB 구성

### VPC06

``` text
MyVPC06              10.0.0.0/16
└─ MyPublic1Subnet   10.0.1.0/24
   ├─ Public IP 할당
   ├─ MyPublic1Routing
   │  └─ 0.0.0.0/0 → MyIGW1
   ├─ MyPublic1Secugroup
   │  └─ HTTP / HTTPS / SSH / ICMP
   └─ MyWeb1
      └─ 10.0.1.101
```

### VPC07

``` text
MyVPC07              172.16.0.0/16
└─ MyPublic2Subnet   172.16.1.0/24
   ├─ MyWeb2         172.16.1.102
   ├─ MyWeb3         172.16.1.103
   └─ NLB
      └─ Target Group
         ├─ MyWeb2:80
         └─ MyWeb3:80
```

### NLB 핵심

-   `AWS::ElasticLoadBalancingV2::TargetGroup`
-   Protocol: `TCP`
-   Port: `80`
-   Target: MyWeb2 / MyWeb3
-   Internet-facing Network Load Balancer
-   Listener가 TCP/80 요청을 Target Group으로 전달

### NLB 분산 확인

``` bash
for i in {1..100}; \
do curl http://<NLB-DNS-NAME> \
| grep MyWeb ; done | sort | uniq -c
```

반복 요청 후 Web Server별 응답 횟수를 집계하여 로드밸런싱을 확인한다.

------------------------------------------------------------------------

# 3. VPC08 --- Multi-AZ 3-Tier Architecture

## 전체 구조

``` text
                         Internet
                            │
                            ▼
                           IGW
                            │
              ┌─────────────┴─────────────┐
              │                           │
       Public Subnet 1             Public Subnet 2
        10.0.1.0/24                 10.0.2.0/24
              │                           │
           NAT GW1                     NAT GW2
              │                           │
              ▼                           ▼
      Private Subnet 1            Private Subnet 2
       10.0.100.0/24               10.0.200.0/24
              │                           │
              └──────────┬────────────────┘
                         │
                  Auto Scaling Group
                    EC2 4 ~ 6대
                         ▲
                         │
                    Target Group
                         ▲
                         │
                        ALB
                         ▲
                         │
                      Internet

                  Aurora MySQL Cluster
                    ├─ MyDB1 (2a)
                    └─ MyDB2 (2c)
```

## Public Subnet

Public Subnet의 기본 경로:

``` text
0.0.0.0/0 → Internet Gateway
```

주요 구성:

-   `MyPublic1Subnet` --- `10.0.1.0/24`
-   `MyPublic2Subnet` --- `10.0.2.0/24`
-   Public IP 자동 할당
-   각 Public Subnet에 NAT Gateway 배치
-   ALB는 두 Public Subnet 사용

## Private Subnet

``` text
MyPrivate1Subnet → 10.0.100.0/24
MyPrivate2Subnet → 10.0.200.0/24
```

Public IP를 할당하지 않는다.

Private Route Table의 기본 경로:

``` text
Private EC2
   ↓
0.0.0.0/0
   ↓
NAT Gateway
   ↓
Internet Gateway
   ↓
Internet
```

### 핵심 비교

``` text
Public Subnet  → 0.0.0.0/0 → IGW
Private Subnet → 0.0.0.0/0 → NAT Gateway
```

------------------------------------------------------------------------

# 4. ALB

구성:

``` text
Internet
   ↓
ALB
   ↓
Listener : HTTP/80
   ↓
Target Group
   ↓
Auto Scaling EC2
```

주요 리소스:

-   `MyALBtargetgroup`
-   `MyALB`
-   `MyALBlistner`

ALB는 Application Layer에서 HTTP 요청을 받아 Target Group으로 전달한다.

------------------------------------------------------------------------

# 5. Launch Template + Auto Scaling

## Launch Template

EC2를 **어떻게 생성할 것인지** 정의한다.

주요 설정:

``` text
AMI           → LatestAmiId
Instance Type → t3.micro
Key Pair      → KeyName
Public IP     → false
User Data     → Apache 자동 설치
```

## Auto Scaling Group

EC2를 **몇 대, 어디에 배치하고 유지할 것인지** 관리한다.

``` text
MinSize         = 4
DesiredCapacity = 4
MaxSize         = 6
```

Private Subnet 2개에 EC2를 배치하고 ALB Target Group과 연결한다.

``` text
Launch Template
       ↓
Auto Scaling Group
       ↓
EC2 생성
       ↓
Target Group 등록
       ↓
ALB 요청 전달
```

------------------------------------------------------------------------

# 6. Aurora MySQL

## DB Security Group

MySQL:

``` text
TCP / 3306
```

실습에서는 `0.0.0.0/0`으로 설정했지만 운영 환경에서는 DB를 전체 인터넷에
개방하지 않고 Application Tier의 Security Group 등 필요한 Source만
허용하는 것이 바람직하다.

## DB Subnet Group

``` text
MyPrivate1Subnet
MyPrivate2Subnet
```

서로 다른 AZ의 Private Subnet을 DB 배치 영역으로 구성한다.

## Aurora 구조

``` text
MyDBCluster
│
├─ MyDB1
│  └─ ap-northeast-2a
│
└─ MyDB2
   └─ ap-northeast-2c
```

주요 설정:

``` text
Engine        = aurora-mysql
EngineVersion = 8.0.mysql_aurora.3.10.3
DatabaseName  = testdb
```

### DBCluster vs DBInstance

-   **DBCluster**: Aurora 클러스터의 논리적 단위
-   **DBInstance**: 클러스터에 속해 DB 연산을 수행하는 인스턴스

> 실습 코드에 DB 비밀번호가 평문으로 포함되었으나 실제 운영/IaC
> 저장소에서는 Secrets Manager 등 별도 비밀 관리 방식을 사용해야 한다.

------------------------------------------------------------------------

# Part 2. Terraform

## 7. Terraform 개발 환경

오늘 구성한 환경:

-   Terraform 설치
-   AWS CLI 확인
-   PuTTY 공개키 / 개인키 준비
-   Sublime Text Terraform 편집 환경 구성
-   작업 디렉터리: `C:\terraform\01_tf`

초기화:

``` bash
terraform init
```

AWS Provider 설치 및 `.terraform.lock.hcl` 생성 확인.

------------------------------------------------------------------------

# 8. Provider

``` hcl
provider "aws" {
  region = "ap-northeast-2"
}
```

Terraform이 AWS 서울 리전을 대상으로 작업한다.

------------------------------------------------------------------------

# 9. Key Pair

``` hcl
resource "aws_key_pair" "tf_keypair" {
  key_name   = "tf_keypair"
  public_key = file("C:\\sshkey\\tf_keypair.pub")

  tags = {
    Name = "tf_keypair"
  }
}
```

`file()`을 이용해 로컬 공개키 파일 내용을 읽어 AWS Key Pair로 등록한다.

------------------------------------------------------------------------

# 10. AMI Data Source

``` hcl
data "aws_ami" "LatestAmi" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }

  owners = ["amazon"]
}
```

### Resource vs Data Source

``` text
resource → 생성 / 변경 / 관리
data     → 기존 정보 조회
```

EC2에서는 다음처럼 조회 결과를 사용한다.

``` hcl
ami = data.aws_ami.LatestAmi.id
```

------------------------------------------------------------------------

# 11. Terraform VPC

``` text
MyVPC04          10.0.0.0/16
│
├─ MyIGW
│
└─ MyPublicSubnet
   ├─ 10.0.1.0/24
   ├─ ap-northeast-2a
   └─ Public IP 자동 할당
```

VPC 참조:

``` hcl
vpc_id = aws_vpc.MyVPC04.id
```

Terraform 참조 표현식의 기본 형태:

``` text
ResourceType.LocalName.Attribute
```

예:

``` hcl
aws_vpc.MyVPC04.id
aws_subnet.MyPublicSubnet.id
aws_internet_gateway.MyIGW.id
```

------------------------------------------------------------------------

# 12. Route Table

``` hcl
route {
  cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.MyIGW.id
}
```

흐름:

``` text
MyPublicSubnet
      ↓
Route Table Association
      ↓
MyPublicRouting
      ↓
0.0.0.0/0
      ↓
MyIGW
      ↓
Internet
```

## `depends_on`

``` hcl
depends_on = [aws_internet_gateway.MyIGW]
```

명시적 의존성을 지정한다.

하지만:

``` hcl
gateway_id = aws_internet_gateway.MyIGW.id
```

처럼 다른 리소스를 직접 참조하면 Terraform이 암시적 의존성을 자동으로
파악할 수 있다.

------------------------------------------------------------------------

# 13. Security Group

허용한 Inbound:

  Protocol     Port 용도
  ---------- ------ -------
  TCP            80 HTTP
  TCP           443 HTTPS
  TCP            22 SSH
  ICMP          All Ping

Outbound:

``` text
All Traffic → 0.0.0.0/0
```

> SSH `0.0.0.0/0` 허용은 실습 목적이며 운영에서는 관리 IP 제한 또는 SSM
> 등의 방식을 고려한다.

------------------------------------------------------------------------

# 14. ENI --- 고정 Private IP

``` hcl
resource "aws_network_interface" "MyWebPrivateAddress" {
  subnet_id       = aws_subnet.MyPublicSubnet.id
  private_ips     = ["10.0.1.101"]
  security_groups = [aws_security_group.MyPublicSecugroup.id]
}
```

구조:

``` text
MyPublicSubnet
      ↓
MyWebPrivateAddress (ENI)
      ├─ 10.0.1.101
      └─ MyPublicSecugroup
      ↓
MyWeb
```

EC2에는 생성한 ENI를 Primary Network Interface로 연결한다.

------------------------------------------------------------------------

# 15. EC2 MyWeb

``` hcl
resource "aws_instance" "MyWeb" {
  depends_on    = [aws_internet_gateway.MyIGW]
  ami           = data.aws_ami.LatestAmi.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.tf_keypair.key_name

  primary_network_interface {
    network_interface_id = aws_network_interface.MyWebPrivateAddress.id
  }
}
```

핵심 참조:

``` text
AMI      ← data.aws_ami.LatestAmi.id
Key Pair ← aws_key_pair.tf_keypair.key_name
ENI      ← aws_network_interface.MyWebPrivateAddress.id
```

------------------------------------------------------------------------

# 16. User Data

EC2 생성 후 자동으로:

``` text
Hostname 설정
      ↓
SSH 설정
      ↓
Apache 설치
      ↓
httpd 시작/활성화
      ↓
index.html 생성
```

실습 내용:

``` bash
hostnamectl --static set-hostname MyWeb
yum install -y httpd
systemctl enable --now httpd
echo "<h1>MyWeb test web page</h1>" > /var/www/html/index.html
```

`user_data_replace_on_change = true`도 설정했다.

> Root 비밀번호 로그인 허용과 평문 비밀번호는 학습 실습용으로만 보고
> 실제 운영 환경에서는 키 기반 인증, SSM, 최소 권한 등의 보안 구성을
> 사용한다.

------------------------------------------------------------------------

# 17. 최종 Terraform Architecture

``` text
                       Internet
                          │
                          ▼
                        MyIGW
                          │
                    0.0.0.0/0
                          │
                          ▼
                  MyPublicRouting
                          │
                 Route Association
                          │
                          ▼
                   MyPublicSubnet
                    10.0.1.0/24
                          │
                          ▼
                MyWebPrivateAddress
                       ENI
                    10.0.1.101
                          │
                 MyPublicSecugroup
                HTTP/HTTPS/SSH/ICMP
                          │
                          ▼
                        MyWeb
                      t3.micro
                   Amazon Linux 2
                       Apache
```

`terraform plan` 최종 결과:

``` text
Plan: 9 to add, 0 to change, 0 to destroy.
```

------------------------------------------------------------------------

# 18. Terraform 명령어 핵심

## init

``` bash
terraform init
```

-   Working Directory 초기화
-   Provider 다운로드
-   Module / Backend 준비
-   `.terraform.lock.hcl` 생성

## fmt

``` bash
terraform fmt
```

HCL 코드 형식을 표준 스타일로 정리한다.

## validate

``` bash
terraform validate
```

Terraform 구성의 문법 및 내부 일관성을 검증한다.

## plan

``` bash
terraform plan
```

현재 상태와 원하는 상태를 비교해 실행 계획을 출력한다.

``` text
+ create
~ update
- destroy
```

## apply

``` bash
terraform apply
```

Plan에 따른 변경을 실제 인프라에 반영한다.

## destroy

``` bash
terraform destroy
```

Terraform이 관리하는 리소스를 제거한다.

실습:

``` bash
terraform destroy -auto-approve
```

`-auto-approve`는 확인 프롬프트를 생략하므로 특히 운영 환경에서는
주의한다.

------------------------------------------------------------------------

# 19. 오늘 만난 Terraform 오류 🤡

## Unsupported block type

잘못된 코드:

``` hcl
list "aws_internet_gateway" "MyIGW" {
```

또는:

``` hcl
resourece "aws_internet_gateway" "MyIGW" {
```

올바른 코드:

``` hcl
resource "aws_internet_gateway" "MyIGW" {
```

### 핵심

Terraform의 최상위 블록 타입을 정확하게 작성해야 한다.

------------------------------------------------------------------------

## Missing item separator

잘못된 코드:

``` hcl
depends_on = [aws_internet_gateway MyIGW]
```

올바른 코드:

``` hcl
depends_on = [aws_internet_gateway.MyIGW]
```

Terraform Resource Reference는 `.`으로 연결한다.

``` text
ResourceType.LocalName.Attribute
```

------------------------------------------------------------------------

# 20. CloudFormation ↔ Terraform 비교

  CloudFormation                Terraform
  ----------------------------- ------------------------------------
  YAML / JSON                   HCL
  `AWS::EC2::VPC`               `aws_vpc`
  `AWS::EC2::Subnet`            `aws_subnet`
  `AWS::EC2::InternetGateway`   `aws_internet_gateway`
  `AWS::EC2::RouteTable`        `aws_route_table`
  `AWS::EC2::SecurityGroup`     `aws_security_group`
  `AWS::EC2::Instance`          `aws_instance`
  `!Ref MyVPC`                  `aws_vpc.MyVPC04.id`
  `!Ref KeyName`                `aws_key_pair.tf_keypair.key_name`
  AMI Parameter                 `data.aws_ami.LatestAmi.id`
  `DependsOn`                   `depends_on`

### 가장 중요한 관점

``` text
AWS Architecture는 동일하다.

CloudFormation
      ↓
YAML/JSON으로 선언

Terraform
      ↓
HCL로 선언
```

도구와 문법이 달라져도 VPC, Subnet, Routing, Security Group, EC2라는 AWS
인프라 원리는 그대로다.

------------------------------------------------------------------------

# 21. Terraform State

Terraform은 실제 인프라와 자신이 관리하는 리소스 상태를 추적한다.

대표 파일:

``` text
terraform.tfstate
```

주의:

``` text
.terraform/            → Git 커밋 X
*.tfstate              → Git 커밋 X
*.tfstate.*            → Git 커밋 X
민감정보 포함 *.tfvars → Git 커밋 주의

*.tf                   → 코드로 관리
.terraform.lock.hcl    → 일반적으로 버전 관리
.gitignore             → 버전 관리
```

State에는 민감정보가 포함될 가능성이 있으므로 저장소에 무분별하게
업로드하면 안 된다.

------------------------------------------------------------------------

# 22. 실무 / 면접 핵심 Q&A

### Q1. Terraform이란?

Infrastructure as Code 도구로, HCL을 이용하여 원하는 인프라 상태를
선언하고 인프라를 생성·변경·관리한다.

### Q2. `resource`와 `data`의 차이는?

-   `resource`: Terraform이 생성하거나 관리할 리소스
-   `data`: 기존 인프라나 외부 정보를 조회

### Q3. `terraform plan`의 목적은?

실제 변경 전에 현재 상태와 구성 파일을 비교하여 어떤 리소스가
생성·변경·삭제될지 확인한다.

### Q4. `(known after apply)`는 오류인가?

아니다. 실제 리소스를 생성한 후에야 AWS에서 결정되는 ID, ARN 등의
값이라는 의미다.

### Q5. Terraform에서 리소스를 어떻게 참조하는가?

기본 형태:

``` text
ResourceType.LocalName.Attribute
```

예:

``` hcl
aws_vpc.MyVPC04.id
```

### Q6. `depends_on`은 무엇인가?

리소스 간 명시적 의존성을 정의한다. 다른 리소스 속성을 직접 참조하면
Terraform이 암시적 의존성을 자동으로 파악하는 경우가 많다.

### Q7. Launch Template과 Auto Scaling Group의 차이는?

-   Launch Template: EC2를 **어떻게 만들지** 정의
-   Auto Scaling Group: EC2를 **몇 대 만들고 어디에 배치하며 유지할지**
    관리

### Q8. Public Subnet과 Private Subnet의 인터넷 경로 차이는?

``` text
Public  → IGW
Private → NAT Gateway → IGW
```

### Q9. ALB와 Target Group의 관계는?

ALB Listener가 받은 요청을 설정된 규칙에 따라 Target Group으로 전달하고
Target Group이 등록된 EC2 등으로 요청을 분산한다.

### Q10. Terraform의 기본 작업 흐름은?

``` text
init
 ↓
fmt
 ↓
validate
 ↓
plan
 ↓
apply
 ↓
state 추적
 ↓
destroy
```

------------------------------------------------------------------------

# 23. 오늘 반드시 기억할 10가지

1.  **CloudFormation과 Terraform은 도구가 달라도 AWS 인프라 원리는
    동일하다.**
2.  `resource`는 관리/생성, `data`는 조회다.
3.  Terraform 참조는 `ResourceType.LocalName.Attribute` 형태다.
4.  `plan`은 실제 변경 전에 실행 계획을 확인하는 단계다.
5.  `(known after apply)`는 오류가 아니다.
6.  Terraform은 참조 관계를 통해 의존성을 자동으로 파악할 수 있다.
7.  Public Subnet의 인터넷 경로는 IGW가 핵심이다.
8.  Private Subnet의 Outbound 인터넷 접근에는 NAT Gateway를 사용할 수
    있다.
9.  ALB → Target Group → ASG EC2 흐름을 이해한다.
10. `terraform.tfstate`는 Terraform 운영의 핵심이며 민감하게 관리해야
    한다.

------------------------------------------------------------------------

# 24. 오늘의 한 문장

> **CloudFormation으로 AWS 고가용성 3-Tier 아키텍처를 구성하고,
> Terraform HCL로 VPC·Routing·Security Group·ENI·EC2를 선언하여
> `init → plan → apply → destroy` 전체 IaC 생명주기를 직접 실습했다.**

