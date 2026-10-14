# Day 47 — 2026-10-14 AWS EKS 로드 밸런싱 & Ansible 자동화 실습 총정리

> **근거 자료:** `Day47.txt`, `10-14 cmd 기록지.txt`, `1014-master.txt`, `1014-node1.txt`  
> **실습 구성:** Windows CMD에서 AWS EKS / VMware CentOS Stream 9 VM 4대(master, node1, node2, node3)에서 Ansible  
> **기록 해석:** node2·node3의 별도 터미널 로그는 node1과 동일한 과정·결과로 진행했다는 학습자 설명을 반영한다. Ansible에서 세 노드가 모두 `pong`을 반환한 사실은 master 로그에서 직접 확인된다.

---

## 1. 오늘의 전체 그림

| 구분 | 작업 | 실습 증거 |
|---|---|---|
| EKS | kubeconfig 연결 및 4개 워커 노드 확인 | `kubectl get node`에서 4대 Ready |
| EKS | Nginx 4개 복제본 + CLB 형태의 LoadBalancer Service | Deployment `4/4`, ELB DNS 발급 |
| EKS | AWS Load Balancer Controller 구성 | OIDC 연결, IAM Policy/ServiceAccount, Helm 설치 성공 |
| EKS | NLB / ALB 실습 | 별도 YAML 작성·적용·조회·삭제 기록 |
| EKS | eksctl 클러스터 선언적 구성 및 정리 | `eksctl create cluster -f`, `delete cluster -f` |
| Ansible | VMware 네 대의 관리 환경 구성 | master .60 / node1 .61 / node2 .62 / node3 .63 |
| Ansible | SSH 키 배포, 인벤토리 구성, 연결 검증 | 세 관리 노드 모두 Ansible `ping: pong` |
| Ansible | Ad-hoc 모듈 실습 | shell, command, user, yum, service, copy, fetch, lineinfile |

### 핵심 아키텍처

```text
Windows CMD + AWS CLI + kubectl + eksctl + Helm
                  │
                  ▼
            Amazon EKS
                  │
           워커 노드 4대
                  │
      Deployment (nginx × 4)
                  │
      Service / Ingress
                  │
       CLB · NLB · ALB

VMware 실습 환경 (192.168.2.0/24)

master.example.com  192.168.2.60  ← Ansible Control Node
   ├─ node1.example.com  192.168.2.61
   ├─ node2.example.com  192.168.2.62
   └─ node3.example.com  192.168.2.63
        SSH + Python 기반 원격 관리
```

> **구분:** EKS는 Kubernetes 클러스터 운영 실습이고, VMware 네 대는 Ansible 관리 환경이다. 같은 네 대라는 이유로 하나의 클러스터로 혼동하지 않는다.

---

## 2. AWS EKS: Windows에서 클러스터 관리

### 2.1 환경 변수 및 kubeconfig

```bat
set CLUSTER_NAME=MyEKSCluster
set VPCID=vpc-032836b3569207434
aws eks update-kubeconfig --region ap-northeast-2 --name %CLUSTER_NAME%
kubectl get node
kubectl get node -o wide
kubectl get pod -A
```

- `update-kubeconfig`: 로컬 `C:\Users\User\.kube\config`에 EKS 접속 컨텍스트 등록.
- `get node -o wide`: 내부/외부 IP, OS, 런타임까지 확인.
- 실제 로그에서 **워커 노드 4대 Ready**, Amazon Linux 2023, containerd 런타임 확인.
- `get pod -A`: CoreDNS, VPC CNI(`aws-node`), kube-proxy, metrics-server, Pod Identity Agent, external-dns 등 확인.

### 2.2 Deployment + CLB 계열 Service

