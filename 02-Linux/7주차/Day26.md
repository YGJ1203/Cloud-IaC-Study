# Linux 파일 시스템 · 링크 · 압축/아카이브 핵심 정리 🐧

> **목표:** 명령어를 무작정 외우기보다 **파일 종류 → 링크 → 디렉터리
> 구조 → 압축 → 아카이브** 순서로 이해한다.

------------------------------------------------------------------------

## 1. Linux 파일 종류

`ls -l`의 맨 앞 문자를 보면 파일 종류를 확인할 수 있다.

  문자   종류             핵심
  ------ ---------------- ----------------------------
  `-`    일반 파일        텍스트, 실행 파일 등
  `d`    디렉터리         파일/디렉터리를 담는 구조
  `l`    링크 파일        다른 파일 또는 경로를 연결
  `b`    블록 장치 파일   디스크처럼 블록 단위 처리
  `c`    문자 장치 파일   터미널처럼 문자 단위 처리

``` text
-rw-r--r--  일반 파일
drwxr-xr-x  디렉터리
lrwxrwxrwx  심볼릭 링크
brw-rw----  블록 장치
crw-rw----  문자 장치
```

장치 파일은 주로 `/dev` 아래에 있다.

``` bash
ls -l /dev
```

------------------------------------------------------------------------

## 2. 링크 파일

### 하드 링크 (Hard Link)

``` bash
ln 원본파일 링크파일
```

예:

``` bash
ln test.txt hard_test.txt
```

-   원본과 **같은 inode**를 가리킨다.
-   하나의 실제 데이터에 이름이 하나 더 생긴 것과 비슷하다.
-   한쪽 이름을 삭제해도 다른 하드 링크가 남아 있으면 데이터는 유지된다.
-   일반적으로 디렉터리에는 만들지 않는다.
-   다른 파일 시스템을 넘어 만들 수 없다.

inode 확인:

``` bash
ls -li
```

### 심볼릭 링크 (Symbolic Link)

Windows의 바로가기와 비슷하다.

``` bash
ln -s 원본 링크파일
```

예:

``` bash
ln -s /etc/passwd passwd_link
```

-   원본과 별도의 inode를 가진다.
-   원본의 **경로를 가리킨다.**
-   디렉터리에도 만들 수 있다.
-   다른 파일 시스템의 경로도 가리킬 수 있다.
-   원본이 삭제되면 링크가 깨질 수 있다.

확인:

``` bash
ls -l passwd_link
```

``` text
passwd_link -> /etc/passwd
```

### 하드 링크 vs 심볼릭 링크

  구분               하드 링크                      심볼릭 링크
  ------------------ ------------------------------ --------------------------
  명령어             `ln`                           `ln -s`
  inode              원본과 동일                    별도 inode
  개념               같은 데이터의 또 다른 이름     경로를 가리키는 바로가기
  원본 삭제          다른 링크가 남으면 사용 가능   링크가 깨질 수 있음
  디렉터리           일반적으로 제한                가능
  다른 파일 시스템   불가능                         가능

**암기:** `Hard = 같은 inode`, `Symbolic = 경로를 가리킴`

------------------------------------------------------------------------

## 3. Linux 디렉터리 구조

모든 디렉터리는 최상위 `/`에서 시작한다.

``` text
/
├── bin
├── boot
├── dev
├── etc
├── home
├── root
├── tmp
├── usr
└── var
```

  디렉터리   핵심 역할
  ---------- ------------------------------------
  `/`        최상위 Root 디렉터리
  `/bin`     기본 사용자 명령어
  `/boot`    부팅 관련 파일
  `/dev`     장치 파일
  `/etc`     시스템 설정 파일
  `/home`    일반 사용자 홈
  `/root`    root 사용자의 홈
  `/tmp`     임시 파일
  `/usr`     프로그램·라이브러리·공유 데이터 등
  `/var`     로그 등 자주 변경되는 데이터

### 우선 외울 5개

