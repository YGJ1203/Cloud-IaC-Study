# 2026-11-02 네트워크·시스템 보안 실습 총정리

> **실습일:** 2026-11-02 (월)  
> **실습 환경:** Kali Linux, CentOS 5, Windows Server 2008, VMware, Nessus Essentials, FortiGate VM64 (FortiOS 7.4.11)  
> **범위:** Nmap → Netcat Bind/Reverse Shell → Linux SUID/SGID → 백도어 탐지 및 제거 → Nessus → FortiGate NGFW/IPS  
> **자료 기준:** 대화에 제공된 CLI 출력·스크린샷, FortiGate `default.pdf`(13쪽).  
> **중요:** FortiGate PDF의 **생성일은 11월 2일이나 집계 기간은 11월 1일**이다. 오늘 수행한 모든 실습이 해당 PDF에 반영되었다고 볼 수 없다.

---

## 1. 오늘의 핵심 성과

1. Nmap으로 CentOS의 기본 서비스 포트와 **4444/tcp 백도어 포트**를 구분해 탐색했다.
2. 실습용 CentOS에서 Netcat **Bind Shell**과 **Reverse Shell** 통신을 확인하고, Wireshark에서 TCP 세션을 관찰했다.
3. 일반 사용자와 root의 권한 차이를 확인한 후, **SUID 설정에 따른 권한 상승**을 실습했다.
4. SUID 파일 목록을 전후 비교해 `/tmp/backdoor`가 추가되었음을 식별하고 삭제했다.
5. Kali에서 **Nessus Essentials** 관리 화면에 접속하고 Windows2008/CentOS5 취약점 스캔 작업을 구성했다. 결과의 CVE별 상세 내용은 제공되지 않았다.
6. **FortiGate 교재 실습 23단계를 완료했다고 보고**했다. 제공된 화면으로 인터페이스 및 GUI 접속을 확인했고, 일일 보안 보고서에서 침입 탐지·차단 이벤트를 확인했다.

### 실습 자산 및 역할

| 장비 | IP / 식별 | 용도 | 확인 근거 |
|---|---|---|---|
| Kali Linux | `192.168.20.50` | Nmap, Netcat, Wireshark, Nessus | CLI 및 Nessus URL |
| CentOS 5 | `192.168.20.200` | 취약 서버 및 권한 상승 실습 | Nmap/쉘 출력 |
| FortiGate port1 | `192.168.2.100/24` | 외부측 인터페이스 | FortiGate GUI |
| FortiGate port2 | `192.168.20.100/24` | 내부측 인터페이스 | FortiGate GUI |
| Nessus 관리 | `https://192.168.20.50:8834` | 취약점 진단 웹 콘솔 | 브라우저 화면 |
| FortiGate 관리 | `https://192.168.20.100` | 방화벽 웹 콘솔 | 브라우저 화면 |
| Windows Server 2008 | IP 미확인 | Nessus 스캔 대상 | 스캔 목록 화면 |

> **주의:** FortiGate 일일 보고서에는 침입 **출발지 `192.168.2.50`**, 피해 대상 **`192.168.20.200`**이 기록되어 있다. 대화에서 확인된 Kali IP `192.168.20.50`과 출발지 IP가 다르므로, 같은 세션/장비라고 단정하지 않는다.

---

## 2. Nmap 서비스 탐색

### 2.1 기본 서비스 버전 확인

```bash
nmap -sS -sV 192.168.20.200
```

- `-sS`: TCP SYN 기반 포트 스캔
- `-sV`: 열린 포트에서 서비스 및 버전 식별

**관측 결과: 기본 1,000개 TCP 포트 중 13개 open, 987개 closed.**

