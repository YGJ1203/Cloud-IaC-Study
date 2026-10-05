# ☁️ AWS 실습 치트시트

> **목적:** AWS 실습 중 막혔을 때 빠르게 확인하기 위한 치트시트  
> **범위:** IAM · VPC · Subnet · IGW · Route Table · Security Group · EC2 · S3 · Auto Scaling · CloudFormation  
> **핵심 흐름:** `네트워크 설계 → 보안 설정 → 서버 배포 → 통신 검증 → IaC 자동화`

---

# 1. AWS 기본 구조

```text
AWS Region
│
└── VPC
    │
    ├── Public Subnet
    │   └── EC2
    │
    ├── Internet Gateway
    │
    ├── Route Table
    │
    └── Security Group
```

### 핵심 개념

| AWS 서비스 | 역할 |
|---|---|
| Region | AWS의 물리적 서비스 지역 |
| AZ | Region 내부의 독립적인 데이터센터 영역 |
| VPC | 사용자가 구성하는 가상 네트워크 |
| Subnet | VPC 네트워크를 나눈 영역 |
| IGW | VPC와 인터넷을 연결 |
| Route Table | 패킷의 이동 경로 결정 |
| Security Group | EC2 등에 적용하는 상태 저장형 방화벽 |
| EC2 | AWS 가상 서버 |

---

# 2. VPC 구축 정석 순서 ⭐

AWS 네트워크 실습에서는 다음 흐름을 기억한다.

```text
1. VPC 생성
      ↓
2. Internet Gateway 생성
      ↓
3. IGW ↔ VPC 연결
      ↓
4. Public Subnet 생성
      ↓
5. Route Table 생성
      ↓
6. 0.0.0.0/0 → IGW 설정
      ↓
7. Route Table ↔ Subnet 연결
      ↓
8. Security Group 생성
      ↓
9. EC2 생성
      ↓
10. 통신 테스트
```

### 예시

```text
VPC
10.0.0.0/16

└── Public Subnet
    10.0.1.0/24

Internet Gateway
        │
        ▼
Route Table
0.0.0.0/0 → IGW
        │
        ▼
Public Subnet
        │
        ▼
EC2
```

---

# 3. CIDR 빠르게 보기

```text
10.0.0.0/16
```

약 65,536개의 주소 범위를 가진다.

```text
10.0.1.0/24
```

256개의 주소 범위를 가진다.

예를 들어,

```text
VPC
10.0.0.0/16

Public Subnet
10.0.1.0/24

Private Subnet
10.0.2.0/24
```

처럼 VPC 내부를 여러 Subnet으로 나눌 수 있다.

> AWS에서는 각 Subnet마다 일부 IP 주소를 예약하므로 `/24 = 256개`가 모두 사용자 리소스에 할당되는 것은 아니다.

---

# 4. Public Subnet의 핵심 ⭐⭐⭐

Subnet 이름에 `Public`이라고 적는다고 Public Subnet이 되는 것이 아니다.

핵심은 **Route Table**이다.

```text
Destination      Target

10.0.0.0/16      local
0.0.0.0/0        Internet Gateway
```

즉,

```text
0.0.0.0/0 → IGW
```

경로가 존재해야 인터넷으로 나갈 수 있다.

그리고 EC2가 인터넷과 직접 통신하려면 일반적으로 **Public IPv4 주소**도 필요하다.

---

# 5. Security Group

Security Group은 EC2 등에 적용하는 가상 방화벽이다.

대표적인 Inbound Rule:

| Protocol | Port | 용도 |
|---|---:|---|
| SSH | TCP 22 | Linux 원격 접속 |
| HTTP | TCP 80 | 웹 |
| HTTPS | TCP 443 | HTTPS 웹 |
| ICMP | - | ping 테스트 |

예:

```text
SSH
TCP 22
Source: My IP

HTTP
TCP 80
Source: 0.0.0.0/0
```

### 중요 ⭐

