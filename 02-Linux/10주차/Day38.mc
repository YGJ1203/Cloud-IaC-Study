# Linux 종합 인프라 구축 복습

> **핵심 한 줄 요약**  
> Storage의 디스크 자원을 RAID/LVM으로 구성하고 NFS로 Server1·Server2에 제공한 뒤,  
> Apache/Nginx 웹 서버, MariaDB, Primary/Secondary DNS, 메일 서버를 연계하고 Client에서 검증한 종합 실습.

---

## 1. 오늘의 전체 흐름

```text
                         ┌────────────────────────────┐
                         │ Storage (192.168.2.205)    │
                         │                            │
                         │ RAID 1+0 → /mnt/server1   │
                         │ LVM      → /mnt/server2   │
                         │ NFS / SMB                  │
                         └─────────────┬──────────────┘
                                       │ NFS
                    ┌──────────────────┴──────────────────┐
                    │                                     │
                    ▼                                     ▼
      ┌───────────────────────────┐        ┌───────────────────────────┐
      │ Server1 (192.168.2.203)   │        │ Server2 (192.168.2.204)   │
      │                           │        │                           │
      │ Apache                    │        │ Nginx                     │
      │ /www, /www1~3            │        │ /www                      │
      │ MariaDB                   │        │ MariaDB                   │
      │ Primary DNS (ns1)         │───────▶│ Secondary DNS (ns2)       │
      │                           │ Zone    │ Sendmail + Dovecot        │
      │                           │Transfer │ Mail Server               │
      └────────────┬──────────────┘        └─────────────┬─────────────┘
                   │                                     │
                   └────────────────┬────────────────────┘
                                    │
                              DNS / WEB / MAIL
                                    │
                    ┌───────────────┴───────────────┐
                    ▼                               ▼
             Client1 (.201)                  Client2 (.202)
             curl / nmap                     nslookup / Evolution
```

### 장비 역할

| 시스템 | IP | 오늘의 주요 역할 |
|---|---|---|
| Client1 | `192.168.2.201` | Apache 접근 테스트, `nmap` 서비스 스캔, DNS 검증 |
| Client2 | `192.168.2.202` | DNS 검증, Evolution 메일 클라이언트 설치 |
| Server1 | `192.168.2.203` | Apache, MariaDB, Primary DNS |
| Server2 | `192.168.2.204` | Nginx, MariaDB, Secondary DNS, Sendmail/Dovecot |
| Storage | `192.168.2.205` | RAID 1+0, LVM, NFS, SMB 저장소 |

> **기록 참고**  
> Day33 개요에는 `Server1 Nginx 웹 서버`라고 적혀 있지만, 실제 `0831-Server2.txt` 세션에서는
> Server2의 `/etc/nginx`에서 Nginx Virtual Host를 구성했다. 따라서 이 문서에서는
> **실제 세션 기록 기준으로 Server2=Nginx**라고 표기한다.

---

# 2. Storage — RAID / LVM / NFS

## 2-1. Server1용 RAID 1+0

사용 디스크:

```text
/dev/sdb
/dev/sdc
/dev/sdd
/dev/sde
```

RAID 장치 생성:

```bash
mdadm --create /dev/md10 \
  --level=10 \
  --raid-devices=4 \
  /dev/sdb1 /dev/sdc1 /dev/sdd1 /dev/sde1
```

`/etc/fstab` 예시:

```fstab
/dev/md10    /mnt/server1    ext4    defaults    0 1
```

### RAID 1+0 개념

RAID 10은 **Mirroring(RAID 1) + Striping(RAID 0)** 구조이다.

```text
Disk1 ─┐
       ├─ Mirror ─┐
Disk2 ─┘          │
                  ├─ Stripe → RAID 10
Disk3 ─┐          │
       ├─ Mirror ─┘
Disk4 ─┘
```

핵심 목적:

- RAID 1의 장애 대응 능력
- RAID 0의 성능 향상
- 최소 4개 디스크 필요

