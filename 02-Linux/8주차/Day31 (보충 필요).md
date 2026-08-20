일요일
tar -g /backup/backup.list -cf /backup/file0.tar *

월요일
touch A
tar -g /backup/backup.list -cf /backup/file1.tar *

화요일
touch B
tar -g /backup/backup.list -cf /backup/file2.tar *

# For details see man 4 crontabs

# Example of job definition:
# .---------------- minute (0 - 59)
# |  .------------- hour (0 - 23)
# |  |  .---------- day of month (1 - 31)
# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
# |  |  |  |  |
# *  *  *  *  * user-name  command to be executed

오후 3시				0 15 * * *
오전 3시 오후 3시			0 3,15 * * *
일요일 오후 3시			0 15 * * 0
일요일 오후 3시와 목요일 오후 3시		0 15 * * 0,4
매월 1일 오후 3시			0 15 1 * *
매월 1일 오전 3시와 오후 3시		0 3,15 1 * *
분기날(1월, 4월, 7월, 10월) 1일 오전 3시	0 3 1 1,4,7,10 *
1분마다				* * * * *

-----------------------------------------------------------------------------------

[일] vi /root/bin/backup0.sh
#!/bin/bash
rm -rf /backup/*.list
touch /root/test/file_`date +%m%d_%H%M%S`
tar -g /backup/backup1.list -cvzf /backup/bakfile_`date +%m%d_%H%M%S`.tar.gz -C /root/test/ . >> /backup/backup.log 2>&1
cp /backup/backup1.list /backup/backup2.list
echo "### 일요일 백업이 완료됐습니다. ###" > /backup/bakmsg.txt
cat /backup/bakmsg.txt /backup/backup.log > /dev/pts/0

[월] vi /root/bin/backup1.sh
#!/bin/bash
touch /root/test/file_`date +%m%d_%H%M%S`
tar -g /backup/backup1.list -cvzf /backup/bakfile_`date +%m%d_%H%M%S`.tar.gz -C /root/test/ . >> /backup/backup.log 2>&1
echo "### 월요일 백업이 완료됐습니다. ###" > /backup/bakmsg.txt
cat /backup/bakmsg.txt /backup/backup.log > /dev/pts/0

[화] vi /root/bin/backup2.sh
#!/bin/bash
touch /root/test/file_`date +%m%d_%H%M%S`
tar -g /backup/backup1.list -cvzf /backup/bakfile_`date +%m%d_%H%M%S`.tar.gz -C /root/test/ . >> /backup/backup.log 2>&1
echo "### 화요일 백업이 완료됐습니다. ###" > /backup/bakmsg.txt
cat /backup/bakmsg.txt /backup/backup.log > /dev/pts/0

[수] vi /root/bin/backup3.sh
#!/bin/bash
touch /root/test/file_`date +%m%d_%H%M%S`
tar -g /backup/backup1.list -cvzf /backup/bakfile_`date +%m%d_%H%M%S`.tar.gz -C /root/test/ . >> /backup/backup.log 2>&1
echo "### 수요일 백업이 완료됐습니다. ###" > /backup/bakmsg.txt
cat /backup/bakmsg.txt /backup/backup.log > /dev/pts/0

[목] vi /root/bin/backup4.sh
#!/bin/bash
touch /root/test/file_`date +%m%d_%H%M%S`
tar -g /backup/backup2.list -cvzf /backup/bakfile_`date +%m%d_%H%M%S`.tar.gz -C /root/test/ . >> /backup/backup.log 2>&1
echo "### 목요일 백업이 완료됐습니다. ###" > /backup/bakmsg.txt
cat /backup/bakmsg.txt /backup/backup.log > /dev/pts/0

[금] vi /root/bin/backup5.sh
#!/bin/bash
touch /root/test/file_`date +%m%d_%H%M%S`
tar -g /backup/backup2.list -cvzf /backup/bakfile_`date +%m%d_%H%M%S`.tar.gz -C /root/test/ . >> /backup/backup.log 2>&1
echo "### 금요일 백업이 완료됐습니다. ###" > /backup/bakmsg.txt
cat /backup/bakmsg.txt /backup/backup.log > /dev/pts/0

[토] vi /root/bin/backup6.sh
#!/bin/bash
touch /root/test/file_`date +%m%d_%H%M%S`
tar -g /backup/backup2.list -cvzf /backup/bakfile_`date +%m%d_%H%M%S`.tar.gz -C /root/test/ . >> /backup/backup.log 2>&1
echo "### 토요일 백업이 완료됐습니다. ###" > /backup/bakmsg.txt
cat /backup/bakmsg.txt /backup/backup.log > /dev/pts/0

rm -rf /backup
mkdir -p /backup

chmod 700 /root/bin/backup*
ls -l /root/bin/

crontab -e
31 14 * * * /root/bin/backup0.sh
32 14 * * * /root/bin/backup1.sh
33 14 * * * /root/bin/backup2.sh
34 14 * * * /root/bin/backup3.sh
35 14 * * * /root/bin/backup4.sh
36 14 * * * /root/bin/backup5.sh
37 14 * * * /root/bin/backup6.sh
38 14 * * * /root/bin/backup0.sh

crontab -r
crontab -l
rm -rf /root/bin/*
rm -rf /root/test/*
rm -rf /backup

------------------------------------------------------
nmcli connection modify ens33 ipv4.addresses 192.168.2.100/24
nmcli connection modify ens33 ipv4.gateway 192.168.2.253
nmcli connection modify ens33 ipv4.dns 8.8.8.8
nmcli connection modify ens33 ipv4.dns-search example777.com

------------------------------------------------------
nmcli connection modify ens33 ipv4.addresses 192.168.2.203/24 \
ipv4.gateway 192.168.2.254 \
ipv4.dns 168.126.63.1 \
ipv4.dns-search example.com

------------------------------------------------------
192.168.2.203	server1.example7777.com	server1
192.168.2.204	server2.example7777.com	server2
192.168.2.201	client1.example7777.com	client1
192.168.2.202	client2.example7777.com	client2
142.251.153.119	google


///////////////////////////

nmcli connection modify ens33 ipv4.addresses 10.1.1.1/24 \
ipv4.gateway 10.1.1.254 \
ipv4.dns 10.1.1.254 \
ipv4.dns-search example2.com


//////////////////////////////

yum -y install telnet-server tenlet