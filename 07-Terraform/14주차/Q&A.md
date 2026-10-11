# AWS 일요일 실무 상황형 Q&A 20선

> 2026-10-11 (일) | 주제: AWS 네트워크 · EC2 · ALB/NLB · Terraform · CloudFormation · 트러블슈팅
>
> 학습 방식: **증상 → 확인 순서 → 원인 → 해결 → 면접 한 줄 답변**. 실제 환경에서 리소스를 변경하기 전 영향 범위와 비용을 확인하세요.

## 1. ALB 대상 EC2가 실행 중인데 Unhealthy입니다. 왜일까요?
**확인 순서**: 대상 그룹의 Health check 프로토콜/포트/경로/성공 코드 → 대상 등록 포트 → EC2 웹서버 리스닝 → EC2 보안 그룹에서 **ALB 보안 그룹을 소스로** 허용 → NACL/라우팅 → 애플리케이션 로그.

```bash
sudo ss -lntp
curl -i http://127.0.0.1/
sudo systemctl status httpd  # nginx라면 nginx 확인
```

**꼬리질문**: `/health`가 302를 반환하면? → 대상 그룹 Matcher의 성공 코드 설정에 따라 실패할 수 있습니다. 리다이렉트 원인을 확인하고 의도에 맞게 경로 또는 성공 코드 범위를 조정합니다.

## 2. ALB DNS는 접속되지만 `/dir1/index.html`은 404입니다.
ALB는 요청 경로를 자동으로 모든 EC2에 복제하지 않습니다. 각 대상의 콘텐츠와 리스너 규칙, 대상 그룹을 확인합니다. 경로 기반 라우팅을 구성하지 않았다면 요청이 해당 파일이 없는 인스턴스로 갈 수 있습니다.

**꼬리질문**: 해결책은? → 모든 대상에 동일 콘텐츠 배포 또는 `/dir1/*` 전용 대상 그룹으로 경로 기반 라우팅.

## 3. ALB로 100회 요청했는데 요청 수가 정확히 반반이 아닙니다.
로드밸런싱은 매번 정확한 50:50을 보장하지 않습니다. 알고리즘, 대상 상태, 연결 재사용, 세션 고정, 가중치, 요청 특성에 따라 달라집니다. 표본을 늘리고 대상 그룹 설정과 액세스 로그를 함께 확인합니다.

```bash
for i in {1..100}; do curl -s http://ALB_DNS/; done | grep MyWeb | sort | uniq -c
```

## 4. ALB와 NLB를 어떻게 선택합니까?
ALB는 L7 HTTP/HTTPS, 호스트/경로 기반 라우팅 및 HTTP 애플리케이션 기능에 적합합니다. NLB는 L4 TCP/UDP/TLS 등 연결 중심 처리, 고정 IP 요구 등에 적합합니다. NLB는 HTTP 경로 규칙을 직접 해석하지 않습니다.

**꼬리질문**: NLB 뒤의 서버에서 클라이언트 IP가 항상 보이나요? → 대상 유형과 프로토콜, 클라이언트 IP 보존 설정에 따라 다릅니다. Proxy Protocol v2도 고려합니다.

## 5. 인터넷에서 EC2에 접속되지 않습니다.
공인 IP/EIP 유무 → 서브넷의 `0.0.0.0/0 → IGW` 라우트 → IGW 연결 → 보안 그룹 인바운드 → NACL 양방향 규칙 → OS 방화벽 → 서비스 리스닝을 점검합니다. **공인 IP만 있다고 인터넷 접속이 보장되지는 않습니다.**

## 6. Private Subnet EC2에서 패키지 다운로드가 안 됩니다.
기본 경로가 NAT Gateway로 향하는지, NAT Gateway가 퍼블릭 서브넷에 있고 EIP와 IGW 경로를 갖는지, SG/NACL 및 DNS가 정상인지 확인합니다. NAT Gateway는 기본적으로 사설 인스턴스의 **아웃바운드 인터넷 접속**을 지원하며 인터넷에서 시작한 직접 인바운드 접속을 허용하지 않습니다.