---

## 2-2. Server2용 LVM

사용 디스크:

```text
/dev/sdf
/dev/sdg
/dev/sdh
```

최종 Logical Volume:

```text
/dev/TEST_VG/TEST_LV
```

`/etc/fstab`:

```fstab
/dev/TEST_VG/TEST_LV    /mnt/server2    ext4    defaults    0 1
```

### LVM 구조 복습

```text
Physical Disk
    ↓
PV (Physical Volume)
    ↓
VG (Volume Group)
    ↓
LV (Logical Volume)
    ↓
Filesystem
    ↓
Mount Point
```

RAID가 주로 **성능/장애 대응**에 초점을 둔다면,
LVM은 여러 디스크 공간을 논리적으로 묶어 **용량을 유연하게 관리**하기 위한 기술이다.

---

# 3. NFS — Storage의 저장 공간을 웹 서버에 제공

Server1, Server2, Storage에 NFS 관련 패키지를 설치:

```bash
yum -y install nfs-utils
```

Server1:

```fstab
192.168.2.205:/mnt/server1    /www    nfs    rw    0 1
```

Server2:

```fstab
192.168.2.205:/mnt/server2    /www    nfs    rw    0 1
```

즉:

```text
Storage:/mnt/server1 ──NFS──▶ Server1:/www
Storage:/mnt/server2 ──NFS──▶ Server2:/www
```

Server2에서 실제로 다음 형태로 확인됐다.

```text
192.168.2.205:/mnt/server2  →  /www
```

검증 명령어:

```bash
df -h
mount
ls /www
```

### 핵심

웹 서버의 Document Root가 반드시 서버 자신의 로컬 디스크일 필요는 없다.

오늘 실습에서는:

```text
웹 서버
   ↓
/www
   ↓
NFS Mount
   ↓
Storage Server
```

구조를 만든 것이다.

---

# 4. SMB / Samba

관련 패키지:

```bash
yum -y install samba samba-client cifs-utils
```

서비스 활성화:

```bash
systemctl enable --now smb nmb
systemctl status smb nmb
```

### NFS와 SMB 차이

| 구분 | NFS | SMB |
|---|---|---|
| 대표 사용 환경 | Linux/Unix | Windows + Linux |
| Linux 서버 패키지 | `nfs-utils` | `samba` |
| 파일 공유 방식 | Network File System | Server Message Block |
| 관련 Linux 서비스 | `nfs-server` | `smb`, `nmb` |

---

# 5. Server1 — Apache Web Server

## 5-1. 기본 Virtual Host

```apache
<VirtualHost *:80>
    ServerAdmin webmaster@example7777.com
    DocumentRoot "/www"
    ServerName www.example7777.com
    ServerAlias example7777.com

    ErrorLog "/var/log/httpd/example7777.com-error_log"
    CustomLog "/var/log/httpd/example7777.com-access_log" common

    <Directory "/www">
        Options Indexes FollowSymLinks
        Require all granted
    </Directory>
</VirtualHost>
```

Apache 설정 변경 후 필수 점검:

```bash
httpd -t
systemctl restart httpd
```

정상:

```text
Syntax OK
```

---

# 6. Apache Virtual Host 3가지 방식

오늘의 핵심 웹 서버 실습이다.

## 6-1. Name-Based Virtual Host

하나의 IP와 하나의 포트를 사용하면서
**요청한 Host 이름**으로 사이트를 구분한다.

`/etc/hosts` 예시:

```text
192.168.2.203    www1.example7777.com
192.168.2.203    www2.example7777.com
192.168.2.203    www3.example7777.com
```

Virtual Host:

```apache
<VirtualHost *:80>
    DocumentRoot "/www1"
    ServerName www1.example7777.com

    <Directory "/www1">
        Options Indexes FollowSymLinks
        Require all granted
    </Directory>
</VirtualHost>
```

