# Git Troubleshooting - `cannot lock ref` & `Failed to authenticate`

## 📌 문제 발생

회사에서 작업한 내용을 집 컴퓨터에서 이어서 작업하기 위해 `git pull`을 수행하였다.

```bash
git pull
```

다음과 같은 오류가 발생하였다.

```text
error: cannot lock ref 'refs/remotes/origin/main':
is at efed33f2c608cc02fec609afb979ac14d15b9ae3
but expected 2873ce7af9fc834f94c2e44bca1d0bd6b4340641

From https://github.com/YGJ1203/Cloud-IaC-Study
! 2873ce7..efed33f main -> origin/main (unable to update local ref)
```

---

## 🤔 원인 분석

`origin/main`은 GitHub의 브랜치가 아니라 **로컬에 저장된 원격 추적 브랜치(Remote Tracking Branch)** 이다.

Git은 Pull을 수행하면서 `origin/main`을 최신 커밋으로 갱신하는데,

로컬에 저장된 참조(ref) 정보와 Git이 예상한 커밋 정보가 일치하지 않아 안전을 위해 업데이트를 중단하였다.

즉,

* Git이 예상한 커밋 : `2873ce7`
* 실제 로컬 ref가 가리키는 커밋 : `efed33f`

두 정보가 달라 충돌이 발생한 것이다.

---

## 🔧 해결 과정

### 1. 현재 상태 확인

```bash
git status
```

---

### 2. 꼬인 원격 추적 브랜치(ref) 삭제

```bash
git update-ref -d refs/remotes/origin/main
```

---

### 3. 원격 저장소 정보 다시 가져오기

```bash
git fetch origin
```

---

### 4. 최신 내용 가져오기

```bash
git pull origin main
```

정상적으로 Pull이 완료되었다.

---

# 😱 그런데 또 다른 문제 발생...

VS Code에서 **Sync Changes** 버튼을 누르자 이번에는

```text
Failed to authenticate
```

오류가 발생하였다.

순간...

> "아니 이번엔 또 뭐야...? 💀"

라는 생각이 들었다.

---

## 🔍 원인 분석

먼저 원격 저장소 연결 상태를 확인하였다.

```bash
git remote -v
```

결과

```text
origin https://github.com/YGJ1203/Cloud-IaC-Study.git (fetch)
origin https://github.com/YGJ1203/Cloud-IaC-Study.git (push)
```

원격 저장소 주소는 정상이었다.

즉,

* 저장소 문제 ❌
* 브랜치 문제 ❌
* 원격 주소 문제 ❌

인증(Authentication) 문제일 가능성이 높았다.

---

## 🔧 해결

직접 Push를 수행하였다.

```bash
git push
```

그러자 다음과 같은 메시지가 출력되었다.

```text
info: please complete authentication in your browser...
```

브라우저가 자동으로 열리면서 GitHub 로그인 및 인증을 진행하였다.

인증 완료 후

```text
Writing objects: 100%
To https://github.com/YGJ1203/Cloud-IaC-Study.git
efed33f..cfc9d92 main -> main
```

메시지가 출력되며 Push가 정상적으로 완료되었다.

---

# 💡 원인

VS Code의 **Sync Changes**는 Push/Pull을 수행하기 전에 GitHub 인증이 필요한데,

브라우저 인증이 완료되기 전에 일시적으로

```text
Failed to authenticate
```

메시지를 표시한 것이다.

브라우저 인증을 완료한 뒤에는 정상적으로 Push가 가능했다.

---

# 📝 이번 트러블슈팅에서 배운 점

* `origin/main`은 GitHub 브랜치가 아니라 로컬의 원격 추적 브랜치이다.
* `cannot lock ref` 오류는 대부분 원격 추적 브랜치(ref) 정보가 꼬였을 때 발생한다.
* `git update-ref -d`로 ref를 삭제한 뒤 `fetch`하면 최신 정보가 다시 생성된다.
* `git remote -v`로 원격 저장소 연결 상태를 확인할 수 있다.
* `Failed to authenticate`는 저장소 문제가 아니라 GitHub 인증 문제인 경우가 많다.
* 브라우저 인증을 완료하면 대부분 정상적으로 Push/Pull이 가능하다.

---

# 🎯 회고

오늘은 단순히 오류를 해결한 것이 아니라,

Git이 **원격 추적 브랜치(Remote Tracking Branch)** 와 **인증(Authentication)** 을 어떻게 관리하는지 이해할 수 있었다.

앞으로 비슷한 오류가 발생하면

* "ref 문제인가?"
* "인증 문제인가?"

를 먼저 구분하여 빠르게 원인을 파악할 수 있을 것이다.

---

## 😎 오늘의 한 줄

> "Git은 나를 괴롭히는 것이 아니라, 잘못된 상태에서 데이터를 안전하게 지켜주고 있었다."

(물론 그걸 깨닫기 전까지는 Git이 빌런처럼 느껴졌다... 🤡💀)
