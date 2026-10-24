# KAIST HQ EKS · CloudWatch 프로젝트 1차 총정리

> 기준일: 2026-10-24 (토) | 범위: 10월 21~23일 진행 내용 및 다음 작업

## 1. 프로젝트 목표와 담당 범위

- **전체 목표:** Terraform 기반 KAIST HQ AWS 인프라와 Kubernetes 애플리케이션 환경을 연계하여 구성·검증하고 발표 자료를 준비한다.
- **담당:** HQ 측 Amazon EKS 및 CloudWatch, 클러스터·노드 상태 점검, 애플리케이션 접근 확인, 발표용 증거 수집.
- **역할 구분:** HQ 공통 네트워크·ALB·ASG·Aurora 등은 기존 Terraform 구성과 협업하고, EKS/CloudWatch는 콘솔 중심으로 진행한다. Kubernetes 리소스 배포는 YAML/Helm을 활용한다.
- **핵심 원칙:** 강사 PDF 교재 설정 우선. 다른 권장 구성은 별도 선택지로 명시하고, 보안상 위험이나 호환성 문제는 분명히 표시한다.

## 2. 기존 HQ 인프라와 EKS의 관계

| 영역 | 구성/확인 내용 | 관리 방식 |
|---|---|---|
| 리전 | 서울 `ap-northeast-2` | AWS |
| VPC | `KAVPC`, `10.0.0.0/16` | 기존 Terraform |
| 네트워크 | Public/Private Subnet, NAT Gateway, 라우팅 | 기존 Terraform |
| 웹 진입 | ALB 관련 리소스 | 기존 Terraform 및 실습 연동 |
| 컴퓨팅/DB | ASG/EC2, Aurora | 기존 Terraform |
| Kubernetes | `KAEKSConsoleLab` (교재 콘솔 실습), 별도 프로젝트 명칭 `KAEKSCluster` 논의 | EKS 콘솔 중심 |
| 관측 | CloudWatch / Container Insights | 후속 구축·검증 필요 |

**주의:** 교재 콘솔 클러스터와 프로젝트용 클러스터 명칭은 구분해야 한다. 10월 23일 시연 성공 사실을 다른 이름의 클러스터에 자동으로 귀속하지 않는다.

## 3. 날짜별 진행 이력

### 10월 21일 — 범위와 우선순위 확정
- HQ Terraform 소스에 VPC/서브넷/IGW/NAT/라우트, ALB, ASG, 내부 구성, RDS 등이 존재함을 확인.
- EKS 관련 Terraform 소스가 없는 상태에서 무리하게 전체 재구축하지 않기로 함.
- 우선순위: EKS 클러스터 → Worker Node → 배포 및 통신 확인 → PPT 증거.

### 10월 22일 — EKS 분리, 콘솔 실습, 상태 확인
- `C:\terraform\project-backup-before-console-eks`에 Terraform 백업을 수행.
- 기존 Terraform에서 EKS/IAM 관련 8개 리소스를 정리한 뒤 `No changes` 상태를 확인했던 시점이 있음.
- 콘솔 기반 `KAEKSConsoleLab` 구성: Kubernetes 1.37, Private Subnet 중심 노드 구성.
- `aws eks update-kubeconfig` 및 `kubectl` 연결 확인.
- Worker Node **2/2 Ready**, 시스템 Pod **13/13 Running**, 재시작 **0** 상태 확인.
- 노드에 공인 IP가 없는 구성 확인.
- 이 시점의 CloudWatch Container Insights와 Nginx는 완료로 간주하지 않음.

### 10월 23일 — 애플리케이션 접근 검증과 정리
- EKS와 ALB를 연계한 KAIST 홈페이지 접근 실습에서 HTTP **200 OK** 확인.
- Ingress/ALB 상태 확인을 포함한 검증 이력을 정리.
- 이후 리소스 정리 과정에서 Terraform `38 to destroy` 계획과 Subnet `DependencyViolation` 이슈가 언급됨.
- **삭제 계획 출력은 삭제 완료 증거가 아니다.** 실제 삭제 범위는 콘솔/CLI 재확인이 필요.
- PPT에는 실제 검증한 `Ready`, `Running`, `200 OK`만 명확하게 제시하기로 함.