Security Group은 **Stateful**이다.

```text
Client → EC2
       ←
```

허용된 요청에 대한 반환 트래픽은 자동으로 허용된다.

---

# 6. Security Group vs NACL

| 구분 | Security Group | NACL |
|---|---|---|
| 적용 대상 | ENI/인스턴스 수준 | Subnet |
| 상태 | Stateful | Stateless |
| Allow | O | O |
| Deny | X | O |
| 규칙 평가 | 전체 규칙 | 번호 순서 |

기억법:

```text
Security Group
= 서버 문 앞 경비원

NACL
= Subnet 입구 검문소
```

---

# 7. EC2 생성 체크리스트

EC2를 생성할 때 확인한다.

```text
AMI
↓
Instance Type
↓
Key Pair
↓
VPC
↓
Subnet
↓
Public IP
↓
Security Group
↓
Storage
```

Linux 접속 예:

```bash
ssh -i key.pem ec2-user@PUBLIC_IP
```

Amazon Linux 계열에서는 일반적으로 다음 사용자를 사용한다.

```text
ec2-user
```

---

# 8. EC2 인터넷 통신 흐름 ⭐

외부 사용자가 웹 서버 EC2에 접근한다고 가정한다.

```text
Internet
   ↓
Internet Gateway
   ↓
Route Table
   ↓
Public Subnet
   ↓
Security Group
   ↓
EC2
   ↓
Apache / Nginx
```

따라서 웹 접속이 실패하면 **EC2만 보면 안 된다.**

---

# 9. EC2 웹 접속 실패 시 점검 순서

```text
① EC2 Running?
        ↓
② Public IP 존재?
        ↓
③ IGW가 VPC에 연결?
        ↓
④ Route Table에 0.0.0.0/0 → IGW?
        ↓
⑤ Subnet과 Route Table 연결?
        ↓
⑥ Security Group TCP 80 허용?
        ↓
⑦ Web Server 실행?
        ↓
⑧ OS Firewall 문제?
```

이 순서대로 확인하면 트러블슈팅 범위를 빠르게 좁힐 수 있다.

---

# 10. SSH 접속 실패

```text
SSH 접속 실패
│
├── Public IP 확인
├── Security Group TCP/22 확인
├── Source IP 확인
├── Key Pair 확인
├── 사용자 이름 확인
└── EC2 상태 확인
```

특히 SSH를

```text
0.0.0.0/0
```

으로 무조건 개방하기보다는 실습에서도 가능하면 **My IP**를 사용한다.

---

# 11. IAM 핵심

IAM은 AWS 리소스에 대한 **인증(Authentication)**과 **권한(Authorization)**을 관리한다.

핵심 구성:

```text
IAM
├── User
├── Group
├── Role
└── Policy
```

### Policy

실제로 어떤 작업을 허용/거부할지 정의한다.

```text
User / Group / Role
        ↓
      Policy
        ↓
 AWS Resource 접근
```

### 핵심 원칙

> **Least Privilege**

필요한 최소 권한만 부여한다.

---

# 12. Root User vs IAM User

### Root User

AWS 계정 생성 시 만들어지는 최고 권한 계정.

일상적인 작업에는 사용하지 않는 것이 원칙이다.

### IAM User

관리 및 실습 등에 사용하는 사용자 계정.

```text
Root
→ 계정 수준의 중요 작업

IAM User / Role
→ 일반적인 AWS 리소스 관리
```

그리고 Root 계정에는 반드시 **MFA 적용**을 고려한다.

---

# 13. S3 핵심

S3는 AWS의 **Object Storage** 서비스이다.

구조:

```text
Bucket
└── Object
    ├── Key
    ├── Data
    └── Metadata
```

전통적인 파일 시스템처럼 생각하기보다

```text
Key → Object
```

구조로 이해하는 것이 중요하다.

대표 활용:

```text
정적 웹 콘텐츠
백업
로그
이미지
파일 저장
데이터 분석
```

