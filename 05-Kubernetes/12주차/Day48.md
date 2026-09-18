# Kubernetes 핵심 정리 --- ConfigMap · Secret · MongoDB · Storage

> **2026-09-18 핵심 흐름**\
> `ConfigMap / Secret → Pod 환경변수 → MongoDB + Mongo Express → Service → Volume → PV/PVC`

## 1. ConfigMap

ConfigMap은 애플리케이션의 **민감하지 않은 설정값을 컨테이너 이미지와
분리**하여 관리하는 Kubernetes 리소스이다.

``` bash
kubectl create configmap test-config \
  --from-literal=INTERVAL=2 \
  --from-literal=OPTION=dog

kubectl get cm
kubectl describe cm test-config
kubectl edit cm test-config
kubectl delete cm test-config
```

YAML 기본형:

``` yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: test-config
data:
  INTERVAL: "2"
  OPTION: dog
```

YAML 초안을 만들 때는 다음 방식이 편리하다.

``` bash
kubectl create cm test-config \
  --from-literal=INTERVAL=2 \
  --dry-run=client -o yaml
```

특정 key 하나를 환경변수로 가져올 때:

``` yaml
env:
- name: INTERVAL
  valueFrom:
    configMapKeyRef:
      name: test-config
      key: INTERVAL
```

ConfigMap 전체를 환경변수로 가져올 때:

``` yaml
envFrom:
- configMapRef:
    name: test-config
```

------------------------------------------------------------------------

## 2. ConfigMap + 멀티 컨테이너 + emptyDir

오늘 `smlinux/genid:env` 이미지에서는 `INTERVAL`, `OPTION` 환경변수를
사용해 `/webdata/index.html`을 반복 생성했다.

``` text
ConfigMap
INTERVAL / OPTION
       │
       ▼
  genid 컨테이너
  /webdata (RW)
       │
       ▼
  emptyDir: html
       │
       ▼
 nginx 컨테이너
 /usr/share/nginx/html (RO)
```

같은 Pod의 두 컨테이너가 `emptyDir`를 공유하므로 genid가 만든 HTML을
nginx가 서비스할 수 있다.

------------------------------------------------------------------------

## 3. Secret과 Base64

Secret은 비밀번호·인증정보 등 민감한 설정을 애플리케이션과 분리하는 데
사용한다.

``` bash
echo -n cisco | base64
# Y2lzY28=

echo -n Y2lzY28= | base64 -d
# cisco
```

> **중요:** Base64는 암호화가 아니라 **인코딩**이다.

`cisco`의 소문자 ASCII:

``` text
c        i        s        c        o
01100011 01101001 01110011 01100011 01101111
```

6bit 단위로 나누면:

``` text
011000 110110 100101 110011 011000 110110 111100
  24     54     37     51     24     54     60
   Y      2      l      z      Y      2      8

→ Y2lzY28=
```

`01000011`은 소문자 `c`가 아니라 대문자 `C`이므로 주의한다.

CLI 생성:

``` bash
kubectl create secret generic test-secret \
  --from-literal=INTERVAL=2 \
  --from-literal=OPTION=dog

kubectl get secrets
kubectl describe secret test-secret
```

일반 범용 Secret의 대표 타입은 `Opaque`이다.

------------------------------------------------------------------------

## 4. Secret YAML --- data와 stringData

`data:`에는 **Base64 인코딩 값**을 넣는다.

``` yaml
apiVersion: v1
kind: Secret
metadata:
  name: mongodb-secret
type: Opaque
data:
  USERNAME: ZGJhZG1pbg==
  PASSWORD: YWJjZDEyMzQ=
```

``` text
ZGJhZG1pbg== → dbadmin
YWJjZDEyMzQ= → abcd1234
```

평문으로 작성하고 싶다면 `stringData:`를 사용할 수 있다.

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

따라서 아래 형태는 잘못 기억하면 안 된다.

``` yaml
# ❌ data에 평문 직접 입력
data:
  project.id: webserver-1234
  project.user: webadmin
  project.pass: abcd1234
```

