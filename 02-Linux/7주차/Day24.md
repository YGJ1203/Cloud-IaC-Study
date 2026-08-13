# Linux 기본 파일·디렉터리 명령어 정리 🐧

> VMware + MobaXterm Linux 실습 기초 명령어 요약

---

## 1. `pwd` — 현재 위치 확인

**Print Working Directory**

현재 작업 중인 디렉터리의 절대 경로를 출력한다.

```bash
pwd
```

예시:

```text
/etc/httpd/conf.d
```

> 💡 Linux에서 길을 잃었다면 가장 먼저 `pwd`로 현재 위치를 확인한다.

---

## 2. `cd` — 디렉터리 이동

**Change Directory**

```bash
cd [경로]
```

### 절대 경로

루트(`/`)부터 전체 경로를 지정한다.

```bash
cd /etc/httpd/conf.d
```

현재 위치와 관계없이 항상 `/etc/httpd/conf.d`로 이동한다.

### 상대 경로

현재 위치를 기준으로 이동한다.

```bash
cd ../conf.d
```

주요 표현:

| 표현 | 의미 |
|---|---|
| `.` | 현재 디렉터리 |
| `..` | 상위 디렉터리 |
| `~` | 현재 사용자의 홈 디렉터리 |
| `/` | 최상위(Root) 디렉터리 |

```bash
cd ..
cd ~
cd /
```

---

## 3. `ls` — 파일 및 디렉터리 목록 확인

**List**

```bash
ls
```

### 주요 옵션

| 명령어 | 의미 |
|---|---|
| `ls -l` | 상세 정보 출력 |
| `ls -a` | 숨김 파일 포함 전체 출력 |
| `ls -i` | inode 번호 출력 |
| `ls -id [디렉터리]` | 디렉터리 자체의 inode 번호 출력 |
| `ls -R` | 하위 디렉터리까지 재귀적으로 출력 |

예시:

```bash
ls -l
ls -a
ls -i
ls -id /etc
ls -R
```

옵션은 조합할 수도 있다.

```bash
ls -al
```

> `-a` + `-l` → 숨김 파일까지 상세 정보로 출력

---

## 4. `mkdir` — 디렉터리 생성

**Make Directory**

```bash
mkdir test
```

### `-p` 옵션

필요한 상위 디렉터리까지 함께 생성한다.

```bash
mkdir -p linux/test/config
```

`linux`, `test`가 존재하지 않아도 한 번에 전체 구조를 생성할 수 있다.

> ⚠️ 옵션은 소문자 `-p`이다.

---

## 5. `rmdir` — 빈 디렉터리 삭제

**Remove Directory**

```bash
rmdir test
```

단, **비어 있는 디렉터리만 삭제 가능**하다.

파일 등이 들어 있으면 삭제되지 않는다.

---

## 6. `rm` — 파일 및 디렉터리 삭제

**Remove**

```bash
rm test.txt
```

### 주요 옵션

| 옵션 | 의미 |
|---|---|
| `-r` | 디렉터리와 하위 내용을 재귀적으로 삭제 |
| `-f` | 확인 메시지 없이 강제로 삭제 |
| `-rf` | 하위 내용까지 강제로 삭제 |

```bash
rm -r test/
rm -f test.txt
rm -rf test/
```

### ⚠️ `rm -rf` 주의

`rm -rf`는 매우 강력한 삭제 명령어다.

실행 전 반드시 현재 위치와 삭제 대상을 확인하는 습관을 들인다.

```bash
pwd
ls
```

그 다음 삭제 대상을 다시 확인한다.

> 💀 특히 root 권한으로 광범위한 경로를 대상으로 실행하면 심각한 데이터 손실로 이어질 수 있다.

---

## 7. `touch` — 빈 파일 생성 / 시간 정보 변경

기본적으로 파일이 존재하지 않으면 빈 파일을 생성한다.

```bash
touch test.txt
```

이미 존재하는 파일이라면 기본적으로 접근/수정 시간 정보를 현재 시각으로 갱신한다.

### `-t` 옵션

파일의 시간 정보를 직접 지정한다.

```bash
touch -t YYYYMMDDhhmm test.txt
```

예시:

```bash
touch -t 202608101500 test.txt
```

→ `test.txt`의 시간을 `2026-08-10 15:00`으로 지정

---

## 8. `cp` — 파일 및 디렉터리 복사

**Copy**

기본 형식:

```bash
cp [원본] [대상]
```

예시:

```bash
cp test.txt backup.txt
```

### 주요 옵션

| 옵션 | 의미 |
|---|---|
| `-p` | 권한, 소유권, 시간 정보 등을 가능한 한 보존하여 복사 |
| `-r` | 디렉터리와 하위 내용을 재귀적으로 복사 |

```bash
cp -p test.txt backup.txt
cp -r dir1 dir2
```

---

## 9. `mv` — 파일·디렉터리 이동 / 이름 변경

**Move**

기본 형식:

```bash
mv [원본] [대상]
```

### 이동

```bash
mv test.txt /tmp/
```

### 이름 변경

```bash
mv test.txt linux.txt
```

즉 `mv`는 상황에 따라:

```text
파일 이동
디렉터리 이동
파일 이름 변경
디렉터리 이름 변경
```

에 사용할 수 있다.

---

# 🚀 초간단 암기표

| 명령어 | 핵심 의미 |
|---|---|
| `pwd` | 나 지금 어디지? |
| `cd` | 이동 |
| `ls` | 뭐가 있지? |
| `mkdir` | 디렉터리 생성 |
| `rmdir` | 빈 디렉터리 삭제 |
| `rm` | 삭제 |
| `touch` | 파일 생성 / 시간 변경 |
| `cp` | 복사 |
| `mv` | 이동 / 이름 변경 |

---

## 실습 흐름으로 기억하기

```bash
pwd
ls
mkdir linux
cd linux
touch test.txt
ls -l
cp test.txt backup.txt
mv backup.txt linux.txt
ls -li
rm linux.txt
cd ..
rmdir linux
```

흐름:

```text
현재 위치 확인
    ↓
목록 확인
    ↓
디렉터리 생성
    ↓
이동
    ↓
파일 생성
    ↓
복사
    ↓
이름 변경
    ↓
삭제
```

---

## 🐧 핵심 포인트

1. **`pwd`**로 현재 위치를 확인한다.
2. **절대 경로는 `/`부터**, 상대 경로는 **현재 위치부터** 시작한다.
3. `ls` 옵션은 처음부터 전부 외우기보다 자주 사용하면서 익힌다.
4. 디렉터리 복사는 `cp -r`, 디렉터리 삭제는 `rm -r`이 필요하다.
5. **`rm -rf` 실행 전에는 경로와 삭제 대상을 반드시 확인한다.**
6. `mv`는 이동뿐 아니라 **이름 변경**에도 사용된다.

> 🐧 Linux 기본기 = **현재 위치 확인 → 대상 확인 → 작업 → 결과 확인**
