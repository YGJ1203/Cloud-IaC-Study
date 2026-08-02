NAT 이후 실습에서 경험했거나 점검할 수 있는 추가 트러블슈팅 사례를 정리하였다.기존 Troubleshooting_NAT_to_VLAN.md와 내용이 겹치지 않도록 구성하였다.

13. Trunk 상태인데 특정 VLAN만 통신되지 않는 문제

증상

스위치 간 Trunk 상태는 정상

일부 VLAN은 통신 성공s

특정 VLAN만 반대편 스위치로 전달되지 않음

원인

Trunk 포트의 Allowed VLAN 목록에서 해당 VLAN이 제외되어 있었다.

확인 명령어

show interfaces trunk
show interfaces e0/1 switchport

확인 예시:

Port        Vlans allowed on trunk
Et0/1       10,20,30

VLAN 40이 필요한 상황에서 목록에 VLAN 40이 포함되지 않았다.

해결

기존 목록을 유지하면서 VLAN을 추가한다.

interface e0/1
 switchport trunk allowed vlan add 40

모든 VLAN을 허용해야 하는 실습이라면 다음과 같이 설정할 수 있다.

interface e0/1
 switchport trunk allowed vlan all

배운 점

Trunk가 정상적으로 형성되었다고 해서 모든 VLAN이 자동으로 통과하는 것은 아니다.

Trunk 문제를 확인할 때는 다음 세 가지를 함께 확인해야 한다.

Operational Mode가 Trunk인지

Encapsulation이 올바른지

Allowed VLAN 목록에 필요한 VLAN이 포함되어 있는지

14. DHCP Relay 누락으로 다른 VLAN에서 IP를 받지 못하는 문제

증상

DHCP 서버와 같은 네트워크의 PC는 정상적으로 IP를 받음

다른 VLAN의 PC는 DHCP 주소를 받지 못함

PC에 169.254.x.x 주소가 설정되거나 DHCP 요청이 계속 실패함

원인

DHCP Discover는 Broadcast 패킷이므로 라우터를 넘어가지 못한다.

DHCP 서버가 다른 네트워크에 있을 경우 Gateway 인터페이스에 DHCP Relay 설정이 필요하다.

해결

클라이언트 VLAN의 Gateway 인터페이스에 다음 명령어를 설정한다.

interface e0/0.10
 ip helper-address 10.1.11.201

여기서 10.1.11.201은 DHCP 서버의 IP 주소이다.

확인 명령어

show running-config interface e0/0.10
show ip dhcp binding
show ip interface brief

배운 점

DHCP Pool이 정상이어도 DHCP 서버와 클라이언트가 다른 네트워크에 있다면 ip helper-address가 필요하다.

점검 순서:

DHCP 서버 IP 확인

DHCP Pool의 Network 확인

Default Router 확인

Gateway 인터페이스 상태 확인

ip helper-address 확인

15. DHCP Pool의 Network 주소가 실제 VLAN과 다른 문제

증상

DHCP 서비스는 활성화되어 있음

일부 VLAN만 주소를 받지 못함

DHCP Binding이 생성되지 않음

원인

DHCP Pool에 설정한 Network 주소 또는 Subnet Mask가 실제 VLAN 대역과 일치하지 않았다.

잘못된 예시:

ip dhcp pool VLAN10
 network 172.16.1.0 255.255.255.0
 default-router 172.16.10.254

Gateway는 172.16.10.254인데 Network가 172.16.1.0/24로 설정되어 있다.

해결

ip dhcp pool VLAN10
 network 172.16.10.0 255.255.255.0
 default-router 172.16.10.254

확인 명령어

show running-config | section dhcp
show ip dhcp pool
show ip dhcp binding

배운 점

DHCP Pool에서는 다음 세 가지 주소가 같은 대역이어야 한다.

Network

Default Router

실제 Gateway 인터페이스

16. DHCP Excluded Address 누락으로 Gateway 주소가 할당될 위험

증상

PC가 DHCP로 Gateway 주소 또는 서버 주소를 받을 가능성이 있음

IP 충돌이 발생함

간헐적으로 통신이 끊김

원인

고정 IP로 사용하는 주소를 DHCP 할당 범위에서 제외하지 않았다.

해결

ip dhcp excluded-address 172.16.10.201 172.16.10.254

또는 필요한 주소만 개별적으로 제외한다.

