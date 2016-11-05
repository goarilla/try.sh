 #! /bin/sh
NAP=60
old=0

while [ true ]; do 
	rm newest.php
	wget 'http://en.pastebin.ca/newest.php'
	
        id="$(grep -m 1 'http://en.pastebin.ca/[0-9][0-9]*' newest.php)"
	id="$(echo "$id" | sed -e 's/..*pastebin.ca\/\([0-9][0-9]*\).*/\1/g')"

        if [ x"$old" != x"$id" ]; then
        	open 'http://en.pastebin.ca/newest.php'
                old="$id"
        fi

	sleep $(( $(($((NAP*3))/4)) + $((RANDOM%$(($NAP/2)))) ))
done 
