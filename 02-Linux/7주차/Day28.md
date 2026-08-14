# 🐧 Linux Shell & Process

> Linux의 **Shell(쉘)**과 **Process(프로세스)**의 기본 개념 및 주요 명령어 정리

---

# 1. Shell이란?

**Shell**은 사용자가 입력한 명령어를 해석하여 Linux Kernel에 전달하는 **명령어 해석기(Command Interpreter)**이다.

```text
사용자
  ↓
Shell
  ↓
Kernel
  ↓
Hardware
```

예를 들어 다음 명령어를 입력하면,

```bash
ls -l
```

Shell이 `ls -l`이라는 명령을 해석하여 운영체제에 전달하고 결과를 사용자에게 보여준다.

### 대표적인 Shell

| Shell  | 특징                      |
| ------ | ----------------------- |
| `sh`   | Unix의 기본적인 Shell        |
| `bash` | Linux에서 널리 사용되는 Shell   |
| `zsh`  | 다양한 편의 기능을 제공하는 Shell   |
| `csh`  | C언어와 비슷한 문법을 사용하는 Shell |

현재 사용 중인 Shell 확인:

```bash
echo $SHELL
```

예시:

```text
/bin/bash
```

---

# 2. Shell 변수

Shell에서 값을 저장하기 위해 변수를 사용할 수 있다.

```bash
name=linux
```

변수의 값을 확인할 때는 `$`를 사용한다.

```bash
echo $name
```

출력:

```text
linux
```

⚠️ 변수 선언 시 `=` 앞뒤에 공백을 넣지 않는다.

```bash
name=linux      # 정상
name = linux    # 잘못된 형태
```

---

# 3. 환경 변수

환경 변수(Environment Variable)는 Shell 및 프로그램이 동작할 때 참고하는 시스템 환경 정보이다.

확인:

```bash
env
```

또는

```bash
printenv
```

대표적인 환경 변수:

| 환경 변수    | 의미            |
| -------- | ------------- |
| `$HOME`  | 사용자의 홈 디렉터리   |
| `$USER`  | 현재 사용자        |
| `$SHELL` | 현재 사용자의 Shell |
| `$PATH`  | 명령어를 검색하는 경로  |

예:

```bash
echo $HOME
echo $USER
echo $PATH
```

---

# 4. export

일반 Shell 변수를 **환경 변수로 내보낼 때** 사용한다.

```bash
name=linux
export name
```

또는 한 번에 작성할 수도 있다.

```bash
export name=linux
```

핵심 구조:

```text
Shell 변수
   ↓
 export
   ↓
환경 변수
   ↓
자식 프로세스에서도 사용 가능
```

---

# 5. alias

긴 명령어를 짧은 별칭으로 등록할 수 있다.

```bash
alias ll='ls -l'
```

이후 다음과 같이 사용할 수 있다.

```bash
ll
```

실제로는 다음 명령어가 실행된다.

```bash
ls -l
```

현재 등록된 alias 확인:

```bash
alias
```

alias 삭제:

```bash
unalias ll
```

---

# 6. Redirection

명령어의 입력과 출력을 다른 곳으로 보내는 기능이다.

## `>` 출력 덮어쓰기

```bash
ls > list.txt
```

`ls` 결과를 `list.txt`에 저장한다.

기존 내용이 존재하면 **덮어쓴다.**

---

## `>>` 출력 추가

```bash
ls >> list.txt
```

기존 내용을 유지하면서 결과를 파일 마지막에 추가한다.

```text
>   → 덮어쓰기
>>  → 이어쓰기
```

---

## `<` 입력

파일의 내용을 명령어의 입력으로 사용한다.

```bash
command < file.txt
```

---

# 7. Pipe `|`

앞 명령어의 출력 결과를 **다음 명령어의 입력으로 전달**한다.

```bash
ps -ef | grep httpd
```

동작 과정:

```text
ps -ef
  ↓
전체 프로세스 출력
  ↓
   |
  ↓
grep httpd
  ↓
httpd가 포함된 결과만 출력
```

여러 명령어를 연결할 수도 있다.

```bash
ps -ef | grep httpd > process.txt
```

```text
프로세스 확인
     ↓
httpd 검색
     ↓
파일 저장
```

