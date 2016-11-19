#! /bin/bash
# try.sh [ping_top]
#
# vim: set ts=4 sws=4 sw=4 smartindent tw=78:

NAP=${NAP:-2}
WIDTH=${WIDTH:-52}
TICKS=${TICKS:-2}

###########################################
#----------*----------------*-*-- *-------# 
###########################################
## STATUS: OK  ############################
## LASTRTT:    ############################
## AVG:     |     MIN:   |    MAX: ########
## LOSSES:   ##############################
###########################################

function _float_toint()
{
	# truncates a float to int
	[ $# -ne 1 ] && return 2
	awk "END { print int($1) }" < /dev/null
}

function multiply_char()
{
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
function shift_intlist()
{
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
	nth_element 0 "$@"
}

function last_element()
{
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
	printf "%s\n" "$PONGSLINE"
}

function print_border_line()
{
	i=0
	while [ $i -lt $WIDTH ]; do
		printf "%c" "#"
		i=$((i+1))
	done
	printf "\n"
}

function print_footer_section()
{
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
	# wrapper procedure
	[ $# -ne 0 ] && return
	clear

	print_border_line
	print_pongs_line
	print_border_line
	print_footer_section
	print_border_line
}


function init_state()
{
	#create global state
	for i in $(seq 0 20); do
		PINGS="$PINGS 0"
	done

	PONGSLINE=""
	i=0
	while [ $i -lt $WIDTH ]; do
		PONGSLINE="${PONGSLINE}#"
		i=$((i+1))
	done
	PONGSLINE=$(echo $PONGSLINE)

	AVGRTT=0
	MINRTT=0
	MAXRTT=0
	LOSSES=0
	STATUS="-"


}

function update_state()
{
	# $1: $? of ping command
	# $2: output of ping command

	# parse ping output
	if [ $1 -ne 0 ]; then
		LASTRTT=0
	else
		LASTRTT="$(echo "$2" | grep '^64\ bytes' | \
			awk 'END { print $((NF-1))}'| cut -d'=' -f2)"
	fi

	# update state
	# $LOSSES
	[ "$LASTRTT" -eq 0 ] && LOSSES="$((LOSSES+1))"

	# $MAXRTT MAX(LASTRTT)
	[ "$LASTRTT" -gt "$MAXRTT" ] && MAXRTT="$LASTRTT"

	# $MINRTT MIN(LASTRTT)
	[ "$MINRTT" -gt "$LASTRTT" ] && MINRTT="$LASTRTT"

	# $AVGRTT
	AVGRTT="$(echo "(5*$AVGRTT+10*LASTRTT)/15)" | bc)"

	# update intlist $PINGS

	# update PONGSLINE

}

function usage()
{
	printf "Usage: %s ip|hostname\n" "$(basename "$0")"
}

function main()
{
	if [ $# -ne 1 ]; then
		usage 1>&2
		exit 1
	fi

	init_state
	while (( 1 )); do
		start="$(date '+%s.%S')"
		# mac osx
		output="$(ping -c 1 -t 1 "$1")"
		# linux
		#output="$(ping -c 1 -w 1 "$1")"
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
