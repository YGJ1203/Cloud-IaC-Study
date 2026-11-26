# 2026.11.26 (목) 시스템 보안 학습 정리

## 1. 오늘의 학습 주제

- 시스템 보안 기초
- FTZ 리눅스 실습 환경
- CPU 레지스터의 구조와 역할
- x86 32bit 어셈블리어
- 16진수 및 메모리 주소 계산
- 스택(Stack)과 스택 프레임(Stack Frame)
- 배열의 메모리 저장 구조
- 함수 호출 및 반환 과정
- GCC 컴파일 및 어셈블리어 변환
- GDB를 이용한 실행 파일 분석

---

## 2. 실습 환경

| 구분 | 내용 |
|---|---|
| 실습 환경 | FTZ Linux |
| 접속 도구 | MobaXterm |
| 접속 방식 | SSH |
| 서버 IP | 192.168.2.130 |
| 사용자 | level9 |
| 작업 경로 | /home/level9/tmp |
| CPU 아키텍처 | x86 32bit |
| 컴파일러 | GCC 3.2.2 |
| 디버깅 도구 | GDB |
| 어셈블리어 문법 | AT&T Syntax |

### 기본 환경 확인

```bash
pwd
id
ls -ld
ls -l
cd tmp
```

- 현재 작업 디렉터리 확인
- 사용자 UID 및 GID 확인
- 파일 및 디렉터리 권한 확인
- 실습 파일을 작성할 tmp 디렉터리로 이동

---

## 3. CPU 레지스터

레지스터(Register)는 CPU 내부에 존재하는 고속 저장 공간이다.

CPU는 레지스터를 이용하여 데이터를 저장하고,
연산을 수행하며, 메모리 주소와 명령어 실행 위치를 관리한다.

### 주요 레지스터

| 레지스터 | 역할 |
|---|---|
| EAX | 산술 연산 및 함수 반환값 저장 |
| EBX | 범용 데이터 저장 |
| ECX | 반복 횟수 및 범용 데이터 저장 |
| EDX | 연산 보조 및 범용 데이터 저장 |
| ESI | 데이터 복사 시 출발지 주소 등에 사용 |
| EDI | 데이터 복사 시 목적지 주소 등에 사용 |
| ESP | 현재 스택의 최상단 주소 |
| EBP | 스택 프레임의 기준 주소로 사용 |
| EIP | 다음에 실행할 명령어의 주소 |
| EFLAGS | 연산 결과 및 CPU 상태 정보 저장 |

### 핵심 레지스터

- EAX : 연산 결과 및 함수 반환값
- ESP : 현재 스택의 위치
- EBP : 함수의 스택 프레임 기준점
- EIP : 명령어 실행 위치

※ EBP의 스택 프레임 역할은 오늘 실습한 함수 구조를 기준으로 한다.

---

## 4. 16진수와 메모리 주소

컴퓨터의 메모리 주소는 일반적으로 16진수로 표현한다.

### 16진수의 기본 구성

| 10진수 | 16진수 |
|---|---|
| 10 | A |
| 11 | B |
| 12 | C |
| 13 | D |
| 14 | E |
| 15 | F |
| 16 | 10 |

- 0x는 16진수를 나타내는 접두사이다.
- 16진수는 F 다음에 자리올림이 발생한다.
- 메모리 주소는 데이터가 저장된 위치를 의미한다.
- 메모리 주소와 해당 주소에 저장된 값은 서로 다르다.

### 메모리 주소 계산 예시

기준 주소 : 0xbfffe5dc

| 변화량 | 메모리 주소 |
|---|---|
| -8 Byte | 0xbfffe5d4 |
| -4 Byte | 0xbfffe5d8 |
| 0 Byte | 0xbfffe5dc |
| +4 Byte | 0xbfffe5e0 |
| +8 Byte | 0xbfffe5e4 |
| +12 Byte | 0xbfffe5e8 |
| +16 Byte | 0xbfffe5ec |
| +20 Byte | 0xbfffe5f0 |

32bit x86 환경에서 int 및 일반적인 32bit 스택 값은
4Byte 크기를 가지므로 4Byte 단위의 주소 계산이 자주 사용된다.

---

## 5. 어셈블리어(Assembly Language)

어셈블리어는 CPU의 기계어 명령을 사람이 읽을 수 있는
기호와 명령어 형태로 표현한 저수준 언어이다.

### 프로그램 변환 과정

