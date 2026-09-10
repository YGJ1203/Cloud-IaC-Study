# Docker 자원관리 & 이미지 빌드 핵심정리
> 학습일: 2026-09-10  
> 환경: CentOS Stream 9 / Docker Engine / VMware / MobaXterm  
> 주제: **컨테이너 자원 제한 → 런타임 트러블슈팅 → 이미지 생성/백업 → Dockerfile → Multi-stage → CMD/ENTRYPOINT → ONBUILD → MySQL Volume**

---

## 0. 오늘의 전체 흐름

```text
Host 자원 확인
   ↓
Docker 자원 제한 옵션 확인
   ↓
CPU / Memory / Disk I/O 제한
   ↓
stress 실습 시도
   ↓
Disk I/O 100 B/s 사건 💀
   ↓
컨테이너 종료 / shim 상태 꼬임
   ↓
Docker / containerd 재시작도 지연
   ↓
VM reboot
   ↓
hello-world → nginx로 정상 복구 검증
   ↓
docker create / run
   ↓
docker commit
   ↓
export / import
   ↓
save / load
   ↓
Dockerfile 기반 이미지 빌드
   ↓
Image Layer / Build Context
   ↓
Single-stage / Multi-stage
   ↓
RUN Shell / Exec 형식
   ↓
CMD / ENTRYPOINT
   ↓
ONBUILD
   ↓
MySQL 환경변수 / 익명 Volume
```

오늘의 핵심 변화는 단순히 **"이미지를 받아서 컨테이너를 실행한다"**에서 끝나지 않고,

> **컨테이너를 제한하고, 이미지로 만들고, 저장하고, Dockerfile로 재현 가능한 이미지를 설계하는 단계**

로 넘어갔다는 점이다.

---

# 1. Docker 컨테이너 자원 관리

Docker 컨테이너는 기본적으로 호스트의 CPU, Memory, Block I/O 자원을 공유한다.

따라서 여러 컨테이너가 동시에 동작할 때 특정 컨테이너가 자원을 독점하지 못하도록 제한할 수 있다.

핵심 원리:

```text
Linux Kernel
 ├─ Namespace : 무엇을 볼 수 있는가? → 격리
 └─ cgroup    : 얼마나 쓸 수 있는가? → 자원 제한
```

## 1.1 호스트 자원 확인

```bash
free
lsmem
lscpu
lsblk
```

오늘 실습 환경에서는 대략 다음 자원을 확인했다.

```text
Memory : 약 3 GB
Swap   : 약 3 GB
CPU    : 4개 논리 CPU (0-3)
Disk   : /dev/sda 100 GB
```

자원 제한 실습 전에 호스트 자체의 자원을 먼저 확인해야 한다.

---

## 1.2 주요 Docker 자원 제한 옵션

```bash
docker container run --help
```

주요 옵션:

| 옵션 | 의미 |
|---|---|
| `--cpus` | 사용할 수 있는 CPU 양 제한 |
| `--cpuset-cpus` | 사용할 CPU 번호 지정 |
| `-c`, `--cpu-shares` | CPU 상대적 가중치 |
| `-m`, `--memory` | Memory 최대 사용량 |
| `--memory-swap` | Memory + Swap 총량 |
| `--device-read-bps` | 블록 장치 읽기 속도 제한 |
| `--device-write-bps` | 블록 장치 쓰기 속도 제한 |
| `--device-read-iops` | 읽기 IOPS 제한 |
| `--device-write-iops` | 쓰기 IOPS 제한 |

---

# 2. Memory 제한

예:

```bash
docker container run \
  -m 100m \
  --memory-swap 100m \
  IMAGE
```

의미:

```text
Memory 최대 = 100 MB
Memory + Swap 최대 = 100 MB
```

즉 추가 Swap을 사실상 허용하지 않는 구성이다.

반면:

```bash
-m 100m --memory-swap 200m
```

이라면 개념적으로:

```text
Memory : 최대 100 MB
Swap   : 추가 최대 약 100 MB
총량   : 최대 200 MB
```

### 핵심

`--memory-swap`은 **Swap만의 크기**가 아니라:

> **Memory + Swap의 총 허용량**

이다.

---

# 3. CPU 제한

## 3.1 CPU 개수에 해당하는 연산량 제한

```bash
docker run --cpus="1" IMAGE
```

컨테이너가 최대 약 CPU 1개 분량의 연산 자원을 사용하도록 제한한다.

호스트가 CPU 4개를 가지고 있어도 컨테이너가 마음대로 4개 분량을 다 사용할 수 없도록 한다.

---

## 3.2 CPU 번호 지정

호스트 CPU:

```text
CPU 0
CPU 1
CPU 2
CPU 3
```

예:

```bash
docker run --cpuset-cpus="0-1" IMAGE
```

컨테이너가 CPU 0, 1에서만 스케줄링되도록 제한한다.