실습 YAML의 핵심:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deploy
spec:
  replicas: 4
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
          image: nginx
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-loadbalancer
spec:
  type: LoadBalancer
  selector:
    app: webui
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 30000
```

```bat
kubectl create -f nginx-deploy-clb.yml
kubectl get deploy,rs,pod
kubectl get svc,pod,ep -o wide
kubectl delete -f nginx-deploy-clb.yml
```

**관찰:** Deployment 4/4, Pod 4개 Running, `nginx-loadbalancer`에 외부 ELB 주소 부여. 각 Pod가 서로 다른 워커 노드에 배치된 결과도 기록됨. 단, 항상 노드당 하나씩 배치되는 것은 아니다.

**개념 연결:** `Deployment → ReplicaSet → Pod`, `Service selector(app=webui) → Pod labels`, `LoadBalancer Service → AWS 외부 로드 밸런서`. `nodePort: 30000`은 노드에서 Service를 노출하는 포트이며, `targetPort: 80`은 컨테이너로 전달할 목적 포트다.

> **추가 해설:** CLB/NLB/ALB의 실제 생성 경로는 EKS 설정, Service 어노테이션, 설치된 컨트롤러에 따라 달라진다. `type: LoadBalancer`만으로 무조건 CLB라고 일반화하면 안 된다.

### 2.3 AWS Load Balancer Controller 준비

```bat
eksctl utils associate-iam-oidc-provider --cluster %CLUSTER_NAME% --approve
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam-policy.json
```

이후 `eksctl create iamserviceaccount`로 `kube-system/aws-load-balancer-controller` 서비스 계정과 IAM 역할을 연결하고, `kubectl describe serviceaccount`에서 `eks.amazonaws.com/role-arn` 어노테이션을 확인했다.

**흐름:** IAM 정책(필요한 AWS API 권한) → IAM 역할 → Kubernetes ServiceAccount → 컨트롤러 Pod의 AWS 권한 사용. 실습에서는 **IRSA(OIDC 기반 서비스 계정 IAM 역할)** 방식을 사용했다. EKS Pod Identity Agent가 보이는 것과 IRSA 설정은 서로 별개의 사실이다.

### 2.4 Helm 설치와 실제 오류

```bat
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller ^
  -n kube-system ^
  --set clusterName=%CLUSTER_NAME% ^
  --set serviceAccount.create=false ^
  --set serviceAccount.name=aws-load-balancer-controller ^
  --set region=ap-northeast-2 ^
  --set vpcId=%VPCID%
```

**실제 오류(2회):** `INSTALLATION FAILED ... error validating data: the server is currently unable to handle the request`.

**실제 성공:** 같은 설치 명령에 `--disable-openapi-validation`을 추가했을 때 `STATUS: deployed`, `AWS Load Balancer controller installed!` 출력.

**주의:** OpenAPI 검증을 끄는 것은 검증 단계를 우회하는 조치이지 API 서버 문제의 근본 원인을 해결했다는 증거가 아니다. 실제 원인은 이 로그만으로 확정할 수 없다. 운영 환경에서는 API 서버 상태, admission webhook, 차트/Kubernetes 버전 호환성, 컨트롤러 Pod 및 로그를 추가 확인해야 한다.

### 2.5 NLB와 ALB 실습

Windows 기록에서 다음 순서가 확인된다.

```bat
copy con nginx-deploy-nlb.yml
kubectl create -f nginx-deploy-nlb.yml
kubectl get svc,pod,ep -o wide
kubectl delete -f nginx-deploy-nlb.yml

