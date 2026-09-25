#!/bin/bash

# Workspace state is rendered centrally by aerospace_spaces_update.sh.
if [ "$SENDER" = "mouse.clicked" ]; then
  aerospace workspace "$1"
fi
