en
conf t
!
hostname R1
!
no ip domain-lookup
!
enable secret cisco
!
line con 0
logg syn
exec-timeout 0 0 
password ciscocon
login
!
line vty 0 4
password ciscovty
login
!
int fa0/0
ip address 13.13.10.1 255.255.255.0
no shutdown
!
int s1/0
ip address 13.13.12.1 255.255.255.0
no shutdown
end
!

@ R2 

en
conf t
!
hostname R2
!
no ip domain-lookup
!
enable secret cisco
!
line con 0
logg syn
exec-timeout 0 0 
password ciscocon
login
!
line vty 0 4
password ciscovty
login
!
int fa0/0
ip address 13.13.20.1 255.255.255.0
no shutdown
!
int s1/0
ip address 13.13.23.2 255.255.255.0
no shutdown
!
int s1/1
ip address 13.13.12.2 255.255.255.0
no shutdown
end
!

@ R3 

en
conf t
!
hostname R3
!
no ip domain-lookup
!
enable secret cisco
!
line con 0
logg syn
exec-timeout 0 0 
password ciscocon
login
!
line vty 0 4
password ciscovty
login
!
int fa0/0
ip address 13.13.30.1 255.255.255.0
no shutdown
!
int s1/1
ip address 13.13.23.3 255.255.255.0
no shutdown
end
!

@ R1, R2, R3
conf t
router eigrp 100
 no auto-summary
 network 13.0.0.0
 passive-interface fa0/0
 end

show run
show ip eigrp neighbor
show ip route

@ R2
conf t
int s1/0
 bandwidth 2048
 end

@ R3
conf t
int s1/0
bandwidth 2048
int s1/1
bandwidth 2048
end

@R4
en
conf t
int s1/1
bandwidth 2048
end

@R1
conf t
int lo 1
ip address 128.28.8.1 255.255.255.0
int lo 2
ip address 128.28.9.1 255.255.255.0
int lo 3
ip address 128.28.10.1 255.255.255.0
int lo 4
ip address 128.28.11.1 255.255.255.0
int lo 5
ip address 128.28.12.1 255.255.255.0
router eigrp 100
network 128.28.0.0
passive-interface lo1
passive-interface lo2
passive-interface lo3
passive-interface lo4
passive-interface lo5
end

128.28.8.0/24  ~ 128.28.12.0/24
--------------------------------------------- 128.28.0.0/16


  128.28.00001 000.0
  128.28.00001 001.0
  128.28.00001 010.0
  128.28.00001 011.0
  128.28.00001 100.0
---------------------------------------------> 128.28.8.0./21
255.255.11111 000.0 <- 255.255.248.0 <- /21

@R3
conf t
int lo 1
ip address 100.100.1.1 255.255.255.0
int lo 2
ip address 100.100.2.1 255.255.255.0
int lo 3
ip address 100.100.3.1 255.255.255.0
router rip
version 2
no auto-summary
network 100.0.0.0
router eigrp 100
redistribute rip metric 1544 2000 255 1 1500
end

@R1
conf t
int fa0/1
ip address 61.41.162.129 255.255.255.252
no shutdown
!
ip route 0.0.0.0 0.0.0.0 61.41.162.130
end
!

show run
show ip int brief
show ip route
ping 61.41.162.130 
ping 168.126.63.1

@R2

conf t
ip route 0.0.0.0 0.0.0.0 13.13.12.1
end

@R3
conf t
ip route 0.0.0.0 0.0.0.0 13.13.23.2
end

----------------------------------------------------------------------------
13-5 
PC3과 PC5에서 다른 PC로 ping이 안되는데, 핑이 가능하도록 해결해야함.

@ RTC
show ip route
show ip eigrp neighbors
show run

---------------------------------------------------------------------------
en 
conf t
hostname R3
no ip domain-lookup
no cdp run
enable secret cisco

line con 0
logg syn
exec-timeout 0 0

line vty 0 4
password ciscovty
login
transport input all
end