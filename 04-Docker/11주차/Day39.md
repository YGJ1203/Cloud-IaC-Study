# Day Docker 01 — Docker 기초, 이미지와 컨테이너 관리

> **실습 환경:** CentOS Stream 9 / Docker Engine Community 29.8.0  
> **실습 주제:** Docker 설치 → 구조 확인 → 이미지 검색/다운로드 → 컨테이너 실행 → 포트 매핑 → 이미지 관리/Inspect/Tag

---

## 1. Docker 핵심 개념

Docker는 애플리케이션과 실행에 필요한 환경을 **이미지(Image)** 로 묶고, 그 이미지를 기반으로 **컨테이너(Container)** 를 실행하는 플랫폼이다.

```text
Registry (Docker Hub / Quay.io)
          │
          │ pull
          ▼
       Image
          │
          │ run
          ▼
      Container
          │
          ├── 실행 중: Up
          └── 프로세스 종료: Exited
```

### Image와 Container

- **Image**: 컨테이너를 만들기 위한 읽기 전용 템플릿
- **Container**: 이미지를 기반으로 생성된 실제 실행 환경
- 하나의 이미지에서 여러 컨테이너를 생성할 수 있다.
- 컨테이너의 주 프로세스가 종료되면 일반적으로 컨테이너도 종료된다.

VM에 비유하면 이미지는 설치 이미지/템플릿, 컨테이너는 그 템플릿에서 생성되어 실행되는 인스턴스에 가깝다. 단, 컨테이너는 VM처럼 별도의 완전한 OS와 커널을 각각 부팅하는 구조가 아니다.

---

## 2. Docker 설치

