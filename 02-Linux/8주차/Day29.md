# Linux Storage & RAID 정리 🐧💽💀

> VMware 가상 하드디스크 추가부터 파티션, 파일시스템, 마운트, LVM, RAID까지 한 번에 정리한 복습용 문서입니다.

---

# 1. 전체 흐름 한눈에 보기

리눅스에서 새로운 저장장치를 사용하기 위한 기본 흐름은 다음과 같습니다.

```text
VMware에서 HDD 추가
        ↓
Linux에서 디스크 인식
        ↓
lsblk / fdisk -l
        ↓
fdisk로 파티션 생성
        ↓
mkfs로 파일시스템 생성
        ↓
mount로 디렉터리에 연결
        ↓
df -h로 확인
        ↓
/etc/fstab에 등록
        ↓
부팅 시 자동 마운트
```

핵심 암기:

```text
fdisk → mkfs → mount → /etc/fstab
```

---

# 2. 디스크와 파티션

예를 들어 새 디스크가 `/dev/sdb`로 인식되었다고 가정합니다.

```text
/dev/sdb     ← 디스크 전체
/dev/sdb1    ← 1번 파티션
/dev/sdb2    ← 2번 파티션
```

즉,

```text
디스크
  ↓
파티션
  ↓
파일시스템
  ↓
마운트
```

의 순서로 생각하면 됩니다.

---

# 3. 디스크 확인 명령어

## lsblk

```bash
lsblk
```

블록 장치 구조를 트리 형태로 확인합니다.

쉽게 말하면:

> 현재 디스크와 파티션 구조를 보여줘.

---

## fdisk -l

```bash
fdisk -l
```

디스크와 파티션 정보를 자세히 확인합니다.

특정 디스크만 확인하려면:

```bash
fdisk -l /dev/sdb
```

---

# 4. fdisk 파티션 작업

예시:

```bash
fdisk /dev/sdr
```

`fdisk` 내부에서 자주 사용하는 명령어:

| 명령어 | 의미 | 암기 |
|---|---|---|
| `m` | 도움말 출력 | menu/help |
| `p` | 현재 파티션 테이블 출력 | print |
| `n` | 새 파티션 생성 | new |
| `d` | 파티션 삭제 | delete |
| `t` | 파티션 타입 변경 | type |
| `l` | 파티션 타입 목록 출력 | list |
| `w` | 변경사항 저장 후 종료 | write |
| `q` | 저장하지 않고 종료 | quit |

---

## 4-1. 새 파티션 생성 예시

```bash
fdisk /dev/sdr
```

예시 흐름:

```text
Command (m for help): n
Partition type:
   p   primary
   e   extended

Select: p
Partition number: 1
First sector: Enter
Last sector: +1G

Command (m for help): p
Command (m for help): w
```

결과 예:

```text
/dev/sdr1
```

핵심:

```text
w = 저장하고 종료
q = 저장하지 않고 종료
```

---

# 5. 파일시스템 생성

파티션을 만들었다고 바로 파일을 저장할 수 있는 것은 아닙니다.

파티션에 파일시스템을 생성해야 합니다.

대표 파일시스템:

- ext4
- xfs

---

## ext4 생성

```bash
mkfs -t ext4 /dev/sdb1
```

또는:

```bash
mkfs.ext4 /dev/sdb1
```

---

## xfs 생성

```bash
mkfs -t xfs /dev/sdb1
```

또는:

```bash
mkfs.xfs /dev/sdb1
```

핵심 관계:

```text
mkfs = 파일시스템 생성 명령
ext4 / xfs = 생성할 파일시스템 종류
```

---

# 6. mount / umount

리눅스에서는 파일시스템을 디렉터리에 연결해서 사용합니다.

예:

```bash
mkdir /mnt/test
mount /dev/sdb1 /mnt/test
```

구조:

```text
/dev/sdb1
    ↓
  mount
    ↓
/mnt/test
```

이제 사용자는 `/mnt/test`를 통해 해당 저장공간에 접근합니다.

---

## 마운트 확인

```bash
df -h
```

