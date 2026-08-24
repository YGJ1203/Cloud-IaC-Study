# Linux 서버 서비스 핵심 개념 정리

> 오늘의 핵심: **FTP Mode → NFS → Samba → MariaDB → Apache(httpd)**\
> 각각의 서비스가 무엇을 하는지, 서로 어떤 차이가 있는지를 중심으로
> 정리한다.

------------------------------------------------------------------------

## 1. FTP Active / Passive Mode

FTP는 **제어 연결(Control)** 과 **데이터 연결(Data)** 을 따로 사용하는
파일 전송 프로토콜이다.

### Active Mode

-   클라이언트가 서버의 **TCP 21번 포트**로 제어 연결을 생성한다.
-   실제 데이터 전송 시 **서버가 클라이언트 쪽으로 데이터 연결을
    시도**한다.
-   전통적으로 서버 측 데이터 포트로 **TCP 20번**을 사용한다.
-   클라이언트가 NAT 또는 방화벽 뒤에 있으면 서버가 클라이언트로
    접속하기 어려울 수 있다.

**핵심 암기**

> Active = 서버가 클라이언트에게 데이터 연결을 시도

### Passive Mode

-   클라이언트가 서버의 **TCP 21번 포트**로 제어 연결을 생성한다.
-   서버가 데이터 통신에 사용할 포트를 알려준다.
-   **클라이언트가 서버의 데이터 포트로 연결을 시도**한다.
-   NAT/방화벽 환경에서 Active Mode보다 사용하기 편리하다.

**핵심 암기**

> Passive = 제어 연결과 데이터 연결 모두 클라이언트가 시작

------------------------------------------------------------------------

## 2. NFS (Network File System)

NFS는 네트워크를 통해 **원격 서버의 디렉터리를 로컬 디렉터리처럼 사용할
수 있게 하는 파일 공유 방식**이다.

주로 **Linux/Unix 시스템 간 파일 공유**에 사용한다.

### 기본 구조

``` text
NFS Server                       NFS Client

/test/share1  ────────────────→  /mnt/nfs1
/test/share2  ────────────────→  /mnt/nfs2
```

클라이언트의 `/mnt/nfs1`에 접근하지만 실제 데이터는 NFS 서버의
`/test/share1`에 존재한다.

### /etc/fstab 예시

``` text
192.168.2.203:/test/share1  /mnt/nfs1  nfs  rw  0 0
192.168.2.203:/test/share2  /mnt/nfs2  nfs  ro  0 0
```

구조:

``` text
NFS서버:공유디렉터리  마운트위치  파일시스템  옵션  dump  fsck
```

-   `rw` : 읽기/쓰기
-   `ro` : 읽기 전용
-   `nfs` : NFS 파일시스템
-   `/etc/fstab` : 부팅 시 자동 마운트 설정 가능

### 서버 권한과 클라이언트 마운트 옵션

서버에서 `rw`로 공유했다고 해서 클라이언트가 반드시 `rw`로 사용해야 하는
것은 아니다.

``` text
Server : rw 허용
Client : ro 마운트
→ Client에서는 읽기 전용
```

반대로 서버가 `ro`만 허용하는데 클라이언트가 `rw`로 설정한다고 해서 쓰기
권한을 얻을 수는 없다.

**핵심 암기**

> NFS = Linux ↔ Linux 파일 공유 + 원격 디렉터리를 로컬에 Mount

------------------------------------------------------------------------

## 3. Samba

Samba는 **SMB/CIFS 프로토콜을 이용하여 Linux와 Windows 등이 파일 및
프린터를 공유할 수 있도록 하는 서비스**이다.

### NFS와 차이

-   NFS → 주로 Linux/Unix 간 공유
-   Samba → Windows와의 호환성이 중요한 파일 공유

### 관련 패키지

``` bash
yum -y install samba samba-client cifs-utils
```

-   `samba` : Samba 서버 기능
-   `samba-client` : Samba 클라이언트 기능
-   `cifs-utils` : SMB/CIFS 공유를 Linux에 마운트할 때 사용

### /etc/fstab 예시

``` text
//192.168.2.203/public  /mnt/samba  cifs  credentials=/etc/samba/cred  0 0
```

의미:

``` text
//192.168.2.203/public
        ↓
원격 Samba 공유

/mnt/samba
        ↓
로컬 마운트 위치

cifs
        ↓
SMB/CIFS 파일시스템
```

### Credentials 파일

``` text
username=user1
password=centos
```

인증 정보를 `/etc/fstab`에 직접 노출하지 않고 별도 파일로 관리할 수
있다.

실제 환경에서는 다음과 같이 접근 권한을 제한하는 것이 중요하다.

``` bash
chmod 600 /etc/samba/cred
```

**핵심 암기**

> Samba = SMB/CIFS 기반 파일 공유 + Windows 호환

------------------------------------------------------------------------

## 4. NFS vs Samba

  구분                NFS                               Samba
  ------------------- --------------------------------- -------------------------
  주요 목적           Linux/Unix 파일 공유              Windows/Linux 파일 공유
  대표 프로토콜       NFS                               SMB/CIFS
  대표 포트           TCP 2049                          TCP 445
  Linux 마운트 타입   `nfs`                             `cifs`
  인증 특징           호스트 및 Unix 권한 체계와 밀접   사용자 계정 인증 활용
  대표 설정           `/etc/exports`                    `/etc/samba/smb.conf`