실습에서는 Docker 공식 설치 스크립트를 다운로드하여 설치했다.

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
```

설치 과정에서 Docker CE 저장소가 추가되고 다음 구성요소들이 설치되었다.

```text
docker-ce
docker-ce-cli
containerd.io
docker-compose-plugin
docker-buildx-plugin
docker-ce-rootless-extras
...
```

Docker 서비스는 systemd를 통해 활성화 및 시작되었다.

```bash
systemctl status docker
```

실습 결과:

```text
Loaded: loaded
Active: active (running)
```

### Docker 버전 확인

```bash
docker version
```

실습 환경에서는 Client와 Server 모두 Docker Engine 29.8.0이 확인되었다.

---

## 3. Docker 시스템 정보 확인

```bash
docker system info
```

주요 확인 항목:

```text
Containers
Images
Storage Driver
Cgroup Driver
Kernel Version
Operating System
Architecture
Docker Root Dir
Firewall Backend
```

실습 환경의 주요 값:

```text
Operating System : CentOS Stream 9
Architecture     : x86_64
Cgroup Driver    : systemd
Cgroup Version   : 2
Docker Root Dir  : /var/lib/docker
Firewall Backend : iptables
```

Docker의 주요 데이터는 `/var/lib/docker` 아래에서 관리된다.

```bash
ls /var/lib/docker/
tree /var/lib/docker/
```

예:

```text
/var/lib/docker/
├── buildkit
├── containers
├── image
├── network
├── plugins
├── runtimes
├── swarm
├── tmp
└── volumes
```

Docker 디스크 사용량은 다음 명령으로 확인한다.

```bash
docker system df
```

---

## 4. Docker 명령어 구조

Docker CLI의 기본 구조:

```bash
docker [관리대상] [명령] [옵션]
```

예:

```bash
docker image ls
docker image pull nginx
docker container ls
docker container run nginx
```

자주 사용하는 관리 대상:

| 대상 | 의미 |
|---|---|
| `image` | Docker 이미지 관리 |
| `container` | 컨테이너 관리 |
| `network` | Docker 네트워크 관리 |
| `volume` | 볼륨 관리 |
| `system` | Docker 시스템 전체 관리 |

---

## 5. 이미지 검색 — `docker search`

Docker Hub에서 이미지를 검색한다.

```bash
docker search nginx
docker search ubuntu
docker search debian
docker search centos
```

검색 결과 수를 제한할 수도 있다.

```bash
docker search nginx --limit 4
docker search ubuntu --limit 3
docker search debian --limit 3
docker search centos --limit 3
```

### 실습 중 오타

```bash
docker search debain --limit 3
```

`debian`을 `debain`으로 잘못 입력하면 의도하지 않은 이미지들이 검색된다.

또한 다음은 잘못된 형태다.

```bash
docker search nginx | --limit 4
```

`--limit`은 별도 명령어가 아니라 `docker search`의 옵션이므로 다음처럼 작성한다.

```bash
docker search nginx --limit 4
```

### CentOS 검색 시 주의

실습에서 Docker Hub의 `centos` 검색 결과에는 다음과 같이 표시되었다.

```text
centos   DEPRECATED; The official build of CentOS.
```

따라서 최신 CentOS Stream 이미지는 기존 Docker Hub `centos` 저장소만 생각하지 말고 배포 위치와 태그를 확인해야 한다.

---

## 6. 이미지 다운로드 — `docker image pull`

### Ubuntu

```bash
docker image pull ubuntu
```

태그를 생략하면 기본적으로 `latest`가 사용된다.

```text
ubuntu:latest
```

### Debian

```bash
docker image pull debian
```

### Nginx

```bash
docker image pull nginx
```

### CentOS 8

```bash
docker image pull centos:8
```

실습에서 단순히 다음 명령을 실행했을 때:

```bash
docker image pull centos
```

`centos:latest`를 찾지 못해 실패했다.

```text
failed to resolve reference "docker.io/library/centos:latest"
... centos:latest: not found
```

하지만 명시적으로 `centos:8`을 지정하면 다운로드되었다.

### CentOS Stream 9

```bash
docker pull quay.io/centos/centos:stream9
```

CentOS Stream 9 실습에서는 Docker Hub가 아니라 **Quay.io의 CentOS 저장소**를 사용했다.

```text
quay.io/centos/centos:stream9
```

---

## 7. `docker pull` 명령의 인자

실습 중 다음 명령은 실패했다.

```bash
docker image pull ubuntu debian
```

출력:

```text
'docker image pull' requires 1 argument
```

즉, 이번 실습에서 사용한 `docker image pull` 형식은 한 번에 하나의 이미지 이름을 전달했다.

여러 이미지를 연속으로 받고 싶다면 예를 들어:

```bash
docker image pull ubuntu && docker image pull debian && docker image pull nginx
```

처럼 실행할 수 있다.

> `&&`는 앞 명령이 성공했을 때 다음 명령을 실행한다.

실습에서는 마지막 부분을 다음처럼 잘못 입력하기도 했다.

```bash
docker image nginx
```

올바른 명령:

```bash
docker image pull nginx
```

---

## 8. 이미지 목록 확인 — `docker image ls`

```bash
docker image ls
```

실습 후 다음 이미지들이 확인되었다.

```text
centos:8
debian:latest
nginx:latest
quay.io/centos/centos:stream9
ubuntu:latest
```

`-a` 옵션을 사용하면 모든 이미지를 표시한다.

```bash
docker image ls -a
```

---

## 9. 최초 컨테이너 실행 — hello-world

```bash
docker container run hello-world
```

로컬에 `hello-world:latest`가 없었기 때문에 Docker가 자동으로 이미지를 다운로드했다.

흐름:

```text
docker container run hello-world
        │
        ├─ 1. 로컬 이미지 검색
        │
        ├─ 2. 이미지가 없으면 Registry에서 Pull
        │
        ├─ 3. 이미지로 Container 생성
        │
        ├─ 4. /hello 실행
        │
        └─ 5. 프로그램 종료 → Container 종료
```

실행 후:

```bash
docker container ls
```

에는 보이지 않았지만,

```bash
docker container ls -a
```

에서는 다음처럼 종료된 컨테이너가 확인되었다.

```text
STATUS
Exited (0)
```

### `ls`와 `ls -a` 차이

```bash
docker container ls
```

현재 **실행 중인 컨테이너** 확인.

```bash
docker container ls -a
```

실행 중 + 종료된 컨테이너를 포함한 **전체 컨테이너** 확인.

---

## 10. Ubuntu 컨테이너와 프로세스 종료

```bash
docker container run ubuntu /bin/echo "Hello Docker Docker"
```

실행 결과:

```text
Hello Docker Docker
```

그 뒤 컨테이너는 `Exited (0)` 상태가 되었다.

왜냐하면 이 컨테이너의 실행 목적은 `/bin/echo` 프로세스를 실행하는 것이었고, 출력이 끝나면서 해당 프로세스도 종료되었기 때문이다.

```text
Container 시작
     │
     ▼
