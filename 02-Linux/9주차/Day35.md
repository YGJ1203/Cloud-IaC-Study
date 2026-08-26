# Linux DNS & Email Server 실습 정리

> **실습 환경:** CentOS Stream 9 / VMware\
> **구성:** Server1, Server2, Client1, Client2\
> **도메인:** `example7777.com`\
> **핵심:** BIND Master/Slave DNS + 정/역방향 조회 + Zone Transfer +
> Sendmail + Dovecot + Evolution

------------------------------------------------------------------------

## 1. 전체 구성

``` text
                         example7777.com
                                |
                +---------------+---------------+
                |                               |
        Server1 (192.168.2.203)         Server2 (192.168.2.204)
        - Master DNS                    - Slave DNS
        - ns1                           - ns2
        - www / ftp                     - mail
                |                               |
                |       Zone Transfer           |
                +------------------------------>|
                                                |
                                      Sendmail / Dovecot
                                      SMTP / POP3 / IMAP
                                                |
                            +-------------------+-------------------+
                            |                                       |
                     Client1                                  Client2
                     Evolution                                Evolution
```

### 장비별 역할

  -----------------------------------------------------------------------
  장비                    주요 역할               주요 이름/IP
  ----------------------- ----------------------- -----------------------
  Server1                 Master DNS, Web/FTP     `192.168.2.203`, `ns1`,
                          관련 레코드             `www`, `ftp`

  Server2                 Slave DNS, Mail Server  `192.168.2.204`, `ns2`,
                                                  `mail`

  Client1                 DNS/서비스 검증,        실습 클라이언트
                          Evolution 메일          
                          클라이언트              

  Client2                 DNS/서비스 검증,        실습 클라이언트
                          Evolution 메일          
                          클라이언트              
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# Part 1. DNS 서버

## 2. DNS 핵심 개념

DNS(Domain Name System)는 사람이 사용하는 도메인 이름과 IP 주소를
연결한다.

``` text
정방향 조회 : 이름 -> IP
www.example7777.com -> 192.168.2.203

역방향 조회 : IP -> 이름
192.168.2.204 -> mail.example7777.com
```

### 주요 DNS 레코드

  레코드    의미                    실습 예시
  --------- ----------------------- -------------------------
  `SOA`     Zone의 기본 관리 정보   `ns1.example7777.com.`
  `NS`      해당 Zone의 DNS 서버    `ns1`, `ns2`
  `A`       호스트 이름 -\> IPv4    `www -> 192.168.2.203`
  `MX`      메일을 담당할 서버      `mail.example7777.com.`
  `CNAME`   다른 이름에 대한 별칭   `blog -> mega.web.test`
  `PTR`     IP -\> 호스트 이름      역방향 Zone에서 사용

------------------------------------------------------------------------

## 3. Server1 - Master DNS 구축

### 3-1. BIND 설치 및 확인

수업에서 사용한 주요 명령어:

``` bash
yum -y install bind
dnf -y install bind

rpm -qa bind
rpm -ql bind
rpm -ql bind | egrep -v "/doc|/man|/lib"

systemctl enable --now named
systemctl status named
ps -ef | grep named
netstat -ntulp | grep named
```

온라인 저장소 설치가 정상적이지 않을 때 ISO가 마운트된 AppStream의 RPM을
직접 사용한 실습도 진행했다.

``` bash
df -h
cd /run/media/root/CentOS-Stream-9-BaseOS-x86_64/AppStream/Packages
ls -l | grep bind
rpm -i bind-9.16.23-15.el9.x86_64.rpm
```

> `named`는 BIND DNS 서버 데몬이다. DNS의 기본 포트는 **53번**이다.

### 3-2. 주요 설정 파일

``` text
/etc/named.conf
/etc/named.rfc1912.zones
/var/named/example7777.com.zone
/var/named/192.168.2.rev
```

설정 문법 검사:

``` bash
named-checkconf /etc/named.conf
named-checkconf /etc/named.rfc1912.zones
```

### 3-3. Master Zone 선언

수업에서 작성한 정방향/역방향 Zone:

``` conf
zone "example7777.com" IN {
        type master;
        file "example7777.com.zone";
        allow-update { none; };
};

zone "2.168.192.in-addr.arpa" IN {
        type master;
        file "192.168.2.rev";
        allow-update { none; };
};
```

-   `type master` : 이 서버가 Zone 원본을 관리
-   `file` : 실제 Zone 데이터 파일
-   `allow-update { none; };` : 동적 업데이트 허용 안 함
-   `2.168.192.in-addr.arpa` : `192.168.2.0/24`의 역방향 조회 Zone

------------------------------------------------------------------------

## 4. 정방향 Zone 파일

파일:

``` text
/var/named/example7777.com.zone
```

수업 설정:

``` dns
$TTL 3H
@       IN SOA  ns1.example7777.com. root.example7777.com. (
                                        0       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum

example7777.com.    IN  NS      ns1.example7777.com.
example7777.com.    IN  NS      ns2.example7777.com.
example7777.com.    IN  MX 10   mail.example7777.com.
www                 IN  A       192.168.2.203
ftp                 IN  A       192.168.2.203
ns1                 IN  A       192.168.2.203
ns2                 IN  A       192.168.2.204
mail                IN  A       192.168.2.204
mega.web.test       IN  A       192.168.2.203
blog                IN  CNAME   mega.web.test
```

### SOA 값

  항목          값 의미
  --------- ------ ---------------------------------------------
  serial       `0` Zone 데이터 버전
  refresh     `1D` Slave가 갱신 여부를 확인하는 주기
  retry       `1H` 갱신 실패 시 재시도 주기
  expire      `1W` Master와 통신 불가 시 Zone 데이터 유효 기간
  minimum     `3H` 기본 캐시 관련 시간

### MX 레코드

``` dns
example7777.com. IN MX 10 mail.example7777.com.
```

`example7777.com`의 메일을 처리할 서버가 `mail.example7777.com`임을
지정한다.

``` text
example7777.com
      |
      +-- MX 10 --> mail.example7777.com
                          |
                          +-- A --> 192.168.2.204
```

MX 앞의 `10`은 우선순위이며 일반적으로 숫자가 작을수록 우선순위가 높다.

### CNAME

``` dns
blog IN CNAME mega.web.test
```

``` text
blog.example7777.com
        -> mega.web.test.example7777.com
        -> 192.168.2.203
```

------------------------------------------------------------------------

## 5. 역방향 Zone 파일

파일:

``` text
/var/named/192.168.2.rev
```

수업 설정:

``` dns
$TTL 3H
@       IN SOA  ns1.example7777.com. root.example7777.com. (
                                        0       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum

            IN  NS      ns1.example7777.com.
            IN  NS      ns2.example7777.com.
            IN  MX 10   mail.example7777.com.
203         IN  PTR     www.example7777.com.
203         IN  PTR     ftp.example7777.com.
203         IN  PTR     ns1.example7777.com.
204         IN  PTR     ns2.example7777.com.
204         IN  PTR     mail.example7777.com.
203         IN  PTR     mega.web.test.example7777.com.
203         IN  PTR     blog.example7777.com.
```

검사:

``` bash
named-checkzone example7777.com example7777.com.zone
named-checkzone 2.168.192.in-addr.arpa 192.168.2.rev
```

Zone 파일 권한 설정에 사용한 명령:

``` bash
chown .named example7777.com.zone
chown .named 192.168.2.rev
```

적용:

``` bash
systemctl restart named
systemctl status named
```

------------------------------------------------------------------------

## 6. Server2 - Slave DNS

Server2는 Master인 Server1로부터 Zone 정보를 전송받는 역할을 수행했다.

### DNS 주소 설정

``` bash
nmcli connection modify ens33 ipv4.dns "192.168.2.203 192.168.2.204" && systemctl restart NetworkManager
cat /etc/resolv.conf
```

### Slave Zone 설정

수업에서 사용한 설정 중 Slave 구성:

``` conf
zone "example7777.com" IN {
        type slave;
        file "slaves/example7777.com.zone";
        masters { 192.168.2.203; };
};

zone "168.192.in-addr.arpa" IN {
        type slave;
        file "slaves/192.168.2.rev";
        masters { 192.168.2.203; };
};
```

