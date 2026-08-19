# 📦 Linux Package Management

> Linux에서 프로그램을 설치·삭제·업데이트하고 패키지 정보를 확인하는 방법을 정리한다.
> CentOS/RHEL 계열의 **RPM, YUM/DNF**를 중심으로 학습하고, **Repository**, 다운로드 도구인 **wget/curl/git**, Debian/Ubuntu 계열의 **APT/DPKG**까지 비교한다.

---

## 1. Linux 패키지 관리란?

Linux에서 프로그램은 일반적으로 **패키지(Package)** 형태로 배포된다.

패키지에는 프로그램 실행 파일뿐만 아니라 설정 파일, 라이브러리, 패키지 정보 등이 포함될 수 있다.

대표적인 Linux 계열별 패키지 관리 방식은 다음과 같다.

| 계열              | 패키지 형식 | 저수준 패키지 도구 | 저장소 기반 관리 도구 |
| --------------- | ------ | ---------- | ------------ |
| RHEL / CentOS   | `.rpm` | `rpm`      | `yum`, `dnf` |
| Debian / Ubuntu | `.deb` | `dpkg`     | `apt`        |

큰 구조로 보면 다음과 같다.

```text
RHEL / CentOS
.rpm
 └─ RPM
     ↑
 YUM / DNF
     ↓
 Repository


Debian / Ubuntu
.deb
 └─ DPKG
     ↑
    APT
     ↓
 Repository
```

---

# 2. RPM

## 2.1 RPM이란?

**RPM(RPM Package Manager)**은 RHEL/CentOS 계열에서 사용하는 패키지 관리 시스템이다.

`.rpm` 패키지 파일을 직접 이용하여 프로그램을 설치하거나 삭제하고 패키지 정보를 조회할 수 있다.

예:

```bash
vsftpd-버전정보.rpm
```

RPM의 중요한 특징은 **패키지 의존성을 자동으로 해결해 필요한 패키지를 저장소에서 설치해주는 도구가 아니라는 것**이다.

따라서 특정 프로그램이 다른 패키지를 필요로 한다면 사용자가 해당 의존성을 해결해야 할 수 있다.

---

# 3. RPM 패키지 설치

## 기본 형식

```bash
rpm -ivh 패키지파일.rpm
```

예:

```bash
rpm -ivh vsftpd-버전정보.rpm
```

옵션의 의미는 다음과 같다.

| 옵션   | 의미                       |
| ---- | ------------------------ |
| `-i` | install, 설치              |
| `-v` | verbose, 상세 정보 출력        |
| `-h` | hash, 설치 진행 상황을 `#`으로 표시 |

즉,

```bash
rpm -ivh
```

는

> **RPM 패키지를 설치하면서 진행 상황과 정보를 화면에 표시한다.**

라고 이해할 수 있다.

---

# 4. RPM 패키지 업그레이드

```bash
rpm -Uvh 패키지파일.rpm
```

`-U`는 Upgrade를 의미한다.

기존 패키지가 설치되어 있다면 업그레이드하고, 설치되어 있지 않다면 새로 설치할 수도 있다.

```text
rpm -ivh
   ↓
Install

rpm -Uvh
   ↓
Upgrade / Install
```

---

# 5. RPM 패키지 재설치

이미 설치된 RPM 패키지를 다시 설치해야 하는 상황이 발생할 수 있다.

RPM 버전에 따라 재설치 옵션 지원 여부가 다를 수 있으므로 실습 환경에서 사용하는 명령과 `rpm --help`를 확인하는 것이 안전하다.

YUM/DNF를 사용하는 환경에서는 다음과 같이 재설치할 수 있다.

```bash
yum reinstall vsftpd
```

또는

```bash
dnf reinstall vsftpd
```

---

# 6. RPM 패키지 삭제

```bash
rpm -e 패키지명
```

예:

```bash
rpm -e vsftpd
```

여기서 중요한 점은 **삭제할 때 RPM 파일 이름이 아니라 설치된 패키지 이름을 사용한다는 것**이다.

```text
설치
rpm -ivh vsftpd-버전정보.rpm

삭제
rpm -e vsftpd
```

---

# 7. RPM 패키지 정보 확인

## 전체 설치 패키지 확인

```bash
rpm -qa
```

* `-q` : Query
* `-a` : All

즉,

> 현재 시스템에 설치된 모든 RPM 패키지를 조회한다.

---

