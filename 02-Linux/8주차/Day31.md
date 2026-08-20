# Linux Backup, Scheduling & Network Management 실습 정리

> **범위:** 완전/증분/차등 백업 → `tar -g` → `atd`/`crond` →
> NetworkManager → `nmcli`/`nmtui` → DNS/hosts → 네트워크 점검 →
> Telnet/Wireshark → SSH\
> **환경:** CentOS/RHEL 계열 + VMware 실습 기준

------------------------------------------------------------------------

## 0. 오늘 수업 전체 흐름

``` text
[오전]
백업
├─ 완전 백업 (Full)
├─ 증분 백업 (Incremental)
├─ 차등 백업 (Differential)
└─ tar -g + snapshot 파일

작업 예약
├─ at / atd      → 한 번만 실행
└─ cron / crond  → 반복 실행

[오후]
NetworkManager
├─ /etc/NetworkManager/
├─ ens33
├─ nmcli
├─ nmtui
└─ nm-connection-editor
        ↓
IP / Gateway / DNS 설정
        ↓
/etc/resolv.conf
/etc/hosts
        ↓
NetworkManager 재시작 / 연결 활성화
        ↓
netstat 등으로 네트워크 상태 확인
        ↓
Telnet
        ↓
Wireshark로 평문 확인
        ↓
SSH로 안전한 원격 접속
```

------------------------------------------------------------------------

# Part 1. Linux Backup

## 1. 완전 백업 (Full Backup)

전체 데이터를 모두 백업하는 방식이다.

### 특징

-   복구가 가장 단순하다.
-   백업 시간이 오래 걸릴 수 있다.
-   백업 저장 공간을 많이 사용한다.
-   증분/차등 백업의 기준점이 된다.

### 예시

월요일에 `X`, `Y`, `Z`가 존재한다고 가정한다.

``` bash
mkdir /backup
mkdir test
cd test

touch X Y Z
ls
```

출력 예:

``` text
X  Y  Z
```

------------------------------------------------------------------------

## 2. GNU tar의 snapshot을 이용한 증분 백업

### 최초 백업

``` bash
tar -g /backup/backup.list -cf /backup/file0.tar *
```

### 옵션 해석

  옵션        의미
  ----------- -------------------------------------------------
  `-g FILE`   GNU tar의 listed-incremental snapshot 파일 사용
  `-c`        새로운 tar archive 생성
  `-f FILE`   archive 파일 이름 지정
  `*`         현재 디렉터리에서 shell glob에 매칭되는 항목

> **주의:** `*`는 shell glob이므로 일반적으로 숨김 파일(`.file`)은
> 포함하지 않는다. 실제 전체 디렉터리를 백업하려면 백업 대상 지정 방식을
> 신중하게 선택한다.

생성 결과 확인:

``` bash
ls /backup
```

예:

``` text
backup.list  file0.tar
```

tar 내부 확인:

``` bash
tar -tf /backup/file0.tar
```

`file0.tar`는 최초 실행이므로 사실상 **Level 0(전체) 백업** 역할을 한다.

------------------------------------------------------------------------

## 3. backup.list의 역할

``` bash
cat /backup/backup.list
```

`backup.list`는 백업 데이터 자체가 아니라 GNU tar가 다음
listed-incremental 백업에서 참고하는 **snapshot 상태 정보**이다.

즉:

``` text
file0.tar
→ 실제 백업 데이터

backup.list
→ 이전 백업 시점의 상태를 기억하기 위한 정보
```

### Unix timestamp 확인

실습에서 snapshot에 나타난 epoch 값을 사람이 읽을 수 있는 시간으로
확인할 수 있다.

``` bash
date -d "1970-01-01 UTC 1787188246sec"
```

Unix epoch의 기준은:

``` text
1970-01-01 00:00:00 UTC
```

이다.

------------------------------------------------------------------------

# Part 2. 증분 백업 (Incremental Backup)

## 4. 핵심 개념

**직전 백업 이후 변경된 데이터**를 백업한다.

월요일 Full 이후 매일 파일을 하나씩 생성한다고 가정한다.

``` text
월 : X Y Z → Full
화 : A 추가
수 : B 추가
목 : C 추가
금 : D 추가
토 : E 추가
일 : F 추가
```

