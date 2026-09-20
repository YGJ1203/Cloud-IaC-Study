 ☸️ Kubernetes 일요일 전용 Q&A

> **2026-09-20 · 이번 주 핵심 복습용**\
> 목표: 외우기보다 **"왜 이렇게 쓰는지"를 말로 설명할 수 있는지**
> 확인하기 😏

------------------------------------------------------------------------

## Q1. `apiVersion: v1`과 `apps/v1`은 왜 다를까요?

**A. 리소스가 속한 API 그룹이 다르기 때문입니다.**

-   `v1` : Pod, Service, ConfigMap, Secret, Namespace 등 핵심(Core)
    리소스
-   `apps/v1` : Deployment, ReplicaSet, StatefulSet, DaemonSet 등
    애플리케이션 관리 리소스

``` yaml
apiVersion: v1
kind: Pod
```

``` yaml
apiVersion: apps/v1
kind: Deployment
```

**한 줄 기억:** `kind`에 따라 사용할 `apiVersion`이 결정된다.

------------------------------------------------------------------------

## Q2. YAML에서 항목 순서는 중요한가요?

**A. 대부분의 Kubernetes 필드는 순서가 중요하지 않습니다.**

예를 들어 아래 둘은 의미가 같습니다.

``` yaml
resources:
  requests:
    cpu: 200m
  limits:
    cpu: "1"
```

``` yaml
resources:
  limits:
    cpu: "1"
  requests:
    cpu: 200m
```

단, **들여쓰기와 계층 구조는 매우 중요**합니다.

**한 줄 기억:** 순서보다 **구조와 들여쓰기**가 핵심.

------------------------------------------------------------------------

## Q3. `requests`와 `limits`의 차이는?

**A. `requests`는 스케줄링 기준, `limits`는 최대 사용 한도입니다.**

``` yaml
resources:
  requests:
    cpu: 200m
    memory: 500Mi
  limits:
    cpu: "1"
    memory: 1Gi
```

-   `requests` → "이 Pod를 배치하려면 최소 이 정도 자원이 필요합니다."
-   `limits` → "이 컨테이너는 최대 여기까지만 사용할 수 있습니다."

------------------------------------------------------------------------

## Q4. ReplicaSet과 Deployment는 무슨 차이인가요?

**A. ReplicaSet은 Pod 개수를 유지하고, Deployment는 ReplicaSet까지
관리합니다.**

``` text
Deployment
   ↓
ReplicaSet
   ↓
Pod Pod Pod
```

실무에서는 일반적으로 Pod 복제본을 직접 관리하기보다 **Deployment를
사용**합니다.

------------------------------------------------------------------------

## Q5. `replicas: 6`이면 Pod가 하나 죽었을 때 어떻게 되나요?

**A. 컨트롤러가 원하는 상태(desired state)를 맞추기 위해 새 Pod를
생성합니다.**

``` yaml
spec:
  replicas: 6
```

현재 5개뿐이라면 Kubernetes는 다시 6개가 되도록 조정합니다.

**핵심:** Kubernetes는 "명령 실행"보다 **선언한 상태를 계속 유지하는
시스템**입니다.

------------------------------------------------------------------------

## Q6. Label은 왜 필요한가요?

**A. Kubernetes 리소스를 분류하고 선택하기 위해 사용합니다.**

``` yaml
metadata:
  labels:
    app: apache
```

Service나 Controller는 Selector를 이용해 해당 Label을 가진 Pod를 찾을 수
있습니다.

``` yaml
selector:
  app: apache
```

**한 줄 기억:** `Label = 이름표`, `Selector = 이름표 검색기`.

------------------------------------------------------------------------

## Q7. Annotation은 Label과 무엇이 다른가요?

**A. Label은 선택/분류용이고, Annotation은 부가 정보 기록용입니다.**

``` yaml
metadata:
  annotations:
    description: "web server pod"
```

Annotation은 보통 Selector 대상으로 사용하지 않습니다.

------------------------------------------------------------------------

## Q8. Service가 필요한 이유는 무엇인가요?

**A. Pod의 IP가 변경되어도 안정적으로 접근할 수 있는 고정된 접점을
제공하기 때문입니다.**

``` text
Client
  ↓
Service
  ↓
Pod A
Pod B
Pod C
```

Service는 Selector를 이용해 대상 Pod를 찾고 트래픽을 전달합니다.

------------------------------------------------------------------------

## Q9. ClusterIP는 무엇인가요?

**A. 클러스터 내부에서 Service에 접근하기 위한 가상 IP입니다.**

``` yaml
spec:
  type: ClusterIP
  clusterIP: 10.233.10.10
```

기본 Service 타입도 `ClusterIP`입니다.

------------------------------------------------------------------------

## Q10. Headless Service는 무엇인가요?

