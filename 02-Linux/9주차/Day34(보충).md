# Linux Web Server 심화 핵심 정리

> **학습 주제:** Apache(httpd), PHP, MariaDB, VirtualHost, 웹 접근 인증, Directory Listing, Tomcat/JSP, Nginx

---

## 1. 오늘의 전체 흐름

```text
Client
  │
  ├─ Apache(httpd) ─ PHP ─ MariaDB
  │       ├─ 일반/관리자 웹 페이지
  │       ├─ CGI / Perl
  │       ├─ .htaccess 인증
  │       └─ VirtualHost
  │
  ├─ Tomcat ─ JSP ─ JDBC ─ MariaDB
  │
  └─ Nginx
          ├─ VirtualHost
          └─ Directory Listing 설정
```

핵심은 **웹 서버가 요청을 받아 적절한 콘텐츠/애플리케이션을 실행하고, 필요하면 DB와 연동하여 결과를 반환하는 과정**을 이해하는 것이다.

---

# 2. Apache(httpd) 웹 서비스

## 주요 URL과 실제 파일 경로

| 접속 URL | 실제 경로 | 용도 |
|---|---|---|
| `http://192.168.2.203` | `/www/index.html` | 펜션 홈페이지 |
| `http://192.168.2.203/admin/` | `/www/admin/index.html` | 관리자 홈페이지 |
| `http://192.168.2.203/cgi-bin/test.sh` | `/www/cgi-bin/test.sh` | Bash CGI 페이지 |
| `http://192.168.2.203/perl/test.pl` | `/www/perl/test.pl` | Perl CGI 페이지 |
| `http://192.168.2.203/index.php` | `/www/index.php` | `phpinfo()` 확인 |
| `http://192.168.2.203/test.php` | `/www/test.php` | PHP ↔ DB 연동 테스트 |
| `http://192.168.2.203/cmd.php` | `/www/cmd.php` | 교육용 웹 쉘 실습 |
| `/main.php` | `/www/main.php` | PHP 회원가입 페이지 |

### PHP + MariaDB 흐름

```text
Browser → Apache → PHP → MariaDB
                         │
                         └─ 회원정보 저장/조회
```

PHP가 DB에 SQL을 전달하고 MariaDB가 처리 결과를 반환한다.

---

# 3. `.htaccess` 웹 접근 인증

`.htaccess`를 사용하면 특정 디렉터리에 대한 웹 접근 인증 등의 설정을 적용할 수 있다.

```text
Client → 보호된 URL 요청
             ↓
        Apache 인증 확인
             ↓
       성공 → 페이지 접근
       실패 → 접근 거부
```

> 실제 적용 가능 여부는 Apache의 `AllowOverride` 설정 등에 영향을 받는다.

### Apache 설정 검사

```bash
httpd -t
```

설정 파일의 **문법 오류를 검사**한다.

> `httpd -t`는 SQL 쿼리를 검사하는 명령이 아니라 **Apache 설정 문법 검사 명령**이다.

권장 흐름:

```text
설정 수정 → httpd -t → reload/restart → 접속 테스트
```

---

# 4. Apache VirtualHost

VirtualHost는 **하나의 Apache 서버에서 여러 웹 사이트를 서비스**하기 위한 기능이다.

## 4-1. 이름 기반 VirtualHost

```apache
<VirtualHost *:80>
    DocumentRoot "/www1"
    ServerName www1.example7777.com

    <Directory "/www1">
        Require all granted
    </Directory>
</VirtualHost>
```

클라이언트 이름 해석 예:

```text
192.168.2.203 www1.example7777.com
192.168.2.203 www2.example7777.com
192.168.2.203 www3.example7777.com
```

### 핵심

```text
동일 IP + 동일 Port
        ↓
요청 Host 이름으로 사이트 구분
```

---

## 4-2. IP 기반 VirtualHost

NIC 하나에 여러 IP를 추가할 수 있다.

```bash
nmcli connection modify ens33 \
+ipv4.addresses 192.168.2.210/24 \
+ipv4.addresses 192.168.2.220/24 \
+ipv4.addresses 192.168.2.230/24

nmcli connection up ens33
```

예:

```apache
<VirtualHost 192.168.2.210:80>
    DocumentRoot "/www1"
    ServerName www1.example7777.com

    <Directory "/www1">
        Require all granted
    </Directory>
</VirtualHost>
```

