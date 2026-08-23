# 🐧 Linux Weekly Interview Q&A
> **범위:** Package Management · Storage · LVM · RAID · Backup · Scheduling · NetworkManager · SSH/SCP/SFTP/FTP · systemd  
> **목적:** 복습용 문답 + 기술 면접 대비  
> **추천 사용법:** 질문만 보고 먼저 답한 뒤, 아래 모범 답안과 비교하기

---

# 1. Package Management

## Q1. RPM이란 무엇인가요?

### 짧은 답변
RPM은 Red Hat 계열 Linux에서 사용하는 패키지 관리 시스템입니다.

### 면접형 답변
RPM은 `.rpm` 형식의 패키지를 설치, 삭제, 조회하는 저수준 패키지 관리 도구입니다.  
패키지 자체를 직접 관리할 수 있지만, 의존성을 자동으로 해결해 주지는 않는다는 특징이 있습니다.

### 핵심 명령어

```bash
rpm -ivh package.rpm
rpm -Uvh package.rpm
rpm -e package
rpm -qa
rpm -qi package
rpm -ql package
```

---

## Q2. RPM과 YUM의 차이는 무엇인가요?

### 짧은 답변
RPM은 개별 패키지를 직접 관리하고, YUM은 Repository를 이용해 의존성까지 자동 처리합니다.

### 면접형 답변
RPM은 로컬에 있는 `.rpm` 패키지를 직접 설치하거나 삭제할 때 사용합니다.  
반면 YUM은 Repository를 조회하여 필요한 패키지와 의존 패키지를 함께 설치할 수 있습니다.

```text
RPM
→ 개별 패키지 직접 관리
→ 의존성 직접 해결

YUM / DNF
→ Repository 기반
→ 의존성 자동 해결
```

### 꼬리 질문
**Q. 실무에서는 어떤 것을 더 자주 사용하나요?**

일반적인 패키지 설치와 업데이트에서는 `yum` 또는 `dnf`를 더 자주 사용합니다.  
다만 특정 RPM 파일을 직접 설치하거나 패키지 정보를 세밀하게 조회할 때는 `rpm`도 사용합니다.

---

## Q3. YUM과 DNF의 관계는 무엇인가요?

DNF는 YUM의 후속 패키지 관리 도구입니다.

최근 RHEL 계열 배포판에서는 DNF가 기본 패키지 관리자로 사용됩니다.

```bash
dnf install nginx
dnf remove nginx
```

---

## Q4. Debian 계열에서는 어떤 패키지 관리 명령어를 사용하나요?

```text
Red Hat 계열
rpm
yum / dnf

Debian 계열
dpkg
apt
```

예:

```bash
apt install curl
dpkg -l curl
dpkg -L curl
```

---

## Q5. wget, curl, git의 차이는 무엇인가요?

```text
wget
→ 파일 다운로드

curl
→ URL 요청 / API 테스트 / 파일 다운로드

git
→ Git Repository 복제 및 버전 관리
```

### 면접형 답변
`wget`은 파일 다운로드에 적합하고, `curl`은 HTTP 요청이나 API 테스트 등 네트워크 요청을 다양하게 처리할 수 있습니다.  
`git`은 단순 파일 다운로드가 아니라 Git Repository 전체를 복제하고 버전 관리를 할 때 사용합니다.

---

# 2. Storage

## Q6. Linux에서 새 디스크를 사용하기 위한 일반적인 순서는 무엇인가요?

```text
Disk
 ↓
Partition
 ↓
Filesystem
 ↓
Mount
 ↓
사용
```

### 예

```bash
fdisk /dev/sdb
mkfs -t ext4 /dev/sdb1
mkdir /data
mount /dev/sdb1 /data
df -h
```

### 면접형 답변
새 디스크를 추가하면 먼저 파티션을 생성하고, 그 위에 파일시스템을 생성한 뒤, 디렉터리에 마운트하여 사용합니다.

---

## Q7. `fdisk`는 무엇을 하는 명령어인가요?

디스크의 파티션을 생성, 삭제, 조회하기 위한 명령어입니다.

```bash
fdisk -l
fdisk /dev/sdb
```

---

## Q8. `mkfs`는 무엇인가요?

파티션이나 논리 볼륨 등에 파일시스템을 생성하는 명령어입니다.

```bash
mkfs -t ext4 /dev/sdb1
```

또는:

