#!/usr/bin/env bash
set -euo pipefail

# Find all .jar files and comma delimit into a string
SPARK_JARS="$(find "${SPARK_HOME}/jars/" -type f -name '*.jar' | paste -sd,)"
export SPARK_JARS

# Create interpreter.json
if [[ "${ZEPPELIN_APPLY_INTERPRETER_JSON}" == "true" ]]; then
    tera -f ./conf/interpreter.json.template --env > ./conf/interpreter.json
fi

# Create zeppelin-site.xml
if [[ "${ZEPPELIN_APPLY_ZEPPELIN_SITE}" == "true" ]]; then
    tera -f ./conf/zeppelin-site.xml.template --env > ./conf/zeppelin-site.xml
fi

if [[ "${ZEPPELIN_APPLY_SHIRO}" == "true" ]]; then
    # Create shiro.ini if desired
    tera -f ./conf/shiro.ini.template --env > ./conf/shiro.ini

    # Protect potential secrets in shiro.ini
    chmod 600 ./conf/shiro.ini
fi

# Permit notebook directory to be written to
chown -R zeppelin "${ZEPPELIN_NOTEBOOK}"

# Start zeppelin
exec ./bin/zeppelin.sh
