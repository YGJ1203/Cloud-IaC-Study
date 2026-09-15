# Kubernetes Pod 핵심 실습 총정리

> **학습 주제:** Pod 생성과 YAML, Multi-Container Pod, Pod Lifecycle,
> Liveness Probe, Init Container, Resource Requests/Limits, 환경 변수,
> Static Pod\
> **실습 환경:** Kubernetes v1.27.7 / master + node1\~node3 / Docker +
> cri-dockerd\
> **핵심 흐름:**
> `Pod YAML → kube-apiserver → scheduler → kubelet → Container Runtime`

------------------------------------------------------------------------

## 1. 오늘의 큰 그림

Kubernetes에서 **Pod는 컨테이너를 실행하는 가장 작은 배포 단위**이다.

일반 Pod는 보통 다음 흐름으로 실행된다.

``` text
kubectl
  ↓
kube-apiserver
  ↓
scheduler
  ↓
실행할 Node 결정
  ↓
해당 Node의 kubelet
  ↓
Container Runtime
  ↓
실제 Container 실행
```

반면 **Static Pod**는 API Server를 통해 생성하는 일반 Pod와 달리, 특정
Node의 `kubelet`이 지정된 manifest 디렉토리를 직접 감시하여 실행한다.

``` text
/etc/kubernetes/manifests/*.yml
              ↓
           kubelet
              ↓
       Static Pod 실행
```

------------------------------------------------------------------------

# 2. kubectl로 Pod 생성하기

## 2.1 가장 기본적인 Pod 생성

``` bash
kubectl run webserver1 --image=nginx --port=80
```

확인:

``` bash
kubectl get pod
kubectl get pod -o wide
kubectl describe pod webserver1
```

`-o wide`를 사용하면 Pod IP와 어느 Node에 배치되었는지 확인하기 좋다.

예:

``` text
NAME         READY   STATUS    IP             NODE
webserver1   1/1     Running   10.233.x.x     node3
```

Pod IP로 nginx 동작 확인:

``` bash
curl http://<POD-IP>
```

------------------------------------------------------------------------

## 2.2 YAML 골격을 자동으로 만들어보기

직접 YAML을 처음부터 작성하기 어렵다면 `--dry-run=client -o yaml`이 매우
유용하다.

``` bash
kubectl run webserver2 \
  --image=nginx \
  --port=80 \
  --dry-run=client \
  -o yaml
```

기본적으로 다음과 같은 골격을 얻을 수 있다.

``` yaml
apiVersion: v1
kind: Pod
metadata:
  name: webserver2
spec:
  containers:
  - image: nginx
    name: webserver2
    ports:
    - containerPort: 80
  dnsPolicy: ClusterFirst
  restartPolicy: Always
```

### 실수 포인트

``` bash
-o yaml
```

에서 알파벳 소문자 `o`를 사용한다.

``` bash
-0 yaml
```

처럼 숫자 `0`을 쓰면 오류가 발생한다.

------------------------------------------------------------------------

# 3. Pod YAML 기본 구조

가장 먼저 다음 뼈대를 기억한다.

``` yaml
apiVersion: v1
kind: Pod

metadata:
  name: pod-name
  namespace: default

spec:
  containers:
  - name: container-name
    image: nginx
```

구조를 트리로 보면:

``` text
Pod
├── apiVersion
├── kind
├── metadata
│   ├── name
│   └── namespace
└── spec
    └── containers
        ├── name
        ├── image
        ├── ports
        ├── env
        ├── livenessProbe
        └── resources
```

> **YAML에서 들여쓰기는 단순한 꾸밈이 아니라 부모-자식 관계를
> 결정한다.**

------------------------------------------------------------------------

# 4. Namespace

Namespace는 Kubernetes 리소스를 논리적으로 구분하는 공간이다.

Namespace 생성:

``` bash
kubectl create namespace product
```

확인:

``` bash
kubectl get namespace
```

Pod를 `product` Namespace에 생성하려면:

``` yaml
metadata:
  name: myweb6
  namespace: product
```

### 주의

다음은 잘못된 구조이다.

``` yaml
metadata:
  name: myweb6
namespace: product
```