```bash
mkfs.ext4 /dev/sdb1
```

---

## Q9. mount란 무엇인가요?

Linux의 파일시스템 구조에 저장장치를 연결하는 작업입니다.

```bash
mount /dev/sdb1 /data
```

즉 `/dev/sdb1`의 내용을 `/data` 디렉터리를 통해 접근할 수 있게 됩니다.

---

## Q10. `df -h`와 `du -sh`의 차이는 무엇인가요?

```text
df
→ 파일시스템 전체 사용량 확인

du
→ 특정 디렉터리 또는 파일이 사용하는 용량 확인
```

예:

```bash
df -h
du -sh /var/log
```

---

# 3. /etc/fstab

## Q11. `/etc/fstab`은 왜 사용하나요?

재부팅 후에도 특정 파일시스템이 자동으로 마운트되도록 설정하기 위해 사용합니다.

예:

```text
/dev/sdb1 /data ext4 defaults 0 0
```

---

## Q12. `/etc/fstab`을 수정한 뒤 바로 재부팅하면 위험한 이유는 무엇인가요?

설정에 오타가 있으면 부팅 과정에서 파일시스템 마운트에 실패할 수 있기 때문입니다.

따라서 수정 후 먼저 다음 명령으로 검증하는 것이 좋습니다.

```bash
mount -a
```

---

## Q13. `/etc/fstab`의 각 필드는 무엇을 의미하나요?

```text
장치  마운트포인트  파일시스템  옵션  dump  fsck
```

예:

```text
/dev/sdb1 /data ext4 defaults 0 0
```

---

# 4. LVM

## Q14. LVM이란 무엇인가요?

LVM은 Logical Volume Manager의 약자로, 물리적인 디스크 공간을 논리적으로 유연하게 관리하기 위한 기술입니다.

---

## Q15. LVM의 구성 순서를 말해보세요.

```text
PV
 ↓
VG
 ↓
LV
 ↓
Filesystem
 ↓
Mount
```

### 의미

```text
PV = Physical Volume
VG = Volume Group
LV = Logical Volume
```

---

## Q16. PV, VG, LV의 차이를 설명해보세요.

### PV
실제 디스크나 파티션을 LVM에서 사용할 수 있도록 준비한 것입니다.

### VG
하나 이상의 PV를 묶어 만든 저장 공간 Pool입니다.

### LV
VG에서 실제 사용할 크기만큼 잘라 만든 논리 볼륨입니다.

---

## Q17. LVM을 사용하는 이유는 무엇인가요?

일반 파티션보다 저장 공간을 유연하게 확장하거나 관리하기 쉽기 때문입니다.

### 면접형 답변
LVM을 사용하면 여러 디스크를 하나의 저장 공간처럼 묶을 수 있고, 논리 볼륨 단위로 필요한 용량을 할당하거나 확장하기 편리합니다.

---

## Q18. LVM 생성 과정의 대표 명령어를 말해보세요.

```bash
pvcreate /dev/sdb1

vgcreate vg01 /dev/sdb1

lvcreate -L 1G -n lv01 vg01

mkfs -t ext4 /dev/vg01/lv01

mount /dev/vg01/lv01 /data
```

---

# 5. RAID

## Q19. RAID란 무엇인가요?

여러 개의 디스크를 조합하여 성능, 용량, 장애 대응 능력 등을 향상시키는 기술입니다.

---

## Q20. RAID 0의 특징은 무엇인가요?

RAID 0은 Striping 방식입니다.

```text
장점
→ 빠른 성능
→ 디스크 용량을 모두 사용 가능

단점
→ 장애 복구 기능 없음
→ 디스크 하나만 고장 나도 전체 데이터 손실 가능
```

---

## Q21. RAID 1의 특징은 무엇인가요?

RAID 1은 Mirroring 방식입니다.

동일한 데이터를 두 개 이상의 디스크에 복제합니다.

```text
장점
→ 장애 대응 가능

단점
→ 사용 가능한 용량 감소
```

---

## Q22. RAID 5의 특징은 무엇인가요?

RAID 5는 데이터와 Parity를 여러 디스크에 분산 저장합니다.

```text
최소 디스크 수
3개

허용 장애
1개

사용 가능 용량
(N - 1) × 디스크 용량
```

---

## Q23. RAID 6의 특징은 무엇인가요?

RAID 6는 이중 Parity를 사용합니다.

