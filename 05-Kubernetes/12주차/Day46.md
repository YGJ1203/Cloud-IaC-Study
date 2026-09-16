# ☸️ Kubernetes Controller & Service 실습 총정리

> **실습일:** 2026-09-16\
> **환경:** CentOS Stream 9 / Kubernetes v1.27.7 / Master + Node1\~3 /
> HAProxy\
> **핵심 흐름:**
> `RC → ReplicaSet → Deployment → Service → ClusterIP → NodePort → LoadBalancer`

------------------------------------------------------------------------

## 0. 오늘의 한 장 요약

오늘 실습은 크게 두 덩어리다.

``` text
[Pod 관리]
ReplicationController
        ↓
ReplicaSet
        ↓
Deployment
        ↓
      Pod

[Pod 접근]
Client
  ↓
Service
  ├─ ClusterIP
  ├─ NodePort
  └─ LoadBalancer
        ↓
      Pod
```

### 반드시 기억할 3문장

1.  **Controller는 원하는 개수의 Pod를 유지한다.**
2.  **Deployment는 ReplicaSet을 관리하고, ReplicaSet은 Pod를 관리한다.**
3.  **Service는 label/selector로 Pod를 찾아 안정적인 접근 지점을
    제공한다.**

------------------------------------------------------------------------

# 1. Kubernetes Controller

## 1-1. ReplicationController (RC)

RC는 지정한 `replicas` 수만큼 Pod가 존재하도록 유지한다.

``` text
ReplicationController
       │
       ├── Pod
       ├── Pod
       └── Pod
```

예를 들어 `replicas: 3`이면 Pod 하나를 삭제해도 RC가 다시 생성하여 3개를
맞춘다.

### 핵심 YAML 구조

``` yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: nginx-rc

spec:
  replicas: 3

  selector:
    app: webui

  template:
    metadata:
      labels:
        app: webui

    spec:
      containers:
        - name: nginx-pod
          image: nginx:1.14
          ports:
            - containerPort: 80
```

### 핵심 명령어

``` bash
kubectl create -f nginx-rc.yml
kubectl get rc,pod -o wide
kubectl describe rc nginx-rc

kubectl scale rc nginx-rc --replicas 2

kubectl delete pod <POD_NAME>
kubectl delete pod --all

kubectl delete -f nginx-rc.yml
```

### 실습에서 확인한 Self-Healing

Pod를 직접 삭제해도:

``` bash
kubectl delete pod nginx-rc-5xqtt
```

잠시 후 새로운 Pod가 생성되었다.

``` text
기존 Pod 삭제
     ↓
현재 Pod 수 < replicas
     ↓
RC가 차이를 감지
     ↓
새로운 Pod 생성
     ↓
Desired State 복구
```

> **핵심:** Kubernetes Controller는 현재 상태(Current State)를 원하는
> 상태(Desired State)에 맞추려 한다.

------------------------------------------------------------------------

# 2. ReplicaSet (RS)

ReplicaSet도 지정한 수만큼 Pod를 유지한다.

RC와 비슷하지만 `apps/v1`을 사용하며 selector 구조에 `matchLabels`가
사용된다.

``` yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-rs

spec:
  replicas: 3

  selector:
    matchLabels:
      app: webui

  template:
    metadata:
      labels:
        app: webui

    spec:
      containers:
        - name: nginx-pod
          image: nginx:1.14
          ports:
            - containerPort: 80
```

### 중요한 연결 조건

``` yaml
selector:
  matchLabels:
    app: webui
```

와

``` yaml
template:
  metadata:
    labels:
      app: webui
```

가 서로 일치해야 한다.

``` text
ReplicaSet selector
   app=webui
       │
       ▼
Pod label
   app=webui
```

### 핵심 명령어

``` bash
kubectl create -f nginx-rs-1.yml

kubectl get rs,pod -o wide
kubectl describe rs nginx-rs

kubectl scale rs nginx-rs --replicas=6

kubectl delete -f nginx-rs-1.yml
```

------------------------------------------------------------------------

# 3. Deployment

## 3-1. 관계부터 이해하기

Deployment를 생성하면 실제 Pod 관리 구조는 다음과 같다.

``` text
Deployment
    │
    ▼
ReplicaSet
    │
    ▼
   Pods
```

즉:

-   **Deployment:** 배포 전체 관리
-   **ReplicaSet:** Pod 개수 유지
-   **Pod:** 실제 Container 실행