---

# ⚙️ 8. Process란?

**Process**란 현재 메모리에서 **실행 중인 프로그램**을 의미한다.

```text
Program
   ↓ 실행
Process
```

예를 들어 `bash`, `sshd`, `httpd` 등의 프로그램이 실행되면 각각 프로세스가 생성된다.

---

# 9. PID / PPID

## PID

**Process ID**

각 프로세스를 구분하기 위해 Linux가 부여하는 고유 번호이다.

```text
PID 1001 → bash
PID 1002 → sshd
PID 1003 → httpd
```

---

## PPID

**Parent Process ID**

현재 프로세스를 생성한 **부모 프로세스의 PID**이다.

```text
부모 Process
PID 1000
   │
   ├── PID 1001
   ├── PID 1002
   └── PID 1003
```

PID 1001~1003의 PPID는 `1000`이 된다.

---

# 10. ps

현재 실행 중인 프로세스를 확인한다.

```bash
ps
```

자세히 확인:

```bash
ps -ef
```

주요 항목:

| 항목   | 의미            |
| ---- | ------------- |
| UID  | 프로세스를 실행한 사용자 |
| PID  | 프로세스 ID       |
| PPID | 부모 프로세스 ID    |
| CMD  | 실행된 명령어       |

특정 프로세스 검색:

```bash
ps -ef | grep sshd
```

```bash
ps -ef | grep httpd
```

⭐ 프로세스 문제를 확인할 때 매우 자주 사용하는 형태이다.

---

# 11. top

현재 시스템에서 실행되는 프로세스와 시스템 자원 사용량을 **실시간으로 확인**한다.

```bash
top
```

주로 확인할 수 있는 정보:

* CPU 사용률
* Memory 사용량
* Load Average
* 실행 중인 프로세스
* PID
* 프로세스별 CPU 사용률
* 프로세스별 Memory 사용률

종료:

```text
q
```

---

# 12. htop

`top`보다 보기 편한 **대화형 프로세스 모니터링 도구**이다.

```bash
htop
```

환경에 따라 별도의 설치가 필요할 수 있다.

화면에서는 다음과 같은 정보를 쉽게 확인할 수 있다.

```text
CPU  [|||||||||       ]
Mem  [||||||||||||    ]
Swp  [                ]

PID    USER     CPU%    MEM%    COMMAND
1234   root     82.1     5.2    java
1500   user      1.3     0.8    bash
```

### ps / top / htop 비교

| 명령어    | 특징                    |
| ------ | --------------------- |
| `ps`   | 특정 시점의 프로세스 목록 확인     |
| `top`  | 프로세스 및 자원 사용량 실시간 확인  |
| `htop` | `top`보다 직관적인 대화형 모니터링 |

쉽게 생각하면:

```text
ps   → 📸 프로세스 단체사진
top  → 📺 실시간 중계
htop → 📺✨ 보기 편한 실시간 중계
```

---

# 13. Foreground / Background

## Foreground

현재 Terminal을 점유하면서 실행되는 프로세스이다.

```bash
ping 8.8.8.8
```

명령어가 실행되는 동안 일반적으로 다른 명령어를 입력할 수 없다.

`Ctrl + C`

→ 실행 중인 프로세스에 인터럽트 신호를 보내 종료할 때 주로 사용한다.

---

## Background

프로세스를 백그라운드에서 실행한다.

```bash
command &
```

예:

```bash
sleep 100 &
```

Terminal을 계속 사용할 수 있다.

---

# 14. jobs

현재 Shell에서 실행 중이거나 중지된 작업(Job)을 확인한다.

```bash
jobs
```

예:

```text
[1]+ Running    sleep 100 &
```

여기서 `[1]`은 Job 번호이다.

---

# 15. fg / bg

## fg

Background 작업을 Foreground로 가져온다.

```bash
fg %1
```

---

## bg

중지된 작업을 Background에서 계속 실행한다.

```bash
bg %1
```

대표적인 흐름:

```text
프로그램 실행
     ↓
 Ctrl + Z
     ↓
프로세스 일시 정지
     ↓
   jobs
     ↓
┌────┴────┐
↓         ↓
fg        bg
↓         ↓
전면      후면
실행      실행
```

