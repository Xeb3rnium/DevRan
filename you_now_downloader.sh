#!/bin/bash

verbose=false

source ./you_now_moments.sh

echo "+--------------------------------------------+"
echo "|        YouNow video downloader             |"
echo "+--------------------------------------------+"
echo "|       This script helps you download       |"
echo "|   YouNow.com broadcasts and live streams   |"
echo "+--------------------------------------------+"
echo "| 1.0   @nikisdro             [ 2015-07-25 ] |"
echo "|       * Windows script for YN downloading  |"
echo "|                                            |"
echo "| 1.1   truethug              [ 2016-02-05 ] |"
echo "|       * Extend script to linux/ mac        |"
echo "|                                            |"
echo "| 1.2   IcedPenguin           [ 2016-05-28 ] |"
echo "|       * Fix for new YN streaming format    |"
echo "|                                            |"
echo "| 1.3   IcedPenguin           [ 2016-06-14 ] |"
echo "|       * Updated the menuing system         |"
echo "|       * Added moment support               |"
echo "|                                            |"
echo "| 1.4   Xeb3rnium             [ 2019-05-19 ] |"
echo "|       * Ported into Bash scripts           |"
echo "|                                            |"
echo "+--------------------------------------------+"
echo ""
echo "Paste broadcast URL or username below (right click - Paste) and press Enter"
echo "Example 1: https://www.younow.com/example_user/54726312/1877623/1043/b/June..."
echo "Example 2: example_user"
echo ""
echo "This script relise on several binary files located in ./_bin. You are responsible "
echo "for finding these files. Apt-get or brew install them."
echo "    file: ffmpeg"
echo "    file: rtmpdump"
echo "    file: xidel"
echo "    file: wget"
echo "    file: jq"
echo " "


function mainProgramLoop() {
    local status="running"
    while [[ "${status}" == "running" ]]; do
        echo ""
        echo "URL or username (leave blank to quit):" 
        read entered_name
        web=`echo $entered_name | grep 'younow.com'`

        if [ -z ${entered_name} ]; then
            status="exit"

        elif [ ! -z ${web} ]; then
            directDownloadMenu

        else
            userDownloadMenu "${entered_name}"
        fi
    done
}


# @param: url
function directDownloadMenu()
{
    local url=$1

    user=`echo ${url} | cut -d'/' -f4`
    broadcast_id=`echo ${url} | cut -d'/' -f5`
    user_id=`echo ${url} | cut -d'/' -f6`

    downloadVideo "${user}" "0" "${broadcast_id}"

    echo " OK! Started download in a separate window."
}

# Handles the user interaction for downloading videos for a YouNow user. This
# includes capturing live broadcasts, downloading past broadcasts, or downloading
# moments.
#
# @param: user_name
function userDownloadMenu()
{
    local user_name=$1

    while : ; do
        echo " "
        wget --no-check-certificate -q "http://www.younow.com/php/api/broadcast/info/user=${user_name}" -O "./_temp/${user_name}_channel.json"

        local user_id=`cat  ./_temp/${user_name}_channel.json | jq -r '.userId'`
        local error=`cat    ./_temp/${user_name}_channel.json | jq -r '.errorCode'`
        local errorMsg=`cat ./_temp/${user_name}_channel.json | jq -r '.errorMsg'`

        if [ "${error}" == "101" ]
        then
            echo "There was a problem with the provided user name."
            echo "    Error: $errorMsg"
            echo " "
            return

        elif [ "${error}" == "0" ]; then
            echo "[LIVE] ${user_name} is broadcasting now!"
            echo "What would you like to do: Capture (L)ive Broadcast, download past (B)roadcasts, or download a (M)oment? (L / B / M)"

        else    
            echo "What would you like to do: download past (B)roadcasts or download a (M)oment? (B / M)"
        fi

        read user_action

        
        if [ "${user_action}" == "L" ] || [ "${user_action}" == "l" ]; then
            echo "LIVE mode."
            downloadLiveBroadcast "${user_name}"

        elif  [ "${user_action}" == "B" ] || [ "${user_action}" == "b" ]; then
            echo "Broadcast mode"
            downloadPreviousBroadcastsMenu "${user_id}" "${user_name}"

        elif  [ "${user_action}" == "M" ] || [ "${user_action}" == "m" ]; then
            echo "Moment mode"
            downloadMomentsMenu $user_name $user_id

        else
            return # user did not enter a command, return to previous menu.
        fi
    done
}

