#!/bin/bash

windowid=$(niri msg -j windows | jq ".[] | select(.app_id==\"$*\") | .id")
niri msg action focus-window --id "$windowid"