> **주의:** 위 두 번째 Slave 역방향 Zone은 수업에서 제공된
> `168.192.in-addr.arpa` 설정을 그대로 기록한 것이다. 앞에서 사용한
> Master의 `2.168.192.in-addr.arpa`와는 별개의 설정으로 학습했다.

### Zone Transfer 확인

``` bash
named-checkconf /etc/named.conf
named-checkconf /etc/named.rfc1912.zones
systemctl enable --now named

ls /var/named/slaves/
```

실습에서는 최종적으로 다음 파일들이 확인되었다.

``` text
/var/named/slaves/example7777.com.zone
/var/named/slaves/192.168.2.rev
```

역방향 파일 내용 확인에 사용:

``` bash
strings /var/named/slaves/192.168.2.rev
```

핵심 흐름:

``` text
Server1 (Master)
192.168.2.203
      |
      | Zone Transfer
      v
Server2 (Slave)
192.168.2.204
      |
      +-- /var/named/slaves/example7777.com.zone
      +-- /var/named/slaves/192.168.2.rev
```

------------------------------------------------------------------------

## 7. Client1 / Client2 DNS 적용 및 검증

두 Client에서 사용한 DNS 설정:

``` bash
nmcli connection modify ens33 ipv4.dns "192.168.2.203 192.168.2.204" && systemctl restart NetworkManager
cat /etc/resolv.conf
```

예시 결과:

``` text
nameserver 192.168.2.203
nameserver 192.168.2.204
```

### 정방향 조회

``` bash
nslookup www.example7777.com
nslookup ftp.example7777.com
nslookup ns1.example7777.com
nslookup ns2.example7777.com
nslookup mail.example7777.com
nslookup blog.example7777.com
```

핵심 결과:

``` text
www.example7777.com  -> 192.168.2.203
ftp.example7777.com  -> 192.168.2.203
ns1.example7777.com  -> 192.168.2.203
ns2.example7777.com  -> 192.168.2.204
mail.example7777.com -> 192.168.2.204
```

### 역방향 조회

``` bash
nslookup 192.168.2.203
nslookup 192.168.2.204
```

Client1에서는 `.203`에 `www`, `ftp`, `ns1`, `mega.web.test`, `blog` 등의
PTR 결과가, `.204`에는 `mail`, `ns2`가 확인되었다.

### 외부 DNS 조회

``` bash
nslookup www.google.com
nslookup www.naver.com
```

Slave DNS(`192.168.2.204`)를 통한 외부 `www.google.com` 조회도 확인했다.

### `dig` 사용

``` bash
dig example7777.com
dig www.example7777.com
```

`dig www.example7777.com`의 Answer Section에서 다음 A 레코드를 확인했다.

``` text
www.example7777.com. IN A 192.168.2.203
```

### DNS 이름으로 FTP 접속 확인

``` bash
ftp ftp.example7777.com
```

실습에서는 `ftp.example7777.com`이 `192.168.2.203`으로 해석되고 vsFTPd
서버에 연결되는 것을 확인했다.

------------------------------------------------------------------------

# Part 2. Email Server

## 8. 이메일 프로토콜 핵심

  프로토콜       기본 포트 역할
  ------------ ----------- -------------------------------------------
  SMTP              TCP 25 서버 간/실습 환경의 메일 전송
  POP3             TCP 110 서버에서 메일을 가져오는 프로토콜
  IMAP             TCP 143 서버의 메일을 동기화하며 관리
  Submission       TCP 587 메일 클라이언트의 메시지 제출에 주로 사용

이번 실습에서 Server2의 메일 구성은 크게 다음과 같이 볼 수 있다.

``` text
메일 보내기
Evolution -> SMTP -> Sendmail -> /var/spool/mail/<user>

메일 확인
Evolution <- POP3/IMAP <- Dovecot <- /var/spool/mail/<user>
```

------------------------------------------------------------------------

## 9. Server2 - Sendmail 설치

``` bash
yum -y install sendmail
rpm -qa sendmail
rpm -ql sendmail | egrep -v "/doc|/man|/lib"
```

주요 파일:

``` text
/etc/mail/sendmail.cf
/etc/mail/sendmail.mc
/etc/mail/access
/etc/mail/access.db
/etc/mail/local-host-names
/var/spool/mqueue
```