# Performing the actual download of a live broadcasts. The download operation takes place
# in a child process (new shell window).
#
# @param: user_name
function downloadLiveBroadcast()
{
    local user_name=${1}

    local broadcast_id=`xidel -q ./_temp/${user_name}_channel.json -e '$json("broadcastId")'`
    local temp=`xidel -q -e 'join(($json).media/(host,app,stream))' ./_temp/${user_name}_channel.json`
    local host=`echo $temp | cut -d' ' -f1`
    local app=`echo $temp | cut -d' ' -f2`
    local stream=`echo $temp | cut -d' ' -f3`
    local file_name=$(findNextAvailableFileName ${user_name} "live" ${broadcast_id} "flv")

    if [ ! -d "./videos/${user_name}" ]
    then
        mkdir "./videos/${user_name}"
    fi

    # Execute the command
    if [ "$mac" == "" ] 
    then
        $terminal -x sh -c "./you_now_broadcasts.sh live linux ${user_name} ${file_name} ${host} ${app} ${stream}"
    else

        echo "cd `pwd`; ./you_now_broadcasts.sh live mac ${user_name} ${file_name} ${host} ${app} ${stream}"  > "./_temp/${file_name}.command"
        chmod +x "./_temp/${file_name}.command"
        open "./_temp/${file_name}.command"
    fi
    echo " OK! Started recording in a separate window."
}


# @param: user_id
# @param: user_name
function downloadPreviousBroadcastsMenu()
{
    local user_id=$1
    local user_name=$2

    local ex="false"
    local idx=1
    local videos

    while [ "$ex" == "false" ]
    do
        wget --no-check-certificate -q "http://www.younow.com/php/api/post/getBroadcasts/startFrom=$startTime/channelId=${user_id}" -O "./_temp/${user_name}_broadcasts.json"
        xidel -q -e '($json).posts().media.broadcast/join((videoAvailable,broadcastId,broadcastLengthMin,ddateAired),"-")' "./_temp/${user_name}_broadcasts.json" > "./_temp/${user_name}_broadcast_list.json"
        if [  -f "./_temp/${user_name}_broadcast_list.json" ]
        then
            echo "You can download these broadcasts:"
            while read line 
            do
                available=`echo $line|cut -d'-' -f1`
                broadcast_id=`echo $line|cut -d'-' -f2`
                length=`echo $line|cut -d'-' -f3`
                ddate=`echo $line | cut -d'-' -f4`
                if [ "$available" == "1" ]
                then
                   current=""
                   echo "${idx} ${length} ${ddate} - ${broadcast_id}"
                   videos[${idx}]=${broadcast_id}
                   idx=$((idx + 1))
                fi
            done < "./_temp/${user_name}_broadcast_list.json"

            echo "Type comma separated numbers, \"all\" to download everything,"
            echo "\"n\" to list next 10 broadcasts or leave blank to return: "
            read input      

            if [ "$input" == "" ]
            then
                ex="true"
            elif [ "$input" == "n" ]
            then  
                startTime=$(( startTime  + 10 ))
            else
                if [ "$input" == "all" ]
                then
                    for i in `seq 1 ${#videos[@]}`
                    do
                        downloadVideo "${user_name}" "$i" "${videos[$i]}"
                    done
                fi

                while [ "$input" != "$current" ]
                do
                    current=`echo $input | cut -d',' -f1`
                    input=`echo $input | cut -d',' -f2-`  
                    downloadVideo "${user_name}" "${num1}" "${videos[${current}]}"
                    num1=$((num1 + 1))
                done
                startTime=$(( startTime  + 10 ))
            fi 
        else
            echo " - There's nothing to show."
            ex="true"
        fi
    done
}