### 기본 YAML

``` yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deploy

spec:
  replicas: 3

  selector:
    matchLabels:
      app: webui

  template:
    metadata:
      labels:
        app: webui

    spec:
      containers:
        - name: nginx-container
          image: nginx:1.14
          ports:
            - containerPort: 80
```

### 확인

``` bash
kubectl create -f nginx-deploy.yml

kubectl get deploy,rs,pod -o wide
```

여기서 Deployment → ReplicaSet → Pod가 동시에 보인다.

------------------------------------------------------------------------

## 3-2. Scaling

Pod 개수를 변경할 수 있다.

``` bash
kubectl scale deployment nginx-deploy --replicas 6
```

다시 3개로:

``` bash
kubectl scale deployment nginx-deploy --replicas 3
```

``` text
replicas: 3
    ↓
Pod Pod Pod

replicas: 6
    ↓
Pod Pod Pod Pod Pod Pod
```

------------------------------------------------------------------------

# 4. Deployment Rolling Update / Rollback

Deployment의 중요한 장점 중 하나는 이미지 업데이트와 롤백이다.

### 이미지 업데이트

``` bash
kubectl set image deploy nginx-deploy \
nginx-container=nginx:1.15
```

확인:

``` bash
kubectl describe pod | grep -i image:
```

실습에서는 `nginx:1.14 → 1.15 → 1.16 → 1.17 → 1.18` 형태로 변경하며
revision을 확인했다.

### Rollout History

``` bash
kubectl rollout history deployment nginx-deploy
```

예:

``` text
REVISION
1
2
3
4
5
```

### 바로 이전 버전으로 Rollback

``` bash
kubectl rollout undo deployment nginx-deploy
```

### 특정 Revision으로 Rollback

``` bash
kubectl rollout undo deployment nginx-deploy --to-revision 2
```

### ⚠️ `--record`

실습 로그에서는 다음과 같이 사용했다.

``` bash
kubectl create -f nginx-deploy.yml --record
kubectl set image deploy nginx-deploy nginx-container=nginx:1.15 --record
```

실제 출력에서 `--record has been deprecated` 경고가 발생했다.

따라서 **오늘 실습에서 사용한 옵션이지만 deprecated 상태라는 점을 같이
기억한다.**

------------------------------------------------------------------------

# 5. Service가 필요한 이유

Pod는 Controller에 의해 삭제되고 다시 만들어질 수 있다.

``` text
Pod A
10.233.x.x
   ↓ 삭제
새 Pod B
10.233.y.y
```

따라서 Client가 특정 Pod IP만 알고 접근하는 구조는 불편하다.

Service가 앞에 위치하면:

``` text
Client
   ↓
Service
   ↓
┌──┼──┐
Pod Pod Pod
```

Client는 개별 Pod IP를 직접 신경 쓰지 않고 **Service라는 고정된 접근
지점**을 이용할 수 있다.

------------------------------------------------------------------------

# 6. Service와 Label / Selector

오늘 가장 중요한 연결고리 중 하나.

Deployment의 Pod:

``` yaml
template:
  metadata:
    labels:
      app: apache
```

Service:

``` yaml
selector:
  app: apache
```

즉:

``` text
Service
selector: app=apache
       │
       │ Matching
       ▼
Pod
label: app=apache
```

> **selector와 label이 맞아야 Service가 원하는 Pod를 backend로 선택할 수
> 있다.**

------------------------------------------------------------------------

# 7. ClusterIP

## 개념

ClusterIP는 Kubernetes Service의 내부 접근용 형태다.

오늘 실습에서는:

``` text
ClusterIP = 10.233.10.10
Service Port = 80
Pod TargetPort = 80
```

### YAML

``` yaml
apiVersion: v1
kind: Service
metadata:
  name: httpd-svc1

spec:
  type: ClusterIP
  clusterIP: 10.233.10.10

  selector:
    app: apache

  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

### 적용

``` bash
kubectl create -f httpd_svc1.yml
kubectl get svc
```

### 테스트

``` bash
curl http://10.233.10.10
```

실습에서는 여러 번 요청했을 때:

``` text
#2# Test Page
#6# Test Page
#3# Test Page
#1# Test Page
#5# Test Page
#4# Test Page
```

처럼 여러 Apache Pod가 응답하는 것을 확인했다.

### 흐름

``` text
Master
  │
  │ curl 10.233.10.10:80
  ▼