구조:

```text
192.168.2.210:80 → /www1
192.168.2.220:80 → /www2
192.168.2.230:80 → /www3
```

추가 IP 제거:

```bash
nmcli connection modify ens33 \
-ipv4.addresses 192.168.2.210/24 \
-ipv4.addresses 192.168.2.220/24 \
-ipv4.addresses 192.168.2.230/24

nmcli connection up ens33
```

> NetworkManager 속성명은 `ipv4.addresses`로 기억한다.

---

## 4-3. 포트 기반 VirtualHost

```apache
Listen 8081
Listen 8082
Listen 8083

<VirtualHost 192.168.2.203:8081>
    DocumentRoot "/www1"
    ServerName www.example7777.com

    <Directory "/www1">
        Require all granted
    </Directory>
</VirtualHost>
```

구조:

```text
192.168.2.203:8081 → /www1
192.168.2.203:8082 → /www2
192.168.2.203:8083 → /www3
```

---

# 5. VirtualHost 3종 비교

| 방식 | 구분 기준 | 예 |
|---|---|---|
| 이름 기반 | 도메인/Host | `www1.example7777.com` |
| IP 기반 | 목적지 IP | `192.168.2.210` |
| 포트 기반 | TCP Port | `8081`, `8082`, `8083` |

### 암기

```text
이름 기반 = 이름이 다르다
IP 기반   = IP가 다르다
포트 기반 = Port가 다르다
```

---

# 6. Directory Listing 취약점

웹 디렉터리에 `index.html` 등의 기본 문서가 없는데 디렉터리 목록 출력 기능이 활성화되어 있으면 파일 목록이 노출될 수 있다.

```text
GET /doc/
   ↓
index 파일 없음
   ↓
Directory Listing 활성화
   ↓
파일 목록 노출
```

Apache에서는 `Options Indexes`, Nginx에서는 `autoindex on`이 관련 설정이다.

검색 패턴 실습 예:

```text
intitle:"index of" intext:DCIM
```

이는 검색엔진에 노출된 디렉터리 인덱스의 형태를 이해하기 위한 예이다.

### 방어 핵심

```text
불필요한 Directory Listing 비활성화
민감한 파일을 Web Root 아래에 두지 않기
접근 권한 최소화
```

---

# 7. Tomcat + JSP + MariaDB

Tomcat은 Java Servlet/JSP를 실행할 수 있는 Java 웹 애플리케이션 서버(서블릿 컨테이너)이다.

설치 파일 다운로드 실습 예:

```bash
cd /usr/local
wget https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.121/bin/apache-tomcat-9.0.121.tar.gz
```

## JSP의 정체

```jsp
<%@ page import="java.sql.*"%>
```

```jsp
<%
    // Java 코드
%>
```

`<% ... %>`는 JSP **Scriptlet(스크립틀릿)** 문법이다.

### JDBC 연동 흐름

```text
Browser
   ↓
Tomcat
   ↓
JSP
   ↓
MariaDB JDBC Driver
   ↓
MariaDB :3306
   ↓
SELECT 실행
   ↓
ResultSet
   ↓
HTML 응답
```

주요 JDBC 코드:

```java
Class.forName("org.mariadb.jdbc.Driver");
conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
stmt = conn.createStatement();
rs = stmt.executeQuery(query);
```

결과 조회:

```java
while (rs.next()) {
    out.println(rs.getString(1));
    out.println(rs.getString(4));
}
```

자원 정리:

```java
rs.close();
stmt.close();
conn.close();
```

> 이 코드는 PHP가 아니라 **JSP + Java JDBC 코드**이다.

---

# 8. Nginx VirtualHost(Server Block)

Nginx에서는 Apache의 VirtualHost와 비슷한 역할을 `server {}` 블록이 담당한다.

## 8-1. 이름 기반

Client1:

```text
192.168.2.204 www1.example8888.com
192.168.2.204 www2.example8888.com
192.168.2.204 www3.example8888.com
```

Server2 `/etc/nginx/conf.d/vhost.conf`:

```nginx
server {
    listen 80;
    server_name www1.example8888.com;
    root /www1;
    index index.html;
}
```

핵심:

```text
같은 IP:80 → server_name으로 구분
```

---

## 8-2. IP 기반

