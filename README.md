## Quick Start

1. Create a github repo named `edgerouter` and create a dummmy/blank file called `config.boot.erxsfp`.
2. Create an auth token with `public_repo` permissions.
3. SSH into your edgerouter -- `ssh username@192.168.1.1` or whatever your username and IP address are.
4. Create a file named `github-backup.sh` in your home directory with the following contents:

```bash
#!/bin/bash

## Set your github username and token
user=<github user name>
token=<github Personal Access Token>

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
```

> Make sure to replace USER:TOKEN with your github username and auth token

5. Make the script executable with `chmod +x github-backup.sh`
6. edit the bash completion script to automatically upload your config when you `save` -- `sudo vi /etc/bash_completion.d/vyatta-cfg`. Add `/home/user/github-backup.sh` under `save()`.

OR

6. create a crontab to run `home/user/github-backup.sh`.

## Introduction

This script automatically creates a backup of the ERX config file to this repository. The script itself is pretty simple, but it was a pain in the ass trying to decipher github's API which most of the documentation goes over my head.

There are probably better ways to do this, but this is what I came up with.

As far as I know this should work on any edgerouter system, but I have only confirmed that this works on the ERX SFP.

## Detailed Instructions

### Set up Github Repository

First, if you haven't alraedy, create a github account.

