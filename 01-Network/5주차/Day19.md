1. 기본 설정

@ GW1
en
conf t
hostname GW1
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


@ DSW11, ASW101 ~ ASW104
en
conf t
hostname ASW104
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
!
int vlan 1
 ip address 192.168.100.104 255.255.255.0
 no shutdown
!
ip default-gateway 192.168.100.254
end
!

2. 트렁크 구성

@DSW11
conf t
int range e0/0,e1/0 - 3
 switchport trunk encapsulation dot1q
 switchport mode trunk
 end
!

@ASW101 ~ 104

conf t
int range e1/0
 switchport trunk encapsulation dot1q
 switchport mode trunk
 end
!

show run
show int trunk

3. VLAN 생성

@ 모든 스위치
conf t
vlan 11
 name VLAN_A
vlan 12
 name VLAN_B
vlan 13
 name VLAN_C
vlan 14
 name VLAN_D
vlan 15
 name VLAN_E
vlan 16
 name VLAN_F
 end
! 

show vlan brief

4. VLAN Access 설정

@ ASW101
conf t
 int range e0/1 - 2 
 switchport mode access
 switchport access vlan 11
 end
!

@ ASW102
conf t
 int range e0/1 - 2 
 switchport mode access
 switchport access vlan 12
 end
!

@ ASW103
conf t  
int e0/1
 switchport mode access
 switchport access vlan 13
!
int e0/2
 switchport mode access
 switchport access vlan 14
end
! 

@ ASW104
conf t  
int e0/1
 switchport mode access
 switchport access vlan 15
!
int e0/2
 switchport mode access
 switchport access vlan 16
end
!  


5. Inter-VLAN 설정

@GW11

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


6. ping test

 - 각각의 시스템에서 게이트웨이로 Ping 테스트
 - 서로 다른 VLAN 간의 ping 테스트

user1, user2 >ping 10.1.x.200


7. 인터넷 연결 설정

@GW1
conf t
int e0/1
 ip address 192.168.2.251 255.255.255.0
 no shutdown
!
ip route 0.0.0.0 0.0.0.0 192.168.2.254
end
!
show run

@ GW1
conf t
access-list 10  permit 10.1.0.0 0.0.255.255
!
ip nat inside source list 10 interface e0/1 overload
!
int e0/1
 ip nat outside
!
int e0/0.11
 ip nat inside 
!
int e0/0.12
 ip nat inside 
!
int e0/0.13
 ip nat inside 
!
int e0/0.14
 ip nat inside 
!
int e0/0.15
 ip nat inside 
!
int e0/0.16
 ip nat inside 
end
!
8. 인터넷 통신 테스트

 - 각각의 시스템에서 'ping 168.126.63.1' 실시
 - 윈도우 시스템에서 브라우저 실행 -> www.google.com 접속 실시


9. 윈도우 서버 구성

 1) DHCP 서버

  - 12p 참조

@ GW1
 conf t
 int e0/0.11
 ip helper-address 10.1.13.200
!
int e0/0.12
 ip helper-address 10.1.13.200
 end
!

 2) Web 서버 + GW1 정적 NAT

@GW1
conf t
ip nat inside source static tcp 10.1.14.200 80 192.168.2.251 80
ip nat inside source static tcp 10.1.14.200 443 192.168.2.251 443
end
!

 3) 인트라넷 서버
 4) FTP 서버
 5) DNS 서버
 6) 이메일 서버