## 4. 아키텍처 흐름

```text
사용자 브라우저
      |
      v
   ALB / Ingress
      |
      v
  Kubernetes Service
      |
      v
  EKS 애플리케이션 Pod
      |
      v
  Private Subnet의 Worker Node

[관측 경로 - 후속 검증 대상]
EKS 노드/Pod -> CloudWatch Agent 또는 관측 구성 -> CloudWatch Logs/Metrics
```

- ALB는 외부 HTTP(S) 요청의 진입점이며, Ingress와 연결된다.
- Service는 Kubernetes 내부에서 Pod 접근을 추상화한다.
- Worker Node는 Private Subnet에 배치되어 공인 IP 없이 운영될 수 있다.
- CloudWatch 관측 경로는 **구성 및 실제 데이터 수집 확인 전까지 완료로 표기하지 않는다.**

## 5. 검증 명령어 치트시트

```powershell
# EKS 클러스터 인증정보 갱신
aws eks update-kubeconfig --region ap-northeast-2 --name KAEKSConsoleLab

# 노드 상태
kubectl get nodes -o wide

# 모든 네임스페이스 Pod 확인
kubectl get pods -A

# Service 및 Ingress 확인
kubectl get svc -A
kubectl get ingress -A

# ALB 주소 확인 후 실제 DNS로 테스트
curl.exe -I http://<ACTUAL_ALB_DNS>

# Terraform 변경 예정 사항 확인 (삭제 전 필수)
terraform plan
```

> `KAEKSConsoleLab`은 교재 콘솔 실습 클러스터 이름이다. 실제 프로젝트용 클러스터를 따로 만들면 이름을 정확히 교체한다. ALB DNS는 해당 시점에 확인한 실주소만 사용한다.

## 6. 주요 트러블슈팅과 교훈

### Terraform State와 콘솔 리소스
- Terraform으로 관리하는 리소스와 콘솔에서 만든 리소스의 관리 경계가 다르다.
- `terraform plan`이 `No changes`라고 해도 콘솔 EKS의 존재·삭제 여부까지 보장하지 않는다.
- 반대로 `38 to destroy`는 계획이며, 실제 삭제 완료 여부는 별도 검증이 필요하다.

### Subnet `DependencyViolation`
- Subnet에 EKS 네트워크 인터페이스, 로드밸런서, NAT 등 종속 리소스가 남으면 삭제가 막힐 수 있다.
- 종속 관계를 먼저 조사하고 리소스별 정리 순서를 계획해야 한다.
- 프로젝트 공용 Terraform State를 무심코 `destroy`하지 않는다.

### 클러스터 검증과 서비스 검증은 다르다
- `Ready`는 노드 정상 등록, `Running`은 Pod 실행 상태, `200 OK`는 실제 HTTP 요청 성공을 뜻한다.
- 세 결과는 서로 다른 층의 증거이며, 각각의 명령어/콘솔 화면을 구분해서 보관한다.

## 7. PPT 1차 구성안

1. 담당 범위 및 HQ 전체 아키텍처에서 EKS의 위치
2. EKS 콘솔 생성 설정과 VPC/Private Subnet 선택
3. Worker Node `2/2 Ready` 검증
4. 시스템 Pod `Running` 검증
5. Ingress/ALB 구성 및 요청 경로
6. KAIST 홈페이지 HTTP `200 OK` 검증
7. 시행착오: Terraform과 콘솔 관리 경계, 의존성 오류
8. 최종 결과 및 후속 CloudWatch 계획

**디자인 규칙:** 팀 기존 PPT의 색상·폰트·레이아웃 유지. 검증하지 않은 성과는 넣지 않는다. CloudWatch 실제 수집 검증이 끝나면 2~3장을 별도로 추가한다.