| 포트 | 서비스 | Nmap 버전 탐지 |
|---|---|---|
| 21/tcp | FTP | vsftpd 2.0.5 |
| 22/tcp | SSH | OpenSSH 4.3 |
| 23/tcp | Telnet | BSD-derived telnetd |
| 25/tcp | SMTP | Sendmail 8.13.8 |
| 53/tcp | DNS | ISC BIND 9.3.6-P1 |
| 80/tcp | HTTP | Apache httpd 2.2.3 |
| 110/tcp | POP3 | Dovecot pop3d |
| 111/tcp | RPC | rpcbind 2 |
| 143/tcp | IMAP | Dovecot imapd |
| 443/tcp | HTTPS | Apache httpd 2.2.3 |
| 993/tcp | IMAPS | Dovecot imapd |
| 995/tcp | POP3S | Dovecot pop3d |
| 3306/tcp | MySQL | MySQL (unauthorized) |

**해석:** 버전이 오래되어 취약 가능성을 조사할 필요가 있지만, 배포판의 보안 패치 백포트 및 실제 설정을 확인하지 않고 특정 CVE의 취약성을 확정해서는 안 된다.

### 2.2 기본 스캔에 없던 4444 포트 조사

```bash
nmap -sS -sV -p 4444 192.168.20.200
```

관측 출력:

```text
4444/tcp open backdoor No-auth shell (**BACKDOOR**)
```

**핵심:** Nmap의 기본 스캔은 모든 65,535개 TCP 포트를 조사하는 것이 아니다. 이번 `4444/tcp`는 명시적 지정 후 발견되었다. `No-auth shell`은 인증 없이 명령 실행이 가능한 서비스라는 강한 경고 신호이며, 실제 `nc` 접속 후 `id` 출력으로 권한을 검증했다.

---

## 3. Netcat 백도어와 쉘 통신

> 이 절은 **승인된 폐쇄형 교육 실습의 재현 기록 및 방어 분석**이다. 외부 시스템에 적용해서는 안 된다.

### 3.1 Bind Shell 관찰

Kali에서 실습 서버의 4444 포트에 접속:

```bash
nc 192.168.20.200 4444
id
uname -a
```

관측 출력:

```text
uid=0(root) gid=0(root) groups=0(root),1(bin),2(daemon),3(sys),4(adm),6(disk),10(wheel)
Linux CentOS 2.6.18-371.el5 ... x86_64 GNU/Linux
```

`python -c 'import pty;pty.spawn("/bin/bash")'`로 PTY를 할당해 프롬프트를 얻었으며, `/etc/passwd`, `whoami`를 통해 원격 쉘의 사용자 정보를 확인했다.

- **Bind Shell:** 대상 서버가 포트를 열고 대기하며, 외부 클라이언트가 그 포트로 접속하는 방식.
- 실습 서버에서 `netstat -ntlp | grep 4444` 결과 `0.0.0.0:4444 LISTEN`을 확인했다.
- 연결 후 `netstat -ntp | grep 4444`에서 `192.168.20.200:4444` ↔ `192.168.20.50:60668`, `ESTABLISHED`, `bash` 프로세스를 확인했다.
- 일부 연결 직후 `Exit 127`이 출력되었고, 재시도 후 연결이 관찰되었다. 실패 원인은 로그만으로 확정할 수 없다.

### 3.2 Reverse Shell 관찰

Kali에서 4444 포트를 수신 대기한 뒤, 실습 CentOS가 Kali로 역방향 연결한 기록이 있다.

```text
Kali listener: 192.168.20.50:4444
CentOS source: 192.168.20.200:39960
connect to [192.168.20.50] from [192.168.20.200] 39960
```

- **Reverse Shell:** 대상 서버가 외부의 수신 대기 장비로 먼저 연결하는 방식.
- 네트워크 관점에서 Bind는 **대상으로 향하는 접속**, Reverse는 **대상에서 나오는 접속**이라는 차이가 있다.
- 방화벽 탐지 시 방향, 목적지 포트, 연결 주체, 프로세스, 트래픽 내용 등을 함께 분석한다.

### 3.3 Wireshark에서 확인한 사항

화면 필터: `tcp`

