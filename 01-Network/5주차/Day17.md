PC1~PC4>ping -t 168.126.63.1


Ex1) '0001.9619.038C' MAC 주소를 사용하는 PC 찾기(각각의 장비 접속 가능)

ipconfig /all (X)
라우터부터 확인 -> CLI 들어가서 show arp
-> SW2 확인 : show mac address-table Fa0/22 포트 연결 확인
-> SW3 확인 : show mac address-table Fa0/1 포트 연결 확인
-> PC3 확인
(근데 일일이 이렇게 왔다갔다 하면 비효율적이니, 작업 노트북으로 telnet으로 한번에 조회하는게 효율적.
허나 이 과정을 하려면, 우선적으로 각 스위치에 vlan 설정 필수)

@ SW1, SW2, SW3
conf t
int vlan 1
ip address 13.13.10.10x 255.255.255.0
no shutdown
end
!
show run

이후 작업 노트북에서 show arp, show mac address-table로 확인
+ show cdp neighbor (detail)

@SW1, SW2, SW3
conf t
username admin privilege 15 password 0 cisco
username user1 password 0 cisco
!
line vty 0 4
login local
!
end

@ R1
conf t
username admin privilege 15 password 0 cisco
username user1 password 0 cisco
!
ip domain-name example7777.com
!
crypto key generate rsa
!	
ip ssh version 2
!
line vty 0 4
login local
!
end
!
ssh -1 admin 13.13.10.254
Ex2) '0001.43EA.A46A' MAC 주소를 사용하는 PC 찾기(담당자 노트북에서만 작업 실시)


18-4

@ R1
en
conf t
hostname R1
no ip domain-lookup
!
line con 0
exec-timeout 0 0
logg syn
!
line vty 0 4
password ciscovty
login
!
int fa0/0
ip address 192.168.100.254 255.255.255.0
no shutdown
end
!

@ SW1
en
conf t
hostname SW1
no ip domain-lookup
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
ip address 192.168.100.1 255.255.255.0
no shutdown
!
ip default-gateway 192.168.100.254
end
!

@ SW2
en
conf t
hostname SW2
no ip domain-lookup
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
ip address 192.168.100.2 255.255.255.0
no shutdown
!
ip default-gateway 192.168.100.254
end
!

@ SW3
en
conf t
hostname SW3
no ip domain-lookup
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
ip address 192.168.100.3 255.255.255.0
no shutdown
!
ip default-gateway 192.168.100.254
end
!



@ R1
conf t
int fa0/1
 ip address dhcp
 no shutdown
!
ip route 0.0.0.0 0.0.0.0 192.168.10.1
end

show run
show ip int brief
show ip route

이어서 NAT 설정

conf t
access-list 10 permit 192.168.100.0 0.0.0.255
!
ip nat inside source list 10 interface fa0/1 overload
!
int fa0/1
 ip nat outside
!
int fa0/0
 ip nat inside
 end
!

PC1~PC4>ping 168.126.63.1
R1#show ip nat translation

SW1,SW2,SW3,R1 #reload

19-1 VLAN

@ SW1
conf t
vlan 11
name VLAN_A
vlan 12
name VLAN_B
end

- vlan 11	fa0/1 - 7, fa0/11 - 15
- vlan 12	fa0/8 - 10, fa0/16, fa0/19 -20



conf t
int range fa0/1 - 7, fa0/11 - 15
switchport mode access
switchport access vlan 11
!
int range fa0/8 - 10 , fa0/16, fa0/19 - 20
switchport mode access
switchport access vlan 12
!

@ SW1, SW2
conf t
int fa0/24
switchport trunk encapsulation dot1q
switchport mode trunk
end
!

@ SW1만 추가
conf t
int fa0/10
switchport trunk encapsulation dot1q
switchport mode trunk
end
!

show run
show int trunk

@ R1
conf t
int fa0/0
no shutdown
!

int fa0/0.11
 encapsulation dot1q 11
 ip address 192.168.11.254 255.255.255.0
!
int fa0/0.12
 encapsulation dot1q 12
 ip address 192.168.12.254 255.255.255.0
!
int fa0/0.13
 encapsulation dot1q 13
 ip address 192.168.13.254 255.255.255.0
end

@SW1
conf t
int vlan 1
 ip address 192.168.100.1 255.255.255.0
 no shutdown
!
ip default-gateway 192.168.100.254
end

@SW2
conf t
int vlan 1
 ip address 192.168.100.2 255.255.255.0
 no shutdown
!
ip default-gateway 192.168.100.254
end

@ R1
conf t
int fa0/0.1
 encapsulation dot1q 1
 ip address 192.168.100.254 255.255.255.0
 end
!

@ SW1, SW2
conf t
vlan 14
 name VLAN_D
 end

@ SW2
conf t
int range fa0/6 - 7
 switchport mode access
 switchport access vlan 14
 end

show vlan brief

@ R1
conf t
int fa0/0.14
 encapsulation dot1q 14
 ip address 192.168.14.254 255.255.255.0
 end
!

@ R1
conf t
int fa0/0.11
 ip helper-address 192.168.14.200
!
int fa0/0.12
 ip helper-address 192.168.14.200
!
int fa0/0.13
 ip helper-address 192.168.14.200
end
!

@ R1
conf t
access-list 10 permit 192.168.0.0 0.0.255.255
!
ip nat inside source list 10 interface fa0/1 overload
!
int fa0/1
 ip nat outside
!
int range fa0/0.11, fa0/0.12, fa0/0.13, fa0/0.14
 ip nat inside
!

19-4

@ SW1, SW2
conf t
int fa0/24
 switchport trunk encapsulation dot1q
 switchport mode trunk

@ 문제를 해결하기 위한 정보 확인

 - SW1,SW2,R5#show run
 - SW1,SW2#show int trunk
 - SW1,SW2#show vlan brief
 - R5#show ip route
 - PC IP 주소 및 게이트웨이 주소 정보 확인