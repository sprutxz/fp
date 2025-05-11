#!/bin/bash

# Build and deploy script for Tomcat

# Build the WAR file first
./build.sh

# Deploy to Tomcat
echo "Deploying to Tomcat..."

# Remove old deployment
sudo rm -rf /opt/tomcat/webapps/fp*
echo "Current webapps directory contents:"
ls -la /opt/tomcat/webapps/

# Copy new WAR file
sudo cp /home/sprutz/dev/fp/fp.war /opt/tomcat/webapps/

# Restart Tomcat
echo "Restarting Tomcat..."
sudo /opt/tomcat/bin/shutdown.sh
sudo /opt/tomcat/bin/startup.sh

echo "Deployment complete!"
echo "Application will be available at: http://localhost:8080/fp"