`www2`, `www3`도 동일 구조로 각각 `/www2`, `/www3`를 사용한다.

### 흐름

```text
www1.example7777.com ─┐
www2.example7777.com ─┼─▶ 192.168.2.203:80
www3.example7777.com ─┘
                           │
                           └─ Host 헤더를 보고 VirtualHost 선택
```

---

## 6-2. IP-Based Virtual Host

Server1의 `ens33`에 추가 IP를 설정했다.

```bash
nmcli connection modify ens33 \
  +ipv4.address 192.168.2.210 \
  +ipv4.address 192.168.2.220 \
  +ipv4.address 192.168.2.230

nmcli connection up ens33
ip address show ens33
```

실제 인터페이스에는:

```text
192.168.2.203
192.168.2.210
192.168.2.220
192.168.2.230
```

이 함께 존재했다.

VirtualHost 예:

```apache
<VirtualHost 192.168.2.210:80>
    DocumentRoot "/www1"
    ServerName www1.example7777.com
</VirtualHost>

<VirtualHost 192.168.2.220:80>
    DocumentRoot "/www2"
    ServerName www2.example7777.com
</VirtualHost>

<VirtualHost 192.168.2.230:80>
    DocumentRoot "/www3"
    ServerName www3.example7777.com
</VirtualHost>
```

Client1 검증:

```bash
curl http://192.168.2.210
curl http://192.168.2.220
curl http://192.168.2.230
```

결과:

```text
192.168.2.210 → www1
192.168.2.220 → www2
192.168.2.230 → www3
```

실습 후 추가 IP 제거:

```bash
nmcli connection modify ens33 \
  -ipv4.address 192.168.2.210 \
  -ipv4.address 192.168.2.220 \
  -ipv4.address 192.168.2.230

nmcli connection up ens33
```

---

## 6-3. Port-Based Virtual Host

이번에는 IP는 하나만 사용한다.

```text
192.168.2.203
```

대신 포트를 구분한다.

```apache
Listen 8081
Listen 8082
Listen 8083
```

```apache
<VirtualHost 192.168.2.203:8081>
    DocumentRoot "/www1"
    ServerName www1.example7777.com
</VirtualHost>

<VirtualHost 192.168.2.203:8082>
    DocumentRoot "/www2"
    ServerName www2.example7777.com
</VirtualHost>

<VirtualHost 192.168.2.203:8083>
    DocumentRoot "/www3"
    ServerName www3.example7777.com
</VirtualHost>
```

Client1:

```bash
curl http://192.168.2.203:8081
curl http://192.168.2.203:8082
curl http://192.168.2.203:8083
```

결과:

```text
8081 → www1
8082 → www2
8083 → www3
```

---

## Virtual Host 비교

| 방식 | 구분 기준 | 예 |
|---|---|---|
| Name-Based | Host 이름 | `www1.example7777.com` |
| IP-Based | 목적지 IP | `192.168.2.210` |
| Port-Based | 목적지 Port | `:8081` |

암기:

```text
Name-Based → 이름으로 구분
IP-Based   → IP로 구분
Port-Based → Port로 구분
```

---

# 7. Client1 — Nmap으로 서비스 확인

설치:

```bash
yum -y install nmap
```

스캔:

```bash
nmap -sS -sV 192.168.2.203
```

옵션:

```text
-sS : TCP SYN Scan
-sV : 서비스 및 버전 탐지
```

실습에서 확인된 주요 Port:

| Port | Service |
|---:|---|
| 21 | FTP |
| 22 | SSH |
| 80 | HTTP |
| 111 | RPCBind |
| 139 | NetBIOS/Samba |
| 443 | HTTPS |
| 445 | SMB |
| 2049 | NFS |
| 8081 | Apache VirtualHost |
| 8082 | Apache VirtualHost |
| 8083 | Apache VirtualHost |

즉 `systemctl status`만 보는 것이 아니라
**클라이언트 입장에서 실제 Port가 열려 있는지** 확인하는 용도로 Nmap을 사용했다.

