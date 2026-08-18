# 🐧 Linux Supplementary Notes

> 리눅스 기본 명령어와 파일 시스템, 권한, 프로세스 등을 학습한 뒤
> **추가로 알아두면 좋은 개념과 실무에서 자주 사용하는 내용을 정리한 보충 노트**

---

## 1. Linux 명령어를 볼 때 가장 중요한 구조

리눅스 명령어는 대부분 다음 형태로 사용한다.

```bash
명령어 [옵션] [대상]
```

예시:

```bash
ls -al /etc
```

* `ls` : 명령어
* `-al` : 옵션
* `/etc` : 대상 경로

또 다른 예시:

```bash
cp -r test /backup
```

* `cp` : 복사
* `-r` : 디렉토리를 재귀적으로 복사
* `test` : 원본
* `/backup` : 목적지

### 핵심

명령어를 통째로 외우기보다는 다음 순서로 해석한다.

```text
무엇을 할 것인가?
      ↓
어떤 옵션을 사용할 것인가?
      ↓
어디에 적용할 것인가?
```

---

# 2. 절대 경로 vs 상대 경로

## 절대 경로

루트(`/`)부터 시작하는 전체 경로이다.

```bash
cd /etc/httpd/conf.d
```

```text
/
└── etc
    └── httpd
        └── conf.d
```

어느 위치에서 실행하더라도 동일한 위치로 이동한다.

---

## 상대 경로

현재 위치를 기준으로 이동한다.

```bash
cd ../conf.d
```

주요 기호:

| 표현   | 의미             |
| ---- | -------------- |
| `.`  | 현재 디렉토리        |
| `..` | 상위 디렉토리        |
| `~`  | 현재 사용자의 홈 디렉토리 |
| `/`  | 루트 디렉토리        |

예:

```bash
cd ..
cd ../..
cd ~
cd /
```

---

# 3. Linux에서 "모든 것은 파일이다"

리눅스를 이해할 때 매우 중요한 개념이다.

리눅스에서는 일반 문서뿐만 아니라

* 디렉토리
* 장치
* 디스크
* 터미널
* 프로세스 관련 정보

등도 파일 형태로 관리된다.

예:

```text
/dev
```

장치 파일이 존재하는 디렉토리이다.

```text
/proc
```

프로세스 및 커널 정보를 파일 형태로 제공한다.

즉,

> Linux는 시스템의 많은 자원을 **파일이라는 공통 인터페이스로 다룬다.**

---

# 4. 숨김 파일의 정체

Linux에서는 이름이 `.`으로 시작하면 숨김 파일로 취급한다.

예:

```text
.bashrc
.profile
.ssh
```

일반 `ls`로는 보이지 않는다.

```bash
ls
```

숨김 파일까지 확인하려면:

```bash
ls -a
```

상세 정보까지 같이 확인:

```bash
ls -al
```

### 기억법

```text
a = all
l = long
```

따라서:

```bash
ls -al
```

→ **모든 파일을 자세히 보여줘!**

---

# 5. inode란?

Linux에서 파일 이름 자체가 파일의 모든 정보를 가지고 있는 것은 아니다.

파일 시스템 내부에서는 **inode**라는 구조가 파일 정보를 관리한다.

inode에는 대표적으로 다음 정보가 저장된다.

* 파일 종류
* 권한
* 소유자
* 그룹
* 파일 크기
* 시간 정보
* 실제 데이터 위치

inode 번호 확인:

```bash
ls -i
```

상세 정보와 함께 확인:

```bash
ls -li
```

### 구조

```text
파일 이름
   ↓
inode 번호
   ↓
inode
   ↓
실제 데이터 블록
```

이 개념은 이후 **하드 링크**를 이해할 때 매우 중요하다.

---

# 6. Hard Link vs Symbolic Link

## Hard Link

원본과 동일한 inode를 참조한다.

```bash
ln original.txt hard.txt
```

구조:

```text
original.txt ─┐
              ├── inode ── 실제 데이터
hard.txt ─────┘
```

따라서 원본 파일 이름을 삭제하더라도 데이터가 바로 사라지지 않는다.

---

## Symbolic Link

원본 파일의 **경로를 가리키는 별도의 파일**이다.

```bash
ln -s original.txt soft.txt
```

구조:

```text
soft.txt
   ↓
original.txt
   ↓
inode
   ↓
실제 데이터
```

원본이 삭제되면 심볼릭 링크가 가리킬 대상이 사라진다.

### 비교

| 구분        | Hard Link | Symbolic Link |
| --------- | --------- | ------------- |
| inode     | 동일        | 다름            |
| 원본 삭제     | 접근 가능     | 링크 깨짐         |
| 디렉토리 링크   | 제한적       | 가능            |
| 다른 파일 시스템 | 불가능       | 가능            |

---

# 7. 파일 권한 빠르게 읽기

예:

```text
-rwxr-xr--
```

분리하면:

```text
- | rwx | r-x | r--
    ↓      ↓      ↓
  Owner  Group  Other
```

첫 글자:

```text
- : 일반 파일
d : 디렉토리
l : 링크 파일
```

권한:

```text
r = Read
w = Write
x = Execute
```

숫자로 표현하면:

```text
r = 4
w = 2
x = 1
```

따라서:

```text
rwx = 7
r-x = 5
r-- = 4
```

예:

```bash
chmod 754 test.sh
```

의미:

```text
Owner : rwx = 7
Group : r-x = 5
Other : r-- = 4
```

---

# 8. 파일과 디렉토리의 x 권한 차이

여기서 많이 헷갈린다. 💀

## 파일에서 x

파일을 **실행할 수 있는 권한**

```bash
./script.sh
```

---

## 디렉토리에서 x

해당 디렉토리에 **진입하거나 내부 항목에 접근할 수 있는 권한**

```bash
cd directory
```

즉 디렉토리에서는 `x`를 단순히 "실행"이라고 외우면 헷갈릴 수 있다.

```text
파일 x
→ 실행

디렉토리 x
→ 접근/진입
```

---

# 9. root 사용자가 강력한 이유

Linux의 최고 관리자 계정:

```text
root
```

일반적으로 UID는:

```text
UID = 0
```

root는 시스템 전체에 강력한 권한을 가지고 있다.

따라서 다음과 같은 명령은 매우 조심해야 한다.

```bash
rm -rf
```

특히:

```bash
rm -rf /
```

같은 형태는 시스템에 치명적인 손상을 줄 수 있으므로 절대 실습 삼아 실행하지 않는다. 💀

### 핵심 원칙

> root 권한은 **필요할 때만 사용한다.**

---

# 10. 압축과 묶기의 차이

Linux에서는 **파일 묶기**와 **압축**을 구분해서 이해하면 쉽다.

## tar

여러 파일을 하나로 묶는다.

```bash
tar -cvf backup.tar directory/
```

해제:

```bash
tar -xvf backup.tar
```

---

## gzip

파일을 압축한다.

```bash
gzip file
```

결과:

```text
file.gz
```

---

## bzip2

gzip과 비슷한 압축 도구이다.

```bash
bzip2 file
```

결과:

```text
file.bz2
```

---

## tar + gzip

실무에서 매우 자주 볼 수 있다.

```bash
tar -czvf backup.tar.gz directory/
```

해제:

```bash
tar -xzvf backup.tar.gz
```

### 옵션 기억법

```text
c = create
x = extract
v = verbose
f = file
z = gzip
j = bzip2
```

---

# 11. Shell과 Kernel 관계

Linux를 처음 배울 때 반드시 구분해야 한다.

```text
사용자
  ↓
Shell
  ↓
Kernel
  ↓
Hardware
```

## Shell

사용자가 입력한 명령어를 해석한다.

예:

```text
bash
zsh
```

## Kernel

CPU, 메모리, 디스크, 프로세스 등의 시스템 자원을 관리한다.