```bash
nmcli connection modify ens33 \
+ipv4.addresses 192.168.2.211/24 \
+ipv4.addresses 192.168.2.221/24 \
+ipv4.addresses 192.168.2.231/24

nmcli connection up ens33
```

```nginx
server {
    listen 192.168.2.211:80;
    server_name www1.example8888.com;
    root /www1;
    index index.html;
}
```

구조:

```text
192.168.2.211:80 → /www1
192.168.2.221:80 → /www2
192.168.2.231:80 → /www3
```

제거:

```bash
nmcli connection modify ens33 \
-ipv4.addresses 192.168.2.211/24 \
-ipv4.addresses 192.168.2.221/24 \
-ipv4.addresses 192.168.2.231/24

nmcli connection up ens33
```

---

## 8-3. 포트 기반

```nginx
server {
    listen 8081;
    server_name www1.example8888.com;
    root /www1;
    index index.html;
}

server {
    listen 8082;
    server_name www2.example8888.com;
    root /www2;
    index index.html;
}

server {
    listen 8083;
    server_name www3.example8888.com;
    root /www3;
    index index.html;
}
```

```text
:8081 → /www1
:8082 → /www2
:8083 → /www3
```

### 설정 파일 이름 변경

```bash
mv vhost.conf vhost.conf.name-based
mv vhost.conf vhost.conf.ip-based
mv vhost.conf vhost.conf.port-based
```

`conf.d`가 일반적으로 `*.conf` 파일을 include하므로 `.conf`로 끝나지 않게 변경하여 **실습 설정을 백업하면서 활성 설정에서 제외**하는 방식으로 사용할 수 있다.

---

# 9. Nginx Directory Listing

실습:

```bash
mkdir -p /usr/share/nginx/html/doc
cp -p /etc/passwd /usr/share/nginx/html/doc/
ls -l /usr/share/nginx/html/doc/
```

웹 루트:

```nginx
root /usr/share/nginx/html;
```

따라서 `/doc/` 요청은 다음 경로를 바라본다.

```text
http://SERVER/doc/
        ↓
/usr/share/nginx/html/doc/
```

Directory Listing 활성화:

```nginx
autoindex on;
```

방어:

```nginx
autoindex off;
```

또는 불필요한 `autoindex on;` 설정을 제거한다.

> `/etc/passwd` 복사는 취약점의 위험성을 확인하기 위한 교육용 예시이다. 실제 운영 환경에서는 민감한 시스템 파일을 웹 루트에 두면 안 된다.

### Nginx 설정 검사

```bash
nginx -t
```

---

# 10. Apache vs Nginx

| 기능 | Apache | Nginx |
|---|---|---|
| 가상 호스트 | `<VirtualHost>` | `server {}` |
| 도메인 | `ServerName` | `server_name` |
| 웹 루트 | `DocumentRoot` | `root` |
| 포트 | `Listen` | `listen` |
| 디렉터리 설정 | `<Directory>` | `location` 등 |
| Directory Listing | `Options Indexes` | `autoindex on` |
| 설정 검사 | `httpd -t` | `nginx -t` |

---

# 11. Apache / Nginx / Tomcat 비교

| 서버 | 핵심 역할 |
|---|---|
| Apache(httpd) | 범용 웹 서버, PHP/CGI 등의 서비스 구성 |
| Nginx | 웹 서버, Reverse Proxy, 정적 콘텐츠 처리 등에 널리 사용 |
| Tomcat | Java Servlet/JSP 실행 환경 |

간단 암기:

```text
Apache → 웹 서버
Nginx  → 웹 서버 / Reverse Proxy
Tomcat → Java 웹 애플리케이션
```

---

# 12. MariaDB 기본 SQL

## 테이블 생성 - CREATE

```sql
CREATE TABLE linux (
    id INT,
    login VARCHAR(10),
    password VARCHAR(10),
    username VARCHAR(20),
    age INT
);
```

`cisco`, `security`, `java` 테이블도 동일한 형태로 생성하였다.

---

## 데이터 삽입 - INSERT

```sql
INSERT INTO cisco
VALUES (1, 'cisco1', 'cisco1111', 'jeong yun gu', 23);
```

---

## 데이터 수정 - UPDATE

```sql
UPDATE cisco
SET username='jeong yun gu'
WHERE login='cisco2';
```

