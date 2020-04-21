# Zeppelin

[![CI Status](https://img.shields.io/github/workflow/status/dsaidgovsg/zeppelin/ci/master?label=ci&logo=github&style=for-the-badge)](https://github.com/dsaidgovsg/zeppelin/actions)

Zeppelin Dockerfile set-up with the following enhancements:

- Dynamic GitHub releases JAR loader. See
  [here](#how-to-use-the-dynamic-JAR-loader) for how to use. Original repo is in
  [here](https://github.com/dsaidgovsg/zeppelin-jar-loader).
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
SPARK_VERSION="2.4.4"
SCALA_VERSION="2.12"
HADOOP_VERSION="3.1.0"

docker build . -t zeppelin \
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

## How to use the dynamic JAR loader (only for v0.8.1 and below)

By default, Zeppelin supports dynamic JAR loading, but only through Maven
repository or local filesystem. See
[this](https://zeppelin.apache.org/docs/latest/interpreter/spark.html#3-dynamic-dependency-loading-via-sparkdep-interpreter)
for more details.

This set-up enhances this capability by installing a special JAR to do loading
from GitHub release JAR assets.

### Example

```scala
%spark.dep
z.reset() /* z is an implicit value of type org.apache.zeppelin.spark.dep.SparkDependencyContext */

// Saves JAR asset from GitHub release into local filesystem and loads JAR
zepjarloader.github.Loader.loadJar(
    z,
    "checkstyle/checkstyle",    /* github_owner/repo_name */
    "checkstyle-8.21",          /* tag_name */
    "checkstyle-8.21-all.jar",  /* asset_name */
    None,                       /* Some(sys.env.get("GITHUB_API_TOKEN").get) if private repo, None if no token needed */
    "/tmp/",                    /* local_file_dir_or_path to save into */
    true)                       /* Optional param (true), true to read from local_file_path first (cache), false to always fetch from scratch */
```

```scala
import com.puppycrawl.tools.checkstyle._
```

### Caveat

This only applies to Zeppelin version 0.8.1 and below, since 0.8.2 and 0.9.z
drops support for it.

One mitigation for this is to use a GitHub release asset as filesystem mount, as
such: <https://github.com/guangie88/ghafs>. This should also work for 0.8.z. The
way to use that is to add a first cell in notebook containing this:

```jupyter
%spark.conf
spark.jars /path/to/your/mounted/release/asset.jar
```
