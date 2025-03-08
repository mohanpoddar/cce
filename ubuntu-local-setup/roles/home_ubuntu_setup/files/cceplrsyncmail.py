#!/usr/bin/python3
import os
import smtplib
import subprocess
from datetime import datetime
from email.message import EmailMessage
from datetime import datetime

HOSTNAME = subprocess.run("hostname", shell=True, capture_output=True, text=True).stdout.strip()
print("HOSTNAME:", HOSTNAME)

if HOSTNAME == "av-pc":
    datacenter = "Greater Noida"
elif HOSTNAME == "503S":
    datacenter = "Vasundhara"
elif HOSTNAME == "mylearnersepoint":    
    datacenter = "Ccepladmin Testing Server"
    
# Fetch latest log
def get_latest_rsync_log():
    # Execute the command and capture the output
    result = subprocess.run("ls -ltrh /home/cce/logs/rsync/rsync_cron_* | awk '{print $NF}' | tail -n 1", shell=True, capture_output=True, text=True)
    
    # Check if the command was successful
    if result.returncode == 0:
        # Return the output, stripping any trailing newline characters
        return result.stdout.strip()
    else:
        # Handle the error
        print("Error executing command:", result.stderr)
        return None

def get_latest_rsync_actual_command_log():
    # Execute the command and capture the output
    result = subprocess.run("ls -ltrh /home/cce/logs/rsync/rsync_in_backup_location_latest_* | awk '{print $NF}' | tail -n 1", shell=True, capture_output=True, text=True)
    
    # Check if the command was successful
    if result.returncode == 0:
        # Return the output, stripping any trailing newline characters
        return result.stdout.strip()
    else:
        # Handle the error
        print("Error executing command:", result.stderr)
        return None

# Usage example
latest_log_cron_path = get_latest_rsync_log()
latest_rsync_actual_log_path = get_latest_rsync_actual_command_log()
if latest_log_cron_path:
    print("Latest rsync log file:", latest_log_cron_path)

if latest_rsync_actual_log_path:
    print("Latest rsync actual log file:", latest_rsync_actual_log_path)

error = False
print (error)
if latest_log_cron_path.split('_')[-1] != latest_rsync_actual_log_path.split('_')[-1]:
    error = True
    print (error)

#def send_email_with_attachment(subject, body, to, attachment_path):
def send_email(subject, to, cc=None):
    # Email configuration
    email_user = 'learnersepoint@gmail.com'
    email_password = 'xgao djru pwpb uhxz'  # Use an App Password for better security
    email_server = 'smtp.gmail.com'
    email_port = 587

    # Read the content of the file to include in the email body
    with open(latest_log_cron_path, 'r') as latest_log_cron_path_file:
        latest_log_cron = latest_log_cron_path_file.read()
    
    with open(latest_rsync_actual_log_path, 'r') as latest_rsync_actual_log_path_file:
        latest_rsync_actual_log = latest_rsync_actual_log_path_file.readlines()

    # Append the file content to the email body
    if len(latest_rsync_actual_log) > 15: 
        body = f"""
        <html>
        <head>
            <style>
                body {{
                    font-family: Arial, sans-serif;
                    background-color: #f4f4f9;
                    color: #333;
                    margin: 0;
                    padding: 0;
                    font-size: 16px;
                }}
                .container {{
                    width: 80%;
                    margin: 0 auto;
                    background-color: #fff;
                    padding: 20px;
                    box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
                    border-radius: 8px;
                }}
                .header {{
                    background-color: #4CAF50;
                    color: white;
                    padding: 10px 0;
                    text-align: center;
                    border-radius: 8px 8px 0 0;
                }}
                .content {{
                    padding: 20px;
                    font-size: 16px;
                }}
                .footer {{
                    text-align: center;
                    padding: 10px 0;
                    color: #777;
                    font-size: 12px;
                }}
                pre {{
                    background-color: #f4f4f9;
                    padding: 10px;
                    border-radius: 4px;
                    overflow-x: auto;
                    font-size: 14px;
                }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>CCEPL RSYNC ALERT<br>{datacenter}</h1>
                </div>
                <div class="content">
                    <p>Hi1,</p>
                    <p>Please find below the Rsync backup details for {datacenter}:</p>
                    <h2>Latest Rsync Cron Job Report:</h2>
                    <p>Latest cron log path: {latest_log_cron_path}</p>
                    <pre>{latest_log_cron}</pre>
                    <h2>Latest Rsync Backup Report:</h2>
                    <p>Latest rsync actual log path: {latest_rsync_actual_log_path}</p> 
                    <pre>{"".join(latest_rsync_actual_log[:5])}\n...\n--snip--\n...\n\n{"".join(latest_rsync_actual_log[-5:])}</pre>
                    <br>
                    Regards, <br>
                    CCEPL IT Team
                </div>
                <div class="footer">
                    <p>&copy; {datetime.now().year} CCEPL IT Team. All rights reserved.</p>
                </div>
            </div>
        </body>
        </html>    
        """
    else:
        body = f"""
        <html>
        <head>
            <style>
                body {{
                    font-family: Arial, sans-serif;
                    background-color: #f4f4f9;
                    color: #333;
                    margin: 0;
                    padding: 0;
                    font-size: 16px;
                }}
                .container {{
                    width: 80%;
                    margin: 0 auto;
                    background-color: #fff;
                    padding: 20px;
                    box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
                    border-radius: 8px;
                }}
                .header {{
                    background-color: #4CAF50;
                    color: white;
                    padding: 10px 0;
                    text-align: center;
                    border-radius: 8px 8px 0 0;
                }}
                .content {{
                    padding: 20px;
                    font-size: 16px;
                }}
                .footer {{
                    text-align: center;
                    padding: 10px 0;
                    color: #777;
                    font-size: 12px;
                }}
                pre {{
                    background-color: #f4f4f9;
                    padding: 10px;
                    border-radius: 4px;
                    overflow-x: auto;
                    font-size: 14px;
                }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>CCEPL RSYNC ALERT<br>{datacenter}</h1>
                </div>
                <div class="content">
                    <p>Hi,</p>
                    <p>Please find below the Rsync backup details for {datacenter}:</p>
                    <h2>Latest Rsync Cron Job Report:</h2>
                    <p>Latest cron log path: {latest_log_cron_path}</p>
                    <pre>{latest_log_cron}</pre>
                    <h2>Latest Rsync Backup Report:</h2>
                    <p>Latest rsync actual log path: {latest_rsync_actual_log_path}</p> 
                    <pre>{"".join(latest_rsync_actual_log)}</pre>
                    <br>
                    Regards, <br>
                    CCEPL IT Team
                </div>
                <div class="footer">
                    <p>&copy; {datetime.now().year} CCEPL IT Team. All rights reserved.</p>
                </div>
            </div>
        </body>
        </html>    
        """
    
    # Create the email message
    msg = EmailMessage()
    msg['Subject'] = subject
    msg['From'] = email_user
    msg['To'] = to
    if cc:
        msg['Cc'] = cc
    #msg.set_content(body)
    msg.set_content(body, subtype='html')

    ## Attach the file - Uncomment if you want to enable the attachement.
    #with open(attachment_path, 'rb') as f:
    #    file_data = f.read()
    #    file_name = os.path.basename(attachment_path)
    #    msg.add_attachment(file_data, maintype='application', subtype='octet-stream', filename=file_name)

    # Send the email
    with smtplib.SMTP(email_server, email_port) as server:
        server.starttls()
        server.login(email_user, email_password)
        server.send_message(msg)