- `192.168.20.50:60668` ↔ `192.168.20.200:4444` 통신
- `192.168.20.200:39960` ↔ `192.168.20.50:4444` 통신
- `SYN`, `SYN, ACK`, `ACK`와 데이터 전달 중 `PSH, ACK`, 종료 시 `FIN, ACK` 관찰
- `PSH, ACK`는 데이터 전달 시 흔히 나타나지만, **그 자체로 악성 트래픽이라는 의미는 아니다**.

**방어 관점 체크:** 예상하지 못한 포트 리스닝, 셸 프로세스와 네트워크 연결의 결합, 외부로 향하는 비정상 장시간 세션, 자산 변경 이력을 확인한다.

---

## 4. Linux 권한 모델: SUID·SGID

### 4.1 기본 권한과 특수 권한

| 항목 | 의미 | 표기 예 |
|---|---|---|
| 일반 실행 | 소유자·그룹·기타 사용자 실행 비트 | `-rwxr-xr-x` |
| SUID | 실행 시 유효 사용자 ID가 파일 소유자로 설정될 수 있음 | `-rwsr-xr-x` |
| SGID | 실행 시 유효 그룹 ID가 파일 그룹으로 설정될 수 있음 | `-rwxr-sr-x` |
| 대문자 `S` | 특수 권한 비트는 있지만 해당 실행 비트는 없음 | `-rwSr-xr-x` |

**실습 출력:**

```text
chmod 4755 file1  → -rwsr-xr-x
chmod 4655 file1  → -rwSr-xr-x
chmod 2755 file1  → -rwxr-sr-x
chmod 2765 file1  → -rwxrwSr-x
```

> `file1`은 `touch`로 만든 **0바이트 일반 파일**이었다. 표시되는 권한 비트의 의미를 관찰한 것이며, 이 파일로 권한 상승이 실행되었다는 뜻은 아니다.

### 4.2 `/usr/sbin/usermod` SUID 권한 실험

초기:

```text
-rwxr-xr-x 1 root root ... /usr/sbin/usermod
```

- root에서 `usermod -s /bin/csh user01` 실행 후 `user01`의 로그인 쉘이 `/bin/csh`로 변경됨.
- 일반 사용자 `user01`에서는 같은 종류의 변경 시도에 `열쇠글 파일 잠금을 할 수 없습니다`라는 오류가 발생함.
- root가 `/usr/sbin/usermod`에 SUID 비트를 추가한 뒤 권한이 `-rwsr-xr-x`로 변경됨.
- 이후 `user01`이 `usermod -s /bin/bash user01`을 실행했고, `nscd` 관련 경고가 있었지만 `/etc/passwd`에 `/bin/bash`로 변경된 결과가 확인됨.

**해석:** root 소유의 관리 프로그램에 불필요한 SUID를 부여하면 일반 사용자에게 의도하지 않은 관리 작업 권한이 생길 수 있다. `nscd` 경고가 출력되었다는 사실도 기록하되, 변경 자체는 확인되었다.

**실습 후 원상 복구 점검:**

```bash
ls -l /usr/sbin/usermod
# 실습에서 추가한 SUID 비트가 남아 있다면, 승인된 실습 환경에서만:
chmod u-s /usr/sbin/usermod
```

### 4.3 `/etc/passwd`와 `/etc/shadow`

```text
/etc/passwd  → -rw-r--r--
/etc/shadow  → -r--------
```

- `/etc/passwd`는 계정 이름, UID, GID, 홈 디렉터리, 로그인 쉘 등을 포함한다.
- `/etc/shadow`는 비밀번호 해시 등 민감한 인증 정보를 담는다.
- 파일의 읽기 권한 차이를 확인했으며, 계정 정보 파일을 직접 변조하는 실습은 기록되지 않았다.

---

## 5. SUID 백도어 프로그램 실습과 탐지

### 5.1 실습 관찰 결과

`/tmp/backdoor.c`를 컴파일할 때 첫 시도는 C 소스 첫 줄의 문법 오류로 실패했고, 수정 후 빌드에 성공했다.

```text
gcc -o backdoor backdoor.c
-rwxr-xr-x 1 root root 6.9K ... backdoor
```

