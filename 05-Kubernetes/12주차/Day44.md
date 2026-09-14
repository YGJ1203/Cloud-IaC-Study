# 2026-09-14 Docker Swarm & Kubernetes(Kubespray) 핵심 정리

> **학습 키워드:** Docker Swarm / Manager & Worker / Service / Task /
> Replica / Scale / Rolling Update / Rollback / SSH Key / Ansible /
> Kubespray / Kubernetes / Calico / CoreDNS / Deployment\
> **실습 환경:** CentOS Stream 9, Docker, master + node1\~3

------------------------------------------------------------------------

## 0. 오늘의 흐름 한눈에 보기

오늘 실습은 크게 두 덩어리로 볼 수 있다.

### Part A. Docker Swarm

``` text
Docker 단일 호스트
        ↓
Swarm 초기화
        ↓
Manager + Worker 구성
        ↓
Service 생성
        ↓
Replica 배치
        ↓
Scale Out / Scale In
        ↓
Rolling Update
        ↓
Rollback
        ↓
Service 제거 / Swarm 탈퇴
```

### Part B. Kubernetes + Kubespray

``` text
master / node1 / node2 / node3 준비
        ↓
SSH Key 기반 접속 구성
        ↓
Ansible + Kubespray
        ↓
cluster.yml 실행
        ↓
Kubernetes Control Plane 구성
        ↓
Worker Node Join
        ↓
Calico / CoreDNS 등 구성
        ↓
kubectl로 클러스터 확인
        ↓
httpd Deployment 3 replicas 생성
```

오늘의 핵심은 단순히 **컨테이너 하나를 실행하는 단계**에서 벗어나,

> **여러 서버에 컨테이너 워크로드를 배치하고 관리하는 오케스트레이션의
> 시작**

이라고 볼 수 있다. 😏

------------------------------------------------------------------------

# 1. Docker Swarm이란?

Docker Swarm은 여러 Docker 호스트를 하나의 클러스터처럼 묶어 컨테이너
서비스를 배포하고 관리하는 Docker의 오케스트레이션 기능이다.

단일 Docker에서는 보통 다음처럼 직접 컨테이너를 실행했다.

``` bash
docker run -d --name web nginx
```

Swarm에서는 개별 컨테이너보다 **Service**라는 단위로 원하는 상태를
선언한다.

``` bash
docker service create --name myweb --replicas 2 nginx
```

그러면 Swarm이 적절한 노드를 골라 필요한 수의 **Task**를 배치한다.

------------------------------------------------------------------------

# 2. Docker Swarm 핵심 구성요소

## 2.1 Manager Node

Manager는 Swarm 클러스터를 관리한다.

주요 역할:

-   클러스터 상태 관리
-   Service 생성/수정/삭제
-   Task 스케줄링
-   Worker 관리
-   원하는 Replica 수 유지
-   Rolling Update / Rollback 관리

실습에서는 `docker1.example.com`이 Manager이자 Leader였다.

------------------------------------------------------------------------

## 2.2 Worker Node

Worker는 Manager가 할당한 Task를 실제로 실행하는 노드다.

실습 구성:

``` text
docker1.example.com  → Manager / Leader
docker2.example.com  → Worker
docker3.example.com  → Worker
```

------------------------------------------------------------------------

## 2.3 Service

Swarm에서 실행하고 싶은 애플리케이션의 **목표 상태(Desired State)** 를
정의한다.

예:

``` bash
docker service create \
  --name myweb \
  -p 80:80 \
  --replicas 2 \
  --update-delay 30s \
  --constraint=node.role!=manager \
  nginx:1.14
```

이 명령은 다음과 같은 의미다.

  옵션                                의미
  ----------------------------------- ------------------------------------
  `--name myweb`                      서비스 이름
  `-p 80:80`                          Published Port 80 → Target Port 80
  `--replicas 2`                      Task 2개 유지
  `--update-delay 30s`                업데이트 Task 사이에 30초 간격
  `--constraint=node.role!=manager`   Manager가 아닌 노드에 배치
  `nginx:1.14`                        사용할 이미지

