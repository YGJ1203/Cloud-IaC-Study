# Cloud-IaC-Study Network Handbook Vol.1

<!-- markdownlint-disable MD013 MD025 MD026 MD033 -->

> Cisco Packet Tracer Edition — IOS CLI와 Simulation Mode로 배우는 패킷 흐름

![Edition](https://img.shields.io/badge/edition-Cisco%20Packet%20Tracer-blue)
![Level](https://img.shields.io/badge/level-beginner--intermediate-green)
![Focus](https://img.shields.io/badge/focus-CCNA%20fundamentals-orange)

---

## 이 판의 목적

이 책은 Linux 네트워크 명령을 Cisco Packet Tracer 환경에 억지로 적용하지 않는다. 라우터와 스위치에서는 Cisco IOS CLI를 사용하고, PC에서는 Packet Tracer의 Command Prompt를 사용하며, 패킷 분석은 Simulation Mode의 Event List와 PDU Details로 수행한다.

학습자는 하나의 기준 토폴로지를 반복 사용하면서 다음을 익힌다.

- Cisco IOS 명령 모드와 설정 저장
- Ethernet 스위칭, MAC 주소 테이블, ARP
- IPv4 주소와 서브넷 계산
- 정적 라우팅과 기본 경로
- VLAN, trunk, router-on-a-stick
- ICMP, TCP, UDP, DNS, DHCP
- 표준·확장 ACL
- Static NAT와 PAT
- Simulation Mode에서 계층별 PDU 분석
- Cisco 장비 중심 트러블슈팅과 면접 답변

## Packet Tracer의 성격과 한계

Packet Tracer는 Cisco의 교육용 네트워크 시뮬레이터다. 실제 IOS 전체를 에뮬레이션하지 않으며 장비 모델과 Packet Tracer 버전에 따라 지원 명령·프로토콜이 다를 수 있다.

이 책의 원칙:

1. Packet Tracer에서 널리 지원되는 IOS 명령을 우선 사용한다.
2. 실제 장비 전용 명령이나 플랫폼 의존 명령은 핵심 실습에서 제외한다.
3. Wireshark 대신 Simulation Mode의 OSI Model·Inbound PDU·Outbound PDU 화면을 사용한다.
4. 명령이 거부되면 오타뿐 아니라 선택한 장비 모델의 기능 지원 여부를 확인한다.
5. 실제 운영 장비에서 <code>debug</code>를 사용할 때는 부하 영향을 검토하지만, 이 책의 핵심 분석은 <code>show</code> 명령과 Simulation Mode로 수행한다.

## 권장 환경

- Cisco Packet Tracer 8.x 계열
- Router: Cisco 2911 두 대
- Switch: Cisco 2960 두 대
- End Device: PC 두 대
- 필요 장에서 Server, ISP Router 추가

> [!NOTE]
> 다른 라우터 모델에서는 인터페이스 이름이 <code>GigabitEthernet0/0</code> 대신 <code>GigabitEthernet0/0/0</code>처럼 보일 수 있다. 반드시 <code>show ip interface brief</code>로 실제 이름을 확인한 뒤 책의 인터페이스 이름을 바꿔 입력한다.

## 기준 토폴로지

~~~mermaid
flowchart LR
    A["PC-A<br>192.168.10.10/24"] --- S1["SW1<br>2960"]
    S1 --- R1["R1<br>192.168.10.1<br>10.0.12.1"]
    R1 --- R2["R2<br>10.0.12.2<br>192.168.20.1"]
    R2 --- S2["SW2<br>2960"]
    S2 --- B["PC-B<br>192.168.20.10/24"]
~~~

### 케이블 연결표

| 장비 A | 인터페이스 | 장비 B | 인터페이스 |
| --- | --- | --- | --- |
| PC-A | FastEthernet0 | SW1 | FastEthernet0/1 |
| SW1 | GigabitEthernet0/1 | R1 | GigabitEthernet0/0 |
| R1 | GigabitEthernet0/1 | R2 | GigabitEthernet0/0 |
| R2 | GigabitEthernet0/1 | SW2 | GigabitEthernet0/1 |
| SW2 | FastEthernet0/1 | PC-B | FastEthernet0 |

Packet Tracer의 Automatically Choose Connection Type을 사용해도 되지만, 학습을 위해 연결 인터페이스를 표와 대조한다.

### 주소 계획

| 구간 | 네트워크 | 장비 주소 |
| --- | --- | --- |
| LAN-A | 192.168.10.0/24 | R1 G0/0=192.168.10.1, PC-A=.10 |
| R1-R2 | 10.0.12.0/30 | R1 G0/1=.1, R2 G0/0=.2 |
| LAN-B | 192.168.20.0/24 | R2 G0/1=192.168.20.1, PC-B=.10 |

## 학습 흐름

각 장은 다음 구조를 따른다.

1. **개념**
2. **Topology**
3. **Configuration**
4. **Verification**
5. **Simulation Mode**
6. **Troubleshooting**
7. **배운 점**

---

## 목차

- [Part I. Packet Tracer와 Cisco IOS](#part-i-packet-tracer와-cisco-ios)
  - [1장. 작업 화면과 IOS CLI](#1장-작업-화면과-ios-cli)
  - [2장. 기준 토폴로지 구축](#2장-기준-토폴로지-구축)
- [Part II. 링크와 주소](#part-ii-링크와-주소)
  - [3장. Ethernet, MAC 주소 테이블, ARP](#3장-ethernet-mac-주소-테이블-arp)
  - [4장. IPv4와 서브넷팅](#4장-ipv4와-서브넷팅)
  - [5장. VLAN과 802.1Q trunk](#5장-vlan과-8021q-trunk)
- [Part III. 경로와 서비스](#part-iii-경로와-서비스)
  - [6장. 정적 라우팅, ICMP, traceroute](#6장-정적-라우팅-icmp-traceroute)
  - [7장. TCP, UDP, DNS, DHCP](#7장-tcp-udp-dns-dhcp)
  - [8장. ACL과 NAT](#8장-acl과-nat)
- [Part IV. 패킷 분석과 장애 해결](#part-iv-패킷-분석과-장애-해결)
  - [9장. Simulation Mode 패킷 분석](#9장-simulation-mode-패킷-분석)
  - [10장. 계층형 트러블슈팅](#10장-계층형-트러블슈팅)
  - [11장. 장애 주입 시나리오](#11장-장애-주입-시나리오)
  - [12장. 종합 프로젝트](#12장-종합-프로젝트)
- [Part V. 면접과 부록](#part-v-면접과-부록)

---

# Part I. Packet Tracer와 Cisco IOS

## 1장. 작업 화면과 IOS CLI

### 1.1 Packet Tracer의 세 가지 관찰 공간

| 공간 | 역할 | 이 책에서 하는 일 |
| --- | --- | --- |
| Logical Workspace | 논리 토폴로지 | 장비 배치, 케이블 연결, 링크 상태 확인 |
| Realtime Mode | 평상시 동작 | 설정, ping, 수렴 결과 확인 |
| Simulation Mode | 이벤트 단계별 재생 | ARP·ICMP·TCP·DNS 패킷의 계층별 분석 |

Realtime Mode에서는 프로토콜 이벤트가 즉시 처리된다. Simulation Mode에서는 Capture/Forward로 한 단계씩 진행하며 각 장비에서 PDU가 어떻게 처리되는지 볼 수 있다.

### 1.2 IOS 명령 모드

~~~text
Router>                         User EXEC
Router> enable
Router#                        Privileged EXEC
Router# configure terminal
Router(config)#                Global configuration
Router(config)# interface g0/0
Router(config-if)#             Interface configuration
Router(config-if)# exit
Router(config)# line console 0
Router(config-line)#           Line configuration
~~~

프롬프트는 현재 모드를 알려 준다.

| 프롬프트 | 모드 | 대표 작업 |
| --- | --- | --- |
| <code>></code> | User EXEC | 제한된 상태 확인 |
| <code>#</code> | Privileged EXEC | 전체 show, copy, clear |
| <code>(config)#</code> | Global config | 장비 전체 설정 |
| <code>(config-if)#</code> | Interface config | 인터페이스 주소·상태 |
| <code>(config-router)#</code> | Routing process | 동적 라우팅 |
| <code>(config-line)#</code> | Line config | console, VTY |

### 1.3 도움말과 명령 편집

~~~ios
Router# ?
Router# show ?
Router# show ip ?
Router(config)# interface ?
Router(config-if)# ip address ?
~~~

IOS의 문맥 도움말은 현재 이미지가 지원하는 명령을 확인하는 가장 정확한 첫 도구다.

유용한 키:

- Tab: 명령 완성
- <code>?</code>: 가능한 키워드 표시
- 위/아래 화살표: 명령 기록
- Ctrl+A / Ctrl+E: 줄 처음 / 끝
- Ctrl+Shift+6: 진행 중인 ping·traceroute 중단에 사용되는 경우가 많음

### 1.4 기본 설정 템플릿

R1:

~~~ios
Router> enable
Router# configure terminal
Router(config)# hostname R1
R1(config)# no ip domain-lookup
R1(config)# service password-encryption
R1(config)# banner motd #Authorized lab access only#
R1(config)# line console 0
R1(config-line)# logging synchronous
R1(config-line)# exec-timeout 0 0
R1(config-line)# exit
R1(config)# end
~~~

<code>no ip domain-lookup</code>은 잘못 입력한 명령을 호스트명으로 해석하며 오래 기다리는 현상을 줄인다. 실무의 DNS 기능을 끄라는 의미가 아니라 학습 콘솔의 오입력 처리를 조정하는 것이다.

### 1.5 running-config와 startup-config

~~~ios
R1# show running-config
R1# show startup-config
R1# copy running-config startup-config
Destination filename [startup-config]?
Building configuration...
[OK]
~~~

- running-config: 현재 RAM에서 적용 중인 설정
- startup-config: 재부팅 때 불러올 NVRAM 설정
- <code>copy running-config startup-config</code>: 현재 설정 저장

Packet Tracer 파일 자체를 저장하는 것과 IOS startup-config 저장은 별개다. <code>.pkt</code> 파일을 저장하고 장비 설정도 startup-config에 복사하는 습관을 들인다.

### 1.6 검증 명령의 역할

~~~ios
R1# show version
R1# show running-config
R1# show ip interface brief
R1# show interfaces description
R1# show ip route
R1# show arp
~~~

설정을 입력한 사실이 아니라 운영 상태를 검증한다.

~~~text
Interface              IP-Address      OK? Method Status                Protocol
GigabitEthernet0/0     192.168.10.1   YES manual up                    up
GigabitEthernet0/1     10.0.12.1      YES manual administratively down down
~~~

<code>administratively down</code>은 <code>shutdown</code> 상태다. <code>no shutdown</code>이 필요하다. Status up / Protocol down이면 물리 연결 너머의 데이터 링크 조건을 조사한다.

### 1.7 show 출력 필터

Packet Tracer가 선택한 IOS에서 지원한다면:

~~~ios
R1# show running-config | section interface
R1# show ip interface brief | include up
R1# show ip route | begin Gateway
~~~

지원되지 않으면 전체 출력을 확인한다. Packet Tracer는 실제 IOS의 모든 파이프 필터를 구현하지 않을 수 있다.

### 1.8 초기화 주의

학습 파일을 처음부터 다시 구성할 때:

~~~ios
R1# erase startup-config
R1# reload
~~~

스위치 VLAN 데이터베이스가 별도 파일로 남는 모델에서는 VLAN 상태도 확인해야 한다.

> [!CAUTION]
> 이 명령은 저장 설정을 지운다. 제출용 <code>.pkt</code>를 복사해 둔 뒤 실습 장비에서만 사용한다.

### 1.9 배운 점

- 프롬프트는 현재 IOS 명령 모드를 나타낸다.
- 설정 후에는 반드시 show 명령으로 운영 상태를 검증한다.
- Packet Tracer 파일 저장과 startup-config 저장은 서로 다른 작업이다.

---

## 2장. 기준 토폴로지 구축

### 2.1 구축 순서

1. 장비를 Logical Workspace에 배치한다.
2. 표의 인터페이스를 케이블로 연결한다.
3. PC 주소를 설정한다.
4. 라우터 인터페이스를 설정하고 <code>no shutdown</code>한다.
5. 직접 연결 구간부터 ping한다.
6. 정적 경로는 6장에서 추가한다.

### 2.2 PC-A 설정

PC-A → Desktop → IP Configuration:

| 항목 | 값 |
| --- | --- |
| IPv4 Address | 192.168.10.10 |
| Subnet Mask | 255.255.255.0 |
| Default Gateway | 192.168.10.1 |
| DNS Server | 비워 둠 |

Command Prompt:

~~~cmd
PC> ipconfig

FastEthernet0 Connection:(default port)
   Link-local IPv6 Address.........: FE80::...
   IP Address......................: 192.168.10.10
   Subnet Mask.....................: 255.255.255.0
   Default Gateway.................: 192.168.10.1
~~~

### 2.3 PC-B 설정

| 항목 | 값 |
| --- | --- |
| IPv4 Address | 192.168.20.10 |
| Subnet Mask | 255.255.255.0 |
| Default Gateway | 192.168.20.1 |

### 2.4 R1 인터페이스 설정

~~~ios
R1# configure terminal
R1(config)# interface gigabitEthernet0/0
R1(config-if)# description LAN-A_to_SW1
R1(config-if)# ip address 192.168.10.1 255.255.255.0
R1(config-if)# no shutdown
R1(config-if)# exit
R1(config)# interface gigabitEthernet0/1
R1(config-if)# description TRANSIT_to_R2
R1(config-if)# ip address 10.0.12.1 255.255.255.252
R1(config-if)# no shutdown
R1(config-if)# end
R1# copy running-config startup-config
~~~

### 2.5 R2 인터페이스 설정

~~~ios
R2# configure terminal
R2(config)# interface gigabitEthernet0/0
R2(config-if)# description TRANSIT_to_R1
R2(config-if)# ip address 10.0.12.2 255.255.255.252
R2(config-if)# no shutdown
R2(config-if)# exit
R2(config)# interface gigabitEthernet0/1
R2(config-if)# description LAN-B_to_SW2
R2(config-if)# ip address 192.168.20.1 255.255.255.0
R2(config-if)# no shutdown
R2(config-if)# end
R2# copy running-config startup-config
~~~

### 2.6 1차 검증

R1:

~~~ios
R1# show ip interface brief
R1# show interfaces description
R1# ping 10.0.12.2
R1# ping 192.168.10.10
~~~

PC-A:

~~~cmd
PC> ping 192.168.10.1
~~~

PC-B:

~~~cmd
PC> ping 192.168.20.1
~~~

처음 ping의 첫 Echo가 실패할 수 있다. ARP 주소 해석이 선행되기 때문이다. 반복 ping이 성공하면 최초 실패와 지속 실패를 구분한다.

### 2.7 현재 왜 종단 간 ping이 실패하는가

R1은 다음 네트워크만 안다.

~~~ios
R1# show ip route

C    10.0.12.0/30 is directly connected, GigabitEthernet0/1
L    10.0.12.1/32 is directly connected, GigabitEthernet0/1
C    192.168.10.0/24 is directly connected, GigabitEthernet0/0
L    192.168.10.1/32 is directly connected, GigabitEthernet0/0
~~~

R1에는 <code>192.168.20.0/24</code> 경로가 없고 R2에는 <code>192.168.10.0/24</code> 경로가 없다. 링크와 IP 주소만 설정했다고 원격 네트워크 경로가 자동으로 생기지는 않는다.

### 2.8 Troubleshooting

링크가 빨갛거나 인터페이스가 down이면:

~~~ios
R1# show ip interface brief
R1# show interfaces gigabitEthernet0/0
R1# show running-config interface gigabitEthernet0/0
~~~

확인:

- 올바른 케이블인가?
- 실제 연결한 인터페이스를 설정했는가?
- <code>no shutdown</code>했는가?
- 양쪽 주소가 같은 서브넷인가?
- 중복 주소가 없는가?

### 2.9 배운 점

- 직접 연결 경로는 인터페이스가 up/up이고 주소가 설정될 때 라우팅 테이블에 나타난다.
- PC의 기본 게이트웨이는 같은 LAN의 라우터 주소여야 한다.
- 종단 간 통신에는 중간 라우터가 원격 네트워크의 경로를 알아야 한다.

---

# Part II. 링크와 주소

## 3장. Ethernet, MAC 주소 테이블, ARP

### 3.1 스위치가 학습하는 것

스위치는 수신 프레임의 출발지 MAC을 보고 MAC 주소 테이블을 학습하고, 목적지 MAC에 따라 출력 포트를 선택한다.

SW1:

~~~ios
SW1> enable
SW1# show mac address-table
SW1# show mac address-table dynamic
~~~

예시:

~~~text
          Mac Address Table
-------------------------------------------
Vlan    Mac Address       Type        Ports
----    -----------       --------    -----
   1    0001.632a.1111    DYNAMIC     Fa0/1
   1    00d0.ba8c.2222    DYNAMIC     Gi0/1
~~~

해석:

- VLAN 1에서 두 MAC을 동적으로 학습했다.
- PC-A MAC은 Fa0/1 뒤에 있다.
- R1 G0/0 MAC은 Gi0/1 뒤에 있다.
- 목적지 MAC을 아직 모르면 같은 VLAN의 다른 포트로 unknown unicast flooding한다.

### 3.2 PC와 라우터의 ARP 확인

PC-A:

~~~cmd
PC> arp -a
~~~

R1:

~~~ios
R1# show arp
R1# show ip arp
~~~

Packet Tracer IOS 이미지에 따라 둘 중 하나를 사용한다.

예시:

~~~text
Protocol  Address         Age (min)  Hardware Addr   Type   Interface
Internet  192.168.10.1           -   00D0.BA8C.2222  ARPA   GigabitEthernet0/0
Internet  192.168.10.10          2   0001.632A.1111  ARPA   GigabitEthernet0/0
~~~

Age의 <code>-</code>는 장비 자신의 인터페이스 주소처럼 로컬 항목일 수 있다.

### 3.3 같은 서브넷 패킷 흐름

PC-A가 같은 LAN의 다른 PC에 보낸다면:

1. PC-A는 서브넷 마스크로 상대가 on-link라고 판단한다.
2. 상대 IP의 MAC을 ARP Request로 묻는다.
3. 스위치는 ARP 브로드캐스트를 VLAN 내에 전달한다.
4. 대상 PC가 ARP Reply한다.
5. PC-A는 대상 PC MAC으로 유니캐스트 프레임을 보낸다.
6. 기본 게이트웨이는 데이터 경로에 참여하지 않는다.

### 3.4 다른 서브넷 패킷 흐름

PC-A가 PC-B에 보낼 때:

1. PC-A는 <code>192.168.20.10</code>이 /24 로컬 서브넷 밖이라고 판단한다.
2. PC-A는 기본 게이트웨이 <code>192.168.10.1</code>의 MAC을 ARP한다.
3. Ethernet 목적지 MAC은 R1, IP 목적지는 PC-B다.
4. R1은 L2 헤더를 제거하고 라우팅 테이블을 조회한다.
5. R1-R2 링크에서 새로운 MAC 헤더를 만든다.
6. R2는 LAN-B에서 PC-B의 MAC을 ARP한다.

### 3.5 Simulation Mode로 ARP 보기

1. Realtime Mode에서 PC-A Command Prompt를 연다.
2. 가능하면 <code>arp -d</code>로 PC ARP 캐시를 지운다. 지원되지 않으면 장비 전원을 껐다 켜거나 새 토폴로지 상태를 사용한다.
3. Simulation Mode로 전환한다.
4. Event List Filters → Edit Filters에서 ARP와 ICMP만 선택한다.
5. PC-A에서 <code>ping 192.168.10.1</code>을 실행한다.
6. Capture/Forward를 한 번씩 누른다.
7. Event List의 색상 봉투를 클릭한다.
8. OSI Model, Inbound PDU Details, Outbound PDU Details를 확인한다.

기록:

| 이벤트 | Ethernet 목적지 | ARP Target IP |
| --- | --- | --- |
| ARP Request | FFFF.FFFF.FFFF | 192.168.10.1 |
| ARP Reply | PC-A MAC | 192.168.10.10 |
| ICMP Echo | R1 G0/0 MAC | 해당 없음 |

### 3.6 MAC과 IP의 홉별 변화

PC-A → R1 → R2 → PC-B 경로:

| 구간 | Source MAC | Destination MAC | Source IP | Destination IP |
| --- | --- | --- | --- | --- |
| PC-A→R1 | PC-A | R1 G0/0 | 192.168.10.10 | 192.168.20.10 |
| R1→R2 | R1 G0/1 | R2 G0/0 | 192.168.10.10 | 192.168.20.10 |
| R2→PC-B | R2 G0/1 | PC-B | 192.168.10.10 | 192.168.20.10 |

NAT가 없으므로 IP는 유지되고 MAC은 링크마다 바뀐다.

### 3.7 캐시를 지울 때 주의

~~~ios
SW1# clear mac address-table dynamic
R1# clear arp-cache
~~~

Packet Tracer 이미지가 명령을 지원하지 않으면 문맥 도움말을 확인한다. 캐시 삭제 직후에는 ARP와 MAC 학습이 다시 발생하므로 첫 패킷의 지연이나 실패가 정상일 수 있다.

### 3.8 Troubleshooting

PC-A가 게이트웨이에 ping하지 못할 때:

~~~ios
R1# show ip interface brief
R1# show arp
SW1# show interfaces status
SW1# show mac address-table
~~~

Packet Tracer의 2960에서 <code>show interfaces status</code> 지원이 제한되면 <code>show interfaces</code>와 <code>show mac address-table</code>을 사용한다.

Simulation Mode에서:

- ARP Request가 PC-A에서 나오는가?
- SW1이 Fa0/1에서 받고 Gi0/1로 보내는가?
- R1이 요청을 받고 Reply하는가?
- Reply가 PC-A까지 돌아오는가?

### 3.9 배운 점

- 스위치는 출발지 MAC으로 학습하고 목적지 MAC으로 전달한다.
- ARP는 같은 링크의 다음 홉 IP를 MAC에 매핑한다.
- Simulation Mode에서는 ARP와 ICMP 이벤트를 분리해 패킷 순서를 볼 수 있다.

---

## 4장. IPv4와 서브넷팅

### 4.1 Cisco IOS의 마스크 입력

인터페이스 주소 설정에는 dotted-decimal subnet mask를 입력한다.

~~~ios
R1(config-if)# ip address 192.168.10.1 255.255.255.0
~~~

정적 경로의 목적지에도 일반적으로 네트워크와 마스크를 입력한다.

~~~ios
R1(config)# ip route 192.168.20.0 255.255.255.0 10.0.12.2
~~~

ACL에서는 반대로 wildcard mask를 사용하는 경우가 많다.

~~~ios
R1(config)# access-list 10 permit 192.168.10.0 0.0.0.255
~~~

<code>0.0.0.255</code>는 서브넷 마스크가 아니다. 해당 비트에서 “비교하지 않아도 되는 부분”을 나타내는 wildcard mask다.

### 4.2 프리픽스 표

| CIDR | Subnet mask | Wildcard mask | 전체 주소 | 일반 호스트 |
| ---: | --- | --- | ---: | ---: |
| /24 | 255.255.255.0 | 0.0.0.255 | 256 | 254 |
| /25 | 255.255.255.128 | 0.0.0.127 | 128 | 126 |
| /26 | 255.255.255.192 | 0.0.0.63 | 64 | 62 |
| /27 | 255.255.255.224 | 0.0.0.31 | 32 | 30 |
| /28 | 255.255.255.240 | 0.0.0.15 | 16 | 14 |
| /29 | 255.255.255.248 | 0.0.0.7 | 8 | 6 |
| /30 | 255.255.255.252 | 0.0.0.3 | 4 | 2 |

Wildcard mask는 각 옥텟에서 <code>255 - subnet mask</code>로 계산할 수 있다.

### 4.3 /30 transit 구간

<code>10.0.12.0/30</code>:

- 네트워크: 10.0.12.0
- R1: 10.0.12.1
- R2: 10.0.12.2
- 브로드캐스트: 10.0.12.3

잘못된 예:

~~~ios
R2(config-if)# ip address 10.0.12.3 255.255.255.252
Bad mask /30 for address 10.0.12.3
~~~

브로드캐스트 주소를 인터페이스에 할당할 수 없다.

### 4.4 VLSM 설계

<code>172.16.0.0/24</code>를 다음 요구로 나눈다.

| 구간 | 필요 호스트 | 프리픽스 | 할당 |
| --- | ---: | ---: | --- |
| Users | 100 | /25 | 172.16.0.0/25 |
| Servers | 50 | /26 | 172.16.0.128/26 |
| Management | 20 | /27 | 172.16.0.192/27 |
| Transit | 2 | /30 | 172.16.0.224/30 |

큰 서브넷부터 정렬해 주소 단편화를 줄인다.

### 4.5 IOS에서 주소 충돌·중복 확인

~~~ios
R1# show ip interface brief
R1# show running-config | section interface
R1# show arp
~~~

Packet Tracer는 실제 네트워크의 모든 duplicate address detection 동작을 재현하지 않을 수 있다. 토폴로지의 주소 계획표와 실제 설정을 함께 비교한다.

### 4.6 프리픽스 불일치 장애

PC-A가 <code>192.168.10.10/16</code>, R1이 <code>192.168.10.1/24</code>라고 하자. PC-A는 <code>192.168.20.10</code>도 같은 /16 링크라고 잘못 판단해 기본 게이트웨이가 아니라 PC-B의 MAC을 ARP한다. 라우터 너머의 PC-B는 ARP 브로드캐스트를 받을 수 없으므로 실패한다.

Simulation Mode에서 PC-A가 누구의 MAC을 ARP하는지 보면 프리픽스 판단을 역으로 알 수 있다.

### 4.7 연습문제

1. <code>192.168.50.77/26</code>의 네트워크와 브로드캐스트는?
2. /27의 subnet mask와 wildcard mask는?
3. 호스트 28대에 필요한 최소 일반 서브넷은?
4. <code>10.0.12.0/30</code>에서 사용 가능한 두 주소는?

<details>
<summary>정답</summary>

1. 네트워크 192.168.50.64, 브로드캐스트 192.168.50.127.
2. 255.255.255.224, 0.0.0.31.
3. /27. 일반 호스트 30개.
4. 10.0.12.1과 10.0.12.2.

</details>

### 4.8 배운 점

- 인터페이스·정적 경로의 subnet mask와 ACL의 wildcard mask를 구분한다.
- /30은 두 라우터 사이 transit 실습에 적합하다.
- 잘못된 PC 마스크는 ARP 대상 자체를 바꿔 원격 통신을 실패시킨다.

---

## 5장. VLAN과 802.1Q trunk

### 5.1 VLAN의 목적

VLAN은 하나의 스위치 인프라를 여러 L2 브로드캐스트 도메인으로 분리한다.

- Access port: 한 VLAN의 일반 엔드 장비 연결
- Trunk port: 여러 VLAN 프레임 전달
- 802.1Q tag: VLAN ID를 프레임에 표시
- Inter-VLAN routing: 서로 다른 VLAN 사이의 L3 통신

VLAN ID와 IP 서브넷은 같은 개념은 아니지만, 실무 설계에서는 보통 VLAN 하나에 서브넷 하나를 대응한다.

### 5.2 별도 실습 토폴로지

~~~mermaid
flowchart LR
    U["PC-USER<br>192.168.10.10/24<br>VLAN 10"] --- SW["SW1<br>2960"]
    S["PC-SERVER<br>192.168.20.10/24<br>VLAN 20"] --- SW
    SW ---|"802.1Q trunk"| R["R1<br>Router-on-a-stick"]
~~~

연결:

| 장비 | 포트 | 상대 |
| --- | --- | --- |
| PC-USER | Fa0 | SW1 Fa0/1 |
| PC-SERVER | Fa0 | SW1 Fa0/2 |
| SW1 | Gi0/1 | R1 Gi0/0 |

### 5.3 VLAN 생성과 access port

~~~ios
SW1> enable
SW1# configure terminal
SW1(config)# hostname SW1
SW1(config)# vlan 10
SW1(config-vlan)# name USERS
SW1(config-vlan)# exit
SW1(config)# vlan 20
SW1(config-vlan)# name SERVERS
SW1(config-vlan)# exit
SW1(config)# interface fastEthernet0/1
SW1(config-if)# description PC_USER
SW1(config-if)# switchport mode access
SW1(config-if)# switchport access vlan 10
SW1(config-if)# spanning-tree portfast
SW1(config-if)# exit
SW1(config)# interface fastEthernet0/2
SW1(config-if)# description PC_SERVER
SW1(config-if)# switchport mode access
SW1(config-if)# switchport access vlan 20
SW1(config-if)# spanning-tree portfast
SW1(config-if)# end
~~~

PortFast는 엔드 호스트용 access port에 적용한다. 스위치 간 링크에 무분별하게 적용하면 L2 loop 보호를 약화시킬 수 있다.

### 5.4 trunk 설정

~~~ios
SW1# configure terminal
SW1(config)# interface gigabitEthernet0/1
SW1(config-if)# description TRUNK_to_R1
SW1(config-if)# switchport mode trunk
SW1(config-if)# switchport trunk allowed vlan 10,20
SW1(config-if)# no shutdown
SW1(config-if)# end
~~~

2960 계열은 802.1Q만 사용하므로 <code>switchport trunk encapsulation dot1q</code> 명령이 없을 수 있다. 명령을 억지로 입력하지 않는다.

검증:

~~~ios
SW1# show vlan brief
SW1# show interfaces trunk
SW1# show interfaces gigabitEthernet0/1 switchport
~~~

예시:

~~~text
Port        Mode         Encapsulation  Status        Native vlan
Gi0/1       on           802.1q         trunking      1

Port        Vlans allowed on trunk
Gi0/1       10,20
~~~

### 5.5 Router-on-a-stick

물리 인터페이스 하나에 VLAN별 subinterface를 만든다.

~~~ios
R1# configure terminal
R1(config)# interface gigabitEthernet0/0
R1(config-if)# no ip address
R1(config-if)# no shutdown
R1(config-if)# exit
R1(config)# interface gigabitEthernet0/0.10
R1(config-subif)# encapsulation dot1Q 10
R1(config-subif)# ip address 192.168.10.1 255.255.255.0
R1(config-subif)# description VLAN10_GATEWAY
R1(config-subif)# exit
R1(config)# interface gigabitEthernet0/0.20
R1(config-subif)# encapsulation dot1Q 20
R1(config-subif)# ip address 192.168.20.1 255.255.255.0
R1(config-subif)# description VLAN20_GATEWAY
R1(config-subif)# end
~~~

PC-USER 기본 게이트웨이는 192.168.10.1, PC-SERVER 기본 게이트웨이는 192.168.20.1로 설정한다.

### 5.6 검증

~~~ios
R1# show ip interface brief
R1# show running-config | section GigabitEthernet0/0
R1# show ip route connected
~~~

Packet Tracer 이미지에서 <code>show ip route connected</code>가 지원되지 않으면 <code>show ip route</code>를 사용한다.

PC-USER:

~~~cmd
PC> ping 192.168.10.1
PC> ping 192.168.20.1
PC> ping 192.168.20.10
~~~

### 5.7 패킷 흐름

PC-USER가 PC-SERVER로 보낼 때:

1. PC-USER는 목적지가 다른 /24라고 판단한다.
2. VLAN 10 게이트웨이 MAC을 ARP한다.
3. access port에서 들어온 프레임은 trunk로 나갈 때 VLAN 10 tag를 가진다.
4. R1 G0/0.10에서 역캡슐화하고 L3 경로를 선택한다.
5. R1 G0/0.20에서 VLAN 20 tag를 사용해 SW1에 돌려보낸다.
6. SW1은 PC-SERVER access port로 내보내며 엔드 호스트에는 일반 untagged 프레임을 전달한다.

### 5.8 Simulation Mode

필터를 ARP와 ICMP로 제한하고 PC-USER에서 PC-SERVER로 ping한다.

PDU Details에서 확인:

- PC-USER는 PC-SERVER MAC이 아니라 게이트웨이 MAC을 사용한다.
- SW1 trunk 방향 프레임에 802.1Q 정보가 표시되는지 확인한다.
- R1에서 inbound VLAN 10과 outbound VLAN 20이 달라진다.
- IP source/destination은 유지된다.

### 5.9 장애 사례

#### Access VLAN 오류

~~~ios
SW1(config)# interface fastEthernet0/2
SW1(config-if)# switchport access vlan 10
~~~

PC-SERVER가 VLAN 10에 잘못 들어간다. IP는 192.168.20.10/24이므로 VLAN 20 게이트웨이와 ARP할 수 없다.

#### Allowed VLAN 누락

~~~ios
SW1(config)# interface gigabitEthernet0/1
SW1(config-if)# switchport trunk allowed vlan 10
~~~

VLAN 20 트래픽이 trunk를 통과하지 못한다.

#### Subinterface encapsulation 오류

~~~ios
R1(config)# interface gigabitEthernet0/0.20
R1(config-subif)# encapsulation dot1Q 30
~~~

스위치 VLAN 20 tag와 라우터 subinterface VLAN이 일치하지 않는다.

조사 명령:

~~~ios
SW1# show vlan brief
SW1# show interfaces trunk
SW1# show interfaces gigabitEthernet0/1 switchport
R1# show ip interface brief
R1# show running-config | section GigabitEthernet0/0
~~~

### 5.10 배운 점

- Access port는 한 VLAN의 엔드 장비, trunk는 여러 VLAN을 운반한다.
- Router-on-a-stick은 subinterface와 802.1Q tag를 매핑한다.
- VLAN 장애는 access VLAN, allowed VLAN, tag 번호를 양쪽에서 대조한다.

---

# Part III. 경로와 서비스

## 6장. 정적 라우팅, ICMP, traceroute

### 6.1 정적 경로 설정

기준 토폴로지로 돌아간다.

R1:

~~~ios
R1# configure terminal
R1(config)# ip route 192.168.20.0 255.255.255.0 10.0.12.2
R1(config)# end
~~~

R2:

~~~ios
R2# configure terminal
R2(config)# ip route 192.168.10.0 255.255.255.0 10.0.12.1
R2(config)# end
~~~

반환 경로까지 있어야 한다. R1에 forward 경로만 추가하고 R2의 return 경로를 빼면 요청이 도착해도 응답이 PC-A로 돌아오지 못한다.

### 6.2 라우팅 테이블 해석

~~~ios
R1# show ip route
~~~

~~~text
Codes: L - local, C - connected, S - static, R - RIP, O - OSPF

Gateway of last resort is not set

     10.0.0.0/8 is variably subnetted, 2 subnets, 2 masks
C       10.0.12.0/30 is directly connected, GigabitEthernet0/1
L       10.0.12.1/32 is directly connected, GigabitEthernet0/1
S    192.168.20.0/24 [1/0] via 10.0.12.2
~~~

- <code>S</code>: static route
- <code>[1/0]</code>: administrative distance 1, metric 0
- <code>via 10.0.12.2</code>: next hop
- connected와 local 경로는 인터페이스 상태와 주소에서 생성된다.

### 6.3 가장 긴 프리픽스 일치

~~~ios
R1(config)# ip route 192.168.0.0 255.255.0.0 10.0.12.2
R1(config)# ip route 192.168.20.0 255.255.255.0 10.0.12.2
~~~

목적지 192.168.20.10에는 /16과 /24가 모두 일치하지만 더 긴 /24가 선택된다.

특정 목적지 경로:

~~~ios
R1# show ip route 192.168.20.10
~~~

### 6.4 기본 경로

말단 라우터가 모든 미지의 목적지를 한 ISP 방향으로 보낼 때:

~~~ios
R1(config)# ip route 0.0.0.0 0.0.0.0 10.0.12.2
~~~

검증:

~~~ios
R1# show ip route static
R1# show ip route 0.0.0.0
~~~

출력:

~~~text
S*   0.0.0.0/0 [1/0] via 10.0.12.2
~~~

별표는 candidate default를 나타낸다.

### 6.5 ping 출력

~~~ios
R1# ping 10.0.12.2

Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 10.0.12.2, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 0/0/1 ms
~~~

기호:

| 기호 | 일반 의미 |
| --- | --- |
| <code>!</code> | Echo Reply 수신 |
| <code>.</code> | timeout |
| <code>U</code> | Destination Unreachable |

Packet Tracer의 시뮬레이션 시간은 실제 네트워크 성능 측정값과 같지 않다. 지연 수치보다 도달성과 패킷 흐름 학습에 집중한다.

### 6.6 Extended ping

IOS에서 <code>ping</code>만 입력하면 대화형 확장 ping을 지원하는 이미지가 있다.

~~~text
R1# ping
Protocol [ip]:
Target IP address: 192.168.20.10
Repeat count [5]:
Datagram size [100]:
Timeout in seconds [2]:
Extended commands [n]: y
Source address or interface: 192.168.10.1
~~~

출발지 주소를 고정해 특정 반환 경로를 시험할 수 있다. Packet Tracer의 선택 이미지가 확장 옵션을 모두 구현하지 않을 수 있다.

### 6.7 traceroute

PC-A:

~~~cmd
PC> tracert 192.168.20.10
~~~

Router:

~~~ios
R1# traceroute 192.168.20.10
~~~

traceroute는 TTL을 증가시키며 중간 라우터의 ICMP Time Exceeded를 유도한다.

~~~text
  1   192.168.10.1
  2   10.0.12.2
  3   192.168.20.10
~~~

PC 도구와 IOS 도구의 탐색 방식·표시는 다를 수 있다.

### 6.8 Simulation Mode

PC-A에서 PC-B로 ping하고 ARP와 ICMP만 표시한다.

R1에서 PDU를 열어 확인:

- Inbound source/destination IP
- Inbound source/destination MAC
- TTL
- 라우팅 결정 후 outbound 인터페이스
- Outbound source/destination MAC
- 감소한 TTL

### 6.9 Troubleshooting 절차

~~~ios
R1# show ip interface brief
R1# show ip route
R1# show ip route 192.168.20.10
R1# show arp
R1# ping 10.0.12.2
R1# ping 192.168.20.1
R1# traceroute 192.168.20.10
~~~

순서:

1. 출력 인터페이스가 up/up인가?
2. next hop이 직접 연결 구간에 있는가?
3. next hop ping이 되는가?
4. 목적지 네트워크 경로가 있는가?
5. 반대 라우터에 반환 경로가 있는가?
6. PC 기본 게이트웨이가 맞는가?

### 6.10 배운 점

- 정적 경로는 목적지 네트워크, 마스크, next hop을 지정한다.
- 요청 경로와 반환 경로가 모두 있어야 한다.
- Simulation Mode에서 라우터의 TTL 감소와 L2 헤더 교체를 확인할 수 있다.

---

## 7장. TCP, UDP, DNS, DHCP

### 7.1 Packet Tracer에서 전송 계층 보기

Packet Tracer PC의 Web Browser와 Server의 HTTP 서비스를 이용하면 TCP 3-way handshake와 HTTP 흐름을 Simulation Mode에서 볼 수 있다.

~~~mermaid
sequenceDiagram
    participant PC as Client PC
    participant R as Routers
    participant S as PT Server
    PC->>R: TCP SYN
    R->>S: TCP SYN
    S-->>PC: TCP SYN ACK
    PC->>S: TCP ACK
    PC->>S: HTTP GET
    S-->>PC: HTTP response
~~~

### 7.2 Server 추가

LAN-B에 Server-PT를 추가하고 SW2 Fa0/2에 연결한다.

Server → Desktop → IP Configuration:

| 항목 | 값 |
| --- | --- |
| IP | 192.168.20.100 |
| Mask | 255.255.255.0 |
| Gateway | 192.168.20.1 |
| DNS | 192.168.20.100 |

Server → Services:

- HTTP: On
- DNS: On
- DNS record: <code>www.lab.local</code> → <code>192.168.20.100</code>

PC-A DNS Server를 192.168.20.100으로 설정한다.

### 7.3 DNS 검증

PC-A:

~~~cmd
PC> nslookup www.lab.local
Server: [192.168.20.100]
Address: 192.168.20.100

Name: www.lab.local
Address: 192.168.20.100
~~~

PC-A → Desktop → Web Browser:

~~~text
http://www.lab.local
~~~

DNS가 실패하면 IP URL로 비교한다.

~~~text
http://192.168.20.100
~~~

IP URL 성공 + 이름 URL 실패면 DNS 설정과 서비스 레코드를 우선 조사한다.

### 7.4 Simulation Mode에서 DNS와 HTTP

1. Simulation Mode로 전환한다.
2. Edit Filters에서 DNS, TCP, HTTP만 선택한다.
3. PC-A Web Browser에서 <code>http://www.lab.local</code>을 연다.
4. Capture/Forward를 진행한다.

예상 이벤트:

1. DNS query
2. DNS response
3. TCP SYN
4. TCP SYN/ACK
5. TCP ACK
6. HTTP request
7. HTTP response

PDU Details에서 UDP/TCP source port와 destination port를 비교한다.

### 7.5 TCP 실패 패턴

| 관찰 | 해석 방향 |
| --- | --- |
| DNS 응답 이후 TCP SYN 생성 | 이름 해석 완료, 연결 단계 진입 |
| SYN이 Server까지 도착하지 않음 | 경로 또는 ACL |
| SYN 도착 후 응답 없음 | 서비스 상태 또는 Server 설정 |
| TCP 연결 후 HTTP 실패 | HTTP 서비스·요청·응답 확인 |

Packet Tracer는 실제 운영체제의 모든 TCP 상태와 재전송 타이머를 동일하게 재현하지 않는다. 계층 순서와 필드 관계를 학습하는 데 사용한다.

### 7.6 라우터 DHCP Server

R1이 LAN-A PC에 주소를 할당하도록 구성한다.

~~~ios
R1# configure terminal
R1(config)# ip dhcp excluded-address 192.168.10.1 192.168.10.20
R1(config)# ip dhcp pool LAN_A
R1(dhcp-config)# network 192.168.10.0 255.255.255.0
R1(dhcp-config)# default-router 192.168.10.1
R1(dhcp-config)# dns-server 192.168.20.100
R1(dhcp-config)# domain-name lab.local
R1(dhcp-config)# end
~~~

PC-A → IP Configuration → DHCP를 선택한다.

검증:

~~~ios
R1# show ip dhcp binding
R1# show ip dhcp pool
~~~

PC-A:

~~~cmd
PC> ipconfig /all
~~~

Packet Tracer PC 명령 지원에 따라 출력 항목이 제한될 수 있다.

### 7.7 DHCP DORA 분석

Simulation Mode에서 DHCP와 ARP만 표시하고 PC-A의 DHCP 버튼을 다시 누른다.

| 순서 | 메시지 | 주요 의미 |
| ---: | --- | --- |
| 1 | DHCP Discover | 클라이언트가 서버 탐색 |
| 2 | DHCP Offer | 서버가 주소 제안 |
| 3 | DHCP Request | 클라이언트가 선택 요청 |
| 4 | DHCP ACK | 임대 확정 |

초기 클라이언트는 주소와 서버 위치를 모르므로 브로드캐스트가 사용된다.

### 7.8 다른 서브넷의 DHCP와 relay

DHCP Server가 LAN-B에 있고 PC-A가 LAN-A에 있으면 R1 LAN-A 인터페이스에 helper를 설정한다.

~~~ios
R1(config)# interface gigabitEthernet0/0
R1(config-if)# ip helper-address 192.168.20.100
~~~

Server-PT의 DHCP 서비스에서 LAN-A용 pool을 만든다.

필수 값:

- Pool name
- Default gateway 192.168.10.1
- DNS server 192.168.20.100
- Start IP
- Subnet mask
- Maximum users

relay가 없으면 라우터가 PC-A의 DHCP 브로드캐스트를 다른 서브넷으로 전달하지 않는다.

### 7.9 DNS/DHCP Troubleshooting

~~~ios
R1# show running-config | section dhcp
R1# show ip dhcp binding
R1# show ip interface brief
R1# show ip route 192.168.20.100
~~~

확인:

- DHCP pool의 network와 mask가 맞는가?
- default-router가 해당 서브넷의 라우터 주소인가?
- excluded-address가 전체 pool을 막지 않았는가?
- relay 주소로 가는 경로가 있는가?
- Server-PT 서비스가 On인가?
- PC가 Static이 아니라 DHCP로 선택됐는가?

### 7.10 배운 점

- Packet Tracer에서는 DNS→TCP→HTTP 이벤트 순서를 시각적으로 분석할 수 있다.
- DHCP는 주소뿐 아니라 게이트웨이와 DNS 정보를 전달한다.
- 다른 서브넷 DHCP에는 relay가 필요하다.

---

## 8장. ACL과 NAT

### 8.1 ACL의 처리 원칙

Cisco IOS ACL은 위에서 아래로 순서대로 평가하고 처음 일치한 항목의 permit/deny를 적용한다. 끝에는 표시되지 않는 implicit deny가 있다.

좋은 설계 절차:

1. 어떤 source가
2. 어떤 destination의
3. 어떤 protocol/port에
4. 어느 방향으로
5. 허용·거부되어야 하는지 문장으로 쓴다.
6. 인터페이스와 in/out 방향을 결정한다.

### 8.2 표준 ACL

LAN-A만 관리 네트워크로 허용하는 예:

~~~ios
R2(config)# access-list 10 permit 192.168.10.0 0.0.0.255
R2(config)# access-list 10 deny any
~~~

표준 ACL은 주로 source IPv4만 검사한다. 목적지를 구분하지 못하므로 일반적으로 차단하려는 목적지 가까이에 배치하는 원칙을 배운다.

### 8.3 확장 ACL

LAN-A에서 Server 192.168.20.100의 HTTP와 ICMP만 허용:

~~~ios
R1(config)# ip access-list extended LAN_A_POLICY
R1(config-ext-nacl)# permit tcp 192.168.10.0 0.0.0.255 host 192.168.20.100 eq 80
R1(config-ext-nacl)# permit icmp 192.168.10.0 0.0.0.255 host 192.168.20.100
R1(config-ext-nacl)# deny ip any any
R1(config-ext-nacl)# exit
R1(config)# interface gigabitEthernet0/0
R1(config-if)# ip access-group LAN_A_POLICY in
~~~

확장 ACL은 source, destination, protocol, port를 구분할 수 있어 일반적으로 source 가까이에 배치한다.

### 8.4 ACL 검증

~~~ios
R1# show access-lists
R1# show ip interface gigabitEthernet0/0
R1# show running-config interface gigabitEthernet0/0
~~~

예시:

~~~text
Extended IP access list LAN_A_POLICY
    10 permit tcp 192.168.10.0 0.0.0.255 host 192.168.20.100 eq www (3 match(es))
    20 permit icmp 192.168.10.0 0.0.0.255 host 192.168.20.100 (5 match(es))
    30 deny ip any any (2 match(es))
~~~

재현할 때 match counter가 증가하는 ACE를 보면 실제로 어느 규칙이 적용됐는지 확인할 수 있다.

### 8.5 in과 out

- in: 패킷이 해당 인터페이스로 들어온 직후
- out: 라우팅 결과 해당 인터페이스로 나가기 직전

“트래픽이 R1을 기준으로 어느 인터페이스에 들어와 어느 인터페이스로 나가는가”를 화살표로 그린다. PC 관점의 업로드/다운로드 표현과 혼동하지 않는다.

### 8.6 ACL 장애 분석

증상: ping은 허용했지만 웹은 실패.

~~~ios
R1# show access-lists LAN_A_POLICY
R1# show ip interface gigabitEthernet0/0
~~~

Simulation Mode:

1. ICMP와 TCP/HTTP를 각각 시험한다.
2. R1에서 PDU가 dropped로 표시되는지 본다.
3. OSI Model의 처리 설명을 읽는다.
4. ACL counter와 같은 재현을 연결한다.

### 8.7 NAT 실습 토폴로지

R2의 LAN-B 쪽을 inside, 새 ISP 링크를 outside로 확장하는 별도 실습을 사용한다.

~~~mermaid
flowchart LR
    C["Inside PC<br>192.168.20.10"] --> R2["R2 NAT<br>inside / outside"]
    R2 --> ISP["ISP<br>203.0.113.1"]
    ISP --> WEB["Public Server<br>198.51.100.100"]
~~~

예시 주소:

| 링크 | 주소 |
| --- | --- |
| R2 inside G0/1 | 192.168.20.1/24 |
| R2 outside G0/2 | 203.0.113.2/30 |
| ISP G0/0 | 203.0.113.1/30 |
| ISP G0/1 | 198.51.100.1/24 |
| Public Server | 198.51.100.100/24, GW 198.51.100.1 |

장비 모델에 G0/2가 없으면 지원되는 여분 인터페이스가 있는 라우터를 선택하거나 모듈을 추가한다.

### 8.8 PAT 구성

R2:

~~~ios
R2(config)# interface gigabitEthernet0/1
R2(config-if)# ip nat inside
R2(config-if)# exit
R2(config)# interface gigabitEthernet0/2
R2(config-if)# ip address 203.0.113.2 255.255.255.252
R2(config-if)# ip nat outside
R2(config-if)# no shutdown
R2(config-if)# exit
R2(config)# access-list 1 permit 192.168.20.0 0.0.0.255
R2(config)# ip nat inside source list 1 interface gigabitEthernet0/2 overload
R2(config)# ip route 0.0.0.0 0.0.0.0 203.0.113.1
~~~

ISP에는 public server 연결 경로가 직접 생긴다. Public Server의 default gateway를 반드시 설정한다.

### 8.9 NAT 검증

Inside PC에서 public server로 ping 또는 HTTP 요청을 만든 뒤:

~~~ios
R2# show ip nat translations
R2# show ip nat statistics
R2# show access-lists 1
R2# show ip route 198.51.100.100
~~~

예시:

~~~text
Pro  Inside global      Inside local       Outside local      Outside global
icmp 203.0.113.2:1      192.168.20.10:1    198.51.100.100:1  198.51.100.100:1
~~~

- Inside local: 내부에서 실제 사용하는 주소
- Inside global: 외부에 보이는 변환 주소
- overload: 여러 내부 흐름을 포트·식별자로 구분

### 8.10 Static NAT

Inside server 192.168.20.100을 203.0.113.10으로 고정 변환하는 개념 예:

~~~ios
R2(config)# ip nat inside source static 192.168.20.100 203.0.113.10
~~~

외부에서 203.0.113.10으로 가는 경로가 R2를 향하도록 ISP 쪽 라우팅도 설계해야 한다. NAT 명령 하나만으로 전체 경로가 자동 완성되지는 않는다.

### 8.11 Simulation Mode에서 NAT

필터를 ICMP 또는 TCP/HTTP로 제한한다.

R2의 inbound와 outbound PDU를 비교:

| 필드 | Inside에서 들어올 때 | Outside로 나갈 때 |
| --- | --- | --- |
| Source IP | 192.168.20.10 | 203.0.113.2 |
| Destination IP | 198.51.100.100 | 198.51.100.100 |
| Source MAC | inside PC | R2 outside |
| Destination MAC | R2 inside | ISP |

응답 방향에서는 destination IP가 inside global에서 inside local로 복원된다.

### 8.12 NAT Troubleshooting

~~~ios
R2# show ip interface brief
R2# show running-config | include ip nat
R2# show access-lists 1
R2# show ip nat statistics
R2# show ip nat translations
R2# show ip route
~~~

확인:

- inside/outside가 반대로 지정되지 않았는가?
- NAT ACL이 실제 inside local 네트워크와 일치하는가?
- outside 인터페이스가 up/up인가?
- default route가 ISP를 향하는가?
- public server의 반환 경로가 있는가?
- 트래픽을 생성한 뒤 translation을 확인했는가?

### 8.13 배운 점

- ACL은 순서, wildcard, 인터페이스, 방향을 함께 봐야 한다.
- NAT는 주소 변환이고 ACL은 접근 정책이다.
- NAT 문제도 변환 전·후 주소와 양방향 경로를 함께 검증한다.

---

# Part IV. 패킷 분석과 장애 해결

## 9장. Simulation Mode 패킷 분석

### 9.1 Wireshark와 무엇이 다른가

Packet Tracer Simulation Mode는 실제 NIC에서 pcap을 수집하는 도구가 아니다. 시뮬레이터 내부 프로토콜 이벤트를 단계별로 시각화한다.

| Simulation Mode | 실제 패킷 캡처 |
| --- | --- |
| 교육용 이벤트와 OSI 설명 | 실제 인터페이스에서 관찰한 프레임 |
| 장비 내부 처리 단계를 쉽게 표시 | 캡처 지점에 보이는 정보만 존재 |
| 지원 프로토콜·필드가 제한됨 | 구현이 보내는 실제 필드와 타이밍 |
| Capture/Forward로 단계 실행 | 패킷이 실시간으로 수집됨 |

Packet Tracer에서는 계층과 경로의 인과관계를 배우고, 실제 캡처 기술은 EVE-NG판에서 확장한다.

### 9.2 기본 조작

1. 오른쪽 아래 Simulation 탭을 선택한다.
2. Show All/None으로 모든 필터를 해제한다.
3. Edit Filters에서 필요한 프로토콜만 선택한다.
4. Realtime에서 명령을 준비한 뒤 Simulation에서 실행한다.
5. Capture/Forward로 한 이벤트씩 진행한다.
6. Auto Capture/Play는 전체 흐름을 연속 재생한다.
7. Reset Simulation은 이벤트 목록과 시뮬레이션 상태를 초기화한다.

필터를 너무 많이 켜면 STP, CDP 등 배경 이벤트가 섞여 핵심 흐름을 보기 어렵다.

### 9.3 Event List 읽기

일반 열:

- Visible: 화면 표시 여부
- Time: 시뮬레이션 시간
- Last Device: 직전에 처리한 장비
- At Device: 현재 장비
- Type: ARP, ICMP, TCP, DNS 등
- Info: 세부 이벤트

같은 봉투가 여러 장비를 이동하는 과정과, ARP Request·Reply처럼 서로 다른 PDU를 구분한다.

### 9.4 PDU Information

이벤트 봉투를 클릭하면 보통 다음 탭을 확인할 수 있다.

#### OSI Model

장비가 각 계층에서 어떤 결정을 했는지 설명한다.

예:

- Layer 1에서 인터페이스로 신호 수신
- Layer 2에서 목적지 MAC 검사
- Layer 3에서 목적지 IP와 라우팅 테이블 검사
- TTL 감소
- 새 프레임 생성

#### Inbound PDU Details

장비에 들어온 프레임·패킷 필드.

#### Outbound PDU Details

장비에서 나갈 때 새로 만들어진 필드.

라우터의 inbound/outbound를 비교하면 MAC과 TTL 변화가 선명하다.

### 9.5 Simple PDU와 실제 명령

Add Simple PDU 봉투는 빠르게 ICMP 연결을 시험한다. 그러나 학습 보고서에는 PC Command Prompt의 ping과 함께 사용한다.

- Simple PDU: 빠른 topology validation
- Command Prompt ping: 사용자 관점의 출력 확인
- Simulation Event: 패킷 처리 원인 분석

초록 체크 하나만 보고 완료하지 않는다.

### 9.6 ARP 분석 체크리스트

필터: ARP, ICMP

기록:

1. 누가 ARP Request를 보냈는가?
2. Ethernet destination이 broadcast인가?
3. Sender IP/MAC은 무엇인가?
4. Target IP는 최종 목적지인가, 게이트웨이인가?
5. 누가 Reply했는가?
6. 이후 ICMP 프레임의 destination MAC은 무엇인가?

### 9.7 라우팅 분석 체크리스트

필터: ARP, ICMP

각 라우터에서:

- 입력 인터페이스
- 입력 source/destination MAC
- source/destination IP
- 입력 TTL
- 선택한 출력 인터페이스
- 출력 source/destination MAC
- 출력 TTL

표로 정리:

| Device | In interface | Destination IP | Route | Out interface | Next-hop MAC |
| --- | --- | --- | --- | --- | --- |
| R1 | G0/0 | 192.168.20.10 | S 192.168.20.0/24 | G0/1 | R2 G0/0 |
| R2 | G0/0 | 192.168.20.10 | C 192.168.20.0/24 | G0/1 | PC-B |

### 9.8 TCP·HTTP 분석 체크리스트

필터: TCP, HTTP

순서:

1. SYN
2. SYN/ACK
3. ACK
4. HTTP request
5. HTTP response

확인:

- 클라이언트의 임시 source port
- 서버 destination port 80
- TCP flags
- sequence/acknowledgment 정보가 표시되는 범위
- HTTP request method와 destination

### 9.9 DNS 분석 체크리스트

필터: DNS, UDP

- Query name
- Query type
- DNS server destination IP
- UDP source/destination port
- Response address
- 응답 후 TCP 연결 대상 IP가 DNS 결과와 같은가?

### 9.10 ACL drop 분석

1. ACL 없이 정상 흐름을 저장한다.
2. ACL을 적용한다.
3. 같은 source/destination/protocol을 재현한다.
4. drop된 장비를 찾는다.
5. OSI Model의 ACL 처리 설명을 확인한다.
6. <code>show access-lists</code> counter와 연결한다.

정상 기준선과 장애 흐름을 같은 조건으로 비교하는 것이 핵심이다.

### 9.11 NAT 분석

R2 NAT 장비의 inbound/outbound PDU에서:

- inside local
- inside global
- destination
- source port 또는 ICMP identifier

를 기록한다. 응답 방향에서 역변환되는지도 끝까지 진행한다.

### 9.12 분석 보고서 템플릿

~~~markdown
# Packet Tracer PDU Analysis

## Topology

## Addressing Table

## Trigger
- Source:
- Destination:
- Protocol:
- Command/Application:

## Event Sequence
| No. | At Device | Type | Inbound | Decision | Outbound |
| ---: | --- | --- | --- | --- | --- |

## Layer Changes
- L2:
- L3:
- L4:

## First Unexpected Event

## Related IOS Evidence

## Conclusion
~~~

### 9.13 배운 점

- Simulation Mode는 필터를 좁히고 한 이벤트씩 읽어야 한다.
- 라우터의 inbound/outbound PDU 비교로 L2 재캡슐화와 TTL 감소를 확인한다.
- 시각적 drop 결과를 IOS show 출력과 연결해야 원인을 입증할 수 있다.

---

## 10장. 계층형 트러블슈팅

### 10.1 증상 정의

나쁜 증상:

~~~text
핑이 안 됩니다.
~~~

좋은 증상:

~~~text
PC-A 192.168.10.10에서 PC-B 192.168.20.10으로 ping하면
Request timed out이 발생한다. PC-A에서 gateway 192.168.10.1 ping은 성공하고,
R1에서 R2 transit 10.0.12.2 ping도 성공한다.
~~~

이미 LAN-A 링크와 transit 일부를 정상 범위로 분리했다.

### 10.2 Packet Tracer 7단계

1. 토폴로지와 케이블 확인
2. 인터페이스 up/up 확인
3. 주소·마스크·게이트웨이 확인
4. ARP·MAC 학습 확인
5. 라우팅 테이블 양방향 확인
6. ACL·NAT·서비스 확인
7. Simulation Mode에서 최초 drop 위치 확인

### 10.3 계층별 명령

| 질문 | Router IOS | Switch IOS | PC |
| --- | --- | --- | --- |
| 링크가 up인가? | <code>show ip interface brief</code> | <code>show interfaces</code> | <code>ipconfig</code> |
| 포트가 어느 VLAN인가? | 해당 없음 | <code>show vlan brief</code> | 해당 없음 |
| trunk가 VLAN을 허용하는가? | subinterface 확인 | <code>show interfaces trunk</code> | 해당 없음 |
| MAC을 학습했는가? | 해당 없음 | <code>show mac address-table</code> | 해당 없음 |
| ARP가 있는가? | <code>show arp</code> | L3 switch가 아니면 제한 | <code>arp -a</code> |
| 경로가 있는가? | <code>show ip route</code> | L2 switch에는 없음 | 기본 게이트웨이 확인 |
| 정책이 막는가? | <code>show access-lists</code> | port-security 등 확인 | 해당 없음 |
| 주소 변환되는가? | <code>show ip nat translations</code> | 해당 없음 | 해당 없음 |

### 10.4 Interface 상태 조합

| Status | Protocol | 의미와 조사 |
| --- | --- | --- |
| administratively down | down | shutdown, <code>no shutdown</code> |
| down | down | 케이블, 상대 장비, 모듈, 포트 |
| up | down | L2 keepalive·encapsulation 등 |
| up | up | 인터페이스 기본 전달 가능, 상위 설정 계속 확인 |

up/up만으로 IP·라우팅·ACL 정상까지 보장하지 않는다.

### 10.5 Hop-by-hop ping

PC-A에서 PC-B까지 한 번에만 시험하지 않는다.

1. PC-A → 192.168.10.1
2. R1 → 10.0.12.2
3. R1 → 192.168.20.1
4. R2 → 192.168.20.10
5. PC-A → 192.168.20.10

어느 단계에서 처음 실패하는지 찾는다. 단, 라우터에서 보내는 ping의 source IP가 PC-A와 다를 수 있으므로 ACL·반환 경로 조건을 고려한다.

### 10.6 PC 체크리스트

~~~cmd
PC> ipconfig /all
PC> arp -a
PC> ping 127.0.0.1
PC> ping 기본_게이트웨이
PC> tracert 목적지_IP
PC> nslookup 이름
~~~

Packet Tracer PC가 일부 옵션을 지원하지 않으면 Desktop의 IP Configuration과 Simulation Mode로 보완한다.

### 10.7 Router 체크리스트

~~~ios
R1# show ip interface brief
R1# show interfaces description
R1# show arp
R1# show ip route
R1# show ip route 목적지_IP
R1# show access-lists
R1# show ip nat translations
R1# show running-config
~~~

모든 명령을 무작정 실행하지 말고 현재 가설에 필요한 출력을 선택한다.

### 10.8 Switch 체크리스트

~~~ios
SW1# show interfaces
SW1# show vlan brief
SW1# show interfaces trunk
SW1# show mac address-table
SW1# show spanning-tree
SW1# show running-config
~~~

### 10.9 정상 비교군

| 테스트 | PC-A→R1 | R1→R2 | R2→PC-B | PC-A→PC-B |
| --- | --- | --- | --- | --- |
| 결과 | 성공 | 성공 | 성공 | 실패 |
| 해석 | LAN-A 정상 | transit 정상 | LAN-B 정상 | 종단 경로·정책·반환 조건 |

각 구간이 따로 성공해도 종단 흐름의 source·destination 조건에만 적용되는 ACL이 있을 수 있다.

### 10.10 조치 전 증거

설정을 지우거나 장비를 교체하기 전에:

~~~ios
show clock
show running-config
show ip interface brief
show ip route
show arp
show access-lists
show ip nat translations
~~~

Packet Tracer Activity Wizard나 평가 파일에서는 설정 변경이 점수에 영향을 줄 수 있다. 별도 사본에서 조사한다.

### 10.11 수정과 재검증

수정 후:

- 원래 실패 ping/HTTP를 동일하게 재실행
- 양쪽 방향 시험
- 관련 없는 정상 통신 회귀 시험
- Simulation Mode에서 PDU 완료 확인
- running-config 저장
- <code>.pkt</code> 파일 저장

### 10.12 배운 점

- show 명령은 설정과 운영 상태를 구분해 보여 준다.
- hop-by-hop 테스트와 정상 비교군으로 범위를 줄인다.
- Simulation Mode의 drop 위치는 원인 후보이고 IOS 상태로 다시 입증한다.

---

## 11장. 장애 주입 시나리오

### 11.1 시나리오 A: shutdown

주입:

~~~ios
R1(config)# interface gigabitEthernet0/1
R1(config-if)# shutdown
~~~

증상:

- R1-R2 링크 빨간 상태
- 원격 LAN 전체 실패
- <code>show ip interface brief</code>에 administratively down
- transit connected route 사라짐

복구:

~~~ios
R1(config-if)# no shutdown
~~~

### 11.2 시나리오 B: /30 주소 오류

R2를 다른 subnet으로 설정:

~~~ios
R2(config)# interface gigabitEthernet0/0
R2(config-if)# ip address 10.0.13.2 255.255.255.252
~~~

양쪽 링크는 up/up일 수 있지만 ARP와 next-hop 도달성이 실패한다.

증거:

~~~ios
R1# show ip interface brief
R2# show ip interface brief
R1# show arp
R1# ping 10.0.12.2
~~~

### 11.3 시나리오 C: 정적 경로 next hop 오류

~~~ios
R1(config)# no ip route 192.168.20.0 255.255.255.0 10.0.12.2
R1(config)# ip route 192.168.20.0 255.255.255.0 10.0.12.3
~~~

10.0.12.3은 /30 브로드캐스트 주소다.

조사:

~~~ios
R1# show ip route
R1# show running-config | include ip route
R1# show arp
~~~

### 11.4 시나리오 D: 반환 경로 누락

~~~ios
R2(config)# no ip route 192.168.10.0 255.255.255.0 10.0.12.1
~~~

Simulation Mode에서 Echo Request가 PC-B까지 가더라도 Echo Reply가 R2에서 올바른 경로를 찾지 못하는지 확인한다.

### 11.5 시나리오 E: PC 기본 게이트웨이 오류

PC-A gateway를 192.168.10.254로 바꾼다.

증상:

- 같은 subnet 통신 가능
- 원격 subnet 통신 실패
- ARP Request target이 192.168.10.254

이 사례는 “같은 LAN ping 성공”이 기본 게이트웨이 정상의 증거가 아님을 보여 준다.

### 11.6 시나리오 F: VLAN access 포트 오류

~~~ios
SW1(config)# interface fastEthernet0/2
SW1(config-if)# switchport access vlan 10
~~~

검증:

~~~ios
SW1# show vlan brief
SW1# show mac address-table
~~~

PC-SERVER의 IP는 VLAN 20 subnet인데 포트는 VLAN 10이므로 VLAN 20 gateway ARP가 실패한다.

### 11.7 시나리오 G: trunk allowed VLAN 누락

~~~ios
SW1(config)# interface gigabitEthernet0/1
SW1(config-if)# switchport trunk allowed vlan 10
~~~

VLAN 10은 정상, VLAN 20만 실패하는 비교군을 만든다.

~~~ios
SW1# show interfaces trunk
~~~

### 11.8 시나리오 H: ACL implicit deny

~~~ios
R1(config)# ip access-list extended BROKEN_POLICY
R1(config-ext-nacl)# permit icmp 192.168.10.0 0.0.0.255 host 192.168.20.100
R1(config-ext-nacl)# exit
R1(config)# interface gigabitEthernet0/0
R1(config-if)# ip access-group BROKEN_POLICY in
~~~

ICMP만 permit했으므로 HTTP와 DNS 등 다른 IP 트래픽은 implicit deny에 걸린다.

증거:

~~~ios
R1# show access-lists BROKEN_POLICY
R1# show ip interface gigabitEthernet0/0
~~~

### 11.9 시나리오 I: NAT inside/outside 반대

inside와 outside 지정이 뒤집힌 설정을 만든다.

~~~ios
R2(config)# interface gigabitEthernet0/1
R2(config-if)# no ip nat inside
R2(config-if)# ip nat outside
R2(config)# interface gigabitEthernet0/2
R2(config-if)# no ip nat outside
R2(config-if)# ip nat inside
~~~

<code>show ip nat statistics</code>에서 Inside interfaces와 Outside interfaces를 확인한다.

### 11.10 시나리오 J: DNS 레코드 오류

Server-PT DNS 레코드를 <code>www.lab.local → 192.168.20.200</code>으로 잘못 설정한다.

증상:

- <code>nslookup</code>은 응답하지만 잘못된 IP
- IP URL 192.168.20.100은 성공
- 이름 URL은 실패

DNS “응답이 왔다”와 “정답이 맞다”를 구분한다.

### 11.11 장애 보고서

각 시나리오에 대해:

~~~markdown
## Symptom

## Scope

## Hypotheses

## IOS/PC Evidence

## Simulation Event

## Root Cause

## Fix

## Validation

## Lessons Learned
~~~

---

## 12장. 종합 프로젝트

### 12.1 요구사항

회사의 본사와 지사를 Packet Tracer로 설계한다.

- 본사 Users VLAN 10: 192.168.10.0/24
- 본사 Servers VLAN 20: 192.168.20.0/24
- 지사 LAN: 192.168.30.0/24
- 본사-지사 transit: 10.0.12.0/30
- Router-on-a-stick으로 본사 inter-VLAN routing
- 정적 경로로 본사와 지사 연결
- DHCP로 사용자 PC 주소 할당
- 내부 DNS 이름 <code>intranet.lab.local</code>
- HTTP Server 제공
- Users는 HTTP와 DNS 허용
- 지사에서 Server 접근 허용
- 별도 ISP 확장 시 PAT 구성

### 12.2 제출 토폴로지

~~~mermaid
flowchart TB
    U["HQ Users<br>VLAN 10"] --> SW["HQ Switch"]
    SV["HQ Server<br>VLAN 20"] --> SW
    SW -->|"trunk"| HQ["HQ Router"]
    HQ -->|"10.0.12.0/30"| BR["Branch Router"]
    BR --> B["Branch LAN<br>192.168.30.0/24"]
~~~

### 12.3 구축 체크포인트

#### Checkpoint 1: L1/L2

- 모든 필수 링크 up
- VLAN과 access port 확인
- trunk에 VLAN 10,20 허용
- MAC 주소 학습

#### Checkpoint 2: L3

- 각 gateway ping
- transit ping
- 양쪽 정적 경로
- end-to-end ping

#### Checkpoint 3: Services

- DHCP binding
- DNS query
- HTTP 접속

#### Checkpoint 4: Policy

- 허용해야 할 트래픽 성공
- 거부해야 할 트래픽 실패
- ACL counter 증가

#### Checkpoint 5: Packet Analysis

- ARP
- ICMP routed flow
- DNS
- TCP handshake
- HTTP

각 흐름에서 최소 한 개 PDU의 inbound/outbound 필드를 기록한다.

### 12.4 장애 주입

동료가 아래 중 세 가지를 선택해 적용한다.

- access VLAN 오류
- trunk allowed VLAN 누락
- subinterface VLAN tag 오류
- PC mask 오류
- PC gateway 오류
- 정적 경로 삭제
- ACL 순서 오류
- DHCP pool mask 오류
- DNS A record 오류
- NAT inside/outside 오류

조사자는 설정을 보기 전에 증상과 Simulation Mode로 범위를 좁힌다.

### 12.5 평가 기준

| 항목 | 배점 |
| --- | ---: |
| 토폴로지·주소 설계 | 15 |
| VLAN·trunk | 15 |
| 라우팅 | 15 |
| DHCP·DNS·HTTP | 15 |
| ACL·NAT | 15 |
| Simulation PDU 분석 | 15 |
| 장애 해결 보고서 | 10 |

### 12.6 GitHub 제출물

~~~text
01-Network/
├── Network-Handbook-Vol1-Packet-Tracer.md
├── Labs/
│   ├── PT-Vol1-Base.pkt
│   ├── PT-Vol1-VLAN.pkt
│   └── PT-Vol1-Capstone.pkt
└── Images/
    ├── pt-base-topology.png
    └── pt-simulation-pdu.png
~~~

공개 전 장비 비밀번호와 실제 조직 주소를 제거한다.

### 12.7 배운 점

- Packet Tracer 프로젝트도 요구사항→설계→구성→검증→장애 해결 순으로 진행한다.
- <code>.pkt</code>만 제출하지 않고 주소표, 명령 근거, PDU 분석을 함께 문서화한다.
- 포트폴리오는 성공 화면보다 실패를 증거로 좁혀 간 과정을 보여 줘야 한다.

---

# Part V. 면접과 부록

## 면접 질문과 모범 답변

### Q1. Packet Tracer는 실제 IOS와 같은가요?

아닙니다. Packet Tracer는 교육용 시뮬레이터이며 Cisco IOS 기능의 일부를 모델링합니다. 장비 모델과 버전에 따라 명령 지원이 다르므로 문맥 도움말과 show 출력으로 확인합니다. 실제 구현의 타이밍과 모든 데이터 플레인 동작을 그대로 재현하는 도구로 보지는 않습니다.

### Q2. 스위치가 MAC 주소 테이블을 어떻게 학습하나요?

수신 프레임의 출발지 MAC과 들어온 포트를 학습합니다. 목적지 MAC이 테이블에 있으면 해당 포트로 전달하고, 없으면 같은 VLAN에서 flooding합니다. <code>show mac address-table</code>로 VLAN, MAC, 포트, 타입을 확인합니다.

### Q3. 원격 서버로 갈 때 첫 프레임의 목적지 MAC은 무엇인가요?

기본 게이트웨이 또는 라우팅으로 선택된 다음 홉의 MAC입니다. IP 목적지는 원격 서버지만 Ethernet은 현재 링크에서 다음 홉까지만 전달합니다.

### Q4. 라우터를 통과할 때 무엇이 바뀌나요?

입력 L2 헤더는 제거되고 출력 링크에 맞는 source/destination MAC으로 새 프레임이 만들어집니다. IPv4 TTL은 감소합니다. NAT가 없다면 종단 source/destination IP는 유지됩니다.

### Q5. <code>show ip interface brief</code>에서 administratively down은 무엇인가요?

인터페이스가 설정으로 shutdown된 상태입니다. 올바른 인터페이스 설정 모드에서 <code>no shutdown</code>하고 케이블·상대 포트까지 검증합니다.

### Q6. connected route는 언제 생성되나요?

라우터 인터페이스에 유효한 IP/mask가 설정되고 인터페이스가 up/up일 때 해당 subnet의 connected route와 인터페이스 주소의 local /32 경로가 생깁니다.

### Q7. 정적 경로를 양쪽에 넣어야 하는 이유는?

요청 경로뿐 아니라 응답이 출발지 네트워크로 돌아오는 경로가 필요하기 때문입니다. 한 방향 경로만 있으면 요청이 도착해도 응답이 사라질 수 있습니다.

### Q8. 기본 경로는 어떻게 설정하나요?

~~~ios
ip route 0.0.0.0 0.0.0.0 다음_홉
~~~

더 구체적인 경로가 없을 때 사용합니다. <code>show ip route</code>에서 <code>S*</code>와 gateway of last resort를 확인합니다.

### Q9. /27의 subnet mask와 wildcard mask는?

Subnet mask는 255.255.255.224이고 wildcard mask는 0.0.0.31입니다. wildcard는 각 옥텟에서 255에서 subnet mask를 뺀 값입니다.

### Q10. VLAN과 subnet은 같은가요?

아닙니다. VLAN은 L2 브로드캐스트 도메인을 분리하고 subnet은 L3 주소 범위입니다. 운영상 보통 1:1로 대응하지만 서로 다른 개념입니다.

### Q11. Access port와 trunk port 차이는?

Access port는 일반적으로 한 VLAN의 엔드 장비를 연결합니다. Trunk는 여러 VLAN 프레임을 802.1Q tag로 구분해 전달합니다. <code>show vlan brief</code>와 <code>show interfaces trunk</code>로 검증합니다.

### Q12. Router-on-a-stick을 설명해 주세요.

스위치-라우터 사이 한 물리 trunk를 사용하고 라우터에 VLAN별 subinterface를 만들어 inter-VLAN routing하는 방식입니다. 각 subinterface의 <code>encapsulation dot1Q VLAN_ID</code>와 IP가 해당 VLAN gateway 역할을 합니다.

### Q13. ping 성공은 무엇을 증명하나요?

해당 source와 destination 사이 ICMP Echo 왕복이 됐음을 보여 줍니다. DNS, TCP port, HTTP 서비스, ACL의 다른 프로토콜 허용까지 증명하지는 않습니다.

### Q14. traceroute는 어떤 원리를 사용하나요?

TTL을 단계적으로 증가시키고 중간 라우터의 ICMP Time Exceeded 응답을 이용해 홉을 관찰합니다. 응답 정책 때문에 별표가 나와도 그 장비가 실제 포워딩을 못 한다고 즉시 결론 내리지 않습니다.

### Q15. ACL은 어떤 순서로 처리되나요?

위에서 아래로 평가하고 처음 일치한 ACE의 동작을 적용합니다. 마지막에는 implicit deny가 있습니다. 그래서 더 구체적인 permit·deny와 일반 규칙의 순서가 중요합니다.

### Q16. 표준 ACL과 확장 ACL의 차이는?

표준 IPv4 ACL은 주로 source 주소만 검사합니다. 확장 ACL은 source, destination, protocol, TCP/UDP port 등을 구분할 수 있습니다. 일반 원칙으로 표준 ACL은 destination 가까이, 확장 ACL은 source 가까이 배치합니다.

### Q17. ACL의 in과 out은 누구 관점인가요?

해당 라우터 인터페이스 관점입니다. in은 인터페이스로 들어오는 패킷, out은 라우팅 후 그 인터페이스로 나가는 패킷입니다.

### Q18. ACL이 적용됐는지 어떻게 확인하나요?

<code>show ip interface</code>로 인터페이스와 방향을 확인하고, <code>show access-lists</code>로 ACE와 match counter를 봅니다. 동일 트래픽을 재현할 때 어떤 counter가 증가하는지 연결합니다.

### Q19. NAT inside local과 inside global은 무엇인가요?

Inside local은 내부 호스트가 내부에서 사용하는 주소이고 inside global은 외부 네트워크에 보이는 변환 주소입니다. <code>show ip nat translations</code>로 양쪽 튜플을 확인합니다.

### Q20. PAT의 overload는 무엇인가요?

여러 내부 호스트의 흐름을 하나 또는 소수의 외부 주소로 변환하면서 port나 ICMP identifier로 구분합니다. 내부 private 주소 다수가 한 인터페이스 주소를 공유할 수 있습니다.

### Q21. DHCP relay가 필요한 이유는?

DHCP 초기 요청은 브로드캐스트인데 라우터는 L2 브로드캐스트를 다른 subnet으로 전달하지 않기 때문입니다. 클라이언트 쪽 라우터 인터페이스에 <code>ip helper-address DHCP_SERVER</code>를 설정해 중계합니다.

### Q22. DNS는 되는데 웹이 안 될 때 무엇을 보나요?

DNS 응답 IP가 맞는지 확인한 뒤 TCP와 HTTP 이벤트를 봅니다. Simulation Mode에서 DNS response 이후 SYN이 생성되는지, 서버까지 도착하는지, HTTP 서비스가 On인지, ACL이 TCP 80을 허용하는지 확인합니다.

### Q23. 처음 ping 한 개가 실패하고 이후 성공하는 이유는?

ARP 주소 해석이 먼저 필요하거나 장비·프로토콜 상태가 수렴 중일 수 있습니다. Simulation Mode에서 ARP Request/Reply 뒤 ICMP가 시작되는지 확인합니다. 지속 실패와 최초 일회성 실패를 구분합니다.

### Q24. <code>show running-config</code>만 보면 충분한가요?

아닙니다. running-config는 의도한 설정이 들어갔는지 보여 주지만 링크와 프로토콜의 실제 운영 상태를 모두 보여 주지는 않습니다. <code>show ip interface brief</code>, <code>show ip route</code>, <code>show arp</code>, <code>show access-lists</code> 같은 상태 출력을 함께 봅니다.

### Q25. Packet Tracer 장애를 어떻게 접근하나요?

증상을 source, destination, protocol로 정의하고 링크→주소→ARP/MAC→라우팅→ACL/NAT→서비스 순으로 확인합니다. hop-by-hop 테스트로 범위를 줄이고 Simulation Mode에서 PDU가 처음 drop되거나 예상과 달라지는 장비를 찾습니다. 수정 후 원래 흐름과 회귀 흐름을 모두 재검증합니다.

---

## 부록 A. Cisco IOS 명령 치트시트

### 기본

~~~ios
enable
configure terminal
hostname R1
no ip domain-lookup
end
copy running-config startup-config
show running-config
show startup-config
show version
~~~

### 인터페이스

~~~ios
show ip interface brief
show interfaces
show interfaces description
show running-config interface gigabitEthernet0/0

configure terminal
interface gigabitEthernet0/0
 description LAN
 ip address 192.168.10.1 255.255.255.0
 no shutdown
~~~

### Ethernet·VLAN

~~~ios
show mac address-table
show vlan brief
show interfaces trunk
show interfaces switchport
show spanning-tree

vlan 10
 name USERS
interface fastEthernet0/1
 switchport mode access
 switchport access vlan 10
interface gigabitEthernet0/1
 switchport mode trunk
 switchport trunk allowed vlan 10,20
~~~

### ARP·라우팅

~~~ios
show arp
show ip route
show ip route 192.168.20.10
show running-config | include ip route
ping 192.168.20.10
traceroute 192.168.20.10

ip route 192.168.20.0 255.255.255.0 10.0.12.2
ip route 0.0.0.0 0.0.0.0 10.0.12.2
~~~

### DHCP

~~~ios
ip dhcp excluded-address 192.168.10.1 192.168.10.20
ip dhcp pool LAN_A
 network 192.168.10.0 255.255.255.0
 default-router 192.168.10.1
 dns-server 192.168.20.100

show ip dhcp binding
show ip dhcp pool
~~~

### ACL

~~~ios
show access-lists
show ip interface gigabitEthernet0/0

ip access-list extended POLICY
 permit tcp 192.168.10.0 0.0.0.255 host 192.168.20.100 eq 80
 permit icmp 192.168.10.0 0.0.0.255 host 192.168.20.100
 deny ip any any
interface gigabitEthernet0/0
 ip access-group POLICY in
~~~

### NAT

~~~ios
interface gigabitEthernet0/1
 ip nat inside
interface gigabitEthernet0/2
 ip nat outside
access-list 1 permit 192.168.20.0 0.0.0.255
ip nat inside source list 1 interface gigabitEthernet0/2 overload

show ip nat translations
show ip nat statistics
~~~

## 부록 B. PC Command Prompt

~~~cmd
ipconfig
ipconfig /all
arp -a
ping 192.168.10.1
tracert 192.168.20.10
nslookup www.lab.local
~~~

Packet Tracer PC는 실제 Windows 전체 명령을 제공하지 않는다.

## 부록 C. Simulation Filter 조합

| 학습 목표 | 필터 |
| --- | --- |
| 같은 LAN ping | ARP, ICMP |
| Routed ping | ARP, ICMP |
| DHCP DORA | DHCP, ARP |
| 이름 기반 웹 | DNS, UDP, TCP, HTTP |
| ACL ICMP | ICMP |
| ACL HTTP | TCP, HTTP |
| NAT ping | ARP, ICMP |
| NAT HTTP | ARP, TCP, HTTP |

## 부록 D. show 출력 판독표

| 출력 | 정상 기준 | 이상 예 |
| --- | --- | --- |
| <code>show ip interface brief</code> | 필요한 인터페이스 up/up | admin down, down/down |
| <code>show vlan brief</code> | access port가 기대 VLAN | 포트가 VLAN 1 또는 다른 VLAN |
| <code>show interfaces trunk</code> | trunking, VLAN allowed | not-trunking, VLAN 누락 |
| <code>show mac address-table</code> | 올바른 VLAN·포트 | MAC 미학습·잘못된 포트 |
| <code>show arp</code> | next hop IP-MAC | 필요한 항목 없음 |
| <code>show ip route</code> | 목적지·반환 경로 | 경로 없음·next hop 오류 |
| <code>show access-lists</code> | 의도한 ACE counter 증가 | deny counter 증가 |
| <code>show ip nat translations</code> | inside local/global 매핑 | 트래픽 후에도 비어 있음 |

## 부록 E. GitHub 배치

~~~text
Cloud-IaC-Study/
└── 01-Network/
    ├── Network-Handbook-Vol1-Packet-Tracer.md
    ├── Labs/
    │   ├── PT-Base.pkt
    │   ├── PT-VLAN.pkt
    │   └── PT-Capstone.pkt
    └── Images/
~~~

커밋:

~~~bash
git add 01-Network/Network-Handbook-Vol1-Packet-Tracer.md
git add 01-Network/Labs
git commit -m "docs(network): add Packet Tracer handbook edition"
~~~

## 부록 F. 공식 참고 자료

- [Cisco Packet Tracer 공식 소개](https://www.netacad.com/cisco-packet-tracer)
- [Cisco Packet Tracer 공식 Tutorials](https://tutorials.ptnetacad.net/)
- [Packet Tracer 다운로드 안내](https://www.netacad.com/skillsforall/files/Cisco_Packet_Tracer_Download_and_Installation_Instructions.pdf)
- [Packet Tracer — Explore Network Functionality Using PDUs](https://contenthub.netacad.com/legacy/I2PT/1.1/en/course/files/3.1.1.3%20Packet%20Tracer%20-%20Explore%20Network%20Functionality%20Using%20PDUs.pdf)
- [Cisco IOS CLI Basics](https://www.cisco.com/c/en/us/td/docs/ios/fundamentals/configuration/guide/12_2sr/cf_12_2sr_book/cf_cli-basics.html)
- [Cisco Ping and Traceroute](https://www.cisco.com/c/en/us/support/docs/ios-nx-os-software/ios-software-releases-121-mainline/12778-ping-traceroute.html)
- [Cisco Static IP Routing](https://www.cisco.com/c/en/us/td/docs/switches/lan/cisco_ie3000/software/release/12-2_55_se/configuration/guide/swipstatrout.html)
- [Cisco Inter-VLAN Routing](https://www.cisco.com/c/en/us/support/docs/lan-switching/inter-vlan-routing/14976-50.html)
- [Cisco NAT Configuration](https://www.cisco.com/c/en/us/support/docs/ip/network-address-translation-nat/13772-12.html)

## 완독 체크리스트

- [ ] Packet Tracer와 실제 IOS의 차이를 설명한다.
- [ ] IOS 명령 모드와 설정 저장을 수행한다.
- [ ] show 출력으로 인터페이스 상태를 판독한다.
- [ ] MAC 주소 학습과 ARP를 Simulation Mode에서 추적한다.
- [ ] subnet mask와 wildcard mask를 계산한다.
- [ ] VLAN access/trunk와 router-on-a-stick을 구성한다.
- [ ] 양방향 정적 경로를 구성하고 검증한다.
- [ ] DNS→TCP→HTTP 이벤트를 순서대로 설명한다.
- [ ] DHCP DORA와 relay를 구성·분석한다.
- [ ] ACL 순서·방향·counter를 검증한다.
- [ ] NAT 변환 전·후 주소를 PDU에서 비교한다.
- [ ] 10개 장애 중 최소 5개를 증거로 해결한다.
- [ ] 종합 프로젝트와 장애 보고서를 GitHub에 제출한다.

---

## 마무리

Packet Tracer에서 네트워크를 잘한다는 것은 초록 링크와 Successful 메시지를 만드는 데서 끝나지 않는다. IOS show 출력과 Simulation PDU를 근거로 “어느 장비가 어떤 필드를 보고 어떤 결정을 했는가”를 설명할 수 있어야 한다.

> 설정은 의도이고, show 출력은 상태이며, PDU 흐름은 결과다. 세 가지가 일치할 때 구성이 완성된다.

---

**Edition:** Cisco Packet Tracer  
**Last reviewed:** 2026-08-06  
**Repository target:** <code>YGJ1203/Cloud-IaC-Study/01-Network</code>