## 특정 패키지 검색

```bash
rpm -qa | grep vsftpd
```

전체 패키지 목록 중 `vsftpd`가 포함된 항목만 출력한다.

---

## 패키지 상세 정보 확인

```bash
rpm -qi vsftpd
```

`-i`는 Information을 의미한다.

패키지의 버전, 설명 등의 정보를 확인할 수 있다.

---

## 패키지가 설치한 파일 확인

```bash
rpm -ql vsftpd
```

`-l`은 List를 의미한다.

해당 패키지가 시스템에 설치한 파일 목록을 확인할 수 있다.

---

# 8. RPM 의존성 💀

RPM을 사용할 때 반드시 이해해야 하는 개념이 **Dependency(의존성)**이다.

예를 들어 `php` 패키지가 `php-common`의 기능을 필요로 한다고 가정한다.

```text
php
 │
 └── 필요
      ↓
 php-common
```

이 상태에서 필요한 의존 패키지가 없다면 RPM 설치 과정에서 오류가 발생할 수 있다.

```text
사용자
  │
  ↓
php 설치
  │
  ├─ 필요한 패키지 존재 → 설치 진행
  │
  └─ 필요한 패키지 없음
           ↓
      Dependency Error 💀
```

그리고 필요한 패키지를 직접 설치하려 했는데 그 패키지가 또 다른 패키지를 요구한다면 관리가 점점 복잡해질 수 있다.

```text
A 설치
 ↓
B 필요
 ↓
B 설치
 ↓
C 필요
 ↓
C 설치
 ↓
D 필요...

💀 Dependency Hell
```

이 문제를 훨씬 편하게 처리하기 위해 **YUM/DNF**와 같은 저장소 기반 패키지 관리 도구를 사용한다.

---

# 9. YUM / DNF

## YUM이란?

**YUM(Yellowdog Updater Modified)**은 RHEL/CentOS 계열에서 사용되어 온 저장소 기반 패키지 관리 도구이다.

RPM과 달리 Repository를 이용하여 필요한 패키지를 찾고 **의존성을 계산하여 함께 설치할 수 있다.**

최근 RHEL 계열에서는 `dnf`가 주로 사용되며, 일부 환경에서는 `yum` 명령이 DNF 기반으로 동작하기도 한다.

---

# 10. RPM vs YUM/DNF

## RPM

```text
사용자
 ↓
RPM 파일
 ↓
rpm
 ↓
설치
 ↓
의존성 문제 발생 가능
 ↓
사용자가 해결 💀
```

## YUM/DNF

```text
사용자
 ↓
yum install 패키지
 ↓
Repository 확인
 ↓
패키지 + 의존성 계산
 ↓
필요한 패키지 다운로드
 ↓
설치 😎
```

### 핵심 비교

| RPM             | YUM / DNF        |
| --------------- | ---------------- |
| `.rpm` 파일 직접 관리 | Repository 기반 관리 |
| 의존성 자동 해결에 제한   | 의존성 자동 해결        |
| 직접 파일 지정 가능     | 패키지 이름으로 설치 가능   |
| 저수준 패키지 관리      | 고수준 패키지 관리       |

---

# 11. YUM 패키지 설치

```bash
yum install vsftpd
```

자동 확인까지 진행하려면:

```bash
yum -y install vsftpd
```

`-y`는 설치 과정에서 나타나는 확인 질문에 자동으로 Yes를 선택한다.

---

# 12. YUM 패키지 재설치

```bash
yum reinstall vsftpd
```

또는:

```bash
yum -y reinstall vsftpd
```

설정이나 파일 손상 등의 이유로 패키지를 다시 설치할 때 사용할 수 있다.

---

# 13. YUM 패키지 삭제

```bash
yum remove vsftpd
```

자동 확인:

```bash
yum -y remove vsftpd
```

> ⚠️ `remove` 실행 시 관련 의존 패키지가 함께 제거될 가능성이 있으므로 삭제 목록을 확인하는 습관이 중요하다.

---

# 14. YUM 패키지 정보 확인

```bash
yum info vsftpd
```

패키지의 버전, Repository, 설명 등의 정보를 확인할 수 있다.

설치 가능한 패키지 검색:

```bash
yum search vsftpd
```

Repository 목록 확인:

```bash
yum repolist
```

---

# 15. Repository란?

**Repository(저장소)**는 Linux 패키지와 관련 메타데이터를 제공하는 저장 공간이다.

