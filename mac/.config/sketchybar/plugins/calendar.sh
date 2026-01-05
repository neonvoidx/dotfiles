#!/bin/bash

sketchybar --set $NAME icon="$(date '+%a %d. %b')" label="$(date '+%H:%M') EST $(date -u '+%H:%M') UTC"
