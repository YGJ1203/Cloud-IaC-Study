# 2026-10-08 AWS 네트워크 실습 핵심 정리

> 주제: VPC Endpoint · NAT Instance · ALB/NLB · VPC Peering · Transit Gateway · Squid Proxy · CloudFormation

## 1. 오늘 배운 내용을 한눈에 보기

| 기능 | 해결하는 문제 | 기억할 핵심 |
|---|---|---|
| S3 Gateway Endpoint | Private EC2에서 S3 접근 | S3 목적지 경로를 Endpoint로 전달 |
| NAT Instance | Private EC2의 외부 IPv4 통신 | 라우팅 + IP Forwarding + NAT + Source/Destination Check 해제 |
| ALB | HTTP/HTTPS 요청 분산 | Listener → Rule → Target Group → Target |
| NLB | TCP/UDP 등 연결 분산 | 프로토콜·포트·대상 상태 확인 |
| VPC Peering | 두 VPC 간 사설 통신 | 연결 수락 + 양쪽 경로 + 보안 정책 |
| Transit Gateway | 여러 VPC의 중앙 라우팅 | VPC Route + Attachment + TGW Route |
| Squid Proxy | 클라이언트의 웹 요청 중계 | 클라이언트 → Proxy:3128 → 외부 웹 서버 |
| CloudFormation | 기본 인프라 자동 생성 | 템플릿에 선언된 리소스 범위를 확인 |

**오늘의 중심 질문: “패킷의 목적지는 무엇이며, 어느 라우팅 테이블이 다음 경로를 결정하는가?”**

## 2. 자료와 검증 범위를 구분하기

| 자료 | 확인 가능한 내용 | 확인할 수 없는 내용 |
|---|---|---|
| 10.png | MyVPC09의 엔드포인트 실습 초기 환경 | Endpoint 생성·S3 접근 성공 여부 |
| 11.png + 661p YAML | NAT 실습 목표 구조와 기본 VPC/EC2 | NAT 인스턴스 실제 생성·NAT 설정 결과 |
| 12.png + 689p YAML | LB 가이드와 웹 서버 기본 환경 | ALB/NLB 실제 생성·분산 테스트 결과 |
| 13.png + 749p YAML | Peering 가이드와 두 VPC 기본 환경 | Peering 실제 경로·통신 테스트 결과 |
| 15.png + 825p YAML | TGW 추가 전 세 VPC와 프록시 구성 의도 | TGW 생성·Attachment 상태 |
| 15-.png | TGW 및 라우팅을 추가하는 단계의 가이드 | 실제 계정의 최종 결과 |
| 남아 있는 콘솔 로그 | Ping 결과 변화, HTTP 프록시 응답, 종료 절차 | 각 설정 변경 시점·변경값의 정확한 대응 |

**모든 이미지는 강사 제공 가이드이며 실제 구축 완료 화면이 아니다.** 15-.png도 단계별 안내 중 한 장이다.

사용자는 TGW 설정을 추가·변경하면서 `ping.sh`를 반복 실행했다. 중간 콘솔 변경 기록과 PuTTY 전체 로그는 보관하지 못했다. 따라서 통신 상태 변화는 실습 과정의 관찰로 기록하고, 특정 실패를 장애나 패킷 손실로 확정하지 않는다.

## 3. CloudFormation 템플릿 실제 분석

| 파일 | 주요 선언 | 포함되지 않은 후속 리소스 |
|---|---|---|
| 661p_cloudformation_11_yaml.txt | MyVPC12, IGW, Public/Private Subnet, Route Table, SG, Private EC2 2대 | MyNAT EC2, Private 기본 NAT 경로 |
| 689p_cloudformation_12_yaml.txt | MyVPC13·14, IGW 2개, Public Subnet 3개, 웹 EC2 3대 | ALB/NLB, Listener, Target Group |
| 749p_cloudformation_13_yaml.txt | MyVPC15·16, IGW 2개, Public EC2 2대 | VPC Peering 연결 및 상대 VPC 경로 |
| 825p_cloudformation_15_yaml.txt | MyVPC19·20·21, IGW 1개, EC2 3대, Squid·Proxy 환경 변수 | TGW, Attachment, TGW Route Table, VPC의 TGW 경로 |