---

# 14. Auto Scaling

Auto Scaling은 필요에 따라 EC2 인스턴스 수를 자동 조절한다.

```text
사용량 증가
    ↓
Scale Out
    ↓
EC2 증가
```

반대로

```text
사용량 감소
    ↓
Scale In
    ↓
EC2 감소
```

대표 구성:

```text
Launch Template
       +
Auto Scaling Group
       +
Scaling Policy
```

---

# 15. Load Balancer + Auto Scaling

실무적인 웹 서비스 구조에서는 다음과 같이 구성할 수 있다.

```text
              Internet
                  │
                  ▼
          Application Load
             Balancer
            /       \
           ▼         ▼
        EC2-1      EC2-2
           \         /
            \       /
         Auto Scaling
```

트래픽이 증가하면:

```text
EC2 2대
 ↓
EC2 4대
 ↓
EC2 6대
```

처럼 확장할 수 있다.

---

# 16. CloudFormation ⭐⭐⭐

CloudFormation은 AWS 인프라를 코드로 정의하는 **IaC(Infrastructure as Code)** 서비스이다.

콘솔 방식:

```text
클릭
클릭
클릭
클릭...
```

CloudFormation:

```text
YAML / JSON
     ↓
CloudFormation
     ↓
AWS Resources 생성
```

---

# 17. CloudFormation 기본 구조

```yaml
Parameters:

Resources:

Outputs:
```

### Parameters

사용자로부터 값을 입력받는다.

```yaml
Parameters:
  KeyName:
    Type: AWS::EC2::KeyPair::KeyName
```

### Resources

실제로 생성할 AWS 리소스를 정의한다.

```yaml
Resources:
  MyVPC:
    Type: AWS::EC2::VPC
```

### Outputs

Stack 생성 후 필요한 값을 출력할 수 있다.

---

# 18. Console ↔ CloudFormation 대응표

| Console에서 만든 것 | CloudFormation |
|---|---|
| VPC | `AWS::EC2::VPC` |
| Internet Gateway | `AWS::EC2::InternetGateway` |
| Subnet | `AWS::EC2::Subnet` |
| Route Table | `AWS::EC2::RouteTable` |
| Route | `AWS::EC2::Route` |
| Security Group | `AWS::EC2::SecurityGroup` |
| EC2 | `AWS::EC2::Instance` |

결국 CloudFormation은

> **콘솔에서 직접 만들었던 AWS 인프라를 코드로 표현하는 것**

이라고 이해하면 된다.

---

# 19. 온프레미스 ↔ AWS 대응표 ⭐⭐⭐

기존에 배운 기술과 AWS를 연결해서 생각한다.

| 기존 환경 | AWS |
|---|---|
| 물리/가상 네트워크 | VPC |
| 네트워크 주소 | CIDR |
| 네트워크 분리 | Subnet |
| Routing | Route Table |
| 인터넷 연결 | Internet Gateway |
| NAT | NAT Gateway |
| 방화벽 | Security Group / NACL |
| VMware VM | EC2 |
| HAProxy | ELB |
| 서버 증설 | Auto Scaling |
| DNS | Route 53 |
| 공유 파일 스토리지 | EFS |
| Object Storage | S3 |
| IaC | CloudFormation |

---

# 20. 지금까지 배운 기술과 AWS 연결 🔥

```text
Network
   ↓
VPC / Subnet / Route Table / IGW

Linux
   ↓
EC2

Apache / Nginx
   ↓
EC2 Web Server

Firewall
   ↓
Security Group / NACL

HAProxy
   ↓
ELB

Docker / Kubernetes
   ↓
ECS / EKS

NFS
   ↓
EFS

DNS
   ↓
Route 53

IaC
   ↓
CloudFormation
```