기억:

``` text
data       → Base64
stringData → 평문 입력 가능
```

------------------------------------------------------------------------

# 5. MongoDB + Mongo Express

## MongoDB Secret

``` yaml
apiVersion: v1
kind: Secret
metadata:
  name: mongodb-secret
type: Opaque
data:
  USERNAME: ZGJhZG1pbg==
  PASSWORD: YWJjZDEyMzQ=
```

MongoDB Deployment:

``` yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongodb
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongodb
  template:
    metadata:
      labels:
        app: mongodb
    spec:
      containers:
      - image: mongo
        name: mongodb
        ports:
        - containerPort: 27017
        env:
        - name: MONGO_INITDB_ROOT_USERNAME
          valueFrom:
            secretKeyRef:
              name: mongodb-secret
              key: USERNAME
        - name: MONGO_INITDB_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mongodb-secret
              key: PASSWORD
```

연결 구조:

``` text
mongodb-secret.USERNAME
        ↓ secretKeyRef
MONGO_INITDB_ROOT_USERNAME

mongodb-secret.PASSWORD
        ↓ secretKeyRef
MONGO_INITDB_ROOT_PASSWORD
```

## MongoDB Service

``` yaml
apiVersion: v1
kind: Service
metadata:
  name: mongodb-service
spec:
  selector:
    app: mongodb
  ports:
  - port: 27017
    protocol: TCP
    targetPort: 27017
  type: ClusterIP
```

Pod label과 Service selector가 일치해야 한다.

``` text
Pod:     app=mongodb
            ⇅
Service: app=mongodb
```

실습에서는 `mongodb-service`가 MongoDB Pod의 `27017` Endpoint를
정상적으로 잡았다.

------------------------------------------------------------------------

# 6. Mongo Express ConfigMap

``` yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mongodb-express-config
data:
  DB_URL: mongodb-service
```

Mongo Express가 변할 수 있는 MongoDB Pod IP 대신 **Service 이름**을
사용하도록 한다.

``` text
Mongo Express
     │
     │ mongodb-service:27017
     ▼
ClusterIP Service
     │
     ▼
MongoDB Pod
```

------------------------------------------------------------------------

# 7. Mongo Express Deployment --- 오류 교정 ☠️

Mongo Express 환경변수:

``` text
ME_CONFIG_MONGODB_ADMINUSERNAME
ME_CONFIG_MONGODB_ADMINPASSWORD
ME_CONFIG_MONGODB_SERVER
```

오늘 작성한 YAML에서 가장 중요한 오류:

``` yaml
# ❌ 특정 ConfigMap key 참조에는 없는 필드
valueFrom:
  configMapRef:
```

올바른 필드:

``` yaml
# ✅
valueFrom:
  configMapKeyRef:
```

교정본:

``` yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongo-express
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongo-express
  template:
    metadata:
      labels:
        app: mongo-express
    spec:
      containers:
      - image: mongo-express
        name: mongo-express
        ports:
        - containerPort: 8081
        env:
        - name: ME_CONFIG_MONGODB_ADMINUSERNAME
          valueFrom:
            secretKeyRef:
              name: mongodb-secret
              key: USERNAME
        - name: ME_CONFIG_MONGODB_ADMINPASSWORD
          valueFrom:
            secretKeyRef:
              name: mongodb-secret
              key: PASSWORD
        - name: ME_CONFIG_MONGODB_SERVER
          valueFrom:
            configMapKeyRef:
              name: mongodb-express-config
              key: DB_URL
```

필드 이름 암기:

``` text
Secret 특정 key    → secretKeyRef
ConfigMap 특정 key → configMapKeyRef
Secret 전체        → envFrom.secretRef
ConfigMap 전체     → envFrom.configMapRef
```

### Secret 이름도 확인

별도로 다음 Secret을 만들었다면:

``` yaml
metadata:
  name: mongodb-express
```

Deployment에서 이것을 사용할 의도라면 `secretKeyRef.name`도
`mongodb-express`여야 한다.

