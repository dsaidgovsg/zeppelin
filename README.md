# Zeppelin

[![Codefresh build status]( https://g.codefresh.io/api/badges/pipeline/dsaid/datagovsg%2Fzeppelin%2Fzeppelin?branch=master&key=eyJhbGciOiJIUzI1NiJ9.NWNhNDBjNDA1MTMxODZjZjdhMTUyYjQx.uEnKk6__Qzfhrurzdo57Oly3AhBgrjFWZZrovG-m-8E&type=cf-1)]( https://g.codefresh.io/pipelines/zeppelin/builds?repoOwner=datagovsg&repoName=zeppelin&serviceName=datagovsg%2Fzeppelin&filter=trigger:build~Build;branch:master;pipeline:5cf86ebd38d1cd3c3a44c178~zeppelin)

Zeppelin Dockerfile set-up with the following enhancements:

- Dynamic GitHub releases JAR loader. See
  [here](how-to-use-the-dynamic-JAR-loader) for how to use.
- `pac4j` additional environment variable based email domain authorization.
  See [here](https://github.com/datagovsg/pac4j-authorizer) for more details.

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

## How to have a quick local deployment demo

```bash
docker build . -t zeppelin
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

## How to use the dynamic JAR loader

By default, Zeppelin supports dynamic JAR loading, but only through Maven
repository or local filesystem. See
[this](https://zeppelin.apache.org/docs/latest/interpreter/spark.html#3-dynamic-dependency-loading-via-sparkdep-interpreter)
for more details.

This set-up enhances this capability by
installing a special JAR to do loading from GitHub release JAR assets.

### Example

Para #1

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

Para #2

```scala
import com.puppycrawl.tools.checkstyle._
```
