#!/bin/sh
set -eu

plugin_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/plugins"
mkdir -p "$plugin_dir"
tmp=""
trap 'if [ -n "$tmp" ]; then rm -f "$tmp"; fi' EXIT HUP INT TERM

install_plugin() {
  name="$1" url="$2" expected="$3"
  destination="$plugin_dir/$name.wasm"
  if [ -f "$destination" ] && [ "$(shasum -a 256 "$destination" | cut -d ' ' -f 1)" = "$expected" ]; then
    return
  fi
  tmp="$(mktemp "$plugin_dir/.download.XXXXXX")"
  curl --fail --location --silent --show-error "$url" -o "$tmp"
  printf '%s  %s\n' "$expected" "$tmp" | shasum -a 256 --check --status
  chmod 644 "$tmp"
  mv "$tmp" "$destination"
  tmp=""
}

install_plugin autolock \
  https://github.com/fresh2dev/zellij-autolock/releases/download/0.3.0/zellij-autolock.wasm \
  217e071b785981efda480b279d1a98e86da21971cf0bc7edd45f8b7c6359ab02
install_plugin zjstatus \
  https://github.com/dj95/zjstatus/releases/download/v0.25.0/zjstatus.wasm \
  282ceab219e56e1908c9fac33907241fe6c3e1ef7d85faab3e5f438cef87b8fe
install_plugin zellij_forgot \
  https://github.com/karimould/zellij-forgot/releases/download/0.4.2/zellij_forgot.wasm \
  31194145519dbdc128685b456f970374378fa19fc9da742fbe4a321bace449db
install_plugin zextract \
  https://github.com/codingfragments/zellij-zextract/releases/download/v0.4.0/zextract.wasm \
  2e79de6a71002b621c068ea4232bb3cae3edf676ff9928cbd3e002db67a1fc10
install_plugin zjstatus-hints \
  https://github.com/b0o/zjstatus-hints/releases/download/v0.1.4/zjstatus-hints.wasm \
  936c55e9025c0edbd43421383efc151bdfdc78e924f966bfe9e7c682bec8719d

# zjstatus-hints runs hidden and cannot present a selectable approval prompt.
case "$(uname -s)" in
  Darwin) permission_cache="$HOME/Library/Caches/org.Zellij-Contributors.Zellij/permissions.kdl" ;;
  *) permission_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zellij/permissions.kdl" ;;
esac
hints_path="${XDG_CONFIG_HOME:-$HOME/.config}/zellij/plugins/zjstatus-hints.wasm"
if ! grep -Fq "\"$hints_path\" {" "$permission_cache" 2>/dev/null; then
  mkdir -p "$(dirname "$permission_cache")"
  cat >> "$permission_cache" <<EOF
"$hints_path" {
    ReadApplicationState
    MessageAndLaunchOtherPlugins
}
EOF
fi