/bin/echo 실행
     │
     ▼
문자열 출력
     │
     ▼
echo 종료
     │
     ▼
Container 종료
```

### 핵심

> **컨테이너의 생명주기는 컨테이너의 주 실행 프로세스와 밀접하게 연결된다.**

---

## 11. Nginx 컨테이너 실행

```bash
docker container run -itd nginx
```

Nginx 컨테이너는 Ubuntu의 `echo` 실습과 달리 계속 `Up` 상태를 유지했다.

```bash
docker container ls -a
```

예:

```text
IMAGE   STATUS
nginx   Up ...
```

Nginx 서버 프로세스가 계속 실행되고 있기 때문이다.

### 옵션

```text
-i : 표준 입력을 열린 상태로 유지
-t : TTY 할당
-d : Detached mode, 백그라운드 실행
```

---

## 12. 컨테이너 이름과 포트 매핑

실습에서는 Nginx 컨테이너를 다음과 같이 실행했다.

```bash
docker container run -itd --name webserver -p 80:80 nginx
```

옵션 해석:

```text
--name webserver
└─ 컨테이너 이름을 webserver로 지정

-p 80:80
└─ Host 80번 포트 → Container 80번 포트
```

구조:

```text
Client
  │
  │ HTTP :80
  ▼
Docker Host :80
  │
  │ Port Mapping
  ▼
Nginx Container :80
```

실행 후 `docker container ls -a`에서는 다음과 같은 형태로 확인되었다.

```text
0.0.0.0:80->80/tcp
[::]:80->80/tcp
```

---

## 13. 컨테이너 삭제

실행 중인 컨테이너를 바로 삭제하려 하면 실패할 수 있다.

```bash
docker container rm <container>
```

실습 오류:

```text
cannot remove container:
container is running:
stop the container before removing or force remove
```

따라서 먼저 중지하고 삭제했다.

```bash
docker container stop <container>
docker container rm <container>
```

흐름:

```text
Running
   │
   │ docker container stop
   ▼
Stopped
   │
   │ docker container rm
   ▼
Removed
```

---

## 14. 이미지 삭제

```bash
docker image rm hello-world:latest nginx:latest ubuntu:latest
```

실습에서는 이미지가 삭제되면서 다음과 같은 메시지가 확인되었다.

```text
Untagged: ...
Deleted: sha256:...
```

삭제 후:

```bash
docker image ls
```

로 확인할 수 있다.

---

## 15. 동일 이미지 다시 Pull하기

Nginx 이미지를 다운로드한 뒤 다시 같은 명령을 실행했다.

```bash
docker image pull nginx
docker image pull nginx
```

두 번째 실행에서는:

```text
Status: Image is up to date for nginx:latest
```

가 출력되었다.

즉 로컬에 해당 최신 이미지가 이미 존재하면 매번 동일 데이터를 새로 받는 것이 아니라 현재 이미지 상태를 확인한다.

---

## 16. 이미지 상세 정보 — `docker image inspect`

```bash
docker image inspect ubuntu:latest
docker image inspect debian
docker image inspect centos:8
docker image inspect quay.io/centos/centos:stream9
docker image inspect nginx
```

`inspect`를 사용하면 이미지의 상세 메타데이터를 JSON 형식으로 확인할 수 있다.

주요 항목:

```text
Id
RepoTags
RepoDigests
Created
Config
Architecture
Os
Size
RootFS
Layers
```

### Ubuntu / Debian / CentOS

Ubuntu와 CentOS 계열 이미지에서는 기본 실행 명령으로 Bash가 설정된 것을 확인할 수 있었다.

예:

```json
"Cmd": [
    "/bin/bash"
]
```

Debian은:

```json
"Cmd": [
    "bash"
]
```

### Nginx

Nginx 이미지는 일반 OS 베이스 이미지보다 실행 설정이 구체적이다.

```text
ExposedPorts : 80/tcp
Entrypoint   : /docker-entrypoint.sh
Cmd          : nginx -g "daemon off;"
```

개념적으로:

```text
Container 시작
      │
      ▼