`namespace`는 반드시 `metadata` 아래에 있어야 한다.

Namespace를 지정하지 않으면 일반적으로 `default` Namespace가 사용된다.

------------------------------------------------------------------------

# 5. Container Port

nginx 컨테이너의 TCP/80 포트를 명시:

``` yaml
ports:
- containerPort: 80
  protocol: TCP
```

`containerPort`는 컨테이너가 사용하는 포트 정보를 Pod spec에 명시하는
것이다.

------------------------------------------------------------------------

# 6. 환경 변수 env

컨테이너에 환경 변수를 전달할 수 있다.

``` yaml
env:
- name: DB
  value: "mydb"

- name: MYWEB
  value: "/usr/share/nginx/html"
```

컨테이너 내부에서 확인:

``` bash
kubectl exec <POD-NAME> -- env
```

특정 값만 확인:

``` bash
kubectl exec <POD-NAME> -- env | grep -E 'DB|MYWEB'
```

개념적으로 Docker의 다음 옵션과 비슷하다.

``` bash
docker run \
  -e DB=mydb \
  -e MYWEB=/usr/share/nginx/html \
  nginx
```

------------------------------------------------------------------------

# 7. Liveness Probe

## 7.1 개념

`livenessProbe`는 컨테이너가 **정상적으로 살아 있는지** kubelet이
검사하는 기능이다.

쉽게 표현하면:

``` text
kubelet
   ↓
"컨테이너 살아 있나?"
   ↓
Liveness Probe
   ↓
성공 → 계속 실행
실패 누적 → 컨테이너 재시작
```

------------------------------------------------------------------------

## 7.2 HTTP GET 방식

nginx의 `/` 경로와 TCP/80을 검사:

``` yaml
livenessProbe:
  httpGet:
    path: /
    port: 80
```

실습에서 `kubectl describe pod`를 확인하면 다음과 같이 Probe 정보가
표시된다.

``` text
Liveness: http-get http://:80/
```

nginx 로그에서는 kubelet이 주기적으로 요청한 흔적도 확인할 수 있다.

``` text
"GET / HTTP/1.1" 200 ... "kube-probe/1.27"
```

즉 kubelet이 실제 HTTP 요청을 보내 컨테이너 상태를 검사한다.

------------------------------------------------------------------------

# 8. Init Container

Init Container는 **메인 컨테이너보다 먼저 실행되는 준비용
컨테이너**이다.

``` text
Pod 생성
  ↓
Init Container A
  ↓ 완료
Init Container B
  ↓ 완료
Main Container
  ↓
Running
```

Init Container가 아직 끝나지 않았다면 Pod 상태에서 다음과 같은 모습을 볼
수 있다.

``` text
READY   STATUS
0/1     Init:0/2
```

Init Container의 용도 예:

-   애플리케이션 실행 전 설정 파일 생성
-   의존 서비스 준비 대기
-   초기 데이터 다운로드
-   권한 및 디렉토리 준비

즉 **본 컨테이너 실행 전에 반드시 끝내야 할 준비 작업**을 분리할 수
있다.

------------------------------------------------------------------------

# 9. Resource Requests / Limits

오늘 실습에서 특히 중요한 부분이다.

``` yaml
resources:
  requests:
    cpu: "200m"
    memory: "500Mi"
  limits:
    cpu: "1"
    memory: "1Gi"
```

## 9.1 Requests

``` yaml
requests:
  cpu: "200m"
  memory: "500Mi"
```

Scheduler가 Pod를 어느 Node에 배치할지 판단할 때 사용하는 **요구
자원량**이다.

``` text
Pod: CPU 200m 필요
        ↓
Scheduler
        ↓
"어느 Node가 이 Pod를 수용할 수 있지?"
```

`requests`를 설정했다고 해서 컨테이너가 실제로 항상 그만큼 CPU/Memory를
소비한다는 뜻은 아니다.

------------------------------------------------------------------------

## 9.2 Limits

``` yaml
limits:
  cpu: "1"
  memory: "1Gi"
```

컨테이너가 사용할 수 있는 자원의 상한을 설정한다.

### CPU 단위