YUM/DNF는 Repository 정보를 이용하여 필요한 패키지를 찾는다.

```text
yum install vsftpd
        │
        ↓
Repository 설정 확인
        │
        ↓
패키지/메타데이터 검색
        │
        ↓
의존성 계산
        │
        ↓
다운로드
        │
        ↓
설치
```

---

# 16. Repository 설정 파일

CentOS/RHEL 계열에서는 일반적으로 다음 디렉터리에서 Repository 설정을 확인할 수 있다.

```bash
/etc/yum.repos.d/
```

확인:

```bash
ls -l /etc/yum.repos.d/
```

`.repo` 파일에는 Repository의 위치와 활성화 여부 등의 설정이 저장된다.

대표적인 항목은 다음과 같다.

```text
baseurl
mirrorlist
metalink
enabled
gpgcheck
```

---

# 17. baseurl / mirrorlist / metalink

## baseurl

특정 Repository 서버의 위치를 직접 지정한다.

```text
baseurl
   ↓
특정 Repository 주소
```

## mirrorlist

사용 가능한 여러 미러 서버 정보를 이용한다.

```text
mirrorlist
    ↓
여러 Mirror
    ↓
사용할 서버 선택
```

## metalink

Repository의 미러 정보와 검증에 활용할 수 있는 메타정보를 제공하는 방식이다.

```text
YUM / DNF
    ↓
metalink
    ↓
사용 가능한 Repository 정보
    ↓
패키지 다운로드
```

---

# 18. Vault Repository

CentOS의 특정 버전이 지원 종료(EOL)되면 기존 Mirror에서 패키지를 정상적으로 가져오지 못하는 상황이 발생할 수 있다.

이 경우 과거 버전의 패키지를 보관하는 **Vault Repository**를 사용해야 하는 상황이 생길 수 있다.

```text
기존 Repository
      ↓
지원 종료 / Mirror 변경
      ↓
yum 오류 💀
      ↓
Repository 설정 확인
      ↓
Vault Repository 검토
```

따라서 오래된 CentOS 실습 환경에서 YUM이 갑자기 동작하지 않는다면 네트워크 문제만 볼 것이 아니라 **OS 버전과 Repository 상태**도 확인해야 한다.

---

# 19. Repository 문제 발생 시 확인

```bash
yum repolist
```

Repository 설정 파일:

```bash
ls -l /etc/yum.repos.d/
```

설정 내용 확인:

```bash
cat /etc/yum.repos.d/*.repo
```

필요하면 다음 항목을 확인한다.

```text
baseurl
mirrorlist
metalink
enabled
```

---

# 20. wget

`wget`은 URL을 통해 파일을 다운로드할 때 사용할 수 있는 명령어이다.

```bash
wget URL
```

예:

```bash
wget https://example.com/file.rpm
```

기본적으로 다운로드한 파일을 현재 디렉터리에 저장한다.

```text
Internet
   ↓
 wget
   ↓
file.rpm
```

---

# 21. curl

`curl`은 URL을 이용하여 데이터를 송수신하는 도구이다.

파일 다운로드뿐만 아니라 HTTP 요청, API 테스트 등 다양한 목적으로 사용할 수 있다.

```bash
curl URL
```

파일 이름을 유지하여 저장:

```bash
curl -O URL
```

출력 파일 이름을 직접 지정:

```bash
curl -o 파일명 URL
```

예:

```bash
curl -o package.rpm https://example.com/package.rpm
```

---

# 22. wget vs curl

| wget          | curl                  |
| ------------- | --------------------- |
| 파일 다운로드에 편리   | 데이터 송수신 기능이 매우 다양     |
| 재귀 다운로드 기능 지원 | API/HTTP 테스트 등에 많이 사용 |
| 기본적으로 파일 저장   | 기본적으로 내용을 표준 출력       |
| 비교적 다운로드 중심   | 다양한 프로토콜 및 요청 처리      |

간단하게 기억하면:

```text
wget
→ "파일 받아줘!"

curl
→ "이 URL과 데이터를 주고받아줘!"
```

---

# 23. Git

Git은 단순한 파일 다운로드 프로그램이 아니라 **분산 버전 관리 시스템**이다.

원격 Git Repository를 복제할 때:

```bash
git clone 저장소주소
```

```text
Git Repository
      ↓
  git clone
      ↓
Repository 복제
      ↓
파일 + Git 이력
```

