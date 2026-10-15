# Ansible 실습 정리 및 node3 장애 기록 — 2026-10-15

> VMware CentOS Stream 9 / Ansible Core 2.14.18 / Kubernetes v1.27.7  
> **주의:** 기존 KAIST Kubernetes 프로젝트가 운영되는 VM입니다. 변경 가능 명령은 실행 전에 별도 검토합니다.

## 1. 환경 및 Inventory

| 호스트 | IP | 역할 |
|---|---|---|
| master | 192.168.2.60 | Ansible 제어 노드, K8s control-plane |
| node1 | 192.168.2.61 | 관리 노드, worker |
| node2 | 192.168.2.62 | 관리 노드, worker |
| node3 | 192.168.2.63 | 관리 노드, worker |
| loadbalancer | 192.168.2.80 | KAIST 관련 서버 |

`/etc/ansible/hosts`:

```ini
[testnode]
192.168.2.61
192.168.2.62
192.168.2.63
```

`ansible-inventory --list -y` 결과에서 `all > children > testnode > hosts`에 세 노드가 확인됐고, `ungrouped`는 비어 있었습니다. master는 현재 testnode 그룹에 포함되지 않습니다.

## 2. Ad-hoc 모듈 복습

| 명령 | 관찰 결과 | 학습 포인트 |
|---|---|---|
| `ansible testnode -m ping` | 3/3 pong | SSH 및 Ansible 연결 확인 |
| `ansible 192.168.2.61 -m command -a 'id'` | UID/GID 0(root) | 원격 명령 실행 사용자 |
| `ansible 192.168.2.61 -m shell -a 'cat /etc/passwd \| grep ^root'` | root 계정 행 출력 | 셸 파이프 사용 |
| `ansible testnode -m command -a 'id root'` | 세 노드 UID/GID 0 | 계정 식별 정보 |
| `ansible testnode -m command -a 'getent passwd root'` | 세 노드 `/root`, `/bin/bash` | 계정 데이터베이스 조회 |

**`command` vs `shell`:** `command`는 셸 연산자(`|`, `>`, `&&` 등)를 셸처럼 처리하지 않으며, `shell`은 원격 셸을 통해 실행합니다. `command`나 `shell`의 `CHANGED`는 실제 변경이 발생했다는 증거가 아닙니다.

## 3. 패키지와 체크 모드

```bash
ansible testnode -m command -a 'rpm -q vsftpd'
# 세 노드: FAILED | rc=1 → vsftpd 미설치

ansible testnode -m command -a 'rpm -q bash'
# 세 노드: CHANGED | rc=0 → bash-5.1.8-9.el9.x86_64

ansible testnode -m command -a 'rpm -q bash' --check
# 세 노드: SKIPPED
```

- `rpm -q`에서 `rc=1`은 미설치 패키지를 조회했을 때 나타날 수 있습니다. 서버 장애가 아닙니다.
- `command`는 조회 명령이라도 기본적으로 `CHANGED`로 보고할 수 있습니다.
- `--check`에서 `command`는 `creates`/`removes` 등의 조건이 없으면 실행을 생략할 수 있습니다.
- `yum`/`dnf` 모듈의 `state: present`는 패키지 설치 상태를 보장하지만 실제 변경이 가능하므로 현재 노드에서 설치 실습은 진행하지 않았습니다.

## 4. Facts와 서비스 상태

```bash
ansible testnode -m setup -a 'filter=ansible_distribution*'
```

세 노드 모두 `SUCCESS`, `changed: false`로 확인된 정보:

```yaml
ansible_distribution: CentOS
ansible_distribution_major_version: '9'
ansible_distribution_release: Stream
ansible_distribution_version: '9'
discovered_interpreter_python: /usr/bin/python3
```

Facts는 OS·CPU·메모리·네트워크 등 대상 시스템의 정보입니다. `setup`은 Facts 수집 모듈입니다.

```bash
ansible testnode -m command -a 'systemctl is-active sshd'
# active
ansible testnode -m command -a 'systemctl is-enabled sshd'
# enabled
```

- `active`: 현재 서비스 실행 중.
- `enabled`: 일반적인 부팅 과정에서 자동 시작하도록 설정됨.
- `service`의 `state: started`는 실행 상태 보장, `state: restarted`는 실행 때마다 재시작 요청.
- 서비스 중지·재시작은 수행하지 않았습니다.

## 5. 파일 관리: stat, copy, fetch

```bash
ansible testnode -m stat -a 'path=/etc/hosts'
ansible testnode -m command -a 'cat /etc/hosts'
ansible-doc fetch
ansible-doc copy
```

