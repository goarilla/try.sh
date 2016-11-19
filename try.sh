#! /bin/bash

NAP=${NAP:-2}
WIDTH=${WIDTH:-40}

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


# all shifts are to the left
#

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
	[ $@ -lt 2 ] && return 2
	rounds="$1"
	string="$2"

	len="${#string}"
	while [ $len -gt $ronds ]; do
		$len=$((len-1))
		msg="${msg}$(nth_element "$len" "$string")" 
			
	done
	echo "$msg" | rev


}

#### collection functions ####
function first_element()
{
	# list
	if [ $# -gt 1 ]; then
		for arg; do
			echo "$arg"
			return
		done

	fi

	# string
	for i in $(echo "$1" | sed -e 's/./& /g'); do
		echo "$i"
		return
	done
	
}

function last_element()
{
	# list
	last=""
	if [ $# -gt 1 ]; then
		for arg; do
			last="$arg"
		done
		echo "$last"
		return
	fi

	# string
	last=""
	for i in $(echo "$1" | sed -e 's/./& /g'); do
		last="$i"
		echo "$last"
		return
	done

}

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
	[ $index -gt ${#1} ] && return 1
	for c in $(echo "$1" | sed -e 's/./& /g'); do
		if [ $i -eq $index ]; then
			echo "$c"
			return 0
		fi
	done
	
	return 1	
}


function next_ping_string()
{
	# rotate_string wrapper
	# direction fixed
	# line fixed
	#
	# rounds 
	# char

	# if [ $# -eq 1 ] shift_string 1 $PINGS +  $lastchar $PINGS$@ $lastchar $PINGS
	# if [ $# -eq 2 ] shift_string $rounds $PINGS + char + lengten(char)
	[ $# -lt 2 ] && return 2
	rounds="$1"
	char="$2"

}

function length_line()
{
	# $*: line
	i=0
	for c in $(echo "$*" | sed -e 's/./\ &/g'); do
		i=$((i+1))
	done
	echo "$i" 
}

function print_pongs_line()
{
	# build on state
	# update pongsline
	echo "$PONGSLINE" 
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
	msg="# STATUS: "
	msg="${msg} $STATUS "
	echo "$msg"
	rounds="$((40-${#msg}))"
	echo
	# LASTRTT
	# AVGRTT # MAXRTT # MINRTT
	# LOSSES
}

function draw_new_screen()
{
	# wrapper procedure
	[ $# -ne 0 ] && return 1
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
	MAXRT=0
	LOSSES=0
	STATE="-"


}

function update_state()
{
	# update global state
	# parse ping output
	# update intlist
	# update $PONGSLINE
	#
	# $PINGS
	# $LOSSES
	# $AVGRTT #5*AVGRTT + 10*$now/3
	# $MAXRTT MAX(AVGRTT)
	# $MINRTT MIN(AVGRTT)
	# #STATE #(DEAD|ALIVE)

	# $1: $? of ping command
	# $2: output of ping command
	# ----------------------------- #

	# parse ping output

:
}



function main()
{
	[ $# -ne 1 ] && return 2

	init_state
	while (( 1 )); do
		start="$(date '+%s.%S')"
		output="$(ping -w 1 "$1")"
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