즉:

> **Shell은 사용자와 Kernel 사이의 명령어 통역사 역할을 한다.**

---

# 12. Process란?

실행 중인 프로그램을 **Process**라고 한다.

프로세스 확인:

```bash
ps
```

전체 프로세스 확인:

```bash
ps -ef
```

실시간 확인:

```bash
top
```

조금 더 보기 편한 도구:

```bash
htop
```

프로세스마다 고유한 번호가 존재한다.

```text
PID = Process ID
```

예:

```text
PID 1234
```

---

# 13. kill은 무조건 "죽여버리는 명령어"가 아니다

```bash
kill PID
```

`kill`은 정확히 말하면 프로세스에 **Signal을 전달하는 명령어**이다.

대표적인 Signal:

| Signal  | 번호 | 의미               |
| ------- | -: | ---------------- |
| SIGHUP  |  1 | 재시작/설정 재로드 등에 사용 |
| SIGINT  |  2 | 인터럽트             |
| SIGTERM | 15 | 정상 종료 요청         |
| SIGKILL |  9 | 강제 종료            |

일반적인 종료:

```bash
kill 1234
```

강제 종료:

```bash
kill -9 1234
```

### 중요한 차이

```text
kill PID
→ 종료 요청

kill -9 PID
→ 강제 종료
```

따라서 처음부터 무조건 `kill -9`를 사용하는 습관은 좋지 않다.

---

# 14. foreground / background

명령어를 일반적으로 실행하면 foreground에서 동작한다.

```bash
command
```

background에서 실행:

```bash
command &
```

예:

```bash
sleep 100 &
```

현재 작업 확인:

```bash
jobs
```

background 작업을 foreground로 가져오기:

```bash
fg
```

---

# 15. Linux 명령어가 기억 안 날 때

모든 옵션을 외우려고 할 필요는 없다.

## man

매뉴얼 확인:

```bash
man ls
```

```bash
man chmod
```

---

## --help

간단한 도움말:

```bash
ls --help
```

```bash
cp --help
```

### 실무적인 접근

```text
명령어의 존재와 목적을 기억
        ↓
자주 사용하는 옵션 기억
        ↓
세부 옵션은 man / --help 확인
```

수십 개의 옵션을 전부 암기하는 것보다 훨씬 현실적이다.

---

# 16. 명령어가 실행되는 과정

예를 들어:

```bash
ls -al
```

을 입력했다고 하자.

```text
사용자
 │
 │ ls -al 입력
 ▼
Shell
 │
 │ 명령어 해석
 ▼
실행 파일 탐색
 │
 │ PATH 확인
 ▼
/usr/bin/ls
 │
 ▼
Kernel
 │
 │ 파일 시스템 접근
 ▼
결과 반환
 │
 ▼
터미널 출력
```

여기서 중요한 개념이 `$PATH`이다.

```bash
echo $PATH
```

Shell은 PATH에 등록된 디렉토리를 검색하여 명령어를 찾는다.

---

# 17. 자주 사용하는 확인 명령어

문제가 발생했을 때 무작정 설정부터 변경하지 말고 **현재 상태를 먼저 확인한다.**

```bash
pwd
```

현재 위치 확인

```bash
ls -al
```

파일 확인

```bash
whoami
```

현재 사용자 확인

```bash
id
```

UID / GID 확인

```bash
ps -ef
```

프로세스 확인

```bash
df -h
```

디스크 사용량 확인

```bash
free -h
```

메모리 사용량 확인

---

# 18. Linux Troubleshooting 기본 사고방식

리눅스에서도 네트워크 트러블슈팅과 마찬가지로 **현재 상태부터 확인하는 습관**이 중요하다.

```text
문제 발생
   ↓
현재 위치 확인
   ↓
파일 존재 여부 확인
   ↓
권한 확인
   ↓
사용자 확인
   ↓
프로세스 확인
   ↓
로그 확인
   ↓
설정 변경
   ↓
재확인
```