서비스 실행:

``` bash
systemctl enable --now sendmail
systemctl status sendmail
ps -ef | grep sendmail
netstat -ntlp | grep sendmail
```

초기 확인에서는 Sendmail이 다음처럼 localhost의 25번 포트에서 LISTEN하는
상태도 관찰했다.

``` text
127.0.0.1:25 LISTEN
```

설정 변경 후 최종 확인에서는 다음처럼 외부 인터페이스에서도 SMTP가
대기하는 상태를 확인했다.

``` text
0.0.0.0:25 LISTEN
```

------------------------------------------------------------------------

## 10. Sendmail RELAY 설정

수업에서 작성한 내용:

``` text
Connect:example7777.com     RELAY
Connect:192.168.2           RELAY
```

`/etc/mail/access`는 텍스트 설정 파일이며 Sendmail이 사용할 DB 파일을
다시 만들어야 한다.

``` bash
cd /etc/mail
vi access
makemap hash access.db < access
```

확인:

``` bash
file access.db
strings access.db
```

실습에서 `access.db`는 Berkeley DB(Hash)로 확인되었다.

> RELAY는 해당 도메인/네트워크의 메일을 이 메일 서버가 중계할 수 있도록
> 허용하는 설정이다. 실무에서는 무제한 Open Relay가 되지 않도록 허용
> 범위를 엄격히 관리해야 한다.

------------------------------------------------------------------------

## 11. SMTP 동작 확인 - Telnet

Telnet 패키지 설치:

``` bash
yum -y install telnet-server telnet
rpm -qa telnet
rpm -qa telnet-server
rpm -ql telnet | egrep -v "/man|/doc|/lib"
```

SMTP 포트 직접 연결:

``` bash
telnet localhost 25
```

실습에서 확인한 응답:

``` text
220 mail.example7777.com ESMTP Sendmail 8.16.1/8.16.1
```

종료:

``` text
quit
221 2.0.0 mail.example7777.com closing connection
```

즉 TCP 연결뿐 아니라 SMTP 애플리케이션이 실제 응답하는 것까지 확인한
것이다.

Greeting 관련 설정도 확인했다.

``` bash
cat sendmail.cf | grep Greeting
```

``` text
O SmtpGreetingMessage=$j Sendmail $v/$Z; $b
```

------------------------------------------------------------------------

## 12. Dovecot 설치 및 설정

Dovecot은 이번 실습에서 사용자가 메일을 확인할 수 있도록 POP3/IMAP
서비스를 담당했다.

``` bash
yum -y install dovecot
rpm -qa dovecot
rpm -ql dovecot | egrep -v "/doc|/man|/share"
```

실습에서 직접 확인/수정한 주요 설정 파일:

``` text
/etc/dovecot/dovecot.conf
/etc/dovecot/conf.d/10-mail.conf
/etc/dovecot/conf.d/10-ssl.conf
/etc/dovecot/conf.d/10-auth.conf
/etc/dovecot/conf.d/20-pop3.conf
/etc/dovecot/conf.d/20-imap.conf
```

> 업로드된 명령 기록에는 `vi`로 위 파일들을 수정했다는 사실은 남아
> 있지만, 편집기 안에서 변경한 모든 설정값 자체는 기록되어 있지 않다.
> 따라서 여기서는 실제 기록에 없는 값을 임의로 복원하지 않는다.

서비스 적용 및 확인:

``` bash
systemctl restart dovecot
ps -ef | egrep "sendmail|dovecot"
netstat -ntlp | egrep "sendmail|dovecot"
```

최종 실습에서는 다음 포트가 LISTEN 중인 것을 확인했다.

``` text
25/tcp   -> Sendmail
110/tcp  -> Dovecot (POP3)
143/tcp  -> Dovecot (IMAP)
587/tcp  -> Dovecot
```

------------------------------------------------------------------------

## 13. 메일 사용자와 Mail Spool

Server2에서 확인한 메일 저장 위치:

``` bash
ls /var/spool/mail
ls -l /var/spool/mail
```

``` text
/var/spool/mail/user1
/var/spool/mail/user2
```

즉 사용자별 메일이 해당 Mail Spool 파일에 저장되는 구조를 직접 확인했다.

