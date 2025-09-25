#!/bin/bash

# Exit the script if an error occurs
set -e

# Function to display messages
function print_message() {
    echo -e "\n====================="
    echo "$1"
    echo -e "=====================\n"
}

# Start script execution
print_message "Updating package list and installing Docker & Docker Compose"
apt update
apt install -y docker.io docker-compose

print_message "Setting up the Ubuntu Firewall"
ufw enable
ufw allow ssh
ufw allow 80
ufw allow 3000
ufw allow 443/tcp
ufw reload

# Request IP address input
read -p "Enter your VM IP address: " ip_vm_address

# Request username and directory variables
read -p "Enter path for deployment (e.g., /home/azureuser or /root): " deploymentPath

# Check if deploymentPath exists, create it if it doesn't
echo "Directory $deploymentPath does not exist. Creating it now..."
mkdir -p "$deploymentPath"

# Move all files and folders except the script itself to deploymentPath
echo "Moving all files and folders to $deploymentPath..."
for item in *; do
    # Exclude the .sh script
    if [[ "$item" != "${0##*/}" ]]; then
        mv "$item" "$deploymentPath/"
    fi
done

print_message "Updating docker-compose.yml with the provided IP address"
sed -i "s/<IP_Address>/$ip_vm_address/g" $deploymentPath/docker-compose.yml

print_message "Generating self-signed SSL certificates"
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout $deploymentPath/nginx/certs/self-signed.key \
  -out $deploymentPath/nginx/certs/self-signed.crt \
  -subj "/CN=$ip_vm_address"

print_message "Starting Docker Compose services"
docker-compose up -d

print_message "Verifying running containers"
docker ps

print_message "Installing OpenJDK for JMeter"
sudo apt install openjdk-17-jdk -y

print_message "Verifying Java installation"
java -version

print_message "Downloading JMeter"
wget https://downloads.apache.org/jmeter/binaries/apache-jmeter-5.6.3.tgz

print_message "Extracting JMeter files"
tar -xvzf apache-jmeter-5.6.3.tgz

print_message "Move JMeter to /opt directory for system-wide access:"
mv apache-jmeter-5.5 /opt/apache-jmeter

print_message "Add JMeter to your PATH for easier access:"
echo 'export PATH=$PATH:/opt/apache-jmeter/bin' >> ~/.bashrc
source ~/.bashrc

print_message "verify that JMeter is installed"
jmeter --version

print_message "Download Backend Listener Plugin"
wget https://jmeter-plugins.s3.amazonaws.com/plugins/jmeter.backendlistener.mysql/backendlistener-jmeter.mysql-1.0.jar

print_message "Place Backend Listener Plugin in JMeter's lib/ext directory"
mv backendlistener-jmeter.mysql-1.0.jar /opt/apache-jmeter/lib/ext/

print_message "Delete JMeter and Backend Listener Plugin Archives"
rm apache-jmeter-5.6.3.tgz
rm backendlistener-jmeter.mysql-1.0.jar

print_message "Setup complete! Use JMeter and monitor your Docker Compose services."