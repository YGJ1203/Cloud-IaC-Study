# 2026-11-11 보안 실습 복습 및 2차 프로젝트 안내

> KDT 클라우드·보안 과정 | Kali Linux · Wireshark · Snort · 프로젝트 계획

## 1. 오늘의 학습 개요

- 전날 진행한 네트워크 공격·방어 실습 복습
- Kali Linux `hping3`를 이용한 TCP SYN / UDP / ICMP Flood 관찰
- IP Spoofing, 대용량 ICMP 및 IP Fragmentation 확인
- Wireshark 패킷 분석과 Snort 탐지 로그 대조
- 12월 정보시스템 보안 진단 프로젝트 일정·주제 안내

## 2. Kali Linux 공격 실습 기록

> 격리된 실습망에서 수행한 기록. 아래 명령은 실습 재현 기록이며 허가된 환경에서만 사용한다.

### 2.1 사전 스캔

```bash
nmap -sS -sV 192.168.20.205
```

- `-sS`: TCP SYN 스캔
- `-sV`: 서비스 버전 탐지
- 제공된 콘솔 기록에는 시작 메시지만 있어 스캔 결과는 확인할 수 없음.

### 2.2 TCP SYN Flood

```bash
hping3 --interface eth0 --syn -p 80 192.168.20.200 --flood
hping3 --interface eth0 --syn -p 80 192.168.20.205 --flood
```

- 대상 `.200`: 174,685 packets transmitted
- 대상 `.205`: 95,455 packets transmitted
- SYN 패킷을 다량 전송. Wireshark에서 SYN 및 SYN-ACK 흐름을 관찰.
- SYN Flood 탐지와 실제 연결 자원 고갈·서비스 장애는 별도로 검증해야 함.

### 2.3 UDP Flood

```bash
hping3 --interface eth0 --udp -p 53 192.168.20.200 --flood
```

- 52,908 packets transmitted
- UDP 53번 포트 대상. DNS 형식을 갖추지 않은 페이로드는 Wireshark에서 `Malformed Packet`으로 표시될 수 있음.

### 2.4 ICMP Flood

```bash
hping3 --interface eth0 --icmp 192.168.20.200 --flood
```

- 57,568 packets transmitted
- ICMP Echo Request 대량 전송.

### 2.5 출발지 IP Spoofing 및 LAND 유사 패턴

```bash
hping3 --interface eth0 --icmp 192.168.20.200 --flood --spoof 192.168.20.200
```

- 109,872 packets transmitted
- 출발지와 목적지가 모두 `192.168.20.200`인 ICMP 패킷 관찰.
- Snort는 `Land Attack`과 `ICMP Flooding Attack`을 함께 탐지.
- 고전적인 LAND 공격은 주로 TCP SYN을 지칭하므로, 이번 결과는 **ICMP에서 출발지·목적지 IP가 동일한 LAND 유사 패턴**으로 기록.

### 2.6 대용량 ICMP 및 단편화

```bash
# 최초 입력 오류
hping3 --interface eth0 --icmp 192.168.20.200 --d 64000
# 정상 실행
hping3 --interface eth0 --icmp 192.168.20.200 --flood -d 64000
```

- `--d`는 모호한 옵션으로 오류 발생; `-d 64000`으로 데이터 길이 지정.
- 2,140 packets transmitted
- 큰 IP 데이터그램이 MTU에 맞춰 여러 조각으로 나뉘는 IP Fragmentation 확인.
- Snort의 `Ping of Death Attack` 탐지는 규칙 일치 결과이며, 이 로그만으로 IPv4 최대 길이 초과나 실제 장애를 입증하지는 못함.

**주의:** `--flood` 모드는 응답을 표시하지 않으므로 `0 packets received / 100% packet loss`를 서버 장애의 증거로 해석하지 않는다.

## 3. Wireshark 및 시스템 모니터 관찰

- TCP: SYN / SYN-ACK 패킷 흐름
- UDP: 목적지 53번 포트의 반복 패킷 및 일부 `Malformed Packet`
- ICMP: Echo Request 반복
- Spoofing: 동일한 Source / Destination IP
- 대용량 ICMP: `Fragmented IP protocol`, fragment offset 확인
- GNOME System Monitor: CPU 사용률의 일시적 상승 관찰. 공격과의 인과관계 및 서비스 장애는 추가 지표 필요.

## 4. Snort 탐지 결과 (11/11)

| SID | 탐지 메시지 | 확인 시간대 |
|---|---|---|
| 3000012 | NMAP Half Open-SCAN | 10:42~11:05 |
| 3000020 | TCP Syn Flooding Attack | 10:44, 10:50, 11:05 |
| 3000021 | UDP Flooding Attack | 10:45, 11:06 |
| 3000016 | ICMP Flooding Attack | 10:47~10:49, 11:06~11:07 |
| 3000018 | Land Attack | 10:48, 11:07 |
| 3000022 | IP Fragments Attack | 10:49 |
| 3000017 | Ping of Death Attack | 10:49 |
| 3000301 | SQL Injection URI AND | 11:37 등 |
| 3000302 | SQL Injection URI OR | 11:30~11:37 |
| 3000305 | SQL Injection Body AND | 11:37 |
| 3000306 | SQL Injection Body OR | 10:43, 11:30~11:37 |
| 3000205 | OS Command Injection Body / | 11:30~11:31 |

