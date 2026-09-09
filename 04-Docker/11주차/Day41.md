# Docker 핵심 복습 노트 — Network / Container / Volume / Portainer

> 2026-09-09 Docker 실습 핵심 정리  
> 목표: 명령어를 통째로 외우기보다 **Image → Container → Network / Port / Volume → 관리 도구**의 연결 구조를 이해한다.

---

## 0. 오늘 Docker 전체 그림

```text
                         Docker Image
                              │
                         docker run
                              ▼
                       Docker Container
                              │
          ┌───────────────────┼───────────────────┐
          │                   │                   │
       Network              Port                Volume
   컨테이너 간 통신      외부 접근 연결        데이터 보존
          │                   │                   │
   --network NAME        -p HOST:CONT       -v HOST:CONT
                                              또는
                                           -v VOL:CONT
                              │
                              ▼
                         Container 관리
                  attach / exec / top / stats
                   cp / logs / diff / rename
                              │
                              ▼
                           Portainer
                      Docker GUI 관리 도구
```

---

# 1. Docker 기본 네트워크 3가지

Docker 설치 후 기본적으로 다음 네트워크가 존재한다.

```bash
docker network ls
```

대표 결과:

```text
NETWORK ID    NAME      DRIVER
...           bridge    bridge
...           host      host
...           none      null
```

## 1-1. bridge

Docker의 기본 네트워크 방식.

```bash
docker container run --rm --network=bridge busybox ip address
docker container run --rm --network=bridge busybox ip route
```

예시 구조:

```text
Docker Host
192.168.2.10
    │
 docker0
172.17.0.1
    │
    └── Container
        172.17.0.2
```

컨테이너의 기본 게이트웨이는 Docker bridge의 주소가 된다.

```text
Container IP : 172.17.0.2
Gateway      : 172.17.0.1
```

호스트에서도 확인 가능하다.

```bash
ip address show docker0
```

### 핵심

> `bridge` = Docker가 만든 가상 네트워크에 컨테이너를 연결한다.

---

## 1-2. host

```bash
docker container run --rm --network=host busybox ip address
```

컨테이너가 별도의 Docker 네트워크 공간을 사용하지 않고 **호스트의 네트워크를 공유**한다.

```text
Host      : 192.168.2.10
Container : Host 네트워크 공유
```

### 핵심

> `host` = 컨테이너가 Host의 Network Namespace를 공유한다.

---

## 1-3. none

```bash
docker container run --rm --network=none busybox ip address
```

일반 네트워크 인터페이스가 없고 기본적으로 `lo`만 존재한다.

```text
Container
   │
   └── lo 127.0.0.1
```

### 핵심

> `none` = 네트워크 연결을 하지 않는다.

---

# 2. 사용자 정의 Bridge Network

## 생성

```bash
docker network create br0
```

driver를 명시하면:

```bash
docker network create -d bridge br0
```

확인:

```bash
docker network ls
docker network inspect br0
```

Docker가 자동으로 Subnet/Gateway를 할당할 수 있다.

예:

```text
Subnet  : 172.18.0.0/16
Gateway : 172.18.0.1
```

호스트에서는 실제 Linux bridge interface가 생성된다.

```bash
ip address
```

예:

```text
br-xxxxxxxxxxxx
    inet 172.18.0.1/16
```

### 핵심 구조

```text
Docker Host
      │
      ├── docker0          기본 bridge
      │   └── 172.17.0.0/16
      │
      └── br-xxxx          사용자 정의 bridge
          └── 172.18.0.0/16
```

---

# 3. Subnet / Gateway 직접 지정

```bash
docker network create \
  -d bridge \
  --subnet 192.168.100.0/24 \
  --gateway 192.168.100.254 \
  br1
```

확인:

```bash
docker network inspect br1
```

구조:

```text
br1
192.168.100.0/24
       │
       ├── Gateway : 192.168.100.254
       │
       ├── Container1
       └── Container2
```

Gateway는 반드시 지정한 subnet 안에 있어야 한다.

잘못된 예:

```text
Subnet  : 192.168.100.0/24
Gateway : 192.168.200.254   ← 다른 네트워크
```

→ 생성 실패.

---

# 4. Container를 특정 Network에 연결

```bash
docker container run -itd \
  --name myweb \
  --network br0 \
  centos:8
```

확인:

```bash
docker container inspect myweb
```

예:

```text
Network  : br0
Gateway  : 172.18.0.1
IPAddress: 172.18.0.2
```

컨테이너 안에서 확인:

```bash
docker container exec myweb ip address
docker container exec myweb ip route
```

### 네트워크 수업식으로 해석

```text
Container = PC/Server
Docker Network = 가상 Switch + IP Network
Container eth0 = NIC
Docker Bridge Gateway = Default Gateway
```

---

# 5. Network Connect / Disconnect

## 연결 해제

```bash
docker network disconnect br0 myweb
```

컨테이너가 해당 네트워크에서 분리된다.

```text
br0 ─────X──── myweb
```

네트워크가 전부 끊기면 컨테이너에서는 `lo`만 보일 수 있다.

## 다시 연결

```bash
docker network connect br1 myweb
```

```text
br1 ────────── myweb
```

### 가장 쉬운 비유

```text
docker network connect
= 가상 랜선 꽂기 🔌

docker network disconnect
= 가상 랜선 뽑기
```

---

# 6. 사용 중인 Network 삭제

```bash
docker network rm br1
```

컨테이너가 연결되어 있다면 다음과 같은 오류가 발생할 수 있다.

```text
network br1 has active endpoints
```

즉:

```text
br1
 │
 └── myweb   ← 사용 중
```

이 상태에서 네트워크를 없애려고 하기 때문이다.

먼저 컨테이너 연결을 제거하거나 컨테이너를 정리한 후 네트워크를 삭제한다.

---

# 7. 서로 다른 Docker Network 간 통신

실습:

```bash
docker network create --driver bridge testnet1
docker network create --driver bridge testnet2
```

컨테이너:

```bash
docker container run -itd \
  --name myweb1 \
  --network testnet1 \
  -p 8001:80 \
  centos:8

docker container run -itd \
  --name myweb2 \
  --network testnet2 \
  -p 8002:80 \
  centos:8
```

구조:

```text
[testnet1]
    │
  myweb1


[testnet2]
    │
  myweb2
```

`myweb2`에서 `myweb1`으로 ping:

```bash
docker container exec -it myweb2 /bin/bash

ping <myweb1-IP>
```

실습에서는 100% packet loss가 발생했다.

### 핵심

> 서로 다른 사용자 정의 Bridge Network에 속한 컨테이너는 기본적으로 직접 통신하지 않는다.

---

# 8. `-p`와 `--network` 구분

Docker 공부할 때 가장 많이 헷갈리는 부분.

## `-p`

```bash
-p 8080:80
```

```text
Host :8080
    │
    ▼
Container :80
```

> 외부/호스트 → 컨테이너 서비스 접근

## `--network`

```bash
--network testnet1
```

```text
Container
    │
Docker Network
    │
Other Container
```

> 컨테이너가 어떤 Docker Network에 연결될지 결정

### 초압축

```text
-p
= Host ↔ Container

--network
= Container ↔ Network ↔ Container
```

---

# 9. Docker Container 운용

nginx 컨테이너 생성:

```bash
docker container run -itd \
  --name testweb \
  -p 8080:80 \
  nginx
```

구조:

```text
nginx Image
     │
 docker run
     ▼
 testweb Container
     │
Host:8080 → Container:80
```

---

# 10. attach vs exec ⭐

## attach

```bash
docker container attach testweb
```

이미 실행 중인 **컨테이너의 메인 프로세스 입출력에 연결**한다.

```text
Container
   │
   └── PID 1 nginx
           ▲
           │
         attach
```

컨테이너를 종료하지 않고 빠져나오기:

```text
Ctrl + P
Ctrl + Q
```

---

## exec

```bash
docker container exec -it testweb /bin/bash
```

실행 중인 컨테이너에 **새로운 프로세스(Bash)** 를 실행한다.