즉,

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
```

는 각각 별개의 기술이 아니라 서로 연결되는 인프라 스택이다.

---

# 21. AWS 트러블슈팅 사고방식

문제가 발생했을 때 무작정 설정을 바꾸지 않는다.

```text
증상 확인
 ↓
어느 계층 문제인지 판단
 ↓
Network?
Security?
OS?
Application?
 ↓
하나씩 검증
 ↓
원인 발견
 ↓
수정
 ↓
재검증
```

예:

```text
웹 접속 실패

1. EC2 Running?
2. IP 정상?
3. Route 정상?
4. Security Group 정상?
5. ping/SSH 가능?
6. Web Server 실행?
7. TCP 80 Listen?
8. curl localhost 성공?
9. 외부 curl 성공?
```

이 흐름은 기존 Linux/Kubernetes 트러블슈팅과 동일하다.

---

# 22. 💸 실습 종료 후 비용 체크 ☠️

AWS에서 가장 무서운 명령어:

```text
"내일 지우지 뭐"
```

☠️☠️☠️

실습 후 다음 리소스를 확인한다.

```text
□ EC2
□ NAT Gateway
□ Elastic IP
□ Load Balancer
□ RDS
□ Auto Scaling Group
□ Launch Template
□ CloudFormation Stack
□ EBS Volume
□ Snapshot
```

특히

```text
NAT Gateway
Load Balancer
RDS
```

등은 실습 후 반드시 상태를 확인한다.

단순히 EC2를 종료했다고 해서 **모든 AWS 비용 발생 요소가 사라지는 것은 아니다.**

---

# 23. ⭐ 1분 면접 답변

### Q. VPC란?

VPC는 AWS에서 사용자가 정의할 수 있는 논리적으로 격리된 가상 네트워크입니다. CIDR을 이용해 IP 대역을 지정하고, Subnet과 Route Table, Internet Gateway 등을 구성하여 네트워크 환경을 설계할 수 있습니다.

### Q. Public Subnet이란?

Internet Gateway로 향하는 기본 경로가 Route Table에 설정된 Subnet을 일반적으로 Public Subnet이라고 합니다. EC2가 인터넷과 직접 통신하기 위해서는 Public IP와 Security Group 등의 조건도 함께 확인해야 합니다.

### Q. Security Group이란?

EC2와 같은 AWS 리소스에 적용되는 Stateful 방식의 가상 방화벽입니다. Inbound와 Outbound 규칙을 통해 허용할 트래픽을 정의합니다.

### Q. CloudFormation이란?

AWS 인프라를 YAML 또는 JSON 템플릿으로 정의하여 자동으로 생성하고 관리할 수 있는 IaC 서비스입니다. 반복 가능한 인프라 구축과 구성의 일관성을 확보하는 데 사용할 수 있습니다.

---

# 24. 🚀 최종 암기 흐름

AWS VPC 문제가 나오면 먼저 이것을 떠올린다.

```text
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
Application
```

그리고 자동화가 필요하면:

```text
수동 AWS 구축
     ↓
CloudFormation
     ↓
Infrastructure as Code
```

기존 기술과 연결하면:

```text
Network
   +
Linux
   +
Docker / Kubernetes
   +
AWS
   +
IaC
   ↓
Cloud / Infrastructure Engineer
```

---

# 🎯 오늘의 핵심 10줄

```text
1. VPC = AWS 가상 네트워크
2. Subnet = VPC 네트워크 분할
3. Public Subnet 핵심 = 0.0.0.0/0 → IGW
4. Route Table = 패킷 경로 결정
5. Security Group = Stateful 방화벽
6. EC2 = 가상 서버
7. IAM = 사용자와 권한 관리
8. S3 = Object Storage
9. Auto Scaling = 서버 수 자동 조절
10. CloudFormation = AWS Infrastructure as Code
```

> 💡 **핵심:** AWS를 새로운 기술이라고만 생각하지 말고, 지금까지 배운 Network · Linux · Docker · Kubernetes 지식을 AWS 서비스와 연결해서 이해하자.