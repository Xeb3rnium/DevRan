#!/usr/bin/env python3
import hashlib


seed = "ecsc"
final = "c89aa2ffb9edcc6604005196b5f0e0e4"
chain = seed
flag = seed
clock = 0



def md5(val):
	hash = hashlib.md5()
	hash.update(val.encode('utf-8'))
	return hash.hexdigest()

while chain != final:
  chain = md5(chain)
  clock = clock + 1

for i in range(clock - 1):
  flag = md5(flag)



print(flag + " hashes to " + final + "\nThus " + seed + " = " + final + " with MD5 chain length of " + str(clock))