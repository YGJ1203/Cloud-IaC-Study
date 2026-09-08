# 2026-09-08 Docker 컨테이너 관리 실습 정리

> **학습 주제:** Docker 이미지 관리, 컨테이너 생명주기, `--rm`, 포트 매핑, Docker Hub, 컨테이너 접속, 네트워크 옵션, Volume/Bind Mount, MySQL 및 NFS 연동

---

## 1. 오늘의 핵심 흐름

오늘 실습은 단순히 이미지를 내려받고 컨테이너를 실행하는 수준에서 한 단계 더 나아가 다음 흐름을 직접 확인하는 과정이었다.

```text
Docker Image
   ↓
Container 생성 / 실행
   ↓
Foreground / Background 실행
   ↓
attach / exec
   ↓
Port Mapping
   ↓
Volume / Bind Mount
   ↓
Docker Hub Push / Pull
   ↓
MySQL / NFS 등 외부 서비스와 연동
```

핵심은 **이미지(Image)는 컨테이너를 만들기 위한 템플릿이고, 컨테이너(Container)는 이미지를 실제 프로세스로 실행한 인스턴스**라는 점이다.

---

# 2. Docker 이미지 관리

## 2.1 이미지 확인

```bash
docker image ls
```

로컬 시스템에 존재하는 Docker 이미지를 확인한다.

## 2.2 이미지 다운로드

```bash
docker image pull nginx:latest
```

Docker Hub에서 `nginx:latest` 이미지를 내려받는다.

## 2.3 이미지 태그 지정

```bash
docker image tag nginx:latest <DockerHub_ID>/webserver:1.0
```

기존 이미지에 Docker Hub 저장소 형식의 태그를 추가한다.

```text
nginx:latest
      ↓ tag
<DockerHub_ID>/webserver:1.0
```

태그를 추가한다고 이미지 내용이 복제되는 것은 아니다. 같은 이미지에 새로운 이름/태그를 연결하는 개념으로 이해하면 된다.

## 2.4 Docker Hub 로그인 / Push

```bash
docker login -u <DockerHub_ID>
docker image push <DockerHub_ID>/webserver:1.0
```

업로드 후 로컬 이미지를 삭제하고 다시 내려받아 저장소에 정상적으로 등록되었는지 확인할 수 있다.

```bash
docker image rm -f <DockerHub_ID>/webserver:1.0
docker image pull <DockerHub_ID>/webserver:1.0
```

> `latest` 태그를 만들지 않았다면 `docker image pull <DockerHub_ID>/webserver`처럼 태그를 생략했을 때 `:latest`를 찾으므로 실패할 수 있다. 이 경우 실제 등록한 태그까지 지정한다.

```bash
docker image pull <DockerHub_ID>/webserver:1.0
```

---

# 3. 컨테이너 생성과 실행

## 3.1 `docker container create`

```bash
docker container create --name webserver nginx
```

컨테이너를 **생성만** 한다.

```bash
docker container ls -a
```

상태가 `Created`로 표시된다.

이후 별도로 실행한다.

```bash
docker container start webserver
```

종료:

```bash
docker container stop webserver
```

즉,

```text
create → Created
start  → Running
stop   → Exited
```

## 3.2 `docker container run`

```bash
docker container run [OPTIONS] IMAGE [COMMAND]
```

`run`은 실질적으로 다음 과정을 한 번에 수행한다.

```text
create + start
```

예:

```bash
docker container run -it --name test centos:8 /bin/bash
```

---

# 4. 주요 옵션 정리

| 옵션 | 의미 |
|---|---|
| `--name NAME` | 컨테이너 이름 지정 |
| `-i` | 표준 입력(STDIN)을 열린 상태로 유지 |
| `-t` | 가상 터미널(TTY) 할당 |
| `-d` | 백그라운드(detached) 실행 |
| `--rm` | 컨테이너 종료 시 자동 삭제 |
| `-p HOST:CONTAINER` | 호스트 포트와 컨테이너 포트 연결 |
| `-v SOURCE:TARGET` | 볼륨 또는 디렉토리 마운트 |
| `-e KEY=VALUE` | 환경 변수 전달 |
| `--hostname` | 컨테이너 hostname 지정 |
| `--dns` | 컨테이너 DNS 지정 |
| `--add-host` | `/etc/hosts` 항목 추가 |
| `--mac-address` | MAC 주소 지정 |

### `-it`가 자주 같이 사용되는 이유

```bash
docker container run -it centos:8 /bin/bash
```

