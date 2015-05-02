#!/bin/bash

#без параметров скачиваем большой файл 
#с параметром пользуемся предыдущим 

#формат лога: имя OVPN файла; дата;время 
#
#
#

#base64
if [ ! -e base64 ]; then 
echo "...ERROR..."
echo "You need install base64 ..."
exit 1
fi

openvpn_path=/usr/sbin/openvpn
if [ ! -e $openvpn_path ]; then 
echo "...ERROR..."
echo "You need install openvpn or rename path..."
exit 1
fi

ovpn_config_dir=~/ovpn
if [ ! -d $ovpn_config_dir ]; then 
mkdir ~/ovpn
echo "Create dir "~/"ovpn"
fi

vpngate_files_dir=~/vpngate
if [ ! -d $vpngate_files_dir ]; then 
mkdir ~/ovpn
echo "Create dir "~/"vpngate"
fi

log_dir=~/logs
if [ ! -d $log_dir ]; then 
mkdir ~/logs
echo "Create dir "~/"logs"
fi

#фиксируем время
cur_today=`date +%F`
cur_time=`date +%H-%M-%S`
cur_dt=$cur_today.$cur_time

#лог файл
log_file=`tr / ' ' <<< $0| awk '{ print $2}'`.log
if [ ! -e $log_file ]; then 
#$1=""
echo "Log File not exist..."
fi

# 1	   2	3   4	  5	   6		7	     8		9	 10	     11
#HostName,IP,Score,Ping,Speed,CountryLong,CountryShort,NumVpnSessions,Uptime,TotalUsers,TotalTraffic,
#  12	   13	    14			15
#LogType,Operator,Message,OpenVPN_ConfigData_Base64


############################################### START SUBROUTINE ###############################################

#подпрограмма для вывода списков vpn
fChoiceVpnFromList()
{
# $1 = $vpngate_file
declare -a vpnhostname
declare -i num=0
declare -a vpnname

cat $1 | grep ^vpn |   awk -F, ' { printf "%4d %s %9d %-20s %-16s %7d \n", NR, $1, $5, $6, $2, $3 } '
for vpnhostname in `cat $1 | grep ^vpn |   awk -F, ' { print $1 } '`
do
	vpnname[$num]=$vpnhostname
	num=$num+1
done

echo "print number#"
read a
echo key=$a
host_name=`cat $1 | grep ${vpnname[$a-1]} |   awk -F, '{print $1"_"$7"_"$2}'`
ovpn_name=$host_name.ovpn
cat $1 | grep ${vpnname[$a-1]} |   awk -F, ' {print $15} '| base64 -d | cat >$ovpn_config_dir/$ovpn_name
echo $1";"$ovpn_config_dir/$ovpn_name";"$cur_today";"$cur_time>$log_dir/$log_file
sudo $openvpn_path $ovpn_config_dir/$ovpn_name
}

###############################################  STOP SUBROUTINE ###############################################

#опции

case $1 in 

#скачиваем новый файл
"")
vpngate_file=$vpngate_files_dir/cvslistvpngate.$cur_dt.txt
wget -O $vpngate_file http://www.vpngate.net/api/iphone/
if  [ $? -ne 0 ]; then 
echo "...ERROR..."
echo "Downloads from vpngate.net not success..."
echo "Uses old file"
vpngate_file=`ls -t $vpngate_files_dir/cvslistvpngate.$cur_today.*.txt |head -n1`
if [ ! -e $vpngate_file ]; then 
echo "Old File "$vpngate_file" Not Exist... Sorry..."
exit 1
fi
fi

fChoiceVpnFromList $vpngate_file 
exit 0
;;

#HELP
--help|-h|h) 
echo "Usade: $0 [option]"
echo "       $0 --help|-h           ... for this help"
echo "       $0                     ... for downloads new list from vpngate.com and use it"
echo "       $0 --ovpn|-ovpn|-o|-O  ... for use exist .ovpn files"
echo "       $0 --last|-last|-l     ... for use one last time .ovpn file"
echo "       $0 any_other_symbol(s) ... for use OLD downloads file from log"
exit 1
;;

--helpru|-ru|-hru)
echo "Usade: $0 [option]"
echo "       $0 --help|-h       ... for this help"
echo "       $0                     ... for downloads new list from vpngate.com and uses it"
echo "       $0 --ovpn|-ovpn|-o|-O  ... for use exist .ovpn file(s) help"
echo "       $0 --last|-last|-l     ... for use exist .ovpn file(s) help"
echo "       $0 any_other_symbol(s) ... for use OLD downloads file from log"
exit 1
;;


#читаем лог и используем уже готовый предыдущий ovpn файл
-l|-last|--last)
sudo $openvpn_path `cat $log_dir/$log_file | awk -F";" '{print $2}'`

;;
--ovpn|-o|-O|0|-0)
ls -1 $ovpn_config_dir

exit 0
;;

#берём данные для листинга с уже скачанного и записанного в логе файла
*)
vpngate_file=`cat $log_dir/$log_file | awk -F";" '{print $1}'`
fChoiceVpnFromList $vpngate_file 

;;
esac