주의할 오타:

```bash
--cpuset-cpust   # X
--cpuset-cpus    # O
```

---

# 4. stress 개념

`stress`는 시스템에 일부러 부하를 발생시키는 테스트 도구다.

Docker 자원 제한이 실제로 동작하는지 확인할 때 사용할 수 있다.

## 4.1 CPU 부하

```bash
stress -c 2
```

CPU worker 2개를 생성한다.

예:

```bash
stress -c 2 -t 5s
```

5초 동안 CPU worker 2개를 동작시킨다.

---

## 4.2 Memory 부하

```bash
stress --vm 1 --vm-bytes 90m -t 5s
```

의미:

```text
--vm 1
→ Memory worker 1개

--vm-bytes 90m
→ 약 90MB 메모리 사용

-t 5s
→ 5초 동안 실행
```

---

# 5. 매우 중요한 실패 사례: Host에 설치 ≠ Container에 설치

실습 중 Dockerfile은 다음과 비슷한 상태였다.

```dockerfile
FROM debian
RUN apt update && apt -y upgrade
CMD ["/bin/sh","-c","stress -c 2"]
```

하지만 Debian 이미지 내부에 `stress` 패키지를 설치하지 않았다.

호스트 CentOS에:

```bash
yum -y install stress
```

를 실행하더라도 컨테이너 내부에는 설치되지 않는다.

이유:

```text
Host OS
├─ /usr/bin/stress  ← 여기에 설치
│
└─ Container
   └─ 별도의 Root Filesystem
      └─ stress 없음
```

따라서:

```text
exec: "stress": executable file not found in $PATH
```

오류가 발생할 수 있다.

### 교정 Dockerfile 예

```dockerfile
FROM debian

RUN apt update \
    && apt install -y stress \
    && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["stress"]
```

빌드:

```bash
docker image build -t stressimg .
```

실행:

```bash
docker run --rm stressimg -c 2 -t 5s
```

Memory 제한 테스트:

```bash
time docker container run --rm \
  -m 100m \
  --memory-swap 100m \
  stressimg \
  --vm 1 \
  --vm-bytes 90m \
  -t 5s
```

---

# 6. IMAGE 뒤의 값은 컨테이너 명령어/인자다

형식:

```text
docker run [Docker 옵션] IMAGE [COMMAND] [ARG...]
```

예:

```bash
docker run -m 100m stressimg --vm 1
```

구분:

```text
-m 100m
└─ Docker 자체 옵션

stressimg
└─ 실행할 이미지

--vm 1
└─ 이미지에서 실행되는 프로그램에 전달될 명령/인자
```

Docker 옵션의 위치와 컨테이너 내부 명령의 위치를 혼동하지 않는 것이 중요하다.

---

# 7. Block I/O 제한

오늘 가장 강렬했던 실습 💀

## 7.1 정상적인 10MB/s 제한

```bash
docker container run --rm -it \
  --device-write-bps=/dev/sda:10mb \
  ubuntu /bin/bash
```

컨테이너 내부:

```bash
dd if=/dev/zero of=file1 bs=1M count=10 oflag=direct
```

약 10MiB 파일을 생성하면서 쓰기 속도를 약 10MB/s로 제한하였다.

실습에서는 실제로 약:

```text
11 MB/s
```

수준의 결과를 확인했다.

---

## 7.2 `100`의 공포 💀

문제의 명령:

```bash
--device-write-bps=/dev/sda:100
```

이것은:

```text
100 MB/s  X
100 B/s   O
```

이다.

10MiB 파일을 100 B/s로 쓰면 이론적으로:

```text
10,485,760 bytes ÷ 100 bytes/sec
≈ 104,858 sec
≈ 29.1 hours
```

즉 화면이 멈춘 것처럼 보여도 실제로는 **극단적으로 느리게 I/O가 진행되고 있었을 가능성이 높다.**

### 교훈

단위를 반드시 명시한다.

```bash
10kb
10mb
100mb
```

특히 실습 서버에서:

```bash
--device-write-bps=/dev/sda:100
```

같은 지나치게 작은 값은 피한다.

---

# 8. Docker Runtime 트러블슈팅

I/O 제한 실습 중 `dd`를 중단하고 컨테이너 종료를 시도한 뒤 다음 현상이 나타났다.

```text
docker stop → 멈춤
docker kill → exit event를 받지 못함
docker run → 멈춤
systemctl restart docker → 멈춤
systemctl restart containerd → 멈춤
```

확인 구조:

```text
docker CLI
    ↓
dockerd
    ↓
containerd
    ↓
containerd-shim-runc-v2
    ↓
runc
    ↓
Container Process
```

확인 명령:

```bash
systemctl status docker --no-pager
systemctl status containerd --no-pager

docker info

ps -ef | egrep 'dockerd|containerd|runc|containerd-shim'
```