---

# 8. Server2 — Nginx

Nginx 설정 디렉터리:

```bash
cd /etc/nginx
ls
```

핵심 구조:

```text
/etc/nginx/nginx.conf
/etc/nginx/conf.d/
/etc/nginx/default.d/
```

`nginx.conf`에서:

```nginx
include /etc/nginx/conf.d/*.conf;
```

따라서 `/etc/nginx/conf.d/` 아래에 별도 설정 파일을 둘 수 있다.

실습:

```bash
vi /etc/nginx/conf.d/vhost.conf
systemctl restart nginx.service
```

Virtual Host:

```nginx
server {
    listen 80;
    server_name intranet.example7777.com;
    root /www;

    include /etc/nginx/default.d/*.conf;

    error_page 404 /404.html;
    location = /404.html {
    }

    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
    }
}
```

Document Root:

```text
/www
```

그리고 `/www`는 Storage의 NFS 자원이다.

```text
Storage 192.168.2.205:/mnt/server2
               │
               ▼
        Server2:/www
               │
               ▼
             Nginx
```

---

# 9. MariaDB

Server1과 Server2에서 설치:

```bash
yum -y install mariadb-server
```

서비스 활성화:

```bash
systemctl enable --now mariadb
```

의미:

```text
enable → 부팅 시 자동 시작
--now  → 지금 즉시 시작
```

따라서:

```bash
systemctl enable --now mariadb
```

는 사실상 다음 두 동작을 한 번에 수행한다.

```bash
systemctl enable mariadb
systemctl start mariadb
```

> 오늘 기록에서는 MariaDB의 설치와 서비스 활성화가 중심이며,
> DB 생성/사용자 생성/SQL 실습 내용은 확인되지 않는다.

---

# 10. DNS — BIND

## 10-1. 역할

```text
Server1 192.168.2.203 → Primary / Master DNS → ns1
Server2 192.168.2.204 → Secondary / Slave DNS → ns2
```

도메인:

```text
example7777.com
```

---

# 11. Primary DNS — Server1

BIND 설치:

```bash
yum -y install bind
```

서비스:

```bash
systemctl enable --now named
```

설정 검사:

```bash
named-checkconf /etc/named.conf
named-checkconf /etc/named.rfc1912.zones
```

---

## 11-1. 정방향 Zone

```bind
zone "example7777.com" IN {
    type master;
    file "example7777.com.zone";
    allow-update { none; };
};
```

실습 후 Server2 통보를 위해 다음 형태도 사용했다.

```bind
zone "example7777.com" IN {
    type master;
    file "example7777.com.zone";
    also-notify { 192.168.2.204; };
};
```

---

## 11-2. 역방향 Zone

```bind
zone "2.168.192.in-addr.arpa" IN {
    type master;
    file "example7777.com.reverse.zone";
    allow-update { none; };
};
```

또는 실습 후:

```bind
zone "2.168.192.in-addr.arpa" IN {
    type master;
    file "example7777.com.reverse.zone";
    also-notify { 192.168.2.204; };
};
```

---

# 12. DNS 정방향 Zone 파일

주요 레코드:

```dns
$TTL 1D
@   IN SOA ns1.example7777.com. root.example7777.com. (
        0
        1D
        1H
        1W
        3H
)

example7777.com.    IN NS     ns1.example7777.com.
example7777.com.    IN MX 10  mail.example7777.com.

www       IN A    192.168.2.203
ftp       IN A    192.168.2.203
ns1       IN A    192.168.2.203

ns2       IN A    192.168.2.204
mail      IN A    192.168.2.204
intranet  IN A    192.168.2.204

storage   IN A    192.168.2.205
```

### 레코드 의미

| Record | 의미 |
|---|---|
| SOA | Zone의 기본 권한/관리 정보 |
| NS | 해당 Zone의 DNS 서버 |
| A | Hostname → IPv4 |
| MX | Mail Server 지정 |
| PTR | IPv4 → Hostname |