``` text
1000m = 1 CPU
500m  = 0.5 CPU
200m  = 0.2 CPU
```

따라서:

``` yaml
cpu: "200m"
```

은 CPU 0.2개 상당이다.

------------------------------------------------------------------------

## 9.3 Resource YAML 구조 실수

잘못된 예:

``` yaml
resources:
  cpu: "200m"
  memory: "200Mi"
```

이런 구조에서는 Kubernetes가 `resources.cpu`, `resources.memory`를 알 수
없어 `strict decoding error`가 발생할 수 있다.

올바른 예:

``` yaml
resources:
  requests:
    cpu: "200m"
    memory: "200Mi"
```

또는:

``` yaml
resources:
  requests:
    cpu: "200m"
    memory: "200Mi"
  limits:
    cpu: "1"
    memory: "500Mi"
```

------------------------------------------------------------------------

# 10. Resource Limit 실제 검증

실습에서는 컨테이너 내부에 `stress`를 설치하여 메모리 사용을 발생시켰다.

예:

``` bash
kubectl exec -it nginx-resources-pod -- bash
apt update
apt install stress
exit
```

300MB 메모리 부하:

``` bash
time kubectl exec nginx-resources-pod -- \
  stress --vm 1 --vm-bytes 300m -t 5s
```

정상적으로 완료될 수 있다.

더 큰 메모리 부하:

``` bash
time kubectl exec nginx-resources-pod -- \
  stress --vm 1 --vm-bytes 700m -t 5s
```

설정된 메모리 limit을 초과하는 상황에서는 worker가 `signal 9`로 종료되는
현상을 관찰할 수 있었다.

``` text
worker ... got signal 9
failed run
```

즉 **Memory Limit은 실제 컨테이너 실행에 영향을 준다.**

------------------------------------------------------------------------

# 11. Requests가 Node 자원보다 너무 크다면?

예를 들어:

``` yaml
resources:
  requests:
    cpu: "6"
    memory: "200Mi"
```

인데 클러스터 Node들이 해당 CPU request를 만족할 수 없다면:

``` bash
kubectl get pod
```

에서:

``` text
READY   STATUS
0/1     Pending
```

상태가 될 수 있다.

`describe`에서도:

``` text
Node: <none>
```

처럼 아직 배치할 Node를 결정하지 못한 모습을 볼 수 있다.

핵심:

``` text
requests 너무 큼
      ↓
Scheduler가 적합한 Node를 찾지 못함
      ↓
Pod Pending
```

------------------------------------------------------------------------

# 12. Node의 실제 CPU / Memory 확인

Node에서:

``` bash
lscpu | head
```

CPU 확인:

``` text
CPU(s): 4
```

Memory 확인:

``` bash
lsmem
```

예:

``` text
Total online memory: 2G
```

실시간 시스템 자원은 `htop`으로 확인할 수 있다.

``` bash
yum -y install htop
htop
```

### 중요

`htop`에서 보는 값과 Kubernetes `requests`는 같은 값이 아니다.

``` text
requests
→ Scheduler가 배치를 판단하기 위한 요구 자원

htop
→ 현재 프로세스가 실제로 사용하는 CPU / Memory
```

따라서:

``` yaml
requests:
  memory: "500Mi"
```

라고 해도 nginx가 항상 실제 RAM 500Mi를 사용하는 것은 아니다.

------------------------------------------------------------------------

# 13. QoS Class

Pod의 Requests와 Limits 구성에 따라 Kubernetes는 QoS Class를 결정한다.

실습 중 Requests와 Limits가 동일하게 지정된 Pod에서는:

``` text
QoS Class: Guaranteed
```

가 확인되었다.

QoS는 크게 다음 범주로 이해하면 된다.

``` text
Guaranteed
Burstable
BestEffort
```

처음에는 다음 정도로 기억하면 충분하다.

``` text
BestEffort
→ requests/limits가 없는 단순 Pod에서 흔히 확인

Guaranteed
→ 각 컨테이너의 CPU/Memory requests와 limits가 적절히 동일하게 설정된 경우

Burstable
→ 그 중간 형태
```

