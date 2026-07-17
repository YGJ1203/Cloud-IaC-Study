@ R1
en 	
conf t
hostname R1
enable secret cisco
no ip domain-lookup

line con 0
exec-timeout 0 0
logg syn

line vty 0 4
password ciscovty
login

int fa0/0
ip address 13.13.10.1 255.255.255.0
no shutdown

int s1/0
ip address 13.13.12.1 255.255.255.0
no shutdown
end

@ R2
en 	
conf t
hostname R2
enable secret cisco
no ip domain-lookup

line con 0
exec-timeout 0 0
logg syn

line vty 0 4
password ciscovty
login

int fa0/0
ip address 13.13.20.1 255.255.255.0
no shutdown

int s1/0
ip address 13.13.23.2 255.255.255.0
no shutdown

int s1/1
ip address 13.13.12.2 255.255.255.0
no shutdown
end

@ R3
en 	
conf t
hostname R3
enable secret cisco
no ip domain-lookup

line con 0
exec-timeout 0 0
logg syn

line vty 0 4
password ciscovty
login

int fa0/0
ip address 13.13.30.1 255.255.255.0
no shutdown

int s1/1
ip address 13.13.23.3 255.255.255.0
no shutdown
end

@ 라우팅 프로토콜

 - IP 라우팅을 할 수 있는 경로 정보(네트워크 이름, 넥스트-홉, 메트릭, 기타)를 전송 또는 교환하는 프로토콜
 - 라우팅 프로토콜 종류 : RIPv1, RIPv2, IGRP, EIGRP, OSPF, ISIS, BGPv4
 - 현재 사용하는 라우팅 프로토콜 : BGPv4, OSPF > EIGRP > ISIS 

1. 라우팅 업데이트 방식

 1) Distance Vector

 - RIPv1, RIPv2, IGRP, EIGRP


 2) Link-State

 - OSPF, ISIS 


 3) Path Vector

 - BGPv4



2. 서브넷 처리 방식

 1) Classful 라우팅 프로토콜

 - 네트워크를 클래스로 처리한다. 
 - Ex) 13.13.10.0/24 <- 13.0.0.0
 - RIPv1, IGRP

 2) Classless 라우팅 프로토콜

 - 네트워크를 서브넷 마스크를 참조하여 서브넷으로 처리한다.
 - Ex) 13.13.10.0/24 <- 13.13.10.0/24
 - RIPv2, EIGRP, OSPF, ISIS, BGPv4


3. 자동 요약 실시

 - RIPv2, EIGRP, BGPv4 라우팅 업데이트할 때 자동 클래스풀 요약을 실시한다.
 - 'no auto-summary' 명령을 이용하여 자동 요약을 해지해야 한다.


4. 사용하는 지역

 1) IGP

 - RIPv1, RIPv2, IGRP, EIGRP, OSPF, ISIS
 - 라우팅 업데이트 속도가 빠르고 변경 사항이 빠르게 반영된다.
 - 대신, 많은 양의 라우팅 업데이트가 불가능하다.

 2) EGP 

 - BGPv4
 - 라우팅 업데이트 속도가 느리고 변경 사항이 느리게 반영된다.
 - 대신, 많은 양의 라우팅 업데이트가 가능하다.
 - ISP와 ISP(AS와 AS) 간에 라우팅 업데이트할 때 사용한다.


@ R2, R3
conf t
router rip
 passive-interface fa0/0
 end

show run
show ip protocol

@R1, R2, R3
conf t
router rip
 version 2
 no auto-summary
 network 13.0.0.0
 passive-interface fa0/0
 end

@R1
conf t
int fa0/1
 ip address 61.41.162.129 255.255.255.252
 no shutdown
!
ip route 0.0.0.0 0.0.0.0 61.41.162.130
end

@R2
conf t
ip route 0.0.0.0 0.0.0.0 13.13.12.1

@R3	
conf t
ip route 0.0.0.0 0.0.0.0 13.13.23.2

@R1, R2, R3, R4
conf t 
router rip
 version 2
 no auto-summary
 network 13.0.0.0
 end

2)
@R1

conf t
int fa0/0
ip address 121.172.80.30 255.255.255.224
no shutdown

int fa0/1
ip address 61.41.162.129 255.255.255.252
no shutdown

int  s1/0
ip address 121.172.80.129 255.255.255.252
no shutdown

