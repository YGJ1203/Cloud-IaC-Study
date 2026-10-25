# 2026-10-25 (일) KAIST 하이브리드 클라우드 — EKS PPT 제작·발표자료 정리

> **오늘의 한 줄:** 기존에 검증한 EKS 실습 결과를 **발표용 증빙 자료 4장**으로 정리하고, 슬라이드의 코드·실행 결과·최종 홈페이지 화면을 논리적으로 연결했다.
>
> **문서 범위:** 오늘의 PPT 제작 과정, 슬라이드별 배치·문구·검증 기준, 월요일 후속 과제. **기존 10/23 구축 명령어·Terraform destroy 장애 분석·10/24 1차 총정리의 기술 내용을 반복하지 않는다.**

---

## 1. 오늘 실제로 한 일

| 작업 | 오늘 결정·완료한 내용 |
|---|---|
| PPT 구성 재검토 | EKS 클러스터/노드 그룹 관련 기존 장 다음에 **Controller → Deployment → Pod/ALB 검증 → 홈페이지 접속** 4장 구성 |
| YAML 원본 재확인 | `kaist-eks-homepage.yaml` 원본 확인 및 Deployment 코드 캡처 활용 결정 |
| 코드 슬라이드 제작 | Sublime Text에서 Deployment YAML을 **두 영역으로 나눠** 배치 |
| 검증 캡처 재발견 | `kubectl get pods`, `kubectl get ingress`, `curl -I`, `kubectl get nodes -o wide`가 한 화면에 들어 있는 기존 CMD 이미지 확인 |
| 실제 화면 슬라이드 | ALB 주소창이 보이는 KAIST 홈페이지 브라우저 캡처로 최종 성과 시각화 |
| Controller 슬라이드 | `aws-load-balancer-controller`의 `READY 2/2`, `AVAILABLE 2` 화면 활용 |
| 다음 일정 확정 | **CloudWatch는 월요일에 실제 구축·검증 후 PPT 작성** |

### 오늘의 핵심 판단

- **EKS PPT는 현재 자료로 충분하다.** 단, 기존 EKS 클러스터/노드 그룹 장이 팀 발표에 포함된다는 전제다.
- PPT 제작만을 위해 AWS 인프라를 다시 띄울 필요는 없다.
- **월요일 실시간 시연은 별도 과제**이므로, 그때는 신규 환경에서 실제 정상 동작을 다시 검증해야 한다.
- CloudWatch 완료 화면은 오늘 확인되지 않았으므로 성공으로 표시하지 않는다.

---

## 2. 슬라이드별 최종 편집 기록

### ① AWS Load Balancer Controller 설치 및 정상 동작

**상단 제목:** `EKS 구축`

**권장 부제:** `EKS - AWS Load Balancer Controller 설치 및 정상 동작 확인`

**중앙 이미지:** CMD의 다음 결과가 보이는 캡처

```text
kubectl get deployment aws-load-balancer-controller -n kube-system
NAME                           READY   UP-TO-DATE   AVAILABLE
aws-load-balancer-controller   2/2     2            2
```

**설명 핵심:**

- AWS Load Balancer Controller 설치
- Kubernetes Ingress와 AWS ALB 연동
- Controller Deployment의 복제본 2개 정상 실행 확인

**하단 권장 문구:**

> AWS Load Balancer Controller의 정상 실행을 확인하고, EKS 서비스의 외부 접근을 위한 ALB 연동 환경을 구성하였다.

**오늘 발견한 수정 사항:** 기존 부제의 `Load Balacer` 오타를 **`Load Balancer Controller`**로 수정하고, `EKS - EKS 구축`처럼 반복되는 표현을 제거한다. 부제와 이미지 사이의 과도한 여백도 줄이면 좋다.

**발표 포인트:** Controller가 `2/2`인 사실과 **실제 홈페이지 HTTP 200**은 서로 다른 증빙이다. 이 장은 Controller 실행 상태를 증명한다.