------------------------------------------------------------------------

# 14. 종합 Pod 예제: myweb6

## 요구사항

``` text
Pod 이름       : myweb6
Namespace      : product
Container 이름 : nginx-container
Image          : nginx
Port           : TCP/80
Health Check   : HTTP GET / :80

Environment
DB             : mydb
MYWEB          : /usr/share/nginx/html

Resources
                Requests     Limits
CPU             200m         1
Memory          500Mi        1Gi
```

## 완성 YAML

``` yaml
apiVersion: v1
kind: Pod

metadata:
  name: myweb6
  namespace: product

spec:
  containers:
  - name: nginx-container
    image: nginx

    ports:
    - containerPort: 80
      protocol: TCP

    livenessProbe:
      httpGet:
        path: /
        port: 80

    env:
    - name: DB
      value: "mydb"
    - name: MYWEB
      value: "/usr/share/nginx/html"

    resources:
      requests:
        cpu: "200m"
        memory: "500Mi"
      limits:
        cpu: "1"
        memory: "1Gi"
```

------------------------------------------------------------------------

# 15. myweb6 생성 및 검증

실습 디렉토리:

``` bash
mkdir -p ~/kube/example
cd ~/kube/example
```

Namespace 생성:

``` bash
kubectl create namespace product
```

Pod 생성:

``` bash
kubectl create -f myweb6.yml
```

또는:

``` bash
kubectl apply -f myweb6.yml
```

확인:

``` bash
kubectl get pod -n product
kubectl get pod -n product -o wide
kubectl describe pod myweb6 -n product
```

환경 변수 확인:

``` bash
kubectl exec -n product myweb6 -- env
```

삭제:

``` bash
kubectl delete -f myweb6.yml
```

------------------------------------------------------------------------

# 16. Static Pod

## 16.1 일반 Pod와 차이

일반 Pod:

``` text
YAML
 ↓
kubectl create/apply
 ↓
API Server
 ↓
Scheduler
 ↓
Node
 ↓
kubelet
```

Static Pod:

``` text
Node의 manifest 파일
 ↓
kubelet
 ↓
Pod 직접 관리
```

즉 Static Pod는 **특정 Node의 kubelet이 직접 관리하는 Pod**이다.

------------------------------------------------------------------------

# 17. Static Pod 경로 확인

node1에서 kubelet 프로세스 확인:

``` bash
ps -ef | grep kubelet
```

kubelet 설정 확인:

``` bash
cat /var/lib/kubelet/config.yaml
```

핵심 설정:

``` yaml
staticPodPath: /etc/kubernetes/manifests
```

따라서 이 실습 환경에서는:

``` text
/etc/kubernetes/manifests
```

가 Static Pod manifest 감시 디렉토리이다.

확인:

``` bash
ls -l /etc/kubernetes/manifests/
```

기존 `nginx-proxy.yml`도 이 디렉토리에서 확인할 수 있었다.

------------------------------------------------------------------------

# 18. Static Pod 생성

node1:

``` bash
cd /etc/kubernetes/manifests
vi staticpod.yml
```

예:

``` yaml
apiVersion: v1
kind: Pod

metadata:
  name: nginx-static-pod
  namespace: default

spec:
  containers:
  - name: nginx-container
    image: nginx
    ports:
    - containerPort: 80
      protocol: TCP
```

여기서는 중요한 차이가 있다.

``` bash
kubectl create -f staticpod.yml
```

을 실행할 필요가 없다.

**파일을 `/etc/kubernetes/manifests`에 저장하는 것 자체가 생성
작업이다.**

``` text
staticpod.yml 저장
      ↓
kubelet이 파일 발견
      ↓
Static Pod 생성
      ↓
nginx Container 생성
```

------------------------------------------------------------------------

# 19. Node에서 실제 Container 확인

node1에서:

``` bash
docker container ls | grep static
```

실제 실습에서는 다음 형태의 컨테이너 이름을 확인했다.

``` text
k8s_nginx-container_nginx-static-pod-node1_default_...
k8s_POD_nginx-static-pod-node1_default_...
```

여기서 `k8s_POD_...`는 Pod의 sandbox 역할을 하는 pause 컨테이너이다.