```text
최소 디스크 수
4개

허용 장애
2개

사용 가능 용량
(N - 2) × 디스크 용량
```

---

## Q24. RAID 5와 RAID 6의 차이는 무엇인가요?

RAID 5는 디스크 1개 장애까지 허용하고, RAID 6는 디스크 2개 장애까지 허용합니다.

RAID 6가 안정성은 더 높지만 Parity 계산과 쓰기 작업 부담이 더 큽니다.

---

## Q25. RAID 0+1과 RAID 1+0의 차이를 설명해보세요.

### RAID 0+1

```text
Stripe
 ↓
Mirror
```

Striping 그룹 전체를 Mirroring합니다.

### RAID 1+0

```text
Mirror
 ↓
Stripe
```

Mirroring된 디스크 그룹을 Striping합니다.

일반적으로 RAID 10이 장애 상황에서 더 유연합니다.

---

## Q26. RAID는 백업을 대체할 수 있나요?

아니요.

### 면접형 답변
RAID는 디스크 장애에 대한 가용성을 높이는 기술이지 백업 기술은 아닙니다.  
파일 삭제, 악성코드 감염, 데이터 손상 등이 발생하면 RAID에서도 그대로 반영될 수 있기 때문에 별도의 백업이 필요합니다.

> **RAID ≠ Backup**

---

## Q27. Linux Software RAID 관리 명령어는 무엇인가요?

`mdadm`입니다.

예:

```bash
mdadm --create /dev/md0 \
--level=1 \
--raid-devices=2 \
/dev/sdb1 /dev/sdc1
```

---

## Q28. RAID 상태는 어떻게 확인하나요?

```bash
cat /proc/mdstat
mdadm --detail /dev/md0
```

---

## Q29. `mdadm --zero-superblock`은 왜 조심해야 하나요?

디스크에 저장된 RAID Metadata를 제거하기 때문입니다.

잘못된 장치를 지정하면 기존 RAID 구성을 손상시킬 수 있으므로 반드시 대상 디스크를 확인해야 합니다.

---

# 6. Backup

## Q30. Full Backup이란 무엇인가요?

대상 데이터를 모두 백업하는 방식입니다.

### 장점
복구가 가장 단순합니다.

### 단점
백업 시간과 저장 공간을 많이 사용합니다.

---

## Q31. Incremental Backup이란 무엇인가요?

직전 백업 이후 변경된 데이터만 저장하는 방식입니다.

예:

```text
월 Full
화 Incremental
수 Incremental
목 Incremental
```

복구할 때는:

```text
Full
+ 화
+ 수
+ 목
```

이 모두 필요합니다.

---

## Q32. Differential Backup이란 무엇인가요?

마지막 Full Backup 이후 변경된 모든 데이터를 저장하는 방식입니다.

복구할 때는:

```text
Full
+
가장 최근 Differential
```

이면 됩니다.

---

## Q33. Incremental과 Differential Backup의 차이는 무엇인가요?

```text
Incremental
→ 직전 백업 이후 변경분

Differential
→ 마지막 Full Backup 이후 변경분
```

### 면접 포인트

Incremental:
- 백업 속도 빠름
- 저장 공간 적게 사용
- 복구 복잡

Differential:
- 백업량 점점 증가
- 복구 비교적 단순

---

## Q34. Linux에서 tar를 이용한 증분 백업은 어떻게 할 수 있나요?

GNU tar의 snapshot 기능을 사용할 수 있습니다.

```bash
tar -g snapshot.file -cvf backup.tar /data
```

`-g` 옵션을 사용하면 이전 백업 상태를 기준으로 변경된 파일을 추적할 수 있습니다.

---

# 7. Scheduling

## Q35. at과 cron의 차이는 무엇인가요?

```text
at
→ 일회성 작업 예약

cron
→ 반복 작업 예약
```

---

## Q36. at 관련 데몬은 무엇인가요?

```text
atd
```

상태 확인:

```bash
systemctl status atd
```

---

## Q37. cron 관련 데몬은 무엇인가요?

```text
crond
```

상태 확인:

```bash
systemctl status crond
```

---

## Q38. crontab 형식을 설명해보세요.

```text
분 시 일 월 요일 명령어
```

예:

```bash
0 3 * * * /backup.sh
```

매일 새벽 3시에 `/backup.sh`를 실행한다는 의미입니다.

---