---

# 💀 16. kill

프로세스에 **Signal을 전달하는 명령어**이다.

단순히 "프로세스를 죽이는 명령어"라기보다 **프로세스에게 특정 신호를 보내는 명령어**라고 이해하는 것이 정확하다.

기본 사용법:

```bash
kill PID
```

예:

```bash
kill 1234
```

기본적으로 `SIGTERM(15)`을 전달한다.

```text
SIGTERM

"PID 1234님 정상적으로 종료해주세요 🙂"
```

---

# 17. kill -9

프로세스를 강제로 종료한다.

```bash
kill -9 1234
```

`SIGKILL(9)` Signal을 전달한다.

```text
SIGKILL

"PID 1234 즉시 종료 💀"
```

### SIGTERM vs SIGKILL

| Signal  | 번호 | 특징                  |
| ------- | -: | ------------------- |
| SIGTERM | 15 | 정상적인 종료 요청          |
| SIGKILL |  9 | 강제 종료               |
| SIGINT  |  2 | 키보드 인터럽트 (`Ctrl+C`) |
| SIGSTOP | 19 | 프로세스 정지             |

⚠️ 처음부터 무조건 `kill -9`를 사용하는 것은 권장되지 않는다.

일반적인 순서:

```text
kill PID
   ↓
정상 종료 확인
   ↓
종료되지 않음
   ↓
원인 확인
   ↓
필요한 경우
kill -9 PID
```

---

# 18. 프로세스 문제 해결 흐름

서버가 갑자기 느려졌다고 가정한다.

### ① 시스템 상태 확인

```bash
htop
```

또는

```bash
top
```

↓

CPU 또는 Memory를 과도하게 사용하는 프로세스를 찾는다.

### ② 프로세스 확인

```bash
ps -ef | grep 프로세스명
```

### ③ PID 확인

```text
PID 1234
```

### ④ 정상 종료 시도

```bash
kill 1234
```

### ⑤ 종료 여부 확인

```bash
ps -ef | grep 프로세스명
```

### ⑥ 필요한 경우 강제 종료

```bash
kill -9 1234
```

⭐ 핵심:

```text
문제 발생
   ↓
top / htop
   ↓
자원 사용량 확인
   ↓
ps
   ↓
프로세스 / PID 확인
   ↓
원인 분석
   ↓
kill
   ↓
필요한 경우 kill -9
```

---

# 🧠 19. 핵심 암기

```text
Shell
 └─ 사용자의 명령어를 해석

Variable
 └─ 값을 저장

Environment Variable
 └─ 프로그램이 참고하는 환경 정보

export
 └─ Shell 변수를 환경 변수로 내보냄

alias
 └─ 명령어 별칭

>
 └─ 출력 덮어쓰기

>>
 └─ 출력 추가

|
 └─ 앞 명령어의 출력을 다음 명령어로 전달


Process
 └─ 실행 중인 프로그램

PID
 └─ Process ID

PPID
 └─ Parent Process ID

ps
 └─ 프로세스 확인

top
 └─ 실시간 프로세스/자원 확인

htop
 └─ 보기 편한 실시간 프로세스 모니터링

&
 └─ Background 실행

jobs
 └─ Job 확인

fg
 └─ Foreground로 전환

bg
 └─ Background로 전환

kill
 └─ Signal 전달

kill -9
 └─ 강제 종료 💀
```

---

# 🎯 20. 한 줄 요약

> **Shell은 명령어를 해석하고, Process는 그 명령에 의해 실행되는 작업이며, `ps/top/htop`으로 상태를 확인하고 `kill`을 통해 Signal을 전달하여 프로세스를 제어할 수 있다.**

---

## 💀 오늘의 Linux 생존 공식

```bash
ps -ef | grep process_name
```

```text
"누가 문제인가? 👀"
```

↓

```bash
htop
```

```text
"CPU를 누가 다 먹고 있는가? 🤨"
```

↓

```bash
kill PID
```

```text
"정상적으로 나가주세요 🙂"
```

↓

그래도 안 나감

```bash
kill -9 PID
```

```text
"Philadelphia 76ers가 아니라 Process 76ers였습니다. 💀"
```
