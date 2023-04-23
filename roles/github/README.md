# Github role

The Github role is to get the latest version of release published by a given owner/repository on github using github api.

The following parameters are required as variables (vars or extra_vars):

| parameters | description |
| - | - |
| organization | Organization or user name. |
| repository | Repository name. |
| query_string | Words to get the string containing the version from the download link in release page. |
| version_regex | Regex expression to get the string to match the version from the string. This is set to Semantic version (`x.y.z`) by default. |


The obtained version information is set to `release_latest_version` in facts scope.

```
"release_latest_version": "1.2.0"
```