이후 root 소유 바이너리에 SUID가 설정되어 다음과 같이 표시되었다.

```text
-rwsr-xr-x 1 root root 6980 ... /tmp/backdoor
```

일반 사용자 `user01`의 초기 ID:

```text
uid=500(user01) gid=500(user01) groups=500(user01)
```

해당 실습 바이너리를 실행한 후:

```text
uid=0(root) gid=0(root) groups=500(user01)
```

**해석:** 실행 결과에서 UID와 GID가 모두 0으로 바뀌었고, 보조 그룹 목록에는 `user01`이 남아 있었다. 즉, SUID가 적용된 바이너리를 통한 권한 상승이 실습 환경에서 확인되었다. 실제 운영 서버에서 이와 같은 바이너리는 매우 위험하다.

> **보안상 유의:** 원본 소스는 실습 기록에 존재하지만, 이 복습 문서에서는 권한 상승 백도어의 재배포용 전체 소스 코드를 반복 제공하지 않고 결과와 탐지·대응에 초점을 맞춘다.

### 5.2 SUID 기준선 비교

실습에서 사용한 탐색 명령:

```bash
find / -perm -4000 2> /dev/null
```

두 시점의 SUID 파일 목록을 저장한 뒤 비교:

```text
diff setuid_1.txt setuid_2.txt
37a38
> /tmp/backdoor
```

**해석:** 이전 목록에는 없던 `/tmp/backdoor`가 현재 목록에 추가된 것으로 나타났다. `diff`는 파일이 악성인지 자동 판정하는 도구가 아니라 **두 텍스트 목록의 차이**를 표시하는 도구다.

처음에는 기준선 파일이 `/root/nc/setuid_1.txt`에 있어 비교에 실패했고, 이를 `/root`로 이동한 뒤 정상 비교했다.

### 5.3 더 신뢰할 수 있는 점검 방식

```bash
# 승인된 서버에서 SUID 경로를 정렬하여 목록화
find / -type f -perm -4000 2>/dev/null | sort > suid_current.txt

# 정상 기준선과 비교
diff -u suid_baseline.txt suid_current.txt

# 특정 의심 파일의 소유자·권한·해시 확인
stat /tmp/backdoor
sha256sum /tmp/backdoor
```

- **정렬:** `find` 출력 순서 차이에 의한 불필요한 diff를 줄인다.
- **기준선 신뢰성:** 기준 파일을 공격자가 수정할 수 없도록 별도 보호한다.
- **추가 점검:** 기존 SUID 파일의 소유권·권한·해시 변경까지 탐지하려면 경로 목록 비교만으로는 부족하다.
- **삭제 전 증거 보존:** 실제 침해사고에서는 즉시 삭제보다 격리, 로그·해시·프로세스 증거 확보, 영향 범위 조사 등 대응 절차를 우선한다.

### 5.4 실습 정리

```text
rm -rf /tmp/backdoor
ls -l /tmp/backdoor
→ 그런 파일이나 디렉토리가 없음
```

**확인된 사실:** `/tmp/backdoor` 경로에서 파일이 사라졌다. **미확인 사항:** 다른 위치에 복제본이 없는지, 프로세스가 남아 있는지, 전체 시스템이 정상 복구되었는지 등은 추가 검증이 필요하다.

---

## 6. Nessus Essentials 취약점 진단

### 6.1 설치 및 접근

- 초기 `Welcome to Nessus` 설정 화면 확인
- Kali 브라우저에서 `https://192.168.20.50:8834` 접속
- `Nessus Essentials` 웹 콘솔 및 Scan Templates 확인

### 6.2 스캔 템플릿

| 템플릿 | 목적 |
|---|---|
| Host Discovery | 활성 호스트 탐색 |
| Ping-Only Discovery | 최소한의 Ping 중심 호스트 탐색 |
| Basic Network Scan | 기본 네트워크 취약점 검사 |
| Credential Validation | 제공한 인증 정보가 유효한지 확인 |
| Advanced Scan | 플러그인·포트 등 세부 옵션 조정 |
| Web Application Tests | 웹 애플리케이션 취약점 검사 |

