# Zeppelin

Zeppelin Dockerfile set-up with a wrapping dynamic GitHub releases JAR loader.

## How to use the dynamic JAR loader

### Example

Para #1

```scala
%spark.dep
z.reset() /* z is an implicit value of type org.apache.zeppelin.spark.dep.SparkDependencyContext */

// Saves JAR asset from GitHub release into local filesystem and loads JAR
zepjarloader.github.Loader.loadJar(
    z,
    "checkstyle/checkstyle",         /* github_owner/repo_name */
    "checkstyle-8.21",               /* tag_name */
    Some("checkstyle-8.21-all.jar"), /* Some(asset_name) / None if there's only one asset */
    None,                            /* Some(private_api_token) / None if no token needed */
    "/tmp/checkstyle-8.21-all.jar")  /* local_file_path to save into */
```

Para #2

```scala
import com.puppycrawl.tools.checkstyle._
```