```text
C언어 소스 코드
       ↓
전처리 및 컴파일
       ↓
어셈블리어
       ↓
어셈블
       ↓
목적 파일(Object File)
       ↓
링킹(Linking)
       ↓
실행 파일(Executable File)
```

### AT&T 문법의 특징

```asm
movl $6, %eax
```

- % : 레지스터 표시
- $ : 즉시값(Immediate Value) 표시
- 명령어의 첫 번째 피연산자 : 출발지(Source)
- 명령어의 두 번째 피연산자 : 목적지(Destination)
- l : 32bit(Long) 크기의 피연산자

위 명령어는 EAX 레지스터에 숫자 6을 저장한다.

### 주요 어셈블리어 명령어

| 명령어 | 설명 |
|---|---|
| movl | 32bit 데이터 복사 |
| addl | 덧셈 연산 |
| subl | 뺄셈 연산 |
| pushl | 스택에 32bit 데이터 저장 |
| popl | 스택에서 32bit 데이터 추출 |
| leal | 유효 주소 계산 |
| cmpl | 두 값 비교 |
| jmp | 지정한 명령어 위치로 이동 |
| je | 비교 결과가 같을 경우 이동 |
| jne | 비교 결과가 다를 경우 이동 |
| call | 함수 호출 |
| leave | 현재 스택 프레임 정리 |
| ret | 호출한 함수로 복귀 |
| nop | 별도의 데이터 연산을 수행하지 않음 |

### 피연산자 사용 예시

```asm
movl $6, %eax
movl %eax, %ebx
movl %eax, -4(%ebp)
movl -4(%ebp), %eax
```

- EAX에 숫자 6 저장
- EAX의 값을 EBX로 복사
- EAX의 값을 EBP - 4 주소의 메모리에 저장
- EBP - 4 주소의 메모리 값을 EAX로 복사

---

## 6. 스택(Stack)

스택은 함수 호출, 지역변수, 함수 인자,
복귀 주소 등의 데이터를 관리하는 메모리 영역이다.

LIFO(Last In First Out) 구조를 가진다.

- 가장 마지막에 저장한 데이터가 가장 먼저 제거된다.
- x86 환경의 스택은 높은 주소에서 낮은 주소 방향으로 성장한다.
- ESP를 이용하여 현재 스택의 최상단을 관리한다.

### PUSH와 POP

```asm
pushl %eax
```

32bit 환경에서의 동작:

1. ESP를 4Byte 감소시킨다.
2. 변경된 ESP가 가리키는 메모리에 EAX 값을 저장한다.

```asm
popl %eax
```

32bit 환경에서의 동작:

1. ESP가 가리키는 메모리 값을 EAX에 저장한다.
2. ESP를 4Byte 증가시킨다.

### 스택 프레임(Stack Frame)

함수가 실행될 때 함수별로 사용하는 스택 영역이다.

주요 구성 요소:

- 함수 인자(Parameter)
- 복귀 주소(Return Address)
- 이전 EBP 값(Saved EBP)
- 지역변수(Local Variable)

### 일반적인 스택 프레임 구조

오늘 실습한 add 함수 기준:

```text
높은 메모리 주소
┌───────────────────────┐
│ 두 번째 인자 b         │ EBP + 12
├───────────────────────┤
│ 첫 번째 인자 a         │ EBP + 8
├───────────────────────┤
│ 복귀 주소              │ EBP + 4
├───────────────────────┤
│ 이전 EBP              │ EBP
├───────────────────────┤
│ 지역변수 x             │ EBP - 4
├───────────────────────┤
│ 지역변수 y             │ EBP - 8
└───────────────────────┘
낮은 메모리 주소
```

---

## 7. 배열(Array)과 메모리 구조

배열은 동일한 자료형의 데이터를 연속된 메모리 공간에
저장하는 자료구조이다.

### C언어 배열 예시

```c
int arr[3] = {10, 20, 30};
```

int 자료형의 크기가 4Byte인 환경에서는
총 12Byte의 메모리 공간을 사용한다.

### 배열 메모리 배치 예시

시작 주소를 0x1000으로 가정한다.

| 배열 요소 | 메모리 주소 | 저장값 |
|---|---|---|
| arr[0] | 0x1000 | 10 |
| arr[1] | 0x1004 | 20 |
| arr[2] | 0x1008 | 30 |

### 배열 주소 계산 공식

