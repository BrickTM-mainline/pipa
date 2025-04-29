#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <file> <ip> <port>"
    exit 1
fi

FILE=$1
IP=$2
PORT=$3

if [ ! -f "$FILE" ]; then
    echo "Error: $FILE doesn't exist"
    exit 1
fi

echo "Sending $FILE to $IP:$PORT..."
nc -N "$IP" "$PORT" < "$FILE"
echo "Sent"


