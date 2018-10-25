#!/bin/bash

###
# USAGE:
# ./videoDownloader.sh https://www.aparat.com/<CHANEL_NAME> #will download all the chanel's video with default quality (720p)
# ./videoDownloader.sh https://www.aparat.com/<CHANEL_NAME> 360 #will download all the chanel's video with specified quality
# ./videoDownloader.sh <PAGES_LINK_LIST_FILE> #will download all the listed video links with default quality (720p)
# ./videoDownloader.sh <PAGES_LINK_LIST_FILE> 144 #will download all the listed video links with specified quality
###

tempHtmlFile="/tmp/aparatPage.html"
videoLinksFile="videoLinks"
downloadLinksFile="downloadReadyLinks"
videoQuality="720"

if [[ -f "$downloadLinksFile" ]]; then
    rm -f ${downloadLinksFile}
fi

if [[ -z "$1" ]]; then
    echo "Enter a chanel address(including \"https://\"), or the links file name"
    exit
fi

if [[ ! -z "$2" ]]; then
    videoQuality=$2
fi

if [[ $1 == https* ]]; then
    wget -O ${tempHtmlFile} $1 >/dev/null 2>&1
    < ${tempHtmlFile} tr -d '\n' | grep -oP '(?<=<h2 class="video-item__title"> ).*?(?= </h2>)' | grep -o "<a href=\"https://www.aparat.com/v/.*</a>" | grep -o "'https://www\.aparat.com/v/.*'" | awk '!x[$0]++' | cut -d "'" -f2 > ${videoLinksFile}
    chanelName=`grep -o "<title>.*</title>" ${tempHtmlFile} | sed 's/\(<title>\|<\/title>\)//g' | sed 's/\ /_/g'`
else
    videoLinksFile=$1
    chanelName="$(echo $1 | sed 's/\ /_/g')"_videos
fi

index=1
if [[ -f "$videoLinksFile" ]]; then
    while IFS='' read -r line || [[ -n "$line" ]]; do
        echo
        echo "link #$index($line) is processing..."

        wget -O ${tempHtmlFile} ${line} >/dev/null 2>&1

        LINK=`grep -o "<a href=\"https:\/\/.*-${videoQuality}p__.*\.mp4" ${tempHtmlFile} | grep -o "https.*$"`
        if [[ -z "$LINK" ]]; then
            echo -e "\e[31mSomething went wrong! probably $line does not have any \e[4m${videoQuality}p\e[0m \e[31mversion\e[0m"
            continue
        fi
        
        TITLE=`grep -o "<title>.*</title>" ${tempHtmlFile} | sed 's/\(<title>\|<\/title>\)//g'`
        echo -e "$LINK\n        out=$TITLE.mp4" >> ${downloadLinksFile}
        echo -e "\e[32m\"${TITLE}\" download link added successfully!\e[0m"

        index=$(( $index + 1 ))
    done < "$videoLinksFile"
else
    echo -e "\e[31m${videoLinksFile} file not found!\e[0m"
    exit
fi

echo

rm -f ${videoLinksFile}
rm -f ${tempHtmlFile}

aria2c -d${chanelName} -c -x16 -s16 -k 1M -i${downloadLinksFile} -j1

rm -f ${downloadLinksFile}