즉:

``` text
Pod
├── pause container
└── nginx-container
```

형태로 이해할 수 있다.

------------------------------------------------------------------------

# 20. Worker Node에서 kubectl이 없었던 이유

node1에서:

``` bash
kubectl get pod -o wide
```

를 실행했을 때:

``` text
bash: kubectl: 명령을 찾을 수 없습니다...
```

가 나타났다.

이것은 **Static Pod 생성 실패가 아니다.**

실습 환경에서는 `kubectl`을 주로 master에서 사용하고 있고, worker node에
kubectl 명령이 준비되어 있지 않았기 때문이다.

Static Pod 자체는 이미 다음 명령으로 확인 가능했다.

``` bash
docker container ls | grep static
```

클러스터 관점의 Pod 정보는 master에서 확인한다.

``` bash
kubectl get pod -o wide
```

------------------------------------------------------------------------

# 21. Static Pod 삭제

Static Pod의 핵심 시험 포인트.

일반 Pod:

``` bash
kubectl delete -f pod.yml
```

Static Pod:

``` bash
rm /etc/kubernetes/manifests/staticpod.yml
```

왜냐하면 kubelet이 manifest 파일을 계속 감시하기 때문이다.

``` text
staticpod.yml 존재
       ↓
kubelet: "이 Pod가 있어야 한다."
       ↓
Static Pod 유지

staticpod.yml 삭제
       ↓
kubelet: "더 이상 필요 없다."
       ↓
Static Pod 제거
```

실습에서도:

``` bash
rm -rf staticpod.yml
```

후:

``` bash
ls -l /etc/kubernetes/manifests/
```

에서 파일이 사라진 것을 확인했다.

------------------------------------------------------------------------

# 22. 일반 Pod 삭제와 실제 Container 변화 관찰

node3에서 일반 nginx Pod가 존재할 때:

``` bash
docker container ls | grep nginx
```

에서 `testpod` 관련 컨테이너가 확인되었다.

Pod가 삭제된 후:

``` bash
docker container ls | grep testpod
```

결과가 사라졌다.

즉:

``` text
Kubernetes Pod 삭제
      ↓
해당 Node의 kubelet
      ↓
Container Runtime
      ↓
실제 Container 제거
```

까지 연결해서 확인한 것이다.

반면 node3의:

``` text
/etc/kubernetes/manifests/nginx-proxy.yml
```

은 계속 존재하므로 `nginx-proxy` Static Pod 관련 컨테이너도 계속
실행되고 있었다.

------------------------------------------------------------------------

# 23. 오늘 나온 주요 트러블슈팅

## 23.1 이미 존재하는 Pod를 create

``` bash
kubectl create -f webserver2.yml
```

결과:

``` text
Error from server (AlreadyExists)
```

원인:

``` text
같은 이름의 Pod가 이미 존재
```

해결 예:

``` bash
kubectl delete pod webserver2
kubectl create -f webserver2.yml
```

------------------------------------------------------------------------

## 23.2 describe에 `-o json` 사용

``` bash
kubectl describe pod myweb1 -o json
```

은 사용할 수 없다.

JSON/YAML 출력이 필요하면:

``` bash
kubectl get pod myweb1 -o json
kubectl get pod myweb1 -o yaml
```

상세 설명이 필요하면:

``` bash
kubectl describe pod myweb1
```

구분:

``` text
kubectl get ... -o yaml/json
→ 리소스 객체를 YAML/JSON 형태로 출력

kubectl describe ...
→ 사람이 읽기 좋은 상세 상태 + Events 출력
```

------------------------------------------------------------------------

## 23.3 Resource YAML 계층 오류

오류 예:

``` text
strict decoding error:
unknown field "spec.containers[0].resources.cpu"
unknown field "spec.containers[0].resources.memory"
```

잘못된 구조:

``` yaml
resources:
  cpu: "200m"
  memory: "200Mi"
```

수정:

``` yaml
resources:
  requests:
    cpu: "200m"
    memory: "200Mi"
```

------------------------------------------------------------------------

## 23.4 Requests 과다 → Pending

