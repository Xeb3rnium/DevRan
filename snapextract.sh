#!/bin/bash
#
# Extract all snaps present or deleted on Snapchat, requires rooted Android with debugging enabled - Xeb3rnium
#
if [[ $(adb devices | wc -l) == *2* ]];
then echo -e "\n---Please connect device---\n";
else
	echo -e "---Pulling all Snapchats---\n"
	for dir in {chat_snap,story_snap,snap};
	#for dir in {chat_snap,story_snap,snap,snap_first_frame,posted_story_snap,memories_media,memories_thumbnail,memories_overlay,media_package_thumb,external_sticker,non_user_bitmoji}
	do
		adb exec-out su -c cp -r /data/data/com.snapchat.android/files/file_manager/$dir /sdcard/snaps
	done
	adb pull /sdcard/snaps .
	for folder in ./snaps/*;
	do
        	if [ -z "$(ls -A "$folder")" ];
        	then rm -r "$folder";
        	else
        		for file in $folder/*; 
        		do
                		if (file "$file" | grep -q text);
                		then mv "$file" "$file.txt";
                		else 
                        		if (file "$file" | grep -q ISO);
                        		then mv "$file" "$file.mp4";
	                        	else 
        	                        	if (file "$file" | grep -q JFIF);
                	                	then mv "$file" "$file.jpeg"
                        	        	else 
                                	        	if (file "$file" | grep -q RIFF);
                                        		then mv "$file" "$file.webp"
                                        		else 
                                                		if (file "$file" | grep -q PNG);
                                                		then mv "$file" "$file.png"
                                                		fi
                                        		fi
                                		fi
                        		fi
                		fi
        		done
		fi
	done
	adb exec-out rm -r /sdcard/snaps
	echo -e "\n---Done---"
fi