둘 다 핵심 원리는 같다.

> **원격 서버의 공유 자원을 클라이언트에서 사용할 수 있게 한다.**

------------------------------------------------------------------------

## 5. MariaDB

MariaDB는 관계형 데이터베이스 관리 시스템(RDBMS)이다.

파일을 단순히 저장하는 것이 아니라 데이터를 **테이블(Table) 형태로
구조화하여 저장하고 SQL을 이용해 관리**한다.

### 기본 구조

``` text
MariaDB Server
    │
    ├── Database
    │      │
    │      ├── Table
    │      ├── Table
    │      └── Table
    │
    └── User / Privilege
```

### 핵심 개념

-   **Database** : 관련 데이터를 묶어 관리하는 공간
-   **Table** : 행(Row)과 열(Column)로 데이터를 저장
-   **SQL** : 데이터베이스를 조작하기 위한 언어
-   **User** : DB에 접속하는 사용자
-   **Privilege** : 사용자가 수행할 수 있는 작업에 대한 권한

대표적인 SQL:

``` sql
CREATE DATABASE database_name;
USE database_name;
SHOW TABLES;
SELECT * FROM table_name;
```

MariaDB의 기본 TCP 포트는 **3306번**이다.

**핵심 암기**

> MariaDB = 데이터를 구조적으로 저장하고 SQL로 관리하는 RDBMS

------------------------------------------------------------------------

## 6. Apache HTTP Server (httpd)

`httpd`는 Linux에서 많이 사용하는 **Apache 웹 서버 서비스**이다.

클라이언트의 HTTP 요청을 받아 HTML 등의 웹 콘텐츠를 제공한다.

### 기본 흐름

``` text
Web Browser
     │
     │ HTTP Request
     │ TCP 80
     ▼
Apache (httpd)
     │
     ▼
/var/www/html/
     │
     └── index.html
```

기본 웹 문서 경로:

``` text
/var/www/html/
```

대표 서비스 관리:

``` bash
systemctl start httpd
systemctl stop httpd
systemctl restart httpd
systemctl status httpd
systemctl enable httpd
```

HTTP의 대표 포트는 **TCP 80번**이다.

HTTPS는 일반적으로 **TCP 443번**을 사용한다.

**핵심 암기**

> httpd = HTTP 요청을 받아 웹 콘텐츠를 제공하는 Apache 웹 서버

------------------------------------------------------------------------

## 7. 오늘 배운 서비스 한눈에 보기

  서비스    핵심 역할                 대표 포트/프로토콜
  --------- ------------------------- --------------------
  FTP       파일 전송                 TCP 21 / FTP
  NFS       Linux/Unix 파일 공유      TCP 2049 / NFS
  Samba     Windows/Linux 파일 공유   TCP 445 / SMB/CIFS
  MariaDB   데이터베이스 관리         TCP 3306
  httpd     웹 서비스 제공            TCP 80 / HTTP

------------------------------------------------------------------------

## 8. 전체 흐름으로 이해하기

오늘 배운 내용을 단순히 개별 명령어로 외우기보다 **서버가 어떤 서비스를
제공하는가**를 기준으로 구분한다.

``` text
파일을 전송하고 싶다
        ↓
       FTP

Linux 서버의 디렉터리를 공유하고 싶다
        ↓
       NFS

Windows와 Linux 사이에서 파일을 공유하고 싶다
        ↓
      Samba

데이터를 구조적으로 저장하고 관리하고 싶다
        ↓
     MariaDB

웹 페이지를 클라이언트에게 제공하고 싶다
        ↓
 Apache (httpd)
```

------------------------------------------------------------------------

## 9. systemd 관점에서 다시 보기

지금까지 배운 여러 서버 프로그램은 대부분 **서비스(데몬)** 로 실행된다.

``` bash
systemctl start vsftpd
systemctl start nfs-server
systemctl start smb
systemctl start mariadb
systemctl start httpd
```

즉 `systemctl`이라는 명령어 자체를 외우는 것보다,

> **systemd가 Linux의 여러 서버 서비스를 관리한다**

라는 구조를 이해하는 것이 중요하다.

------------------------------------------------------------------------

## 10. 시험/면접용 초압축 암기

``` text
FTP
→ 파일 전송
→ Active / Passive
→ Control TCP 21

NFS
→ Linux/Unix 파일 공유
→ 원격 디렉터리를 Mount
→ /etc/exports
→ TCP 2049

Samba
→ Windows/Linux 파일 공유
→ SMB/CIFS
→ /etc/samba/smb.conf
→ TCP 445

MariaDB
→ RDBMS
→ SQL로 데이터 관리
→ TCP 3306

Apache(httpd)
→ Web Server
→ /var/www/html
→ HTTP TCP 80
→ HTTPS TCP 443
```

------------------------------------------------------------------------

## 한 줄 최종 정리

> **FTP는 파일을 전송하고, NFS와 Samba는 파일을 공유하며, MariaDB는
> 데이터를 관리하고, httpd는 웹 콘텐츠를 제공한다.**