```text
배열 요소의 주소
= 배열 시작 주소 + (인덱스 × 자료형 크기)
```

### 어셈블리어 배열 접근 예시

EBX에 배열 시작 주소가 저장되어 있다고 가정한다.

```asm
movl $1, %ecx
movl (%ebx,%ecx,4), %eax
```

- EBX : 배열 시작 주소
- ECX : 배열 인덱스
- 4 : int 자료형의 크기
- EAX : 배열에서 읽어온 값

실행 결과:

```text
EAX = 20
```

### 주의 사항

- 스택은 낮은 주소 방향으로 성장한다.
- 배열의 인덱스는 높은 주소 방향으로 증가한다.
- 스택 공간을 확보하는 방향과 배열 내부의 배치 방향은 다르다.

※ 배열 부분은 학습 개념을 설명하기 위한 예시이다.

---

## 8. C언어 함수 작성 실습

### stack.c 작성

```bash
vi stack.c
```

### 실제 작성한 소스 코드

```c
#include <stdio.h>

int add(int a, int b)
{
    int x = a, y = b;
    return (x + y);
}

int main(int argc, char* argv[])
{
    int a = 6, b = 2;
    printf("%d\n", add(a, b));
    return 0;
}
```

### 코드 동작 과정

1. main 함수 실행
2. 지역변수 a = 6, b = 2 선언
3. add(a, b) 함수 호출
4. add 함수의 지역변수 x와 y에 인자값 저장
5. x + y 연산 수행
6. 연산 결과 8 반환
7. printf 함수로 결과 출력
8. 프로그램 정상 종료

---

## 9. GCC 컴파일 실습

### 어셈블리어 파일 생성

```bash
gcc -mpreferred-stack-boundary=2 -S -o stack.a stack.c
```

### 실행 파일 생성

```bash
gcc -mpreferred-stack-boundary=2 -o stack stack.c
```

### GCC 옵션 설명

| 옵션 | 설명 |
|---|---|
| -S | 어셈블리어 생성 단계에서 중단 |
| -o | 출력 파일 이름 지정 |
| -mpreferred-stack-boundary=2 | 선호 스택 정렬 경계를 2의 2제곱인 4Byte로 지정 |

### 생성 파일

```text
stack.c : C언어 소스 파일
stack.a : 어셈블리어 텍스트 파일
stack   : ELF 32bit 실행 파일
```

※ 일반적으로 어셈블리어 소스 파일은 .s 확장자를 사용하지만,
오늘 실습에서는 stack.a라는 이름을 사용하였다.

### 파일 형식 확인

```bash
file stack.c
file stack.a
file stack
```

### 프로그램 실행

```bash
./stack
```

실제 실행 결과:

```text
8
```

---

## 10. 컴파일 과정에서 발생한 문제 및 해결

### 문제 상황

```bash
gcc -mpreferred-stack-boundary=2 -S -o stack.a stack.c
gcc -mpreferred-stack-boundary=2 -o stack.a stack.c
```

두 번째 명령어에서 어셈블리어 텍스트 파일인 stack.a를
ELF 실행 파일로 덮어쓰는 문제가 발생하였다.

### 문제 확인

```bash
file stack.a
```

출력 결과:

```text
stack.a: ELF 32-bit LSB executable, Intel 80386
```

```bash
cat stack.a
```

바이너리 실행 파일을 텍스트로 출력하여
깨진 문자 및 읽기 어려운 데이터가 나타났다.

### 해결 방법

```bash
rm -rf stack.a
rm -rf stack

gcc -mpreferred-stack-boundary=2 -S -o stack.a stack.c
gcc -mpreferred-stack-boundary=2 -o stack stack.c
```

### 해결 결과

- 어셈블리어 파일 정상 생성
- ELF 실행 파일 정상 생성
- cat stack.a를 이용한 어셈블리어 확인 성공
- ./stack 실행 결과 8 출력 확인

### 학습 내용

- 파일 확장자만으로 실제 파일 형식이 결정되는 것은 아니다.
- file 명령어를 이용하여 실제 파일 형식을 확인할 수 있다.
- GCC의 -S 및 -o 옵션을 정확히 구분해야 한다.
- 실행 파일 분석에는 cat보다 GDB, objdump 등의 도구가 적합하다.
- 일반 파일 삭제에는 rm -f로도 충분하다.

---

## 11. main 함수 어셈블리어 분석

### 실제 생성된 main 함수