메일 내용 확인:

``` bash
cat /var/spool/mail/user2
cat /var/spool/mail/user1
```

실습에서는 실제로 다음 흐름이 확인되었다.

``` text
Client1 / user1 (192.168.2.201)
        |
        | SMTP
        v
mail.example7777.com
Server2 (192.168.2.204)
        |
        v
/var/spool/mail/user2
```

그리고 user2가 답장을 보내자 `/var/spool/mail/user1`에도 회신 메시지가
저장되었다.

### 추가 사용자 생성 실습

``` bash
useradd user3
echo "user3:centos" | chpasswd
cat /etc/passwd | grep ^user
```

기록에는 `/etc/aliases`와 user1의 `.forward` 파일을 편집한 과정도 있다.

``` bash
vi /etc/aliases
vi /home/user1/.forward
systemctl restart sendmail
```

이는 메일 별칭/전달 관련 실습으로 이어진 부분이다.

------------------------------------------------------------------------

## 14. Client1 / Client2 - Evolution 설치

두 Client에서 GUI 메일 클라이언트인 Evolution을 설치했다.

``` bash
yum -y install evolution
ps -ef | grep yum
```

메일 서버 DNS 확인:

``` bash
nslookup mail.example7777.com
```

결과:

``` text
mail.example7777.com -> 192.168.2.204
```

즉 사용자는 메일 서버 IP를 직접 외우기보다 DNS 이름인
`mail.example7777.com`을 이용할 수 있다.

------------------------------------------------------------------------

## 15. Nmap을 이용한 Server2 서비스 확인

Client1에서 Server2를 스캔했다.

``` bash
nmap -sS -sV 192.168.2.204
```

실습 중 확인된 주요 결과:

``` text
22/tcp open  ssh
25/tcp open  smtp    Sendmail
53/tcp open  domain  BIND
80/tcp open  http    nginx
```

이 명령은 단순히 포트가 열려 있는지만 보는 것이 아니라 `-sV`를 통해
서비스 종류/버전 탐지도 수행한다.

------------------------------------------------------------------------

# Part 3. DNS와 Email의 연결

## 16. 메일 전송에서 DNS가 필요한 이유

DNS와 메일 서버는 독립된 기술이지만 MX 레코드를 통해 연결된다.

``` text
user1@example7777.com
        |
        | 메일 전송 대상 도메인 확인
        v
example7777.com
        |
        | MX 조회
        v
mail.example7777.com
        |
        | A 조회
        v
192.168.2.204
        |
        v
Sendmail
```

따라서 다음 레코드의 연결 관계가 중요하다.

``` dns
example7777.com. IN MX 10 mail.example7777.com.
mail             IN A     192.168.2.204
```

한 줄 암기:

> **MX가 메일 서버의 이름을 알려주고, A 레코드가 그 이름의 IP 주소를
> 알려준다.**

------------------------------------------------------------------------

# Part 4. 실습 검증 루틴

## 17. DNS 점검 순서

``` bash
# 1. 서비스 확인
systemctl status named

# 2. 포트 확인
netstat -ntulp | grep named

# 3. 설정 문법 확인
named-checkconf /etc/named.conf
named-checkconf /etc/named.rfc1912.zones

# 4. Zone 검사
named-checkzone example7777.com /var/named/example7777.com.zone
named-checkzone 2.168.192.in-addr.arpa /var/named/192.168.2.rev

# 5. DNS 설정 확인
cat /etc/resolv.conf

# 6. 정방향 조회
nslookup www.example7777.com
nslookup mail.example7777.com

# 7. 역방향 조회
nslookup 192.168.2.203
nslookup 192.168.2.204

# 8. 상세 DNS 응답 확인
dig www.example7777.com
```

## 18. Mail Server 점검 순서

``` bash
# 1. 서비스 확인
systemctl status sendmail
systemctl status dovecot

# 2. 프로세스 확인
ps -ef | egrep "sendmail|dovecot"

# 3. 포트 확인
netstat -ntlp | egrep "sendmail|dovecot"

# 4. SMTP 직접 확인
telnet localhost 25

# 5. 메일 서버 DNS 확인
nslookup mail.example7777.com

# 6. Mail Spool 확인
ls -l /var/spool/mail
cat /var/spool/mail/user1
cat /var/spool/mail/user2
```