GNU tar 실습에서는 같은 snapshot 파일을 계속 사용한다.

### 화요일

``` bash
touch A
ls

tar -g /backup/backup.list -cf /backup/file1.tar *
tar -tf /backup/file1.tar
```

### 수요일

``` bash
touch B

tar -g /backup/backup.list -cf /backup/file2.tar *
tar -tf /backup/file2.tar
```

### 목요일

``` bash
touch C

tar -g /backup/backup.list -cf /backup/file3.tar *
tar -tf /backup/file3.tar
```

### 금요일

``` bash
touch D

tar -g /backup/backup.list -cf /backup/file4.tar *
tar -tf /backup/file4.tar
```

### 토요일

``` bash
touch E

tar -g /backup/backup.list -cf /backup/file5.tar *
tar -tf /backup/file5.tar
```

### 일요일

``` bash
touch F

tar -g /backup/backup.list -cf /backup/file6.tar *
tar -tf /backup/file6.tar
```

개념적으로:

``` text
file0.tar → X Y Z (Full)
file1.tar → 화요일 변경분
file2.tar → 수요일 변경분
file3.tar → 목요일 변경분
file4.tar → 금요일 변경분
file5.tar → 토요일 변경분
file6.tar → 일요일 변경분
```

> GNU tar의 listed-incremental archive에는 변경 파일뿐 아니라 디렉터리
> 관련 메타데이터 등이 표시될 수 있으므로 `tar -tf` 결과가 새 파일
> 하나만 정확히 표시된다고 단정하면 안 된다.

### 장점

-   매일 백업해야 할 데이터가 상대적으로 작다.
-   백업 속도가 빠르다.
-   저장 공간을 절약할 수 있다.

### 단점

최신 상태까지 복구하려면:

``` text
file0
 ↓
file1
 ↓
file2
 ↓
file3
 ↓
file4
 ↓
file5
 ↓
file6
```

처럼 **전체 백업 + 이후 증분 백업들을 순서대로** 적용해야 한다.

> 암기: **증분 = 직전 백업 이후 변경분**

------------------------------------------------------------------------

# Part 3. 차등 백업 (Differential Backup)

## 5. 핵심 개념

**마지막 완전 백업 이후 변경된 모든 데이터**를 매번 백업한다.

``` text
월 Full : X Y Z

화 차등 : A
수 차등 : A B
목 차등 : A B C
금 차등 : A B C D
토 차등 : A B C D E
일 차등 : A B C D E F
```

증분과 비교:

  요일   증분    차등
  ------ ------- -------------
  월     X Y Z   X Y Z
  화     A       A
  수     B       A B
  목     C       A B C
  금     D       A B C D
  토     E       A B C D E
  일     F       A B C D E F

일요일 시점 복구:

### 증분

``` text
Full + 화 + 수 + 목 + 금 + 토 + 일
```

### 차등

``` text
Full + 가장 최근 차등 백업
```

즉:

``` text
file0 + 일요일 Differential
```

이면 된다.

### 장단점

  방식           백업 속도/용량       복구
  -------------- -------------------- -------------
  Full           가장 큼              가장 단순
  Incremental    가장 작음            가장 복잡
  Differential   시간이 갈수록 커짐   비교적 단순

> 암기:
>
> **완전 = 전부**\
> **증분 = 직전 백업 이후**\
> **차등 = 마지막 Full 이후**

### tar -g 관련 주의

같은 snapshot 파일을 계속 갱신하면 GNU tar listed-incremental 방식이
된다.\
**차등 백업을 구현하려면 기준 snapshot을 Full 시점으로 유지하는 별도
설계가 필요하다.**

즉, `tar -g` 명령 하나가 자동으로 "차등 백업 모드"를 제공한다고 생각하면
안 된다.

------------------------------------------------------------------------

# Part 4. 작업 예약 --- atd

## 6. at / atd

`at`은 **지정한 미래 시각에 한 번만 실행할 작업**을 예약한다.

``` text
atd = at 작업을 실제로 처리하는 daemon
at  = 사용자가 작업을 등록하는 명령
```

상태 확인:

``` bash
systemctl status atd
```

시작:

``` bash
systemctl start atd
```

부팅 시 자동 시작:

``` bash
systemctl enable atd
```

### 작업 등록 예

``` bash
at 23:00
```

