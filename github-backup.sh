hash='"'`curl  https://api.github.com/repos/pconwell/edgerouter/contents/config.boot.erxsfp | grep sha | cut -d '"' -f4`'"'
temp64='"'`/bin/cli-shell-api showCfg --show-hide-secrets | base64 | tr -d '\n'`'"'
curl --request PUT --user "pconwell:TOKEN" --data '{"message": "automated backup", "content": '"$temp64"', "sha": '"$hash"'}' https://api.github.com/repos/pconwell/edgerouter/contents/config.boot.erxsfp