## Q39. cron 작업이 실행되지 않는다면 무엇을 확인해야 하나요?

예시 점검 순서:

```text
1. crond 실행 여부
2. crontab 내용
3. 명령어 경로
4. 실행 권한
5. 환경 변수
6. 로그
```

cron 환경에서는 일반 Shell과 PATH가 다를 수 있으므로 명령어의 절대 경로를 사용하는 것이 안전합니다.

---

# 8. NetworkManager

## Q40. NetworkManager란 무엇인가요?

Linux에서 네트워크 인터페이스와 연결 설정을 관리하는 서비스입니다.

```bash
systemctl status NetworkManager
```

---

## Q41. nmcli란 무엇인가요?

NetworkManager를 CLI 환경에서 제어하는 명령어입니다.

```bash
nmcli connection show
```

---

## Q42. nmtui와 nmcli의 차이는 무엇인가요?

```text
nmcli
→ Command Line Interface

nmtui
→ Text User Interface
```

`nmtui`는 메뉴 기반이라 설정이 익숙하지 않을 때 편리합니다.

---

## Q43. IP 주소를 nmcli로 변경하는 기본 방식은 무엇인가요?

예:

```bash
nmcli connection modify ens33 ipv4.addresses 192.168.2.100/24
nmcli connection up ens33
```

필요에 따라 다음도 함께 설정합니다.

```bash
nmcli connection modify ens33 ipv4.method manual
nmcli connection modify ens33 ipv4.gateway 192.168.2.1
nmcli connection modify ens33 ipv4.dns 8.8.8.8
```

---

## Q44. `/etc/hosts`는 무엇인가요?

로컬 시스템에서 IP 주소와 호스트 이름을 직접 매핑하는 파일입니다.

```text
192.168.2.100 server1
```

DNS를 사용하지 않아도 `server1`이라는 이름으로 해당 IP를 찾을 수 있습니다.

---

## Q45. `/etc/resolv.conf`는 무엇인가요?

DNS Resolver 설정을 확인하는 파일입니다.

일반적으로 DNS 서버 정보가 저장됩니다.

다만 NetworkManager 환경에서는 자동으로 관리될 수 있습니다.

---

# 9. SSH / Telnet

## Q46. Telnet과 SSH의 가장 큰 차이는 무엇인가요?

```text
Telnet
→ 평문 통신
→ TCP 23

SSH
→ 암호화 통신
→ TCP 22
```

실무 원격 접속에서는 보안상 SSH를 사용합니다.

---

## Q47. SSH란 무엇인가요?

원격 시스템에 암호화된 방식으로 접속하기 위한 프로토콜입니다.

```bash
ssh user@192.168.2.100
```

---

## Q48. SSH 접속이 안 될 때 무엇을 확인해야 하나요?

추천 순서:

```text
1. IP 연결 여부
2. SSH 서비스 상태
3. TCP 22 Listen 여부
4. Firewall
5. 계정 / 비밀번호
6. SSH 설정 파일
```

명령어 예:

```bash
ping 서버IP
systemctl status sshd
ss -lntp | grep ':22'
```

---

# 10. SCP / SFTP / FTP

## Q49. SCP란 무엇인가요?

SSH를 기반으로 파일을 복사하는 명령어입니다.

```bash
scp file.txt user@server:/tmp/
```

---

## Q50. SFTP란 무엇인가요?

SSH 기반의 파일 전송 프로토콜입니다.

FTP와 비슷한 대화형 명령을 사용할 수 있지만 SSH를 기반으로 암호화됩니다.

```bash
sftp user@server
```

---

## Q51. SCP와 SFTP의 차이는 무엇인가요?

```text
SCP
→ 파일 복사 중심
→ 간단하고 빠른 사용

SFTP
→ 대화형 파일 관리
→ ls, cd, get, put 등 사용
```

둘 다 일반적으로 SSH의 TCP 22를 사용합니다.

---

## Q52. FTP와 SFTP는 같은 프로토콜인가요?

아닙니다.

```text
FTP
→ File Transfer Protocol
→ 기본 Control Port TCP 21

SFTP
→ SSH File Transfer Protocol
→ SSH 기반 TCP 22
```

이름은 비슷하지만 구조적으로 완전히 다른 프로토콜입니다.

---

## Q53. FTP의 단점은 무엇인가요?

기본 FTP는 계정 정보와 데이터를 암호화하지 않고 전송할 수 있기 때문에 보안에 취약합니다.