현재 마운트된 파일시스템과 사용량을 사람이 읽기 쉬운 단위로 확인합니다.

---

## 마운트 해제

```bash
umount /mnt/test
```

또는 환경에 따라 장치 기준으로:

```bash
umount /dev/sdb1
```

주의:

```text
mount  ← n 있음
umount ← n 없음
```

---

# 7. /etc/fstab과 /etc/mtab

## /etc/fstab

부팅 시 어떤 파일시스템을 어디에 마운트할지 기록하는 설정 파일입니다.

예:

```text
/dev/sdb1    /mnt/test    ext4    defaults    0 0
```

뜻:

```text
장치          마운트 위치     파일시스템     옵션        dump  fsck
/dev/sdb1     /mnt/test       ext4          defaults     0     0
```

핵심:

> `/etc/fstab` = 앞으로 어떻게 마운트할지 저장한 영구 설정

---

## mount -a

```bash
mount -a
```

`-a`의 `a`는 **all**입니다.

쉽게 말하면:

> `/etc/fstab`에 등록된 마운트 항목들을 일괄 적용

실습 흐름:

```text
vi /etc/fstab
      ↓
설정 추가
      ↓
mount -a
      ↓
df -h
      ↓
정상 마운트 확인
```

---

## /etc/mtab

현재 마운트되어 있는 파일시스템 정보를 확인할 수 있습니다.

암기:

```text
/etc/fstab = 설정
/etc/mtab  = 현재 상태
```

---

# 8. /dev/null

예:

```bash
mkfs -t ext4 /dev/TEST_VG/TEST_LV1 > /dev/null
```

`/dev/null`은 흔히 리눅스의 블랙홀이라고 부릅니다.

```bash
> /dev/null
```

은 표준 출력(stdout)을 버립니다.

예:

```bash
echo "hello" > /dev/null
```

화면에 출력되지 않습니다.

주의:

```bash
command > /dev/null
```

은 표준 출력만 버립니다.

표준 에러까지 버리려면:

```bash
command > /dev/null 2>&1
```

---

# 9. LVM 개념

LVM은 Logical Volume Manager의 약자입니다.

일반 파티션보다 저장공간을 더 유연하게 관리하기 위해 사용합니다.

기본 구조:

```text
디스크 / 파티션
      ↓
     PV
      ↓
     VG
      ↓
     LV
      ↓
파일시스템
      ↓
   mount
```

---

# 10. PV, VG, LV

## PV - Physical Volume

LVM에서 사용할 실제 저장공간입니다.

예:

```bash
pvcreate /dev/sdb1
pvcreate /dev/sdc1
```

구조:

```text
/dev/sdb1 → PV
/dev/sdc1 → PV
```

---

## VG - Volume Group

여러 PV를 하나의 저장공간 Pool로 묶습니다.

예:

```bash
vgcreate TEST_VG /dev/sdb1 /dev/sdc1
```

구조:

```text
/dev/sdb1 ─┐
           ├── TEST_VG
/dev/sdc1 ─┘
```

---

## LV - Logical Volume

VG에서 실제 사용할 공간을 논리적으로 잘라냅니다.

예:

```bash
lvcreate -L 5G -n TEST_LV1 TEST_VG
```

구조:

```text
TEST_VG
 ├── TEST_LV1
 ├── TEST_LV2
 └── 남은 공간
```

---

# 11. LVM 파일시스템 생성 및 마운트

예:

```bash
mkfs -t ext4 /dev/TEST_VG/TEST_LV1 > /dev/null
```

뜻:

```text
mkfs
 ├─ -t ext4
 │    └─ ext4 파일시스템 지정
 │
 ├─ /dev/TEST_VG/TEST_LV1
 │    ├─ TEST_VG  = VG
 │    └─ TEST_LV1 = LV
 │
 └─ > /dev/null
      └─ 일반 출력 버림
```

그 후:

```bash
mkdir /mnt/test
mount /dev/TEST_VG/TEST_LV1 /mnt/test
df -h
```

전체 흐름:

```text
/dev/sdb1
    ↓
 pvcreate
    ↓
   PV
    ↓
 vgcreate
    ↓
TEST_VG
    ↓
 lvcreate
    ↓
TEST_LV1
    ↓
mkfs.ext4
    ↓
 mount
    ↓
/mnt/test
```

---

# 12. RAID 개념

RAID는 여러 디스크를 묶어 성능, 안정성, 저장 효율 등을 높이는 기술입니다.

오늘 학습한 RAID:

- RAID 0
- RAID 1
- RAID 5
- RAID 6
- RAID 0+1
- RAID 1+0 (RAID 10)

---

# 13. RAID 0

## 특징

- Striping
- 데이터를 여러 디스크에 분산 저장
- 성능 우수
- 장애 복구 기능 없음

최소 디스크:

```text
2개
```

용량:

```text
N × S
```

- N = 디스크 개수
- S = 가장 작은 디스크 용량

예:

```text
Disk A     Disk B
DATA 1     DATA 2
DATA 3     DATA 4
```

암기:

> 빠르지만 하나라도 죽으면 전체가 위험하다. 💀

---

# 14. RAID 1

## 특징

- Mirroring
- 동일한 데이터를 복제
- 안정성 우수
- 저장 효율은 낮음

최소 디스크:

```text
2개
```

예:

```text
Disk A     Disk B
DATA 1     DATA 1
DATA 2     DATA 2
```

암기:

> RAID 1 = 거울 복제

---

# 15. RAID 5

## 특징

- Striping + Parity
- Parity를 여러 디스크에 분산 저장
- 디스크 1개 장애 허용

최소 디스크:

```text
3개
```

사용 가능 용량:

```text
(N - 1) × S
```

예:

```text
Disk A     Disk B     Disk C
DATA       DATA       PARITY
DATA       PARITY     DATA
PARITY     DATA       DATA
```

암기:

> RAID 5 = Parity 1개 분량 → 1개 장애 허용

---

# 16. RAID 6

## 특징

- RAID 5와 유사
- 이중 Parity 사용
- 디스크 2개 장애 허용

최소 디스크:

```text
4개
```

사용 가능 용량:

```text
(N - 2) × S
```

암기:

> RAID 6 = Parity 2개 분량 → 2개 장애 허용

---

# 17. RAID 0+1

RAID 0을 먼저 만든 뒤 RAID 1로 묶습니다.

즉:

```text
Mirror of Stripes
```

구조:

```text
Disk A ─┐
        ├─ RAID 0 ─┐
Disk B ─┘          │
                   ├─ RAID 1
Disk C ─┐          │
        ├─ RAID 0 ─┘
Disk D ─┘
```

암기:

```text
0 + 1 = 0 먼저 → 1 나중
```

---

# 18. RAID 1+0 (RAID 10)

RAID 1을 먼저 만든 뒤 RAID 0으로 묶습니다.

즉:

```text
Stripe of Mirrors
```

구조:

```text
Disk A ─┐
        ├─ RAID 1 ─┐
Disk B ─┘          │
                   ├─ RAID 0
Disk C ─┐          │
        ├─ RAID 1 ─┘
Disk D ─┘
```

암기:

```text
1 + 0 = 1 먼저 → 0 나중
```

RAID 0+1보다 장애 대응 측면에서 더 유연하여 RAID 10이 더 자주 언급됩니다.

---

# 19. RAID 비교표

| RAID | 방식 | 최소 디스크 | 사용 가능 용량 | 장애 허용 |
|---|---|---:|---:|---|
| RAID 0 | Striping | 2 | N × S | 0 |
| RAID 1 | Mirroring | 2 | S | 보통 1 |
| RAID 5 | Striping + Parity | 3 | (N-1) × S | 1 |
| RAID 6 | Striping + Double Parity | 4 | (N-2) × S | 2 |
| RAID 0+1 | Mirror of Stripes | 4 | 약 50% | 구조에 따라 |
| RAID 1+0 | Stripe of Mirrors | 4 | 약 50% | 구조에 따라 |

---