ip dhcp excluded-address 172.16.10.254
ip dhcp excluded-address 172.16.10.201

배운 점

다음 주소는 DHCP Pool에서 제외하는 것이 안전하다.

Default Gateway

DNS 서버

DHCP 서버

Web, FTP, Mail 서버

네트워크 장비 관리 IP

17. Ping은 성공하지만 웹 또는 FTP 접속이 실패하는 문제

증상

서버 IP로 Ping 성공

HTTP, FTP 또는 Mail 서비스 접속 실패

라우팅 테이블과 Gateway는 정상

원인

Layer 3 통신은 정상이나 서버의 Application 서비스가 비활성화되어 있었다.

가능한 원인:

HTTP 서비스 OFF

FTP 서비스 OFF

사용자 계정 미생성

잘못된 포트 사용

서버 방화벽 차단

해결

서버에서 해당 서비스를 활성화하고 계정 및 포트 설정을 확인한다.

Packet Tracer 예시:

Server
→ Services
→ HTTP / FTP / DNS
→ Service On

배운 점

Ping 성공은 IP 통신이 된다는 의미이지, 모든 서비스가 정상이라는 의미는 아니다.

OSI 계층별로 문제를 구분해야 한다.

Ping 실패: 주로 Layer 1~3 확인

Ping 성공 + 서비스 실패: 주로 Layer 4~7 확인

18. IP 주소로는 접속되지만 도메인으로 접속되지 않는 문제

증상

다음 명령은 성공한다.

ping 10.1.11.202

하지만 다음 명령은 실패한다.

ping www.example7777.com

원인

다음 중 하나가 원인이었다.

PC에 DNS 서버 주소가 설정되지 않음

DNS 서버의 A Record 누락

도메인 이름 오타

DNS Record에 잘못된 IP 등록

DNS 서비스 비활성화

해결

DNS 서버에 올바른 Record를 등록한다.

Name

Type

Address

www.example7777.com

A

10.1.11.202

ftp.example7777.com

A

10.1.11.201

intranet.example7777.com

A

10.1.11.203

mail.example7777.com

A

10.1.11.204

PC의 DNS 주소도 확인한다.

DNS Server: 10.1.11.202

배운 점

DNS 문제를 빠르게 구분하는 방법:

서버 IP로 Ping

도메인으로 Ping

IP는 성공하고 도메인만 실패하면 DNS부터 확인

19. 인터페이스가 Up/Up인데 통신되지 않는 문제

증상

show ip interface brief

출력에서 인터페이스 상태가 다음과 같았다.

FastEthernet0/0    172.16.1.1    YES manual    up    up

그러나 PC와 통신되지 않았다.

원인

라우터 인터페이스에 Gateway 주소가 아닌 PC용 주소를 입력하였다.

예시:

PC 주소: 172.16.1.1

올바른 Gateway 주소: 172.16.1.254

인터페이스의 물리 및 데이터링크 상태는 정상이므로 up/up으로 표시되지만, IP 설계가 잘못되어 통신되지 않았다.

해결

interface f0/0
 no ip address
 ip address 172.16.1.254 255.255.255.0

배운 점

up/up은 케이블과 인터페이스가 정상이라는 의미이지, IP 주소가 올바르다는 의미는 아니다.

반드시 IP Addressing Table과 실제 설정을 비교해야 한다.

20. Router-on-a-Stick에서 Native VLAN 불일치 문제

증상

일부 VLAN 통신은 정상

Native VLAN에 속한 장비만 통신 실패

CDP에서 Native VLAN Mismatch 메시지가 출력됨

원인

스위치 Trunk 포트와 라우터 Subinterface의 Native VLAN 설정이 서로 달랐다.

스위치:

interface f0/24
 switchport trunk native vlan 510

라우터:

interface f0/0.510
 encapsulation dot1q 510

라우터에서는 native 옵션이 빠져 있었다.

해결

interface f0/0.510
 encapsulation dot1q 510 native

배운 점

Native VLAN을 사용하는 경우 양쪽 설정이 반드시 일치해야 한다.

Switch Native VLAN

Router Subinterface Native 설정

VLAN ID

21. Router Subinterface에 Encapsulation이 누락된 문제

증상

물리 인터페이스는 Up

Subinterface에 IP 주소도 설정됨