---

# 13. DNS 역방향 Zone

```dns
$TTL 1D
@   IN SOA ns1.example7777.com. root.example7777.com. (
        0
        1D
        1H
        1W
        3H
)

        IN NS     ns1.example7777.com.
        IN MX 10  mail.example7777.com.

203     IN PTR    www.example7777.com.
203     IN PTR    ftp.example7777.com.
203     IN PTR    ns1.example7777.com.

204     IN PTR    ns2.example7777.com.
204     IN PTR    mail.example7777.com.
204     IN PTR    intranet.example7777.com.

205     IN PTR    storage.example7777.com.
```

### 정방향 / 역방향

```text
정방향 DNS
www.example7777.com
        ↓
192.168.2.203
```

```text
역방향 DNS
192.168.2.203
        ↓
www.example7777.com
```

---

# 14. DNS 설정 검증 명령어

설정 파일 문법:

```bash
named-checkconf /etc/named.conf
named-checkconf /etc/named.rfc1912.zones
```

Zone 파일:

```bash
named-checkzone example7777.com example7777.com.zone

named-checkzone \
  2.168.192.in-addr.arpa \
  example7777.com.reverse.zone
```

정상 결과 예:

```text
loaded serial 0
OK
```

### 실습 중 발생한 오류

정방향 Zone 검사 중:

```text
NS 'ns1.example7777.com.example7777.com' has no address records
```

수정 후:

```text
zone example7777.com/IN: loaded serial 0
OK
```

또 역방향 Zone에서는:

```text
no current owner name
```

오류가 발생했고 Zone 파일 수정 후 최종적으로:

```text
loaded serial 0
OK
```

까지 확인했다.

이 실습의 핵심은 **DNS 설정은 작성 직후 바로 재시작하지 말고
`named-checkconf`, `named-checkzone`으로 먼저 검증하는 것**이다.

---

# 15. Secondary DNS — Server2

Server2 Zone:

```bind
zone "example7777.com" IN {
    type slave;
    file "slaves/example7777.com.zone";
    masters { 192.168.2.203; };
};
```

역방향:

```bind
zone "2.168.192.in-addr.arpa" IN {
    type slave;
    file "slaves/example7777.com.reverse.zone";
    masters { 192.168.2.203; };
};
```

서비스:

```bash
systemctl enable --now named
systemctl restart named
```

Zone Transfer 후:

```bash
ls /var/named/slaves/
```

실제 결과:

```text
example7777.com.zone
example7777.com.reverse.zone
```

즉 Primary의 Zone 정보가 Secondary로 전달된 것을 확인했다.

---

# 16. Primary / Secondary DNS 구조

```text
Client
  │
  │ DNS Query
  ▼
┌───────────────────────┐
│ Primary DNS           │
│ Server1               │
│ 192.168.2.203         │
│ example7777.com       │
│ type master           │
└──────────┬────────────┘
           │
           │ Zone Transfer / Notify
           ▼
┌───────────────────────┐
│ Secondary DNS         │
│ Server2               │
│ 192.168.2.204         │
│ type slave            │
└───────────────────────┘
```

장점:

- DNS 서버 한 대에 장애가 발생해도 다른 DNS 서버를 사용할 수 있음
- Zone 정보를 Secondary에 복제 가능
- DNS 서비스 가용성 향상

---

# 17. Client DNS 설정

Server2, Client1, Client2에서:

```bash
nmcli connection modify ens33 \
  ipv4.dns "192.168.2.203 192.168.2.204"

systemctl restart NetworkManager
```

확인:

```bash
cat /etc/resolv.conf
```

결과:

```text
nameserver 192.168.2.203
nameserver 192.168.2.204
```

즉:

```text
1순위 DNS → Server1
2순위 DNS → Server2
```

---

# 18. DNS 테스트 자동화

Server1의 웹 경로에 `dnstest.sh`를 준비하고
다른 시스템에서 다운로드했다.

