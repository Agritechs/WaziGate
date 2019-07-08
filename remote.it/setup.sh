#!/bin/bash
# @author: Moji eskandari@fbk.eu Jul 05th 2019
#

# It is recommended to store the email and password in a file named "creds" next to this file with the same flowwing format
email="email@example.com"		# Remote.it email (Change it!)
password="Remote.itPassword"	# password (Change it!)

#---------------------------------------#

SCRIPT_PATH=$(dirname $(realpath $0))

#Using Rapi MAC address as device ID
MAC=$(cat /sys/class/net/eth0/address)
MAC=${MAC//:}
gwId="${MAC^^}"

#----------------------------------#

if [ ! -f /usr/bin/connectd_library ]; then
	echo "Error: [ connectd ] is not installed!"
	echo "Run: sudo apt-get update && sudo apt-get install connectd"
	exit 1
fi

#check if the server is accessible
acc=$(curl -Is https://remote.it | head -n 1 | awk '{print $2}')
if [ "$acc" != "200" ]; then
	echo "Remote.it is not accessible"
	exit 1
fi

if [ -f $SCRIPT_PATH/done.txt ]; then
	echo "Already registered."
	exit
fi

#----------------------------------#

echo "Remote.it Automatic registration started"

. $SCRIPT_PATH/creds

rtServices=$(sudo bash $SCRIPT_PATH/services.sh)

#echo "$rtServices"

#----------------------------------#

echo "Registring WAZIGATE_$gwId" > $SCRIPT_PATH/ongoing.txt

if [[ $rtServices == *"WAZIGATE_$gwId"* ]]; then

	echo "Already Registered under name [ WAZIGATE_$gwId ]" 
	echo "Already Registered under name [ WAZIGATE_$gwId ]" >> $SCRIPT_PATH/ongoing.txt

else

	sudo connectd_installer<<EOF
1
$email
$password
WAZIGATE_$gwId
5
y
EOF

	echo "Done" >> $SCRIPT_PATH/ongoing.txt

fi

#--------------------#

echo "Registring SSH..." >> $SCRIPT_PATH/ongoing.txt

if [[ $rtServices == *"SSH-WAZIGATE_$gwId"* ]]; then
	
	echo "SSH is already registered [ SSH-WAZIGATE_$gwId ]"
	echo "SSH already registered [ SSH-WAZIGATE_$gwId ]" >> $SCRIPT_PATH/ongoing.txt
	
else

	sudo connectd_installer<<EOF
1
$email
$password
1
1
y
SSH-WAZIGATE_$gwId
5
y
EOF

	echo "Done" >> $SCRIPT_PATH/ongoing.txt

fi

#--------------------#

echo "Registring HTTP..." >> $SCRIPT_PATH/ongoing.txt

if [[ $rtServices == *"HTTP-WAZIGATE_$gwId"* ]]; then
	
	echo "HTTP is already registered [ HTTP-WAZIGATE_$gwId ]"
	echo "HTTP already registered [ HTTP-WAZIGATE_$gwId ]" >> $SCRIPT_PATH/ongoing.txt
	
else

	sudo connectd_installer<<EOF
1
$email
$password
1
2
y
HTTP-WAZIGATE_$gwId
5
y
EOF

	echo "$error" >> $SCRIPT_PATH/ongoing.txt
	echo "Done" >> $SCRIPT_PATH/ongoing.txt

fi

#--------------------#

#Double check if everything is done correctly
rtServices=$(sudo bash $SCRIPT_PATH/services.sh)

if [[ $rtServices == *"WAZIGATE_$gwId"* ]] && [[ $rtServices == *"SSH-WAZIGATE_$gwId"* ]] && [[ $rtServices == *"HTTP-WAZIGATE_$gwId"* ]]; then

	rm -f $SCRIPT_PATH/ongoing.txt
	echo -e "WAZIGATE_$gwId\nSSH-WAZIGATE_$gwId\nHTTP-WAZIGATE_$gwId" > $SCRIPT_PATH/done.txt
	echo -e "\n\t\t* * * All done successfully :) * * *\n"
	exit 0
fi

echo "There are some erros! Check the logs please."
exit 1