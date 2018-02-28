temp1='"'`curl --request GET --user "USER:TOKEN" https://api.github.com/repos/pconwell/edgerouter/contents/config.boot.erxsfp | jq -r '.content' | tr -d '\n'`'"'

hash='"'`curl  https://api.github.com/repos/pconwell/edgerouter/contents/config.boot.erxsfp | grep sha | cut -d '"' -f4`'"'
temp64='"'`/bin/cli-shell-api showCfg --show-hide-secrets | base64 | tr -d '\n'`'"'

if [ "$temp1" == "$temp64" ];

then

	echo true;
	
else

curl --request PUT --user "USER:TOKEN" --data '{"message": "automated backup", "content": '"$temp64"', "sha": '"$hash"'}' https://api.github.com/repos/pconwell/edgerouter/contents/config.boot.erxsfp


fi
