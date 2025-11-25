#!/bin/sh

address=$1

hyprctl keyword cursor:no_warps true
hyprctl dispatch focuswindow address:$address
hyprctl keyword cursor:no_warps false
