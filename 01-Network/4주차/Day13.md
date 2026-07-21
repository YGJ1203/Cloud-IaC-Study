16-2

@R1

할당에서 제외 IP 주소
할당한 IP 주소 범위		192.168.1.1 ~ 254
서브넷 마스크		255.255.255.0
기본 게이트웨이		192.168.1.254
DNS 서버			192.168.1.253


DHCP 설정시 169.254 -> 서버 못찾았다는 뜻

conf t
ip dhcp excluded-address 192.168.1.253 192.168.1.254
!
ip dhcp pool NET192
 network 192.168.1.0 255.255.255.0
 default-router 192.168.1.254
 dns-server 192.168.1.253
 end
!

@R3

할당에서 제외 IP 주소
할당한 IP 주소 범위		198.133.219.1 ~ 254
서브넷 마스크		255.255.255.0
기본 게이트웨이		198.133.219.254
DNS 서버			198.133.219.25


DHCP 설정시 169.254 -> 서버 못찾았다는 뜻

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

- Inside Local	192.168.1.0/24
- Inside Global	13.13.12.1

@ R1
conf t
access-list 10 permit 192.168.1.0 0.0.0.255
!
ip nat inside source list 10 interface s1/0 overload
!
int s1/0
ip nat outside
!
int fa0/0
ip nat inside
end
!

@ R1
conf t
!
ip nat inside source static tcp 192.168.1.253 80 13.13.12.100 80
ip nat inside source static tcp 192.168.1.253 443 13.13.12.100 443
end
!

NAT	마스커레이드
PAT	포트포워딩

--------------------- EVE 실습 ------------------------

@ R1, SW1
en
conf t
hostname SW1
no cdp run
no ip domain-lookup
enable secret cisco
!
line con 0
logg syn
exec-timeout 0 0
!
line vty 0 4
transport input all
password ciscovty
login
end
!

@ R1
conf t 
int e0/0
ip address 10.1.1.254 255.255.255.0
no shutdown
!
int e0/1
ip address 192.168.2.101 255.255.255.0
no shutdown
!
ip route 0.0.0.0 0.0.0.0 192.168.2.254
end

내부 네트워크를 만들면 이상이 없는지 꼭 확인해야함!!

WEB+DNS		10.1.1.201
INTRANET		10.1.1.202
DHCP+FTP	10.1.1.203
EMAIL 		10.1.1.204

할당에서 제외시킬 IP 주소 10.1.1.201 ~ 204
할당  IP 주소 범위	10.1.1.1 ~ 10.1.1.254 		
서브넷 마스크	255.255.255.0
기본 게이트웨이 주소	10.1.1.254
DNS 서버		10.1.1.201, 168.126.63.1

@ R1
conf t
ip dhcp excluded-address 10.1.1.201 10.1.1.204
!
ip dhcp pool NET10
network 10.1.1.0 255.255.255.0
default-router 10.1.1.254
dns-server 10.1.1.201 168.126.63.1
lease 100 10 10
end
!

@ 나머지 VPC
ip dhcp
ping 10.1.1.254

@ R1

- Inside Local	10.1.1.0/24
- Inside Global	192.168.2.101

conf t
access-list 10 permit 10.1.1.0 0.0.0.255
!
ip nat inside source list 10 interface e0/1 overload
!
int e0/1
ip nat outside
!
int e0/0
ip nat inside
end
!

@ R1

inside local	10.1.1.1
inside global	192.168.2.100

conf t
ip nat inside source static 10.1.1.1 192.168.2.100
end
!

-----------------------------------------
win2008 administrator/toor1234.
win2003 ad/toor
win7 ad/toor

개강