따라서 실제 환경에서는 SFTP, SCP, FTPS 등의 안전한 방식이 선호됩니다.

---

## Q54. FTP의 대표적인 응답 코드를 말해보세요.

```text
220 → Service Ready
230 → Login Successful
331 → Password Required
530 → Login Incorrect
```

큰 범주:

```text
1xx → 처리 진행
2xx → 성공
3xx → 추가 입력 필요
4xx → 일시적 실패
5xx → 실패
```

---

# 11. vsftpd

## Q55. vsftpd란 무엇인가요?

Very Secure FTP Daemon의 약자로, Linux에서 FTP 서버를 구축할 때 사용할 수 있는 FTP 서버 프로그램입니다.

---

## Q56. vsftpd 서비스를 시작하고 확인하는 명령어는 무엇인가요?

```bash
systemctl start vsftpd
systemctl status vsftpd
```

자동 시작:

```bash
systemctl enable vsftpd
```

한 번에:

```bash
systemctl enable --now vsftpd
```

---

## Q57. FTP 서버가 접속되지 않을 때 어떻게 점검하나요?

추천 순서:

```text
1. IP 통신
2. vsftpd 상태
3. TCP 21 Listen
4. 설정 파일
5. Firewall / SELinux
6. 계정 및 권한
7. 로그 확인
```

명령어 예:

```bash
ping 서버IP
systemctl status vsftpd
ss -lntp | grep ':21'
journalctl -u vsftpd
```

---

## Q58. Anonymous FTP란 무엇인가요?

계정이 없는 사용자가 anonymous 계정으로 FTP 서버에 접속할 수 있게 하는 방식입니다.

예:

```text
anonymous_enable=YES
```

실제 운영 환경에서는 보안상 허용 범위를 매우 제한해야 합니다.

---

# 12. systemd

## Q59. systemd란 무엇인가요?

Linux 시스템의 서비스, 프로세스, 부팅 과정 및 다양한 시스템 자원을 관리하는 init 시스템입니다.

---

## Q60. systemctl은 무엇인가요?

systemd의 Unit을 제어하기 위한 명령어입니다.

예:

```bash
systemctl start nginx
systemctl stop nginx
systemctl restart nginx
systemctl status nginx
systemctl enable nginx
```

---

## Q61. CentOS 6과 CentOS 7의 서비스 관리 방식 차이는 무엇인가요?

```text
CentOS 6
→ SysV init
→ service

CentOS 7+
→ systemd
→ systemctl
```

예:

```bash
service vsftpd start
```

vs

```bash
systemctl start vsftpd
```

---

## Q62. systemd의 Unit에는 어떤 종류가 있나요?

대표적으로:

```text
.service
.socket
.target
.timer
.mount
.path
```

등이 있습니다.

---

## Q63. service Unit과 socket Unit의 차이는 무엇인가요?

### service
실제 서비스 프로세스를 정의합니다.

### socket
특정 Socket을 감시하고 연결 요청이 발생하면 관련 서비스를 활성화할 수 있습니다.

```text
Client
 ↓
Socket
 ↓
systemd
 ↓
Service
```

---

## Q64. Standalone 방식과 xinetd 방식의 차이는 무엇인가요?

### Standalone

```text
서비스가 항상 실행
↓
직접 Port Listen
↓
요청 처리
```

### xinetd

```text
xinetd가 Port 감시
↓
요청 발생
↓
필요한 서비스 실행
```

xinetd는 전통적인 Super Server 방식이며, 현대 Linux에서는 많은 기능이 systemd의 socket activation 등으로 대체되었습니다.

---

# 13. Linux Troubleshooting

## Q65. Linux 서비스 장애가 발생하면 어떤 순서로 점검하나요?

추천 답변:

```text
1. 서비스 상태
2. 로그
3. 설정 파일
4. Port Listen
5. Process
6. Firewall / SELinux
7. 수정 후 재시작
```

예:

```bash
systemctl status vsftpd

journalctl -u vsftpd

ss -lntp | grep ':21'

ps -ef | grep vsftpd
```

---

## Q66. `systemctl status`와 `journalctl`의 차이는 무엇인가요?

`systemctl status`는 서비스의 현재 상태와 최근 로그 일부를 빠르게 확인할 때 사용합니다.

`journalctl`은 systemd Journal에 저장된 더 상세한 로그를 조회할 때 사용합니다.