``` text
/etc   → 설정
/home  → 사용자 홈
/dev   → 장치
/var   → 로그 등 변동 데이터
/usr   → 프로그램/라이브러리 계열
```

------------------------------------------------------------------------

## 4. 압축과 아카이브의 차이 ⭐

### 압축 (Compression)

파일의 **용량을 줄이는 것**.

대표 명령:

``` text
gzip
bzip2
zip
```

### 아카이브 (Archive)

여러 파일/디렉터리를 **하나의 파일로 묶는 것**.

대표 명령:

``` text
tar
```

> **`tar`의 기본 역할은 압축이 아니라 여러 파일을 하나로 묶는
> 아카이브이다.**

`tar`에 gzip 또는 bzip2를 결합하면 **묶기 + 압축**을 한 번에 할 수 있다.

------------------------------------------------------------------------

## 5. gzip

압축:

``` bash
gzip file.txt
```

결과:

``` text
file.txt.gz
```

해제:

``` bash
gunzip file.txt.gz
```

또는:

``` bash
gzip -d file.txt.gz
```

**암기:** `gzip → .gz`, `gunzip → 해제`

------------------------------------------------------------------------

## 6. bzip2

압축:

``` bash
bzip2 file.txt
```

결과:

``` text
file.txt.bz2
```

해제:

``` bash
bunzip2 file.txt.bz2
```

또는:

``` bash
bzip2 -d file.txt.bz2
```

**암기:** `bzip2 → .bz2`, `bunzip2 → 해제`

------------------------------------------------------------------------

## 7. tar ⭐⭐⭐

여러 파일/디렉터리를 하나의 아카이브로 묶는다.

  옵션   의미      암기
  ------ --------- ----------------
  `c`    Create    만들기
  `x`    eXtract   풀기
  `t`    lisT      내용 확인
  `v`    Verbose   처리 과정 표시
  `f`    File      파일명 지정
  `z`    gzip      gzip 사용
  `j`    bzip2     bzip2 사용

### 핵심 암기

``` text
c → 만들기
x → 풀기
t → 목록 보기
v → 과정 보기
f → 파일 지정
z → gzip
j → bzip2
```

### tar로 묶기

``` bash
tar -cvf backup.tar test/
```

-   `c`: 생성
-   `v`: 과정 출력
-   `f`: 파일명 지정
-   `backup.tar`: 결과물
-   `test/`: 묶을 대상

### tar 풀기

``` bash
tar -xvf backup.tar
```

**핵심:** `묶을 때 c`, `풀 때 x`

### tar 내부 목록 확인

``` bash
tar -tvf backup.tar
```

실제로 풀지 않고 내부 파일 목록을 확인한다.

------------------------------------------------------------------------

## 8. tar + gzip

묶고 gzip 압축:

``` bash
tar -zcvf backup.tar.gz test/
```

풀기:

``` bash
tar -zxvf backup.tar.gz
```

``` text
z + c → gzip으로 압축하며 묶기
z + x → gzip 압축 해제 + 아카이브 풀기
```

대표 확장자:

``` text
.tar.gz
.tgz
```

------------------------------------------------------------------------

## 9. tar + bzip2

묶고 bzip2 압축:

``` bash
tar -jcvf backup.tar.bz2 test/
```

풀기:

``` bash
tar -jxvf backup.tar.bz2
```

``` text
z → gzip  → .tar.gz
j → bzip2 → .tar.bz2
```

------------------------------------------------------------------------

## 10. zip

여러 파일을 묶으면서 압축할 수 있다.

파일 압축:

``` bash
zip backup.zip file1 file2
```

디렉터리 재귀 압축:

``` bash
zip -r backup.zip test/
```

해제:

``` bash
unzip backup.zip
```

**암기:** `zip → 압축`, `unzip → 해제`

------------------------------------------------------------------------