# 20. mdadm으로 RAID 0 생성

예:

```bash
mdadm --create /dev/md0 --level=0 --raid-devices=3 /dev/sdc1 /dev/sdd1 /dev/sde1
```

구성:

```text
mdadm
 ├─ --create /dev/md0
 │    └─ /dev/md0 RAID 장치 생성
 │
 ├─ --level=0
 │    └─ RAID 0
 │
 ├─ --raid-devices=3
 │    └─ 디스크 3개 사용
 │
 └─ /dev/sdc1 /dev/sdd1 /dev/sde1
      └─ RAID 구성원
```

결과:

```text
/dev/sdc1 ─┐
/dev/sdd1 ─┼── RAID 0 ──→ /dev/md0
/dev/sde1 ─┘
```

---

# 21. RAID 상태 확인

## /dev/md0 확인

```bash
ls -l /dev/md0
```

---

## RAID 장치 정보 확인

```bash
fdisk -l /dev/md0
```

---

## RAID 배열 스캔

```bash
mdadm --detail --scan -v
```

---

## 현재 RAID 상태 확인

```bash
cat /proc/mdstat
```

중요:

> `/proc/mdstat` = 현재 Linux Software RAID 상태 확인

---

# 22. RAID 파일시스템 생성 및 마운트

RAID 장치를 만들었다고 바로 파일 저장이 가능한 것은 아닙니다.

`/dev/md0`에도 파일시스템을 생성해야 합니다.

```bash
mkfs -t ext4 /dev/md0 > /dev/null
```

마운트 포인트 생성:

```bash
mkdir /mnt/raid0
```

마운트:

```bash
mount /dev/md0 /mnt/raid0
```

확인:

```bash
df -h
```

전체 구조:

```text
/dev/sdc1
/dev/sdd1
/dev/sde1
    ↓
  mdadm
    ↓
 /dev/md0
    ↓
  ext4
    ↓
  mount
    ↓
/mnt/raid0
```

---

# 23. RAID 해제 과정

## 1. 마운트 해제

```bash
umount /dev/md0
```

---

## 2. 마운트 포인트 삭제

```bash
rm -rf /mnt/raid0
```

주의:

`rm -rf`는 매우 강력한 삭제 명령이므로 경로를 반드시 확인합니다.

---

## 3. RAID 배열 중지

```bash
mdadm --stop /dev/md0
```

---

## 4. 상태 확인

```bash
cat /proc/mdstat
```

---

## 5. RAID Superblock 확인

```bash
mdadm --examine /dev/sdc1 /dev/sdd1 /dev/sde1
```

RAID 배열을 중지해도 각 구성원에는 RAID 메타데이터가 남아 있을 수 있습니다.

즉:

```text
/dev/sdc1
┌──────────────────┐
│                  │
│ RAID DATA        │
│                  │
│ RAID Superblock  │
└──────────────────┘
```

---

## 6. RAID Superblock 제거

```bash
mdadm --zero-superblock /dev/sdc1 /dev/sdd1 /dev/sde1
```

---

## 7. 제거 확인

```bash
mdadm --examine /dev/sdc1 /dev/sdd1 /dev/sde1
```

---

## 8. /dev/md0 확인

```bash
ls -l /dev/md0
```

---

# 24. RAID 0 생성 → 삭제 전체 실습

```bash
mdadm --create /dev/md0 --level=0 --raid-devices=3 /dev/sdc1 /dev/sdd1 /dev/sde1

ls -l /dev/md0
fdisk -l /dev/md0
mdadm --detail --scan -v
cat /proc/mdstat

mkfs -t ext4 /dev/md0 > /dev/null

mkdir /mnt/raid0
mount /dev/md0 /mnt/raid0
df -h

umount /dev/md0
rm -rf /mnt/raid0

mdadm --stop /dev/md0
cat /proc/mdstat

mdadm --examine /dev/sdc1 /dev/sdd1 /dev/sde1

mdadm --zero-superblock /dev/sdc1 /dev/sdd1 /dev/sde1

mdadm --examine /dev/sdc1 /dev/sdd1 /dev/sde1

ls -l /dev/md0
```

