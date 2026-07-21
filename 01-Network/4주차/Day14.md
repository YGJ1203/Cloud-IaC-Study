Cloud1		VMnet1->DHCP + FTP
Cloud2		VMnet2-> WEB+DNS
Cloud3		VMnet3->Intranet
Cloud4		VMnet4->Email
Cloud5		VMnet5 -> user 1
Cloud6		VMnet6 -> user 2

---------------------------------------------------------------- EVE + 윈도우 서버

@R1, SW1
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



@ R1
conf t
int e0/0
ip address 10.1.11.254 255.255.255.0
no shutdown
!
int e0/1
ip address 192.168.2.101 255.255.255.0
no shutdown
!
ip route 0.0.0.0 0.0.0.0 192.168.2.254
end

ping 168.126.63.1

@ R1

conf t
access-list 10 permit 10.1.11.0 0.0.0.255
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
conf t
ip nat inside source static tcp 10.1.11.202 80 192.168.2.100 80 
ip nat inside source static tcp 10.1.11.201 21 192.168.2.100 21 (필요하다면)
end
!