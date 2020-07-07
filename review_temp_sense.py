import time
import sqlite3
#import

###Email commands###
import smtplib
import ssl

###Email Settings###
port = 587
sender_email = "mrghorm@gmail.com"
receiver_email = "mrghorm@gmail.com"
password = "qyedcgjnfuaewcpj"
message = """ """
context = ssl.create_default_context()
smtp_server = "smtp.gmail.com"

###SQLite3###
sqlconn = sqlite3.connect('bash_ave_mp.db', timeout=10)
c = sqlconn.cursor()

sqlconn2 = sqlite3.connect('bash_ave.db')
c2 = sqlconn2.cursor()


###PROGRAM SETTINGS###

#How far back to pull values (in minutes)
fetchtime = 0
deltatime = 60
deltatime_s = deltatime * 60


###Get Time###
sqlprogram = """
SELECT
	MAX(Time)
FROM AVE_Temps
"""

fetchtime = c.execute(sqlprogram).fetchall()[0][0]

time = fetchtime - deltatime_s
print(time)

temp_dict_max = {}
temp_dict_avg = {}

for a in range(0,2):
	for b in range(0,4):
		temp_dict_max["{}{}".format(a,b)] = int(c.execute("SELECT MAX(Core{}_{}_Temp) FROM AVE_Temps WHERE Time > {}".format(a,b,time)).fetchall()[0][0])
		#print("Adding data for {}{}".format(a,b))

for a in range(0,2):
	for b in range(0,4):
		temp_dict_avg["{}{}".format(a,b)] = int(c.execute("SELECT AVG(Core{}_{}_Temp) FROM AVE_Temps WHERE Time > {}".format(a,b,time)).fetchall()[0][0])



#print(temp_dict)

messages_coretemps_max = "--00----01----02----03----10----11----12----13--\n {}  {}  {}  {}  {}  {}  {}  {}  ".format(temp_dict_max["00"],temp_dict_max["01"],temp_dict_max["02"],temp_dict_max["03"],temp_dict_max["10"],temp_dict_max["11"],temp_dict_max["12"],temp_dict_max["13"])


messages_coretemps_avg = "--00----01----02----03----10----11----12----13--\n {}  {}  {}  {}  {}  {}  {}  {}  ".format(temp_dict_avg["00"],temp_dict_avg["01"],temp_dict_avg["02"],temp_dict_avg["03"],temp_dict_avg["10"],temp_dict_avg["11"],temp_dict_avg["12"],temp_dict_avg["13"])

print(messages_coretemps_max)
print(messages_coretemps_avg)

for i in temp_dict_max.values():
	print(i)

for i in temp_dict_avg.values():
	print(i)


numfilesencoded = c.execute("SELECT COUNT(StartTime) FROM AVE_Log1 WHERE EndTime > {}".format(time)).fetchall()[0][0]
totaldataraw = c.execute("SELECT SUM(StartSize) FROM AVE_Log1 WHERE EndTime > {}".format(time)).fetchall()[0][0]
totaldataencoded = c.execute("SELECT SUM(EndSize) FROM AVE_Log1 WHERE EndTime > {}".format(time)).fetchall()[0][0]

messages_encodes = ""

if numfilesencoded > 0:
	print(numfilesencoded)	
	try:
		print((totaldataraw / 1000000000))
		print((totaldataencoded / 1000000000))

		messages_encodes = "Number of files encoded: {}\nStarting Encode Size: {} GB\nEnding Encode Size: {} GB".format(numfilesencoded, (totaldataraw / 1000000000), (totaldataencoded / 1000000000))

	except Exception as e:
		print("Error fetching data from database")
		messages_encodes = "No files encoded"

else:
	print("No files encoded in the last {} minutes".format(deltatime))
	messages_encodes = "No files encoded"

message_subject = "Bash Auto Video Encoder Review"

message_body ="""Review of the Bash AVE for the last {} minutes

Temperatures:

MAX
{}

AVG
{}

Encoding:

{}

""".format(deltatime, messages_coretemps_max, messages_coretemps_avg, messages_encodes)

message = 'Subject: {}\n\n{}'.format(message_subject,message_body)

try:
	server = smtplib.SMTP(smtp_server,port)
	server.starttls(context=context)
	server.login(sender_email,password)
	
	server.sendmail(sender_email,receiver_email,message)
	server.quit()
except Exception as e:
	print("Failed to send email!")
	print(e)