ClusterIP Service
10.233.10.10:80
  │
  │ selector app=apache
  ▼
Apache Pods
```

------------------------------------------------------------------------

# 8. `port`와 `targetPort`

Service YAML에서 매우 중요하다.

``` yaml
ports:
  - port: 80
    targetPort: 80
```

의미:

``` text
Client
   │
   ▼
Service :80       ← port
   │
   ▼
Pod :80           ← targetPort
```

즉:

-   `port`: Service가 제공하는 포트
-   `targetPort`: 실제 Pod로 전달할 목적지 포트

------------------------------------------------------------------------

# 9. NodePort

## 개념

NodePort는 Node의 IP와 특정 포트를 통해 Service에 접근하게 한다.

오늘 실습:

``` text
ClusterIP = 10.233.10.10
Service Port = 80
NodePort = 31000
```

### YAML

``` yaml
apiVersion: v1
kind: Service
metadata:
  name: httpd-svc2

spec:
  type: NodePort
  clusterIP: 10.233.10.10

  selector:
    app: apache

  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 31000
```

### 확인

``` bash
kubectl create -f httpd_svc2.yml
kubectl get svc
```

출력에서:

``` text
80:31000/TCP
```

를 확인했다.

해석:

``` text
Service Port : 80
NodePort     : 31000
```

------------------------------------------------------------------------

# 10. 오늘 Kubernetes Node 구성

``` text
master   192.168.2.60
node1    192.168.2.61
node2    192.168.2.62
node3    192.168.2.63
```

확인:

``` bash
kubectl get nodes -o wide
```

NodePort 테스트:

``` bash
curl http://192.168.2.61:31000
```

여러 번 요청했을 때 서로 다른 Apache Test Page가 응답했다.

### 흐름

``` text
Client
  │
  │ 192.168.2.61:31000
  ▼
NodePort :31000
  │
  ▼
Service :80
  │
  ▼
Pod :80
```

### 포트 3종 암기

``` text
NodePort
 31000
   ↓
Service port
   80
   ↓
targetPort
   80
```

------------------------------------------------------------------------

# 11. LoadBalancer + HAProxy

오늘 실습에서는 별도의 LoadBalancer 서버를 사용했다.

``` text
LoadBalancer
192.168.2.80
```

Kubernetes Service:

``` yaml
apiVersion: v1
kind: Service
metadata:
  name: httpd-svc3

spec:
  type: LoadBalancer
  clusterIP: 10.233.10.10

  selector:
    app: apache

  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 31000
```

적용:

``` bash
kubectl create -f httpd_svc3.yml
kubectl get svc
```

실습 환경에서는:

``` text
TYPE           LoadBalancer
CLUSTER-IP     10.233.10.10
EXTERNAL-IP    <pending>
PORT(S)        80:31000/TCP
```

형태로 확인되었다.

------------------------------------------------------------------------

# 12. HAProxy 구성

LoadBalancer 서버:

``` text
192.168.2.80
```

HAProxy 설치:

``` bash
yum -y install haproxy
```

설정:

``` bash
vi /etc/haproxy/haproxy.cfg
```

Kubernetes 실습에서 중요한 부분:

``` text
frontend main
    bind *:80
    default_backend app

backend app
    balance roundrobin
    server app1 192.168.2.61:31000 check
    server app2 192.168.2.62:31000 check
    server app3 192.168.2.63:31000 check
```

### 해석

``` text
frontend
   ↓
외부 요청을 받음

default_backend app
   ↓
app backend로 전달

backend app
   ↓
roundrobin 방식으로 분산

server app1/app2/app3
   ↓
Kubernetes NodePort로 전달
```

전체 경로:

``` text
Master / Client
       │
       │ http://192.168.2.80:80
       ▼
┌───────────────────────┐
│ HAProxy               │
│ 192.168.2.80:80       │
└───────────┬───────────┘
            │ roundrobin
     ┌──────┼──────┐
     ▼      ▼      ▼
  Node1   Node2   Node3
   .61     .62     .63
 :31000  :31000  :31000
     └──────┼──────┘
            ▼
      Kubernetes Service
            │
            ▼
       Apache Pods ×6
