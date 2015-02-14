#!/bin/bash

log() { echo "$(date "+%F %T") $*" >> $logfile; }
raw() { echo "$*" >> .botfile; }

. nwbot.cfg
if $has_key; then read -sp "Channel key? " chankey; fi
if $use_ssl; then connect_command="ncat --ssl"; else connect_command="nc"; fi

numberwang=$(($RANDOM % 100))
log "starting. numberwang is $numberwang"

rm .botfile 2>/dev/null
mkfifo .botfile
chmod 600 .botfile
touch $logfile
chmod 600 $logfile
trap "rm .botfile; log 'quitting'" exit term kill
first_run=true

tail -f .botfile | $connect_command $server $port | while true; do
    if $first_run; then
        raw "NICK $nick"
        raw "USER $nick 0 $nick :That's Botwang!"
        raw "JOIN $channel $chankey"
        first_run=false
    fi
    read line
    line=$(echo "$line" | tr -d "\r\n")
    if echo "$line" | grep -qi "^ping"; then
        raw "$(echo "$line" | sed "s/ping/PONG/i")"
    elif echo "$line" | grep -qi " PRIVMSG $channel :$nick: source"; then
        raw "PRIVMSG $channel :https://github.com/relsqui/numberwanger"
    elif echo "$line" | grep -qiv " PRIVMSG $channel :.*\b$numberwang\b"; then
        continue
    else
        raw "PRIVMSG $channel :THAT'S NUMBERWANG!"
        numberwang=$(($RANDOM % 100))
        log "numberwang is now $numberwang"
    fi
done