```asm
main:
    pushl   %ebp
    movl    %esp, %ebp
    subl    $8, %esp
    movl    $6, -4(%ebp)
    movl    $2, -8(%ebp)
    pushl   -8(%ebp)
    pushl   -4(%ebp)
    call    add
    addl    $8, %esp
    pushl   %eax
    pushl   $.LC0
    call    printf
    addl    $8, %esp
    movl    $0, %eax
    leave
    ret
```

### 명령어별 분석

| 명령어 | 설명 |
|---|---|
| pushl %ebp | 기존 EBP 값 백업 |
| movl %esp, %ebp | 새로운 스택 프레임 기준점 설정 |
| subl $8, %esp | 지역변수 공간 8Byte 확보 |
| movl $6, -4(%ebp) | 지역변수 a에 6 저장 |
| movl $2, -8(%ebp) | 지역변수 b에 2 저장 |
| pushl -8(%ebp) | 두 번째 인자 b를 스택에 저장 |
| pushl -4(%ebp) | 첫 번째 인자 a를 스택에 저장 |
| call add | 복귀 주소 저장 및 add 함수 호출 |
| addl $8, %esp | add 함수에 전달한 인자 공간 정리 |
| pushl %eax | add 함수의 반환값을 스택에 저장 |
| pushl $.LC0 | printf의 출력 형식 문자열 주소 저장 |
| call printf | printf 함수 호출 |
| addl $8, %esp | printf 함수의 인자 공간 정리 |
| movl $0, %eax | main 함수의 반환값 0 설정 |
| leave | 스택 프레임 정리 |
| ret | 호출한 위치로 복귀 |

### 함수 인자 전달

오늘 실습에서는 x86 32bit의 cdecl 호출 규약에 따라
함수 인자를 오른쪽에서 왼쪽 순서로 스택에 저장한다.

```c
add(a, b);
```

```asm
pushl -8(%ebp)
pushl -4(%ebp)
call add
```

- b를 먼저 스택에 저장
- a를 나중에 스택에 저장
- call 명령어로 복귀 주소 저장 및 함수 호출
- 함수 반환 후 호출자가 인자 공간 정리

---

## 12. add 함수 어셈블리어 분석

### 실제 생성된 add 함수

```asm
add:
    pushl   %ebp
    movl    %esp, %ebp
    subl    $8, %esp
    movl    8(%ebp), %eax
    movl    %eax, -4(%ebp)
    movl    12(%ebp), %eax
    movl    %eax, -8(%ebp)
    movl    -8(%ebp), %eax
    addl    -4(%ebp), %eax
    leave
    ret
```

### 명령어별 분석

| 명령어 | 설명 |
|---|---|
| pushl %ebp | 이전 EBP 백업 |
| movl %esp, %ebp | 새로운 스택 프레임 생성 |
| subl $8, %esp | 지역변수 x, y 공간 확보 |
| movl 8(%ebp), %eax | 첫 번째 인자 a를 EAX에 저장 |
| movl %eax, -4(%ebp) | 지역변수 x에 a의 값 저장 |
| movl 12(%ebp), %eax | 두 번째 인자 b를 EAX에 저장 |
| movl %eax, -8(%ebp) | 지역변수 y에 b의 값 저장 |
| movl -8(%ebp), %eax | 지역변수 y를 EAX에 저장 |
| addl -4(%ebp), %eax | EAX에 지역변수 x의 값 더하기 |
| leave | 스택 프레임 정리 |
| ret | main 함수로 복귀 |

### 연산 과정

```text
a = 6
b = 2

x = 6
y = 2

EAX = y
EAX = EAX + x
EAX = 2 + 6
EAX = 8
```

함수의 반환값은 EAX를 통해 전달된다.

---

## 13. 함수 호출과 반환 과정

### 함수 프롤로그(Function Prologue)

```asm
pushl %ebp
movl %esp, %ebp
subl $8, %esp
```

- 기존 EBP 백업
- 새로운 스택 프레임의 기준점 설정
- 지역변수 저장 공간 확보

### 함수 에필로그(Function Epilogue)

```asm
leave
ret
```

leave 명령어는 일반적으로 다음 동작과 같다.

```asm
movl %ebp, %esp
popl %ebp
```

- 현재 함수의 지역변수 공간 정리
- 기존 EBP 복원

ret 명령어는 스택에 저장된 복귀 주소를 EIP로 가져와
함수를 호출했던 위치로 실행 흐름을 되돌린다.

