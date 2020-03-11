#!/usr/bin/env python3
import sys
import codecs

#TODO
#
#Fix special characters passed as args not being escaped passed on cli
#Bruteforce all iterations
#

def rot5(msg):
	print(msg.translate(str.maketrans("0123456789", "5678901234")))

def rot13(msg):
	#print(msg.translate(str.maketrans("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz", "NOPQRSTUVWXYZABCDEFGHIJKLMnopqrstuvwxyzabcdefghijklm")))
	print(codecs.encode(msg,'rot13'))

def rot47(msg):
	print(msg.translate(str.maketrans("!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~", "PQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNO")))



if len(sys.argv) < 3 or len(sys.argv) > 3:
	print("Usage: brute.py (dec | alpha | all) <ciphertext>")

else:
	opt = ["dec","alpha","all"]
	key = sys.argv[1]
	msg = sys.argv[2]

	if key in opt[0]:
		rot5(msg)
	elif key in opt[1]:
		rot13(msg)
	elif key in opt[2]:
		rot47(msg)
