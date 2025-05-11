#!/bin/bash

# Create build directories
mkdir -p build/WEB-INF/classes
mkdir -p build/WEB-INF/lib

# Copy web.xml
cp src/main/webapp/WEB-INF/web.xml build/WEB-INF/

# Copy JSP files
cp src/main/webapp/*.jsp build/

# Copy libraries
cp -r src/main/webapp/WEB-INF/lib/* build/WEB-INF/lib/

# Compile Java files
javac -cp "src/main/webapp/WEB-INF/lib/*" -d build/WEB-INF/classes src/main/java/com/auth/*.java

# Create WAR file
cd build
jar -cvf ../fp.war .

echo "WAR file created as fp.war"