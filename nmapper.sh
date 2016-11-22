#! /bin/sh
# nmapper.sh
#
# Moi, The FTP-server Explorer.
#
# vim: set ts=4 sws=4 sw=4 smartindent tw=78:

SPREAD=${SPREAD:-30}
BOTTOM=${BOTTOM:-30}

i=0
while (( 1 )); do
	nmap -p 21,80 -Pn -sT -iR 1 --open
	sleep "$((BOTTOM+RANDOM%(SPREAD+1)))"
	i="$((i+1))"	
	[ $(($i%10)) -eq 0 ] && printf "%d probes sent" "$i"
done