쉘과 상호작용하려면 입력을 받을 수 있어야 하고(`-i`), 터미널 환경도 필요하기 때문에(`-t`) 보통 두 옵션을 함께 사용한다.

---

# 5. 컨테이너 프로세스와 종료

CentOS 이미지의 기본 명령이 `/bin/bash`인 경우 터미널 입력 환경 없이 실행하면 bash가 곧바로 끝나면서 컨테이너도 종료될 수 있다.

```bash
docker container run --name test2 centos:8
docker container ls -a
```

컨테이너는 VM처럼 독립 OS가 계속 켜져 있는 것이 아니라 **컨테이너의 주 프로세스(PID 1)가 살아 있는 동안 실행된다**고 이해하는 것이 중요하다.

```text
PID 1 실행 중 → Container Running
PID 1 종료   → Container Exited
```

---

# 6. `attach`와 `exec`

## attach

```bash
docker container attach test7
```

실행 중인 컨테이너의 기존 표준 입출력 세션에 연결한다.

`attach` 상태에서 쉘 자체를 `exit`하면 PID 1인 쉘이 종료되어 컨테이너까지 종료될 수 있으므로 주의한다.

기본 detach key sequence:

```text
Ctrl + P
Ctrl + Q
```

컨테이너를 종료하지 않고 attach 세션에서 빠져나올 때 사용한다.

## exec

```bash
docker container exec -it test7 /bin/bash
```

실행 중인 컨테이너 안에서 **새로운 프로세스**를 실행한다.

예를 들어 프로세스를 보면 기존 PID 1 bash와 `exec`로 추가된 bash를 함께 확인할 수 있다.

```bash
docker container exec test7 /usr/sbin/ip address
```

> 컨테이너 이미지는 최소 구성인 경우가 많아 `ifconfig` 같은 명령이 설치되어 있지 않을 수 있다.

### attach vs exec

| 구분 | attach | exec |
|---|---|---|
| 대상 | 기존 메인 프로세스 | 새로운 프로세스 |
| 쉘 종료 영향 | 메인 쉘이면 컨테이너 종료 가능 | 일반적으로 컨테이너 유지 |
| 관리 목적 | 기존 세션 연결 | 컨테이너 내부 명령 실행 |
| 실무 편의성 | 주의 필요 | 자주 사용 |

---

# 7. 포트 매핑

```bash
docker container run -itd \
  --name testweb \
  -p 8081:80 \
  nginx
```

의 의미:

```text
Client
  ↓
Docker Host :8081
  ↓
Container :80
  ↓
nginx
```

확인:

```bash
docker container ls
netstat -ntlp
curl http://192.168.2.10:8081
```

호스트의 `8081` 포트로 접속했지만 실제 웹 서비스는 컨테이너의 TCP 80에서 동작한다.

---

# 8. 컨테이너 네트워크 옵션

실습에서 컨테이너 내부의 IP 및 `/etc/hosts`를 확인하고 호스트와의 통신도 테스트하였다.

```bash
docker container exec test7 /usr/sbin/ip address
```

기본 bridge 네트워크에서는 예제와 같이 `172.17.x.x` 대역의 주소가 할당될 수 있다.

추가 옵션 예:

```bash
docker container run -itd \
  --name test2 \
  --mac-address="00:00:00:11:11:11" \
  --dns 8.8.8.8 \
  --hostname myweb \
  --add-host docker1:172.17.0.1 \
  centos:8
```

> 여러 줄 명령에서 `\` 뒤에는 불필요한 문자를 붙이지 않고 다음 줄로 넘긴다. 옵션 사이 공백이 사라지면 `8.8.8.8--hostname`처럼 하나의 잘못된 인자로 해석될 수 있다.

---

# 9. Docker Volume

컨테이너 내부 데이터는 컨테이너 삭제와 함께 잃어버릴 수 있으므로 영속적인 데이터가 필요하면 Volume을 사용한다.

## Volume 생성

```bash
docker volume create wwwvol
docker volume ls
docker volume inspect wwwvol
```

Docker가 관리하는 실제 데이터 위치는 다음과 같은 형태로 확인할 수 있다.

```text
/var/lib/docker/volumes/wwwvol/_data
```

## nginx에 Volume 연결

```bash
docker container run -itd \
  --name webserver \
  -v wwwvol:/usr/share/nginx/html/ \
  -p 8080:80 \
  nginx
```

구조:

```text
Docker Host
/var/lib/docker/volumes/wwwvol/_data
             │
             │ Docker Volume
             ▼
Container
/usr/share/nginx/html
             │
             ▼
           nginx
