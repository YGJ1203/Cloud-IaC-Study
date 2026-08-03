26-2
@ R1
conf t
int fa0/0.11
 standby 11 ip 10.1.11.254
 standby 11 priority 105
 standby 11 preempt
 standby 11 track fa0/1
!
int fa0/0.12
 standby 12 ip 10.1.12.254
 standby 12 preempt
 end
!

show run
show standby brief

@ R2
conf t
int fa0/0.11
 standby 11 ip 10.1.11.254
 standby 11 preempt
!
int fa0/0.12
 standby 12 ip 10.1.12.254
 standby 12 priority 105
 standby 12 preempt
 standby 12 track fa0/1
 end
!

--------------------- EVE 실습 ------------------------------

1. 기본 설정

@ 모든 장비

en
conf t
hostname ASW102
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

@ 스위치 라우팅 기능 해제

conf t
no ip routing
end
wr
!

@ 각 VPC별 IP + DNS 설정

set pcname 이름
ip 10.1.11.1/24 10.1.11.254
ip dns 168.126.63.1

2. 트렁크 및 RSTP 구성

@ 코어, DSW

conf t
spanning-tree mode rapid-pvst
!
int range e1/1 - 2
switchport trunk encapsulation dot1q
switchport mode trunk
end

@ DSW, ASW

conf t
spanning-tree mode rapid-pvst
!
int range e2/1 - 2
switchport trunk encapsulation dot1q
switchport mode trunk
end

@ VLAN IP 주소 할당 + 디폴트 게이트웨이

conf t
int vlan 1
ip address 192.168.100.102 255.255.255.0
no shutdown
! 
ip default-gateway 192.168.100.254
end

@ 모든 스위치에서 VLAN 생성

conf t
vlan 11
name VLAN_11
vlan 12
name VLAN_12
vlan 13
name VLAN_13
vlan 14
name VLAN_14
end

@ ASW VLAN 설정

conf t
int e0/1
 switchport mode access
 switchport access vlan 13
 spanning-tree portfast
int e0/2
 switchport mode access
 switchport access vlan 14
 spanning-tree portfast
 end

@ GW1, Core 스위치 트렁크 설정

1. Core1

conf t
int e0/0
switchport trunk  encapsulation dot1q
switchport mode trunk
spanning-tree portfast trunk
end

1-1. GW1 서브 인터페이스

conf t
int e0/1
no shutdown
!
int e0/1.1
encapsulation dot1q 1
ip address 192.168.100.201 255.255.255.0
!
int e0/1.11 
encapsulation dot1q 11
ip address 10.1.11.201 255.255.255.0
!
int e0/1.12
encapsulation dot1q 12

(추가 보강 필요)

-------------------------------------------------------------------------------

1. 기본 환경 설정

@ 모든 장비
en
conf t
hostname 이름
no ip domain-lookup
no cdp run
!
line con 0
 exec-timeout 0 0
 logg syn
!
line vty 0 4
 password ciscovty
 login
 end
!
wr
!

@ 스위치
conf t
no ip routing
spanning-tree mode rapid-pvst
!
int vlan 1
 ip add 192.168.100.x 255.255.255.0
 no shutdown
!
ip default-gateway 192.168.100.254
end
wr
!


2. Core-DSW 구간 트렁크+이더체널

@ Core1, Core2, DSW11, DSW12
conf t
int range e2/0 - 1
 switchport trunk encapsulation dot1q
 switchport mode trunk
 channel-group 1 mode active
!
int range e1/0 - 1
 switchport trunk encapsulation dot1q
 switchport mode trunk
 channel-group 2 mode active
 end
!

show int trunk
show etherchannel summary


3. DSW-ASW 구간 트렁크

@ DSW11, DSW12
conf t
int range e0/1 - 3 , e3/1 - 3
 switchport trunk encapsulation dot1q
 switchport mode trunk
 end

@ ASW101~106
conf t
int range e0/0 - 1
 switchport trunk encapsulation dot1q
 switchport mode trunk
 end

show int trunk


4. VLAN 생성

@ 모든 스위치

conf t
vlan 11
 name Sales
vlan 12
 name HR
vlan 13
 name Admin
vlan 14
 name Tech
vlan 101
 name Email
vlan 102
 name DHCP+FTP
vlan 103
 name Web+DNS
vlan 104
 name Intranet
 end

show vlan brief


5. VLAN Access

@ ASW101
conf t
int range e0/2 - 3
 switchport mode access
 switchport access vlan 11
 spanning-tree portfast
 end

@ ASW102
conf t
int range e0/2 - 3
 switchport mode access
 switchport access vlan 12
 spanning-tree portfast
 end

@ ASW103
conf t
int e0/2
 switchport mode access
 switchport access vlan 13
 spanning-tree portfast
!
int e0/3
 switchport mode access
 switchport access vlan 14
 spanning-tree portfast
 end