```bash
wget http://192.168.2.203/dnstest.sh
sh dnstest.sh
```

스크립트의 핵심 테스트:

```bash
echo "정방향 테스트"

nslookup www.example7777.com
nslookup ftp.example7777.com
nslookup ns1.example7777.com
nslookup ns2.example7777.com
nslookup mail.example7777.com
nslookup intranet.example7777.com
nslookup storage.example7777.com

sleep 2

echo "역방향 테스트"

nslookup 192.168.2.203
nslookup 192.168.2.204
nslookup 192.168.2.205
```

Client2 결과:

```text
www       → 192.168.2.203
ftp       → 192.168.2.203
ns1       → 192.168.2.203

ns2       → 192.168.2.204
mail      → 192.168.2.204
intranet  → 192.168.2.204

storage   → 192.168.2.205
```

역방향 조회도 성공했다.

---

# 19. Server2 — Mail Server

DNS MX 레코드:

```dns
example7777.com. IN MX 10 mail.example7777.com.
```

그리고:

```dns
mail IN A 192.168.2.204
```

따라서:

```text
example7777.com의 Mail Server
        ↓ MX
mail.example7777.com
        ↓ A
192.168.2.204
        ↓
Server2
```

---

# 20. Sendmail

설정 경로:

```bash
cd /etc/mail
```

주요 파일:

```text
access
access.db
local-host-names
sendmail.cf
```

`access` 수정 후 DB 생성:

```bash
vi access
makemap hash access.db < access
```

확인:

```bash
strings access.db
```

기록에서는 다음 대상에 대해 `RELAY` 설정이 확인됐다.

```text
localhost
localhost.localdomain
example7777.com
192.168.2
127.0.0.1
```

서비스:

```bash
systemctl enable --now sendmail
systemctl status sendmail
```

---

# 21. Dovecot

설정:

```bash
cd /etc/dovecot
vi dovecot.conf
```

주요 설정 디렉터리:

```bash
cd /etc/dovecot/conf.d
```

실습에서 수정한 파일:

```text
10-mail.conf
10-ssl.conf
10-auth.conf
```

서비스:

```bash
systemctl enable --now dovecot
systemctl restart dovecot
```

포트 확인:

```bash
netstat -ntlp | egrep "sendmail|dovecot"
```

실습 결과:

```text
25/tcp  → Sendmail
110/tcp → Dovecot
143/tcp → Dovecot
587/tcp → Dovecot
```

프로세스 확인:

```bash
ps -ef | egrep "sendmail|dovecot"
```

---

# 22. Evolution Mail Client

Client2:

```bash
yum -y install evolution
```

Evolution은 Linux GUI 환경에서 사용할 수 있는 메일 클라이언트이다.

오늘의 구조를 연결하면:

```text
Evolution
   │
   ├─ 메일 발신/SMTP 계열
   │          ↓
   │     Server2 Mail Server
   │
   └─ 메일 수신
              ↓
           Dovecot
```

> 실제 계정 입력값이나 GUI 설정 과정은 제공된 터미널 기록에서 확인되지 않으므로
> 이 문서에서는 설치 및 서버 측 구성까지만 정리한다.

---

# 23. 오늘의 서비스 연결 관계

```text
[1] Storage
    RAID 10 / LVM
         ↓
        NFS
         ↓
[2] Server1 / Server2
         ↓
 Apache / Nginx
         ↓
       HTTP
         ↓
      Client
```

DNS까지 포함하면:

```text
Client
  │
  │ www.example7777.com ?
  ▼
Primary DNS (Server1)
  │
  ├─ www       → Server1
  ├─ ftp       → Server1
  ├─ ns1       → Server1
  ├─ ns2       → Server2
  ├─ mail      → Server2
  ├─ intranet  → Server2
  └─ storage   → Storage
```

메일까지:

```text
Client / Evolution
        │
        │ DNS MX Lookup
        ▼
example7777.com
        │
        ▼
mail.example7777.com
        │
        ▼
192.168.2.204
        │
        ▼
Server2
 ├─ Sendmail
 └─ Dovecot
```

---

# 24. 오늘의 검증 명령어 총정리

```bash
# Network
ip address show ens33
nmcli connection up ens33

# Mount / Storage
df -h
mount
ls /www

# Apache
httpd -t
systemctl restart httpd

# Nginx
systemctl restart nginx
systemctl status nginx

# MariaDB
systemctl enable --now mariadb
systemctl status mariadb

# DNS 설정 검사
named-checkconf /etc/named.conf
named-checkconf /etc/named.rfc1912.zones

# DNS Zone 검사
named-checkzone example7777.com example7777.com.zone
named-checkzone 2.168.192.in-addr.arpa example7777.com.reverse.zone

# DNS Query
nslookup www.example7777.com
nslookup 192.168.2.203

# Service Scan
nmap -sS -sV 192.168.2.203

# Mail
systemctl status sendmail
systemctl status dovecot
netstat -ntlp | egrep "sendmail|dovecot"
ps -ef | egrep "sendmail|dovecot"
```

---

# 25. 장애 발생 시 점검 순서

## 웹 접속이 안 될 때

```text
1. IP가 맞는가?
      ↓
2. NFS가 /www에 정상 Mount 되었는가?
      ↓
3. DocumentRoot가 올바른가?
      ↓
4. Apache/Nginx 설정 문법이 맞는가?
      ↓
5. 서비스가 실행 중인가?
      ↓
6. Port가 Listening 상태인가?
      ↓
7. Client에서 curl/nmap으로 접근 가능한가?
```

예:

```bash
ip addr
df -h
ls /www
httpd -t
systemctl status httpd
ss -lntp
curl http://SERVER_IP
```

---

## DNS가 안 될 때

```text
1. Client DNS 주소 확인
      ↓
2. named 서비스 상태 확인
      ↓
3. named.conf 문법 검사
      ↓
4. Zone 선언 검사
      ↓
5. Zone 파일 검사
      ↓
6. nslookup으로 정방향 검사
      ↓
7. nslookup으로 역방향 검사
      ↓
8. Secondary Zone Transfer 확인
```

명령어:

```bash
cat /etc/resolv.conf

systemctl status named

named-checkconf /etc/named.conf

named-checkzone example7777.com example7777.com.zone

nslookup www.example7777.com
nslookup 192.168.2.203

ls /var/named/slaves/
```

---

# 26. 오늘의 핵심 암기 포인트

```text
RAID 10
→ 장애 대응 + 성능

LVM
→ 논리적/유연한 디스크 관리

NFS
→ Linux 간 Network File System

SMB
→ Samba 기반 파일 공유

Apache VirtualHost
→ Name / IP / Port 기준으로 여러 웹 사이트 제공

Nginx
→ server block을 이용한 웹 서비스

MariaDB
→ 관계형 DB 서버

Primary DNS
→ 원본 Zone 관리

Secondary DNS
→ Primary Zone 복제

A
→ Name → IPv4

PTR
→ IPv4 → Name

MX
→ Mail Server 지정

Sendmail
→ 메일 전송 처리

Dovecot
→ 메일 수신 접근 서비스

nmap
→ Client 관점에서 Port/Service 검사
```

---

# 27. 면접 대비 Q&A

### Q1. NFS를 사용하는 이유는?

여러 Linux 시스템이 네트워크를 통해
원격 서버의 디렉터리를 로컬 디렉터리처럼 사용할 수 있기 때문이다.

---

### Q2. RAID와 LVM의 차이는?

RAID는 여러 디스크를 이용해 성능 또는 장애 대응 능력을 확보하는 기술이고,
LVM은 저장 공간을 논리적으로 묶어 유연하게 할당하고 관리하는 기술이다.

---

### Q3. Apache VirtualHost란?

