# Linux 원격 파일 전송 & FTP 서버 실습 정리

> **학습 주제:** SCP, SFTP, CentOS 6/7 서비스 관리 차이,
> Standalone/xinetd/systemd, systemd service/socket, FTP와 vsftpd\
> **실습 환경:** CentOS 계열 Linux / MobaXterm / Server1 · Client1\
> **핵심 목표:** 원격 파일 전송 방법과 리눅스 서비스 실행 구조를
> 이해하고, vsftpd 기반 FTP 서버를 구축·점검한다.

------------------------------------------------------------------------

## 1. 전체 흐름

``` text
SSH
├── 원격 명령 실행
├── SCP : SSH 기반 파일 복사
└── SFTP : SSH 기반 대화형 파일 전송

FTP
└── vsftpd : FTP 서버 데몬

서비스 관리
CentOS 6 → service 중심
CentOS 7+ → systemctl(systemd) 중심
```

------------------------------------------------------------------------

# 2. SCP (Secure Copy)

## 2.1 핵심 개념

-   SSH를 기반으로 파일/디렉터리를 안전하게 복사한다.
-   기본적으로 SSH의 **TCP 22번 포트**를 사용한다.
-   기본 형식:

``` bash
scp [원본] [목적지]
```

원격 위치는 다음 형식으로 표현한다.

``` text
사용자@IP주소:/경로
```

### 방향 암기

``` bash
# 로컬 → 원격
scp local.txt root@192.168.2.201:/tmp

# 원격 → 로컬
scp root@192.168.2.203:/test/file.txt /tmp
```

> `user@host:/path`가 어느 쪽에 있는지를 보면 전송 방향을 쉽게 판단할 수
> 있다.

------------------------------------------------------------------------

## 2.2 실습용 파일 생성

### Server1

``` bash
mkdir -p /test{1,2,3,4}

cp /etc/services /test1/scpfile1.txt
cp /etc/services /test1/scpfile2.txt
cp /etc/services /test1/scpfile3.txt
cp /etc/services /test1/scpfile4.txt

cp /etc/services /test2/scpfile5.txt

cp /etc/services /test3/scpfile6.txt
cp /etc/services /test3/scpfile7.txt
cp /etc/services /test3/scpfile8.txt
cp /etc/services /test3/scpfile9.txt

cp /etc/services /test4/scpfile10.txt
```

`/etc/services`의 내용 자체가 목적이라기보다, SCP 전송 실습에 사용할
파일을 빠르게 생성하기 위한 것이다.

------------------------------------------------------------------------

## 2.3 Server1 → Client1 파일 전송

``` bash
scp /test1/scpfile1.txt root@192.168.2.201:/tmp
```

-   Server1의 `scpfile1.txt`
-   → Client1(`192.168.2.201`)의 `/tmp`

포트를 명시하려면:

``` bash
scp -P 22 /test1/scpfile2.txt root@192.168.2.201:/tmp
```

> **주의:** `scp`의 포트 옵션은 대문자 `-P`이다.\
> `ssh`는 일반적으로 소문자 `-p`를 사용하므로 혼동 주의.

여러 파일을 한 번에 전송:

``` bash
scp /test1/scpfile3.txt /test1/scpfile4.txt root@192.168.2.201:/tmp
```

### Client1 확인

``` bash
ls -l /tmp/scpfile*
```

------------------------------------------------------------------------

## 2.4 와일드카드로 여러 파일 전송

### Server1

``` bash
scp /test1/* root@192.168.2.201:/tmp
```

`/test1` 내부의 항목을 목적지 `/tmp` 아래로 전송한다.

### Client1

``` bash
ls -l /tmp/scpfile*
```

------------------------------------------------------------------------

## 2.5 디렉터리 전체 전송

``` bash
scp -r /test2 root@192.168.2.201:/tmp
```

`-r`은 **recursive(재귀)** 옵션으로 디렉터리와 내부 내용을 함께
복사한다.

결과:

``` text
Client1
/tmp/test2/
└── scpfile5.txt
```

확인:

``` bash
ls -l /tmp | grep test2
ls -l /tmp/test2
```

### `*`와 `-r` 차이

``` text
scp /test1/* ...:/tmp
→ test1 내부 항목을 /tmp로 전송

scp -r /test2 ...:/tmp
→ test2 디렉터리 자체와 내부 내용을 /tmp로 전송
```

------------------------------------------------------------------------

# 3. 원격 서버 → 로컬 SCP

## 3.1 SSH로 원격 파일 확인

### Client1

``` bash
ssh root@192.168.2.203 ls /test3
```

SSH로 대화형 쉘에 들어가는 대신, Server1에서 `ls /test3` 명령만 실행하고
결과를 Client1 화면에서 확인한다.

------------------------------------------------------------------------

## 3.2 파일 하나 가져오기

``` bash
scp root@192.168.2.203:/test3/scpfile6.txt /tmp
ls -l /tmp/scpfile6.txt
```

형식:

``` bash
scp [원격 사용자@서버:원격 파일] [로컬 경로]
```

------------------------------------------------------------------------

## 3.3 여러 파일 가져오기

중괄호 확장을 이용할 수 있다.

``` bash
scp root@192.168.2.203:/test3/scpfile{7,8,9}.txt /tmp
ls -l /tmp/scpfile{7,8,9}.txt
```

이는 다음 파일을 의미한다.

``` text
/test3/scpfile7.txt
/test3/scpfile8.txt
/test3/scpfile9.txt
```

개별 경로를 나열하는 형태도 가능하지만, 경로 표기를 일관되게 유지하는
것이 좋다.

``` bash
scp root@192.168.2.203:{/test3/scpfile7.txt,/test3/scpfile8.txt,/test3/scpfile9.txt} /tmp
```

------------------------------------------------------------------------

## 3.4 원격 디렉터리의 파일 가져오기

``` bash
scp root@192.168.2.203:/test3/* /tmp
```

확인 예:

``` bash
ls -l /tmp | grep 'scpfile[6-9]'
```

> 정규표현식에서 `[6-9]`는 6, 7, 8, 9 중 한 문자를 의미한다.\
> `[6,7,8,9]`처럼 작성하면 쉼표도 문자 클래스에 포함되므로 `[6-9]`가 더
> 명확하다.

------------------------------------------------------------------------

## 3.5 원격 디렉터리 전체 가져오기

``` bash
scp -r root@192.168.2.203:/test4 /tmp
```

확인:

``` bash
ls -l /tmp | grep test4
ls -l /tmp/test4
```

------------------------------------------------------------------------

## 3.6 실습 정리

### Server1

``` bash
rm -rf /test*
```

### Client1

``` bash
rm -rf /tmp/scpfile*
rm -rf /tmp/test*
```

> ⚠️ `rm -rf` + 와일드카드는 패턴과 일치하는 모든 대상을 강제로
> 삭제한다. 실제 운영 서버에서는 삭제 범위를 반드시 먼저 확인한다.

------------------------------------------------------------------------

# 4. SFTP

## 4.1 개념

SFTP는 **SSH File Transfer Protocol**로 SSH를 기반으로 동작한다.

``` bash
sftp root@서버IP
```

FTP와 이름은 비슷하지만 서로 다른 프로토콜 계열이다.

``` text
SSH
├── SCP
└── SFTP

FTP
└── FTP Server (예: vsftpd)
```

> **SFTP = FTP에 단순히 보안을 추가한 것**으로 이해하면 부정확하다.
> SFTP는 SSH 프로토콜 계열이다.

------------------------------------------------------------------------

## 4.2 주요 SFTP 명령어

  명령어       의미
  ------------ ----------------------
  `pwd`        원격 서버 현재 경로
  `lpwd`       로컬 현재 경로
  `ls`         원격 서버 목록
  `lls`        로컬 목록
  `cd`         원격 디렉터리 이동
  `lcd`        로컬 디렉터리 이동
  `get file`   원격 → 로컬 다운로드
  `put file`   로컬 → 원격 업로드
  `exit`       SFTP 종료

### 암기