Once you have created your account, you will need to [create a new repository](https://github.com/new). You may be able to just fork this repository, but I'm not 100% sure if it will work -- I haven't tried it.

You don't need to do anything special at this point, but make sure the repository is named `edgerouter`. Unless you have a paid account, you will HAVE to leave your repo public, which should be fine as this script does not save any passwords or other sensitive information to the repo.

You do not HAVE to initialize with a readme, but it will be easier if you do. (Otherwise github will make you jump through some hoops to import code -- which we don't want to do. If you initialize with a readme, it allows us to 'cheat' a little and skip some steps).

Once you have created the repo, you should see a green button that says `Clone or Download` on the right side of the page. Just to the left of that button you should see a button that says 'Create a new file'. Click `Create a new file` then enter `config.boot.erxsfp` as the file name, scroll to the bottom and click `Commit new file`.

You should now see `README.md` and `config.boot.erxsfp`.

Next you, will need to [generate a Personal Access Token](https://github.com/settings/tokens). The only permission you need is `public_repo`, you can leave everything else unchecked. Once you generate your key, DO NOT close the window because you cannot see the key again. If you accidentally close the window before copy/pasting the key, just delete the key and generate a new one.

### Create a bash script

This is the meat-and-potatoes of this whole project. Basically, this script is what uploads the config file to github. The script is pretty basic, to be honest, but there are some technical steps we have to go through to get the data formatted correctly for github.

I'll go through the bash script line-by-line, but when we are done it should looking something like this (with your username, token and repo url in place of mine):

```bash
temp1='"'`curl --request GET --user "USER:TOKEN" https://api.github.com/repos/pconwell/edgerouter/contents/config.boot.erxsfp | jq -r '.content' | tr -d '\n'`'"'

hash='"'`curl  https://api.github.com/repos/pconwell/edgerouter/contents/config.boot.erxsfp | grep sha | cut -d '"' -f4`'"'
temp64='"'`/bin/cli-shell-api showCfg --show-hide-secrets | base64 | tr -d '\n'`'"'

if [ "$temp1" == "$temp64" ];

then

	echo true;
	
else

curl --request PUT --user "USER:TOKEN" --data '{"message": "automated backup", "content": '"$temp64"', "sha": '"$hash"'}' https://api.github.com/repos/user/edgerouter/contents/config.boot.erxsfp


fi
```
####
First, we want to get the current config file that exists on github. This way we can check if the config file has changed.

```bash
curl --request GET --user "USER:TOKEN" https://api.github.com/repos/pconwell/edgerouter/contents/config.boot.erxsfp
```

This returns a json format with some newline endings that will will want to remove, so we can use `jq -r '.content'` and `tr -d '\n'` to get the format we will need later on. For now, all we are doing is getting the current config, cleaning up the format a tiny bit and storing it. Nothing else happens during this step.


#### Find Github API Hash

Next, we need to find the current sha hash of your current config file. This tells github what file we want to update (assuming that it has changed). The github API for getting a file's information is `curl https://api.github.com/repos/user/repo/contents/file`. In my example, this would return something like: 

```bash
$ curl  https://api.github.com/repos/pconwell/edgerouter/contents/config.boot.erxsfp

{
  "name": "config.boot.erxsfp",
  "path": "config.boot.erxsfp",
  "sha": "3a69f76c8d11f5102ec748ba3205e49a73db2d7e",
  "size": 8267,
  "url": "https://api.github.com/repos/pconwell/edgerouter/contents/config.boot.erxsfp?ref=master",
  "html_url": "https://github.com/pconwell/edgerouter/blob/master/config.boot.erxsfp",
  "git_url": "https://api.github.com/repos/pconwell/edgerouter/git/blobs/3a69f76c8d11f5102ec748ba3205e49a73db2d7e",
  "download_url": "https://raw.githubusercontent.com/pconwell/edgerouter/master/config.boot.erxsfp",
  "type": "file",
  "content": "a bunch of stuff here",
  "encoding": "base64",
  "_links": {
    "self": "https://api.github.com/repos/pconwell/edgerouter/contents/config.boot.erxsfp?ref=master",
    "git": "https://api.github.com/repos/pconwell/edgerouter/git/blobs/3a69f76c8d11f5102ec748ba3205e49a73db2d7e",
    "html": "https://github.com/pconwell/edgerouter/blob/master/config.boot.erxsfp"
  }
}
```
All we need is the `3a69f76c8d11f5102ec748ba3205e49a73db2d7e`, part so we will slice that part out using grep: ` | grep sha | cut -d '"' -f4`

Now we want to save that as a variable because we will be using that sha hash in a minute. So we will call it `hash` for now. Putting it all together, we get:

    hash='"'`curl  https://api.github.com/repos/pconwell/edgerouter/contents/config.boot.erxsfp | grep sha | cut -d '"' -f4`'"'

#### Get current config from router

This part is easy. The only catch is github wants data uploaded as base64, so we will convert the config file to base64 and save the config file to a variable named `temp64`.

The command that actually shows the config file is `/bin/cli-shell-api showCfg --show-hide-secrets`. Make sure you don't forget the `--show-hide-secrets` part or you will upload your passowrds to github for anyone to see.

We also want to strip out newline charaters or we will have issues when we convert the config file to base64, which is the `tr -d '\n'` part of the command.

     temp64='"'`/bin/cli-shell-api showCfg --show-hide-secrets | base64 | tr -d '\n'`'"'

Other than that, nothing special happends during this step.

#### Check if remote config file (on github) matches our local config file

We want to check if the existing config file on github is different than what we currently have locally. If they are the same, there is nothing else to do and we will just exit. I currently have it output the text 'true' for good measure and debugging - but that's really up to you if you want to do something else.

If it's false (i.e. the remote file and the local file are different), it will go to the next step (the `else` portion).

```bash
if [ "$temp1" == "$temp64" ];

then

	echo true;
	
else
  ...
  
```

#### Upload config to github

Assuing changes exist, we are now ready to upload our file to github. We will be using curl, which is basically a way to talk to websites through the CLI. There are a few different ways to use curl, but for our purposes we are concerned with the following:

* `--request PUT` tells curl we are sending information (as opposed to recieving information)
* `--user "name:token"` is our github username and the auth token we generated above
* `--data ...` is the config file we are sending to github.

We end up with a command that looks like this:

      curl --request PUT --user "USER:TOKEN" --data '{"message": "automated backup", "content": '"$temp64"', "sha": '"$hash"'}' https://api.github.com/repos/user/edgerouter/contents/config.boot.erxsfp

You can see that the content of the API call is your config file sha hash. Make sure you are replacing your username, token and repo url as appropriate.

### Save Script

Now that we know what needs to go in the script, we will save it all to a file. We will be using `vi`, which can be very confusing if you've never used it before. I'll do my best to explain it step-by-step, but you may have to google information on vi.

1. SSH into your router -- `ssh username@192.168.1.1`. Obviously, use your username and IP address.
2. The command prompt should look like `username@ubnt:~$`. The `~` means we are in our home directory, which is where we want to be.
3. Create the script file by typing `vi github-backup.sh` and pressing enter. You will be in the vi editor now.
4. Press `i` in enter insert mode. Copy and paste each line from above into the script on it's own line.
5. Press `esc` to enter command mode. Type `:wq` to write (save) the file and quit.
6. Back at the command prompt, type `chmod +x github-backup.sh` to make the script executable.

### Automatically run the backup script

At this point, you have several different options. You can manually run the script file by typing `./github-backup.sh` at the command prompt, you can set up a cronjob, or you *could* even just manually type out or copy/paste the commands line-by-line into the command prompt (which would defeat the whole purpose of automating this).

If you never use the CLI, a cronjob to run the script every 24 hours (or whatever you want) may be better because if you make a change in the GUI it does not trigger an upload to github. There is no harm in uploading the same config file -- github will ignore the upload if there are no changes to save -- so don't worry too much about running a cronjob if you haven't made any changes. I'll show examples for running the backup script both as a cronjob and after committing changes in the CLI.

I will warn you, you probably don't want to use both. For some reason that I don't understand, if you run the script as a cronjob, it inserts an extra blank line at the begining of each line. If you run the script as part of a commit workflow, it does *not* insert the blank space. While this don't really matter, it makes it hard to compare file version on github because it thinks EVERY line is different. If we only use one or the other, we can use github's cool comparison feature to easy see what changed between versions.

#### Crontab

This will automatically run the backup script at a set interval regardless if changes have been made or not. The script will check if changes exist, so there (hopefully) won't be duplicate commits on github. In my example, I run the script once an hour, every hour, every day. 

>pros: better captures changes made in GUI
>cons: only catches changes as frequent as cronjob is run

I currently use a cronjob with this script and run it every hour. All you need to do is add the script to your crontab. At the command prompt:

1. type `contab -e`
2. Press `i` to enter insert mode
3. arrow down to the end of the file, under the line that says "# m h  dom mon dow   command"
4. create a new line and paste `0 * * * * /home/username/github-backup.sh >/dev/null 2>&1`
5. press `esc` to enter command mode, then type `:wq` to (w)rite the file and (q)uit.

If you want to run the job more or less frequently, google crontab.


#### Commit--Save Workflow

This works pretty well EXCEPT that it does not get triggered by changes in the GUI. It will upload changes that occur in the GUI, but only after you go into the CLI and commit--save any changes.

pros: captures changes instantly upon commit--save in CLI
cons: does not automatically capture changes in GUI (you must commit and save in the CLI)

This is pretty simple, but easy to mess up. I won't give step-by-step directions here because it involves messing with some system files that could break your router. I'm going to assume if you know how to edit these files, you probably know what you are doing, so I'm only going to show an overview here.

You need to edit `/etc/bash_completion.d/vyatta-cfg` using sudo. About 20% down the file you will see `save ()` and change it to something like:

     save ()
     {
       if vyatta_cli_shell_api sessionChanged; then
         echo -e "Warning: you have uncommitted changes that will not be saved.\n"
       fi
       # return to top level.
       reset_edit_level
       # transform individual args into quoted strings
       local arg=''
       local save_cmd="${vyatta_sbindir}/vyatta-save-config.pl"
       for arg in "$@"; do
         save_cmd+=" '$arg'"
       done
       eval "sudo sg vyattacfg \"umask 0002 ; $save_cmd\""
       sync ; sync
       vyatta_cli_shell_api unmarkSessionUnsaved
       /home/username/github-backup.sh
      }

****

You can also use the `dnsmasq.adlist.conf` file to create a DNS level ad blocker, but you are probably better off installing pihole to a VM or docker or a raspberry pi or something - but using a DNS ad blocker within the ERX works pretty well.

If you do want to use `dnsmasq.adlist.conf`, you just need to place that file on your edgerouter and then set up a cron job to run at whatever interval you wish. I'd suggest running the script either once a day or so.
