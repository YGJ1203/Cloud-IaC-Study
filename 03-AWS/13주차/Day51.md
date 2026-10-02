# ☁️ AWS CloudFormation 핵심 정리

> **학습 주제:** AWS CloudFormation을 이용한 VPC 인프라 자동 구축  
> **실습:** MyVPC04 / MyVPC05  
> **핵심:** VPC → Subnet → Routing → Security Group → EC2 → NAT Gateway

---

# 1. CloudFormation이란?

AWS CloudFormation은 AWS 인프라를 **코드로 정의하고 자동으로 생성/관리하는 IaC(Infrastructure as Code) 서비스**이다.

AWS 콘솔에서 직접 VPC, Subnet, EC2 등을 하나씩 생성하는 대신 YAML 또는 JSON 파일에 원하는 인프라 상태를 선언한다.

```text
CloudFormation Template (YAML)
        ↓
CloudFormation Stack
        ↓
AWS Resource 자동 생성
```

예:

```yaml
Resources:
  MyVPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
```

이 코드를 이용하여 VPC를 자동 생성할 수 있다.

---

# 2. CloudFormation 기본 구조

CloudFormation YAML은 대표적으로 다음과 같은 구조를 가진다.

```yaml
Parameters:
  ...

Resources:
  ...
```

## Parameters

스택 생성 시 외부에서 입력받을 값을 정의한다.

```yaml
Parameters:
  KeyName:
    Description: EC2 KeyPair
    Type: AWS::EC2::KeyPair::KeyName
```

EC2에 사용할 Key Pair를 스택 생성 시 선택할 수 있다.

AMI 역시 SSM Parameter Store를 이용하여 지정할 수 있다.

```yaml
LatestAmiId:
  Type: 'AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>'
  Default: '/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2'
```

---

# 3. CloudFormation 핵심 함수 ⭐

## `!Ref`

Parameter 또는 Resource를 참조한다.

```yaml
VpcId: !Ref MyVPC04
```

의미:

```text
MyVPC04 리소스를 참조
```

---

## `!GetAtt`

AWS 리소스의 특정 속성(Attribute)을 가져온다.

```yaml
AllocationId: !GetAtt MyNatGWEIP.AllocationId
```

의미:

```text
MyNatGWEIP
   ↓
AllocationId 속성 조회
   ↓
NAT Gateway에서 사용
```

---

## `!GetAZs`

현재 Region에서 사용할 수 있는 Availability Zone 목록을 가져온다.

```yaml
!GetAZs ''
```

예:

```text
ap-northeast-2a
ap-northeast-2b
ap-northeast-2c
...
```

---

## `!Select`

목록에서 특정 값을 선택한다.

```yaml
AvailabilityZone: !Select [0, !GetAZs '']
```

즉,

```text
현재 Region AZ 목록
        ↓
첫 번째 AZ 선택
```

---

## `DependsOn`

리소스 생성 순서를 명시적으로 지정한다.

```yaml
MyPublicDefault:
  DependsOn: MyIGWattachment
```

의미:

```text
IGW Attachment 완료
        ↓
Default Route 생성
```

---

## `Fn::Base64` + `!Sub`

EC2 UserData 스크립트를 전달할 때 사용한다.

```yaml
UserData:
  Fn::Base64:
    !Sub |
      #!/bin/bash
      yum install -y httpd
      systemctl enable --now httpd
```

EC2가 처음 생성될 때 해당 스크립트가 자동으로 실행된다.

---

# 4. MyVPC04 — Public VPC 구축

## 전체 구조

```text
Internet
   │
   ▼
Internet Gateway
   │
   ▼
MyVPC04
10.0.0.0/16
   │
   ▼
MyPublicSubnet
10.0.1.0/24
   │
   ├── MyPublicRouting
   │       │
   │       └── 0.0.0.0/0 → IGW
   │
   ├── MyPublicSecugroup
   │
   └── MyWeb
           10.0.1.101
           Public IP O
```

---

# 5. VPC

```yaml
MyVPC04:
  Type: AWS::EC2::VPC
  Properties:
    CidrBlock: 10.0.0.0/16
    EnableDnsSupport: 'true'
    EnableDnsHostnames: 'true'
```

VPC 주소:

```text
10.0.0.0/16
```

DNS 기능과 DNS Hostname 기능을 활성화한다.

---

# 6. Internet Gateway