``` text
l = local

pwd  ↔ lpwd
ls   ↔ lls
cd   ↔ lcd
```

------------------------------------------------------------------------

# 5. SCP / SFTP / FTP 비교

  -----------------------------------------------------------------------
  구분              SCP               SFTP              FTP
  ----------------- ----------------- ----------------- -----------------
  기반              SSH               SSH               FTP

  대표 기본 포트    TCP 22            TCP 22            TCP 21(제어)

  암호화            O                 O                 일반 FTP는 X

  사용 방식         명령 한 번으로    대화형 파일 관리  대화형 파일 전송
                    복사                                

  대표 명령         `scp`             `sftp`            `ftp`

  서버 예           SSH 서버          SSH 서버          vsftpd
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# 6. CentOS 6과 CentOS 7+ 서비스 관리 차이

## CentOS 6 계열

전통적으로 SysV init 기반 명령을 많이 사용했다.

``` bash
service vsftpd start
service vsftpd stop
service vsftpd restart
service vsftpd status
```

## CentOS 7+

systemd가 기본 서비스 관리자로 사용된다.

``` bash
systemctl start vsftpd
systemctl stop vsftpd
systemctl restart vsftpd
systemctl status vsftpd
```

부팅 시 자동 시작:

``` bash
systemctl enable vsftpd
```

자동 시작 해제:

``` bash
systemctl disable vsftpd
```

자동 시작 등록 + 즉시 실행:

``` bash
systemctl enable --now vsftpd
```

> `enable`은 부팅 시 자동 실행 설정, `start`는 현재 즉시 실행이다.
> `--now`를 사용하면 두 작업을 함께 수행한다.

------------------------------------------------------------------------

# 7. 데몬 실행 방식

## 7.1 Standalone 방식

서비스 데몬이 항상 실행된 상태로 직접 요청을 기다린다.

``` text
Client
  ↓
Service Daemon (항상 대기)
```

### 특징

-   요청에 빠르게 대응 가능
-   서비스 프로세스가 계속 실행됨
-   자주 사용하는 서버 서비스에 적합

------------------------------------------------------------------------

## 7.2 xinetd 방식

`xinetd`가 여러 서비스의 요청을 대신 감시하다가 요청이 들어오면 필요한
서버 프로그램을 실행한다.

``` text
Client
  ↓
xinetd
  ↓ 요청 발생
Service 실행
```

### 특징

-   서비스가 항상 실행될 필요가 없음
-   전통적인 on-demand 서비스 관리 방식
-   최신 배포판에서는 systemd가 많은 역할을 대체

------------------------------------------------------------------------

# 8. systemd

systemd는 최신 Linux 배포판에서 서비스와 시스템 초기화를 관리하는 핵심
시스템이다.

대표 명령:

``` bash
systemctl status 서비스명
systemctl start 서비스명
systemctl stop 서비스명
systemctl restart 서비스명
systemctl enable 서비스명
systemctl disable 서비스명
```

------------------------------------------------------------------------

## 8.1 `.service`와 `.socket`

### Service Unit

실제 서비스 프로세스의 실행과 상태를 관리한다.

``` text
vsftpd.service
ssh.service
```

### Socket Unit

특정 소켓을 systemd가 먼저 감시하고, 연결 요청이 들어오면 연계된
서비스를 활성화할 수 있다.

``` text
Client
   ↓
.socket가 요청 감시
   ↓
.service 활성화
```

이를 **socket activation**이라고 한다.

> 모든 서비스가 반드시 socket activation을 사용하는 것은 아니다.

확인 예:

``` bash
systemctl list-units --type=service
systemctl list-units --type=socket
```

------------------------------------------------------------------------

# 9. FTP 기본 개념

FTP(File Transfer Protocol)는 네트워크를 통해 파일을 송수신하기 위한
전통적인 프로토콜이다.

일반 FTP는 사용자 이름, 비밀번호, 데이터가 기본적으로 암호화되지
않으므로 보안이 필요한 환경에서는 SFTP/FTPS 등과 구분해야 한다.

### 대표 포트

