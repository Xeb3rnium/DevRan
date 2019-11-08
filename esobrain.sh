#!/bin/bash
#
# Quick dirty script I wrote during a ctf that transliterates esolangs into brainfuck and visa versa
#
if [[ -z "$1" || -f "$1" || -d "$1" ]]
	then
		echo "Usage: "
		echo "esobrain -r <file to read>"
		echo "esobrain -t <file to transliterate>"
		echo
	exit
fi

#Brainfuck to Esolang
if [[ "$1" == "-r" && -f "$2" ]]
	then
		echo "Enter replacement for '>':"
		read rPointer
		echo "Enter replacement for '<':"
		read lPointer
		echo "Enter replacement for '+':"
		read uPointer
		echo "Enter replacement for '-':"
		read dPointer
		echo "Enter replacement for '.':"
		read oPointer
		echo "Enter replacement for ',':"
		read iPointer
		echo "Enter replacement for '[':"
		read oBracket
		echo "Enter replacement for ']':"
		read cBracket
		echo
		echo "Translating"
		sed -i '' -e "s/>/$rPointer/g" $2
		sed -i '' -e "s/</$lPointer/g" $2
		sed -i '' -e "s/+/$uPointer/g" $2
		sed -i '' -e "s/-/$dPointer/g" $2
		sed -i '' -e "s/\./$oPointer/g" $2
		sed -i '' -e "s/,/$iPointer/g" $2
		sed -i '' -e "s/\]/$cBracket/g" $2
		sed -i '' -e "s/\[/$oBracket/g" $2
		echo "Done"
fi

#Esolang to Brainfuck
if [[ "$1" == "-t" && -f "$2" ]]
	then
		echo "Enter replacement for '>':"
		read rPointer
		echo "Enter replacement for '<':"
		read lPointer
		echo "Enter replacement for '+':"
		read uPointer
		echo "Enter replacement for '-':"
		read dPointer
		echo "Enter replacement for '.':"
		read oPointer
		echo "Enter replacement for ',':"
		read iPointer
		echo "Enter replacement for '[':"
		read oBracket
		echo "Enter replacement for ']':"
		read cBracket
		echo
		echo "Translating"
		sed -i '' -e "s/$rPointer/>/g" $2
		sed -i '' -e "s/$lPointer/</g" $2
		sed -i '' -e "s/$uPointer/+/g" $2
		sed -i '' -e "s/$dPointer/-/g" $2
		sed -i '' -e "s/$oPointer/./g" $2
		sed -i '' -e "s/$iPointer/,/g" $2
		sed -i '' -e "s/$oBracket/\[/g" $2
		sed -i '' -e "s/$cBracket/\]/g" $2
		echo "Done"
fi
