# 2026-10-16 Ansible 실습 정리 — Chapter 11: Handlers & Notify

> **학습 상태:** Chapter 11 완료 · Chapter 12(`register` / `changed_when` / `failed_when`)는 다음 시간 진행 예정  
> **환경:** CentOS Stream 9 / Ansible Core 2.14.18 / VMware 기반 master·node1·node2·node3  
> **실습 경로:** `/root/ansible-study`  
> **안전 범위:** `/tmp`의 실습 파일만 변경. Kubernetes 서비스나 실제 systemd 서비스 재시작 없음.

---

## 1. 오늘의 핵심 요약

Ansible의 **Handler**는 일반 Task에서 `notify`를 통해 실행 요청을 받는 특별한 Task이다. 보통 **알림을 보낸 Task가 `changed` 상태일 때만** 실행되며, 기본적으로 Play의 일반 Task 실행 이후 Handler 처리 시점에 실행된다.

- `notify`: 변경 발생 시 특정 Handler의 실행을 요청한다.
- `handlers`: 알림받았을 때 실행할 Task를 정의한다.
- `changed`: 파일 생성·수정 등 상태 변화가 발생했다는 보고이다.
- `ok`: Task가 성공했지만 변경이 없을 수도 있다. Handler의 `debug` 출력도 `ok`로 집계된다.
- `skipped`: `when` 조건이 맞지 않아 Task를 실행하지 않았다.
- **멱등성:** 같은 Playbook을 다시 실행해도 이미 원하는 상태라면 변경하지 않는다.

> **핵심 공식:** 설정 변경 → `notify` → Handler 실행 / 변경 없음 → Handler 실행 요청 없음.

## 2. 실습 환경 및 변수

| 구분 | IP | 그룹 | `server_role` | `service_port` |
|---|---|---|---|---|
| node1 | `192.168.2.61` | `webservers` | `web-primary` | `8080` |
| node2 | `192.168.2.62` | `webservers` | `web` | `80` |
| node3 | `192.168.2.63` | `dbservers` | `database` | `3306` |

- Inventory의 `testnode` 그룹에는 세 노드가 모두 포함된다.
- node1의 `host_vars`가 `webservers`의 `group_vars`보다 우선하여 `web-primary`, `8080`이 적용된다.
- 이번 Playbook은 `when: server_role in ['web', 'web-primary']`로 웹 노드 두 대만 설정을 배포한다.

## 3. 작성한 Playbook: `11-handler.yml`

아래는 **실행 로그와 일치하도록 재구성한 실습 예시**이다. 실제 로그에서 확인된 설정 내용(`# Handler - CP3`, `process=...`)과 Handler 이름을 반영했다. 전체 원본 YAML을 직접 첨부받은 것은 아니므로, 세부 속성은 실제 파일과 다를 수 있다.

```yaml
---
- name: Practice Ansible Handlers and Notify
  hosts: testnode
  gather_facts: false

  tasks:
    - name: Deploy web configuration
      ansible.builtin.copy:
        content: |
          # Handler - CP3
          server_role={{ server_role }}
          service_port={{ service_port }}
          process=Trust the Process
        dest: /tmp/ansible-handler.conf
        owner: root
        group: root
        mode: '0644'
      when: server_role in ['web', 'web-primary']
      notify: Apply web configuration

  handlers:
    - name: Apply web configuration
      ansible.builtin.debug:
        msg: "Configuration changed on {{ inventory_hostname }}! Handler executed."
```

### 주요 구문 분석

| 구문 | 설명 |
|---|---|
| `hosts: testnode` | node1·node2·node3를 Play 대상으로 지정 |
| `gather_facts: false` | 이번 실습에 불필요한 Fact 수집 생략 |
| `ansible.builtin.copy` | 노드별 변수를 반영한 설정 텍스트를 원격 `/tmp`에 배포 |
| `when` | `web`, `web-primary`만 배포하고 DB 노드는 제외 |
| `notify: Apply web configuration` | 배포 Task가 변경되면 Handler 실행 요청 |
| `handlers:` | 일반 Task와 구분하여 Handler 정의 |
| `ansible.builtin.debug` | 실제 서비스 재시작 없이 Handler 실행 여부 확인 |