-   TCP 21: 제어 연결
-   TCP 20: Active FTP 데이터 연결에서 전통적으로 사용

Passive FTP에서는 서버가 데이터 연결용 별도 포트를 열어 클라이언트가
접속한다.

------------------------------------------------------------------------

# 10. vsftpd

`vsftpd`는 Linux에서 널리 사용되는 FTP 서버 프로그램이다.

## 10.1 설치

``` bash
dnf install -y vsftpd
```

환경에 따라:

``` bash
yum install -y vsftpd
```

## 10.2 서비스 활성화

``` bash
systemctl enable --now vsftpd
```

확인:

``` bash
systemctl status vsftpd
```

정상:

``` text
Active: active (running)
```

------------------------------------------------------------------------

# 11. FTP 클라이언트 패키지

FTP 서버와 별개로 FTP 클라이언트 프로그램이 필요할 수 있다.

배포판/저장소에 따라 패키지 이름이 다를 수 있으므로 다음처럼 검색할 수
있다.

``` bash
dnf search ftp
```

설치된 패키지 확인:

``` bash
rpm -qa | grep -i ftp
```

------------------------------------------------------------------------

# 12. FTP 클라이언트 기본 사용

접속:

``` bash
ftp 서버IP
```

대표 명령:

  명령어           기능
  ---------------- --------------------
  `open`           FTP 서버 연결
  `user`           사용자 인증
  `ls` / `dir`     원격 파일 목록
  `pwd`            원격 현재 경로
  `cd`             원격 디렉터리 이동
  `lcd`            로컬 디렉터리 이동
  `get`            파일 다운로드
  `mget`           여러 파일 다운로드
  `put`            파일 업로드
  `mput`           여러 파일 업로드
  `binary`         바이너리 전송 모드
  `ascii`          ASCII 전송 모드
  `bye` / `quit`   연결 종료

------------------------------------------------------------------------

# 13. FTP 응답 코드

FTP 서버는 세 자리 숫자로 처리 결과를 전달한다.

## 첫 번째 숫자의 의미

  범위    의미
  ------- --------------------------
  `1xx`   작업 시작/진행 중
  `2xx`   성공
  `3xx`   추가 정보 또는 인증 필요
  `4xx`   일시적 실패
  `5xx`   영구적 실패/오류

대표적인 예:

``` text
220  Service ready
230  User logged in
331  Password required
425  Can't open data connection
530  Not logged in
550  Requested action not taken
```

> 응답 코드를 보면 FTP 접속·인증·파일 접근 문제를 빠르게 분류할 수 있다.

------------------------------------------------------------------------

# 14. 익명(Anonymous) FTP

익명 FTP는 별도의 일반 사용자 계정 대신 `anonymous` 등의 계정으로 접속할
수 있게 하는 방식이다.

vsftpd 설정 파일:

``` bash
/etc/vsftpd/vsftpd.conf
```

관련 대표 설정:

``` ini
anonymous_enable=YES
```

익명 접속을 금지하려면:

``` ini
anonymous_enable=NO
```

> 익명 업로드를 허용하는 설정은 보안 위험이 커질 수 있으므로 실습 목적과
> 운영 환경을 반드시 구분한다.

------------------------------------------------------------------------

# 15. vsftpd 주요 환경 설정

현재 기본 설정 예:

``` ini
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
xferlog_std_format=YES
listen=NO
listen_ipv6=YES
pam_service_name=vsftpd
userlist_enable=YES
```

## 주요 옵션

### `anonymous_enable`

``` ini
anonymous_enable=NO
```

익명 사용자 접속 허용 여부.

### `local_enable`

``` ini
local_enable=YES
```

로컬 Linux 사용자 계정의 FTP 로그인을 허용한다.

### `write_enable`

``` ini
write_enable=YES
```

쓰기 관련 FTP 명령을 허용한다.

### `local_umask`

``` ini
local_umask=022
```

로컬 사용자가 생성하는 파일의 기본 권한 계산에 사용되는 umask.

### `xferlog_enable`

``` ini
xferlog_enable=YES
```

