# 🌐 IPv4 Subnetting

## 📌 IPv4 Address

IPv4는 32bit 주소 체계를 사용한다.

```
IPv4 = 32bit

2^32개의 주소 표현 가능
```

IPv6:

```
IPv6 = 128bit
```

---

# 📌 Binary 계산

네트워크에서는 2진수 계산이 중요하다.

## 1 Byte

```
1 Byte = 8 bit
```

각 자리 값:

|Bit|Value|
|-|-|
|2^7|128|
|2^6|64|
|2^5|32|
|2^4|16|
|2^3|8|
|2^2|4|
|2^1|2|
|2^0|1|

---

# Subnet Mask Binary

|Binary|Decimal|
|-|-|
|11111111|255|
|11111110|254|
|11111100|252|
|11111000|248|
|11110000|240|
|11100000|224|
|11000000|192|
|10000000|128|

---

# 📌 Subnet Mask

Subnet Mask는 IP 주소에서 Network 영역과 Host 영역을 구분하기 위해 사용한다.

목적:

- Network 구분
- IP 주소 관리
- IP 낭비 감소

특징:

Subnet Mask의 bit 1은 반드시 연속되어야 한다.

가능:

```
11111111.11111111.11111111.00000000
```

불가능:

```
11111111.11101011.00000000.00000000
```

---

# 📌 Network ID / Host ID

Example:

```
121.160.43.23

Subnet Mask

255.255.255.0
```

분리:

```
Network ID

121.160.43


Host ID

23
```

---

# 📌 Prefix (CIDR)

CIDR(Classless Inter-Domain Routing)은 Prefix 길이로 Network 영역을 표현하는 방식이다.

Example:

```
192.168.1.0/24
```

의미:

```
Network bit : 24

Host bit : 8
```

Subnet Mask:

```
255.255.255.0
```

---

# 📌 Host 개수 계산

공식:

```
2^Host bit - 2
```

-2 이유:

사용 불가능 주소 존재

1)

Network Address

2)

Broadcast Address


Example:

```
192.168.1.0/24
```

Host bit:

```
8
```

계산:

```
2^8 -2

=254개
```

---

# 📌 Network / Host / Broadcast

Example:

```
192.168.1.0/24
```

## Network Address

```
192.168.1.0
```

네트워크 자체를 의미

사용 불가


## Host Range

```
192.168.1.1

~

192.168.1.254
```

장비 설정 가능


## Broadcast Address

```
192.168.1.255
```

전체 Host 대상 전송

사용 불가

---

# 📌 Private IP Range

RFC1918 기준 사설 IP 영역

## Class A

```
10.0.0.0/8
```

범위:

```
10.0.0.0

~

10.255.255.255
```

---

## Class B

```
172.16.0.0/12
```

범위:

```
172.16.0.0

~

172.31.255.255
```

---

## Class C

```
192.168.0.0/16
```

범위:

```
192.168.0.0

~

192.168.255.255
```

---

# 📌 Subnetting

Subnetting이란?

하나의 큰 Network를 여러 개의 작은 Network로 나누는 작업

목적:

- IP 주소 낭비 감소
- 효율적인 네트워크 관리

---

# Subnet 계산 방법

Example:

```
198.133.219.0/24
```

조건:

Subnet 5개 이상 필요

Host 29개 필요

---

필요 Host bit 계산:

```
2^x - 2 >= 29

x = 5
```

Host bit:

```
5bit
```

Prefix:

```
32 - 5

= /27
```

Subnet Mask:

```
255.255.255.224
```

---

증가 단위:

```
256 - 224

= 32
```

Subnet:

```
198.133.219.0/27

198.133.219.32/27

198.133.219.64/27

...
```

---

# 📌 /27 Example

```
141.160.7.148/27
```

/27:

```
255.255.255.224
```

Block:

```
32씩 증가
```

Range:

```
128 ~ 159
```

결과:

Network:

```
141.160.7.128
```

Host:

```
141.160.7.129 ~ 141.160.7.158
```

Broadcast:

```
141.160.7.159
```

---

# 📌 /28 Example

```
181.160.85.225/28
```

Subnet Mask:

```
255.255.255.240
```

Block:

```
16씩 증가
```

Network:

```
181.160.85.224
```

Host:

```
181.160.85.225 ~ 238
```

Broadcast:

```
181.160.85.239
```

---

# 📌 /30 Example

```
192.168.1.133/30
```

Subnet Mask:

```
255.255.255.252
```

Block:

```
4씩 증가
```

Network:

```
192.168.1.132
```

Host:

```
192.168.1.133
192.168.1.134
```

Broadcast:

```
192.168.1.135
```

---

# 📌 다른 Octet Subnet 계산

Example:

```
132.21.128.0/23
```

Subnet Mask:

```
255.255.254.0
```

3번째 Octet 기준:

```
256 - 254

= 2씩 증가
```

Network:

```
132.21.128.0
```

범위:

```
132.21.128.0

~

132.21.129.255
```

Host:

```
132.21.128.1

~

132.21.129.254
```

Broadcast:

```
132.21.129.255
```

---

# 📌 Default Gateway 판단 과정

Host는 목적지가 같은 Network인지 먼저 판단한다.


같은 Network:

```
ARP

↓

목적지 MAC 확인

↓

직접 전달
```


다른 Network:

```
Gateway MAC 확인

↓

Gateway 전달

↓

Routing
```

---

# 📌 정리

✔ IP = Network ID + Host ID  
✔ Subnet Mask는 두 영역을 구분한다  
✔ Prefix는 Network bit 개수이다  
✔ Host 개수 = 2^Host bit -2  
✔ Network / Broadcast 주소는 사용 불가  
✔ Subnetting은 IP 낭비 방지를 위한 네트워크 분할 기술이다  
✔ Gateway는 다른 Network 이동 시 사용된다