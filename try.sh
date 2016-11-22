#! /bin/bash
# try.sh [ping_top]
#
# vim: set ts=4 sws=4 sw=4 smartindent tw=78:

NAP=${NAP:-1}
WIDTH=${WIDTH:-52}

## 192.168.1.1 ############################
#-----------+----------------+-+---+-------
###########################################
## STATUS: OK  ############################
## LASTRTT:    ############################
## AVG:     |  MIN:   |    MAX:  ##########
## TOTAL:   | LOSSES:   ###################
###########################################

_float_gt()
{
	# $1 > $2
	if [ x"$(echo "$1 > $2" | bc)" = x"1" ]; then
		return 0
	else
		return 1
	fi
	return 2
}

multiply_char()
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

first_char()
{
	# $1: input string
	[ $# -ne 1 ] && return 2

	echo "$1" | sed -e 's/^\(.\).*/\1/g'
	return $?
}

draw_new_screen()
{
	[ $# -ne 0 ] && return
	clear

	# print header
	msg=" $HOST "
	len="${#msg}"
	mid="$(($((WIDTH-len))/2))"
	rest="$(($((WIDTH-len))%2))"
	msg="$(multiply_char '#' $mid)${msg}"
	msg="${msg}$(multiply_char '#' $((mid+rest)))"
	printf "%s\n" "$msg"

	# print pongsline
	for val in "${PINGS[@]}"; do
		[ x"$val" = x"0" ] && printf "-" && continue
		[[ $val = [0-9][0-9.]* ]] && printf "+" && continue
		printf "%c" "$val"
	done
	printf "\n"

	# print border/spacer line
	printf "%s\n" "$(multiply_char '#' $WIDTH)"

	# print stats
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

	# TOTAL # LOSSES
	msg="# TOTAL: ${TOTAL} | LOSSES: ${LOSSES} "
	rounds="$((WIDTH-${#msg}))"
	padding="$(multiply_char '#' $rounds)"
	msg="${msg}${padding}"
	printf "%s\n" "$msg"

	# print border/spacer line
	printf "%s\n" "$(multiply_char '#' $WIDTH)"
}


init_state()
{
	# create global state
	for ((i=0;i<"$WIDTH";i++)); do
		PINGS[$i]="#"
	done

	AVGRTT=0
	MINRTT=9999
	MAXRTT=0
	LOSSES=0
	STATUS="-"

	TOTAL=0
	GOOD=0
}

update_state()
{
	# $1: $? of ping command
	# $2: output of ping command

	# parse ping output
	if [ $1 -ne 0 ]; then
		LASTRTT=0
	else
		LASTRTT="$(echo "$2" | grep '^64\ bytes' | \
			awk 'END { print $((NF-1)) }' | cut -d'=' -f2)"
	fi

	## update state
	# PINGS array
	for ((i=0;i<"${#PINGS[@]}";i++)); do
		PINGS[$i]="${PINGS[$((i+1))]}"
	done
	# fresh value
	PINGS["${#PINGS[@]}"]="$LASTRTT"

	# $TOTAL
	TOTAL="$((TOTAL+1))"

	# $STATUS
	[ x"$LASTRTT" != x"0" ] && STATUS=OK || STATUS=DEAD

	# $LOSSES
	[ x"$LASTRTT" = x"0" ] && LOSSES="$((LOSSES+1))"

	# $MAXRTT MAX(LASTRTT)
	_float_gt "$LASTRTT" "$MAXRTT" && MAXRTT="$LASTRTT"

	# $MINRTT MIN(LASTRTT)
	[ x"$LASTRTT" != x"0" ] && _float_gt "$MINRTT" "$LASTRTT" && \
		MINRTT="$LASTRTT"

	# $AVGRTT
	[ x"$AVGRTT" = x"0" ] && AVGRTT="$LASTRTT"
	GOOD="$((TOTAL-LOSSES))"
	if [ $GOOD -gt 0 ]; then
		AVGRTT="$(echo "scale=3;(($GOOD-1)*$AVGRTT+$LASTRTT)/$GOOD" | bc -l)"
	fi
	[ x"$(first_char "$AVGRTT")" = x"." ] && AVGRTT="0${AVGRTT}"
}

usage()
{
	printf "Usage: %s ip|hostname\n" "$(basename "$0")"
}

main()
{
	if [ $# -ne 1 ]; then
		usage 1>&2
		exit 1
	fi
	HOST="$1"

	# which ping
	case "$(uname -a)" in *Linux*)
		# Linux
		PINGTOOL="ping -w 1 -c 1"
		;;
		*)
		# other (MacOSX/*BSD)
		PINGTOOL="ping -t 1 -c 1"
		;;
	esac

	init_state
	while (( 1 )); do
		start="$(date '+%s.%S')"
		output="$($PINGTOOL "$HOST" 2>/dev/null)"
		rc=$?

		#
		update_state "$rc" "$output"
		draw_new_screen

		# decide sleep interval
		end="$(date '+%s.%S')"
		delta="$(echo "$end-$start" | bc )"
		diff="$(echo "$NAP - $delta + 0.01" | bc)"
		if [ "$(echo "$diff >= 1" | bc)" -eq 1 ]; then
			sleep "$(echo "$diff" | awk 'END { print int($1) }')"
		fi
	done
}

main "$@"