- 로그상 12종류 SID 확인.
- `.200`, `.205` 대상 네트워크 공격 로그와 `.100:80` 대상 웹 관련 탐지 로그를 분리하여 분석.
- **실습 운영 메모:** Snort 백그라운드 작업을 종료하지 않아 이후 트래픽에 대한 경고도 계속 누적됨. Snort 자체가 공격을 생성한 것은 아님.

```bash
jobs -l      # 현재 셸의 작업 목록 확인
kill %1      # 작업 번호 1 정상 종료 요청
# 종료되지 않는 경우에만: kill -9 %1
```

- Snort 탐지 ≠ 공격 성공 ≠ 차단 성공. 실제 차단은 방화벽/WAF 정책 및 통신 결과를 별도로 확인.

## 5. 02_클라우드 인프라 기반 정보시스템 보안 진단 프로젝트

### 5.1 공식 안내 일정

| 기간 | 일수 |
|---|---:|
| 12/01(화) ~ 12/04(금) | 4일 |
| 12/07(월) ~ 12/11(금) | 5일 |
| 12/14(월) ~ 12/18(금) | 5일 |
| 12/21(월) ~ 12/24(목) | 4일 |
| **총계** | **18일** |

### 5.2 실제 진행 순서: 팀주제2 → 팀주제1

#### 먼저: 팀주제2 — AWS 클라우드 환경 정보시스템 보안 진단 및 Veritas 보안 솔루션

- AWS로 이전한 본사/지사를 위한 보안 구축
- AWS 보안 그룹, NACL, WAF 구축 내용
- 공격 및 방지 시연 내용
- AWS 보안 진단
- Veritas 보안 솔루션 적용

#### 다음: 팀주제1 — IaC 코드 기반 프라이빗 클라우드 환경 정보시스템 보안 진단

- Docker 및 K8S 환경 호스트를 위한 보안 구축
- Fortinet NGFW, Fortinet WAF 구축 내용
- 공격 및 방지 시연 내용
- Docker 보안 진단
- K8S 보안 진단

### 5.3 팀 구성과 미확정 사항

- **팀원:** 기존 KAIST 하이브리드 클라우드 프로젝트와 동일
- **역할 분담:** 11월 12일 재논의 예정
- 주제별 상세 일정, Veritas 적용 제품 및 범위는 아직 안내 내용만으로 확정할 수 없음.

## 6. 기존 경험과 프로젝트 연계

| 기존 학습·프로젝트 | 연계 가능 영역 |
|---|---|
| Terraform / AWS VPC / HQ·Branch Peering | AWS 네트워크·접근 제어 진단 |
| ALB / Route53 / Aurora RDS / EKS | 클라우드 서비스 보안 구성 점검 |
| Docker / Kubernetes / NFS / Ingress | 프라이빗 클라우드 및 컨테이너 보안 |
| Kali / Nmap / Wireshark / Snort | 공격·탐지 검증 및 증거 수집 |
| FortiWeb Reverse Proxy | WAF 정책 및 차단 검증 |
| AD / Enterprise Vault 특강 | Veritas 적용 영역 사전 이해 |

> 위 표는 기존 학습 경험을 토대로 한 **활용 가능성**이며, 공식 역할 분담 또는 필수 구축 범위는 아님.

## 7. 다음 준비 항목

1. 내일 팀원들과 역할·구축 범위 논의.
2. AWS Security Group, NACL, WAF의 기능·적용 위치 복습.
3. 실습 증거를 공격 전/후, 탐지 로그, 차단 로그, 정상 서비스 확인으로 나누어 보관.
4. Veritas 제품 종류와 프로젝트 요구사항 확인.
5. Docker/K8S 진단 체크리스트는 주제1 착수 전에 확정.

## 8. 오늘의 핵심 Q&A

**Q. SYN Flood가 탐지되면 서버가 다운된 것인가?**  
A. 아니다. 연결 실패율, 응답 시간, 자원 사용량 등 별도 증거가 필요하다.

**Q. IP Fragmentation 자체가 공격인가?**  
A. 아니다. 정상적인 네트워크 동작에서도 발생한다. 크기·빈도·패턴과 룰 조건을 함께 검토한다.

**Q. Snort와 WAF의 실습 결과는 어떻게 다른가?**  
A. Snort 로그는 탐지 증거이고, WAF의 차단 로그 및 요청 실패·정상 요청 성공은 방어 검증 증거가 된다.

**Q. 이번 프로젝트에서 가장 중요한 연결 고리는?**  
A. 기존에 구축한 클라우드 인프라를 대상으로 보안 통제를 적용하고, 공격·탐지·방어 결과를 증거로 제시하는 것.

---

**한 줄 정리:** 오늘은 Kali → Wireshark → Snort로 DoS 탐지 흐름을 복습했고, 12월 18일간 진행할 AWS·Veritas → 프라이빗 클라우드·Fortinet 보안 진단 프로젝트의 방향을 확인했다.