### 6.3 스캔 작업 목록

화면에는 다음 **2개 작업**이 표시되었다.

| 이름 | 유형 | 스케줄 | 화면의 마지막 스캔 표시 |
|---|---|---|---|
| Windows2008 | Vulnerability | On Demand | Today at 12:27 PM |
| CentOS5 | Vulnerability | On Demand | Today at 12:27 PM |

**판단 한계:** 목록 화면만으로 완료 여부, 취약점 총개수, Critical/High 건수, CVE, 실제 취약성 확인 여부는 알 수 없다. 결과 화면이나 개별 플러그인 상세 보고서가 필요하다.

### 6.4 Nmap과 Nessus 비교

| 도구 | 중심 질문 | 결과 예 |
|---|---|---|
| Nmap | 어떤 호스트·포트·서비스가 보이는가? | 4444/tcp open, Apache 2.2.3 |
| Nessus | 알려진 취약점·설정 문제는 무엇인가? | 플러그인 결과, CVE, 위험도, 해결 방안 |

**권장 분석 흐름:** Nmap 자산/서비스 파악 → Nessus 취약점 후보 도출 → 버전·패치·설정 검증 → 위험도 평가 → 조치 → 재검사.

---

## 7. FortiGate NGFW 구축 및 운영

### 7.1 완료 범위와 확인 수준

사용자는 **교재 기준 23단계 전체 완료**를 알렸다. 제공된 증빙은 FortiGate 초기 대시보드, 한글 GUI의 인터페이스 화면, 자동 생성 일일 보안 보고서다. 따라서 아래 내용은 **직접 확인된 설정**과 **완료 진술**을 구분한다.

| 항목 | 상태 | 근거 |
|---|---|---|
| FortiGate VM 실행 및 GUI 접속 | 확인 | Dashboard 화면 |
| FortiOS 버전 7.4.11 build2878 | 확인 | Dashboard 화면 |
| NAT 운영 모드 | 확인 | Dashboard 화면 |
| port1 `192.168.2.100/24` | 확인 | Interface 화면 |
| port2 `192.168.20.100/24` | 확인 | Interface 화면 |
| GUI 한글 표시 | 확인 | Interface 화면 |
| FortiGate 교재 23단계 전체 완료 | 사용자 완료 진술 | 단계별 CLI/화면은 일부만 제공 |
| 개별 방화벽 정책·보안 프로파일 전체 내용 | 상세 미확인 | 정책 설정 화면/전체 백업 미제공 |

### 7.2 인터페이스 구성

```text
VMware NAT network (192.168.2.0/24)
                 |
        port1: 192.168.2.100/24
             FortiGate
        port2: 192.168.20.100/24
                 |
Host-Only network (192.168.20.0/24)
```

화면상 port1·port2에 **PING, HTTPS, SSH, HTTP** 관리 접근이 표시되었다.

- **교육 실습:** GUI 접속 및 기능 확인에 유용하다.
- **운영 보안:** 평문 HTTP 관리 비활성화, 관리망/신뢰 호스트 제한, 최소 권한, MFA 및 변경 이력 관리가 권장된다.
- `fortilink`는 FortiSwitch 연동용 인터페이스이며, `NAT interface (naf.root)`는 `MyNAT` 방화벽 정책 그 자체가 아니다.
- 방화벽을 통한 트래픽 통제는 **실제 패킷 경로가 FortiGate를 지나야** 적용된다. 같은 L2 네트워크의 Kali↔CentOS 직접 통신은 FortiGate를 우회할 수 있다.

### 7.3 NAT 및 방화벽 정책 개념

- **방화벽 정책:** 출발지·목적지·서비스·인터페이스·동작을 정의한다.
- **SNAT:** 내부 사설 IP가 외부로 나갈 때 출발지 주소를 변환한다.
- **DNAT/VIP:** 외부 목적지 주소를 내부 서버 주소로 변환하는 데 활용한다.
- **IPS:** 규칙/시그니처/이상징후에 따라 침입 시도를 탐지하거나 차단한다.
- **DoS Policy:** 세션·패킷 임계치 등으로 과도한 트래픽을 제어한다.