## 7. VPC Peering은 Active인데 통신되지 않습니다.
양쪽 라우트 테이블에 상대 VPC CIDR을 피어링 연결 대상으로 추가했는지 → CIDR 중복 여부 → SG/NACL → OS 방화벽/서비스 포트 → DNS 설정을 확인합니다. **피어링은 전이 라우팅을 제공하지 않습니다.**

## 8. VPC A↔B, B↔C 피어링이면 A↔C도 되나요?
아닙니다. VPC Peering은 비전이적입니다. A↔C 직접 피어링을 추가하거나 Transit Gateway 등의 허브형 구조를 설계합니다.

## 9. Transit Gateway 연결만 만들면 모든 VPC가 통신합니까?
아닙니다. TGW 라우트 테이블의 Association/Propagation 또는 정적 경로, VPC 서브넷 라우트 테이블, SG/NACL, CIDR 중복을 확인해야 합니다. 네트워크 분리 정책에 따라 통신을 의도적으로 제한할 수 있습니다.

## 10. 두 VPC CIDR이 겹치면 어떻게 합니까?
일반적인 VPC Peering으로 중복 CIDR VPC를 연결할 수 없습니다. 주소 재설계가 우선이며, 상황에 따라 NAT/프록시/PrivateLink 기반 서비스 노출을 검토합니다. PrivateLink는 전체 VPC 라우팅 연결과 다릅니다.

## 11. VPC Endpoint와 Endpoint Service는 무엇이 다릅니까?
**Endpoint**는 소비자 VPC가 특정 AWS 서비스 또는 제공 서비스에 사설 연결하는 진입점입니다. **Endpoint Service**는 제공자가 주로 NLB/GWLB를 기반으로 자신의 서비스를 PrivateLink 소비자에게 노출하는 구성입니다. Gateway Endpoint(S3/DynamoDB)와 Interface Endpoint(ENI 기반)의 차이도 구분합니다.

## 12. S3 Gateway Endpoint를 만들었는데 다른 VPC에서도 바로 사용할 수 있나요?
Gateway Endpoint는 생성된 **해당 VPC**의 라우트 테이블과 연관됩니다. 다른 VPC에서 피어링/TGW를 통해 해당 Gateway Endpoint를 직접 공유해 사용하는 방식은 지원되지 않습니다. 각 VPC에 적절한 엔드포인트를 설계합니다.

## 13. Terraform `apply` 중 의존성 오류가 납니다.
참조 관계(`aws_vpc.x.id`)와 명시적 `depends_on`, 리소스 생성 순서, 외부에서 생성한 의존 리소스 여부를 확인합니다. Terraform은 일반적으로 리소스 참조로 의존성 그래프를 자동 구성하므로 `depends_on`을 무조건 남발하지 않습니다.

```bash
terraform fmt -check
terraform validate
terraform plan
terraform graph
```

## 14. Terraform 코드에서 리소스를 지우면 AWS에서도 지워지나요?
해당 리소스가 Terraform state로 관리 중이라면 일반적으로 다음 `plan/apply`에서 삭제가 계획됩니다. 다만 `prevent_destroy`, 의존성, 공급자 오류 등이 영향을 줍니다. 코드 삭제 전 반드시 plan을 검토합니다.

## 15. `terraform destroy -auto-approve`가 위험한 이유는?
확인 프롬프트를 생략하고 **현재 구성 및 state가 관리하는 리소스**의 삭제를 실행합니다. 모든 AWS 리소스를 무조건 삭제하는 명령은 아닙니다. 운영 환경에서는 별도 state, 권한 제한, 백업, plan 검토, 승인 절차가 중요합니다.

## 16. 누군가 콘솔에서 보안 그룹을 바꿨습니다. Terraform은 어떻게 반응하나요?
이는 **Configuration Drift**입니다. `terraform plan`에서 실제 상태와 코드의 차이를 확인하고, 코드로 원복할지 의도된 변경을 코드에 반영할지 결정합니다. 드리프트 탐지는 리소스와 provider의 동작에 영향을 받습니다.

## 17. Terraform state 파일을 GitHub에 올려도 될까요?
권장하지 않습니다. state에는 인프라 구성과 민감한 값이 포함될 수 있습니다. 원격 백엔드, 암호화, 접근 제어, 잠금 지원, `.gitignore`를 사용합니다. `.tfvars` 등 비밀값이 포함된 파일도 주의합니다.