다만 MongoDB와 Mongo Express가 같은 관리자 인증정보를 공유한다면 둘 다
`mongodb-secret`을 참조하는 구성도 가능하다. **중요한 것은 생성한
Secret과 참조 대상의 의도를 맞추는 것**이다.

------------------------------------------------------------------------

# 8. Mongo Express Service

``` yaml
apiVersion: v1
kind: Service
metadata:
  name: mongodb-express-service
spec:
  selector:
    app: mongo-express
  ports:
  - port: 8081
    protocol: TCP
    targetPort: 8081
    nodePort: 31000
  type: LoadBalancer
```

실습에서는:

``` text
mongodb-express-service
LoadBalancer
8081:31000/TCP
EXTERNAL-IP: <pending>
```

형태를 확인했다.

별도의 LoadBalancer 구현이 없는 온프레미스 환경에서는 `EXTERNAL-IP`가
`<pending>`으로 남을 수 있다.

또 `31000`이 이미 사용 중이면:

``` text
provided port is already allocated
```

오류가 발생한다.

------------------------------------------------------------------------

# 9. project ConfigMap

``` yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: project
data:
  project.date: "2023-01-05"
  project.id: "webserver-1234"
  project.user: "kimdocker"
```

확인:

``` bash
kubectl create -f configmap.yml
kubectl get cm
kubectl describe cm project
```

------------------------------------------------------------------------

# 10. Storage 개요

오늘 다룬 핵심:

``` text
hostPath
emptyDir
NFS
PV / PVC
```

  종류         핵심
  ------------ ---------------------------------------------------
  `hostPath`   특정 Node의 로컬 경로 사용
  `emptyDir`   Pod 생명주기 동안 사용하는 임시 공유 공간
  `NFS`        외부 NFS 서버의 네트워크 공유 저장소
  `PV/PVC`     저장소를 Kubernetes 리소스로 추상화하여 제공/요청

------------------------------------------------------------------------

# 11. hostPath

``` yaml
apiVersion: v1
kind: Pod
metadata:
  name: hostpath-pod
spec:
  volumes:
  - name: html
    hostPath:
      path: /web
  containers:
  - image: nginx
    name: nginx-container
    ports:
    - containerPort: 80
    volumeMounts:
    - name: html
      mountPath: /usr/share/nginx/html/
```

구조:

``` text
Pod가 실행되는 Node
/web
 │
 │ hostPath
 ▼
nginx-container
/usr/share/nginx/html/
```

특정 Node의 파일에 의존한다는 점이 핵심이다. Pod가 다른 Node에 배치되면
그 Node의 `/web`을 보게 된다.

------------------------------------------------------------------------

# 12. emptyDir

``` yaml
apiVersion: v1
kind: Pod
metadata:
  name: emptydir-pod
spec:
  volumes:
  - name: html
    emptyDir: {}

  containers:
  - image: smlinux/genid:env
    name: genid
    volumeMounts:
    - name: html
      mountPath: /webdata

  - image: nginx
    name: nginx-container
    ports:
    - containerPort: 80
    volumeMounts:
    - name: html
      mountPath: /usr/share/nginx/html/
      readOnly: true
```

``` text
genid:/webdata (RW)
        │
        ▼
    emptyDir(html)
        │
        ▼
nginx:/usr/share/nginx/html (RO)
```

`emptyDir`는 **컨테이너 생명주기가 아니라 Pod 생명주기**에 연결된다.
Pod가 삭제되면 데이터도 사라진다.

------------------------------------------------------------------------

# 13. NFS

``` yaml
apiVersion: v1
kind: Pod
metadata:
  name: nfs-pod
  labels:
    app: mainui
spec:
  volumes:
  - name: html
    nfs:
      server: 192.168.2.80
      path: /test/vol
  containers:
  - image: nginx
    name: nginx-container
    ports:
    - containerPort: 80
    volumeMounts:
    - name: html
      mountPath: /usr/share/nginx/html/
      readOnly: true
```

구조:

``` text
NFS Server
192.168.2.80:/test/vol
          │
          ▼
      Kubernetes Pod
          │
          ▼
/usr/share/nginx/html
```

`hostPath`와 달리 저장 데이터가 특정 Kubernetes Node의 로컬 경로에
묶이지 않는다는 점이 중요하다.

------------------------------------------------------------------------

# 14. nginx Service --- 오류 교정 ☠️

다음처럼 `kind: Pod`에 Service용 필드를 넣으면 잘못된 YAML이다.

``` yaml
# ❌
kind: Pod
spec:
  ports:
  - nodePort: 31000
    port: 80
    targetPort: 80
  selector:
    app: nginx-svc
  type: NodePort
```

올바른 리소스:

``` yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-svc
spec:
  selector:
    app: mainui
  ports:
  - name: 80-80
    nodePort: 31000
    port: 80
    protocol: TCP
    targetPort: 80
  type: NodePort
```

그리고 Pod에도 일치하는 label이 있어야 한다.

``` yaml
metadata:
  labels:
    app: mainui
```

``` text
Pod label:        app=mainui
                      ⇅
Service selector: app=mainui
```

`status:`는 Kubernetes가 관리하는 상태 정보이므로 일반적인 선언용
YAML에서는 직접 작성하지 않는다.

------------------------------------------------------------------------

# 15. PV / PVC

PV:

``` text
PersistentVolume
= 클러스터에 제공되는 저장공간
```

PVC:

``` text
PersistentVolumeClaim
= 필요한 저장공간에 대한 요청
```

관계:

``` text
실제 Storage
     │
     ▼
    PV
     │
   Bound
     │
     ▼
    PVC
     │
     ▼
    Pod
```

오늘 실습 결과:

``` text
PV
Name:           pv
Capacity:       4Gi
Access Modes:   RWX
Reclaim Policy: Retain
Status:         Bound
Claim:          default/pvc
StorageClass:   manual
```

``` text
PVC
Name:         pvc
Status:       Bound
Volume:       pv
Capacity:     4Gi
Access Modes: RWX
StorageClass: manual
```

`Bound` = PVC와 조건에 맞는 PV가 정상 연결된 상태.

``` text
RWO = ReadWriteOnce
ROX = ReadOnlyMany
RWX = ReadWriteMany
```

------------------------------------------------------------------------

# 16. PVC를 사용하는 nginx Pod

``` yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
spec:
  volumes:
  - name: html
    persistentVolumeClaim:
      claimName: pvc

  containers:
  - image: nginx
    name: nginx-container
    ports:
    - containerPort: 80
    volumeMounts:
    - name: html
      mountPath: /usr/share/nginx/html/
      readOnly: true
```

Pod는 실제 저장소의 NFS 서버 주소나 물리 경로를 직접 알 필요 없이
`pvc`를 요청한다.

``` text
nginx Pod
   │
claimName: pvc
   ▼
  PVC
   │ Bound
   ▼
   PV
   │
   ▼
실제 Storage
```

------------------------------------------------------------------------

# 17. 오늘의 트러블슈팅 ☠️

### Secret 이름 누락

``` bash
kubectl create secret generic \
  --from-literal=INTERVAL=2
```

``` text
exactly one NAME is required
```

수정:

``` bash
kubectl create secret generic test-secret \
  --from-literal=INTERVAL=2
```

### kubectl 누락

``` bash
create secret test-secret.yml
```

수정:

``` bash
kubectl create -f test-secret.yml
```

### 명령어 오타

``` text
api-sources → api-resources
dsecribe    → describe
```

### ConfigMap 특정 key 참조 오류

``` text
configMapRef    ❌
configMapKeyRef ✅
```

### NodePort 충돌

``` text
provided port is already allocated
```

→ 동일한 NodePort를 다른 Service가 이미 사용하는지 확인한다.

------------------------------------------------------------------------

