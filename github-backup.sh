#!/bin/bash

## Set your github username and token
user=<your github user name>
token=<your github Personal Access Token>

## Get the current file from github so we can check for changes
github_config='"'`curl --silent --no-buffer --request GET --user "$user:$token" https://api.github.com/repos/$user/edgerouter/contents/config.boot.erxsfp | jq -r '.content' | tr -d '\n'`'"'

## Get the current file's ssh hash from github so we know which file needs to be updated (if changes exist)
github_hash='"'`curl  https://api.github.com/repos/$user/edgerouter/contents/config.boot.erxsfp | grep sha | cut -d '"' -f4`'"'

## Create a base64 version of the current config file (to check against $github_file and also upload if there are changes)
local_config='"'`/bin/cli-shell-api showCfg --show-hide-secrets | base64 | tr -d '\n'`'"'

## Check if local version is same as github version
if [ "$github_config" == "$local_config" ];

## If the versions are the same, print "true" (this isn't necessarily important, but can be output to a log, for example)
then

	echo true;
	
## If the versions are different, upload the new version to github
else

	curl --request PUT --user "$user:$token" --data '{"message": "automated backup", "content": '"$local_config"', "sha": '"$github_hash"'}' https://api.github.com/repos/$user/edgerouter/contents/config.boot.erxsfp

fi