파일 전송 로그를 활성화한다.

### `listen` / `listen_ipv6`

``` ini
listen=NO
listen_ipv6=YES
```

vsftpd가 어떤 방식으로 리스닝할지 지정하는 설정이다. 환경에 맞게
구성하며 두 옵션의 의미와 네트워크 스택 상태를 함께 확인한다.

### `pam_service_name`

``` ini
pam_service_name=vsftpd
```

인증에 사용할 PAM 서비스 이름.

### `userlist_enable`

``` ini
userlist_enable=YES
```

사용자 목록 기반 접근 제어 기능을 활성화한다.

------------------------------------------------------------------------

# 16. 실전 Troubleshooting --- vsftpd 시작 실패 💀

## 증상

``` bash
systemctl enable --now vsftpd
```

실행 시:

``` text
Job for vsftpd.service failed because the control process exited with error code.
```

상태 확인:

``` bash
systemctl status vsftpd
```

``` text
Active: failed (Result: exit-code)
```

------------------------------------------------------------------------

## 16.1 로그 확인

``` bash
journalctl -xeu vsftpd.service
```

또는:

``` bash
journalctl -u vsftpd.service -n 50 --no-pager
```

------------------------------------------------------------------------

## 16.2 설정 파일 확인

``` bash
ls -l /etc/vsftpd/vsftpd.conf
```

설정에서 주석과 빈 줄 제외:

``` bash
grep -v '^#' /etc/vsftpd/vsftpd.conf | grep -v '^$'
```

패키지 파일 확인:

``` bash
rpm -ql vsftpd | grep vsftpd.conf
```

설정 파일이 실제로 유실된 실습 환경이라면 패키지 재설치를 고려할 수
있다.

``` bash
dnf reinstall -y vsftpd
```

> 단, 재설치는 모든 서비스 시작 실패의 만능 해결책이 아니다. 기존 설정
> 보존, 포트 충돌, 실행 중인 프로세스 등 다른 원인이 있을 수 있다.

------------------------------------------------------------------------

## 16.3 TCP 21번 포트 점유 확인

실제 문제 해결의 핵심:

``` bash
ss -lntp | grep ':21'
```

실습 당시 결과:

``` text
LISTEN ... *:21 ... users:(("vsftpd",pid=3595,fd=3))
```

이미 다른 `vsftpd` 프로세스가 TCP 21번을 점유하고 있었다.

프로세스 확인:

``` bash
ps -fp 3595
```

결과:

``` text
root 3595 1 ... /usr/sbin/vsftpd /etc/vsftpd/vsftpd.conf
```

즉 기존 vsftpd 프로세스가 이미 동작하고 있어 systemd가 새로운 vsftpd
인스턴스를 정상적으로 시작하지 못한 상황이었다.

------------------------------------------------------------------------

## 16.4 기존 프로세스 종료

``` bash
kill 3595
```

확인:

``` bash
ps -fp 3595
ss -lntp | grep ':21'
```

출력이 없다면 프로세스가 종료되고 21번 포트가 비워진 것이다.

------------------------------------------------------------------------

## 16.5 systemd를 통한 정상 실행

``` bash
systemctl start vsftpd
systemctl status vsftpd
```

최종 결과:

``` text
Active: active (running)
ExecStart=... status=0/SUCCESS
```

자동 시작 여부:

``` bash
systemctl is-enabled vsftpd
```

------------------------------------------------------------------------

## 16.6 트러블슈팅 흐름 암기

``` text
서비스 시작 실패
      ↓
systemctl status
      ↓
journalctl
      ↓
설정 파일 확인
      ↓
포트 점유 확인 (ss)
      ↓
PID 확인 (ps)
      ↓
불필요한 기존 프로세스 종료
      ↓
systemctl start
      ↓
Active: active (running)
```

### 핵심 교훈

> 서비스가 시작되지 않을 때 패키지 재설치만 반복하지 말고 **로그 → 설정
> → 포트 → 프로세스** 순으로 확인한다.

------------------------------------------------------------------------

# 17. 명령어 핵심 암기표