### 공통 문법

```yaml
VpcId: !Ref MyVPC19
AvailabilityZone: !Select [0, !GetAZs '']
```

- `!Ref`: 해당 리소스 또는 파라미터를 참조한다. 반환값은 리소스 유형에 따라 다르며 VPC에서는 VPC ID다.
- `!GetAZs`: 배포 리전의 가용 영역 목록을 반환한다.
- `!Select`: 목록의 특정 인덱스를 선택한다. `[0]`, `[2]`를 모든 계정에서 무조건 2a·2c로 외우지 않는다.
- `!Sub`: 문자열 안의 CloudFormation 변수를 치환한다.
- `Fn::Base64`: UserData를 Base64로 인코딩한다. 암호화 기능이 아니다.
- `DependsOn`: 명시적인 생성 순서를 지정한다. 템플릿의 줄 배치 순서가 생성 순서를 결정하지 않는다.

### UserData를 읽을 때

EC2 생성과 부팅 스크립트 성공은 별도로 확인해야 한다. `yum install`, 외부 GitHub 다운로드는 그 시점의 인터넷·DNS 경로가 필요하다.

```bash
sudo tail -n 100 /var/log/cloud-init-output.log
sudo systemctl status httpd squid
```

825p는 MyWeb19에서 Squid·Apache를 설치하고 외부 URL에서 `ping.sh`를 내려받는다. MyWeb20·21에서는 `/etc/bashrc`에 Proxy 변수를 추가한다. 템플릿만으로 모든 명령의 실행 성공을 입증할 수 없다.

## 4. VPC Endpoint — S3로 가는 전용 경로

10.png의 MyVPC09는 `10.0.0.0/16`, Public Subnet은 `10.0.1.0/24`, Private Subnet은 `10.0.100.0/24`다. 이미지에는 Private EC2의 IGW 직접 접근이 막힌 상태가 표시되어 있다. 대응하는 10번 YAML은 이번 첨부에 없다.

S3 Gateway Endpoint를 사용하면 NAT나 IGW 없이 해당 VPC에서 S3로 접근할 수 있다. 연결된 라우팅 테이블에는 S3 서비스 Prefix List를 목적지로 하는 Endpoint 경로가 들어간다.[1]

| 확인 대상 | 이유 |
|---|---|
| Private Subnet의 실제 연결 Route Table | Endpoint를 다른 테이블에 연결하면 경로가 적용되지 않음 |
| S3 목적지 Endpoint 경로 | 서비스 트래픽 전달 경로 확인 |
| IAM 권한·Endpoint Policy·Bucket Policy | 네트워크 연결만으로 객체 접근 권한이 생기지 않음 |
| DNS·SG Outbound·NACL | 이름 해석과 요청/응답 허용 확인 |

```bash
# 실제 버킷 이름과 권한을 준비한 뒤 실행하는 복습 명령
aws s3 ls s3://YOUR-BUCKET --region ap-northeast-2
```

S3는 Gateway와 Interface Endpoint 모두 지원한다. Gateway Endpoint는 다른 VPC가 TGW를 통해 공유해서 사용하는 구조가 아니다.[1] **S3 이름이 공인 IP로 해석된다고 인터넷 경로를 사용했다고 단정하면 안 된다. 라우팅이 경로를 결정한다.**

## 5. NAT Instance — EC2가 주소 변환 장비가 되는 구조

가이드의 목표: Private EC2 → MyNAT → IGW → Internet.

| 구성 | 값 |
|---|---|
| VPC | MyVPC12 / 10.0.0.0/16 |
| NAT 배치 서브넷 | Public / 10.0.1.0/24 |
| MyNAT 가이드 IP | 10.0.1.101 |
| Private Subnet | 10.0.100.0/24 |
| MyWeb1 / MyWeb2 | 10.0.100.101 / 10.0.100.102 |