### 전체 실행 흐름

```text
main 함수 실행
       ↓
지역변수 a, b 생성
       ↓
함수 인자 스택 저장
       ↓
call add
       ↓
add 함수 스택 프레임 생성
       ↓
x + y 연산
       ↓
EAX에 결과값 8 저장
       ↓
leave / ret
       ↓
main 함수로 복귀
       ↓
printf 실행
       ↓
8 출력
       ↓
프로그램 종료
```

---

## 14. GDB(GNU Debugger)

GDB는 프로그램의 실행 과정을 추적하고
레지스터, 메모리, 함수 및 명령어를 분석하는 디버깅 도구이다.

### 주요 기능

- 프로그램 실행 및 중단
- 중단점(Breakpoint) 설정
- 레지스터 정보 확인
- 메모리 데이터 확인
- 어셈블리어 역어셈블
- 명령어 단위 실행
- 프로그램 오류 분석
- 함수 호출 구조 분석

### GDB 실행

```bash
gdb -q stack
```

-q 옵션은 GDB의 시작 안내 메시지를 생략한다.

### 주요 GDB 명령어

| 명령어 | 설명 |
|---|---|
| disas main | main 함수 역어셈블 |
| disas add | add 함수 역어셈블 |
| b *main | main 함수 시작 주소에 중단점 설정 |
| run / r | 프로그램 실행 |
| info reg | 전체 레지스터 확인 |
| info reg eax esp ebp | 지정한 레지스터 확인 |
| x/12x $esp | ESP부터 메모리 값 12개를 16진수로 확인 |
| x/12wx $esp | 4Byte 단위 메모리 값 12개 확인 |
| x/i $eip | 다음 실행 명령어 확인 |
| si | 기계어 명령어 한 개 실행 |
| ni | 함수 내부로 진입하지 않고 명령어 단위 실행 |
| continue / c | 프로그램 실행 재개 |
| bt | 함수 호출 스택 확인 |
| quit / q | GDB 종료 |

※ si, ni, bt 등은 추가 복습용 명령어이다.

---

## 15. GDB 실제 실습 결과

### main 함수 역어셈블

```gdb
disas main
```

주요 명령어 주소:

| 주소 | 명령어 |
|---|---|
| 0x08048342 | push %ebp |
| 0x08048343 | mov %esp,%ebp |
| 0x08048345 | sub $0x8,%esp |
| 0x08048348 | movl $0x6,-0x4(%ebp) |
| 0x0804834f | movl $0x2,-0x8(%ebp) |
| 0x0804835c | call add |
| 0x08048361 | add $0x8,%esp |
| 0x0804836a | call printf |
| 0x08048377 | leave |
| 0x08048378 | ret |

### 중단점 설정 및 실행

```gdb
b *main
run
```

실행 결과:

```text
Breakpoint 1, 0x08048342 in main ()
```

main 함수의 첫 번째 명령어를 실행하기 직전에 중단되었다.

### 레지스터 확인

```gdb
info reg eax esp ebp
```

실제 출력 결과:

```text
eax    0x1
esp    0xbfffeb5c
ebp    0xbfffeb78
```

| 레지스터 | 확인된 값 |
|---|---|
| EAX | 0x1 |
| ESP | 0xbfffeb5c |
| EBP | 0xbfffeb78 |

※ 아직 main 함수의 프롤로그가 실행되기 전이므로
새로운 main 함수의 스택 프레임은 생성되지 않은 상태이다.

또한 EAX의 초기값 1은 add 함수의 연산 결과가 아니다.

---

## 16. GDB 스택 메모리 확인

### 실행 명령어

```gdb
x/12x $esp
```

### 실제 출력 결과

```text
0xbfffeb5c:  0x42015574  0x00000001  0xbfffeba4  0xbfffebac
0xbfffeb6c:  0x4001582c  0x00000001  0x08048278  0x00000000
0xbfffeb7c:  0x08048299  0x08048342  0x00000001  0xbfffeba4
```

### 명령어 구성

```text
x / 12 x $esp
│   │  │   └─ ESP 레지스터가 가리키는 주소
│   │  └───── 16진수 출력 형식
│   └──────── 출력할 데이터 개수
└──────────── 메모리 확인 명령어
```

4Byte 단위를 명시적으로 지정하려면 다음과 같이 사용한다.

```gdb
x/12wx $esp
```

- w : Word, 4Byte
- x : Hexadecimal, 16진수