``` bash
# SCP 로컬 → 원격
scp file root@IP:/tmp

# SCP 원격 → 로컬
scp root@IP:/path/file /tmp

# SCP 디렉터리
scp -r directory root@IP:/tmp

# SCP SSH 포트 지정
scp -P 22 file root@IP:/tmp

# SFTP
sftp root@IP

# 서비스 상태
systemctl status vsftpd

# 시작 / 중지 / 재시작
systemctl start vsftpd
systemctl stop vsftpd
systemctl restart vsftpd

# 부팅 자동 시작
systemctl enable vsftpd

# 자동 시작 + 즉시 실행
systemctl enable --now vsftpd

# 로그
journalctl -xeu vsftpd.service

# 포트 확인
ss -lntp | grep ':21'

# 프로세스 확인
ps -fp PID
```

------------------------------------------------------------------------

# 18. 시험/면접형 체크포인트

### Q1. SCP와 SFTP는 어떤 프로토콜을 기반으로 하는가?

**A. SSH**

### Q2. SCP에서 SSH 포트를 지정하는 옵션은?

**A. `-P` (대문자)**

### Q3. 디렉터리를 SCP로 복사할 때 필요한 옵션은?

**A. `-r`**

### Q4. SFTP의 `pwd`와 `lpwd` 차이는?

**A. `pwd`는 원격 경로, `lpwd`는 로컬 경로**

### Q5. FTP와 SFTP는 같은 계열인가?

**A. 아니다. FTP는 FTP 프로토콜, SFTP는 SSH 기반이다.**

### Q6. CentOS 7 이후 대표적인 서비스 관리 명령은?

**A. `systemctl`**

### Q7. `systemctl enable`과 `start`의 차이는?

**A. `enable`은 부팅 시 자동 시작 설정, `start`는 현재 즉시 시작**

### Q8. Standalone 방식이란?

**A. 서비스 데몬이 계속 실행되면서 직접 요청을 기다리는 방식**

### Q9. systemd의 service unit과 socket unit 차이는?

**A. service는 실제 프로세스를 관리하고, socket은 소켓을 감시해 필요할
때 서비스를 활성화할 수 있다.**

### Q10. vsftpd 시작 실패 시 무엇부터 확인할까?

**A. `systemctl status`와 `journalctl`로 로그를 확인한 뒤
설정·포트·프로세스를 점검한다.**

------------------------------------------------------------------------

# 19. 오늘의 핵심 한 장 요약

``` text
[원격 파일 전송]

SSH ─┬─ SCP  → 빠른 파일/디렉터리 복사
     └─ SFTP → 대화형 파일 관리

FTP ─── vsftpd
       ├─ TCP 21 제어 연결
       ├─ FTP 응답 코드
       ├─ 일반/익명 사용자
       └─ /etc/vsftpd/vsftpd.conf


[서비스 관리의 변화]

CentOS 6
   ↓
service / SysV init

CentOS 7+
   ↓
systemd
├─ systemctl
├─ .service
└─ .socket


[장애 대응]

FAILED
 ↓
status
 ↓
journalctl
 ↓
설정 확인
 ↓
ss -lntp
 ↓
ps
 ↓
원인 제거
 ↓
systemctl start
 ↓
ACTIVE 😎
```

------------------------------------------------------------------------

## 마무리

오늘 학습의 핵심은 단순히 `scp`, `sftp`, `ftp` 명령어를 외우는 데 있지
않다.

**원격 파일 전송 → 서비스 실행 방식 → systemd → FTP 서버 구축 →
포트/프로세스 기반 장애 분석**이 하나의 흐름으로 연결된다.

특히 vsftpd 장애 실습에서 확인한 다음 패턴은 다른 Linux 서비스에도
그대로 응용할 수 있다.

``` text
로그 확인 → 설정 확인 → 포트 확인 → 프로세스 확인 → 서비스 재시작
```

🐧 **명령어를 외우는 단계에서, 서비스가 왜 동작하고 왜 실패하는지를
추적하는 단계로 넘어가는 것이 핵심이다.**