예:

```bash
journalctl -u sshd
```

---

## Q67. `ss -lntp`는 무엇을 확인하는 명령어인가요?

현재 Listening 중인 TCP Port와 관련 프로세스를 확인합니다.

```text
-l = Listen
-n = 숫자로 표시
-t = TCP
-p = Process
```

예:

```bash
ss -lntp | grep ':22'
```

---

## Q68. 프로세스가 존재하는 것과 서비스가 정상 동작하는 것은 같은 의미인가요?

아닙니다.

프로세스가 실행 중이어도:

- 설정 오류
- Port Binding 실패
- Firewall
- 권한 문제
- 애플리케이션 내부 오류

등으로 정상 서비스가 불가능할 수 있습니다.

따라서 프로세스뿐 아니라 Port, Log, 서비스 상태까지 함께 확인해야 합니다.

---

# 14. 상황형 면접 문제

## Q69. 사용자가 "SSH 서버에 접속할 수 없다"고 합니다. 어떻게 점검하시겠습니까?

### 모범 답변

먼저 네트워크 연결 여부를 확인합니다.

```bash
ping 서버IP
```

그다음 SSH 서비스 상태를 확인합니다.

```bash
systemctl status sshd
```

TCP 22번 Port가 Listen 중인지 확인합니다.

```bash
ss -lntp | grep ':22'
```

이후 Firewall, sshd 설정, 사용자 계정 및 인증 정보를 점검하고 로그를 확인합니다.

```bash
journalctl -u sshd
```

### 면접 포인트

무작정 서비스 재시작부터 하지 않고,

```text
Network
→ Service
→ Port
→ Firewall
→ Account
→ Log
```

순서로 범위를 좁혀 간다고 설명하면 좋습니다.

---

## Q70. 서버 재부팅 후 `/data`가 사라졌다고 합니다. 어떤 원인을 의심할 수 있나요?

`/data` 디렉터리 자체가 사라진 것이 아니라, 저장장치가 자동 마운트되지 않았을 가능성을 먼저 확인합니다.

```bash
df -h
mount
cat /etc/fstab
```

`/etc/fstab`에 설정이 없거나 잘못되어 있다면 재부팅 후 자동 마운트가 되지 않을 수 있습니다.

---

## Q71. RAID 5에서 디스크 하나가 고장 났습니다. 서비스는 계속 가능한가요?

RAID 5는 디스크 1개의 장애를 허용하므로 일반적으로 Degraded 상태로 동작을 계속할 수 있습니다.

다만 추가 디스크 장애가 발생하면 데이터 손실 위험이 있으므로 가능한 빠르게 장애 디스크를 교체하고 Rebuild를 진행해야 합니다.

---

## Q72. RAID 6에서 디스크 두 개가 동시에 고장 나면 어떻게 되나요?

RAID 6는 이중 Parity를 사용하므로 최대 2개의 디스크 장애까지 견딜 수 있습니다.

하지만 이 상태에서도 추가 장애가 발생하면 데이터 손실 위험이 매우 높으므로 빠른 복구가 필요합니다.

---

## Q73. cron으로 등록한 스크립트가 터미널에서는 실행되지만 cron에서는 실패합니다. 무엇을 의심해야 하나요?

대표적으로 환경 변수와 PATH 차이를 확인합니다.

cron은 로그인 Shell과 다른 최소한의 환경에서 실행될 수 있기 때문입니다.

예:

```bash
/usr/bin/python3 /home/user/script.py
```

처럼 명령어의 절대 경로를 사용하는 것이 안전합니다.

또한:

- 실행 권한
- Shell 지정
- 파일 경로
- 환경 변수
- 로그

를 확인합니다.

---

## Q74. FTP 서버 프로세스는 있는데 접속이 되지 않습니다. 무엇을 확인해야 하나요?

프로세스 존재만으로 서비스가 정상이라고 판단할 수 없습니다.

확인 순서:

```text
1. vsftpd status
2. TCP 21 Listen
3. 설정 파일
4. Firewall
5. SELinux
6. 사용자 계정
7. 디렉터리 권한
8. 로그
```

---

# 15. 꼬리 질문 대비

## Q75. 왜 Telnet보다 SSH를 사용해야 하나요?

Telnet은 인증 정보와 데이터가 평문으로 전달될 수 있습니다.

