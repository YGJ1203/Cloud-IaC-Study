L3 Switch
HSRP

@ SW1, SW2
conf t
spanning-tree mode rapid-pvst
!
int fa0/24
switchport trunk encapsulation dot1q
switchport mode trunk
!
vlan 11
vlan 12
vlan 13
end
!

show int trunk
show vlan brief

@ SW1
conf t
int fa0/1
 switchport mode access
 switchport access vlan 11
 spanning-tree portfast
!
int fa0/2
 switchport mode access
 switchport access vlan 12
 spanning-tree portfast
 end
!

@ SW2

conf t
int fa0/3
 switchport mode access
 switchport access vlan 11
 spanning-tree portfast
!
int fa0/4
 switchport mode access
 switchport access vlan 12
 spanning-tree portfast
!
int fa0/5
 switchport mode access
 switchport access vlan 13
 spanning-tree portfast
 end
!

@ SW1
conf t 
ip routing			// IP 라우팅 활성화
! 
int vlan 11			// SVI 인터페이스 기능
 ip address 192.168.11.254 255.255.255.0
!
int vlan 12
 ip address 192.168.12.254 255.255.255.0
!
int vlan 13
 ip address 192.168.13.254 255.255.255.0
end
!

show run
show ip int brief
show ip route

int fa0/10			// Routed or L3 인터페이스 기능
 no switchport
 ip address 121.160.42.1 255.255.255.252

conf t
ip route 0.0.0.0 0.0.0.0 121.160.42.2
end
!

@ SW1
conf t
access-list 10 permit 192.168.0.0 0.0.255.255
!
ip nat inside source list 10 interface fa0/10 overload
!
int fa0/10
 ip nat outside
!
int vlan 11
 ip nat inside
!
int vlan 12
 ip nat inside
!
int vlan 13
 ip nat inside
 end
! 

25-2

(2950 스위치는 트렁크 설정시 switchport trunk encapsulation dot1q 명령어 없이, switchport mode trunk 하면 됨 ㅇㅇ)

1. 트렁크 구성 (DSW1, DSW2, ASW1 ~ ASW5 구간에 IEEE 802.11 트렁크 구간을 구성하여라.)

@DSW1

en
conf t
int range fa0/1 - 5
switchport trunk encapsulation dot1q
switchport mode trunk
end
!

@ASW 모든 스위치

en
conf t
int fa0/24
switchport mode trunk
end
!


2. VTP 구성 (ASW1~ASW5는 DSW1로부터 다음과 같은 VLAN 정보가 공유되도록 하여라.)

VLAN-ID		Name
vlan 11		VLAN_A
vlan 12		VLAN_B
vlan 13		VLAN_C
vlan 14		VLAN_D
vlan 100		VLAN_Voice
vlan 200		VLAN_Server

@ DSW1


conf t
vtp domain CCNP
vlan 11
 name VLAN_A
vlan 12
 name VLAN_B
vlan 13
 name VLAN_C
vlan 14
 name VLAN_D
vlan 100
 name VLAN_Voice
vlan 200
 name VLAN_Server
end
!

@모든 스위치
show vlan brief
show vtp status

3. VLAN 구성
1) ASW1에 연결된 노드들을 각각의 VLAN 11로 액세스하여라
ASW1[F0/1] -------------------- PC1
ASW1[F0/2] -------------------- PC2
ASW1[F0/3] -------------------- PC3
ASW1[F0/4] -------------------- PC4

@ASW1
conf t
int range fa0/1 - 4
 switchport mode access
 switchport access vlan 11
 spanning-tree portfast
end
! 

2) ASW2에 연결된 노드들을 각각의 VLAN 100과 VLAN 12로 엑세스하여라.

ASW2[F0/5] -----------Phone5--------- PC5
ASW2[F0/6] -----------Phone6--------- PC6
ASW2[F0/7] -----------Phone7--------- PC7

@ASW2 (내 답안)
conf t
int range fa0/5 - 7
 switchport mode access
 switchport access vlan 12
 switchport access voice vlan 100
 spanning-tree portfast