```text
Container
  │
  ├── nginx (PID 1)
  │
  └── bash ← exec로 추가
```

Bash에서:

```bash
exit
```

해도 nginx는 계속 실행된다.

### 핵심 비교

| 명령어 | 의미 |
|---|---|
| `attach` | 기존 메인 프로세스에 연결 |
| `exec` | 컨테이너 안에서 새로운 명령/프로세스 실행 |

---

# 11. Container Process 확인

```bash
docker container top testweb
```

> 컨테이너 내부에서 실행 중인 프로세스를 Host에서 확인한다.

---

# 12. Container 자원 사용량 확인

```bash
docker container stats testweb
```

확인 가능:

```text
CPU %
Memory Usage
Memory %
Network I/O
Block I/O
PIDs
```

nginx에 브라우저 요청을 여러 번 보내면 Network I/O 등의 변화도 관찰할 수 있다.

---

# 13. Container 이름 변경

```bash
docker container rename testweb myweb
```

```text
testweb
   ↓
 myweb
```

---

# 14. Host ↔ Container 파일 복사

## Host → Container

```bash
docker container cp \
  docker/index.html \
  myweb:/usr/share/nginx/html/
```

```text
Host
docker/index.html
      │
      ▼
Container
/usr/share/nginx/html/index.html
```

## Container → Host

```bash
docker container cp \
  myweb:/etc/nginx/nginx.conf \
  docker/
```

확인:

```bash
ls -l docker/nginx.conf
```

### 핵심

```text
docker cp 출발지 목적지
```

컨테이너 경로:

```text
컨테이너이름:/경로
```

---

# 15. Container Log

```bash
docker container logs myweb
```

실시간:

```bash
docker container logs -f myweb
```

nginx의 경우 브라우저 접속 시 다음과 같은 HTTP 요청 로그를 확인할 수 있다.

```text
GET / HTTP/1.1
```

### 핵심

> `logs` = 컨테이너 프로그램이 stdout/stderr로 출력한 로그를 확인한다.

---

# 16. Image와 Container 변경사항 비교

```bash
docker container diff myweb
```

표시:

```text
A = Added
C = Changed
D = Deleted
```

예:

```bash
touch file1
mkdir dir1
rm -rf /etc/issue
useradd user1
```

이후:

```bash
docker container diff testos
```

예상 의미:

```text
A /file1
A /dir1
D /etc/issue
C /etc/passwd
C /etc/shadow
```

### 핵심

```text
Image
  │
  │ docker run
  ▼
Container
  │
  ├── 파일 추가
  ├── 파일 수정
  └── 파일 삭제
       │
       ▼
 docker diff
```

> Image는 원본이고 Container는 실행 중 변경될 수 있다.

---

# 17. Volume / Bind Mount

nginx 예:

```bash
docker container run -itd \
  --name myweb1 \
  -v /www1:/usr/share/nginx/html \
  -p 8081:80 \
  nginx
```

구조:

```text
HOST                            Container

/www1 ───────────────────────▶ /usr/share/nginx/html
                                     │
                                   nginx
                                     │
                                    :80
                                     │
Host :8081 ◀─────────────────────────┘
```

## `-v`

```text
-v HOST_PATH:CONTAINER_PATH
```

예:

```bash
-v /www1:/usr/share/nginx/html
```

### 핵심

> Container 내부의 데이터 영역과 Host를 연결한다.

---

# 18. `-v`와 `-p` 완전 분리

```text
-v
= 파일 / 데이터
= Storage 연결

-p
= TCP/UDP Port
= Network 서비스 연결
```

```text
-v /www1:/usr/share/nginx/html

HOST Directory
      ↕
Container Directory
```

```text
-p 8081:80

HOST Port
   ↓
Container Port
```

---

# 19. MySQL + WordPress Container

## MySQL

```bash
docker container run -d \
  --name mysql \
  -v /dbdata:/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD=wordpress \
  -e MYSQL_PASSWORD=wordpress \
  mysql:5.7
```

주요 옵션:

```text
-v = DB 데이터 저장 영역
-e = 환경변수 전달
```

구조:

```text
MySQL Container
      │
 /var/lib/mysql
      │
      ▼
HOST /dbdata
```

---

## WordPress

수업 예:

```bash
docker container run -d \
  --name wordpress \
  --link mysql \
  -e WORDPRESS_DB_USER=root \
  -e WORDPRESS_DB_PASSWORD=wordpress \
  -p 80:80 \
  wordpress:5
```

구조:

```text
Browser
   │
   ▼
WordPress Container
   │
   │ DB 연결
   ▼
MySQL Container
   │
   ▼
DB Data
```

### `--link`

수업에서는 WordPress → MySQL 연결 확인을 위해 사용했다.

```text
wordpress
    │
    └──── mysql
```

> 실습 로그에서도 default bridge의 `--link`는 deprecated 경고가 발생했다.  
> 현재 개념 학습에서는 “두 컨테이너를 연결한다”는 흐름을 이해하고, 이후에는 사용자 정의 Docker Network를 이용한 통신 개념으로 연결하면 된다.

---

# 20. Portainer 💀

Portainer는 Docker를 **웹 GUI에서 관리할 수 있게 해주는 도구**이다.

수업에서 실행한 형태:

```bash
docker container run -itd \
  --name portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  -p 9000:9000 \
  portainer/portainer-ce
```

확인:

```bash
docker container ls
```

접속:

```text
http://192.168.2.10:9000
```

## 옵션 해석

```text
--name portainer
= Container 이름

--restart=always
= Docker/Host 재시작 후에도 자동 재시작

-v /var/run/docker.sock:/var/run/docker.sock
= Portainer가 Host Docker Engine과 통신

-v portainer_data:/data
= Portainer 설정 데이터 보존

-p 9000:9000
= Host 9000 → Portainer 9000

portainer/portainer-ce
= Portainer Community Edition Image
```

### 가장 중요한 부분

```text
/var/run/docker.sock
```

구조:

```text
Web Browser
     │
     ▼
 Portainer Container
     │
     │ /var/run/docker.sock
     ▼
 Docker Engine
     │
 ┌───┼─────────────┐
 ▼   ▼             ▼
Containers       Images
Networks         Volumes
```

즉 Portainer는 Docker를 대신하는 것이 아니다.

> **Docker Engine을 GUI로 관리하는 Front-end 도구**라고 이해하면 된다.

Portainer 웹 화면에서 보게 되는 Container / Image / Network / Volume 메뉴는 지금까지 CLI로 실습했던 Docker 객체들을 GUI로 보여주는 것이다.

---

# 21. Portainer와 CLI 관계

예를 들어 CLI에서는:

```bash
docker container ls
docker image ls
docker network ls
docker volume ls
```

Portainer에서는 이것을 웹 화면에서 확인하고 관리한다.

```text
CLI                         GUI

docker container ls   ↔   Containers
docker image ls       ↔   Images
docker network ls     ↔   Networks
docker volume ls      ↔   Volumes
```

### 핵심

> Portainer를 새 기술 하나로 따로 외우지 말고 **“지금까지 배운 Docker CLI를 GUI로 본 것”**이라고 생각한다.

---

# 22. 오늘 배운 핵심 명령어 표

| 명령어 | 핵심 의미 |
|---|---|
| `docker network ls` | Network 목록 |
| `docker network inspect` | Network 상세 정보 |
| `docker network create` | Network 생성 |
| `docker network rm` | Network 삭제 |
| `docker network connect` | Container를 Network에 연결 |
| `docker network disconnect` | Network 연결 해제 |
| `docker container run` | Container 생성 + 실행 |
| `docker container ls -a` | Container 목록 |
| `docker container inspect` | 상세 정보 |
| `docker container attach` | 메인 프로세스 입출력 연결 |
| `docker container exec` | 실행 중 Container에서 명령 실행 |
| `docker container top` | 프로세스 확인 |
| `docker container stats` | 자원 사용량 실시간 확인 |
| `docker container rename` | 이름 변경 |
| `docker container cp` | Host ↔ Container 파일 복사 |
| `docker container logs` | 로그 확인 |
| `docker container diff` | Image 대비 파일 변경 확인 |
| `docker container stop` | Container 정지 |
| `docker container rm` | Container 삭제 |
| `docker volume ls` | Volume 목록 |
| `docker volume prune` | 미사용 Volume 정리 |
| `docker network prune` | 미사용 Custom Network 정리 |
| `docker system prune -a` | 미사용 Docker 리소스 대량 정리 |