------------------------------------------------------------------------

# Part 5. 오늘 실제로 나온 트러블슈팅 💀

## 19. BIND 설치 중 Repository 오류

### 증상

``` text
Downloading successful, but checksum doesn't match
Cannot download repomd.xml
All mirrors were tried
```

### 실습에서 사용한 우회

ISO가 마운트되어 있음을 `df -h`로 확인하고 AppStream의 RPM을 직접
설치했다.

``` bash
df -h
cd /run/media/root/CentOS-Stream-9-BaseOS-x86_64/AppStream/Packages
rpm -i bind-9.16.23-15.el9.x86_64.rpm
```

### 포인트

``` text
yum/dnf 실패
   -> 저장소/네트워크 문제 확인
   -> 설치 미디어가 있다면 로컬 RPM 활용 가능
```

------------------------------------------------------------------------

## 20. `sendmial` 오타 💀

### 잘못 입력

``` bash
systemctl status sendmial
systemctl restart sendmial
```

### 결과

``` text
Unit sendmial.service could not be found.
```

### 정상 명령

``` bash
systemctl status sendmail
systemctl restart sendmail
```

서비스가 없다고 나올 때는 설치 문제라고 단정하기 전에 **서비스 이름
오타부터 확인**한다.

------------------------------------------------------------------------

## 21. Sendmail이 처음에 localhost에서만 LISTEN

초기 확인:

``` text
127.0.0.1:25 LISTEN
```

이 상태에서는 localhost 접속은 가능하지만 다른 Client가 Server2의 SMTP에
접근하는 목적에는 맞지 않는다.

설정 변경 후 실습 최종 상태:

``` text
0.0.0.0:25 LISTEN
```

따라서 네트워크 서비스 점검에서는 단순히 `:25`가 보이는지만 볼 것이
아니라 **어떤 주소에 Bind되어 있는지**도 확인해야 한다.

------------------------------------------------------------------------

## 22. `telnet localhost 25`에서 IPv6 실패 후 IPv4 성공

``` text
Trying ::1...
Connection refused
Trying 127.0.0.1...
Connected to localhost.
```

이 출력은 Telnet이 먼저 IPv6 loopback(`::1`)을 시도했다가 실패하고 IPv4
loopback(`127.0.0.1`)으로 다시 접속해 성공한 흐름이다.

중요한 것은 최종적으로 SMTP의 `220` Greeting을 받았는지 확인하는 것이다.

------------------------------------------------------------------------

## 23. 디렉터리를 `cat`한 경우

``` bash
cat /var/spool/mail/
```

결과:

``` text
cat: /var/spool/mail/: 디렉터리입니다
```

`/var/spool/mail` 자체는 디렉터리이므로 먼저 목록을 확인한 뒤 사용자별
파일을 읽는다.

``` bash
ls -l /var/spool/mail
cat /var/spool/mail/user1
cat /var/spool/mail/user2
```

------------------------------------------------------------------------

# Part 6. 핵심 명령어 압축

## 24. DNS

``` bash
yum -y install bind
systemctl enable --now named
systemctl status named

named-checkconf /etc/named.conf
named-checkconf /etc/named.rfc1912.zones
named-checkzone example7777.com example7777.com.zone
named-checkzone 2.168.192.in-addr.arpa 192.168.2.rev

nmcli connection modify ens33 ipv4.dns "192.168.2.203 192.168.2.204"
systemctl restart NetworkManager
cat /etc/resolv.conf

nslookup www.example7777.com
nslookup mail.example7777.com
nslookup 192.168.2.203
nslookup 192.168.2.204
dig www.example7777.com
```

## 25. Sendmail / Dovecot

``` bash
yum -y install sendmail dovecot
systemctl enable --now sendmail
systemctl restart dovecot

rpm -qa sendmail
rpm -qa dovecot

ps -ef | egrep "sendmail|dovecot"
netstat -ntlp | egrep "sendmail|dovecot"

cd /etc/mail
makemap hash access.db < access
systemctl restart sendmail

telnet localhost 25

ls -l /var/spool/mail
cat /var/spool/mail/user1
cat /var/spool/mail/user2
```