end
!

@ ASW2(Cisco Catalyst Switch 2950) 강사님 답안

switchport trunk encapsulation dot1q <- 2950은 dot1q만 지원되므로 설정이 불필요하며, 오타 처리됩니다.

conf t
int range fa0/5 - 7
 switchport mode trunk
 switchport trunk native vlan 12
 switchport voice vlan 100
 spanning-tree portfast trunk

    - ASW2#show int fa0/5 switchport

3) ASW3에 연결된 노드들을 각각의 VLAN 100과 VLAN 13으로 엑세스하여라.

ASW3[F0/8] -----------Phone8--------- PC8
ASW3[F0/9] -----------Phone9--------- PC9
ASW3[F0/10] ----------Phone10-------- PC10

@ ASW3

conf t
int range fa0/8 - 10
 switchport mode trunk
 switchport trunk native vlan 13
 switchport voice vlan 100
 spanning-tree portfast trunk
end
!

4) ASW4에 연결된 노드들을 각각의 VLAN 100과 VLAN 14로 엑세스하여라.

ASW4[F0/11] ----------Phone11--------- PC11
ASW4[F0/12] ----------Phone12--------- PC12
ASW4[F0/13] ----------Phone13--------- PC13

@ ASW4

conf t
int range fa0/11 - 13
 switchport mode trunk
 switchport trunk native vlan 14
 switchport voice vlan 100
 spanning-tree portfast trunk
end
!

 5) ASW5에 연결된 노드들을 각각의 VLAN 200으로 엑세스하여라.

ASW5[F0/14] -------------------- 내부 FTP
ASW5[F0/15] -------------------- 인터넷 Web
ASW5[F0/16] -------------------- 내부 DNS

@ ASW5(Cisco Catalyst Switch 2950)

int range fa0/14 - 16
 switchport mode access
 switchport access vlan 200
 spanning-tree portfast

    - ASW5#show vlan brief


4. DSW1에서 SVI 인터페이스를 이용한 VLAN 라우팅을 실시하여라.

@ DSW1(Cisco Catalyst Switch 3560)

ip routing
!
int vlan 11
 ip address 192.168.11.254 255.255.255.0
!
int vlan 12
 ip address 192.168.12.254 255.255.255.0
!
int vlan 13
 ip address 192.168.13.254 255.255.255.0
!
int vlan 14
 ip address 192.168.14.254 255.255.255.0
!
int vlan 100
 ip address 192.168.100.254 255.255.255.0
!
int vlan 200
 ip address 192.168.200.254 255.255.255.0

    - DSW1#show run
    - DSW1#show ip int brief
    - DSW1#show ip route


5. DSW1에서 각각의 VLAN에 대해서 DHCP 서버를 구성하여, IP 할당이 가능하도록 하여라. 이때, IP Phone에게는 TFTP 서버 IP 주소도 할당해야 한다.(option 150 ip 192.168.100.254)
 
@ DSW1(Cisco Catalyst Switch 3560)

ip dhcp excluded-address 192.168.11.254
ip dhcp excluded-address 192.168.12.254
ip dhcp excluded-address 192.168.13.254
ip dhcp excluded-address 192.168.14.254
ip dhcp excluded-address 192.168.100.254
!
ip dhcp pool VLAN-11
 network 192.168.11.0 255.255.255.0
 default-router 192.168.11.254
 dns-server 192.168.200.253
!
ip dhcp pool VLAN-12
 network 192.168.12.0 255.255.255.0
 default-router 192.168.12.254
 dns-server 192.168.200.253
!
ip dhcp pool VLAN-13
 network 192.168.13.0 255.255.255.0
 default-router 192.168.13.254
 dns-server 192.168.200.253
!
ip dhcp pool VLAN-14
 network 192.168.14.0 255.255.255.0
 default-router 192.168.14.254
 dns-server 192.168.200.253
!
ip dhcp pool VLAN-100
 network 192.168.100.0 255.255.255.0
 default-router 192.168.100.254
 dns-server 192.168.200.253
 option 150 ip 192.168.100.254


