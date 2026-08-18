KAIST AI학과 내부망 구축 프로세스

1. 기본 설정

@ 모든 장비

en
conf t
hostname ASW106
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

@ VPC 이름 및 IP 할당
(ex. VPC1)
set pcname VPC1
ip 10.1.11.1/24 10.1.11.254
show ip


@ 스위치 관리 주소 + 기본 게이트웨이 설정 (x-> 포트번호)

conf t
no ip routing
spanning-tree mode rapid-pvst
!
int vlan 1
 ip add 192.168.100.106 255.255.255.0
 no shutdown
!
ip default-gateway 192.168.100.254
end
wr
!

2. Core-DSW 구간 트렁크+이더체널

@ Core1, Core2, DSW11, DSW12
conf t
int range e1/0 - 1
 switchport trunk encapsulation dot1q
 switchport mode trunk
 channel-group 1 mode active
!
int range e2/0 - 1
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
 name VLAN_A
vlan 12
 name VLAN_B
vlan 13
 name VLAN_C
vlan 21
 name VLAN_D
vlan 22
 name VLAN_E
vlan 101
 name Web+DNS
vlan 102
 name DHCP+FTP
vlan 103
 name Email
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
int range e0/2 - 3
 switchport mode access
 switchport access vlan 13
 spanning-tree portfast
 end

@ ASW104
conf t
int e0/2
 switchport mode access
 switchport access vlan 21
 spanning-tree portfast
!
int e0/3
 switchport mode access
 switchport access vlan 101
 spanning-tree portfast
 end

@ ASW105
conf t
int e0/2
 switchport mode access
 switchport access vlan 22
 spanning-tree portfast
!
int e0/3
 switchport mode access
 switchport access vlan 102
 spanning-tree portfast
 end

@ ASW106
conf t
int e0/2
 switchport mode access
 switchport access vlan 103
 spanning-tree portfast
!
int e0/3
 switchport mode access
 switchport access vlan 104
 spanning-tree portfast
 end


show vlan brief

6. Inter-VLAN 구성

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
int e0/1.21
 encapsulation dot1q 21
 ip address 10.1.21.201 255.255.255.0
!
int e0/1.22
 encapsulation dot1q 22
 ip address 10.1.22.201 255.255.255.0
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
int e0/1.21
 encapsulation dot1q 21
 ip address 10.1.21.202 255.255.255.0
!
int e0/1.22
 encapsulation dot1q 22
 ip address 10.1.22.202 255.255.255.0
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
int e0/1.21
 ip nat inside
!
int e0/1.22
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
int e0/1.21
 standby 21 ip 10.1.21.254
 standby 21 preempt
!
int e0/1.22
 standby 22 ip 10.1.22.254
 standby 22 preempt
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
int e0/1.21
 standby 21 ip 10.1.21.254
 standby 21 priority 120
 standby 21 preempt
 standby 21 track 1 decrement 30
!
int e0/1.22
 standby 22 ip 10.1.22.254
 standby 22 priority 120
 standby 22 preempt
 standby 22 track 1 decrement 30
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

13. PVST를 이용한 VLAN 로드 분산

@ Core1
conf t
spanning-tree vlan 11-13 priority 4096
end

@ DSW11
conf t
spanning-tree vlan 11-13 priority 16384
end

@ Core2
conf t
spanning-tree vlan 21-22,101-104 priority 4096
end

@ DSW12
conf t
spanning-tree vlan 21-22,101-104 priority 16384
end

Core1,DSW11,ASW101-103#show spanning-tree vlan 11-14
Core2,DSW12,ASW104-106#show spanning-tree vlan 22-23,101-104

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
int e0/1.21
 ip helper-address 10.1.102.200
!
int e0/1.22
 ip helper-address 10.1.102.200
 end
!

show run

2) Web 서버

@ GW1, GW2

conf t
ip nat inside source static tcp 10.1.101.200 80 192.168.2.241 80 redundancy HSRP-NAT no-payload
ip nat inside source static tcp 10.1.101.200 443 192.168.2.241 443 redundancy HSRP-NAT no-payload
!
int e0/1.101
standby 101 name HSRP-NAT
end

show run