**주의:** `notify`의 대상 이름과 Handler의 `name`이 일치해야 한다. 이번 예제는 메시지만 출력하므로 실제 서비스 재시작은 발생하지 않는다.

## 4. 단계별 실제 실습 기록

### 4.1 문법 및 대상 호스트 검사 — 성공

```bash
cd /root/ansible-study
ansible-playbook 11-handler.yml --syntax-check
ansible-playbook 11-handler.yml --list-hosts
```

관찰한 결과:

```text
playbook: 11-handler.yml

play #1 (testnode): Practice Ansible Handlers and Notify
hosts (3):
  192.168.2.63
  192.168.2.61
  192.168.2.62
```

**해석:** 문법 검사가 통과했고, Play 대상은 세 노드 모두이다. 단, 대상에 포함되었다고 해서 모든 Task가 실행되는 것은 아니다. `when`에 의해 node3는 건너뛴다.

### 4.2 최초 Check Mode — 변경 예측 + Handler 표시

```bash
ansible-playbook 11-handler.yml --check --diff
```

주요 결과:

```text
TASK [Deploy web configuration]
skipping: [192.168.2.63]
changed: [192.168.2.62]
changed: [192.168.2.61]

RUNNING HANDLER [Apply web configuration]
ok: [192.168.2.61]
ok: [192.168.2.62]

PLAY RECAP
192.168.2.61 : ok=2 changed=1 failed=0
192.168.2.62 : ok=2 changed=1 failed=0
192.168.2.63 : ok=0 changed=0 skipped=1 failed=0
```

`--diff`에서 웹 노드별 설정 내용이 생성될 것으로 예측되었다.

```ini
# Handler - CP3
server_role=web-primary
service_port=8080
process=Trust the Process
```

node2에서는 `server_role=web`, `service_port=80`이 표시되었다.

**중요:** Check Mode의 `changed=1`은 실제 변경이 아니라 **예상 변경**이다. 변경이 예측되면 Handler도 실행된 것처럼 표시될 수 있다. 이번 Handler는 `debug`이므로 Check Mode에서도 메시지가 출력되었다.

### 4.3 최초 실제 배포 — 성공

```bash
ansible-playbook 11-handler.yml --diff
```

관찰 결과:

- node1·node2: `changed=1`
- node3: `skipped=1`
- `RUNNING HANDLER [Apply web configuration]` 표시
- Handler 메시지: `Configuration changed on 192.168.2.61! Handler executed.` 등
- 세 노드 모두 `failed=0`

**해석:** 웹 노드 두 대의 설정 파일이 실제로 배포되었고, 변경에 따라 Handler가 호출되었다.

### 4.4 동일 Playbook 재실행 — 멱등성 검증 성공

```bash
ansible-playbook 11-handler.yml
```

```text
TASK [Deploy web configuration]
skipping: [192.168.2.63]
ok: [192.168.2.61]
ok: [192.168.2.62]

PLAY RECAP
192.168.2.61 : ok=1 changed=0 skipped=0 failed=0
192.168.2.62 : ok=1 changed=0 skipped=0 failed=0
192.168.2.63 : ok=0 changed=0 skipped=1 failed=0
```

**핵심 관찰:** `RUNNING HANDLER`가 **아예 출력되지 않았다**. 설정 파일이 이미 원하는 상태였기 때문에 `copy` Task는 `ok`, `changed=0`으로 끝났고 Handler 알림도 발생하지 않았다.

### 4.5 설정 내용 수정 — 변경 감지 검증 성공

사용자가 직접 설정 내용을 다음과 같이 변경했다.

```diff
-process=Trust the Process
+process=Stepping over Ty Lue
```

수정 후 Check Mode:

```bash
ansible-playbook 11-handler.yml --check --diff
```

두 웹 노드 모두 `changed=1`(예측), Handler 출력 확인. node3는 `skipped=1`.

수정 후 실제 배포:

```bash
ansible-playbook 11-handler.yml --diff
```

두 웹 노드 모두 `changed=1`, Handler 실행 확인. 특히 `--diff`에서 **기존 한 줄이 새 한 줄로 교체되는 차이**를 명확하게 확인했다.

### 4.6 수정 후 최종 재실행 — 멱등성 재검증 성공

```bash
ansible-playbook 11-handler.yml
```

```text
192.168.2.61 : ok=1 changed=0 failed=0
192.168.2.62 : ok=1 changed=0 failed=0
192.168.2.63 : ok=0 changed=0 skipped=1 failed=0
```

Handler 출력 없음. **수정 → Handler 실행 → 재실행 시 Handler 미실행**까지 모두 검증했다.

## 5. 실습 결과 종합

| 실행 단계 | node1 | node2 | node3 | Handler |
|---|---|---|---|---|
| 최초 `--check --diff` | 변경 예측 | 변경 예측 | skipped | Check Mode에서 표시 |
| 최초 실제 배포 | changed=1 | changed=1 | skipped | 실행 |
| 동일 내용 재실행 | changed=0 | changed=0 | skipped | 미실행 |
| 문구 변경 후 Check Mode | 변경 예측 | 변경 예측 | skipped | Check Mode에서 표시 |
| 문구 변경 후 실제 배포 | changed=1 | changed=1 | skipped | 실행 |
| 최종 재실행 | changed=0 | changed=0 | skipped | 미실행 |

**결론:** `when`, `notify`, Handler, `--check`, `--diff`, 멱등성이 의도대로 동작했다. 로그상 실패나 도달 불가 노드는 없었다.

## 6. 트러블슈팅: Vim과 Ansible 옵션 혼동

실습 중 다음 명령을 입력했다.

```bash
vi 11-handler.yml --check --diff
```

결과:

```text
모르는 옵션 인자: "--check"
더 많은 정보를 원하시면: "vim -h"
```

**원인:** `--check`, `--diff`는 `ansible-playbook` 옵션이며 Vim 편집기 옵션이 아니다.

**올바른 실행:**

```bash
vi 11-handler.yml
ansible-playbook 11-handler.yml --check --diff
```

편집은 `vi`, 시뮬레이션과 변경 비교는 `ansible-playbook`으로 분리한다. 이후 올바른 명령으로 실행하여 정상적으로 완료했다.

## 7. 실무 관점에서 알아둘 사항

1. **불필요한 재시작 방지:** 웹 서버 설정이 바뀐 경우에만 `notify: Restart nginx` 등으로 서비스를 재시작하거나 reload하도록 설계할 수 있다. 이번 실습에서는 안전을 위해 `debug`만 사용했다.
2. **Handler 실행 시점:** 기본적으로 일반 Task 실행 후 Handler 처리 시점에 실행된다. `meta: flush_handlers`를 사용하면 그 시점까지 요청된 Handler를 중간에 실행할 수 있다.
3. **중복 알림:** 같은 Handler에 여러 Task가 알림을 보내더라도, 한 번의 Handler 처리 시점에는 보통 호스트당 한 번 실행된다.
4. **실패 처리:** Handler가 예약되었더라도 같은 호스트에서 이후 Task가 실패하면 기본 동작상 실행되지 않을 수 있다. 필요 시 `force_handlers` 동작을 검토한다.
5. **Check Mode 주의:** `--check`는 변경 예측 도구이지 완전한 격리 환경이 아니다. 모듈 지원 여부 및 Task 성격을 고려해야 한다.
6. **`ok`와 `changed`의 차이:** Handler의 `debug`가 `ok`로 집계되어 최초 배포의 `ok=2 changed=1`이 나왔다. `ok`는 성공 Task 수, `changed`는 변경으로 보고된 Task 수이므로 서로 배타적인 값이 아니다.

### 참고용 실무 패턴 — 실제 실습에서는 실행하지 않음

```yaml
- name: Deploy nginx configuration
  ansible.builtin.template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
    mode: '0644'
  notify: Reload nginx

handlers:
  - name: Reload nginx
    ansible.builtin.service:
      name: nginx
      state: reloaded
```