## 26. Client

``` bash
nmcli connection modify ens33 ipv4.dns "192.168.2.203 192.168.2.204" && systemctl restart NetworkManager
nslookup www.example7777.com
nslookup mail.example7777.com

nmap -sS -sV 192.168.2.204

yum -y install evolution
```

------------------------------------------------------------------------

# Part 7. 시험/면접용 핵심 정리

### Q. A 레코드와 PTR 레코드의 차이는?

-   `A` : 도메인/호스트 이름 -\> IPv4 주소
-   `PTR` : IP 주소 -\> 도메인/호스트 이름

### Q. MX 레코드란?

특정 도메인의 메일을 처리하는 메일 서버를 지정하는 DNS 레코드이다.

### Q. Master DNS와 Slave DNS의 차이는?

-   Master : Zone 원본 데이터를 관리
-   Slave : Master에서 Zone 데이터를 전송받아 복제본을 제공

### Q. Slave DNS를 두는 이유는?

DNS 서비스의 가용성과 분산을 높이고 Master 장애 시에도 DNS 응답을
제공하기 위해 사용한다.

### Q. `named-checkconf`와 `named-checkzone`의 차이는?

``` text
named-checkconf -> named 설정 파일 문법 검사
named-checkzone -> 특정 Zone 파일 검사
```

### Q. Sendmail과 Dovecot의 역할 차이는?

``` text
Sendmail -> 메일 전송(SMTP)
Dovecot  -> 사용자가 메일을 조회/수신(POP3/IMAP)
```

### Q. `makemap hash access.db < access`는 왜 사용하는가?

`/etc/mail/access`에 작성한 Sendmail 접근/Relay 정책을 Sendmail이 사용할
DB 형식인 `access.db`로 반영하기 위해 사용한다.

### Q. 메일이 실제 서버에 도착했는지 CLI에서 확인하려면?

이번 실습에서는 다음처럼 Mail Spool을 확인했다.

``` bash
ls -l /var/spool/mail
cat /var/spool/mail/user1
cat /var/spool/mail/user2
```

------------------------------------------------------------------------

# 28. 오늘의 최종 흐름

``` text
[1] Server1에서 Master DNS 구축
        |
        +-- Forward Zone
        +-- Reverse Zone
        +-- A / NS / MX / CNAME / PTR
        |
        v
[2] Server2에서 Slave DNS 구축
        |
        +-- Server1에서 Zone Transfer
        +-- /var/named/slaves 확인
        |
        v
[3] Client1 / Client2 DNS 설정
        |
        +-- nslookup
        +-- dig
        +-- 정방향/역방향 조회
        |
        v
[4] Server2 Sendmail 구축
        |
        +-- SMTP 25
        +-- RELAY
        +-- access.db
        +-- Telnet 검증
        |
        v
[5] Server2 Dovecot 구축
        |
        +-- POP3 110
        +-- IMAP 143
        |
        v
[6] Client1 / Client2 Evolution 설치
        |
        v
[7] user1 <------ 실제 메일 송수신 ------> user2
        |
        v
[8] /var/spool/mail에서 실제 메시지 확인
```

------------------------------------------------------------------------

# 한 줄 총정리

> **DNS는 `example7777.com`의 각 서비스가 어디에 있는지 찾아주고, MX
> 레코드는 메일 서버 `mail.example7777.com`을 가리키며, Server2의
> Sendmail이 SMTP 전송을 담당하고 Dovecot이 POP3/IMAP 수신을 담당한다.
> Master/Slave DNS와 두 Client를 함께 구성하여 이름 해석부터 실제 메일
> 송수신까지 전체 흐름을 실습했다.**

------------------------------------------------------------------------

## 실습 파일 기준 메모

이 문서는 `Server1-0826.txt`, `Server2-0826.txt`, `Client1-0826.txt`,
`Client2-0826.txt`에 기록된 실제 명령어와 대화에서 제공된 Zone/RELAY
설정을 중심으로 재구성했다. `vi` 내부에서 변경한 값처럼 명령 기록에 남지
않은 세부 설정은 임의로 만들어 넣지 않았다.