따라서 `wget`이나 `curl`과 달리 Repository의 파일뿐 아니라 Git 관리 정보와 커밋 이력 등을 함께 가져온다.

---

# 24. wget / curl / git 비교

| 도구     | 주요 목적                       |
| ------ | --------------------------- |
| `wget` | 파일 다운로드                     |
| `curl` | URL 기반 데이터 송수신 / API / 다운로드 |
| `git`  | Git Repository 복제 및 버전 관리   |

```text
파일 하나 받기
→ wget / curl

HTTP 요청/API 확인
→ curl

GitHub Repository 가져오기
→ git clone
```

---

# 25. Debian / Ubuntu 패키지 관리

CentOS/RHEL 계열에서 RPM과 YUM/DNF를 사용한다면 Debian/Ubuntu 계열에서는 주로 **DPKG와 APT**를 사용한다.

```text
RHEL / CentOS          Debian / Ubuntu
----------------------------------------
RPM            ←→     DPKG
YUM / DNF      ←→     APT
.rpm           ←→     .deb
```

---

# 26. APT 패키지 설치

실습 명령:

```bash
apt -y install net-tools iproute2 bind9-dnsutils iputils-ping curl
```

여러 패키지를 한 번에 설치하는 명령이다.

| 패키지              | 용도                               |
| ---------------- | -------------------------------- |
| `net-tools`      | `ifconfig`, `netstat`, `route` 등 |
| `iproute2`       | `ip`, `ss` 등                     |
| `bind9-dnsutils` | DNS 조회 관련 도구                     |
| `iputils-ping`   | `ping`                           |
| `curl`           | URL 요청 및 데이터 송수신                 |

`-y`는 설치 과정의 확인 질문에 자동으로 Yes를 선택한다.

---

# 27. net-tools vs iproute2

과거부터 사용된 `net-tools` 명령과 현대 Linux에서 주로 권장되는 `iproute2` 명령은 다음처럼 대응할 수 있다.

| net-tools  | iproute2   |
| ---------- | ---------- |
| `ifconfig` | `ip addr`  |
| `route`    | `ip route` |
| `netstat`  | `ss`       |

예:

```bash
ifconfig
```

대신:

```bash
ip addr
```

라우팅 테이블 확인:

```bash
ip route
```

소켓 정보 확인:

```bash
ss
```

---

# 28. DPKG 패키지 상태 확인

실습 명령:

```bash
dpkg -l net-tools iproute2 bind9-dnsutils iputils-ping curl
```

`dpkg -l`을 사용하면 지정한 패키지의 상태와 버전 등을 확인할 수 있다.

정상적으로 설치된 패키지에는 일반적으로 다음과 같이 `ii` 상태가 표시된다.

```text
ii
```

즉,

```text
apt로 패키지 설치
       ↓
dpkg -l로 상태 확인
```

이라는 흐름으로 이해할 수 있다.

---

# 29. 패키지가 설치한 파일 확인

```bash
dpkg -L net-tools
```

대문자 `L`을 사용한다.

해당 패키지가 시스템에 설치한 파일 목록을 확인한다.

CentOS/RHEL과 비교하면:

```text
RPM
rpm -ql 패키지명

DPKG
dpkg -L 패키지명
```

두 명령 모두

> **"이 패키지가 어떤 파일들을 설치했는가?"**

를 확인하는 용도로 사용할 수 있다.

---

# 30. grep / egrep을 이용한 결과 필터링

실습에서는 `dpkg -L`의 결과를 파이프로 전달하여 필요한 결과만 확인할 수도 있다.

기본 구조:

```bash
dpkg -L net-tools | egrep -v '패턴'
```

`-v`는 지정한 패턴과 일치하는 줄을 **제외**한다.

```text
dpkg -L
   ↓
전체 파일 목록
   ↓
PIPE |
   ↓
egrep -v
   ↓
특정 패턴 제외
   ↓
필요한 결과 확인
```

> ※ 실제 수업에서 사용한 `egrep -v` 뒤의 패턴은 실습 환경의 명령을 기준으로 확인한다.

---

# 31. CentOS ↔ Debian 패키지 관리 비교