오류:

```text
tried to kill container, but did not receive an exit event
```

정확한 저수준 원인은 journal을 더 분석해야 확정할 수 있지만, 이번 상황에서는 극단적인 I/O 제한 상태의 컨테이너를 중단하는 과정에서 runtime/shim 상태가 비정상적으로 남은 것으로 추정할 수 있었다.

실습 VM이므로 최종적으로:

```bash
reboot
```

를 실시하였다.

---

# 9. 재부팅 후 정상화 검증

## 9.1 hello-world

```bash
docker run --rm hello-world
```

정상 출력:

```text
Hello from Docker!
```

이 테스트 하나로 다음 흐름이 정상임을 간단히 검증할 수 있다.

```text
Docker CLI
 → Docker daemon
 → Image Pull
 → Container Create
 → Container Start
 → Output
 → Container Exit
```

---

## 9.2 nginx 테스트

처음:

```bash
docker run -d --name test-nginx nginx
```

`docker ps`:

```text
80/tcp
```

이 상태에서:

```bash
curl localhost
```

를 하면 실패할 수 있다.

이유:

> 컨테이너가 80/tcp를 사용한다고 해서 호스트의 80번 포트와 자동 연결되는 것은 아니다.

포트 매핑:

```bash
docker rm -f test-nginx

docker run -d \
  --name test-nginx \
  -p 8080:80 \
  nginx
```

검증:

```bash
curl localhost:8080
```

정상:

```text
Welcome to nginx!
```

### 기억

```text
80/tcp
→ Container 내부에서 80 사용

0.0.0.0:8080->80/tcp
→ Host 8080 → Container 80
```

---

# 10. `docker create` vs `docker run`

## create

```bash
docker container create \
  --name testweb1 \
  -p 8081:80 \
  httpd
```

상태:

```text
Created
```

컨테이너의 설정과 filesystem을 생성하지만 바로 실행하지 않는다.

실행하려면:

```bash
docker container start testweb1
```

---

## run

```bash
docker container run -itd \
  --name testweb2 \
  -p 8082:80 \
  httpd
```

상태:

```text
Up
```

개념:

```text
docker run
≈ docker create + docker start
```

---

# 11. Container → Image : `docker commit`

실행 중이거나 생성된 컨테이너의 변경된 filesystem을 새로운 이미지로 저장할 수 있다.

형식:

```bash
docker container commit [OPTIONS] CONTAINER REPOSITORY:TAG
```

실습:

```bash
docker container commit \
  -a "jeong yun gu" \
  -m "testweb1-img" \
  testweb1 \
  ray589/testweb:1.0
```

주요 옵션:

| 옵션 | 의미 |
|---|---|
| `-a` | Author |
| `-m` | Commit Message |

확인:

```bash
docker image ls
docker image inspect ray589/testweb:1.0
```

`inspect`에서 다음 정보를 확인할 수 있다.

```text
Author
Comment
Parent Image
Cmd
Env
ExposedPorts
RootFS Layers
```

---

# 12. 직접 수정한 Ubuntu 컨테이너를 이미지화

Ubuntu 컨테이너 내부에서:

```bash
echo 1234 > image.txt

apt update
apt -y install bind9-utils
apt -y install bind9-dnsutils

nslookup www.google.com
```

변경 후:

```bash
docker container commit \
  -a "jeong yun gu" \
  -m "testweb3-img" \
  testweb3 \
  ray589/testweb3:1.0
```

새 이미지 실행:

```bash
docker container run -it \
  --name testweb4 \
  ray589/testweb3:1.0
```

확인:

```bash
cat image.txt
nslookup www.google.com
```

즉 컨테이너 안에서 추가한 파일/패키지가 새 이미지에 반영되었다.

---

# 13. `export/import` vs `save/load` ★★★

Docker 시험/면접/복습에서 매우 잘 헷갈리는 부분이다.

## 13.1 export / import

### Container → tar

```bash
docker container export testweb1 -o testweb1.tar
```

확인:

```bash
tar tf testweb1.tar | more
```

내용은 컨테이너의 root filesystem 형태이다.

```text
bin/
boot/
dev/
etc/
home/
usr/
var/
...
```

다시 Image로:

```bash
cat testweb1.tar | \
docker image import - ray589/testweb4:1.0
```

흐름:

```text
Container
   ↓ export
Filesystem TAR
   ↓ import
New Image
```

### 포인트

`export`는 컨테이너의 filesystem 중심으로 내보낸다.

---

## 13.2 save / load

Image 자체를 보관:

```bash
docker image save -o image.tar ubuntu:latest
```

확인:

```bash
tar -tf image.tar
```

예:

```text
blobs/
index.json
manifest.json
oci-layout
```

삭제:

```bash
docker image rm -f ubuntu:latest
```

복원:

```bash
docker image load -i image.tar
```

결과:

```text
Loaded image: ubuntu:latest
```

흐름:

```text
Image
  ↓ save
Image Archive
  ↓ load
Image
```

---

## 13.3 비교표

| 구분 | 출발 | 저장 | 복원 |
|---|---|---|---|
| `export` | Container | filesystem tar | `import` |
| `save` | Image | image archive | `load` |

암기:

```text
Container = export / import
Image     = save   / load
```

---

# 14. Dockerfile로 이미지 생성

컨테이너 내부에서 수동 작업 후 `commit`하는 것도 가능하지만, 재현성과 자동화를 위해서는 Dockerfile 사용이 훨씬 중요하다.

실습:

```dockerfile
FROM httpd
COPY public-html/index.html /usr/local/apache2/htdocs/
```

디렉터리:

```text
Dockerfile/
├─ Dockerfile
└─ public-html/
   └─ index.html
```

빌드:

```bash
docker image build -t myimage .
```

실행:

```bash
docker container run -itd \
  --name myweb \
  -p 80:80 \
  myimage:latest
```

확인:

```bash
docker container exec myweb \
  ls /usr/local/apache2/htdocs

docker container exec myweb \
  cat /usr/local/apache2/htdocs/index.html
```

---

# 15. Docker Build Context

```bash
docker image build -t myimage .
```

마지막의 `.`은 매우 중요하다.

```text
.
└─ 현재 디렉터리를 Build Context로 Docker Builder에게 전달
```

실수:

```bash
docker image build -t stressimg
```

결과:

```text
docker buildx build requires 1 argument
```

교정:

```bash
docker image build -t stressimg .
```

---

# 16. Dockerfile 핵심 명령

| 명령 | 역할 |
|---|---|
| `FROM` | Base Image 지정 |
| `RUN` | 이미지 Build 과정에서 명령 실행 |
| `COPY` | Build Context의 파일을 이미지에 복사 |
| `ADD` | COPY 기능 + 일부 추가 기능 |
| `WORKDIR` | 작업 디렉터리 지정 |
| `CMD` | 컨테이너 실행 시 기본 명령/인자 |
| `ENTRYPOINT` | 컨테이너의 주 실행 프로그램 지정 |
| `ENV` | 환경변수 설정 |
| `EXPOSE` | 이미지가 사용할 포트 정보 |
| `VOLUME` | 데이터 저장 경로 지정 |
| `ONBUILD` | 해당 이미지를 Base로 자식 이미지를 만들 때 실행 |

---

# 17. Image Layer

Docker Image는 여러 Layer의 집합이다.

예:

```dockerfile
FROM nginx
COPY testfile /tmp/
COPY index.html /usr/share/nginx/html/
```

개념적으로:

```text
Layer 3 : COPY index.html ...
Layer 2 : COPY testfile ...
Layer 1 : nginx base image
```

확인:

```bash
docker history IMAGE
```

Docker BuildKit은 이전 빌드 결과를 Cache로 재사용할 수 있다.

```text
CACHED
```

라고 표시되면 기존 빌드 결과가 재사용된 것이다.

Cache를 사용하지 않고 확인:

```bash
docker image build \
  --no-cache \
  --progress plain \
  -t run-sample .
```

---

# 18. 압축된 Build Context 사용

Build Context를 tar.gz로 만들 수도 있다.

```bash
tar -czf docker.tar.gz *
```

빌드:

```bash
docker image build \
  -t sample:4.0 \
  - < docker.tar.gz
```

`-`는 표준입력(STDIN)에서 Build Context를 전달받는다는 의미로 볼 수 있다.

---

# 19. Single-stage Build

Go 프로그램을 빌드하기 위해 큰 Golang 이미지를 그대로 최종 이미지로 사용할 수 있다.

예시 구조:

```dockerfile
FROM golang:1.16

WORKDIR /go/src/github.com/test/hello

RUN go get -d -v github.com/urfave/cli

COPY main.go main.go

RUN GOOS=linux go build -a -o hello main.go

ENTRYPOINT ["./hello"]
```

실행:

```bash
docker container run --rm singlestage:latest
```

출력:

```text
Hello, World!
```

문제:

> 컴파일을 위해 필요한 compiler, library, build tool 등이 최종 이미지에도 그대로 들어간다.

실습에서 single-stage 이미지 크기는 약:

```text
1.35 GB
```

였다.

---

# 20. Multi-stage Build ★★★

Build 전용 Stage와 Runtime 전용 Stage를 분리한다.

개념:

```text
[Builder Stage]
golang:1.16
  ↓
Compile
  ↓
hello Binary 생성
  ↓ COPY --from=builder

[Runtime Stage]
busybox
  ↓
hello Binary만 포함
```

핵심:

```dockerfile
FROM golang:1.16 AS builder

WORKDIR /go/src/github.com/test/hello

RUN go get -d -v github.com/urfave/cli

COPY main.go main.go

RUN GOOS=linux go build -a -o hello main.go


FROM busybox

WORKDIR /opt/greet/bin

COPY --from=builder \
  /go/src/github.com/test/hello/ .

ENTRYPOINT ["./hello"]
```

실행:

```bash
docker container run --rm multistage:latest
```

출력:

```text
Hello, World!
```

### 실습 결과

```text
Single-stage : 약 1.35 GB
Multi-stage  : 약 9.76 MB
```

엄청난 차이다.

### 장점

- 최종 Image Size 감소
- 불필요한 Build Tool 제거
- 공격 표면 감소
- 배포 속도 향상
- Registry 저장 공간 절약

한 줄 정리:

> **빌드는 무거운 이미지에서, 실행은 가벼운 이미지에서.**

---

# 21. Dockerfile `RUN`: Shell vs Exec 형식

## Shell 형식

```dockerfile
RUN echo Shell 형식입니다.
```

Docker는 일반적으로 shell을 통해 실행한다.

개념:

```text
/bin/sh -c "echo Shell 형식입니다."
```

---

## Exec 형식

```dockerfile
RUN ["echo", "Exec 형식입니다."]
```

직접 실행 파일을 지정하는 JSON 배열 형식이다.

또는:

```dockerfile
RUN ["/bin/bash","-c","echo '/bin/bash 실행'"]
```

---

# 22. CMD vs ENTRYPOINT ★★★

Docker에서 매우 중요한 파트.

실습 이미지의 설정:

```text
ENTRYPOINT ["top"]
CMD ["-d","10"]
```

기본 실행:

```bash
docker container run -it \
  --name top1 \
  cmd-sample
```

실제로:

```text
top -d 10
```

이 실행된다.

---

## CMD 값 변경

```bash
docker container run -it \
  --name top2 \
  cmd-sample \
  -d 5
```

Dockerfile의 기본 CMD:

```text
-d 10
```

대신:

```text
-d 5
```

가 전달된다.

최종:

```text
top -d 5
```

---

## ENTRYPOINT 때문에 발생한 오류

```bash
docker container run -it \
  --name top3 \
  cmd-sample \
  /bin/bash
```

사용자는 bash를 실행하려 했지만 실제로는:

```text
top /bin/bash
```

가 되어 오류가 발생했다.

이유:

```text
ENTRYPOINT = top
추가 인자    = /bin/bash

→ top /bin/bash
```

---

## ENTRYPOINT 덮어쓰기

```bash
docker container run -it \
  --name top5 \
  --entrypoint /bin/bash \
  cmd-sample:latest
```

이 경우 PID 1:

```text
/bin/bash
```

확인:

```bash
ps -ef
```

---

## 핵심 비교

| 항목 | CMD | ENTRYPOINT |
|---|---|---|
| 역할 | 기본 명령/인자 | 주 실행 프로그램 |
| `docker run IMAGE ARG` | 쉽게 대체됨 | ARG를 뒤에 붙여 실행 |
| 변경 | IMAGE 뒤 ARG | `--entrypoint` |

기억:

```text
ENTRYPOINT = 실행 파일
CMD        = 기본 인자
```

예:

```dockerfile
ENTRYPOINT ["top"]
CMD ["-d","10"]
```

→

```text
top -d 10
```

---

# 23. 공식 nginx 이미지 내부 구조 확인

실습:

```bash
docker container run -itd \
  --name myweb \
  nginx
```

접속:

```bash
docker container exec -it myweb /bin/bash
```

처음:

```bash
ps -ef
```

오류:

```text
ps: command not found
```

경량 Container Image에는 진단 도구까지 모두 들어있지 않을 수 있다.

설치:

```bash
apt update
apt -y install procps
```

이후:

```bash
ps -ef
```

에서:

```text
PID 1 nginx: master process nginx -g daemon off;
```

등을 확인할 수 있다.

### 의미

컨테이너는 VM처럼 모든 관리 도구가 들어있는 완전한 OS가 아니라:

> **애플리케이션 실행에 필요한 최소 구성 중심**

으로 제공되는 경우가 많다.

---

# 24. ENTRYPOINT Script

공식 nginx 이미지에서:

```bash
cat /docker-entrypoint.sh
```

스크립트 마지막 부분의 핵심:

```bash
exec "$@"
```

개념:

```text
Docker Container 시작
       ↓
ENTRYPOINT Script 실행
       ↓
초기 설정 작업 수행
       ↓
exec "$@"
       ↓
실제 nginx Process 실행
```

`exec`를 사용하면 최종 애플리케이션 프로세스가 적절하게 PID 1 역할을 맡도록 연결할 수 있다.

---

# 25. ONBUILD ★★★

ONBUILD는 조금 특이하다.

명령을 선언한 이미지 자체를 빌드할 때 바로 실행되는 것이 아니라:

> **그 이미지를 Base Image로 사용하는 다음 자식 이미지 Build 시점에 실행된다.**

부모:

```dockerfile
FROM ubuntu

RUN apt update && apt -y upgrade
RUN apt -y install nginx

ONBUILD ADD website.tar /var/www/html/

CMD ["nginx","-g","daemon off;"]
```

`web-img`를 만든다.

```bash
docker image build \
  -t web-img \
  . \
  -f Dockerfile1
```

확인:

```bash
docker image inspect web-img
```

설정:

```text
OnBuild:
ADD website.tar /var/www/html/
```

---

## 부모 이미지를 바로 실행

```bash
docker container run -itd \
  --name test1 \
  web-img:latest
```

확인:

```bash
docker container exec test1 \
  ls /var/www/html
```

기본 nginx 페이지 정도만 존재한다.

즉 ONBUILD는 아직 실행되지 않았다.

---

## 자식 이미지 생성

예:

```dockerfile
FROM web-img
```

빌드:

```bash
docker image build \
  -t webserver-img \
  . \
  -f Dockerfile2
```

이 순간 부모의:

```dockerfile
ONBUILD ADD website.tar /var/www/html/
```

가 자동 실행된다.

확인:

```bash
docker container exec test2 \
  ls /var/www/html
```

결과:

```text
css/
images/
index.html
index.nginx-debian.html
```

### 흐름

```text
Dockerfile1
  ↓
web-img
  └─ ONBUILD 명령 예약
          ↓

Dockerfile2
FROM web-img
  ↓
자식 이미지 Build
  ↓
예약된 ONBUILD 실행
  ↓
website.tar 추가
```

---

# 26. MySQL Image의 ENTRYPOINT / CMD / Volume

확인:

```bash
docker image inspect mysql
```

주요 설정:

```text
ExposedPorts:
  3306/tcp
  33060/tcp

Entrypoint:
  docker-entrypoint.sh

Cmd:
  mysqld

Volumes:
  /var/lib/mysql
```

개념:

```text
ENTRYPOINT docker-entrypoint.sh
             +
CMD mysqld
             ↓
MySQL Server 실행
```

---

# 27. MySQL 환경변수

실행:

```bash
docker container run -itd \
  --name mydb \
  -e MYSQL_ROOT_PASSWORD=password \
  -p 3306:3306 \
  mysql
```

`-e`:

```text
Environment Variable 전달
```

즉 컨테이너 시작 시 MySQL 초기 설정 스크립트가 사용할 환경변수를 넘긴다.

---

# 28. 익명 Volume

MySQL Image에는:

```text
VOLUME /var/lib/mysql
```

설정이 존재하므로 별도의 이름을 지정하지 않아도 Docker가 익명 Volume을 생성할 수 있다.

확인:

```bash
docker volume ls
```

Inspect:

```bash
docker volume inspect VOLUME_NAME
```

예:

```text
Mountpoint:
/var/lib/docker/volumes/<ID>/_data
```

---

## Volume 정리

```bash
docker volume prune -a
```

주의:

> 사용되지 않는 local volume을 삭제한다.

데이터가 필요한 환경에서 무심코 사용하면 안 된다. 💀

---

# 29. 오늘 발생한 주요 오타 / 오류 정리

## 29.1 Dockerfile JSON 따옴표 오류

오류:

```dockerfile
CMD ["/bin/sh","-c",stress -c 2"]
```

교정:

```dockerfile
CMD ["/bin/sh","-c","stress -c 2"]
```

---

## 29.2 Docker Build Context 누락

오류:

```bash
docker image build -t stressimg
```

교정:

```bash
docker image build -t stressimg .
```

---

## 29.3 파일명 오타

```bash
cat Docckerfile   # X
cat Dockerfile    # O
```

---

## 29.4 cp 사용

오류:

```bash
cp /root/docker/index.html
```

목적지가 없다.

교정:

```bash
cp /root/docker/index.html .
```

---

## 29.5 `cd`와 `cp` 혼동

오류:

```bash
cd /root/docker/index.html public-html/
```

교정:

```bash
cp /root/docker/index.html public-html/
```

---

## 29.6 inspect 오타

```bash
docker image insepct multistage   # X
docker image inspect multistage   # O
```

---

## 29.7 volume 오타

```bash
docker voulme inspect ...   # X
docker volume inspect ...   # O
```

---

## 29.8 Container 이름 중복

오류:

```text
Conflict. The container name "/test1" is already in use
```

해결:

```bash
docker rm -f test1
```

또는 다른 이름 사용.

---

## 29.9 Image에 프로그램이 없음

```bash
docker run ubuntu /bin/cal
```

오류:

```text
/bin/cal: no such file or directory
```

컨테이너 이미지는 필요한 프로그램이 반드시 다 설치되어 있는 완전한 OS가 아니다.

---

# 30. commit vs Dockerfile