``` yaml
requests:
  cpu: "6"
```

처럼 Node가 감당할 수 없는 자원을 요구하면 Scheduler가 배치하지 못해:

``` text
STATUS: Pending
Node: <none>
```

상태가 될 수 있다.

이 경우 가장 먼저:

``` bash
kubectl describe pod <POD-NAME>
```

의 Events를 확인한다.

------------------------------------------------------------------------

## 23.5 MobaXterm SSH Timeout

``` text
Network error: Connection timed out
Session stopped
```

이 메시지는 Pod 자체의 Kubernetes 오류가 아니라 **MobaXterm과 해당 Node
사이의 SSH 연결이 timeout된 것**이다.

재접속 후 Node에서 정상적으로 명령 실행 및 패키지 설치가 가능했다면 Pod
장애와 SSH 세션 장애를 구분해야 한다.

------------------------------------------------------------------------

# 24. Pod 문제 발생 시 점검 루틴

오늘 실습을 기준으로 다음 순서가 유용하다.

``` bash
# 1. Pod 전체 상태
kubectl get pod -A -o wide

# 2. 특정 Pod 상세 정보
kubectl describe pod <POD-NAME> -n <NAMESPACE>

# 3. Pod 로그
kubectl logs <POD-NAME> -n <NAMESPACE>

# 4. 컨테이너 내부 확인
kubectl exec -it <POD-NAME> -n <NAMESPACE> -- bash

# 5. Node 확인
kubectl get nodes -o wide

# 6. 실제 배치 Node에서 컨테이너 확인
docker container ls

# 7. Static Pod라면 manifest 확인
ls -l /etc/kubernetes/manifests/

# 8. kubelet 확인
ps -ef | grep kubelet
```

핵심은 무작정 YAML부터 수정하는 것이 아니라:

``` text
Pod 상태
 → describe
 → Events
 → logs
 → Node
 → kubelet / container
```

순서로 내려가는 것이다.

------------------------------------------------------------------------

# 25. 일반 Pod vs Static Pod

  구분        일반 Pod                     Static Pod
  ----------- ---------------------------- -------------------------------
  생성 주체   Kubernetes API를 통한 생성   해당 Node의 kubelet
  대표 생성   `kubectl create/apply`       manifest 디렉토리에 YAML 저장
  Scheduler   일반적으로 사용              특정 Node에 직접 존재
  관리 핵심   API Server                   kubelet
  실습 경로   사용자 YAML 파일             `/etc/kubernetes/manifests`
  삭제        `kubectl delete`             manifest 파일 제거
  Node 고정   Scheduler가 선택 가능        manifest가 있는 Node에서 실행

------------------------------------------------------------------------

# 26. Requests vs Limits

  -----------------------------------------------------------------------
  구분                    Requests                Limits
  ----------------------- ----------------------- -----------------------
  의미                    Pod가 요구하는 자원량   컨테이너 자원 사용 상한

  주요 관계               Scheduler의 Node 배치   실제 자원 사용 제한
                          판단                    

  CPU 예                  `200m`                  `1`

  Memory 예               `500Mi`                 `1Gi`

  너무 크게 설정          Pod가 Pending 될 수     과도한 메모리 사용 시
                          있음                    종료 가능
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# 27. YAML 문제 풀이 공식

Pod 문제가 나오면 문장을 바로 YAML로 쓰려고 하지 말고 먼저 분류한다.

예:

``` text
Pod 이름
Namespace
→ metadata

Container 이름
Image
Port
→ spec.containers

Health Check
→ livenessProbe

환경 변수
→ env

CPU / Memory
→ resources
```

그 다음 다음 뼈대에 끼워 넣는다.

``` yaml
apiVersion: v1
kind: Pod

metadata:
  name:
  namespace:

spec:
  containers:
  - name:
    image:

    ports:

    livenessProbe:

    env:

    resources:
      requests:
      limits:
```

이 방식으로 접근하면 복잡해 보이는 문제도 결국 **블록 조립 문제**가
된다.

------------------------------------------------------------------------

# 28. 오늘의 핵심 암기 10문장