예:

```bash
pwd
ls -al
whoami
ps -ef
```

즉,

> **확인 → 원인 추적 → 수정 → 검증**

순서로 접근한다.

---

# 19. 초보자가 자주 하는 실수 💀

### ① 현재 위치를 확인하지 않고 rm 실행

```bash
rm -rf *
```

실행 전에:

```bash
pwd
ls
```

확인 습관을 들인다.

---

### ② 상대 경로를 잘못 계산

```bash
cd ../../../
```

`..` 하나마다 상위 디렉토리 한 단계이다.

헷갈린다면 절대 경로를 사용한다.

---

### ③ 권한 문제인데 파일 문제라고 생각

```text
Permission denied
```

확인:

```bash
ls -l
```

---

### ④ 프로세스가 안 죽는다고 바로 kill -9

먼저:

```bash
kill PID
```

그래도 종료되지 않을 경우 강제 종료를 고려한다.

---

### ⑤ 명령어 옵션을 무조건 암기

필요하면:

```bash
man 명령어
```

또는:

```bash
명령어 --help
```

를 활용한다.

---

# 20. 한 장으로 보는 Linux 핵심 구조

```text
                    Linux
                      │
        ┌─────────────┼─────────────┐
        │             │             │
      Shell       File System     Process
        │             │             │
   bash / 명령어      /            PID
        │             │             │
   PATH / 환경변수   /etc          ps
                      /home         top
                      /var          htop
                      /dev          kill
                      /proc
                        │
              ┌─────────┴─────────┐
              │                   │
            File                Permission
              │                   │
        일반/디렉토리/링크        rwx
              │                   │
          inode/link           chmod
              │
          압축/백업
              │
      tar / gzip / bzip2
```

---

# 21. ⭐ 꼭 기억할 핵심 10개

1. Linux의 최상위 디렉토리는 `/`이다.
2. 절대 경로는 `/`부터 시작한다.
3. `..`은 상위 디렉토리를 의미한다.
4. Linux에서는 많은 시스템 자원을 파일 형태로 다룬다.
5. inode는 파일의 메타데이터와 데이터 위치 정보를 관리한다.
6. 권한은 `Owner / Group / Other`로 구분한다.
7. `r=4`, `w=2`, `x=1`이다.
8. Process는 실행 중인 프로그램이다.
9. `kill`은 프로세스에 Signal을 전달한다.
10. 문제 발생 시 **확인 → 원인 추적 → 수정 → 검증** 순서로 접근한다.

---

# 22. 💀 마지막 암기용 초압축

```text
경로
├─ /  : Root
├─ .  : 현재
├─ .. : 상위
└─ ~  : Home

권한
├─ r = 4
├─ w = 2
└─ x = 1

파일
├─ 일반 파일
├─ 디렉토리
├─ 링크
└─ 장치 파일

압축
├─ tar   : 묶기
├─ gzip  : 압축
├─ bzip2 : 압축
└─ zip   : 묶기 + 압축

프로세스
├─ ps   : 조회
├─ top  : 실시간 조회
├─ htop : 보기 편한 실시간 조회
└─ kill : Signal 전달

Linux 문제 해결
확인 → 추적 → 수정 → 검증
```

---

## 마무리

리눅스 초반에는 명령어가 많아 보여서 전부 외워야 할 것처럼 느껴지지만, 실제로는 **명령어의 목적과 구조를 이해하는 것이 먼저**이다.

특히 다음 네 가지를 중심으로 익힌다.

```text
① 나는 지금 어디에 있는가?
② 어떤 파일을 다루고 있는가?
③ 어떤 권한으로 작업하고 있는가?
④ 어떤 프로세스가 실행되고 있는가?
```

이 네 가지가 익숙해지면 이후 배우게 되는 **서비스 관리, 네트워크 설정, 로그 분석, 서버 운영, 보안, Docker 및 클라우드 환경**도 훨씬 이해하기 쉬워진다. 🐧