------------------------------------------------------------------------

## 2.4 Task

Task는 Service를 실제로 수행하는 실행 단위다.

``` text
Service: myweb
 ├─ Task: myweb.1 → docker3
 └─ Task: myweb.2 → docker2
```

실습에서 `myweb`의 두 Task가 docker2와 docker3에 각각 배치되었다.

확인:

``` bash
docker service ps myweb
```

------------------------------------------------------------------------

## 2.5 Replica

Replica는 동일 Service에서 유지할 Task 개수다.

``` bash
--replicas 2
```

라면 Swarm은 `myweb` Task를 2개 유지하려고 한다.

즉,

``` text
Replica = "몇 개를 계속 살아 있게 유지할 것인가?"
```

------------------------------------------------------------------------

# 3. Swarm 초기화

초기 상태에서는 Swarm이 비활성 상태였다.

Manager가 될 Docker1에서:

``` bash
docker swarm init --advertise-addr 192.168.2.10
```

결과:

``` text
Swarm initialized
current node is now a manager
```

`--advertise-addr`는 다른 노드가 Manager에 접근할 때 사용할 주소를
지정한다.

------------------------------------------------------------------------

# 4. Worker Node Join

`docker swarm init` 후 Worker가 사용할 Join 명령이 출력된다.

형태:

``` bash
docker swarm join --token <WORKER_TOKEN> 192.168.2.10:2377
```

> ⚠️ Join Token은 클러스터 가입에 사용되는 인증 정보이므로 GitHub
> 문서에는 실제 토큰을 그대로 기록하지 않는 편이 좋다.

Manager에서 노드 확인:

``` bash
docker node ls
```

실습 결과:

``` text
docker1.example.com  Ready  Active  Leader
docker2.example.com  Ready  Active
docker3.example.com  Ready  Active
```

### 상태 필드

-   `Ready` : 정상적으로 Swarm에 참여 중
-   `Active` : Task를 배치받을 수 있음
-   `Leader` : Manager 중 현재 리더

------------------------------------------------------------------------

# 5. Swarm Visualizer

클러스터의 Task 배치 상태를 시각적으로 보기 위해 Visualizer Service를
실행했다.

``` bash
docker service create --name swarm_tools \
  --publish=8888:8080 \
  --constraint=node.role==manager \
  --mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  dockersamples/visualizer
```

핵심:

``` text
--constraint=node.role==manager
```

→ Visualizer Task는 Manager에 배치.

``` text
/var/run/docker.sock
```

→ Docker Engine과 통신하기 위한 Unix Socket을 컨테이너에 bind mount.

서비스 확인:

``` bash
docker service ls
```

------------------------------------------------------------------------

# 6. myweb Service 생성

``` bash
docker service create \
  --name myweb \
  -d \
  -p 80:80 \
  --replicas 2 \
  --update-delay 30s \
  --constraint=node.role!=manager \
  nginx:1.14
```

처음에는:

``` text
REPLICAS
0/2
```

처럼 보일 수 있다.

이는 Service 생성 직후 Task가 아직 준비 중이기 때문이다.

잠시 후:

``` bash
docker service ps myweb
```

에서 docker2 / docker3에 각각 Running 상태의 Task가 확인되었다.

------------------------------------------------------------------------

# 7. Service 상세 정보 확인

간단히 보기:

``` bash
docker service inspect --pretty myweb
```

JSON 전체 보기:

``` bash
docker service inspect myweb
```

실습에서 확인한 핵심 설정:

``` text
Service Mode : Replicated
Replicas     : 2

Placement:
  node.role != manager

Update:
  Parallelism : 1
  Delay       : 30s
  Order       : stop-first

Endpoint Mode : vip
PublishedPort : 80
TargetPort    : 80
PublishMode   : ingress
```

## VIP

`Endpoint Mode: vip`는 Service에 가상 IP를 제공하는 방식이다.

클라이언트는 개별 Task의 위치를 직접 알 필요 없이 Service를 대상으로
접근할 수 있다.