```yaml
MyIGW:
  Type: AWS::EC2::InternetGateway
```

Internet Gateway는 VPC와 인터넷 사이의 연결을 제공한다.

하지만 IGW를 생성하는 것만으로는 부족하다.

VPC에 연결해야 한다.

```yaml
MyIGWattachment:
  Type: AWS::EC2::VPCGatewayAttachment
  Properties:
    InternetGatewayId: !Ref MyIGW
    VpcId: !Ref MyVPC04
```

구조:

```text
VPC ←→ IGW
```

---

# 7. Public Subnet

```yaml
MyPublicSubnet:
  Type: AWS::EC2::Subnet
  Properties:
    AvailabilityZone: !Select [0, !GetAZs '']
    CidrBlock: 10.0.1.0/24
    MapPublicIpOnLaunch: true
    VpcId: !Ref MyVPC04
```

주소:

```text
10.0.1.0/24
```

핵심:

```yaml
MapPublicIpOnLaunch: true
```

해당 Subnet에서 생성되는 인스턴스에 Public IPv4 주소를 자동 할당할 수 있도록 설정한다.

---

# 8. Public Route Table

Route Table 생성:

```yaml
MyPublicRouting:
  Type: AWS::EC2::RouteTable
  Properties:
    VpcId: !Ref MyVPC04
```

Subnet과 연결:

```yaml
MyPublicRouteTableAssociation:
  Type: AWS::EC2::SubnetRouteTableAssociation
  Properties:
    RouteTableId: !Ref MyPublicRouting
    SubnetId: !Ref MyPublicSubnet
```

Default Route:

```yaml
MyPublicDefault:
  DependsOn: MyIGWattachment
  Type: AWS::EC2::Route
  Properties:
    DestinationCidrBlock: 0.0.0.0/0
    GatewayId: !Ref MyIGW
    RouteTableId: !Ref MyPublicRouting
```

결과:

```text
Public Route Table

10.0.0.0/16 → local
0.0.0.0/0   → Internet Gateway
```

---

# 9. Security Group

```yaml
SecurityGroupIngress:
  - IpProtocol: tcp
    FromPort: 80
    ToPort: 80
    CidrIp: 0.0.0.0/0
```

실습에서 허용한 트래픽:

| Protocol | Port | 용도 |
|---|---:|---|
| TCP | 80 | HTTP |
| TCP | 443 | HTTPS |
| TCP | 22 | SSH |
| ICMP | ALL | Ping |

Security Group은 EC2 등의 ENI에 적용되는 **상태 저장형(Stateful) 가상 방화벽**이다.

---

# 10. Public EC2 — MyWeb

```yaml
MyWeb:
  Type: AWS::EC2::Instance
```

주요 설정:

```yaml
ImageId: !Ref LatestAmiId
KeyName: !Ref KeyName
InstanceType: t3.micro
```

네트워크:

```yaml
NetworkInterfaces:
  - DeviceIndex: 0
    SubnetId: !Ref MyPublicSubnet
    AssociatePublicIpAddress: true
    PrivateIpAddress: 10.0.1.101
```

결과:

```text
MyWeb

Private IP : 10.0.1.101
Public IP  : O
Subnet     : Public
```

---

# 11. UserData

EC2 생성과 동시에 서버 초기 설정을 자동화한다.

```bash
#!/bin/bash

hostnamectl --static set-hostname MyWeb

yum install -y httpd

systemctl enable --now httpd

echo "<h1>MyWeb test web page</h1>" \
> /var/www/html/index.html
```

즉,

```text
EC2 생성
 ↓
UserData 실행
 ↓
Apache 설치
 ↓
Apache 자동 시작
 ↓
index.html 생성
 ↓
Web Server 완성
```

---

# 12. MyVPC05 — Public + Private VPC

MyVPC05에서는 MyVPC04 구조에 다음 요소가 추가된다.

```text
NAT Gateway
Elastic IP
Private Subnet
Private Route Table
Private EC2
```

전체 구조:

```text
                       Internet
                          │
                          ▼
                         IGW
                          │
              ┌───────────┴───────────┐
              │      MyVPC05          │
              │     10.0.0.0/16       │
              │                       │
        Public Subnet           Private Subnet
         10.0.1.0/24            10.0.100.0/24
              │                       │
           MyWeb1                   MyWeb11
         10.0.1.101              10.0.100.101
         Public IP O             Public IP X
              │                       │
              │                       ▼
              │                   NAT Gateway
              │                       │
              └───────────────────────┘
                          │
                          ▼
                       Internet
```