/docker-entrypoint.sh
      │
      ▼
nginx -g "daemon off;"
      │
      ▼
Nginx가 foreground에서 실행
      │
      ▼
Container가 Up 상태 유지
```

`daemon off;`는 Nginx가 백그라운드 daemon으로 빠져나가지 않고 컨테이너의 주 프로세스로 계속 실행되도록 하는 데 중요하다.

---

## 17. Image Layer

`docker image inspect`의 `RootFS`에서 이미지 Layer를 확인할 수 있다.

```json
"RootFS": {
    "Type": "layers",
    "Layers": [
        "sha256:..."
    ]
}
```

실습 이미지마다 Layer 개수가 달랐다.

예를 들어 Nginx 이미지에는 여러 개의 Layer가 표시되었고, CentOS/Ubuntu/Debian 베이스 이미지들은 서로 다른 Layer 구성을 가졌다.

핵심 개념:

```text
Image
├── Layer
├── Layer
├── Layer
└── ...
```

이미지는 하나의 거대한 파일이라기보다 여러 계층(Layer)이 쌓여 구성되는 방식으로 이해하면 좋다.

---

## 18. 이미지 태그 — `docker image tag`

Nginx 이미지에 새로운 이름과 버전 태그를 지정했다.

처음 시도:

```bash
docker image tag nginx:latest ray589/webserver:1/0
```

결과:

```text
invalid reference format
```

수정:

```bash
docker image tag nginx:latest ray589/webserver:1.0
```

### 이미지 이름 구조

```text
[REGISTRY/]NAMESPACE/REPOSITORY:TAG
```

예:

```text
ray589/webserver:1.0
│      │         │
│      │         └─ TAG
│      └─────────── REPOSITORY
└────────────────── NAMESPACE
```

`docker image tag`는 이미지 내용을 새로 복사하는 개념이라기보다 기존 이미지에 **추가적인 이름/참조를 붙이는 것**으로 이해하는 것이 좋다.

```text
nginx:latest ─────────────┐
                          ├── 동일 이미지
ray589/webserver:1.0 ─────┘
```

확인:

```bash
docker image ls
```

태그가 정상 생성되었다면 두 이름이 동일한 IMAGE ID를 가리키는 것을 확인할 수 있다.

---

## 19. 오늘의 트러블슈팅 모음

### ① `docker image pull ubuntu debian`

```text
원인:
docker image pull 명령에 이미지 이름을 두 개 전달

교정:
docker image pull ubuntu
docker image pull debian
```

또는:

```bash
docker image pull ubuntu && docker image pull debian
```

---

### ② `docker image nginx`

```text
원인:
image 뒤에 수행할 하위 명령이 없음

교정:
docker image pull nginx
```

---

### ③ `docker search nginx | --limit 4`

```text
원인:
--limit을 파이프 뒤의 독립 명령처럼 사용

교정:
docker search nginx --limit 4
```

---

### ④ `docker search debain`

```text
원인:
debian 철자 오류

교정:
docker search debian --limit 3
```

---

### ⑤ `docker image pull centos`

```text
현상:
centos:latest를 찾지 못함

실습에서 사용한 대안:
docker image pull centos:8
docker pull quay.io/centos/centos:stream9
```

CentOS Stream 9를 사용할 때는:

```bash
docker pull quay.io/centos/centos:stream9
```

---

### ⑥ 실행 중인 컨테이너 `rm`

```text
원인:
Running 상태의 컨테이너를 일반 rm으로 제거하려 함

교정:
docker container stop <name>
docker container rm <name>
```

---

### ⑦ `ray589/webserver:1/0`

```text
원인:
잘못된 이미지 reference/tag 형식

교정:
ray589/webserver:1.0
```

```bash
docker image tag nginx:latest ray589/webserver:1.0
```

---

## 20. 오늘 실습 전체 흐름

```text
CentOS Stream 9 Host
        │
        ▼
