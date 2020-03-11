#!/usr/bin/env python3
import sys



def swipe():
	num = "".join(input("Enter card number:  ").split())
	if len(num) > 16:
		print("Card number too long")
		exit()
	return num


def verify():
	card = [int(i) for i in str(swipe())]
	algo = (sum([int(i) for i in card][::2]) * 2) + sum(i >= 5 for i in [int(i) for i in card][::2]) + sum([int(i) for i in card][1::2])
	if algo % 10 == 0:
		print("Card is valid")
	else:
		print("Card is not valid")


def vendor():
	card = swipe()
	iin = card[:6]
	m = str(["50",range(56,69),"6759","676770","676774"])
	l = str(["6304", "6706", "6771", "6709"])
	if iin.startswith(str(4)):
		print("Visa")
	elif iin.startswith(tuple(m)):
		print("Maestro")
	elif iin.startswith(tuple(l)):
		print("Laser")


def checksum():
	card = swipe()
	iin = card[:-4]


def generate():
	print("Work in progress")



if len(sys.argv) < 2 or len(sys.argv) > 2:
	print("Usage: luhn.py (verify | vendor | checksum | generate)")

else:
	opt = ["verify","vendor","checksum","generate"]
	cmd = sys.argv[1]

	if cmd in opt[0]:
		verify()
	elif cmd in opt[1]:
		vendor()
	elif cmd in opt[2]:
		checksum()
	elif cmd in opt[3]:
		generate()