---

# 13. Elastic IP

```yaml
MyNatGWEIP:
  Type: AWS::EC2::EIP
  Properties:
    Domain: vpc
```

NAT Gateway에서 사용할 공인 IPv4 주소를 확보한다.

---

# 14. NAT Gateway

```yaml
MyNatGW:
  DependsOn: MyIGWattachment
  Type: AWS::EC2::NatGateway
  Properties:
    AllocationId: !GetAtt MyNatGWEIP.AllocationId
    SubnetId: !Ref MyPublicSubnet
```

⭐ NAT Gateway는 **Public Subnet에 위치**한다.

```text
Private EC2
   ↓
NAT Gateway
   ↓
Internet Gateway
   ↓
Internet
```

Private EC2가 Public IP 없이 인터넷으로 나갈 수 있게 한다.

---

# 15. Private Subnet

```yaml
MyPrivateSubnet:
  Type: AWS::EC2::Subnet
  Properties:
    CidrBlock: 10.0.100.0/24
    MapPublicIpOnLaunch: false
```

주소:

```text
10.0.100.0/24
```

핵심:

```yaml
MapPublicIpOnLaunch: false
```

Public IP 자동 할당을 사용하지 않는다.

---

# 16. Private Route Table

```yaml
MyPrivateDefault:
  DependsOn: MyNatGW
  Type: AWS::EC2::Route
  Properties:
    DestinationCidrBlock: 0.0.0.0/0
    NatGatewayId: !Ref MyNatGW
    RouteTableId: !Ref MyPrivateRouting
```

Public과 Private Route Table의 차이가 매우 중요하다.

### Public

```text
0.0.0.0/0
     ↓
Internet Gateway
```

### Private

```text
0.0.0.0/0
     ↓
NAT Gateway
```

⭐ 시험 및 면접 핵심 포인트

> Public Subnet과 Private Subnet을 구분하는 핵심 요소 중 하나는 해당 Subnet에 연결된 Route Table의 외부 경로이다.

---

# 17. Private EC2 — MyWeb11

```yaml
MyWeb11:
  Type: AWS::EC2::Instance
```

네트워크:

```yaml
AssociatePublicIpAddress: false
PrivateIpAddress: 10.0.100.101
SubnetId: !Ref MyPrivateSubnet
```

결과:

```text
MyWeb11

Private IP : 10.0.100.101
Public IP  : X
Subnet     : Private
```

하지만 NAT Gateway를 통해 다음 작업은 가능하다.

```text
yum install
dnf install
외부 Repository 접근
패키지 업데이트
외부 API 접근
```

핵심은 다음과 같다.

```text
Internet → Private EC2
직접 접근 X

Private EC2 → Internet
NAT Gateway를 통한 Outbound O
```

---

# 18. Public / Private 구조 비교 ⭐

| 구분 | Public Subnet | Private Subnet |
|---|---|---|
| CIDR | 10.0.1.0/24 | 10.0.100.0/24 |
| EC2 | MyWeb1 | MyWeb11 |
| Private IP | 10.0.1.101 | 10.0.100.101 |
| Public IP | O | X |
| Default Route | IGW | NAT Gateway |
| 인터넷 Outbound | O | O |
| 인터넷 직접 Inbound | 가능하도록 구성 가능 | 직접 불가 |

---

# 19. 기존 네트워크 지식과 AWS 연결하기

기존에 배운 네트워크 개념을 AWS에 연결하면 이해하기 쉽다.

| Network | AWS |
|---|---|
| Network Address | VPC CIDR |
| Subnet | AWS Subnet |
| Routing Table | Route Table |
| Default Route | `0.0.0.0/0` |
| Gateway | Internet Gateway |
| NAT/PAT | NAT Gateway |
| Firewall | Security Group / NACL |
| Static Public IP | Elastic IP |
| Server | EC2 |
| 자동 초기 설정 | UserData |

예를 들어:

```yaml
DestinationCidrBlock: 0.0.0.0/0
NatGatewayId: !Ref MyNatGW
```

기존 네트워크 관점에서는

```text
Default Route → NAT 방향
```

이라고 이해하면 된다.

---

# 20. Kubernetes YAML과 CloudFormation YAML 비교

