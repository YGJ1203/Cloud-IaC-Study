15-2

@ R3
conf t
access-list 110 deny tcp 13.13.10.0 0.0.0.255 13.13.30.0 0.0.0.255 eq 23
access-list 110 deny icmp any host 13.13.30.3 echo
access-list 110 deny tcp 13.13.20.0 0.0.0.255 host 13.13.30.3 eq 80
access-list 110 deny tcp 13.13.20.0 0.0.0.255 host 13.13.30.3 eq 443
access-list 110 deny tcp host 13.13.20.2 host 13.13.30.3 range 20 21
access-list 110 permit ip any any
!
int s1/1
ip access-group 110 in
end

pc에서 nslookup (사이트주소) -> IP주소 가능


15-3

@ R1, R2, R3 (ip 설정만 바꿔주면 됨)
각각 사이트에서 141.101.121.208/24, 81.150.200.78/24 접근못하게 차단

conf t
access-list 110 deny ip 13.13.30.0 0.0.0.255 host 141.101.121.208
access-list 110 deny ip 13.13.30.0 0.0.0.255 host 81.150.200.78
access-list 110 permit ip any any
!
int fa0/0
 ip access-group 110 in 
end
!

ex2)

@ R1
conf t
access-list 120 permit tcp 13.13.20.0 0.0.0.255 host 13.13.10.100 eq 80
access-list 120 permit tcp 13.13.20.0 0.0.0.255 host 13.13.10.100 eq 443
access-list 120 permit tcp 13.13.20.0 0.0.0.255 host 13.13.10.100 range 20 21
access-list 120 permit tcp 13.13.30.0 0.0.0.255 host 13.13.10.100 eq 80
access-list 120 permit tcp 13.13.30.0 0.0.0.255 host 13.13.10.100 eq 443
access-list 120 permit tcp 13.13.30.0 0.0.0.255 host 13.13.10.100 range 20 21
access-list 120 deny tcp any host 13.13.10.100 eq 80
access-list 120 deny tcp any host 13.13.10.100 eq 443
access-list 120 deny tcp any host 13.13.10.100 range 20 21
access-list 120 permit icmp 13.13.20.0 0.0.0.255 host 13.13.10.100 echo-reply
access-list 120 permit icmp 13.13.30.0 0.0.0.255 host 13.13.10.100 echo-reply
access-list 120 deny icmp any host 13.13.10.100
access-list 120 permit ip any any
!
int s0/0/0
 ip access-group 120 in
!

------------------- IPv6 -------------------------------
2007:0000:0000:09c0:8f30:24fe:0000:00ca/64

2007::9c0:8f30:24fe:0:ca/64

2007:0000:0000:0000:8f30:0000:0000:00ca/64


2007::8f30:0:0:ca/64


0000:0000:0000:0000:0000:0000:0000:0000/0
ipv6 route ::/0

@ R1

conf t
ipv6 unicast-routing
!
int fa0/0
 ipv6 enable
 ipv6 address 2001:100:100:100::1/64
!
int s1/0/0
 ipv6 enable
 ipv6 address 2001:12:12:12::1/64
end

show run
show ipv6 int brief
show ipv6 route
ping

@R2, R3 위와 같이 설정

@ R1
conf t
ipv6 route 2001:200:200:200::/64 2001:12:12:12::2
ipv6 route 2001:23:23:23::/64 2001:12:12:12::2
ipv6 route 2001:300:300:300::/64 2001:12:12:12::2
end
!

@ R2
conf t
ipv6 route 2001:100:100:100::/64 2001:12:12:12::1
ipv6 route 2001:300:300:300::/64 2001:23:23:23::3
end
!

@ R3
conf t
ipv6 route ::/0 2001:23:23:23::2
end
!

@ R1
conf t
ipv6 router rip 1
!
int fa0/0
 ipv6 rip 1 enable
!
int s1/0/0
 ipv6 rip 1 enable
 end

show run
show ipv6 route

@ R2
conf t
ipv6 router rip 2
!
int fa0/0
 ipv6 rip 2 enable
!
int s1/0/0
 ipv6 rip 2 enable
!
int s1/0/1
 ipv6 rip 2 enable
 end

show run
show ipv6 route

@ R3
conf t
ipv6 router rip 3
!
int fa0/0
 ipv6 rip 3 enable
!
int s1/0/1
 ipv6 rip 3 enable
 end

show run
show ipv6 route

@ R1, R2, R3
conf t 
ipv6 router eigrp 100
no shutdown
!
int fa0/0
 ipv6 eigrp 100
!

int s1/0/0
 ipv6 eigrp 100
end
!

show run
show ipv6 eigrp neighbor

conf t
no ipv6 router eigrp 100
end
!

@ R1, R2, R3
conf t
ipv6 router ospf1
router-id 1.1.1.1
!
int fa0/0
 ipv6 ospf 1 area 0
!
int s1/0/0
ipv6 ospf 1 area 0
end

show run
show ipv6 ospf neighbor
show ipv6 ospf database
show ipv6 route

------------------DHCP------------------

할당에서 제외시킬 IP 주소   /16-2 기준 192.168.1.253 ~ 192.168.1.254
IP 주소		192.168.1.1 ~ 254
서브넷 마스크	255.255.255.0
기본 게이트웨이	192.168.1.254
DNS 서버		192.168.1.253

@ R1
conf t
ip dhcp excluded-address 192.168.1.253 192.168.1.254
!
ip dhcp pool NET192
 network 192.168.1.0 255.255.255.0
 default-router 192.168.1.254
 dns-server 192.168.1.253
 end
!

@ R3

할당에서 제외시킬 IP 주소   /16-2 기준 198.133.219.25, 198.133.219.254
IP 주소		198.133.219.1 ~ 254
서브넷 마스크	255.255.255.0
기본 게이트웨이	198.133.219.254
DNS 서버		198.133.219.25



conf t
ip dhcp excluded-address 198.133.219.25
ip dhcp excluded-address 198.133.219.254
!
ip dhcp pool NET198
 network 198.133.219.0 255.255.255.0
 default-router 198.133.219.254
 dns-server 198.133.219.25
 end
!

@ ISP
conf t
ip dhcp excluded-address 13.13.111.254
!
ip dhcp pool NET13
 network 13.13.111.0 255.255.255.0
 default-router 13.13.111.254
 dns-server 168.126.63.1
 end
!

@ R2
conf t
int fa0/1
ip address dhcp
no shutdown

A(192.168.1.1) -> 198.133.219.25

ICMP Echo
-------------------------------ICMP
SA 192.168.1.1
DA 198.133.219.25
-------------------------------IP

A(192.168.1.1) <- 198.133.219.25

ICMP Echo-Reply
-------------------------------ICMP
SA 198.133.219.25
DA 192.168.1.1
-------------------------------IP

- Inside Local	192.168.1.0/24	<- ACL
- Inside Global	13.13.12.1

@ R1
conf t
access-list 10 permit 192.168.1.0 0.0.0.255
!
ip nat inside source list 10 interface s1/0 overload
!
int fa0/0
 ip nat inside
!
int s1/0
 ip nat outside
end
!

- Inside Local	192.168.1.253
- Inside Global	13.13.12.100

@ R1
conf t
ip nat inside source static 192.168.1.253 13.13.12.100
end
!

conf t
no ip nat inside source static 192.168.1.253 13.13.12.100
end
!

conf t
ip nat inside source static tcp 192.168.1.253 80 13.13.12.100 80
ip nat inside source static tcp 192.168.1.253 443 13.13.12.100 443