## 18. CloudFormation 스택이 `ROLLBACK_COMPLETE`가 되었습니다.
CloudFormation Events에서 **최초 실패한 리소스와 Status reason**을 확인합니다. 권한 부족, 이름 중복, 잘못된 참조, 쿼터, 서브넷/AZ 제약 등이 원인일 수 있습니다. `ROLLBACK_COMPLETE` 상태의 생성 실패 스택은 일반적으로 삭제 후 수정된 템플릿으로 다시 생성해야 합니다.

## 19. CloudFormation과 Terraform 중 어느 쪽이 더 좋습니까?
정답은 요구사항에 달려 있습니다. CloudFormation은 AWS 네이티브 스택 관리에 강점이 있고 Terraform은 여러 provider와 모듈 생태계, 선언적 상태 관리에 강점이 있습니다. 둘 모두 변경 미리보기(Changeset/Plan), IaC 코드 리뷰, 권한 및 상태 관리가 중요합니다.

## 20. EC2 웹 서비스가 간헐적으로 끊깁니다. 무엇부터 조사합니까?
장애 범위(전체/일부 사용자)와 시점 파악 → ALB 4xx/5xx, TargetResponseTime, HealthyHostCount → EC2 CPU/메모리/디스크/네트워크 → 애플리케이션/웹서버 로그 → 연결 수/타임아웃 → SG/NACL/라우팅 및 배포 이력을 확인합니다. CloudWatch 기본 EC2 지표에는 메모리 사용률이 기본 포함되지 않으므로 CloudWatch Agent 등 추가 수집이 필요합니다.

---

# 1분 모범 답변 공식

1. **증상 구분**: 연결 자체 실패인가, HTTP 오류인가, 간헐적인가?
2. **네트워크 경로**: DNS → 라우팅 → SG/NACL → 대상 포트.
3. **서비스 상태**: 프로세스, 리스닝, Health Check, 로그.
4. **원인 검증**: 변경 이력과 관측 지표로 가설 확인.
5. **재발 방지**: 모니터링, IaC, 배포 검증, 최소 권한.

# 실습용 핵심 명령어 치트시트

```bash
# HTTP 상태 및 응답 헤더
curl -I http://HOST/
curl -v http://HOST/

# 서버 포트 및 프로세스
sudo ss -lntp
sudo systemctl status httpd
sudo journalctl -u httpd --since '30 minutes ago'

# 이름 해석 및 네트워크 경로
getent hosts example.com
ip route

# Terraform 검증과 변경 확인
terraform fmt -check
terraform validate
terraform plan
terraform state list

# AWS CLI (프로파일/권한/리전 사전 설정 필요)
aws sts get-caller-identity
aws elbv2 describe-target-health --target-group-arn TARGET_GROUP_ARN
aws ec2 describe-route-tables --filters Name=vpc-id,Values=VPC_ID
aws cloudformation describe-stack-events --stack-name STACK_NAME
```

# 셀프 모의면접 (정답 보기 전 30초씩 답하기)

- Q1. ALB Health Check 실패를 네트워크 문제와 애플리케이션 문제로 어떻게 분리할까요?
- Q2. NAT Gateway와 Internet Gateway의 역할 차이를 말해 보세요.
- Q3. Peering과 TGW에서 라우트 테이블을 확인해야 하는 이유는?
- Q4. Terraform의 코드, state, 실제 AWS 상태가 서로 다를 때 어떻게 대응하나요?
- Q5. 서비스 장애 시 무엇을 먼저 확인하고, 왜 그 순서로 확인하나요?

## 채점 기준 (각 20점, 총 100점)
- 정확한 핵심 개념 8점
- 확인 순서와 근거 6점
- 검증 명령어 또는 콘솔 확인 지점 4점
- 예방/보안/운영 고려 2점

**90~100점**: 실무 면접 답변 우수 · **70~89점**: 개념 양호, 장애 접근 보완 · **70점 미만**: 경로/의존성부터 재학습

---

> **이번 일요일의 핵심:** 명령어를 외우는 것보다, 어떤 증상이 어떤 계층에서 발생했는지 가설을 세우고 검증하는 능력이 더 중요합니다.