------------------------------------------------------------------------

# 8. 서비스 접속 확인

``` bash
curl http://192.168.2.10
```

결과:

``` html
<h1>Welcome to nginx!</h1>
```

즉, Swarm으로 배포한 nginx 서비스가 정상적으로 응답했다.

------------------------------------------------------------------------

# 9. Scale Out / Scale In

## 9.1 2 → 4

``` bash
docker service scale myweb=4
```

확인:

``` bash
docker service ls
docker service ps myweb
```

결과:

``` text
myweb  4/4
```

Task가 docker2와 docker3에 추가 배치되었다.

------------------------------------------------------------------------

## 9.2 4 → 6

``` bash
docker service scale myweb=6
```

결과:

``` text
6/6
```

Swarm이 원하는 Replica 수를 맞추기 위해 추가 Task를 자동 생성했다.

------------------------------------------------------------------------

## 9.3 다시 축소

``` bash
docker service scale myweb=4
docker service scale myweb=2
```

### 핵심

``` text
Scale Out = Replica 증가
Scale In  = Replica 감소
```

관리자는 **원하는 개수**만 지정하고 실제 Task 생성/종료와 배치는 Swarm이
처리한다.

------------------------------------------------------------------------

# 10. Rolling Update

기존:

``` text
nginx:1.14
```

업데이트:

``` bash
docker service update --image nginx:1.15 myweb
```

`myweb`은 생성 당시:

``` text
Parallelism: 1
Delay: 30s
```

설정을 가지고 있었다.

따라서 모든 Task를 한꺼번에 바꾸기보다 Task를 순차적으로 교체하는
Rolling Update 흐름을 확인할 수 있었다.

확인:

``` bash
docker service ps myweb
```

Task history에서 기존 `nginx:1.14` Task가 Shutdown되고 새로운
`nginx:1.15` Task가 Running 상태가 된 것을 확인했다.

### Rolling Update 목적

서비스 전체를 한 번에 중지하고 교체하는 방식보다 점진적으로 새 버전으로
변경하여 서비스 중단 위험을 줄이는 데 목적이 있다.

------------------------------------------------------------------------

# 11. Rollback

업데이트 이전 버전으로 복귀:

``` bash
docker service rollback myweb
```

실습 결과:

``` text
nginx:1.15
   ↓ rollback
nginx:1.14
```

확인:

``` bash
docker service ps myweb
```

기존 1.15 Task가 Shutdown되고 1.14 Task가 다시 Running 상태가 되었다.

### 기억하기

``` text
update   = 새 버전으로 이동
rollback = 이전 Service 설정으로 복귀
```

------------------------------------------------------------------------

# 12. Swarm 실습 종료

Service 삭제:

``` bash
docker service rm myweb swarm_tools
```

삭제 후:

``` bash
docker service ps myweb
```

결과:

``` text
no such service: myweb
```

Swarm 탈퇴:

``` bash
docker swarm leave -f
```

이후 Manager 전용 명령:

``` bash
docker node ls
```

을 실행하면 더 이상 Swarm Manager가 아니라는 오류가 발생했다.

즉,

``` text
Swarm 구성 → 실습 → Service 삭제 → Swarm 탈퇴
```

까지 전체 라이프사이클을 실습했다.

------------------------------------------------------------------------

# 13. Docker Swarm 트러블슈팅

## Case 1. `dokcer`

실습 기록:

``` bash
dokcer service ls
```

결과:

``` text
bash: dokcer: 명령을 찾을 수 없습니다
```

교정:

``` bash
docker service ls
```

원인: 단순 오타. 💀

------------------------------------------------------------------------

## Case 2. 존재하지 않는 하위 명령 조합

실습:

``` bash
docker service container ls -a
```

오류가 발생했다.

Service의 Task를 보고 싶다면:

``` bash
docker service ps myweb
```

일반 컨테이너를 보고 싶다면:

``` bash
docker container ls -a
```

즉,

``` text
docker service ps <SERVICE>
docker container ls -a
```

