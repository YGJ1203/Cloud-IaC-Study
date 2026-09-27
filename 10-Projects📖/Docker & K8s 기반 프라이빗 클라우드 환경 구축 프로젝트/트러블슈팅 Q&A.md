# 일요일 Review — Kubernetes Troubleshooting Q&A

> **주제:** Docker & Kubernetes 기반 프라이빗 클라우드 프로젝트  
> **목표:** 명령어 암기 ❌ → 장애 원인을 스스로 추적하는 사고방식 만들기 ⭕

---

# Q1. 웹페이지 접속이 안 된다. 가장 먼저 무엇을 확인해야 할까?

바로 Ingress나 HAProxy 설정을 수정하는 것이 아니라 **Pod부터 확인한다.**

```bash
kubectl get pods -n kaist -o wide
```

확인 항목:

- `READY`
- `STATUS`
- Pod IP
- 실행 Node
- Restart 횟수

### 핵심

```text
Pod → Service → Endpoint → NodePort
                    ↓
                 Ingress
                    ↓
                 HAProxy
```

**안쪽부터 바깥쪽으로 확인한다.**

---

# Q2. Pod가 `Running`이면 서비스도 정상일까?

❌ 아니다.

Pod가 정상이어도 다음과 같은 문제가 있을 수 있다.

```text
Service Selector 오류
Endpoint 없음
NodePort 오류
Ingress Rule 오류
HAProxy Backend 오류
Firewall 문제
```

따라서:

```bash
kubectl get pods -n kaist
```

만 보고 끝내면 안 된다.

---

# Q3. Service는 존재하는데 접속이 안 된다. 무엇을 확인해야 할까?

가장 먼저 **Endpoint**를 확인한다.

```bash
kubectl get endpoints -n kaist
```

정상이라면:

```text
kaist-service
10.233.x.x:80
10.233.x.x:80
```

처럼 연결된 Pod IP가 나타난다.

만약:

```text
<none>
```

이라면 Service가 연결할 Pod를 찾지 못하고 있을 가능성이 높다.

---

# Q4. Endpoint가 생성되지 않는 대표적인 이유는?

**Service Selector와 Pod Label 불일치.**

예:

```yaml
# Pod
labels:
  app: kaist-ai
```

```yaml
# Service
selector:
  app: kaist-web
```

서로 다르므로 Service가 Pod를 선택할 수 없다.

확인:

```bash
kubectl get pods -n kaist --show-labels
kubectl describe svc kaist-service -n kaist
```

### 기억

```text
Service Selector
       ↓
    Pod Label
       ↓
    MATCH!
```

---

# Q5. Pod를 삭제했는데 잠시 후 새로운 Pod가 나타났다. 왜 그럴까?

Deployment가 **원하는 상태(Desired State)** 를 유지하기 때문이다.

예를 들어:

```yaml
replicas: 2
```

라면 Kubernetes는 계속 Pod 2개가 존재하도록 관리한다.

```text
Pod 2개
   ↓
Pod 하나 삭제
   ↓
현재 상태 = 1
원하는 상태 = 2
   ↓
ReplicaSet
   ↓
새로운 Pod 생성
   ↓
다시 2개
```

이것이 Kubernetes의 **Self-Healing** 특성이다.

---

# Q6. 새로 생성된 Pod의 IP가 이전과 달라졌다. 문제일까?

❌ 정상이다.

Pod는 삭제 후 재생성되면서 새로운 IP를 받을 수 있다.

따라서 사용자가:

```text
10.233.x.x
```

같은 Pod IP에 직접 의존해서는 안 된다.

대신:

```text
Client
  ↓
Service
  ↓
Pod
```

구조를 사용한다.

Service가 안정적인 접근 지점을 제공한다.

---

# Q7. NodePort가 `30080`이라면 어떻게 테스트할까?

예:

```bash
curl http://192.168.2.60:30080
```

또는 다른 Node에서:

```bash
curl http://192.168.2.61:30080
```

NodePort Service는:

```text
<Node IP>:<NodePort>
```

형태로 접근한다.

### 구조

```text
192.168.2.60:30080
        ↓
     Service
        ↓
    Endpoint
        ↓
       Pod
```

---

# Q8. `docker ps`에서 `80/tcp`가 보이는데 localhost로 접속이 안 된다. 왜?

`80/tcp`는 컨테이너가 80번 포트를 사용한다는 뜻이지,

