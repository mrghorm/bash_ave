#!/bin/sh

SUBJECT="Bash_AVE Not Active"
CONTENTS="Cron found that bash_ave.sh was not active.  Restarting..."


# If an instance of bash_ave is running
if ps -ef | grep -v grep | grep bash_ave.sh ; then
#	/usr/sbin/ssmtp -t << EOF
#To: mrghorm@gmail.com
#From: mrghorm@gmail.com
#Subject: TEST

#TEST CAUZE CRONTAB RAN AND temp_sense.py IS ALREADY RUNNING

#EOF

	exit 0

# If an instance of HandBrake is running
elif ps -ef | grep -v grep | grep HandBrakeCLI ; then


	exit 0

# If there are no files in the RAW_FOOTAGE/ directory

else

	if [ "$(ls -A /home/mrghorm/bash_ave/RAW_FOOTAGE)" ]; then
			/usr/sbin/ssmtp -t << EOF
To: mrghorm@gmail.com
From: mrghorm@gmail.com
Subject: $SUBJECT
	
$CONTENTS

EOF

	else
		echo "No more files to encode"
		exit 0

	fi


	cd /home/mrghorm/bash_ave/
	./bash_ave.sh
	exit 0

fi