661p YAML에는 MyNAT 리소스와 Private 기본 경로가 없다. Public Subnet이 생성되었다는 사실만으로 NAT 기능이 준비되는 것은 아니다.

복습할 구성 조건:

1. Public Subnet에 NAT 역할 EC2를 두고 공인 IPv4 또는 EIP를 연결한다.
2. Public Route Table의 `0.0.0.0/0 → IGW`를 확인한다.
3. NAT EC2의 Source/Destination Check를 해제한다.
4. OS의 IPv4 Forwarding과 SNAT/MASQUERADE를 설정한다.
5. Private Route Table의 외부 목적지 경로를 NAT EC2로 지정한다.
6. SG·NACL·OS 방화벽에서 필요한 흐름을 허용한다.

NAT EC2가 Public Subnet에 있고 공인 IP를 가져야 한다는 조건은 AWS 문서에서도 설명한다.[2]

| 구분 | NAT Instance | NAT Gateway |
|---|---|---|
| 구현 | EC2 및 OS NAT 기능 | AWS 관리형 NAT |
| 운영 | 패치·성능·장애 대응 직접 관리 | 관리 부담이 적음 |
| 용량 | 인스턴스 유형과 설정에 영향 | 관리형 확장 |
| 이번 자료 | 목표 가이드 + 기본 템플릿 | 구성 증거 없음 |

## 6. ALB/NLB — 대상 서버까지 연결해서 보기

689p YAML은 그림에 표시된 MyVPC13뿐 아니라 **MyVPC14와 MyWeb3도 생성**한다.

| VPC | EC2 | 사설 IP | 웹 페이지 |
|---|---|---|---|
| MyVPC13 / 10.0.0.0/16 | MyWeb1 | 10.0.1.101 | `/`, `/dir1/` |
| MyVPC13 / 10.0.0.0/16 | MyWeb2 | 10.0.2.101 | `/`, `/dir11/` |
| MyVPC14 / 172.16.0.0/16 | MyWeb3 | 172.16.1.101 | `/` |

MyWeb1·2는 서로 다른 AZ 인덱스 `[0]`, `[2]`를 사용한다. 그림은 2a·2c를 표시한다. MyWeb3의 초기 SG는 SSH 22만 허용하므로, Apache를 설치하더라도 외부 HTTP 허용은 별도로 확인해야 한다.

| 비교 | ALB | NLB |
|---|---|---|
| 주된 계층 | L7 | L4 |
| 대표 프로토콜 | HTTP/HTTPS | TCP/UDP/TLS 등 |
| 대표 선택 기준 | Host·Path 등 요청 규칙 | 연결과 포트 중심 분산 |

예를 들어 ALB에서 `/dir1/*`와 `/dir11/*`를 서로 다른 Target Group으로 전달할 수 있다. 이는 **복습용 구성 예시**이며 이번 실제 적용 기록이 아니다.

Health Check의 포트·경로·응답 코드와 Target 상태를 함께 본다.[3] Apache가 실행 중이어도 검사 경로가 없거나 SG에서 검사 트래픽이 막히면 문제가 생길 수 있다.

```bash
curl -I http://localhost/
curl -I http://localhost/dir1/
ss -lntp | rg ':80'
```

LB 응답이 번갈아 보이지 않는다는 이유만으로 분산 실패를 확정하지 않는다. 대상 상태, 연결 재사용, 세션 설정 등 실제 조건을 확인한다.

## 7. VPC Peering — 양방향 라우팅

749p YAML의 두 VPC는 CIDR이 겹치지 않는다.

| VPC | CIDR | EC2 IP | 복습용 상대 VPC 경로 |
|---|---|---|---|
| MyVPC15 | 10.0.0.0/16 | 10.0.1.101 | 172.16.0.0/16 → pcx-… |
| MyVPC16 | 172.16.0.0/16 | 172.16.1.101 | 10.0.0.0/16 → pcx-… |

위 경로는 필요한 구성 예시다. 첨부 템플릿에는 Peering 연결·경로가 선언되어 있지 않다.

구성 원리: 연결 요청·수락 → 양쪽 서브넷 Route Table 설정 → SG/NACL 확인 → 사설 IP 테스트.