end

show run
show ip int brief
show ip route

@R2

conf t
int fa0/0
ip address 121.172.80.62 255.255.255.224
no shutdown

int s1/0
ip address 121.172.80.133 255.255.255.252
no shutdown

int s1/1
ip address 121.172.80.130 255.255.255.252
no shutdown

end

show run
show ip int brief
show ip route

@R3

conf t
int fa0/0
ip address 121.172.80.94 255.255.255.224
no shutdown

int s1/1
ip address 121.172.80.134 255.255.255.252
no shutdown

end

3) 패킷 트레이서에서 별도 지정

4) 
 
@ R1, R2, R3
conf t
router rip
version 2
no auto-summary
network 121.0.0.0
end 

++++++ 내부 서버 (Server-PT)도 IP Configuration 해줘야함!!

5) ping www.korea.com -> 확인

6) 

@R1

conf t
int fa0/1
ip route 0.0.0.0 0.0.0.0 61.41.162.130

router rip
default-information originate
end


////////////////////////////////////////// 와일드카드 마스크//////////////////////

Ex4) 192.168.112.32 ~ 192.168.112.63 IP 주소를 한줄로 설정하여라.

192.168.112.001 00000 ~
192.168.112.001 11111
--------------------------------
0.0.0.31

Ex5) A 클래스 IP 주소를 한줄로 설정하여라.

0.0.0.0 ~ 127.255.255.255
0 0000000.00000000.00000000.00000000
0 1111111.11111111.11111111.11111111
---------------------------------------------------------
127.255.255.255

Ex6) B 클래스 IP 주소를 한줄로 설정하여라.

128.0.0.0 ~ 191.255.255.255

10 000000.00000000.00000000.00000000
10 111111.11111111.11111111.11111111
--------------------------------------------------------
00 111111.11111111.11111111.11111111
-> 63.255.255.255

Ex7) C 클래스 IP 주소를 한줄로 설정하여라.

192.0.0.0 ~ 223.255.255.255

110 00000.00000000.00000000.00000000
110 11111.11111111.11111111.11111111
---------------------------------------------------------
000 11111.11111111.11111111.11111111

31.255.255.255 😎

Ex8) A 클래스 사설 IP 주소를 한줄로 설정하여라.

10.0.0.0 0.255.255.255


Ex9) B 클래스 사설 IP 주소를 한줄로 설정하여라.

172.0001 0000.0.0
172.0001 0001.0.0
~
172.0001 1111.0.0
----------------------------> 172.16.0.0 0.15.255.255
   0.0000 1111.255.255 <- 0.15.255.255


Ex10) C 클래스 사설 IP 주소를 한줄로 설정하여라.

192.168.0.0 0.0.255.255


Ex11) IP 주소 전체를 한줄로 설정하여라.

0.0.0.0 255.255.255.255


Ex12) 13.13.10.100 IP 주소 1개를 설정하여라.

13.13.10.100 0.0.0.0


Ex13) 199.172.1.0/24, 199.172.3.0/24를 한줄로 설정하여라.

199.172.000000 0 1.0
199.172.000000 1 1.0
------------------------------> 199.172.1.0 0.0.2.255
   0.   0.000000 1 0.255 <- 0.0.2.255

Ex14) 199.172.1.0/24 ~ 199.172.3.0/24, 199.172.8.0/24 ~ 199.172.11.0/24를 한줄로 설정하여라.

199.172.0000 0 0 01.0
199.172.0000 0 0 10.0
199.172.0000 0 0 11.0
199.172.0000 1 0 00.0
199.172.0000 1 0 01.0
199.172.0000 1 0 10.0
199.172.0000 1 0 11.0
------------------------------> 199.172.0.0 0.0.11.255
    0.   0.0000 1 0 11.255 <- 0.0.11.255

Ex15) 199.172.5.0/24, 199.172.7.0/24, 199.172.10.0/24, 199.172.14.0/24를 두줄로 설정하여라.

199.172.000001 0 1.0
199.172.000001 1 1.0
-----------------------------> 199.172.5.0 0.0.2.255
   0.   0.000000 1 0.255 <- 0.0.2.255

199.172.00001 0 10.0
199.172.00001 1 10.0
-----------------------------> 199.172.10.0 0.0.4.255
   0.    0.00000 1 00.255 <- 0.0.4.255