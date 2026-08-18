1. 루트 브리지 선출

- 브리지 아이디 -> 우선 순위 값이 가장 작은 스위치
- 브리지 아이디 -> MAC 주소 값이 가장 낮은 스위치


2. DP/RP

- DP : BPDU 송신
- RP : Root 브리지가 연결된 포트, BPDU 수신

3. BLK 포트

- Root Path Cost 값이 높은 스위치 포트
- 브리지 아이디 값이 높은 스위치 포트
- 포트 아이디 값이 높은 스위치 포트

21-3

Ex) VLAN 1에 대한 STP 환경에 대해서 다음 조건에 맞게 구성하여라.

 - ASW1~ASW5 스위치에서 BLK 포트가 선정 되도록 구성하여라.
 - DSW1과 DSW2에서는 절대 BLK 포트가 있어서는 안된다.


모든 스위치에 show spanning-tree vlan 1 돌려본 결과, ASW3이 기본 루트 브리지로 설정

DSW1 4096
DSW2 16384



21-4

Ex)  DSW2 F0/20, ASW1 F0/24 포트가 Blocking 되도록 구성하여라.
Core1 4096
DSW1 16384

22-1

@SW1, SW2, SW3
conf t 
spanning-tree mode rapid-pvst
end

@ SW1,2,3

conf t
vlan 11
vlan 12
vlan 13
vlan 14
end


Per VLAN Spanning Tree

VLAN 1		STP
VLAN 11		STP
VLAN 12		STP
VLAN 13		STP
VLAN 14		STP

CST Common Spanning-Tree

VLAN 1		
VLAN 11		
VLAN 12		STP
VLAN 13		
VLAN 14		


@ SW1
conf t
spanning-tree vlan 11,12 priority 4096
spanning-tree vlan 13,14 priority 16384
end

@ SW3
conf t
spanning-tree vlan 11,12 priority 16384
spanning-tree vlan 13,14 priority 4096
end

SW1#show spanning-tree vlan 11 <- This bridge is the root
SW1#show spanning-tree vlan 12 <- This bridge is the root
SW2#show spanning-tree vlan 11 <- F0/22 BLK
SW2#show spanning-tree vlan 12 <- F0/22 BLK

SW3#show spanning-tree vlan 13 <- This bridge is the root
SW3#show spanning-tree vlan 14 <- This bridge is the root
SW2#show spanning-tree vlan 13 <- F0/24 BLK
SW2#show spanning-tree vlan 14 <- F0/24 BLK

24-1

@SW1, SW2
conf t
int port-channel 12
 switchport trunk encapsulation dot1q
 switchport mode trunk
!
int range fa0/23 - 24
 switchport trunk encapsulation dot1q
 switchport mode trunk
 channel-protocol pagp
 channel-group 12 mode desirable
 end

show run

@SW2, SW3

conf t
int port-channel 23
 switchport trunk encapsulation dot1q
 switchport mode trunk
!
int range fa0/21 - 22
 switchport trunk encapsulation dot1q
 switchport mode trunk
 channel-protocol lcap
 channel-group 23 mode active
end
!

@SW1, SW3

conf t
int port-channel 13
 switchport trunk encapsulation dot1q
 switchport mode trunk
!
int range fa0/19 - 20
 switchport trunk encapsulation dot1q
 switchport mode trunk
 channel-protocol lcap
 channel-group 13 mode on
end
!

---------------------------EVE 실습--------------------------------
기본설정 구성

en 
conf t
hostname ASW105
no ip domain lookup
no cdp run
enable secret cisco
!
line con 0
 logg syn
 exec-timeout 0 0
!
line vty 0 4
 password ciscovty
 login
 transport input all
 end
!
wr
!

@ VPC
set pcname 이름
ip 10.1.11.1/24 10.1.11.254
show ip

2. 스위치 관리용 IP 주소 & 기본 게이트웨이 & 아이피 노라우팅 설정

@ 모든 스위치

conf t
no ip routing
spanning-tree mode rapid-pvst
interface vlan 1
 ip address 192.168.100.105 255.255.255.0
 no shutdown
ip default-gateway 192.168.100.254
end

3. 내부 네트워크 구축

@ Core1, DSW11

conf t
int range e1/0 - 1
switchport trunk encapsulation dot1q
switchport mode trunk
channel-group 1 mode active
end

@ DSW11, DSW12

conf t
int range e2/0 - 1
switchport trunk encapsulation dot1q
switchport mode trunk
channel-group 2 mode active
end

@ DSW12, Core1

conf t
int range e3/0 - 1
switchport trunk encapsulation dot1q
switchport mode trunk
channel-group 3 mode active
end

3-1

@ASW101 ~ ASW105

conf t
int range e1/1 - 2
switchport trunk encapsulation dot1q
switchport mode trunk
end

@ DSW11, 12

conf t
int range e0/0 - 3, e1/2
switchport trunk encapsulation dot1q
switchport mode trunk
end

4. VLAN 생성

@ 모든 스위치

conf t
vlan 11
 name VLAN_user1
vlan 12
 name VLAN_user2
vlan 13
 name DHCP+FTP
vlan 14
 name Web+DNS
vlan 15
 name EMAIL
vlan 16
 name Intranet
 end

@ASW 스위치들 (105제외)

conf t
int range e0/1 - 2
 switchport mode access
 switchport access vlan 14
 spanning-tree portfast
 end

@ASW105

conf t
int e0/1
 switchport mode access
 switchport access vlan 15
 spanning-tree portfast
int e0/2
 switchport mode access
 switchport access vlan 16
 spanning-tree portfast
 end

5. Inter-VLAN 구성

@Core1

conf t
int e0/0
 switchport trunk encapsulation dot1q
 switchport mode trunk
 spanning-tree portfast trunk
 end

@GW1

conf t
int e0/0
no shutdown
!
int e0/0.1
 encapsulation dot1q 1
 ip address 192.168.100.254 255.255.255.0
!
int e0/0.11
 encapsulation dot1q 11
 ip address 10.1.11.254 255.255.255.0
!
int e0/0.12
 encapsulation dot1q 12
 ip address 10.1.12.254 255.255.255.0
!
int e0/0.13
 encapsulation dot1q 13
 ip address 10.1.13.254 255.255.255.0
!
int e0/0.14
 encapsulation dot1q 14
 ip address 10.1.14.254 255.255.255.0
!
int e0/0.15
 encapsulation dot1q 15
 ip address 10.1.15.254 255.255.255.0
!
int e0/0.16
 encapsulation dot1q 16
 ip address 10.1.16.254 255.255.255.0
 end
!

6. PVST 구성

@ Core1

conf t
spanning-tree vlan 11,12 priority 4096
end

@ DSW11

conf t
spanning-tree vlan 11,12 priority 16384
end

@ DSW12

conf t
spanning-tree vlan 11,12 priority 24576
end

@ Core1

conf t
spanning-tree vlan 13-16 priority 4096
end

@ DSW11

conf t
spanning-tree vlan 13-16 priority 16384
end

@ DSW12

conf t
spanning-tree vlan 13-16 priority 24576
end

8) 인터넷 연결 설정

이어서...