해당 VLAN의 PC가 Gateway로 Ping하지 못함

원인

Subinterface에 encapsulation dot1q 명령어가 없었다.

잘못된 예시:

interface f0/0.501
 ip address 172.16.1.254 255.255.255.0

해결

interface f0/0.501
 encapsulation dot1q 501
 ip address 172.16.1.254 255.255.255.0

배운 점

Router-on-a-Stick Subinterface에는 두 가지가 모두 필요하다.

VLAN Tag를 구분하는 Encapsulation

해당 VLAN의 Gateway IP

22. 물리 인터페이스 Shutdown으로 모든 Subinterface가 Down된 문제

증상

모든 Subinterface 설정이 존재함

IP와 Encapsulation도 정상

전체 VLAN에서 Gateway 통신 실패

원인

부모 물리 인터페이스에 no shutdown이 설정되지 않았다.

해결

interface f0/0
 no shutdown

확인 명령어

show ip interface brief

예상 상태:

FastEthernet0/0       unassigned    YES unset    up    up
FastEthernet0/0.501   172.16.1.254  YES manual   up    up

배운 점

Subinterface는 부모 인터페이스의 상태를 따라간다.

모든 VLAN이 한꺼번에 실패한다면 부모 인터페이스부터 확인한다.

23. Voice VLAN 단말이 IP를 받지 못하는 문제

증상

PC는 Data VLAN에서 정상적으로 IP를 받음

IP Phone은 Voice VLAN 주소를 받지 못함

전화기가 계속 DHCP 요청 상태에 머무름

원인

다음 중 하나가 누락되었다.

switchport voice vlan

Voice VLAN용 DHCP Pool

Option 150

Voice VLAN Trunk 허용

Voice VLAN Gateway

해결 예시

스위치:

interface f0/1
 switchport mode access
 switchport access vlan 510
 switchport voice vlan 511

라우터 DHCP:

ip dhcp pool VOICE
 network 172.16.11.0 255.255.255.0
 default-router 172.16.11.254
 option 150 ip 172.16.11.254

배운 점

IP Phone 포트에는 Data VLAN과 Voice VLAN이 동시에 존재할 수 있다.

PC 트래픽: Access VLAN

Phone 트래픽: Voice VLAN

24. EtherChannel 포트가 묶이지 않고 개별 포트로 동작하는 문제

증상

show etherchannel summary

출력에서 포트가 (P)가 아니라 (I) 또는 다른 상태로 표시되었다.

정상 예시:

Group  Port-channel  Protocol    Ports
1      Po1(SU)       LACP        Et1/0(P) Et1/1(P)

비정상 예시:

Et1/0(I)

원인

양쪽 포트의 설정이 일치하지 않았다.

확인 항목:

LACP/PAgP Mode

Access 또는 Trunk Mode

Allowed VLAN

Native VLAN

Speed

Duplex

포트 개수

해결

양쪽 장비의 물리 인터페이스 설정을 동일하게 맞춘다.

interface range e1/0 - 1
 switchport trunk encapsulation dot1q
 switchport mode trunk
 channel-group 1 mode active

배운 점

EtherChannel은 묶이는 포트끼리 Layer 2 설정이 동일해야 한다.

25. EtherChannel을 잘못된 포트에 설정한 문제

증상

잘못된 인터페이스에 다음 명령어를 입력하였다.

channel-group 3 mode active

해결

해당 물리 인터페이스에서 Channel Group을 제거한다.

interface range e3/0 - 1
 no channel-group

남아 있는 논리 인터페이스가 불필요하다면 삭제한다.

no interface port-channel 3

확인 명령어

show etherchannel summary
show running-config | section interface

배운 점

설정을 삭제할 때는 다음 두 부분을 구분해야 한다.

물리 포트의 Channel Group 소속

논리 Port-channel 인터페이스

26. STP 수렴 시간 때문에 PC가 DHCP 주소를 받지 못하는 문제

증상

PC를 연결한 직후 DHCP 요청 실패

잠시 후 다시 시도하면 정상

포트가 Listening/Learning 단계를 거침

원인

Access Port에 PortFast가 설정되지 않아 STP 수렴을 기다리는 동안 DHCP 요청이 실패하였다.

해결

PC나 서버가 연결된 Edge Port에 PortFast를 설정한다.

interface range e0/1 - 10
 spanning-tree portfast