copy con nginx-deploy-alb.yml
kubectl create -f nginx-deploy-alb.yml
kubectl get deploy,rs,pod
kubectl get svc,pod,ep -o wide
kubectl get ingress
kubectl describe ingress
kubectl delete -f nginx-deploy-alb.yml
```

| 구분 | CLB | NLB | ALB |
|---|---|---|---|
| 주된 계층 | 전통적인 ELB, L4/L7 기능 혼합 | L4 | L7 |
| 대표 기능 | 레거시 로드 밸런싱 | TCP/UDP/TLS 기반 전송 | HTTP/HTTPS 호스트·경로 라우팅 |
| K8s에서 흔한 연계 | 레거시 Service | LoadBalancer Service | Ingress + AWS Load Balancer Controller |
| 면접 포인트 | 신규 설계에서는 일반적으로 ALB/NLB 우선 | 고성능 L4 트래픽 | 웹 애플리케이션 라우팅 |

**중요:** Ingress는 라우팅 규칙을 선언하는 Kubernetes 리소스이며, 실제 ALB 생성·조정은 해당 Ingress를 처리하는 컨트롤러가 수행한다. `IngressClass`, annotation, subnet/SG/IAM 구성이 핵심이다.

### 2.6 EKS 선언형 클러스터 생성·삭제

```bat
eksctl create cluster -f eks-cluster.yml
kubectl get nodes
kubectl get pod -A
eksctl delete cluster -f eks-cluster.yml
```

`eksctl`은 EKS 클러스터·노드 그룹 등 AWS 인프라를 생성/관리하는 CLI, `kubectl`은 Kubernetes API의 리소스를 관리하는 CLI, `Helm`은 차트로 Kubernetes 애플리케이션을 배포하는 패키지 관리자다.

> **비용 주의:** 실습 후 EKS 클러스터, 노드 그룹/EC2, ELB, NAT Gateway, EIP, EBS, CloudFormation 스택 등을 콘솔에서 점검한다. Kubernetes YAML 삭제와 AWS 인프라 전체 삭제는 다르다. `eksctl delete cluster` 실행 기록만으로 모든 과금 리소스가 완전히 사라졌다고 단정하지 않는다.

---

## 3. VMware 4대: Ansible 사전 환경

### 3.1 IP/호스트명

| 역할 | 호스트명 | IP |
|---|---|---|
| 제어 노드 | master.example.com | 192.168.2.60 |
| 관리 노드 | node1.example.com | 192.168.2.61 |
| 관리 노드 | node2.example.com | 192.168.2.62 |
| 관리 노드 | node3.example.com | 192.168.2.63 |

각 VM에서 `hostnamectl set-hostname`, `nmcli connection modify ens33 ipv4.addresses .../24`, `nmcli connection up ens33`, `ip address show ens33`로 설정·검증했다. Master에서 세 노드로 `ping`을 수행했다. `/etc/hosts`에 네 호스트의 주소·별칭을 등록했다.

**node1 로그에서 직접 확인:** `/etc/hosts` 등록, `systemctl set-default multi-user.target && systemctl isolate multi-user.target`, 이전 실습 사용자 삭제, `yum -y erase httpd` 수행. node2·node3도 같은 방식으로 실습했다는 설명을 반영한다.

> `multi-user.target`은 GUI가 없는 다중 사용자 CLI 중심 실행 목표다. `userdel -r`은 홈 디렉터리까지 삭제할 수 있으므로 실제 운영에서는 신중히 사용한다.

### 3.2 SSH 공개키 인증

```bash
ssh-keygen
ssh-copy-id 192.168.2.60
ssh-copy-id 192.168.2.61
ssh-copy-id 192.168.2.62
ssh-copy-id 192.168.2.63
ssh root@192.168.2.61
```

- `id_rsa`: 개인키 — 절대 공유하지 않음.
- `id_rsa.pub`: 공개키 — 관리 대상의 `authorized_keys`에 등록.
- `known_hosts`: 접속 대상 서버의 호스트 공개키 기록. 사용자 로그인 인증용 `authorized_keys`와 **다른 파일**.
- 로그에서 각 노드에 공개키 1개씩 추가되고 SSH 접속이 확인되었다.

**주의 깊게 볼 현상:** 여러 VM의 SSH 호스트 키 지문이 같다는 경고가 로그에 반복된다. 복제/스냅샷 VM에서 호스트 키까지 복제되었을 가능성이 있다. 학습 환경에서는 발생할 수 있지만 운영 환경에서는 각 서버의 SSH 호스트 키 고유성을 점검하고, 신뢰할 수 있는 방법으로 지문을 검증해야 한다.

### 3.3 Ansible 설치와 Inventory

```bash
yum -y install epel-release
yum -y install yum-utils
yum -y install ansible*
yum install -y python3-argcomplete
activate-global-python-argcomplete
ansible --version
```

`/etc/ansible/hosts` 인벤토리를 편집하고 다음을 실행했다.

```bash
ansible all -m ping --list-hosts
ansible all -m ping
ansible all -m ping -k
```

**실제 결과:** `192.168.2.61`, `.62`, `.63` 모두 `SUCCESS`, `ping: pong`.

별도 `node.list`도 만들었다.

```text
192.168.2.61
192.168.2.62
192.168.2.63
```

```bash
ansible -i node.list all -m ping
ansible testnode -m ping
```

`-i`는 인벤토리 파일 지정, `all`은 전체 관리 대상, `testnode`는 인벤토리 그룹을 가리킨다. `-k`는 SSH 접속 암호를 요청한다. Ansible `ping`은 ICMP ping이 아니라 원격 연결과 Python 실행 가능성을 확인하는 모듈이다.

---

## 4. Ansible Ad-hoc 명령어 실습

### 4.1 기본 문법

```bash
ansible <대상> -m <모듈> -a '<모듈 인수>' [-b] [-i 인벤토리]
```

- `-m`: 모듈 선택
- `-a`: 모듈 인수
- `-b`: become(권한 상승)
- `-i`: 인벤토리 지정
- `-k`: SSH 암호 요청

### 4.2 shell vs command

```bash
ansible all -m shell -a 'uname -a'
ansible 192.168.2.61 -m shell -a 'ps -ef | grep sshd'
ansible 192.168.2.61 -m command -a 'ps -ef | grep sshd'
```

**핵심 차이:** `shell`은 파이프(`|`), 리다이렉션, 셸 변수 등 셸 기능을 해석하지만 `command`는 일반적으로 셸을 거치지 않는다. 따라서 `command`에 `| grep sshd`를 적는다고 파이프가 작동하지 않는다. 불필요한 셸 해석이 없도록 가능한 경우 전용 모듈이나 `command`를 우선한다.

### 4.3 사용자 계정 관리

실제 로그에서 `shell`로 `useradd/userdel`, `user` 모듈로 사용자 생성·삭제, `password_hash('sha512')`를 이용한 암호 설정을 비교했다.

```bash
ansible 192.168.2.61 -m user -a 'name=user1' -b
ansible 192.168.2.61 -m user -a 'name=user2' -b
ansible 192.168.2.61 -m user -a 'name=user1 state=absent' -b
ansible 192.168.2.61 -m user -a 'name=user2 state=absent' -b
```

**실무 보강:** 평문 암호를 명령줄에 노출하지 않는다. Ansible Vault 또는 조직의 비밀 관리 시스템을 사용한다. `state=absent`는 기본적으로 사용자 홈 디렉터리까지 삭제하는 명령이 아니며, 필요한 경우 `remove=yes`의 영향을 따로 검토한다.

### 4.4 패키지 설치 및 서비스 제어

```bash
ansible 192.168.2.61 -m yum -a 'name=httpd state=present' -b
ansible 192.168.2.61 -m service -a 'name=httpd state=started enabled=yes' -b
ansible 192.168.2.61 -m service -a 'name=httpd state=restarted' -b
ansible 192.168.2.61 -m service -a 'name=httpd state=stopped enabled=no' -b
ansible 192.168.2.61 -m yum -a 'name=httpd state=removed' -b
```

| 모듈 | 기능 | 상태 예시 |
|---|---|---|
| `yum` | 패키지 관리 | `present`, `absent`/`removed` |
| `service` | 서비스 실행 상태 | `started`, `stopped`, `restarted` |
| `user` | 사용자 관리 | `present`, `absent` |

**실제 실수 포인트:** `-m service 'name=...'`처럼 `-a`가 빠진 명령과 `service state=removed` 시도가 있었다. 패키지 제거는 `yum` 계열 모듈에서, 서비스 정지는 `service` 모듈에서 수행한다. `state=started`는 이미 실행 중이면 재시작하지 않는 방식으로 원하는 상태를 유지한다.

### 4.5 파일 관리: copy / fetch / lineinfile

```bash
cp /etc/issue testfile
ansible 192.168.2.61 -m copy -a 'src=testfile dest=/tmp'
ansible 192.168.2.61 -m fetch -a 'src=/etc/services dest=/root' -b
ansible 192.168.2.61 -m fetch -a 'src=/etc/services dest=/root flat=yes' -b
ansible 192.168.2.61 -m lineinfile -a 'path=/tmp/testfile line=abcd'
ansible 192.168.2.61 -m lineinfile -a 'path=/tmp/testfile line=abcd state=absent'
```

- `copy`: 제어 노드 → 관리 노드.
- `fetch`: 관리 노드 → 제어 노드. 기본적으로 호스트별 하위 디렉터리를 만들어 저장; `flat=yes`는 이를 평탄화하므로 여러 노드의 동명 파일 수집 시 덮어쓰기 위험을 주의.
- `lineinfile`: 파일 내 특정 줄이 존재하도록 하거나 제거. 설정 파일의 한 줄 관리에 적합.

---

## 5. 오늘의 오류·트러블슈팅 정리

| 로그의 현상 | 해석 | 재발 방지 |
|---|---|---|
| `cat /etc/host` 실패 | 실제 파일은 `/etc/hosts` | 파일 경로 정확히 확인 |
| `kubectl get deploy,ts,pod,svc` 오류 | `ts`는 존재하지 않는 리소스 종류 | `rs` 등 정확한 약어 사용 |
| Helm OpenAPI 검증 실패 | Kubernetes 객체 검증 단계 실패, 원인은 미확정 | API 서버·웹훅·버전·로그 확인 |
| Helm `--disable-openapi-validation`로 배포 성공 | 검증 우회 후 Helm 릴리스 deployed | 우회 옵션을 상시 해결책으로 사용하지 않기 |
| SSH `Permission denied` | `known_hosts_update.sh` 실행 중 인증 실패 출력 | 인증 주체·암호·키·스크립트 확인 |
| VM 여러 대의 SSH 호스트 지문 동일 | 복제된 호스트 키 가능성 | 호스트별 고유 키 및 지문 확인 |
| `command`에 파이프 사용 | 셸 메타문자를 처리하지 않음 | `shell` 또는 전용 모듈 사용 |
| `service state=removed` | 서비스 모듈의 적절한 상태가 아님 | 패키지 삭제는 `yum`/`dnf` |
| `cat /etc/shadow | grep tail` 실패 | `tail`을 파이프 명령이 아닌 grep 검색어로 사용 | `cat /etc/shadow | tail` |

> **보안 보강:** 실습에서 `/etc/sudoers` 권한을 `chmod 740`으로 변경한 기록이 있다. 운영 환경에서는 직접 `vi`와 임의 chmod 대신 `visudo`로 문법을 검증하고, 일반적인 보안 권한(예: 0440)을 유지해야 한다. root 직접 SSH, `sshpass`, 평문 암호도 학습 편의와 운영 권장 사항을 구분한다.

---

## 6. 실무 관점: 왜 중요한가?

**Kubernetes/EKS:** Deployment가 애플리케이션 복제본 수를 유지하고, Service/Ingress가 트래픽 경로를 정의한다. AWS Load Balancer Controller는 이 선언을 AWS ALB/NLB 리소스로 연결한다. IAM·OIDC·IRSA는 컨트롤러가 AWS API를 안전하게 호출할 수 있게 하는 권한 경계다.

**Ansible:** 관리 노드에 별도 Ansible 에이전트를 설치하지 않고 SSH와 원격 Python을 활용하여 여러 서버의 상태를 통일한다. Ad-hoc은 일회성 작업에 유용하고, 반복되는 작업은 Playbook으로 옮겨 코드로 관리한다.

**IaC 연결:** Terraform/CloudFormation은 인프라 프로비저닝에, Ansible은 OS·패키지·서비스 설정에, Kubernetes 매니페스트와 Helm은 컨테이너 워크로드 운영에 각각 많이 쓰인다. 역할이 일부 겹치지만 관리 대상과 선언 방식이 다르다.

### 실무용 개선 예제 — Ansible Playbook (오늘 실습의 확장, 원본 로그 아님)

```yaml
---
- name: Configure web servers
  hosts: webservers
  become: true
  tasks:
    - name: Install Apache
      ansible.builtin.dnf:
        name: httpd
        state: present

    - name: Start and enable Apache
      ansible.builtin.service:
        name: httpd
        state: started
        enabled: true