이후:

``` text
at> tar -cf /backup/backup.tar /home
at> Ctrl+D
```

→ 지정한 시간에 한 번 실행한다.

### 작업 확인

``` bash
atq
```

### 작업 삭제

``` bash
atrm 작업번호
```

### 핵심

``` text
atd
→ "오늘 밤 11시에 딱 한 번 실행해."
```

------------------------------------------------------------------------

# Part 5. 작업 예약 --- crond

## 7. cron / crond

`cron`은 **반복 작업 예약**에 사용한다.

``` text
crond = 예약 작업을 처리하는 daemon
crontab = 사용자의 cron 작업을 관리하는 명령
```

상태 확인:

``` bash
systemctl status crond
```

시작/자동 시작:

``` bash
systemctl start crond
systemctl enable crond
```

사용자 crontab 편집:

``` bash
crontab -e
```

등록 내용 확인:

``` bash
crontab -l
```

### cron 형식

``` text
분  시  일  월  요일  명령어
```

예:

``` text
0 2 * * * /root/backup.sh
```

의미:

``` text
매일 02:00에 /root/backup.sh 실행
```

각 필드:

  필드   일반적인 범위
  ------ ---------------------
  분     0\~59
  시     0\~23
  일     1\~31
  월     1\~12
  요일   0\~7 (0/7 = 일요일)

> **at = 한 번 / cron = 반복**

### 백업과 cron 연결

``` text
tar / rsync 등
      ↓
backup.sh
      ↓
crontab
      ↓
자동 백업
```

실제 운영에서는 백업 성공 여부, 로그, 보관 주기(retention), 원격 저장소,
실패 알림까지 함께 설계해야 한다.

------------------------------------------------------------------------

# Part 6. Linux NetworkManager

## 8. NetworkManager란?

Linux에서 네트워크 연결을 관리하는 서비스이다.

대표적으로 관리하는 내용:

-   NIC
-   IPv4/IPv6
-   IP 주소
-   Prefix
-   Gateway
-   DNS
-   connection profile

관련 디렉터리:

``` bash
/etc/NetworkManager/
```

CentOS/RHEL 버전에 따라 connection profile 저장 위치와 형식은 달라질 수
있다.

------------------------------------------------------------------------

# Part 7. ens33

## 9. ens33이란?

VMware Linux VM에서 흔히 볼 수 있는 **네트워크 인터페이스 이름**이다.

확인 예:

``` bash
ip addr
```

또는:

``` bash
ip link
```

개념:

``` text
VMware 가상 NIC
      ↓
Linux
      ↓
ens33
```

> 환경에 따라 이름은 `ens33`이 아닐 수도 있다.

------------------------------------------------------------------------

# Part 8. NetworkManager를 조작하는 방법

## 10. nmcli / nmtui / nm-connection-editor

``` text
               NetworkManager
                     │
       ┌─────────────┼─────────────┐
       ↓             ↓             ↓
     nmcli          nmtui     nm-connection-editor
      CLI            TUI             GUI
```

### nmcli

Command Line Interface.

``` bash
nmcli
```

서버/터미널 환경에서 매우 중요하다.

### nmtui

텍스트 기반 UI:

``` bash
nmtui
```

키보드로 메뉴를 선택하면서 설정할 수 있다.

### nm-connection-editor

GUI 기반 NetworkManager connection editor:

``` bash
nm-connection-editor
```

VMware에서 Linux GUI 환경을 사용한다면 직접 실행해 설정할 수 있다.

> 셋은 별개의 네트워크 시스템이 아니라 **NetworkManager를 서로 다른
> 방식으로 조작하는 도구**라고 이해하면 쉽다.

------------------------------------------------------------------------

# Part 9. nmcli 핵심 명령어

## 11. connection 확인

전체 connection profile 확인:

``` bash
nmcli connection show
```

특정 connection 확인:

``` bash
nmcli connection show ens33
```

IPv4 설정만 필터링:

``` bash
nmcli connection show ens33 | grep ipv4
```

> 여기서 `ens33`이 실제 connection profile 이름인지 확인한다. device
> 이름과 connection profile 이름은 항상 같다고 보장되지 않는다.

------------------------------------------------------------------------

## 12. 정적 IP 설정

예:

``` bash
nmcli connection modify ens33 ipv4.addresses 192.168.2.100/24
```

의미:

``` text
ens33 connection profile의
IPv4 주소를
192.168.2.100/24로 설정
```

정적 주소를 사용하려면 보통 다음과 같이 manual method도 설정한다.

``` bash
nmcli connection modify ens33 ipv4.method manual
```

Gateway 예:

``` bash
nmcli connection modify ens33 ipv4.gateway 192.168.2.254
```

DNS 예:

``` bash
nmcli connection modify ens33 ipv4.dns "8.8.8.8"
```

설정 후 connection 활성화:

``` bash
nmcli connection up ens33
```

> 원격 SSH 서버에서 IP/Gateway를 변경하면 현재 접속이 끊길 수 있다. 실습
> VM 콘솔에서는 비교적 복구가 쉽지만 운영 서버에서는 특히 주의한다.

------------------------------------------------------------------------

# Part 10. /etc/resolv.conf

## 13. DNS resolver 설정

확인:

``` bash
cat /etc/resolv.conf
```

예:

``` text
nameserver 8.8.8.8
```

DNS 이름 해석에 사용할 resolver 정보가 나타난다.

다만 NetworkManager가 관리하는 시스템에서는 `/etc/resolv.conf`가 자동
생성/갱신될 수 있다.

따라서 무조건 직접 수정하는 것보다 NetworkManager connection 설정을 통해
DNS를 지정하는 방법을 이해해야 한다.

``` bash
nmcli connection modify ens33 ipv4.dns "8.8.8.8"
```

------------------------------------------------------------------------

# Part 11. /etc/hosts

## 14. 로컬 hostname ↔ IP 매핑

``` bash
cat /etc/hosts
```

예:

``` text
192.168.2.100 server1
192.168.2.101 server2
```

그러면 해당 Linux 시스템에서 `server1`이라는 이름을 `192.168.2.100`과
연결하여 사용할 수 있다.

``` text
/etc/hosts
→ 로컬 정적 이름 매핑

DNS
→ DNS 서버를 통한 이름 해석
```

------------------------------------------------------------------------

# Part 12. NetworkManager 설정 적용

## 15. 서비스 재시작 + connection 활성화

실습 명령:

``` bash
systemctl restart NetworkManager.service && nmcli connection up ens33
```

분해:

``` bash
systemctl restart NetworkManager.service
```

→ NetworkManager 서비스 재시작

``` bash
&&
```

→ 앞 명령이 성공했을 때만 뒤 명령 실행

``` bash
nmcli connection up ens33
```

→ 해당 connection profile 활성화

따라서 전체 의미:

``` text
NetworkManager 재시작 성공
          ↓
ens33 connection 활성화
```

> 단순 설정 변경마다 NetworkManager 전체를 재시작할 필요는 없다. 실습
> 절차와 실제 운영 절차를 구분한다. connection을 다시 올리는 것만으로
> 적용 가능한 경우도 많다.

------------------------------------------------------------------------

# Part 13. 네트워크 확인 명령

## 16. IP 확인

``` bash
ip addr
```

특정 인터페이스:

``` bash
ip addr show ens33
```

------------------------------------------------------------------------

## 17. Route 확인

``` bash
ip route
```

예:

``` text
default via 192.168.2.254 dev ens33
```

→ 기본 Gateway가 `192.168.2.254`

------------------------------------------------------------------------

## 18. netstat

네트워크 연결/포트 상태를 확인하는 전통적인 명령이다.

예:

``` bash
netstat -antp
```

주요 옵션:

  옵션   의미
  ------ -------------------------
  `-a`   모든 socket
  `-n`   주소/포트를 숫자로 표시
  `-t`   TCP
  `-p`   프로세스 정보 표시

> 최신 Linux에서는 `ss`가 `netstat`을 대체하는 방향이므로 함께 알아두면
> 좋다.

예:

``` bash
ss -antp
```

------------------------------------------------------------------------

# Part 14. Telnet

## 19. 설치

CentOS/RHEL 계열 실습 예:

``` bash
yum -y install telnet-server telnet
```

-   `telnet-server` → Telnet 서버
-   `telnet` → Telnet client

> 배포판/버전에 따라 저장소 제공 여부와 서비스 구성 방식이 다를 수 있다.

Telnet의 대표 포트:

``` text
TCP 23
```

### 가장 중요한 특징

**Telnet은 통신을 암호화하지 않는다.**

``` text
Client
   │
   │ 평문 통신
   ↓
Telnet Server
```

따라서 현대 환경에서 서버 관리용 원격 접속 수단으로 사용하면 안 된다.

실습에서는 **왜 Telnet이 위험한지 이해하기 위한 교육 목적**으로 매우
유용하다.

------------------------------------------------------------------------

# Part 15. Wireshark와 Telnet

## 20. 왜 같이 실습하는가?

Telnet 통신을 발생시킨 뒤 Wireshark로 패킷을 캡처하면:

``` text
Telnet
 ↓
암호화되지 않은 데이터
 ↓
Wireshark 캡처
 ↓
통신 내용 관찰 가능
```

이라는 구조를 직접 확인할 수 있다.

즉:

> **"Telnet은 평문이라 위험하다"를 암기하는 것이 아니라 패킷에서 직접
> 확인하는 실습**

이다.

⚠️ Wireshark 캡처는 반드시 본인이 관리하거나 실습 허가를 받은
네트워크에서 수행한다.

------------------------------------------------------------------------

# Part 16. SSH

## 21. SSH란?

**Secure Shell**

네트워크를 통해 안전하게 원격 시스템에 접속하기 위한 대표적인
프로토콜이다.

대표 포트:

``` text
TCP 22
```

접속 기본 형태:

``` bash
ssh 사용자명@서버IP
```

예:

``` bash
ssh root@192.168.2.100
```

### Telnet vs SSH

  구분            Telnet                 SSH
  --------------- ---------------------- ----------------------
  기본 TCP 포트   23                     22
  암호화          X                      O
  원격 관리       현대 환경에서 비권장   일반적으로 사용
  교육 목적       평문 위험 확인         안전한 원격접속 이해

``` text
Telnet
→ 평문
→ Wireshark로 위험성 확인
→ "그래서 SSH를 쓴다!"

SSH
→ 암호화된 통신
→ 안전한 원격 관리
```

------------------------------------------------------------------------

# Part 17. 오늘 수업을 하나로 연결하기

## 22. 오전

``` text
데이터가 있다
   ↓
백업해야 한다
   ↓
Full / Incremental / Differential
   ↓
매번 사람이 실행하기 귀찮다
   ↓
at / cron
   ↓
백업 자동화
```

## 23. 오후

``` text
서버가 있다
   ↓
네트워크 설정 필요
   ↓
NetworkManager
   ↓
nmcli / nmtui / nm-connection-editor
   ↓
IP / Gateway / DNS
   ↓
/etc/resolv.conf + /etc/hosts
   ↓
ip / netstat / ss 등으로 확인
   ↓
원격 접속 필요
   ↓
Telnet
   ↓
Wireshark
   ↓
평문 위험 확인 💀
   ↓
SSH 🔐
```

------------------------------------------------------------------------

# Part 18. 시험/복습용 초압축 암기표

  키워드                   한 줄 암기
  ------------------------ ------------------------------------------
  Full                     전체를 백업
  Incremental              직전 백업 이후 변경분
  Differential             마지막 Full 이후 변경분
  `tar -g`                 GNU tar listed-incremental snapshot 사용
  `backup.list`            증분 판단을 위한 snapshot 정보
  `at`                     한 번 실행
  `atd`                    at 작업 처리 daemon
  `cron`                   반복 실행
  `crond`                  cron 작업 처리 daemon
  NetworkManager           네트워크 연결 관리
  `ens33`                  VMware VM에서 흔한 NIC 이름
  `nmcli`                  NetworkManager CLI
  `nmtui`                  NetworkManager TUI
  `nm-connection-editor`   NetworkManager GUI
  `/etc/resolv.conf`       DNS resolver 관련 설정
  `/etc/hosts`             로컬 hostname/IP 매핑
  `netstat`                전통적인 연결/포트 확인
  `ss`                     현대 Linux에서 권장되는 socket 확인 도구
  Telnet                   TCP 23 / 평문
  SSH                      TCP 22 / 암호화
  Wireshark                패킷 캡처/분석

------------------------------------------------------------------------

# Part 19. 자주 헷갈리는 포인트 💀

