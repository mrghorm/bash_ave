#!/bin/sh

SUBJECT="Temp Sense Not Active"
CONTENTS="Cron found that temp_sense.py was not active.  Restarting..."


if ps -ef | grep -v grep | grep temp_sense.py ; then
#	/usr/sbin/ssmtp -t << EOF
#To: mrghorm@gmail.com
#From: mrghorm@gmail.com
#Subject: TEST
#
#TEST CAUZE CRONTAB RAN AND temp_sense.py IS ALREADY RUNNING
#
#EOF

	exit 0
else

	/usr/sbin/ssmtp -t << EOF
To: mrghorm@gmail.com
From: mrghorm@gmail.com
Subject: $SUBJECT
	
$CONTENTS

EOF
	cd /media/mrghorm/VideoFiles/share/bash_ave/
	python3 /media/mrghorm/VideoFiles/share/bash_ave/temp_sense.py
	exit 0

fi
