# Day Docker 종합 복습 — Dockerfile · Compose · DB · Private Registry

> 실습 환경: Docker1 `192.168.2.10`, Docker2 `192.168.2.20`  
> 핵심 흐름: **이미지 사용 → 이미지 직접 빌드 → 여러 컨테이너 Compose 구성 → DB 연동 → 사설 Registry 운영 → TLS/인증 적용**

---

## 1. 오늘의 전체 그림

```text
Dockerfile
   │
   ├─ FROM
   ├─ RUN
   ├─ COPY
   ├─ EXPOSE
   └─ CMD
   ↓
docker image build
   ↓
Custom Image
   ↓
docker container run
   ↓
Container
   ↓
────────────────────────────────────────
Docker Compose
   ↓
여러 Service + Network + Volume
   ↓
MongoDB ↔ Mongo Express
PostgreSQL ↔ Adminer
   ↓
────────────────────────────────────────
Private Registry
   ↓
tag → push → pull
   ↓
TLS 인증서 + CA 신뢰
   ↓
htpasswd 인증
```

오늘 실습의 핵심은 단순히 컨테이너를 **실행하는 단계**에서 벗어나,

1. 이미지를 직접 제작하고
2. 여러 컨테이너를 YAML로 관리하고
3. DB와 관리 UI를 연결하고
4. 이미지를 저장할 사설 Registry까지 구성하는 것

이다.

---

# 2. Dockerfile 핵심

## 2.1 Dockerfile이란?

Dockerfile은 **Docker 이미지를 어떻게 만들 것인지 정의하는 설계서**이다.

```text
Dockerfile
   ↓
docker image build
   ↓
Image
   ↓
docker container run
   ↓
Container
```

---

## 2.2 핵심 명령어

### FROM

베이스 이미지를 지정한다.

```dockerfile
FROM debian
```

또는

```dockerfile
FROM ubuntu
```

---

### RUN

이미지를 만드는 과정에서 명령어를 실행한다.

```dockerfile
RUN apt update && \
    apt install -y vim procps curl \
    iputils-ping bind9-dnsutils \
    iproute2 net-tools nginx
```

`RUN`은 **빌드 시점**에 실행된다.

---

### COPY

호스트의 Build Context 안에 있는 파일을 이미지 내부로 복사한다.

```dockerfile
COPY hyundai_index.html /var/www/html/index.html
```

또는 nginx 공식 이미지 구조를 사용할 경우:

```dockerfile
COPY hyundai_index.html /usr/share/nginx/html/index.html
```

> 실습 과정에서는 웹 루트 경로를 수정하며 재빌드한 흔적이 있으므로,  
> **사용하는 베이스 이미지의 실제 DocumentRoot를 반드시 확인**해야 한다.

---

### EXPOSE

컨테이너가 사용하는 포트 정보를 이미지에 기록한다.

```dockerfile
EXPOSE 80
```

중요:

```text
EXPOSE 80
≠
호스트 포트 개방
```

실제 호스트와 연결하려면 `-p`가 필요하다.

```bash
docker container run -p 8081:80 ...
```

```text
Host 8081 ─────▶ Container 80
```

---

### CMD

컨테이너가 시작될 때 실행할 기본 프로세스를 지정한다.

nginx:

```dockerfile
CMD ["nginx", "-g", "daemon off;"]
```

Apache:

```dockerfile
CMD ["apache2ctl", "-D", "FOREGROUND"]
```

Docker 컨테이너는 기본적으로 **PID 1 프로세스가 종료되면 컨테이너도 종료**되므로,
웹 서버를 foreground 상태로 유지하는 것이 중요하다.

---

# 3. Docker 이미지 빌드

예:

```bash
docker image build -t debian-nginx . -f Dockerfile1
```

구조:

```text
docker image build
    -t debian-nginx      ← 이미지 이름/태그
    .                    ← Build Context
    -f Dockerfile1       ← 사용할 Dockerfile
```

확인:

```bash
docker image ls
```

---

## 3.1 Build Context

명령의 `.`은 단순 장식이 아니다.

```bash
docker image build -t debian-nginx . -f Dockerfile1
                                  ↑
                           Build Context
```

Docker는 이 디렉토리를 기준으로 `COPY`, `ADD` 등에 필요한 파일을 가져간다.

예:

```text
/root/docker/
├── Dockerfile1
└── hyundai_index.html
```

이라면:

```dockerfile
COPY hyundai_index.html /usr/share/nginx/html/index.html
```

처럼 사용할 수 있다.

---

## 3.2 Docker Build Cache

동일한 Dockerfile로 다시 빌드했을 때:

```text
CACHED [2/3] RUN ...
CACHED [3/3] COPY ...
```

와 같이 캐시가 사용될 수 있다.

즉 Docker는 변경되지 않은 레이어를 다시 만들지 않고 재사용하여
빌드 속도를 줄인다.

---

# 4. Web 이미지 실습 구조

## 4.1 debian-nginx

```text
Image         : debian-nginx
Container     : myweb1
Host Port     : 8081
Container Port: 80
HTML          : hyundai_index.html
```

실행:

```bash
docker container run -itd \
  --name myweb1 \
  -p 8081:80 \
  debian-nginx:latest
```

접속:

```text
http://192.168.2.10:8081
```

---

## 4.2 debian-httpd

```text
Image         : debian-httpd
Container     : myweb2
Port          : 8082:80
HTML          : lotte_index.html
Process       : apache2ctl -D FOREGROUND
```

---

## 4.3 ubuntu-nginx

```text
Image         : ubuntu-nginx
Container     : myweb3
Port          : 8083:80
HTML          : hana_index.html
```

---

## 4.4 ubuntu-httpd

```text
Image         : ubuntu-httpd
Container     : myweb4
Port          : 8084:80
HTML          : upbit_index.html
```

---

# 5. Docker Compose

## 5.1 Compose란?

여러 개의 `docker run` 명령을 YAML 파일 하나로 선언하고 관리하는 기능이다.

기존:

```bash
docker container run ...
docker container run ...
docker container run ...
docker container run ...
```

Compose:

```bash
docker compose up -d
```

한 번으로 여러 서비스를 실행한다.

---

## 5.2 docker run ↔ Compose 대응

| docker run | docker-compose.yml |
|---|---|
| 이미지명 | `image:` |
| `--name` | `container_name:` |
| `-p` | `ports:` |
| `-v` | `volumes:` |
| `-e` | `environment:` |
| `--restart` | `restart:` |
| 네트워크 | `networks:` 또는 Compose 기본 네트워크 |
| 컨테이너 의존 관계 | `depends_on:` |

---

## 5.3 YAML 주의사항

Compose 파일은 YAML이므로 **들여쓰기**가 매우 중요하다.

정상:

```yaml
services:
  webserver:
    image: nginx
    ports:
      - "8081:80"
```

주의:

- Tab 대신 Space 사용
- 보통 2칸 들여쓰기
- 같은 계층은 같은 들여쓰기
- `:` 뒤 공백
- 리스트는 `-`

문법 확인:

```bash
docker compose config
```

실습에서는 YAML 파싱 오류도 발생했다.

```text
go-yaml load error ...
did not find expected key
```

이 경우 가장 먼저 **들여쓰기와 key 구조**를 확인한다.

---

# 6. Compose 기본 명령어

실행:

```bash
docker compose up -d
```

상태 확인:

```bash
docker compose ps -a
```

중지:

```bash
docker compose stop
```

특정 서비스 중지:

```bash
docker compose stop server_a
```

삭제:

```bash
docker compose down
```

볼륨까지 삭제:

```bash
docker compose down -v
```

> `-v`는 DB 데이터가 들어 있는 볼륨까지 제거할 수 있으므로 주의한다.

---

# 7. Compose의 기본 Network

Compose 프로젝트를 실행하면 별도 지정이 없어도 기본 Bridge Network가 자동 생성된다.

예:

```text
testdb_default
10_compose_default
test_default
```

같은 Compose Network 안의 서비스는 **서비스명/컨테이너명으로 서로 접근**할 수 있다.

```text
mongoexpress
      │
      └──── mongo:27017
```

IP를 직접 하드코딩하지 않아도 Docker DNS가 이름을 해석한다.

---

# 8. MongoDB + Mongo Express

## 8.1 MongoDB 주요 환경변수

```text
MONGO_INITDB_ROOT_USERNAME
MONGO_INITDB_ROOT_PASSWORD
```

실습 예:

```bash
docker container run -d \
  --name mongo \
  --restart=always \
  --network=mynet \
  -e MONGO_INITDB_ROOT_USERNAME=root \
  -e MONGO_INITDB_ROOT_PASSWORD=example \
  mongo
```

---

## 8.2 Mongo Express 환경변수

```text
ME_CONFIG_MONGODB_ADMINUSERNAME
ME_CONFIG_MONGODB_ADMINPASSWORD
ME_CONFIG_MONGODB_URL
```

실습:

```bash
docker container run -d \
  --name mongoexpress \
  --restart=always \
  --network=mynet \
  -p 8081:8081 \
  -e ME_CONFIG_MONGODB_ADMINUSERNAME=root \
  -e ME_CONFIG_MONGODB_ADMINPASSWORD=example \
  -e ME_CONFIG_MONGODB_URL="mongodb://root:example@mongo:27017/" \
  mongo-express
```

핵심:

```text
mongo:27017
  ↑
Docker DNS가 컨테이너 이름 mongo를 찾아준다.
```

---

## 8.3 Mongo Compose 핵심 구조

```yaml
services:
  mongo:
    image: mongo
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: example

  mongoexpress:
    image: mongo-express
    ports:
      - "8081:8081"
    environment:
      ME_CONFIG_MONGODB_ADMINUSERNAME: root
      ME_CONFIG_MONGODB_ADMINPASSWORD: example
      ME_CONFIG_MONGODB_URL: mongodb://root:example@mongo:27017/
```

---

# 9. PostgreSQL + Adminer

## 9.1 PostgreSQL

실습에서 사용한 핵심 환경변수:

```text
POSTGRES_PASSWORD
```

실습:

```bash
docker container run -itd \
  --name mydb \
  --restart=always \
  --network=mynet \
  -e POSTGRES_PASSWORD=example \
  postgres
```

PostgreSQL 기본 포트:

```text
5432/tcp
```

---

## 9.2 Adminer

```bash
docker container run -d \
  --name myadminer \
  --restart=always \
  --network=mynet \
  -p 8080:8080 \
  adminer
```

Adminer 기본 웹 포트:

```text
8080/tcp
```

---

# 10. 오늘의 대표 트러블슈팅 — Port Already Allocated 💀

오류:

```text
Bind for 0.0.0.0:8080 failed:
port is already allocated
```

원인:

기존 `myadminer` 컨테이너가 이미:

```text
0.0.0.0:8080->8080/tcp
```

으로 호스트 8080 포트를 사용 중인 상태에서,
Compose가 또 다른 Adminer를 8080에 바인딩하려고 했기 때문이다.

구조:

```text
기존 Adminer
Host 8080 ─────▶ Container 8080
     ↑
     이미 사용 중

Compose Adminer
Host 8080 ─────▶ Container 8080
     ↑
     충돌 💀
```

확인:

```bash
docker ps
```

또는:

```bash
ss -lntp | grep ':8080'
```

해결 방법 1:

기존 컨테이너 제거/중지

```bash
docker stop myadminer
docker rm myadminer
docker compose up -d
```

해결 방법 2:

Compose의 호스트 포트 변경

```yaml
ports:
  - "8081:8080"
```

핵심:

```text
"8081:8080"
   ↑    ↑
 Host  Container
```

---

# 11. Bind Mount vs Named Volume

## Bind Mount

```yaml
volumes:
  - /www1:/usr/share/nginx/html
```

```text
Host Directory
/www1
   │
   ▼
Container Directory
/usr/share/nginx/html
```

호스트 경로를 직접 관리한다.

---

## Named Volume

```yaml
volumes:
  - mysqlvol:/var/lib/mysql
```

```text
Docker Volume
mysqlvol
   │
   ▼
Container
/var/lib/mysql
```

Docker가 실제 저장 위치를 관리한다.

---

## 주의할 점

실습 자료 안에서 DB 볼륨 이름이:

```text
mysqlvol
```

과

```text
mydbvol
```

로 다르게 표현된 부분이 있으므로 Compose 작성 시 **하나의 이름으로 통일**해야 한다.

---

# 12. Private Docker Registry

이제 Docker Hub가 아닌 **직접 운영하는 이미지 저장소**를 구성한다.

```text
Docker Client
    │
    ├── push
    ▼
Private Registry
    ▲
    ├── pull
    │
Docker Client
```

Docker2에서 Registry 서버 역할을 수행했다.

---