6. DSW1에서 DHCP 서버 설정이 완료되었다면, PC에서 DHCP(자동 받기)를 클릭하여, DHCP 클라이언트로 전환하여라.

    - DSW1#show ip dhcp binding
 

7. DSW1 F0/10 포트를 Routed Interface로 전환하여, R1 F0/0 인터페이스와 연결이 가능하도록 하여라. 

@ DSW1(Cisco Catalyst Switch 3560)

int fa0/10
 no switchport
 ip address 118.129.57.33 255.255.255.224

@ R1(Cisco Router 2811)

int fa0/0
 ip address 118.129.57.34 255.255.255.224
 no shutdown

    - DSW1#show ip route, R1#show ip route, DSW1#ping 118.129.57.34, R1#ping 118.129.57.33


8. DSW1에서 인터넷 Web 서버(DMZ)에 대해서는 정적 NAT를 구성하고, VLAN 11~14, VLAN 100 사용자들을 위한 동적 NAT를 구성하여라. 
(인터넷 Web 서버의 Inside Global : 118.129.57.35, VLAN 11~14, 100의 Inside Global : 118.129.57.33)

@ DSW1(Cisco Catalyst Switch 3560)

access-list 10 deny 192.168.200.251 0.0.0.0
access-list 10 deny 192.168.200.252 0.0.0.0
access-list 10 deny 192.168.200.253 0.0.0.0
access-list 10 permit 192.168.0.0 0.0.255.255
!
ip nat inside source static tcp 192.168.200.252 80 118.129.57.35 80
ip nat inside source list 10 interface fa0/10 overload
!
int fa0/10
 ip nat outside
!
int vlan 11
 ip nat inside
!
int vlan 12
 ip nat inside
!
int vlan 13
 ip nat inside
!
int vlan 14
 ip nat inside
!
int vlan 100
 ip nat inside
!
int vlan 200
 ip nat inside

    - DSW1#show ip nat translations


9. DSW1에서 R1 F0/0으로 라우팅이 가능한 기본 경로를 설정하여라.

@ DSW1(Cisco Catalyst Switch 3560)

ip route 0.0.0.0 0.0.0.0 118.129.57.34

    - DSW1#show ip route


10. 정보 확인

    - PC1에서 'ping 192.168.200.252' 실시 및 'www.soldesk.com' 접속 실시
    - PC1에서 'ping 198.133.219.25' 실시 및 'www.cisco.com' 접속 실시
    - Test PC에서 'www.soldesk.com' 접속 실시

HSRP

@ R1

conf t
int fa0/0
 standby 1 ip 192.168.100.254
 standby 1 priority 105
 standby 1 preempt
 standby 1 track fa0/1

 standby 2 ip 192.168.100.253
 standby 2 preempt
end

@R2

conf t
int fa0/0
 standby 1 ip 192.168.100.254
 standby 1 preempt
 
 standby 2 ip 192.168.100.253
 standby 2 priority 105
 standby 2 preempt
 standby 2 track fa0/1

----------------------EVE 실습-------------------------------------------
1. 기본설정

모든 장비

en
conf t
hostname ASW101
!
enable secret cisco
no ip domain-lookup
no cdp run
!
line con 0
logg syn
exec-timeout 0 0
!
line vty 0 4
logg syn
exec-timeout 0 0
transport input all
password ciscovty
login
end
!
wr
!

1-1. IP 라우팅 해지
conf t
no ip routing
end
wr
!

1-2. VPC IP 설정

2. 스위치 간 트렁크 설정

@ Core1,2 & ASW101
conf t
spanning-tree mode rapid-pvst
!
int range e0/1 - 2
switchport trunk encapsulation dot1q
switchport mode trunk
end
!

2-1. 스위치 관리용 IP 주소 설정

@ 모든 스위치

conf t
int vlan 1
 ip address 192.168.100.101 255.255.255.0
 no shutdown
!
ip default-gateway 192.168.100.254
end

2-2 포트패스트 장비 설정

