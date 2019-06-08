#!/usr/bin/env sh
set -euo pipefail

# Permit notebook directory to be written to
chown -R zeppelin ${ZEPPELIN_NOTEBOOK}

exec gosu zeppelin sh -c "
# Find all .jar files and comma delimit into a string
export SPARK_JARS=$(find "${SPARK_HOME}/jars/" -type f -name '*.jar' | paste -sd,)

# Create interpreter.json
tera -f ./conf/interpreter.json.template --env > ./conf/interpreter.json

# Create zeppelin-site.xml
tera -f ./conf/zeppelin-site.xml.template --env > ./conf/zeppelin-site.xml

# Create shiro.ini if desired
tera -f ./conf/shiro.ini.template --env > ./conf/shiro.ini

# Protect potential secrets in shiro.ini
chmod 400 ./conf/shiro.ini

# Start zeppelin
./bin/zeppelin.sh
"