## 12.1 Registry 이미지

검색:

```bash
docker search registry
```

Pull:

```bash
docker image pull registry
```

Inspect 결과에서 확인할 수 있는 주요 정보:

```text
Exposed Port : 5000/tcp
Volume       : /var/lib/registry
Entrypoint   : /entrypoint.sh
```

---

## 12.2 Registry 실행

기본 예:

```bash
docker container run -itd \
  --name local-registry \
  -p 5000:5000 \
  registry
```

확인:

```bash
docker ps
netstat -ntlp
```

---

# 13. Image Tag → Push → Pull

## 13.1 Tag

기존 이미지:

```text
hello-world:latest
```

사설 Registry용 이름 추가:

```bash
docker image tag hello-world:latest localhost:5000/hello
```

또는:

```bash
docker image tag hello-world:latest myregistry.com/hello
```

중요:

`tag`는 이미지 내용을 복제하는 것이 아니라 **같은 이미지에 다른 이름을 붙이는 것**이다.

---

## 13.2 Push

```bash
docker image push localhost:5000/hello:latest
```

또는 TLS Registry:

```bash
docker image push myregistry.com/hello:latest
```

---

## 13.3 Pull 검증

로컬 이미지를 제거한 뒤:

```bash
docker image rm hello-world:latest localhost:5000/hello:latest
```

다시 Registry에서:

```bash
docker image pull localhost:5000/hello
```

Pull 후 컨테이너 실행:

```bash
docker container run --name test1 localhost:5000/hello
```

즉:

```text
Docker Hub
   ↓ pull
Local Image
   ↓ tag
Registry Name
   ↓ push
Private Registry
   ↓ local image 삭제
pull
   ↓
재다운로드 성공
```

이것이 Registry 동작 검증의 핵심이다.

---

# 14. Registry 데이터 저장 구조

Registry 내부:

```bash
docker container exec local-registry tree /var/lib/registry
```

대표 구조:

```text
/var/lib/registry
└── docker
    └── registry
        └── v2
            ├── blobs
            │   └── sha256
            └── repositories
```

핵심:

```text
blobs
→ 실제 이미지 레이어/콘텐츠 데이터

repositories
→ Repository / Tag / Manifest 관련 정보
```

---

# 15. DNS/Hosts를 이용한 Registry 이름 지정

Docker2:

```text
192.168.2.20
```

Registry 도메인:

```text
myregistry.com
```

`/etc/hosts`:

```text
192.168.2.20    myregistry.com
```

Docker1과 Docker2 모두 이름 해석이 가능해야 한다.

```text
myregistry.com
      │
      ▼
192.168.2.20
```

---

# 16. TLS 인증서 적용

HTTP Registry에서 한 단계 더 나아가 HTTPS Registry를 구성했다.

인증서 생성 예:

```bash
openssl req -newkey rsa:4096 \
  -nodes \
  -sha256 \
  -x509 \
  -days 365 \
  -out /auth/myregistry.com.crt \
  -keyout /auth/myregistry.com.key \
  -subj '/CN=myregistry.com' \
  -addext "subjectAltName = DNS:myregistry.com"
```

생성 파일:

```text
myregistry.com.crt
myregistry.com.key
```

---

## 16.1 Docker가 인증서를 신뢰하도록 설정

```bash
mkdir -p /etc/docker/certs.d/myregistry.com
cp myregistry.com.crt \
  /etc/docker/certs.d/myregistry.com/ca.crt
```

Docker1에도 CA 전달:

```bash
scp -r /etc/docker/certs.d 192.168.2.10:/etc/docker
```

구조:

```text
/etc/docker/certs.d/
└── myregistry.com/
    └── ca.crt
```

---

# 17. HTTPS Registry 실행

```bash
docker container run -d \
  -p 443:443 \
  --restart=always \
  --name local-registry \
  -v /auth:/certs \
  -v /root/upload-img-1:/var/lib/registry \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/myregistry.com.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/myregistry.com.key \
  -e REGISTRY_HTTP_ADDR=0.0.0.0:443 \
  registry
```

핵심 환경변수:

```text
REGISTRY_HTTP_TLS_CERTIFICATE
REGISTRY_HTTP_TLS_KEY
REGISTRY_HTTP_ADDR
```

확인:

```bash
docker container exec local-registry env
docker container exec local-registry netstat -ntlp
```

