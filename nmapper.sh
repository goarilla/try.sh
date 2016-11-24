#! /bin/sh
# nmapper.sh
#
# Moi, The FTP-server Explorer.
#
# vim: set ts=4 sws=4 sw=4 smartindent tw=78:

SPREAD=${SPREAD:-30}
BOTTOM=${BOTTOM:-30}
SVC=${SVC:-"21,80"}

filter_output()
{
	# $1: file
	mv "$1" "$1".full
	# ipv4 only
	egrep -o '[1-2]?[0-9]{0,2}\.[1-2]?[0-9]{0,2}\.[1-2]?[0-9]{0,2}\.[1-2]?[0-9]{0,2}' "$1".full > "$1"
#	rm "$1".full
}

trap "filter_output "$1"; exit 66" EXIT INT HUP TERM ABRT TSTP

i=0
while (( 1 )); do
	nmap -p "$SVC" -Pn -sT -iR 1 --open | tee -a "$1"
	sleep "$((BOTTOM+RANDOM%(SPREAD+1)))"
	i="$((i+1))"
	[ $(($i%10)) -eq 0 ] && printf "%d probes sent" "$i"
done

