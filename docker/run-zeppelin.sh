#!/usr/bin/env sh
set -euo pipefail

# Find all .jar files and comma delimit into a string
SPARK_JARS=$(find "${SPARK_JARS}" -name '*.jar' | paste -sd,)

# Create interpreter.json
tera -f /zeppelin/conf/interpreter.json.template --env > /zeppelin/conf/interpreter.json

# Create zeppelin-site.xml
tera -f /zeppelin/conf/zeppelin-site.xml.template --env > /zeppelin/conf/zeppelin-site.xml

# Create shiro.ini if desired
tera -f /zeppelin/conf/shiro.ini.template --env > /zeppelin/conf/shiro.ini

# Protect potential secrets in shiro.ini
chmod 600 /zeppelin/conf/shiro.ini

# Permit notebook directory to be written to
chown -R zeppelin /zeppelin/notebook

# Start zeppelin
exec ./bin/zeppelin.sh