@ ASW104
conf t
int e0/2
 switchport mode access
 switchport access vlan 101
 spanning-tree portfast
!
int e0/3
 switchport mode access
 switchport access vlan 102
 spanning-tree portfast
 end

@ ASW105
conf t
int e0/2
 switchport mode access
 switchport access vlan 103
 spanning-tree portfast
 end

@ ASW106
conf t
int e0/2
 switchport mode access
 switchport access vlan 104
 spanning-tree portfast
 end

show vlan brief


6. Inter-VLAN 구송

@ Core1, Core2
conf t
int e0/0
 switchport trunk encapsulation dot1q
 switchport mode trunk
 spanning-tree portfast trunk
 end

show int trunk

@ GW1
conf t
int e0/1
 no shutdown
!
int e0/1.1
 encapsulation dot1q 1
 ip address 192.168.100.201 255.255.255.0
!
int e0/1.11
 encapsulation dot1q 11
 ip address 10.1.11.201 255.255.255.0
!
int e0/1.12
 encapsulation dot1q 12
 ip address 10.1.12.201 255.255.255.0
!
int e0/1.13
 encapsulation dot1q 13
 ip address 10.1.13.201 255.255.255.0
!
int e0/1.14
 encapsulation dot1q 14
 ip address 10.1.14.201 255.255.255.0
!
int e0/1.101
 encapsulation dot1q 101
 ip address 10.1.101.201 255.255.255.0
!
int e0/1.102
 encapsulation dot1q 102
 ip address 10.1.102.201 255.255.255.0
!
int e0/1.103
 encapsulation dot1q 103
 ip address 10.1.103.201 255.255.255.0
!
int e0/1.104
 encapsulation dot1q 104
 ip address 10.1.104.201 255.255.255.0
 end
!

@ GW2
conf t
int e0/1
 no shutdown
!
int e0/1.1
 encapsulation dot1q 1
 ip address 192.168.100.202 255.255.255.0
!
int e0/1.11
 encapsulation dot1q 11
 ip address 10.1.11.202 255.255.255.0
!
int e0/1.12
 encapsulation dot1q 12
 ip address 10.1.12.202 255.255.255.0
!
int e0/1.13
 encapsulation dot1q 13
 ip address 10.1.13.202 255.255.255.0
!
int e0/1.14
 encapsulation dot1q 14
 ip address 10.1.14.202 255.255.255.0
!
int e0/1.101
 encapsulation dot1q 101
 ip address 10.1.101.202 255.255.255.0
!
int e0/1.102
 encapsulation dot1q 102
 ip address 10.1.102.202 255.255.255.0
!
int e0/1.103
 encapsulation dot1q 103
 ip address 10.1.103.202 255.255.255.0
!
int e0/1.104
 encapsulation dot1q 104
 ip address 10.1.104.202 255.255.255.0
 end
!

show run
show ip int brief
show ip route

GW1에서 GW2로 Ping 테스트
GW1,GW2#ping 192.168.100.x


7. 인터넷 연결 설정

@ GW1
conf t
int e0/0
 ip address 192.168.2.101 255.255.255.0
 no shutdown
!
ip route 0.0.0.0 0.0.0.0 192.168.2.254
end

@ GW2
conf t
int e0/0
 ip address 192.168.2.102 255.255.255.0
 no shutdown
!
ip route 0.0.0.0 0.0.0.0 192.168.2.254
end

show ip route
show ip int brief
ping 192.168.2.254
ping 168.126.63.1

@ GW1, GW2
conf t
access-list 10 permit 10.1.0.0 0.0.255.255
ip nat inside source list 10 interface e0/0 overload
!
int e0/0
 ip nat outside
!
int e0/1.11
 ip nat inside
!
int e0/1.12
 ip nat inside
!
int e0/1.13
 ip nat inside
!
int e0/1.14
 ip nat inside
!
int e0/1.101
 ip nat inside
!
int e0/1.102
 ip nat inside
!
int e0/1.103
 ip nat inside
!
int e0/1.104
 ip nat inside
 end
!


8. VPC IP 주소 설정

@ VPC1

ip 10.1.11.1 255.255.255.0 10.1.11.254

@ VPC2

ip 10.1.12.1 255.255.255.0 10.1.12.254

@ VPC3

ip 10.1.13.1 255.255.255.0 10.1.13.254

@ VPC4

ip 10.1.14.1 255.255.255.0 10.1.14.254

show ip
save

VPC에서 게이트웨이로 Ping 테스트
VPCx>ping 10.1.x.201
VPCx>ping 10.1.x.202


9. Windows IP 주소 설정 및 Ping 테스트

Windows에서 게이트웨이로 Ping 테스트
Windows>ping 10.1.x.201
Windows>ping 10.1.x.202


10. HSRP 구성