## 11. 압축/아카이브 비교표

  명령어          주요 목적        확장자       해제
  --------------- ---------------- ------------ -------------
  `gzip`          파일 압축        `.gz`        `gunzip`
  `bzip2`         파일 압축        `.bz2`       `bunzip2`
  `tar`           여러 파일 묶기   `.tar`       `tar -xvf`
  `tar + gzip`    묶기 + 압축      `.tar.gz`    `tar -zxvf`
  `tar + bzip2`   묶기 + 압축      `.tar.bz2`   `tar -jxvf`
  `zip`           묶기 + 압축      `.zip`       `unzip`

------------------------------------------------------------------------

## 12. 시험/실습용 초압축 암기표 🔥

``` bash
# 하드 링크
ln 원본 링크

# 심볼릭 링크
ln -s 원본 링크

# gzip
gzip file
gunzip file.gz

# bzip2
bzip2 file
bunzip2 file.bz2

# tar 묶기
tar -cvf backup.tar dir/

# tar 풀기
tar -xvf backup.tar

# tar 목록 확인
tar -tvf backup.tar

# tar + gzip 압축
tar -zcvf backup.tar.gz dir/

# tar + gzip 해제
tar -zxvf backup.tar.gz

# tar + bzip2 압축
tar -jcvf backup.tar.bz2 dir/

# tar + bzip2 해제
tar -jxvf backup.tar.bz2

# zip 디렉터리 압축
zip -r backup.zip dir/

# zip 해제
unzip backup.zip
```

------------------------------------------------------------------------

## 13. tar 옵션은 문자열째 외우지 말기

``` text
c = Create
x = eXtract
t = lisT
v = Verbose
f = File
z = gZip
j = bzip2
```

예:

``` bash
tar -zcvf backup.tar.gz test/
```

를 보면:

``` text
z → gzip
c → 생성
v → 과정 표시
f → 파일 지정
```

반대로:

``` bash
tar -zxvf backup.tar.gz
```

는:

``` text
z → gzip
x → 해제
v → 과정 표시
f → 파일 지정
```

가장 중요한 차이는:

``` text
c ↔ x
Create ↔ eXtract
만들기 ↔ 풀기
```

------------------------------------------------------------------------

## 14. 전체 구조 한눈에 보기

``` text
Linux 파일 시스템
│
├─ 파일 종류
│  ├─ 일반 파일 (-)
│  ├─ 디렉터리 (d)
│  ├─ 링크 (l)
│  └─ 장치 파일 (b / c)
│
├─ 링크
│  ├─ Hard Link → ln
│  └─ Symbolic Link → ln -s
│
├─ 디렉터리
│  ├─ /etc
│  ├─ /home
│  ├─ /dev
│  ├─ /usr
│  └─ /var
│
└─ 압축/아카이브
   ├─ gzip  → .gz
   ├─ bzip2 → .bz2
   ├─ tar   → .tar
   ├─ tar + gzip  → .tar.gz
   ├─ tar + bzip2 → .tar.bz2
   └─ zip   → .zip
```

------------------------------------------------------------------------

## 15. 최종 핵심 ⭐

``` text
[링크]
Hard Link     → 같은 inode
Symbolic Link → 원본 경로를 가리킴

[디렉터리]
/etc  → 설정
/home → 사용자 홈
/dev  → 장치
/var  → 로그 등 변경 데이터
/usr  → 프로그램/라이브러리 계열

[압축]
gzip  → .gz
bzip2 → .bz2
zip   → .zip

[tar]
tar = 기본적으로 아카이브(묶기)
c = 만들기
x = 풀기
t = 목록
z = gzip
j = bzip2
```

> 🐧 **한 줄 요약:** Linux에서는 파일의 종류와 위치를 이해하고, 링크로
> 파일을 연결하며, `tar`로 여러 파일을 묶고 `gzip`·`bzip2`·`zip` 등을
> 이용해 압축한다.

``` text
❌ "tar는 그냥 압축 명령어다."

⭕ "tar는 기본적으로 아카이브 명령이며,
   gzip/bzip2와 결합해 압축까지 수행할 수 있다."
```