def send_error_email(subject, to, cc=None):
    # Email configuration
    email_user = 'learnersepoint@gmail.com'
    email_password = 'xgao djru pwpb uhxz'  # Use an App Password for better security
    email_server = 'smtp.gmail.com'
    email_port = 587

    # Read the content of the file to include in the email body
    with open(latest_log_cron_path, 'r') as latest_log_cron_path_file:
        latest_log_cron = latest_log_cron_path_file.read()
    
    # with open(latest_rsync_actual_log_path, 'r') as latest_rsync_actual_log_path_file:
    #     latest_rsync_actual_log = latest_rsync_actual_log_path_file.readlines()

    # Append the file content to the email body
    body = f"""
        <html>
        <head>
            <style>
                body {{
                    font-family: Arial, sans-serif;
                    background-color: #f4f4f9;
                    color: #333;
                    margin: 0;
                    padding: 0;
                    font-size: 16px;
                }}
                .container {{
                    width: 80%;
                    margin: 0 auto;
                    background-color: #fff;
                    padding: 20px;
                    box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
                    border-radius: 8px;
                }}
                .header {{
                    background-color: #4CAF50;
                    color: white;
                    padding: 10px 0;
                    text-align: center;
                    border-radius: 8px 8px 0 0;
                }}
                .content {{
                    padding: 20px;
                    font-size: 16px;
                }}
                .footer {{
                    text-align: center;
                    padding: 10px 0;
                    color: #777;
                    font-size: 12px;
                }}
                pre {{
                    background-color: #f4f4f9;
                    padding: 10px;
                    border-radius: 4px;
                    overflow-x: auto;
                    font-size: 14px;
                }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>CCEPL RSYNC ALERT<br>{datacenter}</h1>
                </div>
                <div class="content">
                    <p>Hi,</p>
                    <p>Please find below the Rsync backup details for {datacenter}:</p>
                    <h2>Latest Rsync Cron Job Report:</h2>
                    <p>Latest cron log path: {latest_log_cron_path}</p>
                    <pre>{latest_log_cron}</pre>
                    <h2>Latest Rsync Backup Report:</h2>
                    <h3 style="color: red;">Rsync Backup Failed</h3>
                    <br>
                    Regards, <br>
                    CCEPL IT Team
                </div>
                <div class="footer">
                    <p>&copy; {datetime.now().year} CCEPL IT Team. All rights reserved.</p>
                </div>
            </div>
        </body>
        </html>    
        """
        
    # Create the email message
    msg = EmailMessage()
    msg['Subject'] = subject
    msg['From'] = email_user
    msg['To'] = to
    if cc:
        msg['Cc'] = cc
    #msg.set_content(body)
    msg.set_content(body, subtype='html')

    ## Attach the file - Uncomment if you want to enable the attachement.
    #with open(attachment_path, 'rb') as f:
    #    file_data = f.read()
    #    file_name = os.path.basename(attachment_path)
    #    msg.add_attachment(file_data, maintype='application', subtype='octet-stream', filename=file_name)

    # Send the email
    with smtplib.SMTP(email_server, email_port) as server:
        server.starttls()
        server.login(email_user, email_password)
        server.send_message(msg)

# Usage example
current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
# to = "learnersepoint@gmail.com"
to = "rayosystems@gmail.com"
cc = "learnersepoint@gmail.com"

if not error:
    subject = f"SUCCESS - CCEPL ALERT: Rsync in {datacenter} At - {current_time}"
    send_email(subject, to, cc)
else:
    subject = f"FAILED - CCEPL ALERT: Rsync in {datacenter} At - {current_time}"
    send_error_email(subject, to, cc)

# send_email_with_attachment("Test Email", "This is a test email", to, latest_log_cron_path)
# send_email("Test Email", to, cc)
# send_error_email("Test Email", to, cc)