한 Apache 서버에서 여러 웹 사이트를 제공하기 위한 기능이다.
오늘 실습에서는 Name-Based, IP-Based, Port-Based 방식으로 구분했다.

---

### Q4. `httpd -t`를 왜 사용하는가?

Apache 설정 파일의 문법 오류를 검사하기 위해 사용한다.

설정 오류 상태에서 바로 서비스를 재시작하는 위험을 줄일 수 있다.

---

### Q5. Primary DNS와 Secondary DNS의 차이는?

Primary는 Zone 원본을 관리하며,
Secondary는 Primary에서 Zone 정보를 전달받아 복제본을 유지한다.

---

### Q6. A Record와 PTR Record의 차이는?

```text
A   : Hostname → IPv4
PTR : IPv4 → Hostname
```

---

### Q7. MX Record란?

특정 도메인의 메일을 처리하는 Mail Server를 지정하는 DNS Record이다.

오늘 실습:

```text
example7777.com
       ↓ MX
mail.example7777.com
       ↓ A
192.168.2.204
```

---

### Q8. DNS 설정 후 바로 `systemctl restart named`를 하면 안 되는 이유는?

Zone 파일이나 설정 파일에 문법 오류가 있으면
DNS 서비스가 정상적으로 올라오지 않을 수 있기 때문이다.

따라서 먼저:

```bash
named-checkconf
named-checkzone
```

으로 검사한 뒤 재시작하는 것이 좋다.

---

### Q9. `nmap -sS -sV`의 의미는?

```text
-sS → TCP SYN Scan
-sV → Service / Version Detection
```

즉 대상 서버에서 어떤 TCP Port가 열려 있고
어떤 서비스가 동작 중인지 확인한다.

---

### Q10. `/etc/resolv.conf`에 DNS 서버가 두 개 있는 이유는?

```text
nameserver 192.168.2.203
nameserver 192.168.2.204
```

Primary DNS에 문제가 있을 경우
다른 DNS 서버를 사용할 수 있도록 복수의 Resolver 주소를 지정한 구성이다.

---

# 28. 실습을 한 문장으로 다시 설명하기

> Storage에서 RAID 10과 LVM 기반 저장 공간을 만들고 이를 NFS로 웹 서버에 제공한 뒤,
> Server1에는 Apache와 Primary DNS를, Server2에는 Nginx와 Secondary DNS 및 Mail 서비스를
> 구성하고 Client에서 HTTP, DNS, Port, Mail Client 관점으로 검증한 통합 Linux 서버 구축 실습이다.

---

# 29. 초압축 최종 복습

```text
Storage
 ├─ RAID 10 → NFS → Server1:/www
 ├─ LVM     → NFS → Server2:/www
 └─ Samba

Server1 (.203)
 ├─ Apache
 │   ├─ Name-Based VHost
 │   ├─ IP-Based VHost
 │   └─ Port-Based VHost :8081~8083
 ├─ MariaDB
 └─ Primary DNS (ns1)

Server2 (.204)
 ├─ Nginx
 ├─ MariaDB
 ├─ Secondary DNS (ns2)
 ├─ Sendmail
 └─ Dovecot

DNS
 ├─ www / ftp / ns1 → .203
 ├─ ns2 / mail / intranet → .204
 └─ storage → .205

Client
 ├─ curl
 ├─ nmap -sS -sV
 ├─ nslookup
 ├─ dnstest.sh
 └─ Evolution
```

---

## 오늘의 진짜 핵심

각 서비스를 따로 외우는 것이 아니라 다음 **서비스 연결 관계**를 이해해야 한다.

```text
Disk
 ↓
RAID / LVM
 ↓
Filesystem
 ↓
NFS
 ↓
Web Server
 ↓
DNS
 ↓
Client

그리고

DNS MX
 ↓
Mail Server
 ↓
Mail Client
```

이 흐름이 머릿속에서 연결되면 오늘 실습의 대부분이 정리된다.
