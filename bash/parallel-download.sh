#!/bin/bash 

content_length=`curl -I $1 | grep Content-Length | awk '{print $NF}' | tr -d '\r'`
output_file=`echo $1 | awk -F/ '{print $NF}'`
echo "content-length: $content_length"
start=0
last=$start
chunks=30
step=$(($content_length / $chunks))
counter=1
TMP_DIR=/tmp/parallecl-curl

if [ ! -e $TMP_DIR ]; then
    mkdir $TMP_DIR
fi

while [ $last -lt $content_length ]; do
    next=$(($last + $step))
    if [ $next -gt $content_length ]; then
        next=$content_length
    fi
    curl --retry 3 -svo $TMP_DIR/${output_file}.$counter -r $last-$next $1&
    last=$(($next + 1))
    counter=$(($counter + 1))
done

# Wait for all downloads to finish before reassembling the file
wait

# Reassemble our file
if [ -e $output_file ]; then
    echo "output file $outpuf_file exists! CLOBBERING $output_file"
    rm $output_file
fi
for i in `seq 1 \`ls $TMP_DIR/${output_file}*.[0-9]*| wc -l\``; do
    cat $TMP_DIR/${output_file}.$i >> $output_file;
done