> `prune`, `rm -f`, `system prune -a` 등 삭제 명령은 실습 환경에서도 사용 대상을 반드시 확인한다.

---

# 23. 시험/복습용 핵심 비교

## Image vs Container

```text
Image
= 원본 / Template

Container
= Image로 만든 실행 인스턴스
```

## attach vs exec

```text
attach
= 기존 메인 프로세스에 붙기

exec
= 새로운 프로세스 실행
```

## `-p` vs `-v`

```text
-p
= Port 연결
= Host ↔ Service

-v
= 데이터 연결
= Host/Volume ↔ Container Directory
```

## bridge vs host vs none

```text
bridge
= Docker 가상 Network 사용

host
= Host Network 공유

none
= Network 없음
```

## Network connect / disconnect

```text
connect
= 가상 랜선 꽂기

disconnect
= 가상 랜선 뽑기
```

## CLI vs Portainer

```text
Docker CLI
= 명령어 기반 Docker 관리

Portainer
= 웹 GUI 기반 Docker 관리

둘 다 같은 Docker Engine을 관리한다.
```

---

# 24. Docker를 한 문장으로 설명하면

> **Docker Image를 이용해 Container를 실행하고, Network로 통신시키며, Port Mapping으로 서비스를 외부에 공개하고, Volume으로 데이터를 보존하며, CLI 또는 Portainer 같은 도구로 이를 관리한다.**

---

# 25. 오늘 반드시 기억할 8문장 🔥

1. **Image는 Container를 만드는 원본이다.**
2. **Container는 Image에서 생성된 실행 인스턴스다.**
3. **Docker Network는 Container 간 통신을 담당한다.**
4. **`-p`는 Host Port와 Container Port를 연결한다.**
5. **`-v`는 데이터 저장 영역을 연결한다.**
6. **`exec`는 실행 중인 Container에서 추가 명령을 실행한다.**
7. **`diff`는 Image 대비 Container 파일 변경사항을 보여준다.**
8. **Portainer는 Docker Engine을 웹 GUI로 관리하는 도구다.**

---

# 26. 복습 우선순위

오늘 내용을 한 번에 다시 공부하지 말고 다음 순서로 쪼갠다.

```text
STEP 1
Image ↔ Container

        ↓

STEP 2
bridge / host / none

        ↓

STEP 3
-p / --network

        ↓

STEP 4
attach / exec / logs / diff

        ↓

STEP 5
-v / Volume

        ↓

STEP 6
WordPress ↔ MySQL

        ↓

STEP 7
Portainer로 같은 구조 다시 확인
```

---

# 27. 최종 마인드맵

```text
Docker
│
├── Image
│      │
│      └── docker run
│             │
│             ▼
│         Container
│
├── Container
│      ├── attach
│      ├── exec
│      ├── top
│      ├── stats
│      ├── cp
│      ├── logs
│      ├── diff
│      └── rename
│
├── Network
│      ├── bridge
│      ├── host
│      ├── none
│      ├── create
│      ├── connect
│      └── disconnect
│
├── Port
│      └── -p 8080:80
│
├── Storage
│      ├── Bind Mount
│      └── Volume
│
├── Multi Container
│      └── WordPress ↔ MySQL
│
└── Management
       ├── Docker CLI
       └── Portainer GUI
```

---

## 한 줄 결론

```text
Image → Container
           │
           ├── Network → 서로 통신
           ├── Port    → 외부에서 접근
           ├── Volume  → 데이터 보존
           └── Portainer/CLI → 관리
```

Docker는 결국 이 구조다. 😎