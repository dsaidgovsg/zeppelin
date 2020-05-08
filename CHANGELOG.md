# Version changes

The changes here are cumulative from oldest to latest version.

In principle, new features can be added to an existing version, but the change
should not be breaking to existing default `docker run` with default env vars
set-up.

## v1

This assumes that the default command is used. The default port that Zeppelin
uses is `8080`. To change it, override the env var `ZEPPELIN_PORT` to any other
port value.

- Env vars
  - General
    - `ZEPPELIN_HOME="/zeppelin"`
    - `ZEPPELIN_NOTEBOOK="/zeppelin/notebook"`
    - `ZEPPELIN_IMPERSONATE_USER="zeppelin"`
    - `ZEPPELIN_IMPERSONATE_CMD="gosu zeppelin bash -c "`
    - `ZEPPELIN_IMPERSONATE_SPARK_PROXY_USER="false"`
  - `interpreter.json.template`
    Too many to list, all Spark interpreter related options do have
    corresponding env vars to control the value. E.g.:
    - `SPARK_MASTER`
    - `SPARK_JARS`
    - `ZEPPELIN_SPARK_ENABLESUPPORTEDVERSIONCHECK`, etc.
  - `zeppelin-site.xml.template
    - `SERVER_ADDR="0.0.0.0"`
    - `ZEPPELIN_PORT="8080"`
    - `ZEPPELIN_SSL_PORT="8080"`
    - `ZEPPELIN_NOTEBOOK` notebook dir location as stated in `General`

- Others
  - `zeppelin-jar-loader v0.2.1"` (only for Zeppelin `0.8.1` and below) and
    `pac4j-authorizer v0.1.1` JARs are present for use as described in
    [`README.md`](README.md).
  - `ghafs v0.1.2` executable is present in `PATH`, check
    <https://github.com/guangie88/ghafs> for more details.
