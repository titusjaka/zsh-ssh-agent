typeset ssh_environment

function start_ssh_agent() {
	local lifetime
	local -a identities

	zstyle -s :plugins:ssh-agent lifetime lifetime

	ssh-agent -s ${lifetime:+-t} ${lifetime} | sed 's/^echo/#echo/' >! $ssh_environment
	chmod 600 $ssh_environment
	source $ssh_environment > /dev/null

	zstyle -a :plugins:ssh-agent identities identities

	if [[ ${#identities} -eq 0 ]]; then
		# key list found on `ssh-add` man page's DESCRIPTION section
		for id in id_rsa id_dsa id_ecdsa id_ed25519 identity; do
		# check if file exists
			[[ -f "$HOME/.ssh/$id" ]] && identities+=($id)
		done
	fi

	zstyle -a :plugins:ssh-agent smart_cards smart_cards

	echo starting ssh-agent...
	ssh-add $HOME/.ssh/${^identities}

	if [[ ${#smart_cards} -gt 0 ]]; then
		ssh-add -s ${^smart_cards}
	fi
}

ssh_environment="$HOME/.ssh/environment-$HOST"

if [[ -f "$ssh_environment" ]]; then
	source $ssh_environment > /dev/null
	ps x | grep ssh-agent | grep -q $SSH_AGENT_PID || {
		start_ssh_agent
	}
else
	start_ssh_agent
fi

unset ssh_environment
unfunction start_ssh_agent