@ GW1
conf t
track 1 interface e0/0 line-protocol
!
int e0/1.11
 standby 11 ip 10.1.11.254
 standby 11 priority 120
 standby 11 preempt
 standby 11 track 1 decrement 30
!
int e0/1.12
 standby 12 ip 10.1.12.254
 standby 12 priority 120
 standby 12 preempt
 standby 12 track 1 decrement 30
!
int e0/1.13
 standby 13 ip 10.1.13.254
 standby 13 priority 120
 standby 13 preempt
 standby 13 track 1 decrement 30
!
int e0/1.14
 standby 14 ip 10.1.14.254
 standby 14 priority 120
 standby 14 preempt
 standby 14 track 1 decrement 30
!
int e0/1.101
 standby 101 ip 10.1.101.254
 standby 101 preempt
!
int e0/1.102
 standby 102 ip 10.1.102.254
 standby 102 preempt
!
int e0/1.103
 standby 103 ip 10.1.103.254
 standby 103 preempt
!
int e0/1.104
 standby 104 ip 10.1.104.254
 standby 104 preempt
 end
!

@ GW2
conf t
track 1 interface e0/0 line-protocol
!
int e0/1.11
 standby 11 ip 10.1.11.254
 standby 11 preempt
!
int e0/1.12
 standby 12 ip 10.1.12.254
 standby 12 preempt
!
int e0/1.13
 standby 13 ip 10.1.13.254
 standby 13 preempt
!
int e0/1.14
 standby 14 ip 10.1.14.254
 standby 14 preempt
!
int e0/1.101
 standby 101 ip 10.1.101.254
 standby 101 priority 120
 standby 101 preempt
 standby 101 track 1 decrement 30
!
int e0/1.102
 standby 102 ip 10.1.102.254
 standby 102 priority 120
 standby 102 preempt
 standby 102 track 1 decrement 30
!
int e0/1.103
 standby 103 ip 10.1.103.254
 standby 103 priority 120
 standby 103 preempt
 standby 103 track 1 decrement 30
!
int e0/1.104
 standby 104 ip 10.1.104.254
 standby 104 priority 120
 standby 104 preempt
 standby 104 track 1 decrement 30
 end
!

show standby brief


11. HSRP 테스트
 
 1) 장애가 없는 경우 

@ GW1 Active 

user1,user2>tracert 168.126.63.1
vpc1,vpc2>trace 168.126.63.1

@ GW2 Active

Windows 서버>tracert 168.126.63.1


 2) GW1 e0/1 장애가 발생한 경우

@ GW1
conf t
int e0/1
 shutdown

GW1,GW2#show standby brief

@ GW2 Active 

user1,user2>tracert 168.126.63.1
vpc1,vpc2>trace 168.126.63.1

@ GW1
conf t
int e0/1
 no shutdown

 3) GW1 e0/0 장애가 발생한 경우

@ GW1
conf t
int e0/0
 shutdown

GW1,GW2#show standby brief

@ GW2 Active 

user1,user2>tracert 168.126.63.1
vpc1,vpc2>trace 168.126.63.1

@ GW1
conf t
int e0/0
 no shutdown

 4) GW2 e0/1 장애가 발생한 경우

@ GW2
conf t
int e0/1
 shutdown

GW1,GW2#show standby brief

@ GW1 Active 

Windows 서버>tracert 168.126.63.1

@ GW2
conf t
int e0/1
 no shutdown

 5) GW2 e0/0 장애가 발생한 경우

@ GW2
conf t
int e0/0
 shutdown

GW1,GW2#show standby brief

@ GW1 Active 

Windows 서버>tracert 168.126.63.1

@ GW2
conf t
int e0/0
 no shutdown


13. PVST를 이용한 VLAN 로드 분산

@ Core1
conf t
spanning-tree vlan 11-14 priority 4096
end

@ DSW11
conf t
spanning-tree vlan 11-14 priority 16384
end

@ Core2
conf t
spanning-tree vlan 101-104 priority 4096
end

@ DSW12
conf t
spanning-tree vlan 101-104 priority 16384
end

Core1,DSW11,ASW101-103#show spanning-tree vlan 11-14
Core2,DSW12,ASW104-106#show spanning-tree vlan 101-104



14. 윈도우 서버 구성

 1) DHCP

@ GW1, GW2
conf t
int e0/1.11
 ip helper-address 10.1.102.200
!
int e0/1.12
 ip helper-address 10.1.102.200
!
int e0/1.13
 ip helper-address 10.1.102.200
!
int e0/1.14
 ip helper-address 10.1.102.200
 end
!

show run


 2) Web 서버

@ GW1, GW2

conf t
ip nat inside source static tcp 10.1.103.200 80 192.168.2.241 80 redundancy HSRP-NAT no-payload
ip nat inside source static tcp 10.1.103.200 443 192.168.2.241 443 redundancy HSRP-NAT no-payload
!
int e0/1.103
standby 103 name HSRP-NAT
end

show run