```

```ini
[webservers]
192.168.2.61
192.168.2.62
192.168.2.63
```

```bash
ansible-playbook -i inventory.ini web.yml --check
ansible-playbook -i inventory.ini web.yml
```

`--check`는 변경 사항을 사전 예측하는 모드지만 모든 모듈과 외부 효과를 완벽히 시뮬레이션하지는 않는다.

---

## 7. 면접 예상 질문 & 모범 답변

**Q1. EKS에서 `kubectl`, `eksctl`, `Helm`의 차이는?**  
A. `kubectl`은 Kubernetes 리소스 관리, `eksctl`은 EKS 클러스터 및 AWS 연계 인프라 관리, `Helm`은 Kubernetes 애플리케이션 패키지 설치·업그레이드·제거에 주로 사용합니다.

**Q2. Deployment와 Service의 차이는?**  
A. Deployment는 Pod의 선언된 복제본 수와 업데이트를 관리하고, Service는 레이블 셀렉터 등으로 백엔드를 찾아 안정적인 네트워크 접근을 제공합니다.

**Q3. ALB와 NLB의 차이는?**  
A. ALB는 L7 HTTP/HTTPS 경로·호스트 라우팅에 적합하고, NLB는 L4 TCP/UDP 등 전송 계층 트래픽 처리에 적합합니다.

**Q4. IRSA가 필요한 이유는?**  
A. Kubernetes ServiceAccount에 특정 IAM 역할을 연계해 Pod에 필요한 AWS 권한을 부여하기 위해서입니다. 노드 전체에 과도한 권한을 주는 방식을 줄일 수 있습니다.

**Q5. Ansible은 왜 agentless라고 하나요?**  
A. 일반적인 Linux 관리에서는 대상 서버에 상주하는 Ansible 에이전트를 설치하지 않고 SSH와 Python을 이용해 작업을 수행하기 때문입니다.

**Q6. Inventory란?**  
A. 관리 대상 호스트와 그룹, 연결 변수 등을 정의하는 목록입니다. 기본 파일 또는 `-i`로 지정한 별도 파일을 사용합니다.

**Q7. Ansible `ping`과 OS `ping`의 차이는?**  
A. OS `ping`은 ICMP 통신 검사이고, Ansible `ping` 모듈은 원격 로그인 및 모듈 실행 가능 여부를 확인합니다.

**Q8. `shell`과 `command`의 차이는?**  
A. `shell`은 셸을 거쳐 파이프·리다이렉션 등을 해석하지만, `command`는 기본적으로 셸 없이 명령을 실행합니다.

**Q9. `copy`와 `fetch`의 방향은?**  
A. `copy`는 컨트롤 노드에서 관리 노드로, `fetch`는 관리 노드에서 컨트롤 노드로 파일을 가져옵니다.

**Q10. Ansible 멱등성이란?**  
A. 동일한 원하는 상태를 반복 적용해도 불필요한 변경이 일어나지 않는 성질입니다. `user`, `dnf`, `service` 같은 상태 기반 모듈이 대표적이며, 임의의 `shell` 명령은 자동으로 멱등성을 보장하지 않습니다.

**Q11. Helm 릴리스가 deployed면 모든 것이 정상인가요?**  
A. 아닙니다. 릴리스 상태 외에 Deployment/Pod Ready, 이벤트, 컨트롤러 로그, 실제 ALB/NLB 생성과 트래픽 전달까지 검증해야 합니다.

**Q12. VMware 복제 VM의 SSH 호스트 키가 같다면?**  
A. 서로 다른 서버를 암호학적으로 구별하기 어려워질 수 있으므로 각 서버에 고유한 SSH 호스트 키가 있는지 점검하고 검증된 지문을 신뢰 저장소에 반영합니다.

---

## 8. 복습 체크리스트

- [ ] EKS의 `Deployment → ReplicaSet → Pod` 흐름 설명
- [ ] Service의 `port`, `targetPort`, `nodePort` 구분
- [ ] CLB/NLB/ALB 차이와 Service/Ingress 연결 설명
- [ ] OIDC, IAM Policy, IAM Role, ServiceAccount, IRSA 연결 설명
- [ ] Helm 오류에서 검증 우회와 근본 원인 해결 구분
- [ ] VMware 4대의 IP와 Ansible 제어/관리 노드 역할 기억
- [ ] SSH `authorized_keys`와 `known_hosts` 차이 설명
- [ ] Inventory 그룹을 대상으로 `ansible -m ping` 실행
- [ ] `shell`, `command`, `user`, `yum`, `service` 구분
- [ ] `copy`, `fetch`, `lineinfile`의 사용 목적 설명
- [ ] `ansible-playbook`으로 Ad-hoc 작업을 재사용 가능한 코드로 전환
- [ ] EKS/ELB/EC2 잔여 리소스 및 과금 확인

## 9. 오늘의 한 줄 결론

> **AWS EKS에서는 Kubernetes 워크로드를 AWS 로드 밸런서에 연결하는 과정을, Ansible에서는 SSH 기반으로 여러 Linux 서버의 상태를 일괄 관리하는 기초를 실습했다.**

**자료 구분:** 본문의 실행·성공·실패 사실은 2026-10-14의 네 로그 및 학습자의 node2·node3 설명에 근거한다. 개념 설명, 보안 권고, Playbook 예제, 면접 답변은 이해를 돕기 위해 별도로 보강했다. 비밀번호·계정 ID·전체 공개 주소는 학습 자료에 불필요한 노출을 줄이기 위해 대부분 생략했다.