# Function to find a unique file name to record the video to. This prevents overwriting
# a previously recorded video. In the event of name colisions, the file is extended with
# the letter 'a'.
# 
# @param: user name
# @param: video type {live, broadcast, moment}
# @param: video id
# @param: extension
function findNextAvailableFileName() 
{
    local timestamp=$(date +%s)
    local user_name=$1
    local video_type=$2
    local video_id=$3
    local extension=$4
    local append="a"

    local base_video_name=${user_name}_${video_type}_${video_id}_T${timestamp}
    
    while [ -e "${base_video_name}${extension}" ]; do
        base_video_name="${base_video_name}${append}"
    done

    base_video_name="${base_video_name}.${extension}"
    echo ${base_video_name}
}


# Function: Download a video.
# @param: user name
# @param: video number (numeric order)
# @param: broadcast id
function downloadVideo()
{
    local user_name=$1
    local dirr=$1_$2
    local broadcast_id=$3

    mkdir -p "./_temp/${dirr}"
    mkdir -p "./videos/${user_name}"

    # wget --no-check-certificate -q "http://www.younow.com/php/api/younow/user" -O "./_temp/${dirr}/session.txt"
    wget --no-check-certificate -q "http://www.younow.com/php/api/broadcast/videoPath/broadcastId=${broadcast_id}" -O "./_temp/${dirr}/rtmp.txt"

    local session=`cat ./_temp/${dirr}/rtmp.txt | jq -r '.session'`
    local server=`cat  ./_temp/${dirr}/rtmp.txt | jq -r '.server'`
    local stream=`cat  ./_temp/${dirr}/rtmp.txt | jq -r '.stream'`
    local hls=`cat     ./_temp/${dirr}/rtmp.txt | jq -r '.hls'`
    
    # find a unique file name for the download
    local file_name=$(findNextAvailableFileName ${user_name} "broadcast" ${broadcast_id} "mkv")

    if $verbose ; then
        echo "--- debug download information ---"
        echo "session: $session"
        echo "  sever: $server"
        echo " stream: $stream"
        echo "    hls: $hls"
        echo "file_name: ${file_name}"
        echo "--- debug download information ---"
    fi

    # Execute the command
    if [ "$mac" == "" ] 
    then
        $terminal -x sh -c "./you_now_broadcasts.sh broadcast linux ${user_name} ${file_name} ${hls} ${server} ${stream} ${session}"
    else

        echo "cd `pwd`; ./you_now_broadcasts.sh broadcast mac ${user_name} ${file_name} ${hls} ${server} ${stream} ${session} "  > "./_temp/${file_name}.command"
        chmod +x "./_temp/${file_name}.command"
        open "./_temp/${file_name}.command"
    fi
}


function checkDependencies()
{
    if [ "$mac" == "" ]; then
        echo "Not tested. Good luck."   
        dependencies=( "rtmp" "xidel" "wget" "ffmpeg" "jq")
    else
        dependencies=( "rtmpdump" "xidel" "wget" "ffmpeg" "jq")
    fi

    for i in "${dependencies[@]}"
    do
        :
        if ! hash ${i} 2>/dev/null; then
            echo "Dependcy missing: ${i}"
            echo "Please ensure all dependencies are on the PATH before launching the application."
            echo ""
            exit 1
        fi
    done
}


##################### Program Entry Point #####################
# Set some program global variables
mac=`uname -a | grep -i darwin`

# Locations for working files and final videos
mkdir -p ./_temp
mkdir -p ./videos

# Verify all of the helper tools are available, so the script doesn't crash later.
checkDependencies

# Start the interactive menu
mainProgramLoop
echo "Thanks for using the downloader tool. Have a nice day."

# clean up all the temp files.
rm -rf ./_temp/* 2>/dev/null 
###############################################################
