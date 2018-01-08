## Quick Start

1. Create a github repo named `edgerouter` and create a dummmy/blank file called `config.boot.erxsfp`.
2. Create an auth token with `public_repo` permissions.
3. SSH into your edgerouter -- `ssh username@192.168.1.1` or whatever your username and IP address are.
4. Create a file named `github-backup.sh` in your home directory with the following contents:

```bash
hash='"'`curl  https://api.github.com/repos/pconwell/edgerouter/contents/config.boot.erxsfp | grep sha | cut -d '"' -f4`'"'
temp64='"'`/bin/cli-shell-api showCfg --show-hide-secrets | base64 | tr -d '\n'`'"'
curl --request PUT --user "pconwell:TOKEN" --data '{"message": "automated backup", "content": '"$temp64"', "sha": '"$hash"'}' https://api.github.com/repos/pconwell/edgerouter/contents/config.boot.erxsfp
```

> Make sure to replace TOKEN with your github auth token

5. Make the script executable with `chmod +x github-backup.sh`
6. edit the bash completion script to automatically upload your config when you `save` -- `sudo vi /etc/bash_completion.d/vyatta-cfg`. Add `/home/username/github-backup.sh` under `save()`.

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
hash='"'`curl  https://api.github.com/repos/pconwell/edgerouter/contents/config.boot.erxsfp | grep sha | cut -d '"' -f4`'"'
temp64='"'`/bin/cli-shell-api showCfg --show-hide-secrets | base64 | tr -d '\n'`'"'
curl --request PUT --user "pconwell:TOKEN" --data '{"message": "automated backup", "content": '"$temp64"', "sha": '"$hash"'}' https://api.github.com/repos/pconwell/edgerouter/contents/config.boot.erxsfp
```


#### Find Github API Hash

First, we need to find the current sha hash of your current config file. This tells github what file we want to update. The github API for getting a file's information is `curl https://api.github.com/repos/user/repo/contents/file`. In my example, this would return something like: 

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

#### Upload config to github

Now we are ready to upload our file to github. We will be using curl, which is basically a way to talk to websites through the CLI. There are a few different ways to use curl, but for our purposes we are concerned with the following:

* `--request PUT` tells curl we are sending information (as opposed to recieving information)
* `--user "name:token"` is our github username and the auth token we generated above
* `--data ...` is the config file we are sending to github.

We end up with a command that looks like this:

      curl --request PUT --user "pconwell:TOKEN" --data '{"message": "automated backup", "content": '"$temp64"', "sha": '"$hash"'}' https://api.github.com/repos/pconwell/edgerouter/contents/config.boot.erxsfp

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

My preference is to run the script when I commit a change in the CLI. If you never use the CLI, a cronjob to run the script every 24 hours (or whatever you want) may be better because if you make a change in the GUI it does not trigger an upload to github. There is no harm in uploading the same config file -- github will ignore the upload if there are no changes to save. I'll show examples for running the backup script both as a cronjob and after committing changes in the CLI.

I will warn you, you probably don't want to use both. For some reason that I don't understand, if you run the script as a cronjob, it inserts an extra blank line at the begining of each line. If you run the script as part of a commit workflow, it does *not* insert the blank space. While this don't really matter, it makes it hard to compare file version on github because it thinks EVERY line is different. If we only use one or the other, we can use github's cool comparison feature to easy see what changed between versions.

### Crontab





That's all that's needed to back your config up to github. From here you have a few options, but the most automated way is to run the script each time you save a configuration using the CLI (not sure how/if this would work through the GUI).

You just need to edit `/etc/bash_completion.d/vyatta-cfg` using sudo. About 20% down the file you will see `save ()` and something like

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
       /home/pconwell/github-backup.sh
      }

You just need to edit yours to add the last line `/home/pconwell/github-backup.sh` (assuming you saved your script from above at that location with that name -- which you probably didn't, so you will want to change your location and file name). Also, don't forget to make your script executable with `chmod +x github-backup.sh`.

That's it. Now every time you configure then commit; save; exit; you will automatically back up your config file to github. Specifically, this happens during the `save` step. 

I'm not really sure how changes are commited and saved in the gui, so this script may or may not work for changes made in the gui.

****

You can also use the `dnsmasq.adlist.conf` file to create a DNS level ad blocker, but you are probably better off installing pihole to a VM or docker or a raspberry pi.

If you do want to use `dnsmasq.adlist.conf`, you just need to place that file on your edgerouter and then set up a cron job to run at whatever interval you wish. I'd suggest running the script either once a day or once a week.