443 LISTEN 여부를 확인한다.

---

# 18. Registry 인증 — htpasswd

TLS는 **통신 암호화**이고,
htpasswd는 **사용자 인증**이다.

둘은 역할이 다르다.

```text
TLS
→ 데이터 암호화 + 서버 인증

htpasswd
→ 사용자 ID / Password 인증
```

---

## 18.1 계정 파일 생성

```bash
htpasswd -Bbn tester abcd1234 > htpasswd
```

또는 컨테이너 활용:

```bash
docker container run --rm \
  --entrypoint htpasswd \
  httpd \
  -Bbn tester abcd1234 > htpasswd
```

`-B`는 bcrypt 해시를 사용한다.

---

## 18.2 인증 Registry 실행

```bash
docker container run -d \
  -p 443:443 \
  --restart=always \
  --name local-registry \
  -v /auth:/certs \
  -v /root/upload-img-2:/var/lib/registry \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/myregistry.com.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/myregistry.com.key \
  -e REGISTRY_HTTP_ADDR=0.0.0.0:443 \
  -e REGISTRY_AUTH=htpasswd \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/certs/htpasswd \
  -e REGISTRY_AUTH_HTPASSWD_REALM="Please enter your Username and Password." \
  registry
```

핵심 환경변수:

```text
REGISTRY_AUTH=htpasswd
REGISTRY_AUTH_HTPASSWD_PATH
REGISTRY_AUTH_HTPASSWD_REALM
```

---

# 19. docker login

인증이 적용되면 push/pull 전에 로그인한다.

```bash
docker login myregistry.com
```

성공:

```text
Login Succeeded
```

로그인 정보는 실습 환경에서 다음 파일에 저장되는 것을 확인했다.

```text
/root/.docker/config.json
```

로그에도 다음 경고가 등장했다.

```text
credentials are stored unencrypted
```

즉 실무에서는 credential helper 등 별도의 자격증명 관리 방법을 고려해야 한다.

---

# 20. Registry 인증 오류

인증 없이 push:

```text
push access denied
authorization failed
no basic auth credentials
```

또는 잘못된 계정:

```text
401 Unauthorized
```

해결 순서:

```text
1. Registry 컨테이너 실행 상태
2. TLS 인증서 신뢰 여부
3. /etc/hosts 또는 DNS
4. htpasswd 사용자 존재 여부
5. docker login 성공 여부
6. tag 이름 확인
7. push/pull 재시도
```

---

# 21. Tag 이름 실수

실습 중:

```bash
docker container run myregistry.com/busy:hello
```

처럼 존재하지 않는 `hello` 태그를 요청하면:

```text
not found
```

가 발생한다.

현재 이미지가:

```text
myregistry.com/busy:latest
```

라면:

```bash
docker container run myregistry.com/busy:latest
```

또는:

```bash
docker container run myregistry.com/busy
```

처럼 사용한다.

핵심 구조:

```text
Registry / Repository : Tag
myregistry.com/busy:latest
```

---

# 22. 오늘 나온 대표 오타/오류 💀

## docker 오타

```text
dokcer
```

→

```bash
docker
```

---

## execd 오타

```bash
docker container execd ...
```

→

```bash
docker container exec ...
```

---

## --rm 옵션 오타

```bash
docker container run -rm ...
```

→

```bash
docker container run --rm ...
```

---

## Compose undefined service

오류:

```text
depends on undefined service "mydb"
```

`depends_on`에 적은 이름은 **container_name이 아니라 Compose service key**와 맞아야 한다.

예:

```yaml
services:
  webserver:
    depends_on:
      - database

  database:
    image: redis
```

---

# 23. 실습용 트러블슈팅 루틴

Docker 문제가 생기면 다음 순서로 보면 빠르다.

```bash
docker ps -a
docker image ls
docker network ls
docker volume ls
docker compose ps -a
docker compose logs
```

포트 문제:

```bash
ss -lntp
```

특정 포트:

```bash
ss -lntp | grep ':8080'
```

컨테이너 로그:

```bash
docker logs <container>
```

환경변수 확인:

```bash
docker container exec <container> env
```

컨테이너 내부 프로세스/포트:

```bash
docker container exec <container> ps -ef
docker container exec <container> netstat -ntlp
```

Compose 파일 검증:

```bash
docker compose config
```

---