> 실습 화면의 NAT 운영 모드만으로 특정 정책의 활성화, 통과 트래픽, 실제 차단 효과를 모두 증명할 수는 없다.

---

## 8. FortiGate `default.pdf` 정밀 분석

### 8.1 문서 정보와 날짜 해석

- 문서명: **FortiGate Daily Security Report**
- 보고서 생성일: **2026-11-02**
- **Data Range: Nov 01, 2026**
- PDF: 표지·목차 포함 **13쪽**, 보고서 본문 **10쪽**

**중요:** 11월 2일의 Netcat/Nessus/FortiGate 실습 결과가 이 PDF에 모두 기록되었다고 연결하면 안 된다. 아래 수치는 **11월 1일 집계**다.

### 8.2 트래픽 통계 (PDF 물리 5쪽 / 본문 2쪽)

| 지표 | 값 |
|---|---:|
| Total Sessions | 24 |
| Total Bytes In | 0 B |
| Total Bytes Out | 0 B |
| Total Users | 1 |
| Total Applications | 2 |
| Total Destinations | 4 |
| HTTP 세션 | 16 |
| HTTPS 세션 | 8 |
| Most Active Hour | 2026-11-01 23:00 |

**해석:** 세션은 집계되지만 바이트가 `0 B`로 나타나므로, 실제 트래픽이 전혀 없었다고 단정할 수 없다. 로깅 범위·보고서 집계 방식·라이선스·보관 기간을 점검해야 한다.

### 8.3 침입 탐지 및 차단 (PDF 물리 10~11쪽 / 본문 7~8쪽)

| 탐지 이름 | 탐지 건수 | 차단 보고 건수 | 일반적 의미 |
|---|---:|---:|---|
| `tcp_syn_flood` | 2 | 2 | TCP SYN 플러딩 관련 이벤트 |
| `udp_flood` | 1 | 1 | UDP 플러딩 관련 이벤트 |
| `ip_src_session` | 1 | 1 | 출발지 IP의 세션 관련 임계치 이벤트 |
| **합계** | **4** | **4** | 보고서상 탐지/차단 집계 |

- **Intrusion Source:** `192.168.2.50` (4건)
- **Intrusion Victim:** `192.168.20.200` (4건)
- **Severity:** Critical 4건, **100%**

**정확한 해석:** 이 수치는 **보안 이벤트 4건**이지 공격 패킷 4개나 모든 공격 트래픽 100% 차단을 뜻하지 않는다. 또한 탐지 이벤트와 차단 이벤트가 동일하게 집계되었다는 사실만으로 서버의 서비스 가용성이 유지되었는지까지 확정할 수 없다.

### 8.4 다른 항목에 데이터가 적은 이유

PDF의 웹 사용, 이메일, 악성코드, 봇넷, VPN 항목에는 대부분 `No matching log data for this report`가 표시되었다.

가능한 이유(확정 아님):

1. **집계 날짜가 11월 1일**이어서 오늘 실습과 시점이 다름.
2. 해당 종류의 트래픽/이벤트가 집계 기간에 없었음.
3. 기능 라이선스, 프로파일 적용, 로깅 설정, 수집 범위 등으로 데이터가 남지 않았음.

`No matching log data`를 **악성코드가 없었다는 증거**나 **보안 기능이 실패했다는 증거**로 단정하지 않는다.

### 8.5 관리자 로그인 및 시스템 이벤트 (PDF 물리 13쪽 / 본문 10쪽)

| 항목 | 기록 |
|---|---|
| admin 콘솔 로그인 | 2회, 구성 변경 0회, 10분 02초 |
| admin HTTPS 로그인 | 2회, 구성 변경 2회, 1시간 04분 52초 |
| 실패 로그인 | 일치 로그 없음 |
| Configuration changed | 2건 |
| FortiGate update failed | 1건 |
| License status changed | 1건 |

