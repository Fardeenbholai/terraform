#!/bin/bash
# Install Apache Web Server and PHP
sudo yum install -y httpd mysql php
# Download Lab files
sudo wget https://aws-tc-largeobjects.s3.amazonaws.com/AWS-TC-AcademyACF/acf-lab3-vpc/lab-app.zip
sudo unzip lab-app.zip -d /var/www/html/
# Turn on web server
sudo systemctl start httpd
sudo systemctl enable httpd