를 구분한다.

------------------------------------------------------------------------

## Case 3. Task `exit (137)`

Scale 변경 과정에서 일부 과거 Task에:

``` text
task: non-zero exit (137)
```

기록이 나타났다.

오늘 기록만으로 해당 Task가 왜 137로 종료되었는지는 확정할 수 없다.

중요한 것은 `docker service ps myweb`이 **현재 Task뿐 아니라 이전 Task
history도 보여줄 수 있다**는 점이다.

따라서 장애 분석 시:

``` bash
docker service ps myweb
docker service inspect myweb
docker ps -a
```

등을 함께 확인하는 습관이 좋다.

------------------------------------------------------------------------

# 14. Docker Swarm 핵심 명령어 Cheat Sheet

``` bash
# Swarm 시작
docker swarm init --advertise-addr <MANAGER_IP>

# 노드 확인
docker node ls

# 서비스 생성
docker service create \
  --name myweb \
  -p 80:80 \
  --replicas 2 \
  --constraint=node.role!=manager \
  nginx:1.14

# 서비스 목록
docker service ls

# Task 확인
docker service ps myweb

# 서비스 상세 확인
docker service inspect --pretty myweb

# Scale
docker service scale myweb=4
docker service scale myweb=2

# Image Update
docker service update --image nginx:1.15 myweb

# Rollback
docker service rollback myweb

# 서비스 제거
docker service rm myweb

# Swarm 탈퇴
docker swarm leave -f
```

------------------------------------------------------------------------

# 15. Kubernetes 실습 환경

오늘 후반부에는 Kubernetes 클러스터 구성까지 진행했다.

``` text
master  192.168.2.60  → Control Plane
node1   192.168.2.61  → Worker
node2   192.168.2.62  → Worker
node3   192.168.2.63  → Worker
```

`/etc/hosts`에도 각 호스트의 이름과 IP를 등록했다.

------------------------------------------------------------------------

# 16. SSH Key 기반 접속 구성

master에서:

``` bash
ssh-keygen
```

키 쌍 생성:

``` text
~/.ssh/id_rsa
~/.ssh/id_rsa.pub
```

각 서버에 공개키 배포:

``` bash
ssh-copy-id master
ssh-copy-id node1
ssh-copy-id node2
ssh-copy-id node3
```

### 목적

Ansible은 master에서 여러 노드에 SSH로 접속해 자동화 작업을 수행한다.

따라서 반복적으로 비밀번호를 입력하지 않고 원격 노드를 관리하기 위해 SSH
Key 기반 인증을 준비한 것이다.

> 🔐 **중요:** 실습 로그에는 개인키 내용까지 출력한 흔적이 있다. 실제
> GitHub 문서에는 `id_rsa`의 내용, 비밀번호, Token 등 비밀정보를 절대
> 올리지 않는다.

------------------------------------------------------------------------

# 17. Node 사전 준비

node1 기록에서는 다음 작업을 확인할 수 있다.

Swap 비활성화:

``` bash
swapoff -a
```

확인:

``` bash
free
```

결과:

``` text
Swap: 0
```

기본 Target 변경:

``` bash
systemctl set-default multi-user.target
systemctl isolate multi-user.target
```

패키지 준비:

``` bash
yum -y install epel-release
yum -y install yum-utils
```

Docker Repository 추가:

``` bash
yum config-manager --add-repo \
https://download.docker.com/linux/centos/docker-ce.repo
```

Docker 설치:

``` bash
yum install -y \
docker-ce-28.3.0 \
docker-ce-cli-28.3.0 \
containerd.io
```

Docker 활성화:

``` bash
systemctl enable --now docker
systemctl status docker --no-pager
```

실습 기록에서 Docker는 `active (running)` 상태가 되었다.

------------------------------------------------------------------------

# 18. Ansible + Kubespray

## Ansible

여러 서버에 동일한 설정을 자동으로 적용하는 구성 관리/자동화 도구다.

오늘 구조에서는:

``` text
master
  │
  ├── SSH → node1
  ├── SSH → node2
  └── SSH → node3
```

형태로 여러 노드를 자동 구성했다.

------------------------------------------------------------------------

## Kubespray

Kubespray는 Ansible Playbook을 이용해 Kubernetes 클러스터 설치 및 구성을
자동화하는 프로젝트다.

실습에서 확인한 `cluster.yml`:

``` yaml
---
- name: Install Kubernetes
  ansible.builtin.import_playbook: playbooks/cluster.yml
```

실제 playbook 내부에서는 대략 다음 단계들이 이어졌다.

``` text
Ansible Version 확인
        ↓
Facts 수집
        ↓
Kubernetes 사전 구성
        ↓
Container Engine 구성
        ↓
etcd 구성
        ↓
Control Plane 구성
        ↓
Worker Node 구성
        ↓
Network Plugin 구성
        ↓
Kubernetes Apps 구성
```

------------------------------------------------------------------------

# 19. Kubespray 실행

실습 명령:

``` bash
ansible-playbook \
  -i inventory/mycluster/hosts.yaml \
  --become \
  --become-user=root \
  cluster.yml
```

의미:

  옵션                               의미
  ---------------------------------- --------------------------
  `-i`                               사용할 Inventory 지정
  `inventory/mycluster/hosts.yaml`   master/node 정보
  `--become`                         권한 상승 사용
  `--become-user=root`               root 권한으로 작업
  `cluster.yml`                      Kubernetes 설치 Playbook

------------------------------------------------------------------------

# 20. Kubernetes Node Join

Kubespray 수행 과정에서 kubeadm이 Join Token을 만들고 node1\~3가
클러스터에 참여했다.

흐름:

``` text
Master Control Plane 준비
        ↓
CA 정보 확인
        ↓
Join Token 생성
        ↓
node1 Join
node2 Join
node3 Join
        ↓
kubelet 설정
```

실제 결과에서 node1, node2, node3의 `Join to cluster` 작업이 모두
`changed` 상태로 수행되었다.

------------------------------------------------------------------------

# 21. Kubespray 결과

PLAY RECAP에서:

``` text
master  failed=0
node1   failed=0
node2   failed=0
node3   failed=0
```

즉, 최종적으로 클러스터 구축 Playbook은 실패 없이 완료되었다.

전체 실행 시간은 약 14분 43초로 기록되었다.

------------------------------------------------------------------------

# 22. Kubernetes 클러스터 확인

``` bash
kubectl get nodes
```

결과:

``` text
NAME     STATUS   ROLES           VERSION
master   Ready    control-plane   v1.27.7
node1    Ready    <none>          v1.27.7
node2    Ready    <none>          v1.27.7
node3    Ready    <none>          v1.27.7
```

🔥 이 결과가 오늘 Kubernetes 구축의 가장 중요한 성공 확인 포인트다.

``` text
master = Control Plane
node1~3 = Worker
모든 Node = Ready
```

------------------------------------------------------------------------

# 23. Kubernetes 시스템 Pod 확인

``` bash
kubectl get pod -A
```

실습 결과에서 다음 구성요소가 Running 상태로 확인되었다.

-   Calico
-   CoreDNS
-   기타 kube-system 구성요소

## Calico

Kubernetes에서 Pod 간 네트워크 통신을 제공하는 네트워크 플러그인(CNI)
역할을 한다.

## CoreDNS

Kubernetes 클러스터 내부에서 Service/Pod 관련 이름 해석에 사용되는 DNS
구성요소다.

오늘 Kubespray 실행 과정에서도 `network_plugin/calico` 관련 작업이
수행되었다.

------------------------------------------------------------------------

# 24. Kubernetes Node 상세 확인

``` bash
kubectl get nodes -o wide
```

기록상:

``` text
master → 192.168.2.60
node1  → 192.168.2.61
node2  → 192.168.2.62
node3  → 192.168.2.63
```

OS:

``` text
CentOS Stream 9
```

Kernel:

``` text
5.14.0-452.el9.x86_64
```