```

Volume은 컨테이너와 분리되어 관리되므로 컨테이너를 교체해도 데이터를 유지하는 용도로 사용할 수 있다.

---

# 10. Bind Mount

Docker가 관리하는 named volume 대신 호스트의 특정 디렉토리를 컨테이너에 직접 연결할 수도 있다.

```bash
docker container run -itd \
  --name myweb \
  -v /www:/usr/share/nginx/html \
  -p 8080:80 \
  nginx
```

호스트에서:

```bash
cp docker/index.html /www/
```

컨테이너에서:

```bash
docker container exec myweb ls /usr/share/nginx/html
```

동일한 `index.html`을 확인할 수 있다.

```text
Host /www/index.html
        ⇅
Bind Mount
        ⇅
Container /usr/share/nginx/html/index.html
```

### Named Volume vs Bind Mount

| 항목 | Named Volume | Bind Mount |
|---|---|---|
| 예 | `wwwvol:/data` | `/www:/data` |
| 관리 주체 | Docker | 사용자/호스트 |
| 호스트 경로 | Docker가 관리 | 사용자가 직접 지정 |
| 용도 | DB 데이터 등 영속성 | 설정/웹 파일 직접 공유 |

---

# 11. MySQL 컨테이너 + Volume

MySQL 데이터 영속화를 위해 별도 Volume을 생성한다.

```bash
docker volume create mysqlvol
```

확인:

```bash
docker volume inspect mysqlvol
```

MySQL 실행:

```bash
docker container run -itd \
  --name mydb \
  -v mysqlvol:/var/lib/mysql \
  -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=password \
  mysql
```

구조:

```text
mysqlvol
   │
   ▼
/var/lib/mysql
   │
   ▼
MySQL Container :3306
   │
   ▼
Docker Host :3306
```

`-e`는 컨테이너에 환경 변수를 전달한다.

---

# 12. Docker2에서 MySQL 원격 접속

Docker2에 MySQL 클라이언트를 설치한다.

```bash
yum -y install mysql
```

Docker1의 MySQL 서비스로 접속:

```bash
mysql -h 192.168.2.10 -u root -p
```

실습 SQL:

```sql
show databases;

create database testdb;

use testdb;

create table docker (
    id int,
    login varchar(10),
    password varchar(10)
);

insert into docker values (1, 'docker1', 'docker1111');

select * from docker;
```

DB를 선택하지 않은 상태에서 테이블을 조회하려면 DB 이름까지 지정할 수 있다.

```sql
select * from testdb.docker;
```

### 실습에서 확인한 오류

```text
ERROR 1045 ... Access denied ... (using password: NO)
```

`-p` 없이 접속하여 인증에 실패했고, 이후:

```bash
mysql -h 192.168.2.10 -u root -p
```

처럼 비밀번호 입력 방식으로 접속하였다.

---

# 13. NFS와 Docker 연계

Docker2에서 NFS 공유용 디렉토리를 생성하였다.

```bash
mkdir -m 777 /nfsweb
cp docker/index.html /nfsweb/
vi /etc/exports
```

처음에는:

```bash
systemctl enable --now nfs-server
```

실행 시 NFS 서비스가 존재하지 않아 실패하였다.

따라서 필요한 패키지를 설치하였다.

```bash
yum -y install nfs-utils
```

Docker1에서는 NFS 공유를 `/web` 등에 마운트하여 파일을 확인하는 흐름을 실습하였다.

```text
Docker2
/nfsweb
   │
   │ NFS
   ▼
Docker1
/web
   │
   │ Bind Mount
   ▼
