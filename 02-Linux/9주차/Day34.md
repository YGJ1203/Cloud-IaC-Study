http://192.168.2.203		/www/index.html		팬션 홈페이지
http://192.168.2.203/admin/		/www/admin/index.html	팬션 관리자 홈페이지

http://192.168.2.203/cgi-bin/test.sh	/www/cgi-bin/test.sh	bash 쉘 스크립트 페이지
http://192.168.2.203/perl/test.pl	/www/perl/test.pl		perl 쉘 스크립트 페이지

http://192.168.2.203/index.php	/www/index.php		phpinfo(); 페이지
192.168.2.203/test.php		/www/test.php		php와 DB 연동 테스트 페이지
192.168.2.203/cmd.php		/www/cmd.php		웹 쉘
/main.php				/www/main.php		PHP 회원 가입 페이지

---------------------------------------------------------------------------------------------------------
<VirtualHost *:80>
    DocumentRoot "/www1"
    ServerName www1.example7777.com
    <Directory "/www1">
        Require all granted
     </Directory>
</VirtualHost>

-------------------------------------------------------------------------------------------------------------
192.168.2.203	www1.example7777.com
192.168.2.203	www2.example7777.com
192.168.2.203	www3.example7777.com

--------------------------------------------------------------------------------------------------------------

nmcli connection modify ens33 \
+ipv4.address 192.168.2.210/24 \
+ipv4.address 192.168.2.220/24 \
+ipv4.address 192.168.2.230/24 \

////////////////

<VirtualHost 192.168.2.210:80>
  2     DocumentRoot "/www1"
  3     ServerName www1.example7777.com
  4     <Directory "/www1">
  5         Require all granted
  6      </Directory>
  7 </VirtualHost>
  8
  9 <VirtualHost 192.168.2.220:80>
 10     DocumentRoot "/www2"
 11     ServerName www2.example7777.com
 12     <Directory "/www2">
 13         Require all granted
 14      </Directory>
 15 </VirtualHost>
 16
 17 <VirtualHost 192.168.2.230:80>
 18     DocumentRoot "/www3"
 19     ServerName www3.example7777.com
 20     <Directory "/www3">
 21         Require all granted
 22      </Directory>
 23 </VirtualHost>

------------------------------------------------------------------
nmcli connection modify ens33 \
-ipv4.address 192.168.2.210/24 \
-ipv4.address 192.168.2.220/24 \
-ipv4.address 192.168.2.230/24 

----------------------------------------------------------------------
Listen 8081
Listen 8082
Listen 8083
<VirtualHost 192.168.2.203:8081>
    DocumentRoot "/www1"
    ServerName www.example7777.com
    <Directory "/www1">
        Require all granted
     </Directory>
</VirtualHost>

<VirtualHost 192.168.2.203:8082>
    DocumentRoot "/www2"
    ServerName www.example7777.com
    <Directory "/www2">
        Require all granted
     </Directory>
</VirtualHost>

<VirtualHost 192.168.2.203:8083>
    DocumentRoot "/www3"
    ServerName www.example7777.com
    <Directory "/www3">
        Require all granted
     </Directory>
</VirtualHost>

///////////////////////////////////////////////////

intitle:"index of" intext:DCIM



cd /usr/local
ls

wget https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.121/bin/apache-tomcat-9.0.121.tar.gz

---------------------------------------------------------------
create table linux (id int, login varchar(10), password varchar(10), username varchar(20), age int);
create table cisco (id int, login varchar(10), password varchar(10), username varchar(20), age int);
create table security (id int, login varchar(10), password varchar(10), username varchar(20), age int);
create table java (id int, login varchar(10), password varchar(10), username varchar(20), age int);

insert into cisco values (1, 'cisco1','cisco1111','jeong yun gu',23);
insert into cisco values (2, 'cisco2','cisco2222','jeong yun gu',26);
insert into cisco values (3, 'cisco3','cisco3333','jeong yun gu',29);

insert into linux values (1, 'linux1','linux1111','lee jung woo',33);
insert into linux values (2, 'linux2','linux2222','lee jung soo',36);
insert into linux values (3, 'linux3','linux3333','lee jung ah',39);

insert into security values (1, 'security1','security11','park jung woo',43);
insert into security values (2, 'security2','security22','park jung woo',43);
insert into security values (3, 'security3','security33','park jung woo',43);

update cisco set username='jeong yun gu' where login='cisco2';
delete from cisco where id='3';
alter table linux modify login varchar(20);
alter table linux add email varchar(40) first;
alter table linux modify email varchar(20) after username;

update linux set password=md5('linux1111') where login='linux1';
update linux set password=md5('linux2222') where login='linux2';
update linux set password=md5('linux3333') where login='linux3';

update security set password=sha('security11') where login='security1';
update security set password=sha('security22') where login='security2';
update security set password=sha('security33') where login='security3';

update security set password=sha2('security11',256) where login='security1';
update security set password=sha2('security22',256) where login='security2';
update security set password=sha2('security33',256) where login='security3';

update linux set password=hex(aes_encrypt('linux1111','xyz')) where login='linux1';
update linux set password=hex(aes_encrypt('linux2222','xyz')) where login='linux2';
update linux set password=hex(aes_encrypt('linux3333','xyz')) where login='linux3';

select aes_decrypt(unhex(password),'xyz') from linux;