**Host 80번 포트와 연결되었다는 뜻은 아니다.**

예:

```bash
docker run -d --name web nginx
```

외부 포트 연결 없음.

반면:

```bash
docker run -d \
  --name web \
  -p 8080:80 \
  nginx
```

이면:

```text
Host :8080
   ↓
Container :80
```

이므로:

```bash
curl localhost:8080
```

으로 접근할 수 있다.

---

# Q9. `ImagePullBackOff`가 발생했다. 어디부터 볼까?

```bash
kubectl describe pod <POD_NAME> -n kaist
```

그리고 가장 아래쪽의:

```text
Events:
```

를 확인한다.

대표적인 원인:

- 이미지 이름 오타
- Tag 오류
- Registry 접근 실패
- 인증 문제
- Node에 로컬 이미지가 없음
- `imagePullPolicy` 문제

Docker 이미지도 확인한다.

```bash
docker images
```

프로젝트 이미지라면:

```bash
docker images | grep kaist
```

---

# Q10. `ngnix` 이미지를 실행했는데 Pull 오류가 발생했다. 원인은?

☠️ **오타.**

```text
ngnix ❌
nginx ⭕
```

복잡한 오류 메시지가 나타나더라도:

```text
Image Name
Container Name
Namespace
Service Name
Port
Label
```

부터 확인한다.

> **Troubleshooting Rule #1: 오타를 무시하지 말자.**

---

# Q11. Ingress가 정상인지 확인하려면?

Ingress:

```bash
kubectl get ingress -n kaist
```

상세:

```bash
kubectl describe ingress -n kaist
```

IngressClass:

```bash
kubectl get ingressclass
```

Ingress Controller:

```bash
kubectl get pods -n ingress-nginx
```

Controller Service:

```bash
kubectl get svc -n ingress-nginx
```

### 핵심 구조

```text
Client
  ↓
Ingress Controller
  ↓
Ingress Rule
  ↓
Service
  ↓
Pod
```

Ingress 리소스만 존재한다고 끝이 아니다.

**Ingress Controller가 실제로 동작해야 한다.**

---

# Q12. HAProxy에서 `Connection refused`가 발생했다. 무엇을 의미할까?

HAProxy가 Backend에 TCP 연결을 시도했지만 해당 IP/Port에서 연결을 받아주지 않는 상황을 우선 의심한다.

확인:

```bash
systemctl status haproxy
```

로그:

```bash
journalctl -u haproxy
```

그리고 Backend 설정 확인:

```bash
vi /etc/haproxy/haproxy.cfg
```

예를 들어 실제 서비스가:

```text
192.168.2.61:31512
```

에서 동작하는데 HAProxy가:

```text
192.168.2.61:80
```

으로 접근한다면 실패할 수 있다.

---

# Q13. HAProxy 설정을 수정했다. 바로 브라우저를 열면 될까?

먼저 설정 문법을 검사한다.

```bash
haproxy -c -f /etc/haproxy/haproxy.cfg
```

정상이면:

```bash
systemctl restart haproxy
```

상태:

```bash
systemctl status haproxy
```

로그:

```bash
journalctl -u haproxy
```

마지막으로:

```bash
curl http://192.168.2.80
```

### 정석

```text
Config
  ↓
Syntax Check
  ↓
Restart
  ↓
Status
  ↓
Log
  ↓
curl
  ↓
Browser
```

---

# Q14. 이번 프로젝트에서 NFS/PV/PVC를 사용하지 않아도 됐던 이유는?

현재 프로젝트에서는 웹 콘텐츠가 컨테이너 이미지에 포함되어 있고, 영속적으로 변경되는 데이터를 저장해야 하는 요구사항이 크지 않았다.

따라서:

```text
"NFS도 배웠으니까 넣자!"
```

보다는:

```text
"이 서비스에 Persistent Storage가 필요한가?"
```

를 먼저 판단한다.

향후 다음과 같은 기능이 생긴다면 다시 고려할 수 있다.

- 사용자 업로드
- DB 데이터
- 여러 Pod가 공유하는 파일
- Pod 재생성 후에도 유지되어야 하는 데이터

### 핵심

**기술은 많이 넣는 것이 목적이 아니라 필요한 기술을 선택하는 것이 목적이다.**

---

# Q15. 장애 발생 시 가장 중요한 Kubernetes 점검 순서를 말해보자.