`stat` 결과: 세 노드 모두 `SUCCESS`, `changed: false`, `/etc/hosts` 존재, 일반 파일, 소유자/그룹 `root`, 권한 `0644`, 크기 575바이트. SHA-1 체크섬도 모두 `4db0d260c25c0247e4693dfb6fe2d0f9d3d3945c`로 일치했습니다. 실제 `cat` 출력 내용도 같았습니다. SHA-1은 보안상 강한 무결성 검증에는 권장되지 않습니다.

`0644` = 소유자 읽기·쓰기, 그룹 읽기, 기타 사용자 읽기.

**주의할 기록:** 세 노드의 `/etc/hosts`에 `192.168.2.80 loadbalancer.examlple.com loadbalancer`가 있었으며 `examlple`은 오타로 보입니다. 실제 서비스 영향은 확인되지 않았으므로 수정하지 않았습니다.

| 모듈 | 역할 | 주요 옵션 |
|---|---|---|
| `stat` | 파일 메타데이터 조회 | `path` |
| `copy` | 제어 노드 → 관리 노드 파일 배포 | `src`, `dest`, `owner`, `group`, `mode`, `backup` |
| `fetch` | 관리 노드 → 제어 노드 파일 수집 | `src`, `dest`, `flat` |

`fetch`의 `flat` 설정과 저장 경로에 따라 여러 노드의 동일 파일명이 충돌할 수 있습니다. **실제 파일 배포·수집은 하지 않았습니다.**

## 6. 멱등성

**멱등성(Idempotency):** 같은 작업을 반복해도 최종 시스템 상태가 원하는 상태로 유지되는 성질입니다.

- `state: present`, `state: started` 등은 이미 원하는 상태라면 불필요한 변경을 피할 수 있습니다.
- `state: restarted`는 실행할 때마다 재시작을 요청합니다.
- `changed_when: false`는 **결과 판정만 변경**하며 실제 변경을 막는 안전장치가 아닙니다.

## 7. Ansible 설정 확인

```bash
ansible-config dump --only-changed
# CONFIG_FILE() = None

ansible-config dump | grep '^DEFAULT_HOST_LIST'
# DEFAULT_HOST_LIST(default) = ['/etc/ansible/hosts']
```

별도의 `ansible.cfg`를 적용하지 않았으며 내장 기본 Inventory 경로를 사용하고 있습니다. Inventory는 **어디에 실행할지**, `ansible.cfg`는 **어떻게 실행할지**를 설정합니다.

## 8. 첫 Playbook 작성과 YAML 오류 해결

작업 디렉터리: `/root/ansible-study/`  
작성 파일: `/root/ansible-study/01-check.yml`

**실제로 작성한 YAML:**

```yaml
---
- name: First Ansible Playbook
  hosts: testnode
  gather_facts: false

  tasks:
    - name: Check hostname
      ansible.builtin.command: hostname
      changed_when: false
```

- `hosts`: 실행 대상 그룹.
- `gather_facts: false`: 자동 Facts 수집 생략.
- `tasks`: 작업 목록.
- `command: hostname`: 읽기 전용 호스트 이름 조회.
- `changed_when: false`: 결과를 변경 없음으로 보고.

**첫 구문 검사 오류:**

```text
found a tab character that violates indentation
... line 3, column 1
```

`hosts:` 앞의 탭 문자가 원인이었습니다. YAML 들여쓰기에는 **탭이 아니라 공백**을 사용합니다. `hosts`, `gather_facts`, `tasks`는 같은 Play 속성 수준에 배치해야 합니다.

수정 후:

```bash
ansible-playbook /root/ansible-study/01-check.yml --syntax-check
# playbook: /root/ansible-study/01-check.yml
cat -n /root/ansible-study/01-check.yml
```

구문 검사 통과와 실제 실행 성공은 다릅니다.

## 9. 첫 Playbook 실행 — node3 SSH 장애

```bash
ansible-playbook /root/ansible-study/01-check.yml
```

| 노드 | ok | changed | unreachable | failed |
|---|---:|---:|---:|---:|
| node1 | 1 | 0 | 0 | 0 |
| node2 | 1 | 0 | 0 | 0 |
| **node3** | **0** | **0** | **1** | **0** |

node3 오류:

```text
UNREACHABLE!
Connection timed out during banner exchange
Connection to 192.168.2.63 port 22 timed out
```

- node1, node2에서는 `hostname` 작업이 정상 완료됐습니다.
- node3는 SSH 연결 단계에서 시간 초과가 발생했습니다.
- `UNREACHABLE`은 원격 작업 실행 오류(`FAILED`)와 구분해야 합니다.
- 읽기 전용 `hostname` Playbook이 메모리 부족을 유발했다고 판단할 근거는 없습니다.
- 사용자는 VMware에서 node3의 메모리 부족 증상을 관찰했다고 보고했습니다. 원인 확정은 추가 진단이 필요합니다.

