#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <port> <filename>"
    exit 1
fi

IP=$(ip -4 -br addr show wlp1s0 | awk '{print $3}' | cut -d'/' -f1)
PORT=$1
OUTPUT_FILE=$2

echo "Listening on $IP:$PORT. Write to $OUTPUT_FILE..."
nc -l "$PORT" > "$OUTPUT_FILE"
echo "Received and saved to $OUTPUT_FILE"


unzip -o $OUTPUT_FILE  -d /