---

# 25. 오늘 배운 내용 전체 연결

```text
VMware HDD 추가
      ↓
  /dev/sdX
      ↓
    fdisk
      ↓
  /dev/sdX1
      ↓
┌─────────────────────────┐
│ 일반 파티션 관리       │
│                         │
│ mkfs → mount → fstab    │
└─────────────────────────┘

또는

/dev/sdX1
    ↓
   PV
    ↓
   VG
    ↓
   LV
    ↓
  mkfs
    ↓
 mount

또는

/dev/sdc1
/dev/sdd1
/dev/sde1
    ↓
  mdadm
    ↓
 RAID 장치
 (/dev/md0)
    ↓
  mkfs
    ↓
 mount
```

---

# 26. 핵심 명령어 치트시트

## 디스크 / 파티션

```bash
lsblk
fdisk -l
fdisk /dev/sdb
```

---

## 파일시스템

```bash
mkfs.ext4 /dev/sdb1
mkfs.xfs /dev/sdb1
```

또는:

```bash
mkfs -t ext4 /dev/sdb1
mkfs -t xfs /dev/sdb1
```

---

## 마운트

```bash
mkdir /mnt/test
mount /dev/sdb1 /mnt/test
umount /mnt/test
df -h
```

---

## 자동 마운트

```bash
vi /etc/fstab
mount -a
```

---

## LVM

```bash
pvcreate /dev/sdb1
vgcreate TEST_VG /dev/sdb1
lvcreate -L 5G -n TEST_LV1 TEST_VG
mkfs.ext4 /dev/TEST_VG/TEST_LV1
```

---

## RAID

```bash
mdadm --create
mdadm --detail --scan -v
cat /proc/mdstat
mdadm --stop
mdadm --examine
mdadm --zero-superblock
```

---

# 27. 시험 직전 초압축 암기

```text
파티션
fdisk

파일시스템 생성
mkfs

파일시스템 종류
ext4 / xfs

연결
mount

연결 해제
umount

부팅 시 영구 마운트 설정
/etc/fstab

현재 마운트 상태
/etc/mtab

fstab 일괄 적용
mount -a
(a = all)
```

LVM:

```text
PV → VG → LV
```

RAID:

```text
RAID 0  = Striping / 빠름 / 복구성 없음
RAID 1  = Mirroring / 복제
RAID 5  = Parity 1 / 1개 장애 허용
RAID 6  = Parity 2 / 2개 장애 허용
RAID 01 = RAID 0 → RAID 1
RAID 10 = RAID 1 → RAID 0
```

---

# 28. 최종 핵심

오늘 내용의 핵심을 가장 짧게 정리하면:

```text
일반 저장장치

Disk
 ↓
Partition
 ↓
Filesystem
 ↓
Mount
```

LVM:

```text
Disk
 ↓
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

RAID:

```text
여러 Disk / Partition
        ↓
      RAID
        ↓
   /dev/mdX
        ↓
   Filesystem
        ↓
      Mount
```

---

# 29. 마지막 암기 문장 🐧

> **fdisk는 나누고, mkfs는 포맷하고, mount는 연결한다.**

> **fstab은 부팅 후에도 기억하고, mtab은 지금 상태를 보여준다.**

> **LVM은 PV를 VG로 묶고 VG에서 LV를 잘라 쓴다.**

> **RAID는 여러 디스크를 묶어 성능 또는 안정성을 확보한다.**

---

## 공포의 저장장치 진도 💀

```text
fdisk
 ↓
ext4 / xfs
 ↓
mount
 ↓
fstab
 ↓
PV
 ↓
VG
 ↓
LV
 ↓
RAID 0
 ↓
RAID 1
 ↓
RAID 5
 ↓
RAID 6
 ↓
RAID 0+1
 ↓
RAID 1+0
 ↓
mdadm
 ↓
🐧💀
```

오늘의 결론:

> 펭귄은 디스크 하나 추가해줬을 뿐인데, 우리는 RAID 10까지 갔다.