> 위 예시는 개념 이해용이며 **오늘 실습 환경에 적용한 내용이 아니다.** 실제 운영에서는 설정 검증, 서비스 존재 여부, 재시작 영향 범위 등을 확인한 뒤 적용해야 한다.

## 8. 면접 예상 질문 & 답변

**Q1. Ansible Handler란?**  
A. 일반 Task의 변경으로부터 `notify` 알림을 받아 특정 후속 작업을 실행하는 특별한 Task이다. 서비스 재시작·reload 등 변경 후 조치에 주로 사용한다.

**Q2. `notify`를 작성했는데 Handler가 실행되지 않는 이유는?**  
A. 알림을 보내는 Task가 `changed`가 아닌 `ok`나 `skipped`일 수 있다. Handler 이름 불일치, Task 실패 등도 점검해야 한다.

**Q3. Handler는 `notify` 즉시 실행되는가?**  
A. 기본적으로 즉시 실행되지 않고 Handler 처리 시점에 실행된다. `meta: flush_handlers`로 중간 실행할 수 있다.

**Q4. Handler에 여러 번 알림을 보내면 여러 번 실행되는가?**  
A. 동일 Handler에 대한 중복 알림은 한 번의 처리 시점에 합쳐지므로 보통 한 번만 실행된다.

**Q5. `--check --diff`의 목적은?**  
A. 실제 변경 전 변경 가능성과 변경 내용을 확인하는 것이다. 다만 모든 Task가 완벽하게 시뮬레이션되는 것은 아니다.

**Q6. 멱등성이란?**  
A. 같은 자동화를 반복 실행해도 이미 원하는 상태라면 불필요한 변경을 발생시키지 않는 성질이다.

**Q7. `ok=2 changed=1`은 무슨 뜻인가?**  
A. 성공한 Task가 두 개이며, 그중 변경으로 보고된 Task가 하나라는 뜻이다. 이번 실습에서는 배포 Task가 `changed`, Handler의 `debug`가 `ok`였다.

## 9. 오늘의 명령어 치트시트

```bash
# 문법 검사
ansible-playbook 11-handler.yml --syntax-check

# 실행 대상 확인
ansible-playbook 11-handler.yml --list-hosts

# 변경 예측 + 차이 확인
ansible-playbook 11-handler.yml --check --diff

# 실제 배포 + 차이 확인
ansible-playbook 11-handler.yml --diff

# 멱등성 검증
ansible-playbook 11-handler.yml
```

## 10. 다음 시간 예고 — Chapter 12 (미진행)

**주제:** `register`, `changed_when`, `failed_when`을 이용한 명령 결과 분석 및 상태 판정.

- `register`: 명령 결과 저장 (`rc`, `stdout`, `stderr` 등)
- `changed_when`: 변경 여부 직접 지정
- `failed_when`: 사용자 정의 실패 조건 지정
- 실습 예정 파일: `12-register.yml`, 심화 `12-failed-when.yml`

> **진도 구분:** Chapter 12는 설명과 실습 계획만 다뤘으며, 사용자가 직접 YAML을 작성·실행한 것은 아니다. **다음 시간에 이어서 진행.**

---

## 최종 체크리스트

- [x] `11-handler.yml` 작성
- [x] `--syntax-check` 성공
- [x] `--list-hosts`로 3개 대상 확인
- [x] 최초 `--check --diff` 확인
- [x] 실제 배포 후 Handler 실행 확인
- [x] 변경 없는 재실행에서 Handler 미실행 확인
- [x] `Trust the Process` → `Stepping over Ty Lue` 변경 감지
- [x] 변경 후 Handler 재실행 확인
- [x] 최종 멱등성 재검증
- [x] Vim 옵션 입력 실수 해결
- [ ] Chapter 12 실습 (다음 시간)

**오늘의 한 줄:** `changed=1`이면 Handler가 움직이고, `changed=0`이면 불필요한 후속 작업을 하지 않는다. 