Container Runtime 표시:

``` text
docker://28.3.0
```

Node 상세:

``` bash
kubectl describe node master
```

------------------------------------------------------------------------

# 25. 첫 Deployment 생성

``` bash
kubectl create deployment webserver \
  --image=httpd \
  --replicas 3
```

결과:

``` text
deployment.apps/webserver created
```

확인:

``` bash
kubectl get pod -o wide
```

초기에는:

``` text
ContainerCreating
```

상태였으며 3개의 Pod가 각각 다음 노드에 배치되는 모습이 확인되었다.

``` text
webserver Pod #1 → node1
webserver Pod #2 → node2
webserver Pod #3 → node3
```

### 여기서 중요한 점

Docker Swarm에서:

``` text
Service → Replica → Task
```

였다면 Kubernetes에서는 오늘 실습 기준으로:

``` text
Deployment → Replica → Pod
```

라는 구조를 처음 접한 셈이다.

------------------------------------------------------------------------

# 26. Docker Swarm vs Kubernetes 연결해서 이해하기

  Docker Swarm             Kubernetes                    개념
  ------------------------ ----------------------------- ----------------------
  Manager                  Control Plane                 클러스터 관리
  Worker                   Worker Node                   워크로드 실행
  Service                  Deployment/Service 등         워크로드/서비스 관리
  Task                     Pod와 유사한 실행 단위 관점   실제 워크로드
  Replica                  Replica                       원하는 실행 개수
  `docker service scale`   Deployment replica 조정       Scale
  Rolling Update           Rolling Update                점진적 업데이트
  Rollback                 Rollout undo 계열 개념        이전 상태 복귀

> 완전히 1:1 대응하는 개념은 아니지만, **Swarm에서 익힌 "원하는 상태를
> 선언하고 오케스트레이터가 유지한다"는 사고방식**은 Kubernetes를
> 이해하는 데 매우 중요하다.

------------------------------------------------------------------------

# 27. Kubernetes 트러블슈팅 메모

## `nf_conntrack_ipv4` Module 메시지

Kubespray 수행 중:

``` text
modprobe: FATAL:
Module nf_conntrack_ipv4 not found
```

메시지가 기록되었다.

하지만 해당 Task는 `...ignoring` 처리되었고, 최종 PLAY RECAP에서는
master/node1/node2/node3 모두 `failed=0`으로 끝났다.

따라서 **오늘 실습 기록 기준으로는 이 메시지가 최종 클러스터 구축 실패로
이어지지 않았다.**

이런 경우에는 한 줄의 `FAILED!`만 보고 전체 작업이 실패했다고 단정하지
말고 최종:

``` text
PLAY RECAP
kubectl get nodes
kubectl get pod -A
```

까지 확인해야 한다.

------------------------------------------------------------------------

# 28. 오늘의 가장 중요한 개념: Desired State

오늘 Docker Swarm과 Kubernetes를 하나로 묶어주는 핵심은 **Desired
State(원하는 상태)** 다.

예를 들어:

``` text
"웹 서버를 3개 유지해!"
```

라고 선언하면 오케스트레이터가 현재 상태와 비교한다.

``` text
Desired = 3
Current = 2
```

이면 하나를 추가한다.

``` text
Desired = 3
Current = 4
```

이면 하나를 줄인다.

즉 관리자가 계속 컨테이너 하나하나를 직접 관리하는 것이 아니라:

``` text
사용자 → 원하는 상태 선언
           ↓
오케스트레이터
           ↓
실제 상태를 원하는 상태에 맞춤
```

이라는 방식으로 바뀐다.

이 사고방식이 Docker Swarm → Kubernetes로 이어지는 핵심이다.

------------------------------------------------------------------------

# 29. 오늘의 핵심 명령어 TOP

## Docker Swarm

``` bash
docker swarm init --advertise-addr <IP>
docker node ls

docker service create ...
docker service ls
docker service ps <SERVICE>
docker service inspect --pretty <SERVICE>

docker service scale myweb=4
docker service update --image nginx:1.15 myweb
docker service rollback myweb

docker service rm myweb
docker swarm leave -f
```