nginx Container
/usr/share/nginx/html
```

즉 NFS와 Docker를 조합하면 **다른 서버가 제공하는 공유 스토리지의 데이터를 컨테이너에서 사용하는 구조**를 만들 수 있다.

> NFS로 마운트된 `/web`은 일반 디렉토리처럼 `rm -rf /web`로 제거하는 대상이 아니다. 마운트 해제가 필요하면 먼저 `umount /web`을 수행해야 한다.

---

# 14. 실습 중 주요 오류와 트러블슈팅

## 14.1 컨테이너 이름 중복

```text
Conflict. The container name "/test1" is already in use
```

동일한 이름의 컨테이너가 이미 존재한다.

```bash
docker container ls -a
docker container rm test1
```

후 다시 생성한다.

---

## 14.2 `docker container rm`에 이미지 이름 입력

```bash
docker container rm test1 centos:8
```

`rm` 뒤에는 **컨테이너 이름/ID**가 와야 한다.

```bash
docker container rm test1
```

이미지를 삭제하려면:

```bash
docker image rm centos:8
```

---

## 14.3 `create`에 `-d` 사용

실습에서:

```bash
docker container create -itd ...
```

를 실행했을 때 `-d` 관련 오류를 확인하였다.

`create`는 실행하지 않고 생성만 하므로 detached 실행 옵션의 의미가 없다.

```bash
docker container create -it --name webserver -p 8080:80 nginx
docker container start webserver
```

또는 한 번에:

```bash
docker container run -itd --name webserver -p 8080:80 nginx
```

---

## 14.4 잘못된 Volume 문법

잘못된 예:

```bash
-v :/web:/usr/share/nginx/html
```

`-v`의 기본 형태는 다음과 같다.

```text
-v SOURCE:TARGET
```

예:

```bash
-v /web:/usr/share/nginx/html
```

---

## 14.5 `--itd`와 `-itd`

잘못된 예:

```bash
docker container run --itd ...
```

short option을 묶을 때는:

```bash
-itd
```

처럼 사용한다.

---

# 15. 제6장 Docker 컨테이너 관리 예제

아래 예제는 **`--rm`의 동작과 foreground/background 컨테이너의 차이**를 확인하기 위한 실습이다.

## 15.1 test1 컨테이너

### 조건

- `centos:8` 이미지 사용
- 실행 시 `cat /etc/os-release` 실행
- 명령 종료 후 컨테이너 자동 삭제

### 명령어

```bash
docker container run --rm \
  --name test1 \
  centos:8 \
  cat /etc/os-release
```

확인:

```bash
docker container ls -a
```

`cat` 실행이 끝나면 컨테이너가 종료되고 `--rm`에 의해 바로 삭제되므로 `test1`이 남지 않는다.

```text
Container 생성
    ↓
cat /etc/os-release
    ↓
명령 종료
    ↓
Container 종료
    ↓
--rm
    ↓
Container 자동 삭제
```

---

## 15.2 test2 컨테이너

### 조건

- `centos:8` 이미지 사용
- bash 터미널 접속
- 내부에서 `cat /etc/os-release`
- `exit` 시 컨테이너 자동 삭제

### 명령어

```bash
docker container run --rm -it \
  --name test2 \
  centos:8 \
  /bin/bash
```

컨테이너 내부:

```bash
cat /etc/os-release
exit
```

`exit`로 PID 1인 bash가 끝나면서 컨테이너가 종료되고 `--rm` 옵션으로 자동 삭제된다.

---

## 15.3 test3 컨테이너

### 조건

- `nginx` 이미지 사용
- nginx 기본 웹 서버 프로세스 대신 bash 실행
- `cat /etc/os-release` 확인
- `exit` 시 자동 삭제

### 명령어

```bash
docker container run --rm -it \
  --name test3 \
  nginx \
  /bin/bash
```

컨테이너 내부:

```bash
cat /etc/os-release
exit
```

### 중요 포인트

`nginx` 이미지를 사용했더라도 마지막에 `/bin/bash`를 명시했기 때문에 이 컨테이너의 주 프로세스는 nginx 웹 서버가 아니라 bash가 된다.

```text
nginx Image
   ↓
기본 CMD 대신 /bin/bash 실행
   ↓
bash가 PID 1
   ↓
exit
   ↓
Container 종료 + 자동 삭제
```

---

## 15.4 test4 컨테이너

### 조건

- `nginx` 이미지 사용
- 백그라운드 실행
- 웹 서버로 동작
- 호스트 TCP 80 ↔ 컨테이너 TCP 80
- `stop` 시 컨테이너 자동 삭제

### 명령어

```bash
docker container run --rm -d \
  --name test4 \
  -p 80:80 \
  nginx
```

확인:

```bash
docker container ls
```

브라우저:

```text
http://192.168.2.10
```

또는 CLI:

```bash
curl http://192.168.2.10
```

종료:

```bash
docker container stop test4
```

확인:

```bash
docker container ls -a
```

`--rm` 옵션 때문에 `stop`으로 nginx 프로세스가 종료되면 컨테이너도 자동으로 삭제된다.

---

# 16. 예제 종료 후 전체 정리

모든 컨테이너 삭제:

```bash
docker container rm -f $(docker container ls -aq)
```

모든 이미지 삭제:

```bash
docker image rm -f $(docker image ls -aq)
```

각 명령의 의미:

```bash
docker container ls -aq
```

모든 컨테이너의 ID만 출력한다.

```bash
docker container rm -f $(...)
```

출력된 ID들을 명령 치환하여 한 번에 강제 삭제한다.

이미지도 동일한 원리이다.

> **주의:** 위 명령은 해당 Docker Host의 모든 컨테이너/이미지를 대상으로 한다. 필요한 실습 데이터가 있는 환경에서는 실행 전에 반드시 `docker container ls -a`, `docker image ls`로 확인한다.

---

# 17. 오늘의 명령어 치트시트

```bash
# 이미지
docker image ls
docker image pull nginx
docker image inspect nginx
docker image tag nginx:latest USER/webserver:1.0
docker image push USER/webserver:1.0
docker image rm IMAGE