**A. 일반적인 Service처럼 하나의 ClusterIP를 제공하지 않고, Pod들을 직접
찾을 수 있게 하는 Service입니다.**

``` yaml
spec:
  clusterIP: None
```

특히 StatefulSet처럼 **각 Pod를 개별적으로 식별해야 하는 환경**에서
유용합니다.

------------------------------------------------------------------------

## Q11. ConfigMap은 언제 사용하나요?

**A. 애플리케이션의 일반 설정값을 컨테이너 이미지와 분리할 때
사용합니다.**

``` yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: test-config
data:
  DB_HOST: mydb
```

이미지를 다시 빌드하지 않고 설정을 관리할 수 있다는 장점이 있습니다.

------------------------------------------------------------------------

## Q12. Secret은 ConfigMap과 무엇이 다른가요?

**A. Secret은 비밀번호, 토큰 등 민감한 값을 다루기 위한 Kubernetes
리소스입니다.**

``` yaml
apiVersion: v1
kind: Secret
metadata:
  name: test-secret
type: Opaque
stringData:
  project.id: webserver-1234
  project.user: webadmin
  project.pass: abcd1234
```

`stringData`는 평문 문자열을 작성하면 Kubernetes가 저장 과정에서 처리해
주므로 실습할 때 편리합니다.

> ⚠️ Secret의 기본 저장 방식 자체를 "강력한 암호화"라고 생각하면 안
> 됩니다. Base64 인코딩은 암호화가 아닙니다.

------------------------------------------------------------------------

## Q13. `type: Opaque`는 무엇인가요?

**A. 사용자가 정의한 일반적인 Key-Value 형태의 Secret이라는
의미입니다.**

``` yaml
type: Opaque
```

특별한 Secret 타입이 필요하지 않을 때 자주 사용하는 기본적인 형태입니다.

------------------------------------------------------------------------

## Q14. Liveness Probe와 Readiness Probe 차이는?

**A. 질문 자체가 다릅니다.**

-   **Liveness** → "컨테이너가 살아 있는가?"
-   **Readiness** → "지금 트래픽을 받아도 되는가?"

``` yaml
livenessProbe:
  httpGet:
    path: /
    port: 80

readinessProbe:
  httpGet:
    path: /
    port: 80
```

Liveness 실패는 컨테이너 재시작으로 이어질 수 있고, Readiness 실패
시에는 해당 Pod가 Service 트래픽 대상에서 제외될 수 있습니다.

------------------------------------------------------------------------

## Q15. Static Pod는 일반 Pod와 무엇이 다른가요?

**A. API를 통해 직접 생성하는 방식이 아니라 특정 Node의 kubelet이
manifest를 보고 직접 관리합니다.**

대표적으로 kubelet의 static Pod manifest 디렉터리에 YAML을 배치하여
구성합니다.

**한 줄 기억:** Static Pod의 주인공은 **kubelet**.

------------------------------------------------------------------------

# 🔥 최종 연결 문제

### Q. 사용자가 웹 서비스에 접속했을 때 Kubernetes 내부 흐름을 간단히 설명한다면?

``` text
사용자 요청
    ↓
외부 진입점 / Load Balancer
    ↓
Service
    ↓  selector
Label이 일치하는 Pod들
    ↓
Container
    ↓
Application
```

그리고 뒤에서는:

``` text
Deployment
   ↓ 관리
ReplicaSet
   ↓ 개수 유지
Pods
```

설정값은:

``` text
ConfigMap → 일반 설정
Secret    → 민감 설정
```

상태 확인은:

``` text
Liveness  → 살아 있는가?
Readiness → 요청을 받을 준비가 됐는가?
```

------------------------------------------------------------------------

# 😏 일요일 30초 체크

아래 질문에 **명령어를 보지 않고 한 문장으로 답할 수 있으면 이번 주 복습
성공**입니다.

1.  Deployment와 ReplicaSet의 관계는?
2.  Label과 Selector는 어떻게 연결되는가?
3.  Pod IP 대신 Service를 사용하는 이유는?
4.  ClusterIP와 Headless Service의 차이는?
5.  ConfigMap과 Secret의 차이는?
6.  `requests`와 `limits`의 차이는?
7.  Liveness와 Readiness의 차이는?
8.  Static Pod는 누가 직접 관리하는가?

------------------------------------------------------------------------

## 🏀 이번 주 한 줄

> **YAML을 통째로 암기하는 단계 → 리소스들이 서로 왜 연결되는지 이해하는
> 단계로 넘어가는 주간.**

``` text
Pod
 ↑
ReplicaSet
 ↑
Deployment

Pod ← Label/Selector → Service

Pod ← ConfigMap / Secret
Pod ← Probe / Resources
```

이 그림이 머릿속에 잡히면 Kubernetes가 슬슬 **"각각의 명령어"가 아니라
"하나의 시스템"**으로 보이기 시작합니다. 😏☸️