## Q1. `backup.list`가 실제 백업 파일인가?

**아니다.**

``` text
backup.list = snapshot 정보
fileN.tar   = 실제 archive
```

------------------------------------------------------------------------

## Q2. 증분과 차등의 가장 큰 차이는?

``` text
증분 → 직전 백업 기준
차등 → 마지막 Full 기준
```

------------------------------------------------------------------------

## Q3. at과 cron의 차이는?

``` text
at   → 한 번
cron → 반복
```

------------------------------------------------------------------------

## Q4. nmcli와 nmtui는 서로 다른 네트워크 시스템인가?

아니다.

둘 다 **NetworkManager를 조작하는 frontend**라고 이해하면 된다.

------------------------------------------------------------------------

## Q5. ens33은 무조건 존재하는가?

아니다.

VM/배포판/장치 구성에 따라 인터페이스 이름은 달라질 수 있다.

------------------------------------------------------------------------

## Q6. `/etc/resolv.conf`를 직접 수정하면 끝인가?

NetworkManager가 관리하는 환경에서는 자동으로 다시 생성될 수 있다.

따라서 NetworkManager 설정과의 관계를 반드시 이해한다.

------------------------------------------------------------------------

## Q7. Telnet을 실제 서버 원격 관리에 사용해도 되는가?

권장하지 않는다.

평문 통신이므로 **SSH를 사용한다.**

------------------------------------------------------------------------

## Q8. `netstat`만 외우면 되는가?

수업 명령으로는 중요하지만 현대 Linux에서는 다음도 기억한다.

``` bash
ss -antp
```

------------------------------------------------------------------------

# Part 20. 실습 점검 순서

네트워크가 안 될 때 무작정 NetworkManager부터 재시작하지 말고 아래처럼
확인한다.

``` text
1. NIC 존재/상태
   ↓
2. IP 주소
   ↓
3. Routing / Gateway
   ↓
4. Ping
   ↓
5. DNS 설정
   ↓
6. 이름 해석
   ↓
7. Listening port
   ↓
8. 서비스 상태
   ↓
9. Firewall 등 추가 확인
```

대표 명령:

``` bash
ip addr
ip route
ping <IP>
cat /etc/resolv.conf
cat /etc/hosts
nmcli connection show
nmcli device status
ss -antp
systemctl status <service>
```

------------------------------------------------------------------------

# Part 21. 최종 한 장 요약

``` text
┌─────────────────────────────────────────────┐
│               Linux Server                 │
├─────────────────────────────────────────────┤
│ BACKUP                                      │
│ Full → 전체                                │
│ Incremental → 직전 백업 이후               │
│ Differential → 마지막 Full 이후            │
│ tar -g → snapshot 기반 listed-incremental  │
├─────────────────────────────────────────────┤
│ SCHEDULING                                  │
│ atd   → 1회성                              │
│ crond → 반복                               │
├─────────────────────────────────────────────┤
│ NETWORK                                     │
│ NetworkManager                              │
│ ├─ nmcli                                    │
│ ├─ nmtui                                    │
│ └─ nm-connection-editor                     │
│                                             │
│ ens33 → IP / Gateway / DNS                  │
│ /etc/resolv.conf → DNS resolver             │
│ /etc/hosts → Local name mapping             │
├─────────────────────────────────────────────┤
│ REMOTE                                      │
│ Telnet : TCP 23 / 평문 💀                   │
│ Wireshark : 패킷 분석                       │
│ SSH : TCP 22 / 암호화 🔐                    │
└─────────────────────────────────────────────┘
```

------------------------------------------------------------------------

# 마지막 암기

``` text
Full = 전부
증분 = 직전부터
차등 = Full부터

at = 한 번
cron = 반복

nmcli = CLI
nmtui = TUI
nm-connection-editor = GUI

resolv.conf = DNS resolver
hosts = 로컬 이름 매핑

Telnet = 23 + 평문
SSH = 22 + 암호화
```

> 🐧 **백업하고 → 예약하고 → 네트워크 잡고 → 연결 확인하고 → Telnet의
> 위험성을 보고 → SSH로 넘어간다.**
>
> 이 흐름을 이해하면 오늘 배운 명령어들이 서로 떨어진 암기 과목이 아니라
> 하나의 **Linux 서버 운영 과정**으로 연결된다.