## 8. 1차 완료/미완료 판정

| 항목 | 판정 | 근거/비고 |
|---|---|---|
| HQ Terraform 기반 구조 확인 | 완료 | 기존 VPC, ALB, ASG, Aurora 등 소스 확인 |
| 콘솔 EKS 구축·접속 | 완료 이력 | 10/22 실습 기준 |
| Worker Node 정상 등록 | 완료 이력 | 2/2 Ready |
| 시스템 Pod 정상 실행 | 완료 이력 | 13/13 Running, 재시작 0 |
| ALB/Ingress 웹 접근 | 완료 이력 | 10/23 HTTP 200 OK |
| CloudWatch Container Insights | 미검증 | 실제 수집 데이터 확인 필요 |
| 프로젝트 최종 재구축 | 확인 필요 | 실습 클러스터와 프로젝트 클러스터 구분 |
| 모든 AWS 리소스 삭제 | 확인 필요 | 삭제 계획과 완료 결과 구분 |
| 발표 PPT 최종본 | 진행 중 | 실제 증거 기반으로 마무리 |

## 9. 다음 실습 체크리스트

- [ ] AWS 콘솔에서 EKS/EC2/ALB/NAT/RDS 등 잔여 리소스 및 비용 확인
- [ ] 실제 프로젝트에서 사용할 클러스터 이름·환경 확정
- [ ] 교재 설정대로 EKS 및 노드 재구축(필요 시)
- [ ] `kubectl get nodes`, `kubectl get pods -A` 스크린샷 확보
- [ ] Ingress/ALB DNS와 HTTP 200 OK 재검증
- [ ] CloudWatch Container Insights 설정 및 로그/메트릭 수집 확인
- [ ] 팀 PPT에 검증 결과와 장애 해결 과정 반영
- [ ] 시연 종료 후 공용 인프라에 영향 없는 순서로 리소스 정리

## 10. 면접/발표 핵심 질문

**Q1. 왜 EKS Worker Node를 Private Subnet에 두나요?**  
A. 노드의 직접적인 인터넷 노출을 줄이고, 외부 트래픽은 ALB 등 통제된 진입점을 통해 받기 위해서입니다. 단, 이미지 다운로드와 AWS API 통신을 위한 NAT 또는 VPC Endpoint 등 경로를 확인해야 합니다.

**Q2. Terraform과 콘솔을 혼용하면 어떤 문제가 생기나요?**  
A. 상태 관리가 분리되어 드리프트나 삭제 순서 문제를 일으킬 수 있습니다. 소유권·관리 범위·종속 관계를 문서화해야 합니다.

**Q3. EKS 노드 Ready와 HTTP 200 OK는 무엇이 다른가요?**  
A. 전자는 Kubernetes 노드 상태이고, 후자는 ALB/Ingress/Service/Pod를 포함한 웹 요청 경로가 성공했다는 증거입니다.

**Q4. CloudWatch Container Insights를 검증하려면?**  
A. 필요한 관측 구성 요소를 설치·활성화한 후 CloudWatch에서 실제 클러스터·노드·Pod 메트릭 및 로그 유입 여부를 확인합니다. 설치만으로 완료 처리하지 않습니다.

**Q5. Subnet이 삭제되지 않을 때 어떻게 하나요?**  
A. ENI, EKS, ELB, NAT 등 의존 리소스를 확인하고 공용 리소스 여부를 검토한 후 역순으로 안전하게 정리합니다.

---

### 1차 결론

이번 주의 가장 큰 성과는 **기존 Terraform HQ 기반을 이해하고, 콘솔 EKS의 노드/Pod 정상 동작부터 ALB를 통한 HTTP 200 OK까지 실제 검증한 것**이다. 다음 단계의 핵심은 **재현 가능한 프로젝트 환경 확정, CloudWatch 실데이터 검증, 증거 중심 PPT 완성**이다.