### 메모리 주소별 저장값

| 메모리 주소 | 저장값 |
|---|---|
| 0xbfffeb5c | 0x42015574 |
| 0xbfffeb60 | 0x00000001 |
| 0xbfffeb64 | 0xbfffeba4 |
| 0xbfffeb68 | 0xbfffebac |
| 0xbfffeb6c | 0x4001582c |
| 0xbfffeb70 | 0x00000001 |
| 0xbfffeb74 | 0x08048278 |
| 0xbfffeb78 | 0x00000000 |

메모리 주소와 해당 주소에 저장된 데이터는 구분해야 한다.

---

## 17. 스택 프레임 변화 분석

※ 아래 내용은 실제 GDB 초기 레지스터 값을 기준으로
어셈블리어 명령어의 동작을 계산한 이론적 예상 결과이다.
각 명령어 실행 후의 상태를 GDB에서 직접 확인한 결과는 아니다.

### 초기 상태

```text
ESP = 0xbfffeb5c
EBP = 0xbfffeb78
```

### STEP 1. 기존 EBP 저장

```asm
pushl %ebp
```

```text
ESP = 0xbfffeb58
EBP = 0xbfffeb78
```

ESP가 4Byte 감소하고 기존 EBP 값이 스택에 저장된다.

### STEP 2. 새로운 EBP 설정

```asm
movl %esp, %ebp
```

```text
ESP = 0xbfffeb58
EBP = 0xbfffeb58
```

새로운 스택 프레임의 기준점이 설정된다.

### STEP 3. 지역변수 공간 확보

```asm
subl $8, %esp
```

```text
ESP = 0xbfffeb50
EBP = 0xbfffeb58
```

지역변수 a와 b를 위한 8Byte 공간이 확보된다.

### STEP 4. 지역변수 a 저장

```asm
movl $6, -4(%ebp)
```

```text
0xbfffeb54 = 6
```

### STEP 5. 지역변수 b 저장

```asm
movl $2, -8(%ebp)
```

```text
0xbfffeb50 = 2
```

### 예상 스택 프레임

```text
높은 주소

0xbfffeb5c ┌──────────────────────┐
           │ 0x42015574           │ 복귀 주소
0xbfffeb58 ├──────────────────────┤
           │ 0xbfffeb78           │ 이전 EBP ← EBP
0xbfffeb54 ├──────────────────────┤
           │ 0x00000006           │ 지역변수 a
0xbfffeb50 ├──────────────────────┤
           │ 0x00000002           │ 지역변수 b ← ESP
           └──────────────────────┘

낮은 주소
```

---

## 18. 시스템 보안과 어셈블리어의 연관성

어셈블리어 및 메모리 구조에 대한 이해는
시스템 취약점 분석의 기초가 된다.

### 향후 연계되는 보안 개념

| 보안 개념 | 설명 |
|---|---|
| BOF | Buffer Overflow, 할당된 버퍼 범위를 초과하는 메모리 접근 |
| Stack Overflow | 스택 공간의 한계를 초과하는 현상 |
| Segmentation Fault | 허용되지 않은 메모리 접근 등으로 발생하는 오류 |
| Reverse Engineering | 실행 파일의 구조 및 동작 분석 |
| ASLR | 메모리 주소 배치를 무작위화하는 보호 기법 |
| NX | 특정 메모리 영역의 코드 실행을 제한하는 보호 기법 |
| Stack Canary | 스택 손상을 탐지하기 위한 보호 기법 |
| PIE | 실행 파일의 위치 독립적 실행을 지원하는 방식 |

### 시스템 보안 학습의 목적

- 프로그램의 메모리 사용 방식 이해
- 함수 호출 및 복귀 주소의 역할 이해
- 비정상적인 메모리 접근 원인 분석
- 실행 파일의 내부 동작 분석
- 메모리 취약점 발생 원리 이해
- 시스템 보안 보호 기법 이해

※ 위 보안 기법들은 향후 학습과 연계되는 개념이며,
오늘 직접 공격 및 보호 기법 검증을 수행한 것은 아니다.

---

## 19. 기존 보안 학습과의 연관성