Kubernetes 역시 YAML 기반 선언형 구성을 사용한다.

### Kubernetes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deploy
spec:
  replicas: 6
```

의미:

```text
Pod 6개가 실행되는 상태를 선언
```

### CloudFormation

```yaml
MyVPC:
  Type: AWS::EC2::VPC
  Properties:
    CidrBlock: 10.0.0.0/16
```

의미:

```text
10.0.0.0/16 VPC가 존재하는 상태를 선언
```

따라서 공통 개념은 다음과 같다.

```text
Kubernetes
→ Container Infrastructure 선언

CloudFormation
→ AWS Infrastructure 선언
```

⭐ 핵심 키워드:

```text
Declarative Configuration
Infrastructure as Code
Automation
Reproducibility
```

---

# 21. CloudFormation Resource 의존 관계

MyVPC05를 생성 순서 관점에서 보면 다음과 같이 이해할 수 있다.

```text
MyVPC05
 │
 ├── MyIGW
 │     └── MyIGWattachment
 │
 ├── MyPublicSubnet
 │     ├── MyPublicRouting
 │     │      └── 0.0.0.0/0 → IGW
 │     │
 │     └── MyWeb1
 │
 └── MyPrivateSubnet
       ├── MyPrivateRouting
       │
       └── MyWeb11

MyNatGWEIP
     │
     ▼
MyNatGW
     │
     ▼
Private Default Route
```

CloudFormation은 `!Ref`, `!GetAtt` 등을 통해 리소스 간 의존 관계를 파악할 수 있으며, 필요한 경우 `DependsOn`으로 명시적인 의존 관계를 추가할 수 있다.

---

# 22. 실습 시 주의할 점 ⚠️

## ① Resource Logical ID 확인

```text
MyWeb1  → Public EC2
MyWeb11 → Private EC2
```

정리 노트에서 Private EC2를 `MyWeb1`이라고 적지 않도록 주의한다.

---

## ② NAT Gateway 비용

NAT Gateway는 생성해 둔 채 방치하지 않는다.

실습 종료 후 사용하지 않는다면 관련 리소스를 정리한다.

특히 다음 리소스를 확인한다.

```text
CloudFormation Stack
NAT Gateway
Elastic IP
EC2
Load Balancer
RDS
```

CloudFormation 실습에서는 가능하면 개별 리소스를 수동 삭제하기보다 **스택 단위의 리소스 관계와 삭제 동작**을 함께 확인한다.

---

## ③ SSH 보안

실습에서는 다음과 같은 설정을 사용할 수 있지만:

```text
SSH 22
0.0.0.0/0
```

운영 환경에서는 관리자 IP 등 필요한 Source만 허용하는 것이 안전하다.

예:

```text
SSH
관리자 IP/32
```

---

## ④ Root Password Login

다음 설정은 실습 환경 이해에는 도움이 되지만 실제 운영 환경에서는 지양한다.

```bash
PasswordAuthentication yes
PermitRootLogin yes
```

가능하면 Key Pair, 제한된 사용자, Systems Manager Session Manager 등의 방식을 고려한다.

---

# 23. 자주 발생할 수 있는 트러블슈팅 💀

## EC2 웹페이지 접속 실패

확인 순서:

```text
1. EC2 Running?
2. Public IP 존재?
3. Security Group 80 허용?
4. Subnet Route Table 확인
5. 0.0.0.0/0 → IGW 확인
6. IGW가 VPC에 Attach 되었는지 확인
7. httpd 실행 상태 확인
8. UserData 실행 성공 여부 확인
```

명령:

```bash
systemctl status httpd
curl localhost
```

---

## Private EC2 인터넷 연결 실패

확인 순서:

```text
Private EC2
 ↓
Private Subnet
 ↓
Private Route Table
 ↓
0.0.0.0/0
 ↓
NAT Gateway
 ↓
Public Subnet
 ↓
IGW
 ↓