## SSH / Node 준비

``` bash
ssh-keygen
ssh-copy-id node1
ssh-copy-id node2
ssh-copy-id node3

swapoff -a
free

systemctl enable --now docker
```

## Kubespray

``` bash
ansible-playbook \
  -i inventory/mycluster/hosts.yaml \
  --become \
  --become-user=root \
  cluster.yml
```

## Kubernetes

``` bash
kubectl get nodes
kubectl get nodes -o wide
kubectl describe node master

kubectl get pod -A
kubectl get pod -o wide

kubectl create deployment webserver \
  --image=httpd \
  --replicas 3
```

------------------------------------------------------------------------

# 30. 면접 대비 Q&A

## Q1. Docker Swarm이란?

**A.** 여러 Docker Host를 하나의 클러스터로 구성하여 Service를 배포하고
Replica, Scheduling, Scaling, Rolling Update 등을 관리할 수 있는
Docker의 오케스트레이션 기능입니다.

------------------------------------------------------------------------

## Q2. Manager와 Worker의 차이는?

**A.** Manager는 클러스터 상태와 Service를 관리하고 Task를 스케줄링하며,
Worker는 Manager가 할당한 Task를 실제로 실행합니다.

------------------------------------------------------------------------

## Q3. Service와 Task의 차이는?

**A.** Service는 애플리케이션의 원하는 상태를 정의하고, Task는 그
Service를 구성하기 위해 노드에서 실제 실행되는 작업 단위입니다.

------------------------------------------------------------------------

## Q4. Replica란?

**A.** 동일한 워크로드를 몇 개 유지할 것인지 나타내는 개수입니다.
오케스트레이터는 현재 실행 개수가 Replica 값과 일치하도록 조정합니다.

------------------------------------------------------------------------

## Q5. Scale Out이란?

**A.** 실행되는 Replica 수를 늘려 워크로드를 수평 확장하는 것입니다.

Docker Swarm 예:

``` bash
docker service scale myweb=6
```

------------------------------------------------------------------------

## Q6. Rolling Update란?

**A.** 실행 중인 인스턴스를 한꺼번에 교체하지 않고 순차적으로 새로운
버전으로 변경하는 업데이트 방식입니다.

------------------------------------------------------------------------

## Q7. Rollback이란?

**A.** 업데이트 후 문제가 발생했을 때 이전 Service 설정 또는 버전으로
되돌리는 작업입니다.

``` bash
docker service rollback myweb
```

------------------------------------------------------------------------

## Q8. Ansible을 사용한 이유는?

**A.** 여러 서버에 반복적으로 수행해야 하는 설치와 설정 작업을 SSH
기반으로 자동화하기 위해 사용했습니다.

------------------------------------------------------------------------

## Q9. Kubespray란?

**A.** Ansible Playbook을 이용해 여러 노드에 Kubernetes 클러스터를
자동으로 구축할 수 있도록 구성된 프로젝트입니다.

------------------------------------------------------------------------

## Q10. Kubernetes Control Plane과 Worker Node의 차이는?

**A.** Control Plane은 클러스터 전체의 상태와 워크로드 배치를 관리하고,
Worker Node는 실제 Pod를 실행합니다.

------------------------------------------------------------------------

## Q11. `kubectl get nodes`에서 `Ready`는?

**A.** 해당 Node가 Kubernetes 클러스터에서 정상적으로 동작하며
워크로드를 처리할 준비가 된 상태임을 의미합니다.

------------------------------------------------------------------------

## Q12. Calico는 무엇인가?

**A.** 오늘 구축한 Kubernetes 클러스터에서 사용된 네트워크 플러그인으로,
Pod 네트워크 구성을 담당합니다.

------------------------------------------------------------------------

## Q13. CoreDNS는 무엇인가?

**A.** Kubernetes 클러스터 내부의 DNS 기능을 담당하는 구성요소입니다.

------------------------------------------------------------------------