### ② Kubernetes Deployment를 활용한 KAIST 홈페이지 배포

**상단 제목:** `EKS 구축`

**권장 부제:** `EKS - Kubernetes Deployment를 활용한 KAIST 홈페이지 배포`

**중앙 이미지:** Sublime Text에서 촬영한 **Deployment YAML 코드 2개 영역**을 좌우 배치

- **왼쪽:** `apiVersion`, `kind: Deployment`, `metadata`, `replicas: 2`, `containers`, `image: nginx:stable-alpine`
- **오른쪽:** `volumeMounts`, `mountPath`, `subPath`, `readinessProbe`, `volumes`, `configMap`

두 이미지는 같은 Deployment 정의의 앞·뒷부분이므로, 필요하면 `Deployment YAML (계속)`을 오른쪽 위에 작게 표기한다.

**하단 권장 문구:**

> Nginx Deployment를 통해 KAIST 홈페이지 Pod 2개 구성  
> ConfigMap을 활용한 HTML 콘텐츠 마운트 및 Readiness Probe 설정  
> Service 및 Ingress를 통한 내부 서비스 연결과 ALB 외부 접속 연동

**중요한 표현 구분:** 이미지에 직접 보이는 것은 **Deployment의 코드**다. ConfigMap 자체의 정의, Service·Ingress 전체 설정은 해당 화면에 보이지 않으므로, 발표할 때는 “이 화면은 Deployment의 주요 설정을 보여준다”고 설명한다.

**오늘의 배운 점:** `ConfigMap·Deployment·Service·Ingress` 전체를 부제에 나열하기보다 **실제로 보이는 Deployment를 부제의 주인공으로 삼는 편이 정확하다.**

### ③ Kubernetes Pod 및 ALB 연동 정상 동작 검증

**상단 제목:** `EKS 구축`

**부제:** `EKS - Kubernetes Pod 및 ALB 연동 정상 동작 검증`

**중앙 이미지:** 기존에 올렸던 **한 장의 CMD 캡처**를 크게 배치. 한 화면에서 다음 결과가 확인된다.

| 화면의 영역 | 의미 | 실제 관찰 결과 |
|---|---|---|
| `kubectl get pods -l app=kaist-homepage` | 애플리케이션 실행 상태 | Pod 2개 모두 `1/1 Running` |
| `kubectl get ingress kaist-homepage` | ALB 연결 정보 | Ingress에 ALB DNS 주소 할당 |
| `curl -I http://...` | 외부 HTTP 응답 | `HTTP/1.1 200 OK` |
| `kubectl get nodes -o wide` | 워커 노드 상태 | 노드 2대 `Ready` |

**하단 권장 문구:**

> Nginx Pod 2개 정상 실행 및 EKS 워커 노드 2대 Ready 확인  
> Kubernetes Ingress에 AWS ALB DNS 주소 정상 할당  
> ALB를 통한 HTTP 요청 결과 200 OK 응답 확인

**오늘 발견한 편집상 주의점:** 원본 캡처 맨 위 초기 조회에서는 Pod 하나가 `0/1 Running`으로 보이지만, **바로 아래 재조회에서는 두 Pod가 모두 `1/1 Running`**이다. 발표용으로는 초기 조회 부분을 잘라내거나, 재조회 결과가 더 잘 보이도록 확대하면 혼동을 줄일 수 있다.

**정확성:** Pod의 `1/1`은 각 Pod 내 컨테이너 준비 상태다. Controller Deployment의 `2/2`와 혼동하지 않는다. HTTP 200만으로 고가용성 전체를 입증했다고 말하지 않는다.

### ④ KAIST 홈페이지 외부 접속 성공

**상단 제목:** `EKS 구축`

**부제:** `EKS - KAIST 홈페이지 외부 접속 성공`

