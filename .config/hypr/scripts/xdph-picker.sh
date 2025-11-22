#!/bin/bash

declare -A window_map
menu_items=()
parse_monitors() {
  while IFS= read -r monitor; do
    [[ -z "$monitor" ]] && continue
    menu_items+=("[Screen] $monitor")
  done < <(hyprctl monitors -j | jq -r '.[].name')
}
parse_region() {
  menu_items+=("[Selection] Select area")
}
parse_windows() {
  local rolling="$1"
  local id class title entry
  while [[ -n "$rolling" ]]; do
    entry="${rolling%%\[HE>]*}"
    [[ -z "$entry" ]] && break
    id="${entry%%[HC>]*}"
    local rest="${entry#*"[HC>]"}"
    class="${rest%%[HT>]*}"
    title="${rest#*"[HT>]"}"
    [[ -n "$title" ]] && menu_items+=("[Window] $title") && window_map["$title"]="$id"
    rolling="${rolling#*"[HE>]"}"
    rolling="${rolling#*"[HA>]"}"
  done
}
show_menu() {
  local selection
  selection=$(printf "%s\n" "${menu_items[@]}" | walker -d -n -H)
  echo "$selection"
}
handle_selection() {
  local selection="$1"
  if [[ $selection == "[Screen]"* ]]; then
    monitor="${selection#"[Screen] "}"
    echo "[SELECTION]/screen:$monitor"
  elif [[ $selection == "[Selection]"* ]]; then
    region=$(slurp -f "%o@%x,%y,%w,%h")
    echo "[SELECTION]/region:$region"
  elif [[ $selection == "[Window]"* ]]; then
    title="${selection#"[Window] "}"
    echo "[SELECTION]/window:${window_map["$title"]}"
  else
    echo "[ERROR] Unknown selection: $selection" >&2
  fi
}
parse_monitors
parse_region
parse_windows "$XDPH_WINDOW_SHARING_LIST"
selection=$(show_menu)
handle_selection "$selection"