Internet
```

확인 사항:

```text
NAT Gateway 상태
Elastic IP
Private Route Table
NAT Gateway가 Public Subnet에 있는지
Public Subnet의 IGW Route
```

---

## UserData가 실행되지 않은 것처럼 보이는 경우

로그 확인:

```bash
cat /var/log/cloud-init-output.log
```

또는:

```bash
cloud-init status
```

UserData 내부의 명령어 오류 여부를 확인한다.

---

# 24. 면접 예상 질문 🔥

### Q1. CloudFormation이란?

AWS 인프라를 YAML 또는 JSON 템플릿으로 정의하고 자동으로 생성 및 관리할 수 있도록 해주는 AWS의 IaC 서비스이다.

---

### Q2. `!Ref`와 `!GetAtt`의 차이는?

`!Ref`는 Parameter 또는 Resource의 기본 참조 값을 가져오며, `!GetAtt`는 Resource가 제공하는 특정 Attribute를 가져올 때 사용한다.

---

### Q3. Public Subnet과 Private Subnet의 차이는?

단순히 이름으로 결정되는 것이 아니라 Route Table 및 Public IP 등 네트워크 구성이 중요하다.

Public Subnet은 일반적으로 IGW로 향하는 Default Route를 가지며, Private Subnet은 인터넷에 직접 연결하지 않고 필요한 경우 NAT Gateway 등을 통해 Outbound 인터넷 통신을 수행한다.

---

### Q4. NAT Gateway를 사용하는 이유는?

Private Subnet의 EC2가 Public IP 없이 인터넷으로 Outbound 통신할 수 있도록 하기 위해 사용한다.

예:

```text
Package Update
Repository Access
External API
```

---

### Q5. NAT Gateway는 어느 Subnet에 생성하는가?

인터넷 연결을 위한 일반적인 구성에서는 **Public Subnet**에 생성하고 Elastic IP를 연결한다.

Private Route Table의 Default Route가 해당 NAT Gateway를 가리킨다.

---

### Q6. UserData란?

EC2가 최초 시작될 때 실행할 초기화 스크립트를 전달하는 기능이다.

서버 패키지 설치, 설정 파일 생성, 서비스 시작 등을 자동화할 수 있다.

---

### Q7. `DependsOn`은 왜 사용하는가?

특정 Resource가 다른 Resource 이후 생성되어야 하는 명시적인 의존 관계가 필요한 경우 사용한다.

단, `!Ref`, `!GetAtt` 등으로 이미 의존 관계가 형성되는 경우 CloudFormation이 이를 자동으로 파악할 수 있다.

---

# 25. 오늘의 핵심 암기 ⭐⭐⭐

```text
CloudFormation = AWS IaC

!Ref
→ Resource / Parameter 참조

!GetAtt
→ Resource Attribute 조회

!GetAZs
→ AZ 목록

!Select
→ 목록에서 선택

DependsOn
→ 명시적 생성 의존 관계

Fn::Base64 + !Sub
→ EC2 UserData
```

네트워크:

```text
Public Subnet
0.0.0.0/0
     ↓
Internet Gateway
```

```text
Private Subnet
0.0.0.0/0
     ↓
NAT Gateway
     ↓
Internet Gateway
```

NAT:

```text
Private EC2
     ↓
Private Route Table
     ↓
NAT Gateway
     ↓
Public Subnet
     ↓
Internet Gateway
     ↓
Internet
```

---

# 26. 오늘의 최종 정리

### MyVPC04

```text
VPC
 ↓
IGW
 ↓
Public Subnet
 ↓
Public Route Table
 ↓
Security Group
 ↓
Public EC2
 ↓
Apache
```

### MyVPC05

```text
VPC
 │
 ├─ Public Subnet
 │    ├─ IGW Route
 │    ├─ Public EC2
 │    └─ NAT Gateway + EIP
 │
 └─ Private Subnet
      ├─ NAT Gateway Route
      └─ Private EC2
```

## 한 문장 요약

> **CloudFormation을 이용하여 VPC, Subnet, Route Table, Internet Gateway, Security Group, EC2, Elastic IP, NAT Gateway 등의 AWS 리소스를 YAML 코드로 선언하고 하나의 Stack으로 자동 구축할 수 있다.**

---

# 🔥 오늘의 핵심 흐름

```text
Console 수동 구축
        ↓
CloudFormation
        ↓
Infrastructure as Code
        ↓
YAML Template
        ↓
Stack
        ↓
AWS Resource 자동 구축
```

그리고 지금까지의 학습 흐름을 연결하면:

```text
Network
   ↓
Linux
   ↓
Docker
   ↓
Kubernetes
   ↓
AWS
   ↓
CloudFormation / IaC
```

**“서버를 직접 설정하는 단계에서 인프라 전체를 코드로 정의하는 단계로 확장된다.”**