**중앙 이미지:** ALB DNS가 보이는 **실제 브라우저의 KAIST 프로젝트 홈페이지 화면**을 슬라이드 중앙에 크게 배치한다. 이번 슬라이드에서는 코드보다 결과 화면이 핵심이다.

**하단 권장 문구:**

> AWS EKS 환경에 배포한 KAIST 홈페이지의 ALB를 통한 외부 접속 및 정상 표시 확인

**발표 포인트:** 앞 장의 명령어 결과는 기술적 검증, 이번 장의 브라우저 화면은 사용자 관점의 최종 검증이다.

**정확성:** 공식 KAIST 운영 사이트가 아니라 **프로젝트용 KAIST 홈페이지**임을 구두로 구분한다. 이전 환경의 ALB DNS 주소는 월요일 신규 배포에서 달라질 수 있다.

---

## 3. 오늘 정립한 PPT 디자인 원칙

1. **캡처에 실제 보이는 내용과 부제를 일치시킨다.** Deployment 코드만 보이면 Deployment를 중심으로 설명한다.
2. **한 슬라이드에 검증 메시지 하나.** Controller 실행 / YAML 구성 / 실행 검증 / 브라우저 결과를 구분한다.
3. **코드보다 읽히는 글씨가 중요하다.** CMD·Sublime 캡처를 지나치게 축소하지 않고, 불필요한 여백과 초기 실패·준비 중 화면은 필요 시 잘라낸다.
4. **하단 문구는 세 줄 안팎으로.** 기술 용어와 실제 관찰 결과를 간결하게 연결한다.
5. **증거의 수준을 구분한다.** YAML은 구성 증거, `kubectl`은 실행 증거, `curl`은 HTTP 응답 증거, 브라우저는 사용자 관점의 화면 증거다.
6. **팀 PPT 디자인을 유지한다.** 상단 `EKS 구축`, 중앙 부제, 큰 스크린샷, 하단 설명이라는 일관된 형식.

---

## 4. 발표 순서와 연결 멘트

```text
[기존] EKS 클러스터 및 관리형 노드 그룹 구축
    ↓
[추가 1] AWS Load Balancer Controller 정상 실행
    ↓
[추가 2] Nginx Deployment + ConfigMap HTML 마운트
    ↓
[추가 3] Pod/노드 Ready·Ingress DNS·HTTP 200 검증
    ↓
[추가 4] 실제 KAIST 홈페이지 브라우저 접속 성공
```

### 슬라이드 간 전환 멘트

- **Controller → Deployment:** “ALB와 연동할 수 있는 Controller를 준비한 뒤, 홈페이지를 제공할 Nginx Deployment를 구성했습니다.”
- **Deployment → 검증:** “YAML에 정의한 Pod와 네트워크 리소스가 실제로 정상 실행되는지 명령어로 확인했습니다.”
- **검증 → 홈페이지:** “HTTP 200 응답을 확인한 뒤, 실제 브라우저에서도 프로젝트 홈페이지가 정상 표시되는지 검증했습니다.”

### 30초 발표 요약

> “EKS 클러스터와 관리형 노드 그룹을 준비한 후, AWS Load Balancer Controller를 설치했습니다. 이어서 Nginx Deployment와 ConfigMap으로 프로젝트용 KAIST 홈페이지를 배포했습니다. Pod 2개와 워커 노드 2대의 정상 상태, Ingress의 ALB 주소 발급, HTTP 200 응답을 확인했으며, 마지막으로 실제 브라우저에서 홈페이지가 표시되는 것까지 검증했습니다.”

---

## 5. 일요일 최종 완료 판정과 남은 일

### 오늘 완료로 볼 수 있는 범위

- [x] EKS 추가 PPT **4장** 제작 및 대화에서 이미지로 확인
- [x] Deployment YAML 캡처 구성 정리
- [x] Pod·Ingress·HTTP 200·노드 Ready 검증 화면 확보
- [x] 브라우저 접속 성공 화면 배치
- [x] Controller `2/2` 증빙 배치
- [x] 각 슬라이드의 제목·부제·하단 설명 문구 점검

