# Github role

The Github role is to get the latest version of release published by a given owner/repository on github using github api.

## main.yml

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


## latest.yml

Get the link to download the latest release by a given owner/repository.
The link will be stored in the variable `browser_download_url`.

| parameters | description |
| - | - |
| organization | Organization or user name. |
| repository | Repository name. |
| query_string | Words to get the string containing the version from the download link in release page. |


Example
```yml
# Inputs
ansible.builtin.import_role:
  name: github
  tasks_from: latest.yml
vars:
  organization: test
  repository: test
  query_string: "linux_amd64"

# The result
browser_download_url: "https://github.com/test/test/releases/download/v0.1.1/packagename_linux_amd64.tar.gz"
```
