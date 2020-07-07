import psutil
import time
import subprocess
import warnings
import sqlite3
import statistics

####Email Commands####
import smtplib
import ssl

####Email Settings####
port = 587 #For starttls
sender_email = "mrghorm@gmail.com"
receiver_email = "mrghorm@gmail.com"
password = "qyedcgjnfuaewcpj"
message = """ """
context = ssl.create_default_context()
smtp_server = "smtp.gmail.com"

#FILTER WARNINGS: NOT RECOMMENDED
#	Used to suppress psutil warnings for BASH use
warnings.filterwarnings("ignore")

sensorlist = ["TN0D", "TN0H"]

sqlconn = sqlite3.connect('/home/mrghorm/bash_ave_r710/bash_ave_r710.db', timeout=10)

tempthreshold_time = 0
threshold_temp = 9000

try:

	#initialize variables (sometimes psutil will miss a value)
	cpu_0_0 = 0
	cpu_0_1 = 0
	cpu_0_2 = 0
	cpu_0_3 = 0
	cpu_0_4 = 0
	cpu_0_5 = 0
	cpu_1_0 = 0
	cpu_1_1 = 0
	cpu_1_2 = 0
	cpu_1_3 = 0
	cpu_1_4 = 0
	cpu_1_5 = 0
	#nb_d = 0
	#nb_h = 0
	cpu_usage_total = 0
	cpu_0_0_usage = 0
	cpu_0_1_usage = 0
	cpu_0_2_usage = 0
	cpu_0_3_usage = 0
	cpu_0_4_usage = 0
	cpu_0_5_usage = 0
	cpu_1_0_usage = 0
	cpu_1_1_usage = 0
	cpu_1_2_usage = 0
	cpu_1_3_usage = 0
	cpu_1_4_usage = 0
	cpu_1_5_usage = 0




	while True:
		try:
			#NO NEED FOR SLEEP FUNCTION -- psutil.cpu_percent sleeps for <interval> seconds
			#time.sleep(1)
			print("---------------")

			sensordict = {}

			sensors_all = {}

			try:
				sensors_all = psutil.sensors_temperatures()

				#DOUBLES AS SLEEP FUNCTION -- interval=1 gathers cpu usage for 1 second
				usage_all = psutil.cpu_percent(interval=1,percpu=True)

			except KeyboardInterrupt:
				print("KeyboardInterrupt")
				exit(0)
			except Error:
				#print("pass")
				pass


			cpu_0_0_temp = int(sensors_all["coretemp"][0][1] * 100)
			cpu_0_1_temp = int(sensors_all["coretemp"][1][1] * 100)
			cpu_0_2_temp = int(sensors_all["coretemp"][2][1] * 100)
			cpu_0_3_temp = int(sensors_all["coretemp"][3][1] * 100)
			cpu_0_4_temp = int(sensors_all["coretemp"][4][1] * 100)
			cpu_0_5_temp = int(sensors_all["coretemp"][5][1] * 100)

			cpu_1_0_temp = int(sensors_all["coretemp"][6][1] * 100)
			cpu_1_1_temp = int(sensors_all["coretemp"][7][1] * 100)
			cpu_1_2_temp = int(sensors_all["coretemp"][8][1] * 100)
			cpu_1_3_temp = int(sensors_all["coretemp"][9][1] * 100)
			cpu_1_4_temp = int(sensors_all["coretemp"][10][1] * 100)
			cpu_1_5_temp = int(sensors_all["coretemp"][11][1] * 100)