# 컨테이너 조회
docker container ls
docker container ls -a

# 생성 / 실행
docker container create --name NAME IMAGE
docker container start NAME
docker container stop NAME
docker container run -it --name NAME IMAGE /bin/bash
docker container run -itd --name NAME IMAGE

# 자동 삭제
docker container run --rm IMAGE COMMAND

# 접속
docker container attach NAME
docker container exec -it NAME /bin/bash

# 삭제
docker container rm NAME
docker container rm -f NAME

# 포트
docker container run -d -p 8080:80 nginx

# Volume
docker volume create VOLUME
docker volume ls
docker volume inspect VOLUME
docker container run -d -v VOLUME:/path IMAGE

# Bind Mount
docker container run -d -v /host/path:/container/path IMAGE

# 전체 정리 - 주의
docker container rm -f $(docker container ls -aq)
docker image rm -f $(docker image ls -aq)
```

---

# 18. 복습 핵심 질문

### Q1. Image와 Container의 차이는?

**Image**는 컨테이너 생성에 사용하는 읽기 전용 템플릿이고, **Container**는 그 이미지를 기반으로 실제 프로세스를 실행하는 인스턴스이다.

### Q2. `create`와 `run`의 차이는?

```text
create = 컨테이너 생성
run    = 생성 + 실행
```

### Q3. `-it`는 왜 같이 쓰는가?

쉘에 입력할 수 있도록 STDIN을 유지하고(`-i`), 터미널 환경을 제공하기 위해(`-t`) 함께 사용한다.

### Q4. `-d`는?

컨테이너를 터미널에 붙잡아 두지 않고 백그라운드에서 실행한다.

### Q5. `--rm`은?

컨테이너가 종료되었을 때 자동으로 컨테이너를 삭제한다.

### Q6. `-p 8080:80`은?

```text
Host 8080 → Container 80
```

호스트의 8080 포트로 들어온 연결을 컨테이너의 80 포트로 전달한다.

### Q7. `attach`와 `exec`의 핵심 차이는?

`attach`는 기존 메인 프로세스의 입출력에 연결하고, `exec`는 실행 중인 컨테이너 안에 새로운 프로세스를 생성한다.

### Q8. Volume을 사용하는 이유는?

컨테이너의 생명주기와 데이터를 분리하여 컨테이너가 교체/삭제되더라도 필요한 데이터를 유지하기 위해서이다.

---

# 19. 오늘의 핵심 한 장 요약

```text
             Docker Host
                  │
        ┌─────────┴─────────┐
        │                   │
     Images              Volumes
        │                   │
        ▼                   │
   Containers ◀─────────────┘
        │
        ├── run / create
        ├── start / stop
        ├── attach / exec
        ├── --rm
        ├── -p Port Mapping
        └── -v Volume / Bind Mount
             │
             ├── nginx Web Data
             ├── MySQL Data
             └── NFS Shared Data

Docker Hub
    ▲
    │ push
Docker Host
    │ pull
    ▼
Docker Hub
```

## 오늘 반드시 기억할 5개

1. **컨테이너는 PID 1 프로세스가 종료되면 종료된다.**
2. **`--rm`은 종료된 컨테이너를 자동 삭제한다.**
3. **`-p HOST:CONTAINER`는 호스트와 컨테이너의 포트를 연결한다.**
4. **`exec`는 실행 중인 컨테이너 안에서 새로운 프로세스를 실행한다.**
5. **Volume/Bind Mount는 컨테이너와 데이터를 분리하거나 외부 데이터를 연결하는 핵심 수단이다.**

---

> **한 줄 정리:** 오늘 실습은 Docker를 단순히 "컨테이너 하나 띄우는 도구"로 보는 단계에서 벗어나, **컨테이너의 생명주기·네트워크·스토리지·레지스트리·외부 서비스 연동을 하나의 흐름으로 이해하는 단계**였다.