### 월요일 할 일 — 오늘의 완료 범위와 분리

- [ ] 카카오톡에 백업한 Terraform 프로젝트 ZIP을 확보하고 원본 상태 파일 보존
- [ ] AWS 실제 리소스 상태와 Terraform state 불일치 가능성 검토 후 재구축
- [ ] 새 환경에서 EKS/Controller/Pod/Ingress/HTTP 200/브라우저 접속 재검증
- [ ] **CloudWatch 실제 모니터링 구성·로그·메트릭 검증**
- [ ] 검증된 CloudWatch 캡처로 **2~3장** PPT 제작(실제 구현 범위에 따라 조정)
- [ ] 월요일 실시간 시연 영상 촬영 및 발표 자료 최종 점검
- [ ] 시연 후 과금 가능 리소스 정리 여부 확인

> **주의:** 10월 23일의 캡처는 그날의 구축 성공을 입증한다. 월요일의 재구축·실시간 시연 성공을 미리 보증하는 자료는 아니다.

---

## 6. 오늘의 복습 Q&A — PPT 발표 관점

**Q1. YAML을 Sublime Text에서 캡처해도 되나요?**  
A. 된다. 코드의 구성 의도를 보여주는 데 적합하다. 다만 실제 배포 성공은 `kubectl` 결과로 별도 증명한다.

**Q2. Deployment 코드만 보이는데 부제에 Service·Ingress까지 써도 되나요?**  
A. 기술적으로 같은 파일에 들어 있어도 해당 캡처에 보이지 않으므로, **Deployment 중심 부제**가 더 정확하다. Service·Ingress는 하단 설명과 후속 검증 장에서 연결한다.

**Q3. Pod·Ingress·curl·노드 상태를 한 장의 캡처로 보여줘도 되나요?**  
A. 된다. 단, 발표 화면에서 읽을 수 있도록 글자 크기와 크롭 범위를 조정한다.

**Q4. Controller의 `2/2`와 Pod의 `1/1`은 같은 의미인가요?**  
A. 아니다. Controller Deployment의 `2/2`는 준비된 복제본 수를, 각 Pod의 `1/1`은 준비된 컨테이너 수를 나타낸다.

**Q5. HTTP 200과 브라우저 화면을 굳이 다른 장에 넣는 이유는?**  
A. HTTP 응답 검증과 실제 사용자 화면 검증은 보여주는 관점이 다르기 때문이다. 두 장이 서로 보완한다.

**Q6. EKS PPT를 더 늘려야 하나요?**  
A. 오늘 확인한 구성만으로 **발표 목적상 충분하다.** 새로운 검증 항목이 없다면 장수를 늘리기보다 가독성을 높이는 편이 낫다.

**Q7. CloudWatch까지 완료라고 발표해도 되나요?**  
A. 아직 아니다. 월요일에 실제 구성·데이터 수집·화면 검증을 확인한 뒤 해당 부분을 작성한다.

---

## 7. 최종 요약

**오늘의 성과는 AWS 리소스를 추가로 만든 것이 아니라, 이미 성공한 실습을 청중에게 설득력 있게 보여주는 자료로 바꾼 것**이다.

- 기존 EKS 클러스터/노드 그룹 슬라이드 이후 **Controller → Deployment → 검증 → 실제 접속** 4장 완성
- 캡처에 보이는 사실과 슬라이드 문구의 일치 여부 점검
- PPT용 캡처와 월요일 실시간 시연 증거의 차이 구분
- CloudWatch는 월요일 작업으로 분리

**오늘의 MVP:** `HTTP/1.1 200 OK`가 보이는 CMD 검증 캡처 + 실제 KAIST 홈페이지 브라우저 화면 🏆

**한 줄 결론:** **일요일 EKS PPT 작업 종료, 월요일 CloudWatch 및 실시간 시연 준비!** 😎