BPDU Guard도 함께 사용하는 것이 안전하다.

interface range e0/1 - 10
 spanning-tree bpduguard enable

배운 점

PortFast는 STP를 끄는 기능이 아니다.

Edge Port가 바로 Forwarding 상태로 전환되도록 하는 기능이다.

27. Rapid-PVST 모드를 일부 스위치에만 설정한 문제

증상

스위치마다 STP 동작 방식이 다르게 보임

Root Bridge 선정 또는 수렴 시간이 예상과 다름

실습 답안과 출력이 일치하지 않음

원인

일부 스위치에만 Rapid-PVST를 적용하였다.

해결

토폴로지에 포함된 모든 스위치에 동일하게 설정한다.

spanning-tree mode rapid-pvst

확인 명령어

show spanning-tree summary
show spanning-tree

배운 점

STP Mode는 스위치 전체에 영향을 주는 Global 설정이다.

실습에서는 모든 스위치의 STP Mode를 통일하는 것이 중요하다.

28. 스위치 관리 IP는 있지만 원격 네트워크에서 접근되지 않는 문제

증상

같은 VLAN에서는 관리 IP로 Ping 성공

다른 네트워크에서는 관리 IP로 접근 실패

스위치는 Layer 2 모드로 동작 중

원인

Layer 2 스위치에 Default Gateway가 설정되지 않았다.

해결

관리용 SVI와 Default Gateway를 설정한다.

interface vlan 10
 ip address 172.16.10.10 255.255.255.0
 no shutdown

ip default-gateway 172.16.10.254

배운 점

Layer 2 스위치의 관리 통신에는 다음 설정이 한 세트로 사용된다.

관리 VLAN

SVI 관리 IP

Default Gateway

관리 VLAN이 통과하는 Trunk

29. 관리용 SVI가 Down 상태인 문제

증상

show ip interface brief

출력에서 VLAN 인터페이스가 다음과 같이 표시되었다.

Vlan10    172.16.10.10    YES manual    down    down

원인

해당 VLAN에 속하면서 Up 상태인 물리 포트가 없었다.

또는 VLAN 자체가 생성되지 않았다.

해결

VLAN 생성 여부를 확인한다.

show vlan brief

필요하면 VLAN을 생성한다.

vlan 10
 name MANAGEMENT

해당 VLAN을 사용하는 Access Port 또는 Trunk 포트가 Up인지 확인한다.

배운 점

SVI가 Up되려면 다음 조건이 필요하다.

VLAN이 VLAN Database에 존재

해당 VLAN을 전달하는 포트가 하나 이상 Up

SVI에 no shutdown 적용

30. no ip routing 적용 후 Layer 3 기능이 중단된 문제

증상

스위치에 SVI IP가 존재함

VLAN 간 Routing이 동작하지 않음

show ip route에 Connected Route가 기대대로 표시되지 않음

원인

Layer 3 스위치에 다음 설정이 적용되어 있었다.

no ip routing

이 설정으로 스위치가 Layer 2 스위치처럼 동작하게 되었다.

해결 방향

실습 목적을 먼저 확인한다.

Layer 2 스위치로 사용한다면:

no ip routing
ip default-gateway 172.16.10.254

Layer 3 스위치로 Inter-VLAN Routing을 수행한다면:

ip routing

배운 점

ip routing과 ip default-gateway는 장비의 역할에 따라 구분해야 한다.

Layer 2 관리용 스위치: no ip routing + ip default-gateway

Layer 3 Routing 스위치: ip routing

31. VTP Client에서 VLAN을 직접 생성하려 한 문제

증상

VTP Client 스위치에서 VLAN 생성 명령어를 입력했지만 반영되지 않았다.

vlan 20

원인

VTP Client는 로컬에서 VLAN Database를 직접 수정할 수 없다.

해결

VTP Server에서 VLAN을 생성한다.

vlan 20
 name SALES

이후 Trunk와 VTP 설정이 정상이라면 Client로 전달된다.

배운 점

VTP Mode별 역할:

Server: VLAN 생성·수정·삭제 가능

Client: VLAN 정보 수신

Transparent: 로컬 VLAN 독립 관리

32. VTP Domain은 같지만 VLAN이 동기화되지 않는 문제

증상

VTP Domain 이름이 동일

VTP Mode도 Server/Client로 정상

VLAN 정보는 동기화되지 않음

