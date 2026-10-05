# Cloud-IaC-Study 전체 복습 목차

> **목표:** 문서 제목을 보고 설명한 뒤, 막힌 부분의 원문을 바로 찾아 복습한다.  
> **확인 기준:** 2026-10-05 · [YGJ1203/Cloud-IaC-Study](https://github.com/YGJ1203/Cloud-IaC-Study) · `main`의 [`a08f001`](https://github.com/YGJ1203/Cloud-IaC-Study/commit/a08f001c9760e576841e406c58413da302187b65)  
> **범위:** 위 커밋에 존재하는 Markdown 파일 **113개**의 목록과 대표 문서 본문. 개수에는 README와 중복 파일이 포함된다.

## 1. 오늘은 여기부터 — 30분 복습

아래 시간을 타이머로 정하고, **질문에 먼저 답한 뒤 지정한 부분만 확인**한다. 긴 문서를 처음부터 끝까지 읽을 필요는 없다.

| 시간 | 열 문서 | 읽을 부분 | 먼저 말해 볼 질문 |
|---|---|---|---|
| 5분 | [Network 기초 요약](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/%EC%B7%A8%EC%95%BD%EC%A0%90%20%EB%B3%B4%EC%B6%A9/Summary%28Day01%20-%2008%29.md) | ARP · Gateway · Routing | 다른 네트워크로 보낼 때 누구의 MAC 주소를 찾는가? |
| 5분 | [Linux 서비스 압축본](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/9%EC%A3%BC%EC%B0%A8/9%EC%A3%BC%EC%B0%A8%20%EC%B4%88%EA%B0%84%EB%8B%A8%20%EC%A0%95%EB%A6%AC.md) | 2장 웹 구조 · 8장 장애 점검 | 웹 서비스가 실행 중인데 접속이 안 되면 무엇을 확인하는가? |
| 4분 | [Docker 주간 정리](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/04-Docker/11%EC%A3%BC%EC%B0%A8/11%EC%A3%BC%EC%B0%A8%20%EC%A0%95%EB%A6%AC.md) | 7장 포트 · 9장 볼륨 | `8080:80`의 두 숫자는 각각 어디의 포트인가? |
| 5분 | [Kubernetes 주간 정리](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/05-Kubernetes/12%EC%A3%BC%EC%B0%A8/12%EC%A3%BC%EC%B0%A8%20%EC%A0%95%EB%A6%AC.md) | 7~11장 Deployment · Label · Service | Pod가 재생성되어도 접근점을 유지하려면 어떤 자원이 필요한가? |
| 7분 | [프로젝트 최종 구성](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/10-Projects%F0%9F%93%96/Docker%20%26%20K8s%20%EA%B8%B0%EB%B0%98%20%ED%94%84%EB%9D%BC%EC%9D%B4%EB%B9%97%20%ED%81%B4%EB%9D%BC%EC%9A%B0%EB%93%9C%20%ED%99%98%EA%B2%BD%20%EA%B5%AC%EC%B6%95%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/09-29%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8.md) + [NFS 장애 사례](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/10-Projects%F0%9F%93%96/Docker%20%26%20K8s%20%EA%B8%B0%EB%B0%98%20%ED%94%84%EB%9D%BC%EC%9D%B4%EB%B9%97%20%ED%81%B4%EB%9D%BC%EC%9A%B0%EB%93%9C%20%ED%99%98%EA%B2%BD%20%EA%B5%AC%EC%B6%95%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/09-28%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8.md) | 9/29의 3·5·6·7장, 9/28의 10장 | NFS 경로 변경이 PV/PVC와 Pod에 어떻게 이어졌는가? |
| 4분 | [AWS 실습 치트시트](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/03-AWS/13%EC%A3%BC%EC%B0%A8/AWS%20%ED%9D%90%EB%A6%84.md) | 2·4·16~18장 | VPC 콘솔 구축 순서를 CloudFormation 자원으로 바꿔 설명할 수 있는가? |

**5분만 가능한 날:** 질문 하나를 1분 설명하고, 원문을 3분 확인한 뒤, 마지막 1분에 다시 설명한다.

## 2. 실제 저장소 지도

폴더 번호와 복습 순서는 다르다. 학습 연결을 위해 **Network → Linux → Docker → Kubernetes → 프로젝트 → AWS/IaC** 순서로 본다.

| 실제 폴더 | MD 수 | 복습에 사용할 내용 |
|---|---:|---|
| `01-Network` | 32 | Day01~23, 주소·라우팅·VLAN·HSRP, 보충 핸드북 |
| `02-Linux` | 25 | Day24~38, 7~9주차 요약, 서비스·스토리지·방화벽 |
| `04-Docker` | 8 | Day39~43, 11주차 정리, 컨테이너·이미지·Compose |
| `05-Kubernetes` | 9 | Day44~48, 12주차 정리와 Q&A |
| `10-Projects📖` | 17 | 네트워크 연습, Linux 이관, Docker/K8s 프로젝트 |
| `03-AWS` | 7 | Day49~51, 13주차 정리·Q&A·치트시트 |
| `09-Troubleshooting💀` | 11 | 네트워크·Linux·Git 장애 및 보충 기록 |
| `06-Ansible` | 1 | 현재 소개용 README만 있음 — 후속 학습 칸 |
| `07-Terraform` | 1 | 현재 소개용 README만 있음 — 후속 학습 칸 |
| `08-Security` | 1 | 현재 소개용 README만 있음 — 후속 학습 칸 |
| 루트 `README.md` | 1 | 전체 학습 목록 |
| **합계** | **113** | **README 10개 포함** |

파일 개수는 커밋 횟수와 다르다. 기존 요약을 복습의 출발점으로 사용하고, 필요한 Day 문서로 내려간다.

## 3. 분야별 복습 경로

### 01. Network — 패킷이 도착하는 이유

**입구:** [기초 요약](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/%EC%B7%A8%EC%95%BD%EC%A0%90%20%EB%B3%B4%EC%B6%A9/Summary%28Day01%20-%2008%29.md)  
**찾아보는 책:** [Network Handbook](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/%EC%B7%A8%EC%95%BD%EC%A0%90%20%EB%B3%B4%EC%B6%A9/%EB%84%A4%ED%8A%B8%EC%9B%8C%ED%81%AC%20%ED%95%99%EC%8A%B5%20%EB%B6%80%EB%B6%84%20%EC%A0%95%EB%A6%AC%EB%B3%B8.md) — 목차에서 필요한 장만 선택한다.

| 확인할 주제 | 막히면 열 문서 | 통과 질문 |
|---|---|---|
| IP·MAC·ARP·CIDR | [Day02](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/1%EC%A3%BC%EC%B0%A8/Day02.md) · [Day04](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/2%EC%A3%BC%EC%B0%A8/Day04.md) | 목적지 IP와 다음 홉 MAC을 구분하고, 서브넷 범위를 계산할 수 있는가? |
| Static·RIP·EIGRP·OSPF | [라우팅 복습](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/4%EC%A3%BC%EC%B0%A8/Day15%20%28%EB%B3%B5%EC%8A%B5%29.md) · [EIGRP 보충](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/%EC%B7%A8%EC%95%BD%EC%A0%90%20%EB%B3%B4%EC%B6%A9/EIGRP%20%EA%B0%9C%EB%85%90.md) | 경로 선택 기준과 왕복 경로를 설명할 수 있는가? |
| VLAN·Trunk·STP | [Router-on-a-Stick](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/5%EC%A3%BC%EC%B0%A8/Day18%20%EC%98%88%EC%A0%9C.md) · [STP 실습](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/5%EC%A3%BC%EC%B0%A8/Day20.md) | 서로 다른 VLAN의 통신과 L2 루프 방지를 구분하는가? |
| ACL·NAT·HSRP·통합 구성 | [ACL](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/3%EC%A3%BC%EC%B0%A8/Day11.md) · [KAIST 내부망 구성](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/6%EC%A3%BC%EC%B0%A8/Day23.md) · [HSRP 장애 비교](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/09-Troubleshooting%F0%9F%92%80/01-Network/TroubleShooting5.md) | 정책·주소 변환·게이트웨이 이중화가 각각 무엇을 해결하는가? |

**명령 회상:** `show ip interface brief`, `show ip route`, `show vlan brief`, `show interfaces trunk`, `show standby brief`가 각각 어떤 가설을 확인하는지 말한다.

### 02. Linux — 서버를 운영하는 순서

**입구:** [7주차 기초](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/7%EC%A3%BC%EC%B0%A8/7%EC%A3%BC%EC%B0%A8%20%EC%A0%95%EB%A6%AC%EB%B3%B8.md) → [8주차 스토리지·운영](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/8%EC%A3%BC%EC%B0%A8/8%EC%A3%BC%EC%B0%A8%20%EC%A0%95%EB%A6%AC.md) → [9주차 서비스 압축본](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/9%EC%A3%BC%EC%B0%A8/9%EC%A3%BC%EC%B0%A8%20%EC%B4%88%EA%B0%84%EB%8B%A8%20%EC%A0%95%EB%A6%AC.md)

| 확인할 주제 | 막히면 열 문서 | 통과 질문 |
|---|---|---|
| 경로·권한·Shell·Process | [기초 보충](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/%EC%B7%A8%EC%95%BD%EC%A0%90%20%EB%B3%B4%EC%B6%A9/%EB%A6%AC%EB%88%85%EC%8A%A4%20%EB%B3%B5%EC%8A%B5.md) | 파일과 디렉터리의 `x` 권한은 어떻게 다른가? |
| Disk·RAID·LVM·Mount | [Day29](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/8%EC%A3%BC%EC%B0%A8/Day29.md) · [종합 인프라 복습](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/10%EC%A3%BC%EC%B0%A8/Day38.md) | 장치·파일시스템·마운트 지점을 구분하고, 영구 마운트를 설명하는가? |
| NFS·Web·DNS·Mail | [9주차 상세 정리](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/9%EC%A3%BC%EC%B0%A8/9%EC%A3%BC%EC%B0%A8%20%EC%A0%95%EB%A6%AC.md) | 서비스 역할, 설정 파일, 포트, 확인 방법을 연결할 수 있는가? |
| iptables·firewalld | [iptables](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/9%EC%A3%BC%EC%B0%A8/Day36.md) · [firewalld](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/9%EC%A3%BC%EC%B0%A8/Day37%20%281%29.md) | 서비스 실행 상태와 방화벽 허용을 구분하고, Runtime/Permanent 차이를 아는가? |

**명령 회상:** `systemctl status`, `journalctl -u`, `ss -lntup`, `ip route`, `findmnt`, `df -hT`.  
**말하기 연습:** [Linux Q&A](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/8%EC%A3%BC%EC%B0%A8/8%EC%A3%BC%EC%B0%A8%20Q%26A.md)에서 Storage·Service 질문을 골라 답한다.

### 03. Docker — 실행 환경을 묶고 재현하기

**입구:** [Docker 주간 정리](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/04-Docker/11%EC%A3%BC%EC%B0%A8/11%EC%A3%BC%EC%B0%A8%20%EC%A0%95%EB%A6%AC.md)

| 확인할 주제 | 막히면 열 문서 | 통과 질문 |
|---|---|---|
| Image·Container·PID 1 | [Day39](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/04-Docker/11%EC%A3%BC%EC%B0%A8/Day39.md) · [Day40](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/04-Docker/11%EC%A3%BC%EC%B0%A8/Day40.md) | 이미지와 실행 중인 프로세스를 구분하고, 컨테이너 종료 이유를 설명하는가? |
| Network·Port·Volume | [Day41](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/04-Docker/11%EC%A3%BC%EC%B0%A8/Day41.md) | 포트 공개와 데이터 보존을 각각 어떻게 구성했는가? |
| 자원 제한·Build | [Day42](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/04-Docker/11%EC%A3%BC%EC%B0%A8/Day42.md) | 자원 제한의 수치·단위와 빌드 컨텍스트를 확인할 수 있는가? |
| Dockerfile·Compose·Registry | [Day43](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/04-Docker/11%EC%A3%BC%EC%B0%A8/Day43.md) | 이미지 제작, 여러 서비스 실행, 이미지 배포의 역할을 구분하는가? |

**명령 회상:** `docker ps -a`, `docker logs`, `docker inspect`, `docker stats`, `docker compose config`.  
**꼭 답할 질문:** “컨테이너는 실행 중이고 `80/tcp`도 보이는데, 호스트의 `localhost:8080`으로 접속되지 않는 이유는?”

### 04. Kubernetes — 자원 사이의 연결

**입구:** [Kubernetes 주간 정리](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/05-Kubernetes/12%EC%A3%BC%EC%B0%A8/12%EC%A3%BC%EC%B0%A8%20%EC%A0%95%EB%A6%AC.md)  
**말하기 연습:** [복습용 Q&A](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/05-Kubernetes/12%EC%A3%BC%EC%B0%A8/%EB%B3%B5%EC%8A%B5%EC%9A%A9%20Q%26A.md)

| 확인할 주제 | 막히면 열 문서 | 통과 질문 |
|---|---|---|
| Cluster·Node·Pod | [Swarm·K8s 도입](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/05-Kubernetes/12%EC%A3%BC%EC%B0%A8/Day44.md) · [Pod 실습](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/05-Kubernetes/12%EC%A3%BC%EC%B0%A8/Day45.md) | 노드 문제와 Pod 문제를 어떤 상태·이벤트로 구분하는가? |
| Deployment·ReplicaSet·Service | [Controller·Service](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/05-Kubernetes/12%EC%A3%BC%EC%B0%A8/Day46.md) | Pod 개수 유지와 트래픽 전달은 각각 누가 담당하는가? |
| Label·Selector·Namespace | [Label·Annotation](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/05-Kubernetes/12%EC%A3%BC%EC%B0%A8/Day47.md) | Service가 어떤 Pod를 선택하는지 확인할 수 있는가? |
| 설정·자원·저장소 | [ConfigMap·Secret·Storage](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/05-Kubernetes/12%EC%A3%BC%EC%B0%A8/Day48.md) · [requests·limits·Probe](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/05-Kubernetes/12%EC%A3%BC%EC%B0%A8/Day45.md) | 설정 분리, 재시작 판단, 요청 수신 준비, 저장소 연결을 구분하는가? |

**명령 회상:** `kubectl get`, `describe`, `logs`를 상태 → 이벤트/설정 → 로그의 목적으로 사용한다.  
**꼭 답할 질문:** “Pod가 `Running`인데도 Service로 접속되지 않으면 무엇을 비교할 것인가?”

### 05. 프로젝트 — 최종 결과부터 역순으로 보기

프로젝트 문서는 날짜에 따라 설계가 바뀐다. **마지막 결과 → 장애와 수정 → 초기 설계** 순서로 읽으면 중간 상태를 최종 구성으로 외우는 일을 줄일 수 있다.

| 프로젝트 | 먼저 열 문서 | 이어서 볼 문서 | 설명 목표 |
|---|---|---|---|
| 네트워크 구성 | [KAIST 내부망 구성](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/6%EC%A3%BC%EC%B0%A8/Day23.md) | [VLAN·PortFast 회고](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/10-Projects%F0%9F%93%96/%EC%97%B0%EC%8A%B5%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/%EC%97%B0%EC%8A%B5%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B81.md) · [HSRP 장애 검증](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/09-Troubleshooting%F0%9F%92%80/01-Network/TroubleShooting5.md) | 네트워크 분리, 라우팅, 이중화를 연결한다. |
| Linux 이관 | [9/4 Web 최종 기록](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/10-Projects%F0%9F%93%96/%EB%A6%AC%EB%88%85%EC%8A%A4%20%EC%9D%B4%EA%B4%80%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/0904%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8.md) | [Web·DNS](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/10-Projects%F0%9F%93%96/%EB%A6%AC%EB%88%85%EC%8A%A4%20%EC%9D%B4%EA%B4%80%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/0902%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8.md) · [이관 장애 기록](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/10-Projects%F0%9F%93%96/%EB%A6%AC%EB%88%85%EC%8A%A4%20%EC%9D%B4%EA%B4%80%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/%EC%9D%B4%EA%B4%80%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8%20TroubleShooting.md) | DNS 조회부터 웹 응답까지 장애 지점을 나눈다. |
| Docker/K8s | [9/29 최종 변경](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/10-Projects%F0%9F%93%96/Docker%20%26%20K8s%20%EA%B8%B0%EB%B0%98%20%ED%94%84%EB%9D%BC%EC%9D%B4%EB%B9%97%20%ED%81%B4%EB%9D%BC%EC%9A%B0%EB%93%9C%20%ED%99%98%EA%B2%BD%20%EA%B5%AC%EC%B6%95%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/09-29%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8.md) | [9/28 LVM·NFS](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/10-Projects%F0%9F%93%96/Docker%20%26%20K8s%20%EA%B8%B0%EB%B0%98%20%ED%94%84%EB%9D%BC%EC%9D%B4%EB%B9%97%20%ED%81%B4%EB%9D%BC%EC%9A%B0%EB%93%9C%20%ED%99%98%EA%B2%BD%20%EA%B5%AC%EC%B6%95%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/09-28%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8.md) → [초기 구성과 개념 보강](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/10-Projects%F0%9F%93%96/Docker%20%26%20K8s%20%EA%B8%B0%EB%B0%98%20%ED%94%84%EB%9D%BC%EC%9D%B4%EB%B9%97%20%ED%81%B4%EB%9D%BC%EC%9A%B0%EB%93%9C%20%ED%99%98%EA%B2%BD%20%EA%B5%AC%EC%B6%95%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/09-21~23%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8%20%EC%A0%95%EB%A6%AC.md) | 요청 경로와 저장소 연결을 따로 설명한다. |

**9/29 기록 기준으로 기억할 값**

| 서비스 | Namespace | NFS 경로 | PV / PVC | NodePort |
|---|---|---|---|---:|
| WEB(AI) | `kaist-ai` | `/www/vol/web` | `kaist-web-pv` / `kaist-web-pvc` | 30001 |
| SYS | `kaist-sys` | `/www/vol/sys` | `kaist-sys-pv` / `kaist-sys-pvc` | 30002 |
| COM | `kaist-com` | `/www/vol/com` | `kaist-com-pv` / `kaist-com-pvc` | 30003 |
| FT | `kaist-ft` | `/www/vol/ft` | `kaist-ft-pv` / `kaist-ft-pvc` | 30004 |

출처: [9/28 구성표](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/10-Projects%F0%9F%93%96/Docker%20%26%20K8s%20%EA%B8%B0%EB%B0%98%20%ED%94%84%EB%9D%BC%EC%9D%B4%EB%B9%97%20%ED%81%B4%EB%9D%BC%EC%9A%B0%EB%93%9C%20%ED%99%98%EA%B2%BD%20%EA%B5%AC%EC%B6%95%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/09-28%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8.md)와 [9/29 변경·검증 기록](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/10-Projects%F0%9F%93%96/Docker%20%26%20K8s%20%EA%B8%B0%EB%B0%98%20%ED%94%84%EB%9D%BC%EC%9D%B4%EB%B9%97%20%ED%81%B4%EB%9D%BC%EC%9A%B0%EB%93%9C%20%ED%99%98%EA%B2%BD%20%EA%B5%AC%EC%B6%95%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/09-29%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8.md). **당시 기록된 구성과 성공 결과**를 복습하는 표다.

- WEB의 이전 경로 `/www/vol/ai`는 9/29에 `/www/vol/web`으로 변경되었다.
- Namespace와 Deployment는 `kaist-ai`, `kaist-ai-deploy`를 유지하고, PVC 참조를 `kaist-web-pvc`로 바꿨다.
- 9/22의 PV/PVC 생략 판단, 9/23의 NFS 도입, 9/28의 LVM 구성, 9/29의 WEB 경로 변경을 **설계의 변화**로 읽는다.
- 9/21~23 통합본의 COM·FT “예정” 표시는 그 문서의 기준 시점이다. 9/28~29에는 네 NodePort의 응답 성공이 기록되어 있다.

**내 말로 그릴 세 가지 관계**

| 관계 | 복습할 연결 |
|---|---|
| Pod 관리 | Deployment → ReplicaSet → Pod |
| 웹 요청 | 클라이언트 → NodePort Service → Pod의 Nginx |
| 파일 사용 | Pod의 마운트 → PVC → PV → NFS 공유 경로 |

이 표에서 Deployment는 웹 요청의 중간 장비가 아니다. PV/PVC도 별도의 파일 서버가 아니라 저장소 연결을 표현하는 자원이다. 이 구분은 [프로젝트 보강 문서 2장](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/10-Projects%F0%9F%93%96/Docker%20%26%20K8s%20%EA%B8%B0%EB%B0%98%20%ED%94%84%EB%9D%BC%EC%9D%B4%EB%B9%97%20%ED%81%B4%EB%9D%BC%EC%9A%B0%EB%93%9C%20%ED%99%98%EA%B2%BD%20%EA%B5%AC%EC%B6%95%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/09-21~23%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8%20%EC%A0%95%EB%A6%AC.md)에서 확인한다.

**발표 연습:** [PPT 가이드](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/10-Projects%F0%9F%93%96/Docker%20%26%20K8s%20%EA%B8%B0%EB%B0%98%20%ED%94%84%EB%9D%BC%EC%9D%B4%EB%B9%97%20%ED%81%B4%EB%9D%BC%EC%9A%B0%EB%93%9C%20%ED%99%98%EA%B2%BD%20%EA%B5%AC%EC%B6%95%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/PPT%20%EC%9E%91%EC%84%B1%20%EA%B0%80%EC%9D%B4%EB%93%9C.md)를 보며 “목적 → 담당 작업 → 장애 → 확인 근거 → 개선점”을 3분 안에 설명한다.

### 06. AWS / IaC — 기존 지식을 AWS 자원에 연결하기

**입구:** [치트시트](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/03-AWS/13%EC%A3%BC%EC%B0%A8/AWS%20%ED%9D%90%EB%A6%84.md) → [주간 정리](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/03-AWS/13%EC%A3%BC%EC%B0%A8/13%EC%A3%BC%EC%B0%A8%20%EC%A0%95%EB%A6%AC.md)  
**말하기 연습:** [AWS Q&A](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/03-AWS/13%EC%A3%BC%EC%B0%A8/13%EC%A3%BC%EC%B0%A8%20Q%26A.md)

| 확인할 주제 | 막히면 열 문서 | 통과 질문 |
|---|---|---|
| IAM·VPC·EC2 | [Day49](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/03-AWS/13%EC%A3%BC%EC%B0%A8/Day49.md) | 권한, 네트워크, 가상 서버의 역할을 나눠 설명할 수 있는가? |
| S3·ALB·Auto Scaling·RDS | [Day50](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/03-AWS/13%EC%A3%BC%EC%B0%A8/Day50.md) | 저장, 요청 분산, 서버 수 조절, DB 서비스는 어떻게 다른가? |
| CloudFormation·Public/Private 구성 | [Day51](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/03-AWS/13%EC%A3%BC%EC%B0%A8/Day51.md) | 리소스의 생성과 연결을 `Resources`, `!Ref`, 의존 관계로 설명하는가? |

**꼭 답할 질문:** “인터넷과 IPv4로 직접 통신할 EC2를 만들 때, IGW 경로 외에 무엇을 확인해야 하는가?”  
**연결 질문:** “콘솔에서 만든 VPC·Subnet·Route Table을 CloudFormation으로 옮기면 어떤 자원과 연결 관계가 필요한가?”

### 07. Troubleshooting — 해결 근거까지 말하기

| 상황 | 원문 | 답변에 포함할 것 |
|---|---|---|
| Ping 실패·반환 경로 누락 | [Network 초기 장애](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/09-Troubleshooting%F0%9F%92%80/01-Network/TroubleShooting%20%28Day%2001%20~%20Day%2008%29.md) | IP·Gateway·Route 확인, 왕복 경로, 재검증 |
| NAT 이후 외부 통신 실패 | [NAT·VLAN/STP 장애](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/09-Troubleshooting%F0%9F%92%80/01-Network/TroubleShooting3.md) | 변환 대상, inside/outside, 경로를 구분 |
| 외부/내부 인터페이스 장애 시 HSRP 차이 | [HSRP 장애 비교](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/09-Troubleshooting%F0%9F%92%80/01-Network/TroubleShooting5.md) | 추적 대상과 HSRP 동작 인터페이스의 차이 |
| 내부 도메인이 외부 사이트로 해석됨 | [Web·DNS 장애](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/10-Projects%F0%9F%93%96/%EB%A6%AC%EB%88%85%EC%8A%A4%20%EC%9D%B4%EA%B4%80%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/%EC%9D%B4%EA%B4%80%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8%20TroubleShooting.md) | 클라이언트 DNS 설정, 조회 결과, 내부 Zone |
| NFS 변경 뒤 HTTP 500 | [Stale file handle 사례](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/10-Projects%F0%9F%93%96/Docker%20%26%20K8s%20%EA%B8%B0%EB%B0%98%20%ED%94%84%EB%9D%BC%EC%9D%B4%EB%B9%97%20%ED%81%B4%EB%9D%BC%EC%9A%B0%EB%93%9C%20%ED%99%98%EA%B2%BD%20%EA%B5%AC%EC%B6%95%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/09-28%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8.md) | Pod 내부·Nginx 로그에서 확인한 증거, 재마운트 후 검증 |
| Service가 Pod에 연결되지 않음 | [K8s 장애 점검](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/10-Projects%F0%9F%93%96/Docker%20%26%20K8s%20%EA%B8%B0%EB%B0%98%20%ED%94%84%EB%9D%BC%EC%9D%B4%EB%B9%97%20%ED%81%B4%EB%9D%BC%EC%9A%B0%EB%93%9C%20%ED%99%98%EA%B2%BD%20%EA%B5%AC%EC%B6%95%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8%20%ED%8A%B8%EB%9F%AC%EB%B8%94%EC%8A%88%ED%8C%85.md) | Namespace·Selector·Label·Endpoint·Readiness |
| Git 원격 추적 참조/인증 오류 | [Git 장애 기록](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/09-Troubleshooting%F0%9F%92%80/%EA%B9%83%ED%97%88%EB%B8%8C%20%EA%B4%80%EB%A0%A8/%EA%B9%83%ED%97%88%EB%B8%8C%20Troubleshooting.md) | 현재 상태 확인, 참조 문제와 인증 문제 구분 |

답변은 **증상 → 확인한 증거 → 원인 → 조치 → 재검증** 다섯 문장으로 한다. 원문에 있는 실제 경험과 추가로 제시된 일반 점검 예시를 구분한다.

## 4. 기술을 연결하는 질문

다음 표는 역할을 비교하기 위한 복습 질문이다. 서로 다른 기술이 완전히 같은 동작을 한다는 뜻은 아니다.

| 공통 문제 | 앞에서 배운 내용 | 다음 단계에서 연결할 내용 | 연결 질문 |
|---|---|---|---|
| 네트워크 분리와 경로 | Subnet·VLAN·Routing | AWS VPC·Subnet·Route Table | 무엇을 분리하고, 어떤 경로로 통신시키는가? |
| 필요한 통신 허용 | ACL·Linux 방화벽 | Security Group·NACL | 적용 위치와 상태 추적 방식은 어떻게 다른가? |
| 실행 환경 재현 | Linux 설치·설정 | Dockerfile·Image | 이미지에 담을 것과 실행 시 주입할 것은 무엇인가? |
| 서비스 수 유지와 확장 | 여러 컨테이너 실행 | Deployment·ReplicaSet / EC2 Auto Scaling | 각각 무엇의 개수를 관리하는가? |
| 실행 환경과 데이터 분리 | LVM·Mount·NFS | Docker Volume·Kubernetes PV/PVC | 실제 데이터는 어디 있고, 사용자는 어떻게 연결하는가? |
| 인프라를 코드로 표현 | 콘솔의 VPC·EC2 구성 | CloudFormation | 설정값뿐 아니라 자원 사이의 연결도 표현했는가? |

**종합 질문:** “사용자가 웹 페이지를 열었는데 실패했다. Network, Linux, Docker, Kubernetes, AWS 중 현재 환경에 해당하는 계층을 고르고, 먼저 볼 상태·로그·설정 세 가지를 말해보자.”

## 5. 회상 점수와 다음 복습 결정

- **0점:** 설명을 시작하기 어렵다 → 요약부터 읽는다.
- **1점:** 개념은 설명하지만 실습·확인 방법이 막힌다 → 해당 Day/장애 문서만 본다.
- **2점:** 개념, 실습 예, 검증 근거를 설명한다 → 다음 회차로 넘긴다.

한 번에 모든 분야를 끝내려 하지 말고, **0~1점인 항목 중 하나**를 다음 복습으로 선택한다.

| 분야 | 최근 복습일 | 점수 0/1/2 | 막힌 질문 하나 | 다음에 열 원문 |
|---|---|---|---|---|
| Network |  |  |  |  |
| Linux |  |  |  |  |
| Docker |  |  |  |  |
| Kubernetes |  |  |  |  |
| 프로젝트 |  |  |  |  |
| AWS / IaC |  |  |  |  |
| Troubleshooting |  |  |  |  |

예: `Kubernetes / 10-05 / 1 / Service가 찾는 대상은? / Day47`

## 6. 이 목차를 계속 사용하는 방법

**권장 저장 위치:** `00-Final-Review/README.md`. 모든 원문 링크는 GitHub 절대 URL이므로 이 파일을 다른 위치에 저장해도 사용할 수 있다.

1. 평일 Day 문서와 토요일 총정리, 일요일 Q&A를 계속 기록한다.
2. 새 주간 정리가 생기면 이 목차의 해당 분야에 대표 링크 한 개를 추가한다.
3. 프로젝트가 바뀌면 “최종 구성”의 날짜·경로·검증 결과부터 갱신한다.
4. 새 분야에 실제 학습 문서가 생기면 Ansible·Terraform·Security를 복습 경로에 추가한다.
5. 월간 압축본이 필요해지면, 위 점수표에서 반복해서 막힌 내용부터 정리한다.

본문의 원문 링크는 `main`의 최신 파일을 연다. 문서가 수정되면 내용도 달라질 수 있으며, 작성 당시 상태는 상단 기준 커밋에서 확인한다.

## 7. 중복 문서 — 한쪽만 복습해도 되는 네 쌍

기준 커밋에서 Git blob SHA가 같은 **동일 본문**이다. 아래 첫 번째 경로를 복습 기준으로 연결했다.

| 복습 기준 | 같은 본문의 다른 위치 |
|---|---|
| [Network/취약점 보충/EIGRP 개념](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/%EC%B7%A8%EC%95%BD%EC%A0%90%20%EB%B3%B4%EC%B6%A9/EIGRP%20%EA%B0%9C%EB%85%90.md) | [Network/EIGRP 개념](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/EIGRP%20%EA%B0%9C%EB%85%90.md) |
| [Troubleshooting/01-Network/Day01~08](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/09-Troubleshooting%F0%9F%92%80/01-Network/TroubleShooting%20%28Day%2001%20~%20Day%2008%29.md) | [Troubleshooting/Day01~08](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/09-Troubleshooting%F0%9F%92%80/TroubleShooting%20%28Day%2001%20~%20Day%2008%29.md) |
| [Troubleshooting/01-Network/Part 2](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/09-Troubleshooting%F0%9F%92%80/01-Network/TroubleShooting%202.md) | [Troubleshooting/Part 2](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/09-Troubleshooting%F0%9F%92%80/TroubleShooting%202.md) |
| [Troubleshooting/깃허브 관련/Git](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/09-Troubleshooting%F0%9F%92%80/%EA%B9%83%ED%97%88%EB%B8%8C%20%EA%B4%80%EB%A0%A8/%EA%B9%83%ED%97%88%EB%B8%8C%20Troubleshooting.md) | [Troubleshooting/Git](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/09-Troubleshooting%F0%9F%92%80/%EA%B9%83%ED%97%88%EB%B8%8C%20Troubleshooting.md) |

## 부록. 현재 MD 전체 찾아보기

이 목록은 **검색용 색인**이다. 처음 복습할 때는 1~3절의 대표 링크부터 사용한다.

분류: **일일/실습 · 요약/보충 · Q&A · 장애 기록 · 프로젝트 · 발표 가이드 · 안내**. 파일명과 문서의 목적을 기준으로 분류했으며, 한 문서가 여러 역할을 겸할 수 있다.

<details>
<summary>01-Network — 32개</summary>

- [1주차/Day01.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/1%EC%A3%BC%EC%B0%A8/Day01.md) — 일일/실습
- [1주차/Day02.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/1%EC%A3%BC%EC%B0%A8/Day02.md) — 일일/실습
- [1주차/Day03.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/1%EC%A3%BC%EC%B0%A8/Day03.md) — 일일/실습
- [2주차/Day04.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/2%EC%A3%BC%EC%B0%A8/Day04.md) — 일일/실습
- [2주차/Day04예제.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/2%EC%A3%BC%EC%B0%A8/Day04%EC%98%88%EC%A0%9C.md) — 일일/실습
- [2주차/Day05 예제(2).md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/2%EC%A3%BC%EC%B0%A8/Day05%20%EC%98%88%EC%A0%9C%282%29.md) — 일일/실습
- [2주차/Day05 예제.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/2%EC%A3%BC%EC%B0%A8/Day05%20%EC%98%88%EC%A0%9C.md) — 일일/실습
- [2주차/Day06.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/2%EC%A3%BC%EC%B0%A8/Day06.md) — 일일/실습
- [2주차/Day07.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/2%EC%A3%BC%EC%B0%A8/Day07.md) — 일일/실습
- [2주차/Day08.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/2%EC%A3%BC%EC%B0%A8/Day08.md) — 일일/실습
- [3주차/Day09.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/3%EC%A3%BC%EC%B0%A8/Day09.md) — 일일/실습
- [3주차/Day10.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/3%EC%A3%BC%EC%B0%A8/Day10.md) — 일일/실습
- [3주차/Day11.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/3%EC%A3%BC%EC%B0%A8/Day11.md) — 일일/실습
- [3주차/Day12.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/3%EC%A3%BC%EC%B0%A8/Day12.md) — 일일/실습
- [4주차/Day13.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/4%EC%A3%BC%EC%B0%A8/Day13.md) — 일일/실습
- [4주차/Day14.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/4%EC%A3%BC%EC%B0%A8/Day14.md) — 일일/실습
- [4주차/Day15 (복습).md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/4%EC%A3%BC%EC%B0%A8/Day15%20%28%EB%B3%B5%EC%8A%B5%29.md) — 요약/보충
- [4주차/Day16 (복습).md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/4%EC%A3%BC%EC%B0%A8/Day16%20%28%EB%B3%B5%EC%8A%B5%29.md) — 요약/보충
- [5주차/Day17.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/5%EC%A3%BC%EC%B0%A8/Day17.md) — 일일/실습
- [5주차/Day18 예제(2).md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/5%EC%A3%BC%EC%B0%A8/Day18%20%EC%98%88%EC%A0%9C%282%29.md) — 일일/실습
- [5주차/Day18 예제.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/5%EC%A3%BC%EC%B0%A8/Day18%20%EC%98%88%EC%A0%9C.md) — 일일/실습
- [5주차/Day19.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/5%EC%A3%BC%EC%B0%A8/Day19.md) — 일일/실습
- [5주차/Day20.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/5%EC%A3%BC%EC%B0%A8/Day20.md) — 일일/실습
- [5주차/Day21.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/5%EC%A3%BC%EC%B0%A8/Day21.md) — 일일/실습
- [6주차/Day22.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/6%EC%A3%BC%EC%B0%A8/Day22.md) — 일일/실습
- [6주차/Day23.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/6%EC%A3%BC%EC%B0%A8/Day23.md) — 일일/실습
- [EIGRP 개념.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/EIGRP%20%EA%B0%9C%EB%85%90.md) — 요약/보충 · 동일 본문 중복 있음
- [취약점 보충/EIGRP 개념.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/%EC%B7%A8%EC%95%BD%EC%A0%90%20%EB%B3%B4%EC%B6%A9/EIGRP%20%EA%B0%9C%EB%85%90.md) — 요약/보충 · 동일 본문 중복 있음
- [취약점 보충/Summary(Day01 - 08).md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/%EC%B7%A8%EC%95%BD%EC%A0%90%20%EB%B3%B4%EC%B6%A9/Summary%28Day01%20-%2008%29.md) — 요약/보충
- [취약점 보충/네트워크 학습 부분 정리본.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/%EC%B7%A8%EC%95%BD%EC%A0%90%20%EB%B3%B4%EC%B6%A9/%EB%84%A4%ED%8A%B8%EC%9B%8C%ED%81%AC%20%ED%95%99%EC%8A%B5%20%EB%B6%80%EB%B6%84%20%EC%A0%95%EB%A6%AC%EB%B3%B8.md) — 요약/보충
- [취약점 보충/와이어샤크 예제.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/%EC%B7%A8%EC%95%BD%EC%A0%90%20%EB%B3%B4%EC%B6%A9/%EC%99%80%EC%9D%B4%EC%96%B4%EC%83%A4%ED%81%AC%20%EC%98%88%EC%A0%9C.md) — 요약/보충
- [취약점 보충/포트번호.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/01-Network/%EC%B7%A8%EC%95%BD%EC%A0%90%20%EB%B3%B4%EC%B6%A9/%ED%8F%AC%ED%8A%B8%EB%B2%88%ED%98%B8.md) — 요약/보충

</details>

<details>
<summary>02-Linux — 25개</summary>

- [10주차/Day38.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/10%EC%A3%BC%EC%B0%A8/Day38.md) — 일일/실습
- [7주차/7주차 정리본.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/7%EC%A3%BC%EC%B0%A8/7%EC%A3%BC%EC%B0%A8%20%EC%A0%95%EB%A6%AC%EB%B3%B8.md) — 요약/보충
- [7주차/Day24.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/7%EC%A3%BC%EC%B0%A8/Day24.md) — 일일/실습
- [7주차/Day25.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/7%EC%A3%BC%EC%B0%A8/Day25.md) — 일일/실습
- [7주차/Day26.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/7%EC%A3%BC%EC%B0%A8/Day26.md) — 일일/실습
- [7주차/Day27.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/7%EC%A3%BC%EC%B0%A8/Day27.md) — 일일/실습
- [7주차/Day28.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/7%EC%A3%BC%EC%B0%A8/Day28.md) — 일일/실습
- [7주차/리눅스 사전지식.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/7%EC%A3%BC%EC%B0%A8/%EB%A6%AC%EB%88%85%EC%8A%A4%20%EC%82%AC%EC%A0%84%EC%A7%80%EC%8B%9D.md) — 요약/보충
- [8주차/8주차 Q&A.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/8%EC%A3%BC%EC%B0%A8/8%EC%A3%BC%EC%B0%A8%20Q%26A.md) — Q&A
- [8주차/8주차 정리.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/8%EC%A3%BC%EC%B0%A8/8%EC%A3%BC%EC%B0%A8%20%EC%A0%95%EB%A6%AC.md) — 요약/보충
- [8주차/Day29.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/8%EC%A3%BC%EC%B0%A8/Day29.md) — 일일/실습
- [8주차/Day30.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/8%EC%A3%BC%EC%B0%A8/Day30.md) — 일일/실습
- [8주차/Day31.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/8%EC%A3%BC%EC%B0%A8/Day31.md) — 일일/실습
- [8주차/Day32.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/8%EC%A3%BC%EC%B0%A8/Day32.md) — 일일/실습
- [9주차/9주차 정리.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/9%EC%A3%BC%EC%B0%A8/9%EC%A3%BC%EC%B0%A8%20%EC%A0%95%EB%A6%AC.md) — 요약/보충
- [9주차/9주차 초간단 정리.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/9%EC%A3%BC%EC%B0%A8/9%EC%A3%BC%EC%B0%A8%20%EC%B4%88%EA%B0%84%EB%8B%A8%20%EC%A0%95%EB%A6%AC.md) — 요약/보충
- [9주차/Day33.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/9%EC%A3%BC%EC%B0%A8/Day33.md) — 일일/실습
- [9주차/Day34(보충).md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/9%EC%A3%BC%EC%B0%A8/Day34%28%EB%B3%B4%EC%B6%A9%29.md) — 요약/보충
- [9주차/Day34.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/9%EC%A3%BC%EC%B0%A8/Day34.md) — 일일/실습
- [9주차/Day35.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/9%EC%A3%BC%EC%B0%A8/Day35.md) — 일일/실습
- [9주차/Day36.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/9%EC%A3%BC%EC%B0%A8/Day36.md) — 일일/실습
- [9주차/Day37 (1).md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/9%EC%A3%BC%EC%B0%A8/Day37%20%281%29.md) — 일일/실습
- [9주차/Day37 (2).md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/9%EC%A3%BC%EC%B0%A8/Day37%20%282%29.md) — 일일/실습
- [README.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/README.md) — 안내
- [취약점 보충/리눅스 복습.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/02-Linux/%EC%B7%A8%EC%95%BD%EC%A0%90%20%EB%B3%B4%EC%B6%A9/%EB%A6%AC%EB%88%85%EC%8A%A4%20%EB%B3%B5%EC%8A%B5.md) — 요약/보충

</details>

<details>
<summary>03-AWS — 7개</summary>

- [13주차/13주차 Q&A.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/03-AWS/13%EC%A3%BC%EC%B0%A8/13%EC%A3%BC%EC%B0%A8%20Q%26A.md) — Q&A
- [13주차/13주차 정리.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/03-AWS/13%EC%A3%BC%EC%B0%A8/13%EC%A3%BC%EC%B0%A8%20%EC%A0%95%EB%A6%AC.md) — 요약/보충
- [13주차/AWS 흐름.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/03-AWS/13%EC%A3%BC%EC%B0%A8/AWS%20%ED%9D%90%EB%A6%84.md) — 요약/보충
- [13주차/Day49.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/03-AWS/13%EC%A3%BC%EC%B0%A8/Day49.md) — 일일/실습
- [13주차/Day50.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/03-AWS/13%EC%A3%BC%EC%B0%A8/Day50.md) — 일일/실습
- [13주차/Day51.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/03-AWS/13%EC%A3%BC%EC%B0%A8/Day51.md) — 일일/실습
- [README.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/03-AWS/README.md) — 안내

</details>

<details>
<summary>04-Docker — 8개</summary>

- [11주차/11주차 정리.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/04-Docker/11%EC%A3%BC%EC%B0%A8/11%EC%A3%BC%EC%B0%A8%20%EC%A0%95%EB%A6%AC.md) — 요약/보충
- [11주차/Day39.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/04-Docker/11%EC%A3%BC%EC%B0%A8/Day39.md) — 일일/실습
- [11주차/Day40.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/04-Docker/11%EC%A3%BC%EC%B0%A8/Day40.md) — 일일/실습
- [11주차/Day41.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/04-Docker/11%EC%A3%BC%EC%B0%A8/Day41.md) — 일일/실습
- [11주차/Day42.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/04-Docker/11%EC%A3%BC%EC%B0%A8/Day42.md) — 일일/실습
- [11주차/Day43.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/04-Docker/11%EC%A3%BC%EC%B0%A8/Day43.md) — 일일/실습
- [README.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/04-Docker/README.md) — 안내
- [도커 사전 맛보기.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/04-Docker/%EB%8F%84%EC%BB%A4%20%EC%82%AC%EC%A0%84%20%EB%A7%9B%EB%B3%B4%EA%B8%B0.md) — 요약/보충

</details>

<details>
<summary>05-Kubernetes — 9개</summary>

- [12주차/12주차 정리.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/05-Kubernetes/12%EC%A3%BC%EC%B0%A8/12%EC%A3%BC%EC%B0%A8%20%EC%A0%95%EB%A6%AC.md) — 요약/보충
- [12주차/Day44.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/05-Kubernetes/12%EC%A3%BC%EC%B0%A8/Day44.md) — 일일/실습
- [12주차/Day45.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/05-Kubernetes/12%EC%A3%BC%EC%B0%A8/Day45.md) — 일일/실습
- [12주차/Day46.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/05-Kubernetes/12%EC%A3%BC%EC%B0%A8/Day46.md) — 일일/실습
- [12주차/Day47.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/05-Kubernetes/12%EC%A3%BC%EC%B0%A8/Day47.md) — 일일/실습
- [12주차/Day48.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/05-Kubernetes/12%EC%A3%BC%EC%B0%A8/Day48.md) — 일일/실습
- [12주차/복습용 Q&A.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/05-Kubernetes/12%EC%A3%BC%EC%B0%A8/%EB%B3%B5%EC%8A%B5%EC%9A%A9%20Q%26A.md) — Q&A
- [12주차/쿠버네티스 맛보기.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/05-Kubernetes/12%EC%A3%BC%EC%B0%A8/%EC%BF%A0%EB%B2%84%EB%84%A4%ED%8B%B0%EC%8A%A4%20%EB%A7%9B%EB%B3%B4%EA%B8%B0.md) — 요약/보충
- [README.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/05-Kubernetes/README.md) — 안내

</details>

<details>
<summary>06-Ansible — 1개</summary>

- [README.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/06-Ansible/README.md) — 안내

</details>

<details>
<summary>07-Terraform — 1개</summary>

- [README.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/07-Terraform/README.md) — 안내

</details>

<details>
<summary>08-Security — 1개</summary>

- [README.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/08-Security/README.md) — 안내

</details>

<details>
<summary>09-Troubleshooting💀 — 11개</summary>

- [01-Network/TroubleShooting (Day 01 ~ Day 08).md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/09-Troubleshooting%F0%9F%92%80/01-Network/TroubleShooting%20%28Day%2001%20~%20Day%2008%29.md) — 장애 기록 · 동일 본문 중복 있음
- [01-Network/TroubleShooting 2.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/09-Troubleshooting%F0%9F%92%80/01-Network/TroubleShooting%202.md) — 장애 기록 · 동일 본문 중복 있음
- [01-Network/TroubleShooting3.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/09-Troubleshooting%F0%9F%92%80/01-Network/TroubleShooting3.md) — 장애 기록
- [01-Network/TroubleShooting4.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/09-Troubleshooting%F0%9F%92%80/01-Network/TroubleShooting4.md) — 장애 기록
- [01-Network/TroubleShooting5.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/09-Troubleshooting%F0%9F%92%80/01-Network/TroubleShooting5.md) — 장애 기록
- [02-Linux/TroubleShooting1.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/09-Troubleshooting%F0%9F%92%80/02-Linux/TroubleShooting1.md) — 장애 기록
- [README.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/09-Troubleshooting%F0%9F%92%80/README.md) — 안내
- [TroubleShooting (Day 01 ~ Day 08).md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/09-Troubleshooting%F0%9F%92%80/TroubleShooting%20%28Day%2001%20~%20Day%2008%29.md) — 장애 기록 · 동일 본문 중복 있음
- [TroubleShooting 2.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/09-Troubleshooting%F0%9F%92%80/TroubleShooting%202.md) — 장애 기록 · 동일 본문 중복 있음
- [깃허브 Troubleshooting.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/09-Troubleshooting%F0%9F%92%80/%EA%B9%83%ED%97%88%EB%B8%8C%20Troubleshooting.md) — 장애 기록 · 동일 본문 중복 있음
- [깃허브 관련/깃허브 Troubleshooting.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/09-Troubleshooting%F0%9F%92%80/%EA%B9%83%ED%97%88%EB%B8%8C%20%EA%B4%80%EB%A0%A8/%EA%B9%83%ED%97%88%EB%B8%8C%20Troubleshooting.md) — 장애 기록 · 동일 본문 중복 있음

</details>

<details>
<summary>10-Projects📖 — 17개</summary>

- [Docker & K8s 기반 프라이빗 클라우드 환경 구축 프로젝트/09-21 프로젝트.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/10-Projects%F0%9F%93%96/Docker%20%26%20K8s%20%EA%B8%B0%EB%B0%98%20%ED%94%84%EB%9D%BC%EC%9D%B4%EB%B9%97%20%ED%81%B4%EB%9D%BC%EC%9A%B0%EB%93%9C%20%ED%99%98%EA%B2%BD%20%EA%B5%AC%EC%B6%95%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/09-21%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8.md) — 프로젝트
- [Docker & K8s 기반 프라이빗 클라우드 환경 구축 프로젝트/09-21~23 프로젝트 정리.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/10-Projects%F0%9F%93%96/Docker%20%26%20K8s%20%EA%B8%B0%EB%B0%98%20%ED%94%84%EB%9D%BC%EC%9D%B4%EB%B9%97%20%ED%81%B4%EB%9D%BC%EC%9A%B0%EB%93%9C%20%ED%99%98%EA%B2%BD%20%EA%B5%AC%EC%B6%95%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/09-21~23%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8%20%EC%A0%95%EB%A6%AC.md) — 프로젝트
- [Docker & K8s 기반 프라이빗 클라우드 환경 구축 프로젝트/09-22 프로젝트.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/10-Projects%F0%9F%93%96/Docker%20%26%20K8s%20%EA%B8%B0%EB%B0%98%20%ED%94%84%EB%9D%BC%EC%9D%B4%EB%B9%97%20%ED%81%B4%EB%9D%BC%EC%9A%B0%EB%93%9C%20%ED%99%98%EA%B2%BD%20%EA%B5%AC%EC%B6%95%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/09-22%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8.md) — 프로젝트
- [Docker & K8s 기반 프라이빗 클라우드 환경 구축 프로젝트/09-23 프로젝트.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/10-Projects%F0%9F%93%96/Docker%20%26%20K8s%20%EA%B8%B0%EB%B0%98%20%ED%94%84%EB%9D%BC%EC%9D%B4%EB%B9%97%20%ED%81%B4%EB%9D%BC%EC%9A%B0%EB%93%9C%20%ED%99%98%EA%B2%BD%20%EA%B5%AC%EC%B6%95%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/09-23%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8.md) — 프로젝트
- [Docker & K8s 기반 프라이빗 클라우드 환경 구축 프로젝트/09-28 프로젝트.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/10-Projects%F0%9F%93%96/Docker%20%26%20K8s%20%EA%B8%B0%EB%B0%98%20%ED%94%84%EB%9D%BC%EC%9D%B4%EB%B9%97%20%ED%81%B4%EB%9D%BC%EC%9A%B0%EB%93%9C%20%ED%99%98%EA%B2%BD%20%EA%B5%AC%EC%B6%95%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/09-28%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8.md) — 프로젝트
- [Docker & K8s 기반 프라이빗 클라우드 환경 구축 프로젝트/09-29 프로젝트.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/10-Projects%F0%9F%93%96/Docker%20%26%20K8s%20%EA%B8%B0%EB%B0%98%20%ED%94%84%EB%9D%BC%EC%9D%B4%EB%B9%97%20%ED%81%B4%EB%9D%BC%EC%9A%B0%EB%93%9C%20%ED%99%98%EA%B2%BD%20%EA%B5%AC%EC%B6%95%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/09-29%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8.md) — 프로젝트
- [Docker & K8s 기반 프라이빗 클라우드 환경 구축 프로젝트/PPT 작성 가이드.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/10-Projects%F0%9F%93%96/Docker%20%26%20K8s%20%EA%B8%B0%EB%B0%98%20%ED%94%84%EB%9D%BC%EC%9D%B4%EB%B9%97%20%ED%81%B4%EB%9D%BC%EC%9A%B0%EB%93%9C%20%ED%99%98%EA%B2%BD%20%EA%B5%AC%EC%B6%95%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/PPT%20%EC%9E%91%EC%84%B1%20%EA%B0%80%EC%9D%B4%EB%93%9C.md) — 발표 가이드
- [Docker & K8s 기반 프라이빗 클라우드 환경 구축 프로젝트/트러블슈팅 Q&A.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/10-Projects%F0%9F%93%96/Docker%20%26%20K8s%20%EA%B8%B0%EB%B0%98%20%ED%94%84%EB%9D%BC%EC%9D%B4%EB%B9%97%20%ED%81%B4%EB%9D%BC%EC%9A%B0%EB%93%9C%20%ED%99%98%EA%B2%BD%20%EA%B5%AC%EC%B6%95%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/%ED%8A%B8%EB%9F%AC%EB%B8%94%EC%8A%88%ED%8C%85%20Q%26A.md) — Q&A
- [Docker & K8s 기반 프라이빗 클라우드 환경 구축 프로젝트/프로젝트 트러블슈팅.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/10-Projects%F0%9F%93%96/Docker%20%26%20K8s%20%EA%B8%B0%EB%B0%98%20%ED%94%84%EB%9D%BC%EC%9D%B4%EB%B9%97%20%ED%81%B4%EB%9D%BC%EC%9A%B0%EB%93%9C%20%ED%99%98%EA%B2%BD%20%EA%B5%AC%EC%B6%95%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8%20%ED%8A%B8%EB%9F%AC%EB%B8%94%EC%8A%88%ED%8C%85.md) — 장애 기록
- [README.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/10-Projects%F0%9F%93%96/README.md) — 안내
- [VMware-Mail.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/10-Projects%F0%9F%93%96/VMware-Mail.md) — 프로젝트
- [리눅스 이관 프로젝트/0901 프로젝트.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/10-Projects%F0%9F%93%96/%EB%A6%AC%EB%88%85%EC%8A%A4%20%EC%9D%B4%EA%B4%80%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/0901%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8.md) — 프로젝트
- [리눅스 이관 프로젝트/0902 프로젝트.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/10-Projects%F0%9F%93%96/%EB%A6%AC%EB%88%85%EC%8A%A4%20%EC%9D%B4%EA%B4%80%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/0902%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8.md) — 프로젝트
- [리눅스 이관 프로젝트/0903 프로젝트.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/10-Projects%F0%9F%93%96/%EB%A6%AC%EB%88%85%EC%8A%A4%20%EC%9D%B4%EA%B4%80%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/0903%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8.md) — 프로젝트
- [리눅스 이관 프로젝트/0904 프로젝트.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/10-Projects%F0%9F%93%96/%EB%A6%AC%EB%88%85%EC%8A%A4%20%EC%9D%B4%EA%B4%80%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/0904%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8.md) — 프로젝트
- [리눅스 이관 프로젝트/이관 프로젝트 TroubleShooting.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/10-Projects%F0%9F%93%96/%EB%A6%AC%EB%88%85%EC%8A%A4%20%EC%9D%B4%EA%B4%80%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/%EC%9D%B4%EA%B4%80%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8%20TroubleShooting.md) — 장애 기록
- [연습 프로젝트/연습 프로젝트1.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/10-Projects%F0%9F%93%96/%EC%97%B0%EC%8A%B5%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/%EC%97%B0%EC%8A%B5%20%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B81.md) — 프로젝트

</details>

<details>
<summary>루트 — 1개</summary>

- [README.md](https://github.com/YGJ1203/Cloud-IaC-Study/blob/main/README.md) — 안내

</details>