SSH는 통신 내용을 암호화하므로 원격 관리에 더 안전합니다.

---

## Q76. SSH가 22번 Port를 사용한다고 해서 무조건 안전한가요?

아닙니다.

SSH는 암호화된 프로토콜이지만:

- 약한 비밀번호
- root 직접 로그인
- 오래된 암호화 알고리즘
- 잘못된 접근 제어

등이 있으면 보안 위험이 존재합니다.

---

## Q77. RAID 1을 사용하면 백업은 필요 없나요?

필요합니다.

RAID 1은 디스크 장애에는 대응할 수 있지만, 사용자가 파일을 삭제하면 동일한 삭제 내용이 다른 디스크에도 반영됩니다.

---

## Q78. LVM과 RAID의 목적은 같은가요?

아닙니다.

```text
LVM
→ 저장 공간의 유연한 논리 관리

RAID
→ 여러 디스크를 이용한 성능 / 가용성 향상
```

두 기술을 함께 사용할 수도 있습니다.

---

## Q79. `mount -a`를 왜 중요하게 보나요?

`/etc/fstab`에 정의된 파일시스템을 실제로 마운트해 보면서 설정 오류를 확인할 수 있기 때문입니다.

운영 서버에서는 재부팅 전에 `mount -a`로 검증하는 습관이 중요합니다.

---

## Q80. Linux에서 문제 해결 시 가장 중요한 습관은 무엇이라고 생각하나요?

### 추천 면접 답변

문제가 발생했을 때 바로 설정을 변경하기보다는 현재 상태와 로그를 먼저 확인하고, 네트워크·프로세스·Port·설정 파일 등 범위를 단계적으로 좁혀가는 습관이 중요하다고 생각합니다.

---

# 16. 초압축 면접 암기표

| 질문 | 핵심 답변 |
|---|---|
| RPM vs YUM | RPM 직접 관리 / YUM 의존성 자동 |
| Debian 패키지 | apt / dpkg |
| Storage 순서 | Disk → Partition → FS → Mount |
| LVM | PV → VG → LV |
| RAID 0 | Striping / 장애 대응 없음 |
| RAID 1 | Mirroring |
| RAID 5 | 1 Disk 장애 허용 |
| RAID 6 | 2 Disk 장애 허용 |
| RAID 10 | Mirror 후 Stripe |
| Full Backup | 전체 |
| Incremental | 직전 백업 이후 |
| Differential | Full 이후 |
| at | 일회성 |
| cron | 반복 |
| SSH | TCP 22 / 암호화 |
| Telnet | TCP 23 / 평문 |
| FTP | TCP 21 |
| SCP | SSH 기반 복사 |
| SFTP | SSH 기반 파일 전송 |
| systemd | Linux 서비스/시스템 관리 |
| systemctl | systemd Unit 제어 |
| service vs socket | 실행 프로세스 / 요청 감시 |
| fstab | 부팅 시 자동 Mount |
| mount -a | fstab 설정 검증 |
| RAID ≠ Backup | 반드시 기억 |

---

# 17. 30초 자기 답변 연습

아래 질문은 **30초 이내**로 말하는 연습을 해보자.

### ① LVM이 무엇인가요?

> LVM은 Physical Volume, Volume Group, Logical Volume 구조를 이용해 저장 공간을 논리적으로 관리하는 기술입니다. 일반 파티션보다 용량 확장이나 여러 디스크의 통합 관리가 유연하다는 장점이 있습니다.

### ② RAID 5와 RAID 6의 차이는 무엇인가요?

> RAID 5는 Parity 하나를 사용해 디스크 하나의 장애를 허용하고, RAID 6는 이중 Parity를 사용해 두 개의 디스크 장애까지 허용합니다. RAID 6가 안정성은 더 높지만 쓰기 성능과 용량 효율에서는 비용이 더 큽니다.

### ③ SSH 접속 장애를 어떻게 해결하나요?

> 먼저 서버 IP까지 통신되는지 확인하고, sshd 서비스 상태와 TCP 22번 Port Listen 여부를 확인합니다. 이후 Firewall, 계정, SSH 설정 파일을 점검하고 journalctl을 이용해 로그를 확인하면서 원인을 좁혀 갑니다.

### ④ RPM과 YUM 차이는 무엇인가요?