```

### 설정 검사

``` bash
haproxy -c -f /etc/haproxy/haproxy.cfg
```

정상:

``` text
Configuration file is valid
```

### 서비스 시작

``` bash
systemctl enable --now haproxy.service
systemctl restart haproxy.service
systemctl status haproxy
```

------------------------------------------------------------------------

# 13. LoadBalancer 최종 테스트

Master에서:

``` bash
curl http://192.168.2.80
```

여러 번 요청하여 서로 다른 Test Page 응답을 확인했다.

``` text
#4# Test Page
#6# Test Page
#3# Test Page
#5# Test Page
...
```

즉:

``` text
Client
 ↓
HAProxy
 ↓
NodePort
 ↓
Service
 ↓
Pod
```

경로가 실제로 동작했다.

------------------------------------------------------------------------

# 14. Apache Deployment 최종 종합 실습

조건:

``` text
Pod 수          : 6
Label           : app=apache
Deployment      : httpd-deploy
Container       : apache-web
Image           : httpd:2.2
```

### YAML

``` yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpd-deploy

spec:
  replicas: 6

  selector:
    matchLabels:
      app: apache

  template:
    metadata:
      labels:
        app: apache

    spec:
      containers:
        - name: apache-web
          image: httpd:2.2
          ports:
            - containerPort: 80
```

적용:

``` bash
kubectl create -f httpd_deploy.yml
kubectl get deployments.apps,rs,pod -o wide
```

### 각 Pod 구분

``` bash
kubectl exec -it pod/<POD_NAME> -- /bin/bash
```

Apache DocumentRoot:

``` text
/usr/local/apache2/htdocs/
```

예:

``` bash
echo '<h1>#1# Test Page</h1>' \
> /usr/local/apache2/htdocs/index.html
```

Pod마다 `#1 ~ #6`을 넣어 Service의 분산 결과를 눈으로 확인했다.

------------------------------------------------------------------------

# 15. 오늘의 트러블슈팅 ☠️

## 15-1. `spec.seletor`

오류:

``` text
strict decoding error:
unknown field "spec.seletor"
```

원인:

``` yaml
seletor:
```

오타.

수정:

``` yaml
selector:
```

### 교훈

Kubernetes YAML은 필드 이름을 정확히 작성해야 한다.

------------------------------------------------------------------------

## 15-2. Deployment의 잘못된 API Version

오류:

``` text
no matches for kind "Deployment" in version "v1"
```

원인:

``` yaml
apiVersion: v1
kind: Deployment
```

수정:

``` yaml
apiVersion: apps/v1
kind: Deployment
```

암기:

``` text
Pod / Service / RC
    → v1

ReplicaSet / Deployment
    → apps/v1
```

------------------------------------------------------------------------

## 15-3. `targetport` 오타

오류:

``` text
unknown field "spec.ports[0].targetport"
```

잘못:

``` yaml
targetport: 80
```

정상:

``` yaml
targetPort: 80
```

> YAML/Kubernetes 필드명은 대소문자까지 정확해야 한다.

------------------------------------------------------------------------

## 15-4. Service Port Name 대문자

실습 중 Service port name을 `testSVC`로 작성했을 때 RFC 1123 규칙 오류가
발생했다.

수정:

``` yaml
name: testsvc
```

핵심:

``` text
Service port name
→ 소문자 영숫자와 '-' 사용
```

------------------------------------------------------------------------

## 15-5. kubectl 명령어 오타

실습에서 나온 예:

``` bash
jubectl
kubectl descrobe
kubectl rollout hisotry
```

정상:

``` bash
kubectl
kubectl describe
kubectl rollout history
```

이런 오타는 개념 문제가 아니라 단순 명령어 입력 문제이므로 에러 메시지를
보고 차분하게 수정한다.

------------------------------------------------------------------------

## 15-6. `kubectl delete pod -all`

잘못:

``` bash
kubectl delete pod -all
```

오류:

``` text
unknown shorthand flag: 'a' in -all
```

정상:

``` bash
kubectl delete pod --all
```

------------------------------------------------------------------------

## 15-7. HAProxy `static` backend DOWN

기본 HAProxy 설정에는 다음과 같은 static backend가 존재할 수 있다.

``` text
backend static
    server static 127.0.0.1:4331 check
```

해당 주소에서 실제 서비스가 실행되지 않으면:

``` text
Server static/static is DOWN
backend 'static' has no server available
```

경고가 발생할 수 있다.

오늘 Kubernetes 실습의 핵심 backend는 `app` 쪽이다.