# 18. YAML 오류 체크리스트

  -----------------------------------------------------------------------
  작성 내용               판정                    핵심
  ----------------------- ----------------------- -----------------------
  MongoDB `secretKeyRef`  ✅                      Secret 특정 key 참조

  MongoDB Service         ✅                      `app: mongodb` 일치
  selector                                        

  Mongo Express           ❌                      `configMapKeyRef`로
  `configMapRef`                                  수정

  Secret `data:`에 평문   ❌                      Base64 또는
                                                  `stringData:`

  `kind: Pod` + NodePort  ❌                      `kind: Service`
  Service 필드                                    

  Service의 `status:`     ⚠️                      선언 YAML에서는 제거
  직접 작성                                       

  별도 `mongodb-express`  ⚠️                      의도에 맞게 이름 통일
  Secret 생성 후 다른                             
  Secret 참조                                     

  hostPath Pod            ✅                      Node 종속성 기억

  emptyDir 멀티 컨테이너  ✅                      Pod 생명주기

  NFS Pod                 ✅                      외부 공유 저장소

  PVC 사용 Pod            ✅                      `claimName: pvc`
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# 19. 시험/면접 핵심 Q&A

**Q. ConfigMap과 Secret의 차이는?**\
ConfigMap은 일반 설정, Secret은 비밀번호·인증정보 같은 민감 설정을
애플리케이션과 분리할 때 사용한다.

**Q. Base64는 암호화인가?**\
아니다. 인코딩이다.

**Q. `Opaque`는?**\
일반적인 key/value 데이터를 저장하는 범용 Secret 타입이다.

**Q. `configMapKeyRef`와 `configMapRef` 차이는?**\
`configMapKeyRef`는 특정 key를 `valueFrom`으로 가져올 때,
`configMapRef`는 `envFrom`에서 ConfigMap 전체를 환경변수로 가져올 때
사용한다.

**Q. emptyDir 데이터는 언제 없어지는가?**\
Pod가 삭제될 때 사라진다.

**Q. hostPath의 핵심 단점은?**\
특정 Node의 로컬 경로에 종속된다.

**Q. PV와 PVC는?**\
PV는 제공되는 저장공간, PVC는 저장공간 사용 요청이다.

**Q. Bound는?**\
PVC가 조건에 맞는 PV와 연결된 상태이다.

**Q. Mongo Express가 MongoDB Pod IP 대신 Service 이름을 쓰는 이유는?**\
Pod가 재생성되어 IP가 바뀌더라도 Service라는 안정적인 접근점을 사용할 수
있기 때문이다.

------------------------------------------------------------------------

# 20. 오늘의 최종 그림 🔥

``` text
                       Kubernetes
                            │
          ┌─────────────────┴─────────────────┐
          │                                   │
       설정/인증                            Storage
          │                                   │
   ┌──────┴──────┐             ┌──────────────┼───────────┐
   │             │             │              │           │
ConfigMap      Secret       hostPath       emptyDir      NFS
일반 설정      민감 설정       Node 로컬      Pod 임시      공유 저장소
   │             │                                         │
   └──────┬──────┘                                         ▼
          │                                              PV/PVC
          ▼
     환경변수 주입
          │
    ┌─────┴────────┐
    ▼              ▼
 MongoDB       Mongo Express
    │              │
    └── Service ───┘
```

## 6줄 압축

``` text
1. ConfigMap = 일반 설정 분리
2. Secret = 민감 설정 분리, Base64 ≠ 암호화
3. secretKeyRef / configMapKeyRef = 특정 key를 환경변수로 주입
4. Service = Pod가 바뀌어도 사용할 수 있는 안정적인 네트워크 접근점
5. hostPath / emptyDir / NFS = Node 로컬 / Pod 임시 / 네트워크 공유
6. PV/PVC = 저장소 제공과 저장소 요청을 분리
```

> **오늘의 진짜 핵심**\
> YAML 필드를 외우는 것보다 **설정(ConfigMap), 인증(Secret),
> 네트워크(Service), 저장소(Volume/PV/PVC)를 Pod에 어떻게 연결하는가**를
> 이해하는 것이 핵심이다. 😎