## docker commit

장점:

- 현재 컨테이너 상태를 빠르게 이미지로 저장
- 실습 / 임시 Snapshot에 편리

단점:

- 어떤 과정을 거쳐 이미지가 만들어졌는지 추적하기 어려움
- 재현성 부족
- 자동화에 불리

---

## Dockerfile

장점:

- 이미지 제작 과정이 코드로 남음
- Git으로 버전 관리 가능
- 누구나 동일 이미지 재생성 가능
- CI/CD 자동화 가능
- IaC / DevOps 방향과 잘 맞음

### 실무 관점

```text
수동 Container 수정
       ↓
docker commit
       ↓
"결과만 남음"

Dockerfile
       ↓
docker build
       ↓
"과정과 결과 모두 재현 가능"
```

따라서 학습에서는 `commit`도 이해해야 하지만, 실제 운영/협업에서는 Dockerfile 중심 사고가 매우 중요하다.

---

# 31. 오늘의 핵심 명령어 Cheat Sheet

## 상태 확인

```bash
docker ps
docker ps -a
docker image ls
docker volume ls
docker info
docker stats
```

## Container

```bash
docker create --name NAME IMAGE

docker run -itd \
  --name NAME \
  -p HOST_PORT:CONTAINER_PORT \
  IMAGE

docker exec -it NAME /bin/bash

docker rm -f NAME
```

## Image

```bash
docker image inspect IMAGE
docker history IMAGE

docker container commit \
  -a "AUTHOR" \
  -m "MESSAGE" \
  CONTAINER \
  REPOSITORY:TAG
```

## Export / Import

```bash
docker container export CONTAINER \
  -o container.tar

cat container.tar | \
docker image import - repository:tag
```

## Save / Load

```bash
docker image save \
  -o image.tar \
  IMAGE

docker image load \
  -i image.tar
```

## Build

```bash
docker image build \
  -t IMAGE:TAG \
  .
```

다른 Dockerfile:

```bash
docker image build \
  -t IMAGE \
  -f Dockerfile2 \
  .
```

Cache 없이:

```bash
docker image build \
  --no-cache \
  --progress plain \
  -t IMAGE \
  .
```

## CPU / Memory

```bash
docker run \
  --cpus="1" \
  --cpuset-cpus="0-1" \
  -m 512m \
  --memory-swap 512m \
  IMAGE
```

## Disk I/O

```bash
docker run \
  --device-write-bps=/dev/sda:10mb \
  --device-read-bps=/dev/sda:10mb \
  IMAGE
```

---

# 32. 이것만은 반드시 기억하기 ★★★★★

```text
1. docker run = create + start

2. Host에 설치한 프로그램은 Container에 자동으로 생기지 않는다.

3. IMAGE 뒤의 COMMAND/ARG는 컨테이너 내부 실행 명령이다.

4. -p 8080:80
   Host 8080 → Container 80

5. Container → export → tar → import → Image

6. Image → save → tar → load → Image

7. docker build 마지막의 "." = Build Context

8. Docker Image = 여러 Layer의 집합

9. Multi-stage
   Build 환경과 Runtime 환경을 분리해 최종 이미지 크기를 줄인다.

10. ENTRYPOINT = 주 실행 프로그램
    CMD        = 기본 명령/기본 인자

11. --entrypoint = Dockerfile ENTRYPOINT를 실행 시 덮어쓰기

12. ONBUILD
    부모 이미지에서는 예약되고,
    자식 이미지 Build 시 실행된다.

13. MySQL 같은 Stateful Container는 Volume이 매우 중요하다.

14. --memory-swap = Swap만의 크기가 아니라 Memory + Swap 총량

15. --device-write-bps=/dev/sda:100
    = 100MB/s가 아니라 100B/s일 수 있다. 단위를 꼭 적자. 💀
```

---

# 33. 구조로 기억하기

```text
                 Docker Host
                     │
        ┌────────────┴────────────┐
        │                         │
    Docker Image             Docker Container
        │                         │
        │ docker run              │
        └────────────────────────>│
                                  │
                                  │ docker commit
                                  ▼
                              New Image


Container ── export ──> filesystem.tar ── import ──> Image

Image ───── save ─────> image.tar ─────── load ────> Image


Dockerfile
   │
   │ docker build
   ▼
Image
   │
   │ docker run
   ▼
Container
```

---

# 34. Multi-stage 구조 한 번 더

```text
Source Code
    │
    ▼
┌────────────────────────┐
│ Builder Stage          │
│ golang:1.16            │
│ Compiler / Build Tools │
│                        │
│ go build               │
└──────────┬─────────────┘
           │
           │ binary만 COPY
           ▼
┌────────────────────────┐
│ Runtime Stage          │
│ busybox                │
│                        │
│ ./hello                │
└──────────┬─────────────┘
           │
           ▼
      작은 최종 Image
```