# 24. Dockerfile vs Compose vs Registry

| 구분 | 역할 |
|---|---|
| Dockerfile | 이미지를 어떻게 만들지 정의 |
| Image | 컨테이너 생성 템플릿 |
| Container | 실제 실행 인스턴스 |
| Compose | 여러 컨테이너/네트워크/볼륨을 선언적으로 관리 |
| Volume | 영속 데이터 저장 |
| Network | 컨테이너 간 통신 |
| Registry | Docker 이미지 저장/배포 |
| TLS | Registry 통신 암호화 |
| htpasswd | Registry 사용자 인증 |

---

# 25. 시험/면접 핵심 질문

### Q1. Dockerfile과 Docker Compose의 차이는?

**Dockerfile은 이미지를 만드는 방법**,  
**Docker Compose는 여러 컨테이너를 실행/연결하는 방법**을 정의한다.

---

### Q2. EXPOSE 80을 하면 브라우저에서 바로 접속 가능한가?

아니다.

```dockerfile
EXPOSE 80
```

은 이미지의 포트 메타데이터 성격이며 실제 호스트 포트 연결은:

```bash
-p 8080:80
```

같은 port publishing이 필요하다.

---

### Q3. 왜 nginx를 daemon off로 실행하는가?

Docker 컨테이너의 주 프로세스(PID 1)가 종료되면 컨테이너도 종료되므로 nginx를 foreground로 유지하기 위해서다.

---

### Q4. Compose에서 같은 네트워크의 컨테이너는 어떻게 통신하는가?

Docker DNS를 통해 서비스명/컨테이너 이름으로 통신할 수 있다.

예:

```text
mongodb://root:example@mongo:27017/
```

---

### Q5. Bind Mount와 Named Volume 차이는?

**Bind Mount**

```text
호스트 경로를 직접 지정
```

**Named Volume**

```text
Docker가 저장 위치를 관리
```

---

### Q6. Registry에서 tag가 왜 필요한가?

Docker에게 해당 이미지가 **어느 Registry의 어느 Repository로 push될 것인지** 알려주기 위해 사용한다.

```bash
docker image tag busybox myregistry.com/busy
```

---

### Q7. TLS 인증서와 htpasswd의 차이는?

```text
TLS      → 통신 암호화 / 서버 신뢰
htpasswd → 사용자 인증
```

---

# 26. 오늘 반드시 기억할 명령어

```bash
# Dockerfile Build
docker image build -t IMAGE . -f Dockerfile

# Container
docker container run -d --name NAME -p HOST:CONTAINER IMAGE

# Compose
docker compose config
docker compose up -d
docker compose ps -a
docker compose down

# Registry
docker image tag SOURCE myregistry.com/REPOSITORY
docker image push myregistry.com/REPOSITORY
docker image pull myregistry.com/REPOSITORY

# Registry Login
docker login myregistry.com

# Troubleshooting
docker ps -a
docker logs CONTAINER
ss -lntp
docker container exec CONTAINER env
```

---

# 27. 한 장 압축 정리

```text
[Dockerfile]
이미지를 직접 제작
FROM → RUN → COPY → EXPOSE → CMD
           │
           ▼
      docker build
           │
           ▼
         Image
           │
           ▼
      docker run
           │
           ▼
       Container


[Docker Compose]
여러 Container를 YAML로 선언
           │
           ▼
 docker compose up -d
           │
    ┌──────┼──────┐
    ▼      ▼      ▼
   Web     DB    Admin UI
           │
      Docker Network
           │
     이름으로 통신


[Private Registry]
Local Image
    │
    ▼
   tag
    │
    ▼
myregistry.com/image
    │
    ▼
   push
    │
    ▼
Private Registry
    │
    ▼
   pull
    │
    ▼
다른 Docker Host

+ TLS
+ CA Trust
+ htpasswd
+ docker login
```

---

# 28. 오늘의 핵심 한 문장

> **Dockerfile은 이미지를 만든다. Compose는 여러 컨테이너를 구성한다. Registry는 이미지를 저장하고 배포한다.**

그리고 오늘 실습 흐름을 더 압축하면:

```text
Build → Run → Compose → Connect → Push → Pull → Secure
```

🐳 **이제 단순 Docker 사용자가 아니라, 이미지 제작·서비스 구성·사설 배포 구조까지 만져본 단계다.**