1.  **Pod는 Kubernetes에서 컨테이너를 실행하는 최소 배포 단위이다.**
2.  **`metadata`에는 Pod의 name, namespace 같은 식별 정보가 들어간다.**
3.  **컨테이너 설정은 `spec.containers` 아래에 작성한다.**
4.  **`livenessProbe`는 컨테이너가 살아 있는지 검사한다.**
5.  **`env`로 컨테이너 환경 변수를 전달할 수 있다.**
6.  **Requests는 Scheduler의 Node 배치 판단에 중요한 요구 자원량이다.**
7.  **Limits는 컨테이너가 사용할 수 있는 자원의 상한이다.**
8.  **Requests가 너무 크면 Pod가 Pending 상태가 될 수 있다.**
9.  **Static Pod는 kubelet이 manifest 파일을 직접 감시하고 관리한다.**
10. **Static Pod를 없애려면 감시 디렉토리의 manifest 파일을 제거한다.**

------------------------------------------------------------------------

# 29. 면접 / 복습용 미니 Q&A

### Q1. Pod란?

Kubernetes에서 하나 이상의 컨테이너를 실행하는 최소 배포 단위이다.

### Q2. `kubectl get pod -o wide`의 장점은?

기본 상태뿐 아니라 Pod IP와 배치 Node 등의 추가 정보를 확인할 수 있다.

### Q3. Liveness Probe의 역할은?

컨테이너가 정상적으로 살아 있는지 검사하고, 실패가 누적되면 kubelet이
컨테이너를 재시작할 수 있게 한다.

### Q4. Requests와 Limits의 차이는?

Requests는 주로 Scheduler가 Pod 배치를 판단하는 기준이 되는 요구
자원량이고, Limits는 컨테이너가 사용할 수 있는 자원의 상한이다.

### Q5. CPU `200m`은?

CPU 0.2개 상당이다. `1000m = 1 CPU`.

### Q6. CPU Request를 Node가 제공할 수 없으면?

Scheduler가 적절한 Node를 찾지 못해 Pod가 Pending 상태에 머물 수 있다.

### Q7. Static Pod란?

API를 통한 일반적인 Pod 생성과 달리 특정 Node의 kubelet이 로컬
manifest를 보고 직접 관리하는 Pod이다.

### Q8. 이 실습 환경의 Static Pod 경로는?

`/etc/kubernetes/manifests`

### Q9. Static Pod는 어떻게 삭제하는가?

해당 Node의 Static Pod manifest 파일을 감시 디렉토리에서 제거한다.

### Q10. `kubectl describe`와 `kubectl get -o yaml`의 차이는?

`describe`는 상태와 Events를 사람이 읽기 쉽게 보여주고, `get -o yaml`은
Kubernetes 리소스 객체를 YAML 구조로 출력한다.

------------------------------------------------------------------------

# 30. 최종 흐름도

``` text
                  Kubernetes Pod 학습
                         │
        ┌────────────────┼────────────────┐
        │                │                │
      YAML             운영             자원
        │                │                │
 metadata/spec      get/describe      requests
 containers         logs/exec          limits
 ports/probe            │                │
 env/resources          │           CPU / Memory
        │                │                │
        └──────────────┬─┴────────────────┘
                       │
                    kubelet
                       │
               Container Runtime
                       │
                 실제 Container
                       │
              docker container ls
                       │
             ┌─────────┴─────────┐
             │                   │
         일반 Pod            Static Pod
             │                   │
      API/Scheduler       manifest 파일
                                 │
                       /etc/kubernetes/manifests
                                 │
                              kubelet
```

------------------------------------------------------------------------

# 31. 한 줄 정리

> **오늘의 핵심은 YAML 문법 자체를 외우는 것이 아니라,
> `Pod 요구사항 → YAML 블록 → Scheduler/kubelet → 실제 Node의 Container`까지
> 하나의 흐름으로 연결해서 이해하는 것이다.**

🔥 특히 Static Pod까지 직접 생성하고 `docker container ls`로 실제
컨테이너를 확인한 것은, Kubernetes의 추상적인 Pod 개념을 Linux/Container
레벨까지 연결해서 본 중요한 실습이다.