## 10. node3 Kubernetes 장애 — **미해결**

```bash
kubectl get nodes -o wide
```

관찰 결과: `master`, `node1`, `node2`는 `Ready`; **`node3`는 `NotReady`**.

```bash
kubectl get pods -A -o wide --field-selector spec.nodeName=node3
```

**node3에 남아 있던 KAIST Pod 13개가 `Terminating`:**

| 네임스페이스 | 개수 |
|---|---:|
| kaist-ai | 3 |
| kaist-com | 3 |
| kaist-ft | 3 |
| kaist-sys | 3 |
| kaist | 1 |
| **합계** | **13** |

추가로 `kube-system`의 CoreDNS 1개도 `Terminating`. `calico-node`, `kube-proxy`, `nginx-proxy-node3`, `nodelocaldns`는 출력상 `Running`이었고 각각 13~17회의 재시작 기록이 있었습니다.

**중요한 해석:**

- `1/1 Terminating`이 현재 서비스 정상 작동을 보장하지는 않습니다.
- `NotReady`는 전원이 꺼졌다는 의미와 동일하지 않습니다.
- 노드 통신 장애 시 API 서버에는 이전 Pod 상태가 남아 있을 수 있습니다.
- node2에도 이전에 OOM/SSH 문제가 있었으므로 전체 클러스터의 자원 상황을 신중히 살펴야 합니다.

**수행하지 않은 조치:** node3 종료·강제 재부팅, Pod 강제 삭제, `drain`, 노드 삭제, 서비스 재시작, 패키지 변경. node3 장애는 이 문서 작성 시점에 **복구 확인되지 않았습니다**.

## 11. 다음 학습일 체크리스트

1. **읽기 전용** `kubectl get deployments -A`로 KAIST Deployment 준비 상태 확인.
2. 필요시 노드별 Pod 배치, 이벤트, 메모리/OOM 로그를 읽기 전용으로 점검.
3. node3 종료·재부팅 여부는 서비스 영향과 복구 방법을 확인한 뒤 결정.
4. 클러스터 상태가 안정될 때까지 node3 대상 추가 Ansible 실습 중단.
5. 안정화 후 첫 Playbook의 `hosts`·`tasks`·`changed_when` 복습.
6. 다음에는 `debug`와 Facts를 활용한 **읽기 전용 Playbook**으로 진도 진행.
7. `user`, `yum`, `service`, `copy` 등 변경형 모듈은 별도 실습 환경에서 연습.

## 12. 면접 핵심 질문

**Q. `command`와 `shell`의 차이는?**  
A. `command`는 셸을 거치지 않고 실행하며, `shell`은 파이프·리다이렉션 등 셸 기능을 사용할 수 있습니다.

**Q. `CHANGED`는 반드시 실제 변경인가?**  
A. 아닙니다. `command`의 조회 명령도 기본적으로 `CHANGED`가 표시될 수 있습니다.

**Q. 체크 모드에서 `SKIPPED`가 나온 이유는?**  
A. `command` 모듈은 실행 결과를 예측하기 어려워 특정 조건이 없으면 체크 모드에서 생략할 수 있습니다.

**Q. Facts란?**  
A. Ansible이 수집하는 대상 시스템의 OS·네트워크·메모리 등 정보입니다.

**Q. `active`와 `enabled`의 차이는?**  
A. 현재 실행 상태와 부팅 시 자동 시작 설정의 차이입니다.

**Q. Inventory와 `ansible.cfg`의 차이는?**  
A. 관리 대상 목록과 Ansible 실행 설정의 차이입니다.

**Q. 멱등성이란?**  
A. 동일한 작업을 반복해도 최종 시스템 상태가 원하는 상태로 유지되는 성질입니다.

**Q. `changed_when: false`는 시스템 변경을 방지하나?**  
A. 아닙니다. 결과의 변경 판정만 조정합니다.

**Q. 구문 검사 통과 후에도 실패할 수 있나?**  
A. 네. node3 사례처럼 SSH 연결 장애로 `UNREACHABLE`이 발생할 수 있습니다.

---

**오늘의 결론:** 첫 Playbook의 작성·탭 오류 수정·구문 검사까지 성공했고 node1/node2에서 실제 실행도 성공했습니다. node3는 SSH 시간 초과 및 Kubernetes `NotReady` 상태로 **미해결 장애**입니다. 다음에는 서비스 상태를 먼저 확인한 뒤 실습을 재개합니다. 
