This script automatically creates a backup of the ERX config file to this repository. The script itself is pretty simple, but it was a pain in the ass trying to decipher github's API which most of the documentation doesn't seem to quite be up-to-date or something.

There are probably better ways to do this, but this is what I came up with.

****

**ONE**. Create a github account and then create a repository called 'edgerouter'. Next generate a Personal Access Token. I'm not 100% sure what priliges are needed for the PAT, but I tried once without any extra privliges selected and it didn't work (kept returning a cryptic 404 not found error) and I generated a 2nd token with the majority of priviligies selected and it worked. I suspect you just need 'repo_hook' but again, I have not confirmed what exact privligies are needed for the PAT to work correctly with this script.

**TWO**. Then, you need to get the sha hash of your current backup file:

     hash='"'`curl  https://api.github.com/repos/pconwell/edgerouter/contents/config.boot.erxsfp | grep sha | cut -d '"' -f4`'"'

What this does is finds the hash for the 'current' version of your backup file on github (or if you are just starting out and your repo is empty - it does nothing). You have to have the current hash so you can tell github which file you are updating. Obviously you will want to replace this with your info (your username instead of 'pconwell' and if you give your repo a different name replace 'edgerouter' with whatever you call it).

**THREE**. Next, you need to get the newest config file from your router:

     temp64='"'`/bin/cli-shell-api showCfg --show-hide-secrets | base64 | tr -d '\n'`'"'

You want to be careful here because 'cli-shell-api showCfg' will show you your un-redacted configuration file. In other words, if you mess this part up you will post your passwords all over github. the '--show-hide-secrets' will redact your passwords. Github expects files to be uploaded in base 64 (at least through the API), so we convert it to base64 and strip out the new line characters. Other than that, nothing special.

**FOUR**. Now upload the config file to github:

     curl --request PUT --user "pconwell:TOKEN" --data '{"message": "automated backup", "content": '"$temp64"', "sha": '"$hash"'}' https://api.github.com/repos/pconwell/edgerouter/contents/config.boot.erxsfp

You can see that the content of the API call is your config file from step 3 and the sha hash is the hash from step 2. Again, you will want to change your username and repo name to match your github file. Also, if you have a different router you may want to change the 'erxsfp' part, but that's personal preference.

That's all that's needed to back your config up to github. From here you have a few options, but the most automated way is to run the script each time you save a configuration using the CLI (not sure how/if this would work through the GUI).

You just need to edit /etc/bash_completion.d/vyatta-cfg. About 20% down the file you will see `save ()` and something like

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

You just need to edit yours to add the last line '/config/user-data/github-backup.sh' (assuming you saved your script from above at that location with that name). That's it. Now every time you configure then commit; save;, you will automatically back up your config file to github. I'm not really sure how changes are commited and saved in the gui, so this script may or may not work for changes made in the gui.

****

You can also use the `dnsmasq.adlist.conf` file to create a DNS level ad blocker, but you are probably better off installing pihole to a VM or docker or a raspberry pi.