원인

스위치 사이의 링크가 Access Mode이거나 Trunk가 정상적으로 형성되지 않았다.

VTP Advertisement는 Trunk 링크를 통해 전달된다.

해결

interface f0/24
 switchport mode trunk

필요한 경우 Encapsulation도 설정한다.

switchport trunk encapsulation dot1q

확인 명령어

show interfaces trunk
show vtp status
show vtp password

배운 점

VTP 설정만 맞춰서는 부족하다.

VTP가 이동할 수 있는 Trunk 경로도 함께 존재해야 한다.

33. 잘못 생성한 Subinterface가 설정에 계속 남아 있는 문제

증상

오타로 다음 Subinterface를 생성하였다.

interface ethernet0/0.1
 no cdp enable

원인

인터페이스 설정만 지우고 Subinterface 자체는 삭제하지 않았다.

해결

Global Configuration Mode에서 Subinterface를 삭제한다.

no interface ethernet0/0.1

확인 명령어

show running-config | section interface Ethernet0/0.1
show ip interface brief

배운 점

no 명령어는 적용 위치가 중요하다.

인터페이스 내부 설정 삭제: Interface Configuration Mode

Subinterface 자체 삭제: Global Configuration Mode

34. EVE-NG 가상 장비를 강제 종료한 문제

증상

VMware에서 EVE-NG VM을 바로 Power Off하였다.

위험 요소

장비 설정의 저장 누락

Lab 상태 손상 가능성

가상 디스크 파일 시스템 오류 가능성

권장 종료 순서

네트워크 장비 설정 저장

copy running-config startup-config

EVE-NG Lab에서 장비 종료

EVE-NG 시스템 정상 종료

VMware에서 Shut Down Guest 사용

배운 점

Lab 파일과 장비의 Startup Configuration은 별개로 관리될 수 있다.

중요한 실습에서는 장비 설정을 먼저 저장하고 가상 머신을 정상 종료하는 것이 안전하다.

추가 트러블슈팅 점검 순서

문제가 발생했을 때 다음 순서로 확인하면 원인을 빠르게 좁힐 수 있다.

1단계: 물리 및 인터페이스

show ip interface brief
show interfaces status

확인 항목:

케이블 연결

Shutdown 여부

Status / Protocol

Speed / Duplex

2단계: Layer 2

show vlan brief
show interfaces trunk
show interfaces switchport
show etherchannel summary
show spanning-tree

확인 항목:

Access VLAN

Trunk Mode

Allowed VLAN

Native VLAN

EtherChannel

STP 상태

3단계: Layer 3

show ip route
show arp
show running-config

확인 항목:

IP 주소와 Subnet Mask

Default Gateway

Connected Route

Static/Default Route

Router Subinterface

4단계: 네트워크 서비스

show ip dhcp binding
show ip dhcp pool
show ip nat translations
show access-lists

확인 항목:

DHCP Pool

DHCP Relay

NAT

ACL

DNS 및 서버 서비스

5단계: 단계별 Ping

1. 자기 자신의 IP
2. 같은 네트워크의 다른 장비
3. Default Gateway
4. 원격 네트워크의 Gateway
5. 최종 목적지 IP
6. 목적지 Domain

핵심 정리

이번 추가 트러블슈팅 사례를 통해 다음 내용을 확인하였다.

Trunk 상태와 Allowed VLAN은 별도로 확인해야 한다.

DHCP는 Pool뿐 아니라 Relay와 Excluded Address도 중요하다.

Ping 성공과 Application 서비스 성공은 서로 다른 문제이다.

up/up 상태만으로 IP 설정이 올바르다고 판단할 수 없다.

Router-on-a-Stick은 물리 포트, Encapsulation, Subinterface IP가 모두 필요하다.

EtherChannel은 양쪽의 Layer 2 설정이 일치해야 한다.

관리용 SVI는 VLAN과 활성 포트가 있어야 Up 상태가 된다.

Layer 2 스위치와 Layer 3 스위치는 Gateway 설정 방식이 다르다.

트러블슈팅의 핵심은 패킷이 어느 단계에서 멈추는지 순서대로 추적하는 것이다.

한 줄 요약:명령어를 무작정 다시 입력하기보다, 물리 계층부터 서비스 계층까지 단계적으로 확인하는 것이 가장 빠른 해결 방법이다.