------------------------------------------------------------------------

# 16. Controller 비교

  항목                        RC               ReplicaSet             Deployment
  --------------------------- ---------------- ---------------------- ----------------
  목적                        Pod 개수 유지    Pod 개수 유지          배포 전체 관리
  API                         `v1`             `apps/v1`              `apps/v1`
  Selector                    `selector`       `matchLabels`          `matchLabels`
  Scaling                     가능             가능                   가능
  Pod Self-Healing            가능             가능                   가능
  Rolling Update / Rollback   직접 관리 필요   직접 관리 필요         지원
  실무 관점 핵심              과거 방식 이해   Deployment 하위 계층   ⭐ 중심

### 가장 중요한 관계

``` text
Deployment
    ↓
ReplicaSet
    ↓
Pod
```

------------------------------------------------------------------------

# 17. Service 비교

  Type           접근 형태           오늘 실습
  -------------- ------------------- ----------------------
  ClusterIP      `ClusterIP:Port`    `10.233.10.10:80`
  NodePort       `NodeIP:NodePort`   `192.168.2.61:31000`
  LoadBalancer   외부 LB 주소        `192.168.2.80:80`

관계를 한 줄로 보면:

``` text
LoadBalancer
     ↓
NodePort
     ↓
ClusterIP / Service
     ↓
Pod
```

> 위 그림은 오늘 실습의 트래픽 흐름을 이해하기 위한 단순화된 표현이다.

------------------------------------------------------------------------

# 18. 오늘의 초압축 암기 카드 🧠

``` text
Pod
= Container를 실행하는 Kubernetes의 기본 실행 단위

ReplicaSet
= Pod 개수를 유지

Deployment
= ReplicaSet을 이용해 Pod 배포/업데이트/롤백 관리

Service
= Pod에 접근하는 안정적인 입구

ClusterIP
= Cluster 내부 Service 접근

NodePort
= NodeIP:Port로 접근

LoadBalancer
= 외부 LoadBalancer를 통해 접근

Label
= Pod에게 붙이는 이름표

Selector
= 원하는 Label의 Pod를 찾는 조건
```

------------------------------------------------------------------------

# 19. 장애 발생 시 점검 순서

오늘 실습 기준으로 아래 순서대로 보면 좋다.

``` bash
# 1. Node 상태
kubectl get nodes -o wide

# 2. Deployment / ReplicaSet / Pod
kubectl get deploy,rs,pod -o wide

# 3. Service
kubectl get svc

# 4. Service 상세
kubectl describe svc <SERVICE_NAME>

# 5. Endpoint 확인
kubectl get endpoints

# 6. Pod Label 확인
kubectl get pod --show-labels

# 7. Pod 직접 확인
kubectl describe pod <POD_NAME>

# 8. ClusterIP 테스트
curl http://<CLUSTER_IP>

# 9. NodePort 테스트
curl http://<NODE_IP>:<NODE_PORT>

# 10. LoadBalancer 테스트
curl http://192.168.2.80
```

### 문제를 보는 사고방식

``` text
Pod가 살아 있는가?
       ↓ YES
Service selector가 Pod label과 맞는가?
       ↓ YES
Endpoint가 생성됐는가?
       ↓ YES
ClusterIP가 되는가?
       ↓ YES
NodePort가 되는가?
       ↓ YES
HAProxy backend가 NodePort를 가리키는가?
       ↓ YES
LoadBalancer IP로 접근되는가?
```

이 순서로 보면 복잡한 Kubernetes 네트워크 문제도 **구간별로 잘라서**
확인할 수 있다.

------------------------------------------------------------------------

# 20. Docker와 Kubernetes 연결하기

Docker에서 배운 내용과 연결하면 이해가 쉬워진다.

``` text
Docker
Image
 ↓
Container
 ↓
Port

Kubernetes
Image
 ↓
Container
 ↓
Pod
 ↓
Deployment
 ↓
Service
```

Docker에서:

``` bash
docker run -d -p 8080:80 nginx
```

를 사용했다면 Kubernetes에서는 Container 실행뿐 아니라:

``` text
Pod 관리
복제
장애 복구
배포
Service를 통한 접근
```

까지 Kubernetes가 관리하는 방향으로 확장된다고 이해한다.

------------------------------------------------------------------------

# 21. 면접/복습 Q&A