Peering은 전이적 라우팅을 제공하지 않는다. A↔B, B↔C 연결만으로 A↔C 통신이 되는 것은 아니다. 상대 VPC의 IGW·NAT·Gateway Endpoint를 Peering을 통해 그대로 공유할 수도 없다.[4]

## 8. Transit Gateway — 오늘 실제 검증의 중심

### 8.1 기본 환경

| VPC | CIDR | Subnet | EC2 | 역할 |
|---|---|---|---|---|
| MyVPC19 | 10.19.0.0/16 | 10.19.1.0/24 | 10.19.1.101 | Public / Squid Proxy / Web |
| MyVPC20 | 10.20.0.0/16 | 10.20.1.0/24 | 10.20.1.101 | Private EC2 |
| MyVPC21 | 10.21.0.0/16 | 10.21.1.0/24 | 10.21.1.101 | Private EC2 |

825p YAML은 VPC19에만 IGW와 외부 기본 경로를 선언한다. VPC20·21의 라우팅 테이블에는 TGW 경로가 아직 선언되어 있지 않다.

### 8.2 단계별 가이드 15-.png의 경로

**아래 표는 강사 가이드의 설정이며 실제 최종 설정 캡처가 아니다.**

| VPC Route Table | 목적지 | 대상 |
|---|---|---|
| VPC19 | 10.19.0.0/16 | local |
| VPC19 | 10.0.0.0/8 | TGW |
| VPC19 | 0.0.0.0/0 | IGW |
| VPC20 | 10.20.0.0/16 | local |
| VPC20 | 10.0.0.0/8 | TGW |
| VPC21 | 10.21.0.0/16 | local |
| VPC21 | 10.0.0.0/8 | TGW |

| 가이드의 TGW Route Table 목적지 | 대상 Attachment |
|---|---|
| 10.19.0.0/16 | MyVPC19 |
| 10.20.0.0/16 | MyVPC20 |
| 10.21.0.0/16 | MyVPC21 |

`10.0.0.0/8`은 세 VPC CIDR을 포함한다. VPC19에서는 자신의 `/16` local 경로가 `/8` TGW 경로보다 구체적이다. 다른 VPC의 주소는 `/8` TGW 경로를 사용하고, 외부 IPv4 목적지는 `/0` IGW 경로를 사용할 수 있다. 기본 원리는 가장 구체적인 목적지 경로 선택이다.[5]

### 8.3 Attachment·Association·Propagation

| 항목 | 역할 |
|---|---|
| Attachment | VPC와 TGW 연결 |
| Association | 해당 Attachment에서 들어온 트래픽이 조회할 TGW Route Table 선택 |
| Propagation | Attachment의 네트워크 경로를 지정한 TGW Route Table에 전파 |
| Static Route | 관리자가 목적지와 Attachment를 명시적으로 지정 |
| VPC Route | 서브넷에서 상대 네트워크 트래픽을 TGW로 전달 |

Attachment는 하나의 TGW Route Table에 Association되며, 경로는 여러 TGW Route Table로 Propagation할 수 있다.[6] **Propagation을 켰다고 VPC의 서브넷 Route Table에 TGW 경로가 자동으로 추가되는 것은 아니다.**

복습용 패킷 흐름: MyWeb20 → VPC20 Route Table → TGW20 Attachment → 그 Attachment에 연결된 TGW Route Table → VPC19 Attachment → MyWeb19. 응답에는 반대 방향 경로가 필요하다.

### 8.4 실제 수행 및 관찰 기록

> AWS 콘솔에서 TGW 설정을 추가·변경하면서 EC2에서 `ping.sh`를 반복 실행했다. 설정을 바꾸는 과정에서 VPC 간 통신 가능 범위의 변화를 관찰했으며, 남아 있는 MyWeb19·20 로그에는 세 대상이 모두 `up`으로 출력된 실행 결과가 있다. 정확한 설정 변경값·시점과 개별 출력의 대응 관계는 보관되지 않았다.

MyWeb19에서 확인되는 대표 출력 조합:

| 대상 | 한 실행의 결과 | 다른 실행의 결과 | 모두 성공한 실행 |
|---|---|---|---|
| 10.19.1.101 | up | up | up |
| 10.20.1.101 | down | up | up |
| 10.21.1.101 | down | down | up |

표는 남아 있는 출력 조합을 비교한 것으로, 변경 단계 번호나 정확한 시간 순서를 재구성한 표가 아니다. 자기 자신의 IP에 대한 성공은 VPC 간 경로를 검증하지 않는다.

**성공 로그가 있다는 사실과 최종 구성이 지속적으로 정상이라는 판단은 구분한다.** 전체 통신 행렬·최종 설정·장기 안정성까지 이 자료로 확정할 수 없다.

## 9. Squid Proxy — TGW와 역할 분담

825p YAML에서 MyWeb19는 TCP 3128을 `10.0.0.0/8`에 허용하고 Squid를 실행하도록 되어 있다. MyWeb20·21에는 다음 환경 변수 설정이 들어 있다.

```bash
export http_proxy=http://10.19.1.101:3128
export https_proxy=http://10.19.1.101:3128
```

- TGW는 사설 네트워크 사이의 패킷을 라우팅한다.
- Squid는 클라이언트의 웹 요청을 받고 별도의 외부 연결을 만든다.
- IGW는 Public 프록시 서버의 인터넷 경로에 사용된다.

**Private EC2 → TGW → MyWeb19:3128 → Squid의 외부 연결 → IGW → 웹 서버**가 이번 자료와 연결되는 개념 흐름이다. TGW 자체가 NAT나 웹 Proxy 역할을 하는 것은 아니다.

남아 있는 HTTP 검증 결과:

```text
HTTP/1.1 200 OK
X-Cache: MISS from MyWeb19
Via: 1.1 MyWeb19 (squid/3.5.20)
```

해당 응답은 Squid를 경유해 HTTP 요청이 처리되었음을 뒷받침한다. `MISS`는 캐시 적중 실패이며 웹 요청 실패를 뜻하지 않는다. `https_proxy`가 템플릿에 있다는 이유만으로 실제 HTTPS 통신 성공까지 확정하지 않는다.

명시적인 복습 테스트:

```bash
curl -I -x http://10.19.1.101:3128 http://www.google.com
# 아래는 추가 검증용이며 오늘 성공 기록으로 간주하지 않는다.
curl -I -x http://10.19.1.101:3128 https://www.google.com
```

### 원본에서 발견한 환경 변수 보완점

`no_proxy=...` 줄에는 `export`가 없다. 새 셸에서 단순 셸 변수로만 설정되면 자식 프로세스가 받지 못할 수 있다. 또한 CIDR 예외 지원은 프로그램·버전에 따라 확인해야 한다.

```bash
# 복습용 보완 예시: 필요한 실제 호스트를 명시
export no_proxy=127.0.0.1,localhost,169.254.169.254,10.19.1.101,10.20.1.101,10.21.1.101,.internal
printenv | sort | rg -i 'proxy'
# 내부 웹 요청을 확실히 직접 보내려는 테스트
curl --noproxy '*' -I http://10.19.1.101
```

`/etc/bashrc` 변경 내용은 이미 실행 중인 셸에 자동 반영되지 않는다. 새 세션을 열거나 필요한 변수를 현재 셸에 설정한 뒤 확인한다.

## 10. ping.sh 해석과 다음 실습용 개선

오늘 스크립트는 `ping -c 1 -W 1`로 대상마다 한 번 검사한 뒤 성공·실패를 `up/down`으로 표시했다.

`down`의 정확한 의미는 **이번 검사에서 ICMP 응답 성공을 확인하지 못했다**는 것이다. EC2 전원 상태나 HTTP 서비스 상태를 직접 판별한 결과가 아니다. 이번 실습에서는 TGW 설정을 변경하며 추이를 관찰했다는 설명이 해석의 중심이다.

아래는 다음 실습에서 사용할 개선 예시다. 오늘 실행한 원본으로 기록하지 않는다.