Docker CE 설치
        │
        ├── docker version
        ├── systemctl status docker
        └── docker system info
        │
        ▼
Docker 저장 구조 확인
        │
        ├── /var/lib/docker
        └── docker system df
        │
        ▼
Registry 이미지 검색
        │
        └── docker search
        │
        ▼
Image Pull
        │
        ├── hello-world
        ├── ubuntu
        ├── debian
        ├── nginx
        ├── centos:8
        └── quay.io/centos/centos:stream9
        │
        ▼
Container Run
        │
        ├── hello-world → 실행 후 Exited
        ├── ubuntu echo → 실행 후 Exited
        └── nginx       → Up
        │
        ▼
Nginx 포트 매핑
        │
        └── Host :80 → Container :80
        │
        ▼
Image 관리
        │
        ├── ls
        ├── inspect
        ├── rm
        └── tag
```

---

## 21. 핵심 명령어 치트시트

```bash
# Docker 상태/정보
docker version
docker system info
docker system df
systemctl status docker

# 이미지 검색
docker search nginx
docker search nginx --limit 4

# 이미지 다운로드
docker image pull ubuntu
docker image pull debian
docker image pull nginx
docker image pull centos:8
docker pull quay.io/centos/centos:stream9

# 이미지 확인
docker image ls
docker image ls -a

# 이미지 상세 정보
docker image inspect nginx
docker image inspect quay.io/centos/centos:stream9

# 이미지 태그
docker image tag nginx:latest ray589/webserver:1.0

# 컨테이너 실행
docker container run hello-world
docker container run ubuntu /bin/echo "Hello Docker Docker"
docker container run -itd nginx
docker container run -itd --name webserver -p 80:80 nginx

# 컨테이너 확인
docker container ls
docker container ls -a

# 컨테이너 중지/삭제
docker container stop <NAME>
docker container rm <NAME>

# 이미지 삭제
docker image rm <IMAGE>
```

---

## 22. 면접/복습 포인트

**Q. Docker Image와 Container의 차이는?**  
Image는 컨테이너 생성에 사용하는 템플릿이며, Container는 이미지를 기반으로 생성되어 실제 프로세스가 실행되는 인스턴스이다.

**Q. `docker container ls`와 `docker container ls -a`의 차이는?**  
`ls`는 실행 중인 컨테이너를, `ls -a`는 종료된 컨테이너까지 포함한 전체 컨테이너를 보여준다.

**Q. Ubuntu에서 echo만 실행한 컨테이너는 왜 바로 종료됐는가?**  
컨테이너에서 실행한 `/bin/echo` 프로세스가 작업을 마치고 종료되었기 때문이다.

**Q. Nginx 컨테이너는 왜 계속 실행되는가?**  
이미지 설정에 `nginx -g "daemon off;"`가 지정되어 Nginx가 foreground에서 계속 실행되기 때문이다.

**Q. `-p 80:80`은 무엇인가?**  
Docker Host의 TCP 80번 포트를 컨테이너의 80번 포트에 매핑한다.

**Q. `docker image inspect`는 무엇을 확인하는가?**  
이미지 ID, 태그, Digest, 환경변수, 기본 명령, 아키텍처, OS, Layer 등의 상세 메타데이터를 확인한다.

**Q. `docker image tag`는 이미지를 복사하는가?**  
새로운 이미지 데이터를 통째로 복사하기보다는 기존 이미지를 가리키는 새로운 이름/태그를 추가한다.

---

## 23. 한 줄 핵심 정리

> **Registry에서 Image를 Pull하고 → Image로 Container를 Run하며 → Container의 주 프로세스가 살아 있는 동안 Container도 실행된다.**

그리고 이미지 관리의 기본 흐름은 다음과 같다.

```text
search → pull → ls → inspect → tag → (push)
             │
             └── run → container
```

🐳 **Docker Day 01 핵심:**  
`Image ≠ Container`, `run = 이미지 기반 컨테이너 생성 + 실행`, 그리고 **컨테이너는 결국 프로세스를 격리하여 실행하는 환경**이라는 감각을 잡는 것이 가장 중요하다.