| 학습 분야 | 주요 분석 대상 | 분석 도구 |
|---|---|---|
| 네트워크 보안 | 네트워크 패킷 | Wireshark, tcpdump |
| 네트워크 침입 탐지 | 비정상 트래픽 | Snort IDS |
| 네트워크 방어 | 공격 트래픽 및 세션 | FortiGate NGFW |
| 웹 보안 | HTTP 요청 및 응답 | Burp Suite, FortiWeb |
| 클라우드 보안 | 클라우드 리소스 및 로그 | AWS Console, CloudWatch |
| 시스템 보안 | CPU, 메모리, 실행 파일 | GDB, GCC |

기존에는 네트워크 및 웹 애플리케이션을 중심으로
공격과 방어의 원리를 학습하였다.

오늘은 프로그램 내부의 CPU 명령어, 레지스터,
메모리 및 함수 실행 구조를 분석하는 시스템 보안의
기초 개념을 학습하였다.

---

## 20. 오늘의 핵심 복습

### 반드시 기억할 내용

1. EAX는 일반적인 연산 결과 및 함수 반환값에 사용된다.
2. ESP는 현재 스택의 최상단 주소를 가리킨다.
3. EBP는 오늘 실습에서 스택 프레임의 기준점으로 사용된다.
4. EIP는 다음에 실행할 명령어의 주소를 가리킨다.
5. x86 스택은 높은 주소에서 낮은 주소 방향으로 성장한다.
6. 32bit int 자료형은 4Byte 크기를 가진다.
7. 배열은 연속된 메모리 공간에 저장된다.
8. call은 복귀 주소를 저장하고 함수를 호출한다.
9. leave는 현재 함수의 스택 프레임을 정리한다.
10. ret은 복귀 주소를 이용하여 호출 위치로 돌아간다.
11. GDB는 프로그램의 내부 실행 과정을 분석하는 도구이다.
12. 메모리 주소와 해당 주소에 저장된 값은 서로 다르다.

### 핵심 공식

```text
배열 주소 = 시작 주소 + (인덱스 × 자료형 크기)

PUSH : ESP 감소 → 데이터 저장

POP : 데이터 추출 → ESP 증가

CALL : 복귀 주소 저장 → 함수 호출

RET : 복귀 주소 추출 → 호출 위치로 복귀
```

---

## 21. 실습 완료 및 향후 복습 항목

### 실습 완료

- [x] FTZ SSH 접속
- [x] 사용자 및 디렉터리 권한 확인
- [x] C언어 함수 작성
- [x] GCC 어셈블리어 파일 생성
- [x] GCC 실행 파일 생성
- [x] 컴파일 출력 파일 문제 해결
- [x] 실행 결과 8 확인
- [x] main 함수 어셈블리어 확인
- [x] add 함수 어셈블리어 확인
- [x] GDB 실행
- [x] Breakpoint 설정
- [x] EAX, ESP, EBP 레지스터 확인
- [x] 스택 메모리 데이터 확인

### 향후 복습

- [ ] 16진수 메모리 주소 계산 반복 연습
- [ ] 주요 어셈블리어 명령어 복습
- [ ] EAX, ESP, EBP, EIP 역할 구분
- [ ] GDB si 및 ni 명령어 실습
- [ ] 명령어별 레지스터 변화 직접 확인
- [ ] 함수 호출 전후 스택 프레임 비교
- [ ] 배열의 메모리 저장 구조 분석
- [ ] 버퍼 오버플로우 발생 원리 학습
- [ ] 메모리 보호 기법 학습

---

## 22. 오늘의 학습 소감

오늘은 FTZ 환경에서 C언어 소스를 작성하고,
GCC를 이용하여 어셈블리어 및 실행 파일을 생성하였다.

이후 GDB를 이용하여 함수의 어셈블리어 명령어,
CPU 레지스터 및 스택 메모리 구조를 확인하였다.

기존에 사용하던 고수준 프로그래밍 언어와 달리
어셈블리어는 메모리 주소, 레지스터 및 스택의 변화를
직접 이해해야 하므로 학습 난도가 높았다.

특히 16진수 주소 계산과 함수별 스택 프레임의 변화,
어셈블리어 명령어의 해석에 어려움이 있었다.

향후 명령어 단위 실행과 레지스터 변화 확인을 반복하여
프로그램의 내부 동작 원리를 이해하고,
시스템 취약점 및 메모리 보안 학습의 기반을 마련할 예정이다.

---

## 23. 오늘의 한 줄 정리

C언어로 작성한 프로그램이 CPU 명령어로 변환되고,
레지스터와 스택 메모리를 이용하여 실행되는 과정을
GCC 및 GDB를 통해 학습하였다.