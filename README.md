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
ZEPPELIN_REV="v0.9.0-preview2"
SPARK_VERSION="3.0.1"
SCALA_VERSION="2.12"
HADOOP_VERSION="3.2.0"

docker build . -t zeppelin \
    --build-arg ZEPPELIN_REV="${ZEPPELIN_REV}" \
    --build-arg SPARK_VERSION="${SPARK_VERSION}" \
    --build-arg SCALA_VERSION="${SCALA_VERSION}" \
    --build-arg HADOOP_VERSION="${HADOOP_VERSION}"

docker run --rm -it --name zeppelin -p 8080:8080 zeppelin
```

Wait a while and then access <http://localhost:8080/> in your web browser.

The default username is `user1`, and password is `password2`.

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
