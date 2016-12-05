#!/bin/sh
SAVEIFS=$IFS
IFS=$'\n'

read -p "please submit the ingest volume:	
" p1;
p=$(echo $p1 | tr -d ' ')
ingest="$p"

read -p "please submit the volume where the bags are to be written
" r1;
r=$(echo $r1 | tr -d ' ')
bags="$r"

mkdir $bags/audio
mkdir $bags/video


for d in $(find $ingest -type d -not -path '*/\.*' -name 'cpb*' -maxdepth 1 -mindepth 1); do
	guid=$(echo $d | tr / '\n' | grep -vx '^$' | tail -1)
	echo $guid
	mkdir $bags/$guid 
	mkdir $bags/$guid/master && mkdir $bags/$guid/mezz && mkdir $bags/$guid/proxy
	for f in $(find $d -type f -path '*master*'); do
		echo $f
		file=$(echo $f | tr / '\n' | grep -vx '^$' | tail -1)
		echo $file
		mediainfo -f --Language=Raw --Output=XML $f > $bags/$guid/master/${file}.mediainfo.xml
	done
	for m in $(find $d -type f -path '*mezz*'); do
		echo $m
		mezz=$(echo $m | tr / '\n' | grep -vx '^$' | tail -1)
		mediainfo -f --Language=Raw --Output=XML $m > $bags/$guid/mezz/${mezz}.mediainfo.xml
	done
	for p in $(find $d -type f -path '*proxy*'); do
		echo $p
		proxy=$(echo $p | tr / '\n' | grep -vx '^$' | tail -1)
		mediainfo -f --Language=Raw --Output=XML $p > $bags/$guid/proxy/${proxy}.mediainfo.xml
	done
	
	mediainfo=$(find $bags/$guid/proxy/ -type f -name '*mediainfo*')
	if grep 'Video' $mediainfo; then
		mv $bags/$guid $bags/video/$guid
		/Users/$USER/bagit-python/bagit.py $bags/video/$guid
		cd $bags/video
		zip -r ${guid}-sparse.zip $guid
		find . -type d -maxdepth 1 -mindepth 1 -not -name "*.zip" -exec rm -R {} \;	
		cd $bags
	else
		mv $bags/$guid $bags/audio/$guid
		/Users/$USER/bagit-python/bagit.py $bags/audio/$guid
		cd $bags/audio
		zip -r ${guid}-sparse.zip $guid
		find . -type d -maxdepth 1 -mindepth 1 -not -name "*.zip" -exec rm -R {} \;	
	fi
done

IFS=$SAVEIFS
