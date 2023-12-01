# Zeppelin

[![CI Status](https://img.shields.io/github/workflow/status/dsaidgovsg/zeppelin/ci/master?label=ci&logo=github&style=for-the-badge)](https://github.com/dsaidgovsg/zeppelin/actions)

Zeppelin Dockerfile set-up with the following enhancement(s):

- `pac4j` additional environment variable based email domain authorization.
  See original repo [here](https://github.com/dsaidgovsg/pac4j-authorizer) for
  more details.

This set-up is opinionated towards Spark, as such, many of the Spark
configuration values are set as values that can be interpolated by
[tera-cli](https://github.com/guangie88/tera-cli) via environment variables.

All the values have defaults, so this Docker image can still be easily tried out
without having to set any special environment variables.

Check:

- [`interpreter.json.template`](docker/conf/interpreter.json.template)
- [`zeppelin-site.xml.template`](docker/conf/zeppelin-site.xml.template)

to get a better feel for the above explanation. Search for `{{` to quickly get
all the values that can be interpolated by environment variables.

This repo tries its best to never change the environment variables once they are
part of the above template files, but note that this is a best effort attempt
and there is indeed a change of naming (or removal), this would not be reflected
in the Docker image tags.

## Version changelog

See [`CHANGELOG.md`](CHANGELOG.md) for details.

## How to have a quick local deployment demo

```bash
# Can use any of the tags in zeppelin repo that follows semver. E.g. v0.8.2
ZEPPELIN_VERSION="0.10.1"
SPARK_VERSION="3.4.1"
HADOOP_VERSION="3.3.4"
SCALA_VERSION="2.12"
JAVA_VERSION="8"

docker build . -t zeppelin \
    --build-arg ZEPPELIN_VERSION="${ZEPPELIN_VERSION}" \
    --build-arg SPARK_VERSION="${SPARK_VERSION}" \
    --build-arg HADOOP_VERSION="${HADOOP_VERSION}" \
    --build-arg SCALA_VERSION="${SCALA_VERSION}" \
    --build-arg JAVA_VERSION="${JAVA_VERSION}"

docker run -d --rm -it --name zeppelin -p 8080:8080 zeppelin
```

Wait a while and then access <http://localhost:8080/> in your web browser.

As Spark 3.4.1 is not officially supported by Zeppelin, there is a need to go to `Interpreter` and change `zeppelin.spark.enableSupportedVersionCheck` to false for Spark 3.4.1 to work with Zeppelin

To test that the Spark interpreter is working, simply create a quick notebook
with Spark as the interpreter.

Enter the following into the first paragraph:

```scala
sc.parallelize(0 to 10).sum
```

Press `[SHIFT+ENTER]` to run the paragraph. Wait for Spark to compute the above
and you should get the sum result after some time.

## GHAFS and dynamic JAR loading

[`ghafs`](https://github.com/guangie88/ghafs) is provided to allow JAR files in
GitHub releases to be directly accessible for dynamic JAR loading. Use the CLI
to mount any release that contains JAR file onto some path, then in any notebook
run the first cell like the following:

```jupyter
%spark.conf
spark.jars /path/to/your/mounted/release/asset.jar
```

## Running a quick docker-compose set-up with GitHub OAuth 2.0

Assuming you have a sufficiently modern `docker-compose` and `docker` CLI
set-up, you can go to [`examples/github`](examples/github).

You will need to go to any GitHub account that you can go into the following:

(Top-right) `Settings` > `Developer settings` > `OAuth Apps`, and click on `New
OAuth App`

You can add a new OAuth 2.0 application with a new client id and secret.

Copy the two values into [`shiro.ini`](examples/github/shiro.ini), under
`oauth2Config.key` and `oauth2Config.secret`.

Now run `docker-compose up --build`, and you should get a working Zeppelin
set-up at port 8080. Using your web browser to navigate to it, should redirect
you to login (and accept scopes) in GitHub, and then redirecting you back to the
localhost Zeppelin authenticated.

## Caveat

### Java 11

The build matrix does not build specifically for Java 11, because officially
Zeppelin is only tested and built with Java 8:
<https://zeppelin.apache.org/docs/latest/quickstart/install.html#requirements>

However it has been somewhat empirically tested that the set-up can run on Java
11, with some error logs during start-up that do not seem to cause any major
issues, related to `org.glassfish.jersey.message.internal.DataSourceProvider`.

```log
java.lang.NoClassDefFoundError: javax/activation/DataSource
```

### Scala 2.13

While the latest commit of Zeppelin has already started supporting Spark 2.13,
since
<https://github.com/apache/zeppelin/commit/c4c580a37fde649553d336984a94bcb1b2821201>
the build matrix also does not build specifically for Scala 2.13, since the
released version v0.10.1 does not Spark 2.13.

### Spark 3.3.0

While current the build matrix here builds for Spark 3.3.0, the current latest
released version v0.10.1 of Zeppelin still does not support it, even though
there is already a commit for it:
<https://github.com/apache/zeppelin/pull/4388>.

But since there is workaround for it, this build matrix supports it.

As such, if you are running the built image with Spark 3.3.0, you need to set
environment variable `ZEPPELIN_SPARK_ENABLESUPPORTEDVERSIONCHECK` to `false`, so
the the value `zeppelin.spark.enableSupportedVersionCheck` in `interpreter.json`
is set to `false` to prevent checking of unsupported Spark version.