@ ASW101
conf t
int range e1/1 - 3
 spanning-tree portfast
 end
!

@ Core1, Core2
conf t
int e0/0
 spanning-tree portfast
 end
!

2-3 ) GW1, GW2 E0/1 IP 주소 설정


@ GW1
conf t
int e0/1
ip address 192.168.100.201 255.255.255.0
no shutdown
end
!

@ GW2
conf t
int e0/1
ip address 192.168.100.202 255.255.255.0
no shutdown
end
!

2-4) 인터넷 연결 설정

@ GW1
conf t
int e0/0
ip address 192.168.2.251 255.255.255.0
no shutdown
!
ip route 0.0.0.0 0.0.0.0 192.168.2.254
end

@ GW2
conf t
int e0/0
ip address 192.168.2.252 255.255.255.0
no shutdown
!
ip route 0.0.0.0 0.0.0.0 192.168.2.254
end

2-5) GW1, 2 NAT(PNAT) 설정

@ GW1, GW2
conf t
access-list 10 permit 192.168.100.0 0.0.0.255
ip nat inside source list 10 interface e0/0 overload
!
int e0/0
ip nat outside
!
int e0/1
ip nat inside
end

2-6) 루트 브리지 수동 선출

@ ASW101
conf t
spanning-tree vlan 1 priority 4096
end
@ Core2
conf t
spanning-tree vlan 1 priority 16384
end

3. HSRP 를 이용한 기본 게이트웨이 이중화

3-1) HSRP 구성

@ GW1(Active Router)
conf t
track 10 interface e0/0 line-protocol
!
int e0/1
standby 1 ip 192.168.100.254
standby 1 priority 120
standby 1 preempt
standby 1 track 10 decrement 30
end

@ GW2(Standby Router)
conf t
int e0/1
standby 1 ip 192.168.100.254
standby 1 preempt
end

3-2) GW1 E0/1 장애(내부 장애)
@ GW1
conf t
int e0/1
shutdown
end

장애 복구

conf t
int e0/1
no shutdown
end

3-3) GW1 E0/0 장애(외부 장애)
@ GW1
conf t
int e0/0
shutdown
end

장애 복구

@ GW1
conf t
int e0/0
no shutdown
end

4. 정적 NAT 구성

@ GW1, GW2
conf t
ip nat inside source static tcp 192.168.100.33 80 192.168.2.241 80 redundancy HSRP-NAT no-payload
ip nat inside source static tcp 192.168.100.33 443 192.168.2.241 443 redundancy HSRP-NAT no-payload
!
int e0/1
standby 1 name HSRP-NAT
end

5. HSRP 그룹을 이용한 분산 처리

5-1) VPC2 게이트웨이 변경
ip 192.168.100.22 255.255.255.0 192.168.100.253
show ip

2) HSRP 그룹을 이용한 같은 네티워크 분산 처리

@ GW1(Standby Router)
conf t
int e0/1
standby 2 ip 192.168.100.253
standby 2 preempt
end
@ GW2(Active Router)
conf t
track 10 interface e0/0 line-protocol
!
int e0/1
standby 2 ip 192.168.100.253
standby 2 priority 120
standby 2 preempt
standby 2 track 10 decrement 30
end

6. VRRP를 이용한 기본 게이트웨이 이중화

6-1) 설정 초기화

@ GW1
conf t
default int e0/1
!
int e0/1
ip address 192.168.100.201 255.255.255.0
ip nat inside
duplex full
end

@ GW2
conf t
default int e0/1
!
int e0/1
ip address 192.168.100.202 255.255.255.0
ip nat inside
duplex full
end

6-2) VRRP 구성

@ GW1(Master Router)
conf t
track 10 interface e0/0 line-protocol
!
int e0/1
vrrp 1 ip 192.168.100.254
vrrp 1 priority 120
vrrp 1 preempt
vrrp 1 track 10 decrement 30
end
@ GW2(Backup Router)
conf t
int e0/1
vrrp 1 ip 192.168.100.254
vrrp 1 preempt
end