🔥 **이건 외워두자.**

```text
① Pod
   ↓
② Deployment
   ↓
③ Service
   ↓
④ Endpoint
   ↓
⑤ NodePort
   ↓
⑥ Ingress
   ↓
⑦ HAProxy
   ↓
⑧ Client
```

대표 명령:

```bash
kubectl get pods -n kaist -o wide

kubectl get deploy -n kaist

kubectl get svc -n kaist

kubectl get endpoints -n kaist

curl http://<NODE_IP>:<NODEPORT>

kubectl get ingress -n kaist

systemctl status haproxy

curl http://<VIP>
```

---

# ⭐ Bonus Q1. 왜 Endpoint 확인이 중요할까?

Endpoint는 **Service와 실제 Pod 사이의 연결 상태를 빠르게 보여주기 때문**이다.

```text
Pod Running
      +
Service 존재
```

만으로는 실제 연결을 보장하지 않는다.

```bash
kubectl get endpoints -n kaist
```

에서 Pod IP가 나타난다면:

```text
Service
   ↓
Endpoint
   ↓
Pod
```

연결 관계를 확인할 수 있다.

---

# ⭐ Bonus Q2. 문제를 발견하면 바로 YAML부터 수정하면 안 되는 이유는?

원인을 모르는 상태에서 설정을 변경하면 새로운 문제를 만들 수 있기 때문이다.

잘못된 방식:

```text
안 됨
 ↓
YAML 수정
 ↓
또 안 됨
 ↓
다른 설정 수정
 ↓
💀
```

권장 방식:

```text
증상 확인
 ↓
정상 구간 확인
 ↓
장애 구간 특정
 ↓
원인 확인
 ↓
수정
 ↓
검증
```

---

# ⭐ Bonus Q3. 프로젝트에서 가장 중요한 트러블슈팅 사고방식은?

한 번에 전체 시스템을 보려고 하지 않는다.

예:

```text
Client
   ↓
HAProxy
   ↓
Ingress / NodePort
   ↓
Service
   ↓
Endpoint
   ↓
Pod
   ↓
Container
```

각 구간을 하나씩 테스트하면서:

> **"여기까지는 정상이다."**

라는 경계를 찾아간다.

그 다음 구간이 장애 후보가 된다.

---

# 🎯 면접 30초 답변

> Kubernetes 환경에서 장애가 발생하면 Pod부터 외부 접근 계층까지 단계적으로 확인합니다. 먼저 Pod와 Deployment 상태를 확인하고, Service Selector와 Pod Label이 일치하는지 확인합니다. 이후 Endpoint를 통해 Service와 Pod가 실제 연결되었는지 검증합니다. 내부 구성이 정상이라면 NodePort와 Ingress를 테스트하고 마지막으로 HAProxy의 Backend와 로그를 확인합니다. 이런 방식으로 정상 구간과 장애 구간의 경계를 좁혀 원인을 찾습니다.

---

# 🧠 Sunday 초압축 암기

```text
Pod
 ↓
Deploy
 ↓
Service
 ↓
Endpoint ⭐
 ↓
NodePort
 ↓
Ingress
 ↓
HAProxy
 ↓
Client
```

그리고:

```text
Check
 ↓
Isolate
 ↓
Fix
 ↓
Verify
```

---

# ☠️ 최종 문제

다음 상황을 보자.

```text
Pod          Running
Deployment   2/2
Service      존재
Endpoint     <none>
NodePort     접속 실패
HAProxy      DOWN
```

### 어디부터 봐야 할까?

**HAProxy가 아니다.**

```text
Endpoint <none>
      ↑
여기가 최초 이상 지점
```

따라서 우선 확인:

```bash
kubectl get pods -n kaist --show-labels
kubectl describe svc kaist-service -n kaist
```

그리고:

```text
Service Selector ↔ Pod Label
```

일치 여부를 확인한다.

🔥 **이걸 바로 떠올릴 수 있다면 이번 프로젝트 트러블슈팅 흐름은 제대로 이해한 것이다.**

---

# 😎 이번 주 한 줄 결론

> **좋은 엔지니어는 에러가 없는 사람이 아니라, 에러가 발생했을 때 어디부터 확인해야 하는지 아는 사람이다.**

```text
"웹이 안 됩니다!"

초보:
😱 YAML부터 수정

엔지니어:
😏 kubectl get pods -n kaist -o wide
```