## Q14. 오늘 Swarm과 Kubernetes의 공통점을 하나 꼽는다면?

**A.** 사용자가 원하는 Replica 수 같은 **Desired State를 선언하면
오케스트레이터가 실제 상태를 그 상태에 맞게 유지한다는 점**입니다.

------------------------------------------------------------------------

# 31. 5분 복습 체크리스트

아래 질문에 답할 수 있으면 오늘 핵심은 잡힌 것이다. 😏

-   [ ] Docker Swarm에서 Manager와 Worker 차이를 설명할 수 있다.
-   [ ] Service / Task / Replica 차이를 설명할 수 있다.
-   [ ] `docker service ps`가 무엇을 보여주는지 안다.
-   [ ] `docker service scale`로 Scale Out/In을 할 수 있다.
-   [ ] Rolling Update와 Rollback 차이를 설명할 수 있다.
-   [ ] `--constraint=node.role!=manager` 의미를 안다.
-   [ ] SSH Key를 왜 구성했는지 설명할 수 있다.
-   [ ] Ansible과 Kubespray의 관계를 설명할 수 있다.
-   [ ] Control Plane과 Worker Node 차이를 설명할 수 있다.
-   [ ] `kubectl get nodes`에서 모든 노드가 `Ready`인지 확인할 수 있다.
-   [ ] Calico와 CoreDNS의 역할을 한 문장으로 설명할 수 있다.
-   [ ] Deployment의 Replica와 Swarm Service의 Replica 개념을 연결해서
    이해한다.

------------------------------------------------------------------------

# 32. 오늘의 한 장 요약

``` text
┌───────────────────────────────────────────────┐
│                Docker Swarm                   │
├───────────────────────────────────────────────┤
│ Manager : docker1                             │
│ Worker  : docker2, docker3                    │
│ Service : myweb                               │
│ Image   : nginx:1.14 → 1.15 → rollback 1.14 │
│ Replica : 2 → 4 → 6 → 4 → 2                 │
│ 핵심    : Service / Task / Scale / Update    │
└───────────────────────────────────────────────┘

                    ↓ 오케스트레이션 확장

┌───────────────────────────────────────────────┐
│                Kubernetes                     │
├───────────────────────────────────────────────┤
│ Control Plane : master (192.168.2.60)         │
│ Worker        : node1 / node2 / node3         │
│ 구축 도구     : Ansible + Kubespray           │
│ Kubernetes    : v1.27.7                       │
│ Network       : Calico                        │
│ DNS           : CoreDNS                       │
│ 실습          : httpd Deployment, 3 replicas │
│ 결과          : 모든 Node Ready               │
└───────────────────────────────────────────────┘
```

------------------------------------------------------------------------

# 33. 최종 핵심

오늘은 Docker의 단일 컨테이너 관리에서 한 단계 올라가
**오케스트레이션**을 직접 실습했다.

Docker Swarm에서:

``` text
Manager
Worker
Service
Task
Replica
Scale
Rolling Update
Rollback
```

을 실습했고, 이어서:

``` text
SSH Key
Ansible
Kubespray
Control Plane
Worker Node
Calico
CoreDNS
Deployment
Pod
```

까지 연결했다.

가장 중요한 문장은 이것 하나다.

> **"컨테이너를 직접 하나씩 관리하는 것이 아니라, 원하는 상태를 선언하고
> 오케스트레이터가 그 상태를 유지하도록 한다."**

이 개념을 잡아두면 이후 Kubernetes의 Deployment, ReplicaSet, Service,
Scheduler 등을 배울 때 오늘 실습이 그대로 연결된다. 🔥

------------------------------------------------------------------------

## Source Note

이 문서는 사용자가 제공한 `0914-Docker1.txt`, `0914-master.txt`,
`0914-master(2).txt`, `0914-node1.txt`의 2026-09-14 실습 기록을 중심으로
재구성하였다. 비밀정보에 해당할 수 있는 SSH 개인키 및 Swarm Join Token의
실제 값은 문서에 포함하지 않았다.