**추가 점검:** 업데이트 실패 사유와 라이선스 상태를 확인하고, 변경 이벤트 시각과 작업 내용을 교차 검증한다.

---

## 9. 공격·탐지·방어를 연결한 실무 관점

| 단계 | 오늘의 실습 | 방어 관점에서 남겨야 할 증거 |
|---|---|---|
| 자산 식별 | Nmap 서비스 스캔 | 포트/서비스/버전 목록 |
| 비정상 원격 접근 | Netcat Bind/Reverse Shell | TCP 4-tuple, 프로세스, 연결 방향, 타임라인 |
| 권한 상승 | SUID·SGID, `usermod`, 실습 바이너리 | 파일 소유권/권한, 계정 변경, 실행 흔적 |
| 이상 탐지 | SUID 기준선 `diff` | 정상 목록, 변경 목록, 해시, 검토 결과 |
| 취약점 평가 | Nessus Essentials | 스캔 정책, 대상, CVE·플러그인별 결과 |
| 네트워크 제어 | FortiGate NGFW | 인터페이스/라우팅/정책/세션 로그 |
| 침입 방어 기록 | FortiGate IPS/DoS 이벤트 | 출발지·목적지·시그니처·심각도·차단 기록 |

### 권장 보고서 증거 수집 포인트

- **Nmap:** 명령과 실행 시각, 포트/버전 출력
- **Netcat/Wireshark:** 리스닝/ESTABLISHED, TCP Stream, 쉘 프로세스 확인
- **SUID:** `stat`, `find`, 전후 `diff`, 정상 권한 복구
- **Nessus:** 스캔 완료 화면, Critical/High 건수, Plugin ID/CVE, Solution
- **FortiGate:** 인터페이스, 라우팅, 방화벽 정책, IPS/DoS 정책, Traffic/Attack 로그, 테스트 전후 비교

---

## 10. 실습 종료 후 보안 점검 체크리스트

- [ ] `/tmp/backdoor` 경로에 실습 바이너리가 없는지 재확인
- [ ] `/usr/sbin/usermod`의 **실습 중 추가한 SUID 비트**가 원복되었는지 확인
- [ ] Netcat 4444 리스너/연결이 남아 있지 않은지 점검
- [ ] `user01` 로그인 쉘과 계정 설정이 실습 전 의도한 상태인지 확인
- [ ] SUID 기준선과 현재 목록을 정렬하여 재비교
- [ ] Nessus 스캔 결과를 별도로 보관하고 오탐 여부 검증
- [ ] FortiGate 정책과 로그 수집이 의도한 트래픽 경로에 적용되는지 확인
- [ ] FortiGate 업데이트 실패·라이선스 경고 확인
- [ ] 실습용 광범위 허용 정책, HTTP 관리, 약한 계정 설정은 운영망에 반입하지 않기

---

## 11. 핵심 면접 Q&A 15선

**Q1. SYN Scan과 Connect Scan의 차이는?**  
A. SYN Scan은 TCP 3-way handshake를 완전히 마치지 않고 SYN 응답을 바탕으로 포트 상태를 추정한다. Connect Scan은 운영체제의 TCP 연결을 실제로 완료하는 방식이다.

**Q2. `-sV` 옵션의 목적은?**  
A. 열린 포트에 대해 서비스 종류와 버전 정보를 추정한다.

**Q3. Bind Shell과 Reverse Shell의 차이는?**  
A. Bind는 대상이 포트를 열어 외부 연결을 기다리고, Reverse는 대상이 외부 수신 대기 장비로 먼저 접속한다.

**Q4. 포트 4444가 열려 있으면 무조건 백도어인가?**  
A. 아니다. 포트 번호만으로 단정할 수 없으며 서비스 응답, 프로세스, 권한, 운영 목적 등을 확인해야 한다. 이번에는 Nmap 식별과 실제 쉘 동작이 함께 확인되었다.