### Q1. Pod와 Deployment의 차이는?

**Pod**는 Container를 실행하는 기본 단위이고, **Deployment**는
ReplicaSet을 통해 여러 Pod의 배포와 상태를 관리한다.

### Q2. Pod를 삭제했는데 왜 다시 생성되는가?

Controller가 `replicas`에 정의된 Desired State와 현재 상태를 비교하여
부족한 Pod를 다시 생성하기 때문이다.

### Q3. ReplicaSet과 Deployment의 관계는?

Deployment가 ReplicaSet을 관리하고 ReplicaSet이 Pod 개수를 유지한다.

``` text
Deployment → ReplicaSet → Pod
```

### Q4. Service가 필요한 이유는?

Pod는 재생성되면서 개별 IP가 바뀔 수 있으므로 Service가 Pod 집합에
접근하기 위한 안정적인 지점을 제공한다.

### Q5. Service는 Pod를 어떻게 찾는가?

`selector`와 Pod의 `label`을 비교하여 일치하는 Pod를 선택한다.

### Q6. ClusterIP란?

클러스터 내부에서 Service에 접근하기 위한 IP이다.

### Q7. NodePort란?

Node의 IP와 지정된 포트를 통해 Service에 접근할 수 있도록 하는 Service
방식이다.

### Q8. `port`, `targetPort`, `nodePort`의 차이는?

``` text
Node : nodePort
        ↓
Service : port
        ↓
Pod : targetPort
```

### Q9. Deployment의 장점은?

Pod 복제본 관리뿐 아니라 이미지 변경에 따른 rollout과 rollback 같은 배포
관리 기능을 제공한다.

### Q10. 오늘 HAProxy의 역할은?

`192.168.2.80:80`으로 들어온 요청을 Kubernetes Node들의 NodePort
`31000`으로 전달하는 LoadBalancer 역할을 수행했다.

------------------------------------------------------------------------

# 22. 오늘 실습 최종 그림 ⭐

``` text
                 [Client / Master]
                        │
                        │ curl 192.168.2.80
                        ▼
               ┌─────────────────┐
               │     HAProxy     │
               │ 192.168.2.80:80 │
               └────────┬────────┘
                        │
                    roundrobin
              ┌─────────┼─────────┐
              ▼         ▼         ▼
        Node1 .61   Node2 .62   Node3 .63
          :31000      :31000      :31000
              └─────────┼─────────┘
                        │
                        ▼
               ┌────────────────┐
               │    Service     │
               │ 10.233.10.10   │
               │    port 80     │
               └────────┬───────┘
                        │
                   selector
                  app=apache
                        │
          ┌─────────────┼─────────────┐
          ▼             ▼             ▼
       Apache         Apache        Apache
        Pods           Pods          Pods
         │
         ▼
     httpd:2.2
```

------------------------------------------------------------------------

# 23. 오늘의 결론

오늘 학습량은 많았지만 핵심은 의외로 단순하다.

``` text
[관리]
Deployment
   ↓
ReplicaSet
   ↓
Pod

[접근]
Service
   ↓
Pod

[외부 접근 확장]
ClusterIP
   ↓
NodePort
   ↓
LoadBalancer
```

지금 당장 모든 YAML을 빈 화면에서 외워서 작성하는 것이 목표가 아니다.

먼저 다음을 할 수 있으면 된다.

``` text
1. YAML을 보고 어떤 리소스인지 구분하기
2. replicas가 무엇인지 설명하기
3. label과 selector의 연결을 이해하기
4. Service의 port/targetPort/nodePort를 구분하기
5. Deployment → RS → Pod 관계 설명하기
6. ClusterIP → NodePort → LoadBalancer의 접근 범위를 구분하기
```

이 6개가 잡히면 오늘 실습의 뼈대는 잡힌 것이다. ☸️🔥

------------------------------------------------------------------------

## 📌 복습 우선순위

**1순위**

``` text
Deployment → ReplicaSet → Pod
```

**2순위**

``` text
Service selector ↔ Pod label
```

**3순위**

``` text
ClusterIP → NodePort → LoadBalancer
```

**4순위**

``` text
nodePort → port → targetPort
```

**5순위**

``` text
kubectl get / describe / scale / rollout
```

> 오늘은 이 순서까지만 다시 설명할 수 있으면 충분하다.\
> 세부 YAML 문법은 반복 실습하면서 익힌다.