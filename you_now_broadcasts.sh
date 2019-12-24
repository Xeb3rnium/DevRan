#!/bin/bash

#
# http://redsymbol.net/articles/bash-exit-traps/
# 
# Define a trap function, to intercept cntl-c and perform clean up operations
#
function finish() {
    echo "Should the downloaded broadcast be deleted? (D)" 
    read delete_file
    if [ "${delete_file}" == "D" ] || [ "${delete_file}" == "d" ]; then
        rm "${file_location}"
    fi
}
trap finish EXIT


# Perform the work of actually downloading a live broadcast.
function downloadLive()
{
    platform=$1
    user_name=$2
    file_name=$3
    host=$4
    app=$5
    stream=$6

    file_location="./videos/${user_name}/${file_name}"

    if [ "${platform}" == "linux" ]
    then
        rtmp -v -o "${file_location}" -r "rtmp://${host}${app}/${stream}";
    else
        cd `pwd` ; 
        rtmpdump -v -o "${file_location}" -r "rtmp://${host}${app}/${stream}"
    fi
}


# Perform the work of actually downloading a user's past broadcast.
function downloadBroadcast()
{
    platform=$1
    user_name=$2
    file_name=$3
    hls=$4
    server=$5
    stream=$6
    session=$7

    file_location="./videos/${user_name}/${file_name}"

    if [ "${platform}" == "mac" ]; then
        echo "mac"
        if [[ "$hls" != "" ]]; then
            cd `pwd`; 
            ffmpeg -i "$hls"  -c copy "$file_location" ; 
        else
            cd `pwd`; 
            rtmpdump -v -o "$file_location" -r "$server$stream?sessionId=$session" -p "http://www.younow.com/"; 
        fi

    elif [ "${platform}" == "linux" ]; then
        echo "linux"

        $rtmp -v -o "$file_location" -r "$server$stream?sessionId=$session" -p "http://www.younow.com/"; 
        bash; 
        exit
    else
        echo "Unknown or non-supported platform"
    fi
}

if [ "$1" == "broadcast" ]; then
    downloadBroadcast $2 $3 $4 $5 $6 $7 $8

elif [ "$1" == "live" ]; then
    downloadLive $2 $3 $4 $5 $6 $7
fi