```bash
#!/usr/bin/env bash
set -u
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
list_file="$script_dir/EC2_list.txt"
[[ -r "$list_file" ]] || { echo "IP 목록을 읽을 수 없습니다" >&2; exit 1; }
printf '=== Ping Test: %s ===\n' "$(date -Is)"
while IFS= read -r ip || [[ -n "$ip" ]]; do
  ip=${ip%$'\r'}
  [[ -z "$ip" || "$ip" == \#* ]] && continue
  if ping -c 3 -W 2 "$ip" >/dev/null 2>&1; then
    printf '%s ICMP 응답 확인\n' "$ip"
  else
    printf '%s ICMP 응답 확인 실패\n' "$ip"
  fi
done < "$list_file"
```

3회 검사도 안정성을 보장하지 않는다. 손실률·지연을 보려면 원본 ping 출력을 저장한다.

```bash
bash ./ping.sh | tee "ping-$(date +%Y%m%d-%H%M%S).log"
ping -c 10 -W 2 10.20.1.101
```

`ip route`는 EC2 OS의 경로만 보여 준다. AWS VPC/TGW Route Table의 전체 경로를 표시하는 명령이 아니다.

## 11. 문제를 확인하는 순서

| 증상 | 먼저 확인할 내용 |
|---|---|
| 다른 VPC Ping 실패 | EC2 상태 → SG ICMP → 실제 서브넷 Route Table → TGW Attachment/Association/Route → 반환 경로 → NACL/OS 방화벽 |
| Ping 성공, Proxy 실패 | TCP 3128 SG → Squid Listen/서비스 → Squid ACL → 클라이언트 변수 → Proxy 외부 경로/DNS |
| Proxy 성공, 직접 curl 실패 | 두 요청이 사용하는 목적지·경로·Proxy 환경 변수 차이 |
| S3 AccessDenied | IAM·Bucket·Endpoint Policy 확인, 라우팅 문제와 구분 |
| LB 대상 비정상 | 대상 포트·Health Check 경로·응답 코드·SG·NACL·웹 서버 |
| UserData 설치 실패 | cloud-init 로그·DNS·인터넷 경로·명령 오류 |

```bash
systemctl status squid
ss -lntp | rg ':3128'
sudo tail -n 50 /var/log/squid/access.log
sudo tail -n 50 /var/log/squid/cache.log
```

로그 끝의 `reboot: Power down`, `acpi_power_off called`와 서비스 정지 메시지는 OS 종료 절차 기록이다. 해당 줄만으로 장애나 종료 요청 주체를 확정하지 않는다.

## 12. 원본을 실무용으로 바꿀 때

이번 템플릿은 학습용 설정이다. 실무 재사용 시 아래 항목을 조정한다.

- UserData에 들어 있는 고정 root 비밀번호는 문서·공개 저장소에 복사하지 않는다. SSH 키 또는 SSM 접근과 최소 권한을 설계한다.
- SSH `0.0.0.0/0`, NAT 실습의 전체 UDP 허용은 필요한 출발지·포트로 줄인다.
- Squid 원본의 `http_access allow all`은 접속 가능한 클라이언트에 넓은 권한을 준다. 허용 CIDR·목적지·포트를 업무 요구에 맞게 제한한다. SG의 3128 제한과 Squid ACL은 별도로 관리한다.
- `10.0.0.0/8 → TGW`는 넓은 요약 경로다. 조직 주소 설계와 라우팅 분리 요구에 맞게 구체적인 경로 사용 여부를 결정한다.
- 템플릿의 AMI 파라미터는 Amazon Linux 2다. AL2는 2026-06-30에 지원이 종료되었으므로 새 환경에서는 지원되는 OS를 선택하고 UserData 명령을 재검토한다.[7]

## 13. 면접·시험 핵심 Q&A

**Q1. Private EC2가 S3에 접근하려면 반드시 NAT가 필요한가?**  
아니다. 같은 VPC에 S3 Gateway Endpoint를 구성하고 라우팅·권한 조건을 충족하면 NAT 없이 접근할 수 있다.

