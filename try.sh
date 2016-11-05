#! /bin/sh
# vim: set ts=4 sts=4 sw=4 expandtab smartindent tw=78:
# script that speaks irc chat logs with Mac OS X's say utility.

# say(1) voices
# Agnes               en_US    # Isn't it nice to have a computer that will talk to you?
# Albert              en_US    #  I have a frog in my throat. No, I mean a real frog!

VOICES="$(say -v ? | grep 'en_')"

get_val()
{
	# return numeric value of char in alphabet
	python -c "print ord('$1')"
}

score_speaker()
{
	# score between 1-30
	score=0
	for char in $(echo "$1" | sed -e 's/./\ &/g'); do
		score=$(( score+$(get_val $char) ))
	done
	echo $(( $((score%30))+1 ))

}

while read line;
do
  echo "$line" 
	speaker="$(echo "$line" | cut -d':' -f1)"
	msg="$(echo "$line" | cut -d':' -f2-)"
  
	say -v "$(echo "$VOICES" | sed -n -e "$(score_speaker "$speaker")"p | cut -d' ' -f1)" "$msg"
done < "$1"
