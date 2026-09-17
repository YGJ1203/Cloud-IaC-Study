# Kubernetes Label & Annotation 핵심 정리

## 1. Label 🏷️

Kubernetes Object에 붙이는 **`key=value` 형태의 이름표**이다.

``` yaml
metadata:
  labels:
    name: web
    rel: release
    tier: frontend
```

### Label 확인 / 검색

``` bash
kubectl get pods --show-labels
kubectl get pods -l name=web
kubectl get pods -l tier=backend
kubectl get pods -l 'tier in (cache,backend)'
kubectl get pods -l 'rel!=release'
```

> **Label = 이름표 / Selector = 이름표를 이용한 선택**

------------------------------------------------------------------------

## 2. Node Label 🖥️

Label을 Node에 붙이면 **Node Label**이다.

``` bash
kubectl label nodes node1 disk=ssd
kubectl label nodes node2 gpu=true
kubectl label nodes node3 mem=high

kubectl get nodes -L disk,gpu,mem
```

### nodeSelector

특정 Label을 가진 Node에 Pod를 배치할 때 사용한다.

``` yaml
spec:
  nodeSelector:
    disk: ssd
```

``` text
node1 [disk=ssd]
        ↑
        │ nodeSelector
       Pod
```

Node Label 삭제:

``` bash
kubectl label nodes node1 disk-
kubectl label nodes node2 gpu-
kubectl label nodes node3 mem-
```

------------------------------------------------------------------------

## 3. Annotation 📝

Object에 **설명이나 부가정보를 기록**하는 메타데이터이다.

``` yaml
metadata:
  annotations:
    buildDate: "2023-01-03"
    containerVersion: "nginx:1.14"
```

확인:

``` bash
kubectl describe pod pod21
```

### Label vs Annotation

  구분       Label       Annotation
  ---------- ----------- -----------------------------------
  핵심       이름표      메모/부가정보
  용도       분류·선택   정보 기록
  Selector   가능        일반적인 Label Selector 용도 아님

------------------------------------------------------------------------

## ⭐ 오늘의 핵심

``` text
Label
 ├─ Pod Label  → Pod 분류/선택
 └─ Node Label → Node 분류
                    ↓
               nodeSelector
                    ↓
              Pod 배치 제어

Annotation → Object의 부가정보 기록
```

> **Label = 이름표, Selector = 이름표로 찾기, nodeSelector = Node
> 이름표로 배치하기, Annotation = 메모**
