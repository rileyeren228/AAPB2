#!/bin/sh
SAVEIFS=$IFS
IFS=$'\n'

read -p "please submit the volume to be sorted	
" s1;
SIP=$(echo $s1 | tr -d ' ')

read -p "please submit the folder where the files are to be organized
" r1;
ingest=$(echo $r1 | tr -d ' ')

read -p "please submit the volume where the bags are to be written
" b1;
bags=$(echo $b1 | tr -d ' ')

for f in $(find $SIP -type f \( -not -path '*/\.*' ! -name '*.md5' -name 'cpb*' \)); do
	fb=$(basename $f)
	guidp=${fb%.*.*}
	mkdir $ingest/$guidp 
	mkdir $ingest/$guidp/master && mkdir $ingest/$guidp/mezz && mkdir $ingest/$guidp/proxy
done

for master in $(find $SIP -type f -name "*.mxf"); do
	fb=$(basename $master)
	guidp=${fb%.*.mxf}
	fmas=$(find $SIP -type f -name "*.mxf" -name "$guidp*") 
	mv $fmas $ingest/$guidp/master
done
for mezz in $(find $SIP -type f -name "*.mov"); do
	fb=$(basename $mezz)
	guidp=${fb%.*.mov}
	fmez=$(find $SIP -type f -name "*.mov" -name "$guidp*") 
	mv $fmez $ingest/$guidp/mezz
done
for proxy in $(find $SIP -type f -name "*.mp4"); do
	fb=$(basename $proxy)
	guidp=${fb%.*.mp4}
	fp=$(find $SIP -type f -name "*.mp4" -name "$guidp*")
	mv $fp $ingest/$guidp/proxy
done		

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
