#!/bin/bash

# Update packages and install required software
yum update -y
yum install -y java-21-amazon-corretto wget git unzip awscli

# Define Maven version and download details
MAVEN_VERSION=3.9.10
MAVEN_DIR=apache-maven-$MAVEN_VERSION
ZIP_FILE=$MAVEN_DIR-bin.zip
DOWNLOAD_URL=https://dlcdn.apache.org/maven/maven-3/$MAVEN_VERSION/binaries/$ZIP_FILE

# Download and install Maven
wget $DOWNLOAD_URL -P /tmp
unzip /tmp/$ZIP_FILE -d /opt/

# Set Maven environment variables system-wide
cat <<EOF > /etc/profile.d/maven.sh
export M2_HOME=/opt/$MAVEN_DIR
export PATH=\$PATH:\$M2_HOME/bin
EOF

chmod +x /etc/profile.d/maven.sh
source /etc/profile.d/maven.sh

# Clone the GitHub repo into /opt/mycode
git clone https://github.com/techeazy-consulting/techeazy-devops.git /opt/mycode

# Build the application using Maven
cd /opt/mycode
mvn clean install

# Create application log file
touch /opt/app.log

# Create automate.sh to run the app in background
cat <<'EOT' > /opt/automate.sh
#!/bin/bash
nohup java -jar /opt/mycode/target/techeazy-devops-0.0.1-SNAPSHOT.jar > /opt/app.log 2>&1 &
echo "App manually started at $(date)" >> /opt/app.log
EOT

chmod +x /opt/automate.sh

# Run the automate.sh script to start the app
bash /opt/automate.sh


# --- App Setup ---



# --- Shutdown script ---
cat <<EOL > /opt/shutdown.sh
#!/bin/bash
aws s3 cp /var/log/cloud-init.log s3://${BUCKET_NAME}/ec2-logs/cloud-init.log
aws s3 cp /opt/app.log s3://${BUCKET_NAME}/app/logs/app.log
EOL

chmod +x /opt/shutdown.sh

# --- systemd service ---
cat <<EOL > /etc/systemd/system/upload-logs.service
[Unit]
Description=Upload logs to S3 on shutdown
DefaultDependencies=no
Before=shutdown.target

[Service]
Type=oneshot
ExecStart=/opt/shutdown.sh
RemainAfterExit=true

[Install]
WantedBy=shutdown.target
EOL

systemctl daemon-reexec
systemctl enable upload-logs.service