#			for i in range(0,80) :
#				sensor_code = ""
#				sensor_val = 0
#
#				try:
#					sensor_code = sensors_all["applesmc"][i][0]
#					sensor_val = sensors_all["applesmc"][i][1]
#
#				except IndexError:
#					#print("pass index")
#					pass
#
#
#				sensordict[sensor_code] = sensor_val
#

			nb_d = 0 #int(sensordict[sensorlist[0]] * 100)
			nb_h = 0 #int(sensordict[sensorlist[1]] * 100)

			#psutil.cpu_percent() reports logical cores.  The lines below average (mean) the logical cores to produce average physical core usage
			#The mean is then multiplied by 10 for greater precision, then turned into an integer to report to the sqlite database

			cpu_0_0_usage = int(statistics.mean([usage_all[0], usage_all[1]]) * 10)
			cpu_0_1_usage = int(statistics.mean([usage_all[2], usage_all[3]]) * 10)
			cpu_0_2_usage = int(statistics.mean([usage_all[4], usage_all[5]]) * 10)
			cpu_0_3_usage = int(statistics.mean([usage_all[6], usage_all[7]]) * 10)
			cpu_0_3_usage = int(statistics.mean([usage_all[8], usage_all[9]]) * 10)
			cpu_0_3_usage = int(statistics.mean([usage_all[10], usage_all[11]]) * 10)

			cpu_1_0_usage = int(statistics.mean([usage_all[12], usage_all[13]]) * 10)
			cpu_1_1_usage = int(statistics.mean([usage_all[14], usage_all[15]]) * 10)
			cpu_1_2_usage = int(statistics.mean([usage_all[16], usage_all[17]]) * 10)
			cpu_1_3_usage = int(statistics.mean([usage_all[18], usage_all[19]]) * 10)
			cpu_1_3_usage = int(statistics.mean([usage_all[20], usage_all[21]]) * 10)
			cpu_1_3_usage = int(statistics.mean([usage_all[22], usage_all[23]]) * 10)

			c = sqlconn.cursor()

			c.execute("INSERT INTO AVE_Temps (Time, Core0_0_Temp, Core0_1_Temp, Core0_2_Temp, Core0_3_Temp, Core0_4_Temp, Core0_5_Temp, Core1_0_Temp, Core1_1_Temp, Core1_2_Temp, Core1_3_Temp, Core1_4_Temp, Core1_5_Temp, Core0_0_Usage, Core0_1_Usage, Core0_2_Usage, Core0_3_Usage, Core0_4_Usage, Core0_5_Usage, Core1_0_Usage, Core1_1_Usage, Core1_2_Usage, Core1_3_Usage, Core1_4_Usage, Core1_5_Usage) VALUES ({}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {})".format(int(time.time()), cpu_0_0_temp, cpu_0_1_temp, cpu_0_2_temp, cpu_0_3_temp, cpu_0_4_temp, cpu_0_5_temp, cpu_1_0_temp, cpu_1_1_temp, cpu_1_2_temp, cpu_1_3_temp, cpu_1_4_temp, cpu_1_5_temp, cpu_0_0_usage, cpu_0_1_usage, cpu_0_2_usage, cpu_0_3_usage, cpu_0_4_usage, cpu_0_5_usage, cpu_1_0_usage, cpu_1_1_usage, cpu_1_2_usage, cpu_1_3_usage, cpu_1_4_usage, cpu_1_5_usage))


			sensors_temps = [cpu_0_0_temp, cpu_0_1_temp, cpu_0_2_temp, cpu_0_3_temp, cpu_0_4_temp, cpu_0_5_temp, cpu_1_0_temp, cpu_1_1_temp, cpu_1_2_temp, cpu_1_3_temp, cpu_1_4_temp, cpu_1_5_temp]
			print("{}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}".format(cpu_0_0_temp, cpu_0_1_temp, cpu_0_2_temp, cpu_0_3_temp, cpu_0_4_temp, cpu_0_5_temp, cpu_1_0_temp, cpu_1_1_temp, cpu_1_2_temp, cpu_1_3_temp, cpu_1_4_temp, cpu_1_5_temp))

			sqlconn.commit()


			corecount = 0
			for temp in sensors_temps:
				if temp >= threshold_temp:
					corecount += 1


			if corecount > 0:
				tempthreshold_time += 1
			elif corecount == 0 and tempthreshold_time > 0:
				tempthreshold_time -= 1

			print(tempthreshold_time)

			if tempthreshold_time > 10:
				#print("GOT HERE 1")
				#bashCommand = (r'ssmtp -v -au mrghorm@gmail.com mrghorm@gmail.com < messages/temp_shutdown.txt')
				#print(bashCommand)
				#process = subprocess.Popen(bashCommand.split(), stdout=subprocess.PIPE)
				#print("GOT HERE 2")
				#output, error = process.communicate()
				#print("SIMULATING SHUTDOWN")

				try:
					server = smtplib.SMTP(smtp_server,port)
					#server.ehlo()
					server.starttls(context=context)
					#server.ehlo()
					server.login(sender_email,password)
					subject = "WARNING Threshold Temp Surpassed on MacPro"					


					message = 'Subject: {}\n\nThe maximum temperature has surpassed {} for the threshold time.  Server automatically shutting down.'.format(subject,threshold_temp)

					server.sendmail(sender_email,receiver_email,message)
					server.quit()
				except Exception as e:
					print("Failed to send email!  Commencing shutdown anyways...")
					print(e)
				#finally:
				#	server.quit


				#print("SIMULATING SHUTDOWN")
				#quit()

				####REQUIRES USING visudo TO ALLOW ALL USERS TO POWEROFF WITHOUT PASSWORD####
				####Running sudo for shutdown doesn't require sudo password in this instance####
				bashCommand = "sudo shutdown -h now"
				process = subprocess.Popen(bashCommand.split(), stdout=subprocess.PIPE)
				output, error = process.communicate()


		except KeyboardInterrupt:
			print("KeyboardInterrupt")
			sqlconn.close()
			exit(0)

		except Exception as e:
			print("An error has occured")
			print(e)



except KeyboardInterrupt:
	print("KeyboardInterrupt")
	sqlconn.close()

except:
	sqlconn.close()
	raise