**Q5. SUID란?**  
A. 실행 파일에 설정되는 특수 권한으로, 실행 시 유효 사용자 ID가 파일 소유자 ID로 설정될 수 있다.

**Q6. `s`와 `S`의 차이는?**  
A. `s`는 해당 실행 비트와 특수 권한 비트가 모두 켜진 상태, `S`는 특수 권한 비트만 있고 해당 실행 비트는 없는 상태다.

**Q7. 일반 사용자에게 SUID root 프로그램이 위험한 이유는?**  
A. 프로그램의 설계나 구현에 문제가 있으면 일반 사용자에게 의도하지 않은 root 권한 작업을 허용할 수 있기 때문이다.

**Q8. SUID 파일을 어떻게 탐지하나?**  
A. `find / -type f -perm -4000 2>/dev/null`로 검색하고 승인된 기준선 및 소유권·해시·권한 정보와 비교한다.

**Q9. `diff` 결과에 새 파일이 나오면 악성 파일인가?**  
A. 아니다. 신규 파일이라는 변경 사실을 나타내며 설치/패치/관리 작업 여부를 추가 조사해야 한다.

**Q10. `/etc/passwd`와 `/etc/shadow`의 차이는?**  
A. 전자는 계정 기본 정보, 후자는 비밀번호 해시 등 민감한 인증 정보를 담는다.

**Q11. Nmap과 Nessus의 차이는?**  
A. Nmap은 자산·포트·서비스 탐색에 강하고, Nessus는 플러그인 기반 취약점 진단과 위험도/조치 정보 제공에 강하다.

**Q12. CVE와 CVSS는 무엇인가?**  
A. CVE는 공개 취약점 식별자이고, CVSS는 취약점의 심각도를 수치화하는 점수 체계다.

**Q13. 방화벽 정책과 NAT는 같은 기능인가?**  
A. 아니다. 정책은 트래픽 허용/차단을 결정하고, NAT는 IP 주소/포트 변환을 수행한다. 둘은 함께 사용될 수 있다.

**Q14. IDS와 IPS의 차이는?**  
A. IDS는 탐지·경고가 중심이고, IPS는 트래픽 경로에서 탐지와 함께 차단 조치를 수행할 수 있다.

**Q15. IPS 보고서의 '차단 4건'은 공격 패킷을 전부 차단했다는 의미인가?**  
A. 아니다. 이벤트 집계 4건이며, 실제 패킷 수·서비스 영향·우회 가능성은 트래픽 캡처 및 대상 서버 상태로 추가 검증해야 한다.

---

## 12. 오늘의 최종 결론

이번 실습의 가치는 **공격을 시연하는 것 자체보다, 발생한 현상을 네트워크·프로세스·파일 권한·취약점·방화벽 로그라는 서로 다른 증거로 연결해 설명할 수 있게 된 것**이다.

- **확인된 결과:** Nmap 4444/tcp 백도어 탐지, Netcat 원격 root 쉘, SUID 권한 상승, SUID 목록 차이 탐지 및 파일 삭제, Nessus 작업 목록, FortiGate GUI/인터페이스, 11월 1일 IPS 이벤트 4건.
- **사용자 완료 진술:** FortiGate 교재 23단계 전체 수행.
- **추가 자료가 필요한 결과:** Nessus 취약점별 CVE/위험도, FortiGate 10~23단계 개별 설정과 각 테스트 결과, 11월 2일 당일 IPS 이벤트의 상세 로그.

> **면접용 한 문장:** “Nmap과 Nessus로 자산 및 취약점을 조사하고, Linux SUID 권한 상승과 비정상 원격 쉘을 실습·분석했으며, SUID 기준선 비교와 FortiGate 침입 탐지·차단 보고서를 통해 탐지 및 대응 관점까지 연결해 학습했습니다.”

---

*학습 목적의 승인된 가상 실습 환경을 전제로 작성. 실제 운영 환경에서는 변경 승인·증거 보존·최소 권한·보안 정책을 우선 적용한다.*
