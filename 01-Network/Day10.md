@ R1
conf t
 router ospf 1
 router-id 1.1.1.1
 network 13.13.10.0 0.0.0.255 area 0
 network 13.13.12.0 0.0.0.255 area 0
passivve-interface fa0/0
end

@ R2
conf t
 router ospf 1
 router-id 2.2.2.2
 network 13.13.20.0 0.0.0.255 area 0
 network 13.13.12.0 0.0.0.255 area 0
 network 13.13.23.0 0.0.0.255 area 0
 passive-interface fa0/0
 end

@ R3
conf t
router ospf 1
router-id 3.3.3.3
network 13.13.23.0 0.0.0.255 area 0
network 13.13.30.0 0.0.0.255 area 0
passive-interface fa0/0
end

LSDB (Link Start DataBase)

IP 참고 주소 : https://www.iana.org/assignments/multicast-addresses/multicast-addresses.xhtml

@ R1 링크 정보 (Show ip ospf database)

13.13.10.0/24
13.13.12.0/24
R2와 연결된 IP 주소 13.13.12.1

@ R2 링크 정보 - 5개

13.13.12.0/24
13.13.20.0/24
13.13.23.0/24
R1와 연결된 IP 주소 13.13.12.2
R3와 연결된 IP 주소 13.13.23.2

@ R3 링크 정보 - 3개

13.13.23.0/24
13.13.30.0/24
R2와 연결된 IP 주소 13.13.23.3

@ R3 
conf t
int lo 1
ip address 100.100.1.1 255.255.255.0
int lo 2
ip address 100.100.2.1 255.255.255.0
int lo 3
ip address 100.100.3.1 255.255.255.0

int lo 11
ip address 200.200.1.1 255.255.255.0
int lo 12
ip address 200.200.2.1 255.255.255.0
int lo 13
ip address 200.200.3.1 255.255.255.0

router rip 
version 2
no auto-summary
network 100.0.0.0

router ospf 1
network 200.200.0.0 0.0.255.255 area 13
redistribute rip subnets
end

@ R1
conf t
int fa0/1
ip address 211.242.181.57 255.255.255.252
no shutdown

ip route 0.0.0.0 0.0.0.0 211.242.181.58
end

@ R2
conf t
ip route 0.0.0.0 0.0.0.0 211.242.181.58

@R3
conf t
ip route 0.0.0.0 0.0.0.0 211.242.181.58

------------------------------------------------------------------------
@ R11
en
conf t
int fa0/1
 ip ospf priority 255
 end

@ R12
en
conf t
int fa0/1
 ip ospf priority 254
 end

@ R13,14,15
en
conf t
int fa0/1
 ip ospf priority 0
 endㅅ


14-6

ABR : 해당 예제 기준 Area0과 각 Area가 동시에 연결된 라우터 : R2, R3, R6, R7

R1 정보 :
interface FastEthernet0/0
 ip address 132.100.5.254 255.255.254.0  132.100.5.254/23
 duplex auto
 speed auto
!

512

세번째 옥텟 2씩 증가

network 132.100.4.0 0.0.1.255 area 100

interface FastEthernet0/1
 ip address 132.100.6.30 255.255.255.224
 duplex auto
 speed auto
!

132.100.6.30/27
32씩 증가
132.100.6.0 0.0.0.31 area 100

interface Serial0/0
 ip address 132.100.6.33 255.255.255.252
!

132.100.6.33/30
4씩 증가
132.100.6.32 0.0.0.3 area 100

R2 정보 :
interface FastEthernet0/0
 ip address 132.100.3.254 255.255.252.0
 duplex auto
 speed auto
!

132.100.3.254/22
1024씩 증가
세번째 옥텟 4씩 증가

132.100.0.0 0.0.3.255 area 100

interface Serial0/0
 ip address 198.133.100.1 255.255.255.252
 clock rate 1000000
!

198.133.100.1/30
4씩 증가
198.133.100.0 0.0.0.3 area 0

interface Serial0/1
 ip address 132.100.6.34 255.255.255.252
 clock rate 1000000