실습 결과가 보여준 핵심:

```text
1.35 GB
   ↓
약 9.76 MB
```

---

# 35. 트러블슈팅 사고 순서

Docker에서 이상 현상이 생기면 무작정 재부팅부터 하지 말고 다음 순서로 본다.

```text
1. Container 상태
   docker ps -a

2. Container 로그
   docker logs CONTAINER

3. Docker 정보
   docker info

4. Docker daemon
   systemctl status docker

5. containerd
   systemctl status containerd

6. Runtime Process
   ps -ef | egrep 'dockerd|containerd|runc|shim'

7. System Journal
   journalctl -u docker
   journalctl -u containerd

8. 실습 VM이고 runtime 자체가 심각하게 꼬였다면
   reboot
```

이 순서는 이후 Kubernetes/container runtime 장애를 볼 때도 기반 사고방식이 된다.

---

# 36. 오늘 복습 우선순위

모든 명령을 외울 필요는 없다.

## 1순위

```text
run / create
-p
-m
--cpus / --cpuset-cpus
save / load
export / import
Dockerfile
FROM / RUN / COPY
CMD / ENTRYPOINT
Multi-stage
```

## 2순위

```text
docker history
Build Cache
ONBUILD
ENV
VOLUME
docker commit
```

## 3순위

```text
device-read/write-bps
stress 세부 옵션
containerd / shim 구조
```

---

# 37. 면접형 한 줄 Q&A

### Q. Docker Container와 Image의 차이는?
Image는 읽기 중심의 실행 템플릿이고, Container는 그 이미지를 기반으로 실행된 인스턴스이다.

### Q. `docker run`과 `docker create` 차이는?
`create`는 컨테이너만 생성하고, `run`은 생성 후 바로 시작한다.

### Q. Docker에서 CPU와 Memory 제한은 무엇으로 구현되는가?
Linux cgroup을 기반으로 한다.

### Q. Namespace와 cgroup 차이는?
Namespace는 격리 범위를 담당하고, cgroup은 자원 사용량을 제어한다.

### Q. `save/load`와 `export/import` 차이는?
`save/load`는 Image 단위, `export/import`는 Container filesystem 단위로 이해하면 된다.

### Q. Dockerfile의 `RUN`과 `CMD` 차이는?
`RUN`은 Image Build 시 실행되고, `CMD`는 Container 실행 시 기본 명령/인자로 사용된다.

### Q. `ENTRYPOINT`는?
컨테이너의 주 실행 프로그램을 지정한다.

### Q. Multi-stage Build를 사용하는 이유는?
빌드 도구를 최종 이미지에서 제거해 이미지 크기와 공격 표면을 줄이기 위해서다.

### Q. ONBUILD는 언제 실행되는가?
해당 이미지를 Base Image로 사용하는 자식 Image를 Build할 때 실행된다.

### Q. Container에서 DB 데이터를 유지하려면?
Volume을 사용해 컨테이너 lifecycle과 데이터를 분리한다.

---

# 38. 오늘의 최종 한 줄

> **Docker는 단순히 컨테이너를 띄우는 도구가 아니라, Linux 자원을 제한하고 애플리케이션 실행 환경을 Image로 정의하여 동일한 환경을 반복 배포하는 플랫폼이다.**

그리고 오늘의 역사적 교훈:

```text
10mb ≠ 100

단위는 생명이다. 💀
```

---

## 복습 체크리스트

- [ ] `docker run`과 `docker create` 차이를 설명할 수 있다.
- [ ] `-p 8080:80`의 방향을 설명할 수 있다.
- [ ] `-m`, `--memory-swap`의 의미를 설명할 수 있다.
- [ ] `--cpus`와 `--cpuset-cpus` 차이를 설명할 수 있다.
- [ ] Disk I/O BPS 제한에 단위를 붙여야 하는 이유를 안다.
- [ ] Host와 Container filesystem이 분리되어 있음을 설명할 수 있다.
- [ ] `commit`의 역할을 안다.
- [ ] `export/import`와 `save/load`를 구별할 수 있다.
- [ ] Docker Build Context의 의미를 안다.
- [ ] Image Layer와 Build Cache 개념을 안다.
- [ ] Single-stage와 Multi-stage Build를 비교할 수 있다.
- [ ] `CMD`와 `ENTRYPOINT`의 결합 관계를 설명할 수 있다.
- [ ] `--entrypoint`가 무엇을 하는지 안다.
- [ ] `ONBUILD` 실행 시점을 설명할 수 있다.
- [ ] MySQL Image에서 Volume이 필요한 이유를 설명할 수 있다.
- [ ] Docker → containerd → shim/runc의 대략적인 실행 구조를 설명할 수 있다.

---

**끝. 오늘도 Docker에게 한 대 맞았지만, 대신 런타임 내부 구조까지 배웠다. 🐳💀🔥**
