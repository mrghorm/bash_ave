import smtplib, ssl

#port = 465 #For SSL
port = 587
password = 'qyedcgjnfuaewcpj'

context = ssl.create_default_context()

sender_email = "mrghorm@gmail.com"
receiver_email = "mrghorm@gmail.com"
message = """ 
Subject: TEST

This is another test email sent from Python
"""

try:
	server = smtplib.SMTP("smtp.gmail.com",port)
	server.starttls(context=context)
	server.login(sender_email, password)

	server.sendmail(sender_email,receiver_email,message)

except Exception as e:
	print(e)
finally:
	server.quit()


#with smtplib.SMTP_SSL("smtp.gmail.com", port, context=context) as server:
#	server.login("mrghorm@gmail.com", password)
#	message = """\
#Subject: TESTING
#
#This message was sent by Python SMTP.
#"""	
#	server.sendmail(sender_email, receiver_email, message)
	