**Q2. IGW를 VPC에 붙이면 모든 EC2가 인터넷에 연결되는가?**  
아니다. IPv4 직접 인터넷 통신에는 해당 서브넷의 IGW 경로, EC2 공인 IPv4, 보안 정책 등이 필요하다.

**Q3. NAT 인스턴스에서 Source/Destination Check를 해제하는 이유는?**  
자신이 원래 출발지나 목적지가 아닌 패킷을 전달하는 장비로 사용하기 때문이다.

**Q4. ALB의 핵심 구성은?**  
Listener, 요청 Rule, Target Group, Target 및 Health Check다.

**Q5. Peering과 TGW 차이는?**  
Peering은 VPC 간 직접 연결이며 전이적 라우팅을 제공하지 않는다. TGW는 여러 네트워크를 연결하는 중앙 라우팅 허브다.

**Q6. TGW를 생성하고 Attachment를 붙이면 끝인가?**  
아니다. 서브넷의 VPC Route, Attachment Association, TGW 목적지 경로, 반환 경로와 보안 정책까지 확인한다.

**Q7. Association과 Propagation 차이는?**  
Association은 유입 트래픽이 조회할 TGW 테이블을 선택한다. Propagation은 네트워크 경로를 TGW 테이블에 게시한다.

**Q8. TGW가 있으면 인터넷 통신도 가능한가?**  
TGW 자체는 인터넷 출구·NAT·Proxy가 아니다. 이번에는 VPC19의 Public Squid 서버가 웹 요청을 중계했다.

**Q9. Ping 한 번 실패하면 EC2가 down인가?**  
아니다. 해당 ICMP 검사 실패다. 라우팅 변경, 정책, 지연 등 맥락과 EC2 상태를 함께 확인한다.

**Q10. CloudFormation 성공이면 콘솔 후속 실습까지 완료인가?**  
아니다. 템플릿에 포함된 리소스와 이후 수동 작업을 구분해야 한다. UserData 성공도 로그로 확인한다.

## 14. 다음 실습 기록 양식

| 시각 | 변경 대상 | 변경 전 | 변경 후 | 검증 위치·명령 | 실제 결과 |
|---|---|---|---|---|---|
| YYYY-MM-DD HH:MM | VPC Route/TGW Association 등 | 실제 값 | 실제 값 | MyWeb20 / ping 등 | 출력 또는 로그 파일명 |

설정 변경 전후에 시각과 터미널 출력을 남기고, 해당 Route Table의 목적지·대상·Association·Propagation 화면을 저장한다. AWS 리소스 ID, 인증 정보, 외부 공개 주소 등은 공개 문서에 올리기 전에 필요한 범위로 정리한다.

### GitHub 커밋용 요약

```text
docs: AWS Endpoint, NAT, LB, Peering, TGW 및 Squid 실습 정리

- CloudFormation 4개 템플릿의 기본 리소스와 후속 구성 범위 분석
- 강사 제공 가이드와 실제 검증 결과 구분
- TGW 설정 변경 중 ping.sh로 관찰한 통신 변화 기록
- Squid HTTP 응답 및 프록시 환경 변수 분석
- 라우팅 확인 순서, 기록 한계, 면접 Q&A 정리
```

## 15. 공식 문서

개념 보강은 AWS 공식 문서를 참고했다. 실제 계정의 설정 및 완료 여부는 첨부와 남아 있는 로그의 범위로만 판단했다.

1. [S3 Gateway Endpoint](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints-s3.html)
2. [NAT Instances](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_NAT_Instance.html)
3. [ALB Health Checks](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/target-group-health-checks.html)
4. [VPC Peering 동작과 제약](https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-basics.html)
5. [VPC Route Table 개념](https://docs.aws.amazon.com/vpc/latest/userguide/RouteTables.html)
6. [Transit Gateway Route Tables](https://docs.aws.amazon.com/vpc/latest/tgw/tgw-route-tables.html)
7. [Amazon Linux 2](https://docs.aws.amazon.com/linux/al2/ug/what-is-amazon-linux.html)