> `WHERE`가 없으면 여러 행이 한꺼번에 수정될 수 있으므로 주의한다.

---

## 데이터 삭제 - DELETE

```sql
DELETE FROM cisco
WHERE id=3;
```

> 숫자형 컬럼은 `id='3'`보다 `id=3`처럼 쓰는 것이 명확하다.

---

## 테이블 구조 변경 - ALTER

컬럼 크기 변경:

```sql
ALTER TABLE linux
MODIFY login VARCHAR(20);
```

첫 번째 위치에 컬럼 추가:

```sql
ALTER TABLE linux
ADD email VARCHAR(40) FIRST;
```

컬럼 크기와 위치 변경:

```sql
ALTER TABLE linux
MODIFY email VARCHAR(20) AFTER username;
```

---

# 13. SQL 명령 분류

| 명령 | 역할 | 분류 |
|---|---|---|
| `CREATE` | 객체 생성 | DDL |
| `ALTER` | 객체 구조 변경 | DDL |
| `SELECT` | 데이터 조회 | DQL로 별도 분류하기도 함 |
| `INSERT` | 데이터 삽입 | DML |
| `UPDATE` | 데이터 수정 | DML |
| `DELETE` | 데이터 삭제 | DML |

---

# 14. 오늘의 핵심 명령어

```bash
# Apache 설정 검사
httpd -t

# Nginx 설정 검사
nginx -t

# NetworkManager 추가 IP
nmcli connection modify ens33 +ipv4.addresses IP/24
nmcli connection up ens33

# Tomcat 다운로드 예시
cd /usr/local
wget <Tomcat URL>
```

---

# 15. 시험/면접용 핵심 Q&A

### Q1. VirtualHost란?
하나의 웹 서버에서 여러 웹 사이트를 구분하여 서비스하는 기능이다.

### Q2. 이름 기반 VirtualHost의 구분 기준은?
HTTP 요청의 호스트 이름(Host)을 기준으로 구분한다.

### Q3. IP 기반 VirtualHost는?
서버가 가진 여러 목적지 IP 주소를 기준으로 사이트를 구분한다.

### Q4. 포트 기반 VirtualHost는?
동일한 IP에서도 서로 다른 TCP 포트를 이용해 사이트를 구분한다.

### Q5. Directory Listing이 왜 위험한가?
웹 디렉터리의 파일 목록과 구조가 외부에 노출되어 민감 정보나 공격에 유용한 정보를 제공할 수 있기 때문이다.

### Q6. Apache와 Nginx 설정 검사 명령은?

```bash
httpd -t
nginx -t
```

### Q7. Tomcat은 무엇인가?
Java Servlet/JSP를 실행하는 서블릿 컨테이너이자 Java 웹 애플리케이션 서버로 사용된다.

### Q8. JDBC의 역할은?
Java 애플리케이션과 관계형 DB 사이의 연결 및 SQL 실행을 위한 표준 API이다.

### Q9. `ResultSet`이란?
`SELECT` 등의 SQL 실행 결과를 Java에서 읽을 수 있도록 보관하는 객체이다.

### Q10. `autoindex on`의 의미는?
Nginx에서 조건이 맞을 때 디렉터리 내부 파일 목록을 웹 페이지로 표시하도록 허용하는 설정이다.

---

# 16. 오늘의 최종 암기 포인트

```text
[VirtualHost]
이름 기반 → Host/도메인
IP 기반   → IP 주소
포트 기반 → Port 번호

[설정 검사]
Apache → httpd -t
Nginx  → nginx -t

[Directory Listing]
Apache → Options Indexes
Nginx  → autoindex on

[동적 웹/DB]
PHP → MariaDB
JSP → JDBC → MariaDB

[서버]
Apache → Web Server
Nginx  → Web Server / Reverse Proxy
Tomcat → Java Servlet/JSP

[SQL]
CREATE / ALTER → 구조 관리
SELECT         → 조회
INSERT         → 추가
UPDATE         → 수정
DELETE         → 삭제
```

---

## 한 줄 요약

> **Apache와 Nginx의 이름/IP/포트 기반 가상 호스트를 구성하고, PHP·JSP를 MariaDB와 연동하며, 웹 접근 인증과 Directory Listing 취약점까지 확인함으로써 Linux 웹 서버의 서비스 구성·DB 연동·기본 보안 구조를 종합적으로 실습하였다.**