> RPM은 개별 RPM 패키지를 직접 설치하거나 조회하는 도구이고 의존성을 자동 해결하지 않습니다. YUM이나 DNF는 Repository를 기반으로 필요한 의존 패키지까지 함께 설치할 수 있습니다.

### ⑤ RAID가 있으면 백업이 필요 없나요?

> 필요합니다. RAID는 디스크 장애에 대한 가용성을 높이는 기술이고, 파일 삭제나 데이터 손상까지 복구해주는 백업 기술은 아닙니다. 따라서 RAID와 별도의 백업 전략을 함께 사용해야 합니다.

---

# 18. 실전 랜덤 Q&A

아래는 답을 가리고 빠르게 연습하기 위한 질문 목록이다.

1. RPM과 YUM의 차이는?
2. YUM과 DNF의 관계는?
3. apt와 dpkg의 차이는?
4. Linux에서 새 디스크를 사용하는 순서는?
5. mount란?
6. `/etc/fstab`은 왜 사용하는가?
7. `mount -a`는 왜 중요한가?
8. PV, VG, LV의 차이는?
9. LVM의 장점은?
10. RAID 0의 특징은?
11. RAID 1의 특징은?
12. RAID 5의 최소 디스크 수는?
13. RAID 6는 몇 개 장애까지 허용하는가?
14. RAID 0+1과 RAID 1+0의 차이는?
15. RAID는 백업인가?
16. `mdadm`은 무엇인가?
17. `/proc/mdstat`은 무엇을 확인하는가?
18. Full Backup이란?
19. Incremental Backup이란?
20. Differential Backup이란?
21. Incremental과 Differential 차이는?
22. at과 cron 차이는?
23. crond란?
24. crontab 5개 시간 필드는?
25. NetworkManager란?
26. nmcli란?
27. nmtui란?
28. `/etc/hosts` 역할은?
29. `/etc/resolv.conf` 역할은?
30. Telnet과 SSH 차이는?
31. SSH 기본 Port는?
32. FTP 기본 Control Port는?
33. SCP란?
34. SFTP란?
35. FTP와 SFTP 차이는?
36. vsftpd란?
37. `systemctl enable`은 무엇을 의미하는가?
38. systemd란?
39. service Unit과 socket Unit의 차이는?
40. Standalone과 xinetd의 차이는?
41. `systemctl status`는 무엇을 확인하는가?
42. `journalctl`은 언제 사용하는가?
43. `ss -lntp`의 의미는?
44. SSH가 안 되면 어떤 순서로 확인할 것인가?
45. FTP가 안 되면 어떤 순서로 확인할 것인가?
46. cron은 되지 않는데 직접 실행하면 된다면 무엇을 확인할 것인가?
47. 재부팅 후 Mount가 사라지면 무엇을 확인할 것인가?
48. RAID 5 Degraded 상태란?
49. Process가 존재하면 서비스는 무조건 정상인가?
50. Linux 장애 해결 시 가장 중요한 습관은?

---

# 19. 최종 면접 체크포인트

면접에서는 단순히 명령어만 말하는 것보다 다음 구조로 답하면 좋다.

```text
① 무엇인지 정의

② 왜 사용하는지

③ 핵심 특징

④ 대표 명령어 또는 예시

⑤ 주의점 / Troubleshooting
```

예:

```text
Q. /etc/fstab이 무엇인가요?

1. 정의
→ 파일시스템 자동 마운트 설정 파일입니다.

2. 목적
→ 재부팅 후에도 저장장치가 자동 마운트되게 합니다.

3. 예
→ /dev/sdb1 /data ext4 defaults 0 0

4. 주의점
→ 오타가 있으면 부팅 문제가 발생할 수 있습니다.

5. 검증
→ mount -a로 먼저 확인합니다.
```

---

# 🐧 Final Boss

```text
면접관:
"RAID 5와 RAID 6의 차이를 설명해보세요."

나:
"RAID 5는 한 개, RAID 6는 두 개의 디스크 장애를 허용합니다."

면접관:
"RAID가 있으면 Backup은 필요 없겠네요?"

나:
"아닙니다. RAID는 가용성 기술이고 Backup을 대체할 수 없습니다."

면접관:
"...좋습니다."

             😎
             /|
            / |
           🐧 |
              |
          면접 생존
```

> **명령어를 외우는 것보다  
> "왜 사용하는지 + 장애가 났을 때 무엇을 확인하는지"까지 설명할 수 있으면 훨씬 강하다.**