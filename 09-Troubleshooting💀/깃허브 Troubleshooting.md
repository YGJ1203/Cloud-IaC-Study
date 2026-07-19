# Git Pull 시 cannot lock ref 오류 해결

## 문제

git pull 실행 시

error: cannot lock ref 'refs/remotes/origin/main'

오류가 발생하며 Pull이 진행되지 않았다.

## 원인

로컬의 원격 추적 브랜치(origin/main) 참조 정보와
Git이 기대하는 커밋 정보가 일치하지 않아
원격 브랜치를 업데이트하지 못한 상태였다.

## 해결

1. 원격 추적 브랜치 참조 삭제

git update-ref -d refs/remotes/origin/main

2. 원격 저장소 정보 다시 가져오기

git fetch origin

3. Pull 수행

git pull origin main

## 결과

정상적으로 최신 커밋을 받아와 Pull 완료.

## 배운 점

- origin/main은 원격 저장소 자체가 아니라 로컬에 저장된 원격 추적 브랜치이다.
- Git은 ref 정보가 일치하지 않으면 안전을 위해 업데이트를 중단한다.
- ref를 삭제하고 fetch하면 Git이 최신 정보를 다시 생성한다.