status=$(nmcli -g "name,active" connection | grep proton | awk -F: '{print $2}')

if [ "$status" = "yes" ]; then
  echo "On "
else
  echo "Off "
fi