!

* 나중에 하기

---------------------------------------------------- EVE----------------------------------------------
en
conf t
hostname R3
no ip domain-lookup
no cdp run
enable secret cisco
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

@R1
conf t
int e0/0
 ip address 13.13.10.1 255.255.255.0
 no shutdown
!
int e0/1
 ip address 13.13.12.1 255.255.255.0
 no shutdown
 end
!

show run
show ip int brief
show ip route

@R2
conf t
int e0/0
ip address 13.13.20.1 255.255.255.0
no shutdown
!

int e0/1
ip address 13.13.23.2 255.255.255.0
no shutdown
!

int e0/2 
ip address 13.13.12.2 255.255.255.0
no shutdown
end
!

@R3
conf t
int e0/0
 ip address 13.13.30.1 255.255.255.0
 no shutdown
!
int e0/2
 ip address 13.13.23.3 255.255.255.0
 no shutdown
 end
!

@VPC2
set pcname VPC2
ip 13.13.20.2 255.255.255.0 13.13.20.1
ip dns 168.126.63.1


@VPC3
set pcname VPC3
ip 13.13.30.2 255.255.255.0 13.13.30.1
ip dns 168.126.63.1

@R1

conf t
ip route 13.13.20.0 255.255.255.0 13.13.12.2
ip route 13.13.23.0 255.255.255.0 13.13.12.2
ip route 13.13.30.0 255.255.255.0 13.13.12.2
end

@R2

conf t
ip route 13.13.10.0 255.255.255.0 13.13.12.1
ip route 13.13.30.0 255.255.255.0 13.13.23.3
end

@R3

conf t
ip route 13.13.10.0 255.255.255.0 13.13.23.2
ip route 13.13.12.0 255.255.255.0 13.13.23.2
ip route 13.13.20.0 255.255.255.0 13.13.23.2
end

@R1

conf t
int e0/2
 ip address 192.168.2.101 255.255.255.0
 no shutdown
!
ip route 0.0.0.0 0.0.0.0 192.168.2.254
end

show run
show ip int brief
show ip route
ping 192.168.2.254
ping 168.126.63.1

@R2
conf t
ip route 0.0.0.0 0.0.0.0 13.13.12.1
end
!

@R3
conf t
ip route 0.0.0.0 0.0.0.0 13.13.23.2
end
!

@ R1, R2, R3
conf t
router rip
version 2
no auto-summary
network 13.0.0.0
passive-interface e0/0
end

show run
show ip route

@R1
conf t
int e0/2
 ip address 192.168.2.101 255.255.255.0
 no shutdown
!
ip route 0.0.0.0 0.0.0.0 192.168.2.254
!
router rip
 default-information originate
 end

@ R1, R2, R3
conf t
no router rip
router eigrp 100
no auto-summary
network 13.0.0.0
passive-interface e0/0
end
!

show run
show ip eigrp neighbor
show ip route

@ R1
conf t
router eigrp 100
redistribute static
end

R1#show run

R1,R2,R3# show ip route
	ping 168.126.63.1
	ping 8.8.8.8

@ R1, R2, R3
conf t
no router eigrp 100
!

@ R1
conf t
router ospf 1
router-id 1.1.1.1
network 13.13.10.0 0.0.0.255 area 0
network 13.13.12.0 0.0.0.255 area 0
passive-interface e0/0
end

show ip ospf neighbor
show ip route

@ R2
conf t
router ospf 1
router-id 2.2.2.2
network 13.13.12.0 0.0.0.255 area 0
network 13.13.20.0 0.0.0.255 area 0
network 13.13.23.0 0.0.0.255 area 0
passive-interface e0/0
end

@ R3
conf t
router ospf 1
router-id 3.3.3.3
network 13.13.23.0 0.0.0.255 area 0
network 13.13.30.0 0.0.0.255 area 0
passive-interface e0/0
end

@R1
conf t
router ospf 1
default-information originate
end
!

R1#show run

R1,R2,R3# show ip route
	ping 168.126.63.1
	ping 8.8.8.8