#! /bin/bash
# try.sh [ping_top]
#
# vim: set ts=4 sws=4 sw=4 smartindent tw=78:

NAP=${NAP:-1}
WIDTH=${WIDTH:-52}

## 192.168.1.1 ############################
#----------+----------------+-+-- +-------+
###########################################
## STATUS: OK  ############################
## LASTRTT:    ############################
## AVG:     |     MIN:   |    MAX: ########
## LOSSES:   ##############################
###########################################

function _float_toint()
{
	#printf 1>&2 "%s\n" "_float_toint()"
	# truncates a float to int
	[ $# -ne 1 ] && return 2
	awk "END { print int($1) }" < /dev/null
}

function _float_gt()
{
	#printf 1>&2 "%s\n" "_float_gt()"
	# $1 > $2
	if [ x"$(echo "$1 > $2" | bc)" = x"1" ]; then
		return 0
	else
		return 1
	fi
	return 2
}

function multiply_char()
{
	#printf 1>&2 "%s\n" "multiply_char()"
	# $1: char
	# $2: multiplier
	[ $# -eq 1 ] && set -- "$@" 2
	[ $# -ne 2 ] && return 2
	msg=""
	multiplier="$2"

	while [ $multiplier -gt 0 ]; do
		msg="${msg}$1"
		multiplier="$((multiplier-1))"
	done
	echo "$msg"
}

# all shifts are to the left
#
function shift_itemlist()
{
	#printf 1>&2 "%s\n" "shift_itemlist()"
	# $1: rounds
	# $2: rest line
	[ $# -lt 2 ] && return 2
	rounds="$1"
	for i in $(seq 1 $rounds); do
			shift
	done
	echo "$@"
}

function shift_string()
{
	#printf 1>&2 "%s\n" "shift_string()"
	# $1: rounds
	# $2: rest line
	[ $# -lt 2 ] && return 2
	rounds="$1"
	string="$2"

	len="${#string}"
	msg=""
	while [ $len -gt $rounds ]; do
		len=$((len-1))
		msg="${msg}$(nth_element "$len" "$string")" 
			
	done
	echo "$msg" | rev
}

#### collection functions ####
#
function nth_element()
{
	#printf 1>&2 "%s\n" "nth_element()"
	# which
	[ $# -lt 2 ] && return 2
	index="$1"
	shift

	# list
	if [ $# -gt 1 ]; then
		[ $index -gt ${#@} ] && return 1
		i=0
		for arg; do
			if [ $i -eq $index ]; then
				echo "$arg"
				return 0
			fi
			i=$((i+1))					
		done
		return 1
	fi

	# string
	i=0
	[ $index -gt ${#1} ] && return 1 # probably useless
	for c in $(echo "$1" | sed -e 's/./& /g'); do
		if [ $i -eq $index ]; then
			echo "$c"
			return 0
		fi
	        i=$((i+1))
	done
	
	return 1	
}

function first_element()
{
	#printf 1>&2 "%s\n" "first_element()"
	nth_element 0 "$@"
}

function last_element()
{
	#printf 1>&2 "%s\n" "last_element()"
	args="$@"
	i=0
	for i in $(echo $args); do
		i=$((i+1))
	done

	if [ "$i" -eq 1 ]; then
		# assume string
		# even though it could be a singleton list
		last=0
		for c in $(echo "$args" | sed -e 's/./\ &/g'); do
			last=$((last+1))
		done
		nth_element "$last" "$@"
		return $?
	fi

	nth_element "$i" "$@"
	return $?
}

# print functions
#
function print_pongs_line()
{
	#printf 1>&2 "%s\n" "print_pongs_line()"
	printf "%s\n" "$PONGSLINE"
}

function print_border_line()
{
	#printf 1>&2 "%s\n" "print_border_line()"
	printf "%s\n" "$(multiply_char '#' $WIDTH)"
}

function print_header_line()
{
	#printf 1>&2 "%s\n" "print_header_line()"
	# $1: host
	[ $# -ne 1 ] && return 2
	msg=" $1 "
	len="${#msg}"
	mid="$(($((WIDTH-len))/2))"
	rest="$(($((WIDTH-len))%2))"
	msg="$(multiply_char '#' $mid)${msg}"
	msg="${msg}$(multiply_char '#' $((mid+rest)))"
	printf "%s\n" "$msg"
}

function print_stats()
{
	#printf 1>&2 "%s\n" "print_stats()"
	# STATUS
	msg="# STATUS:"
	msg="${msg} ${STATUS} "
	rounds="$((WIDTH-${#msg}))"
	padding="$(multiply_char '#' $rounds)"
	msg="${msg}${padding}"
	printf "%s\n" "$msg"

	# LASTRTT
	msg="# LASTRTT:"
	msg="${msg} ${LASTRTT} "
	rounds="$((WIDTH-${#msg}))"
	padding="$(multiply_char '#' $rounds)"
	msg="${msg}${padding}"
	printf "%s\n" "$msg"

	# AVGRTT # MAXRTT # MINRTT
	msg="# AVGRTT: ${AVGRTT} | MAX: ${MAXRTT} | MIN: ${MINRTT} "
	rounds="$((WIDTH-${#msg}))"
	padding="$(multiply_char '#' $rounds)"
	msg="${msg}${padding}"
	printf "%s\n" "$msg"

	# LOSSES
	msg="# LOSSES: ${LOSSES} "
	rounds="$((WIDTH-${#msg}))"
	padding="$(multiply_char '#' $rounds)"
	msg="${msg}${padding}"
	printf "%s\n" "$msg"
}

#
#
function draw_new_screen()
{
	#printf 1>&2 "%s\n" "draw_new_screen()"
	# wrapper procedure
	[ $# -ne 0 ] && return
	clear

	print_header_line "$HOST"
	print_pongs_line
	print_border_line
	print_stats
	print_border_line
}


function init_state()
{
	#printf 1>&2 "%s\n" "init_stat()"
	#create global state
	for i in $(seq 0 20); do
		PINGS="$PINGS 0"
	done

	PONGSLINE=""
	i=0
	while [ $i -lt $WIDTH ]; do
		PONGSLINE="${PONGSLINE}#"
		i="$((i+1))"
	done
	PONGSLINE="$(echo $PONGSLINE)"

	AVGRTT=0
	MINRTT=0
	MAXRTT=0
	LOSSES=0
	STATUS="-"


}

function update_state()
{
	#printf 1>&2 "%s\n" "update_state()"
	# $1: $? of ping command
	# $2: output of ping command

	# parse ping output
	if [ $1 -ne 0 ]; then
		LASTRTT=0
	else
		LASTRTT="$(echo "$2" | grep '^64\ bytes' | \
			awk 'END { print $((NF-1)) }' | cut -d'=' -f2)"
	fi

	# update state
	# $STATUS
	[ x"$LASTRTT" != x"0" ] && STATUS=OK || STATUS=DEAD

	# $LOSSES
	[ "$(_float_toint "$LASTRTT")" -eq 0 ] && LOSSES="$((LOSSES+1))"

	# $MAXRTT MAX(LASTRTT)
	_float_gt "$LASTRTT" "$MAXRTT" && MAXRTT="$LASTRTT"

	# $MINRTT MIN(LASTRTT)
	[ x"$MINRTT" = x"0" ] && MINRTT="$LASTRTT"
	_float_gt "$MINRTT" "$LASTRTT" && MINRTT="$LASTRTT"

	# $AVGRTT
	[ x"$AVGRTT" = x"0" ] && AVGRTT="$LASTRTT"
	AVGRTT="$(echo "scale=3;(5*$AVGRTT+10*$LASTRTT)/15" | bc -l)"

	# update intlist $PINGS
	PINGS="$(shift_itemlist 1 $PINGS)"
	PINGS="$PINGS $LASTRTT"

	# update PONGSLINE
	PONGSLINE="$(shift_string 1 "$PONGSLINE")"
	if [ x"$LASTRTT" != x"0" ]; then
		PONGSLINE="${PONGSLINE}+"
	else
		PONGSLINE="${PONGSLINE}-"
	fi
}

function usage()
{
	#printf 1>&2 "%s\n" "usage()"
	printf "Usage: %s ip|hostname\n" "$(basename "$0")"
}

function main()
{
	#printf 1>&2 "%s\n" "main()"
	if [ $# -ne 1 ]; then
		usage 1>&2
		exit 1
	fi
	HOST="$1"

	init_state
	while (( 1 )); do
		start="$(date '+%s.%S')"
		# mac osx
		output="$(ping -c 1 -t 1 "$HOST" 2>/dev/null)"
		# linux
		#output="$(ping -c 1 -w 1 "$HOST" 2>/dev/null)"
		rc=$?

		#
		update_state "$rc" "$output"
		draw_new_screen

		# decide sleep interval
		end="$(date '+%s.%S')"
		delta="$(echo "$end-$start" | bc )"
		diff="$(echo "$NAP - $delta + 0.01" | bc)"
		if [ "$(echo "$diff >= 1" | bc)" -eq 1 ]; then
			sleep "$(_float_toint "$diff")"
		fi
	done
}

main "$@"