| 작업        | RHEL / CentOS | Debian / Ubuntu |
| --------- | ------------- | --------------- |
| 패키지 형식    | `.rpm`        | `.deb`          |
| 저수준 관리    | `rpm`         | `dpkg`          |
| 고수준 관리    | `yum` / `dnf` | `apt`           |
| 패키지 설치    | `yum install` | `apt install`   |
| 삭제        | `yum remove`  | `apt remove`    |
| 설치 패키지 조회 | `rpm -qa`     | `dpkg -l`       |
| 패키지 정보    | `rpm -qi`     | `dpkg -s`       |
| 설치 파일 목록  | `rpm -ql`     | `dpkg -L`       |
| 의존성 관리    | YUM/DNF       | APT             |

---

# 32. 전체 구조 ⭐

오늘 학습의 가장 중요한 흐름은 다음과 같다.

```text
                    Linux Package Management
                              │
              ┌───────────────┴───────────────┐
              │                               │
        RHEL / CentOS                  Debian / Ubuntu
              │                               │
       ┌──────┴──────┐                 ┌──────┴──────┐
       │             │                 │             │
      RPM         YUM/DNF             DPKG          APT
       │             │                 │             │
    .rpm 직접      Repository        .deb 직접     Repository
      관리           기반 관리          관리          기반 관리
       │             │                 │             │
       └──────┬──────┘                 └──────┬──────┘
              │                               │
           패키지 관리                     패키지 관리
```

---

# 33. 핵심 암기 포인트 🔥

### RPM

```bash
rpm -ivh package.rpm
rpm -Uvh package.rpm
rpm -e package
rpm -qa
rpm -qi package
rpm -ql package
```

```text
i = Install
U = Upgrade
e = Erase
q = Query
a = All
i = Information
l = List
```

---

### YUM

```bash
yum install package
yum reinstall package
yum remove package
yum info package
yum search package
yum repolist
```

---

### Repository

```bash
/etc/yum.repos.d/
```

중요 키워드:

```text
baseurl
mirrorlist
metalink
Vault
Repository
```

---

### 다운로드

```bash
wget URL
curl -O URL
git clone Repository
```

---

### Debian / Ubuntu

```bash
apt -y install package

dpkg -l package
dpkg -L package
```

---

# 34. RPM 대신 YUM/DNF를 사용하는 이유 ⭐⭐⭐

면접이나 시험에서도 설명하기 좋은 핵심 내용이다.

**RPM**

```text
RPM 파일을 직접 설치
       ↓
의존성 문제가 발생할 수 있음
       ↓
사용자가 필요한 패키지를 직접 준비
```

**YUM/DNF**

```text
패키지 설치 요청
       ↓
Repository 검색
       ↓
의존성 계산
       ↓
필요한 패키지 다운로드
       ↓
함께 설치
```

따라서 핵심은:

> **YUM/DNF는 Repository를 이용하여 패키지를 관리하고 필요한 의존성을 자동으로 해결할 수 있기 때문에 RPM 파일을 직접 관리하는 것보다 편리하다.**

---

# 35. Troubleshooting 💀

## `yum install`이 되지 않는다

확인 순서:

```text
1. 인터넷 연결 확인
        ↓
2. DNS 확인
        ↓
3. Repository 목록 확인
        ↓
4. /etc/yum.repos.d/*.repo 확인
        ↓
5. baseurl / mirrorlist / metalink 확인
        ↓
6. CentOS 버전 및 EOL 여부 확인
        ↓
7. 필요하면 Vault Repository 확인
```

기본 확인:

```bash
ping 8.8.8.8
```

DNS 확인:

```bash
ping google.com
```

Repository:

```bash
yum repolist
```

설정:

```bash
ls -l /etc/yum.repos.d/
```

---

# 36. 한 줄 최종 정리

```text
RPM  = .rpm 패키지를 직접 관리
YUM/DNF = Repository + 의존성까지 관리

DPKG = .deb 패키지를 직접 관리
APT  = Repository + 의존성까지 관리

wget = 파일 다운로드
curl = URL 기반 데이터 송수신
git = Git Repository 버전 관리/복제
```

## 💀 오늘의 교훈

```text
rpm -ivh
   ↓
오 설치된다 😎
   ↓
Dependency Error
   ↓
뭐가 필요하다고? 💀
   ↓
그거 설치
   ↓
또 다른 Dependency
   ↓
🤡
   ↓
yum install
   ↓
의존성 자동 해결
   ↓
😇
```

> **패키지 관리의 핵심은 명령어 자체보다
> "패키지 → 의존성 → Repository → 패키지 관리자"의 관계를 이해하는 것이다.**
