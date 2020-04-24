#
# Create prompts for displaying battery levels.
#

if [[ "$OSTYPE" = darwin* ]]; then
  function battery_is_charging() {
    ioreg -rc AppleSmartBattery | command grep -q '^.*"ExternalConnected"\ =\ Yes'
  }

  function battery_pct() {
    local battery_status="$(ioreg -rc AppleSmartBattery)"
    local -i capacity=$(sed -n -e '/MaxCapacity/s/^.*"MaxCapacity"\ =\ //p' <<< $battery_status)
    local -i current=$(sed -n -e '/CurrentCapacity/s/^.*"CurrentCapacity"\ =\ //p' <<< $battery_status)
    echo $(( current * 100 / capacity ))
  }
elif [[ "$OSTYPE" = linux* ]]; then
  function battery_is_charging() {
    ! acpi 2>/dev/null | command grep -v "rate information unavailable" | command grep -q '^Battery.*Discharging'
  }

  function battery_pct() {
    [[ -f "/sys/class/power_supply/BAT0/capacity" ]] && \
      cat "/sys/class/power_supply/BAT0/capacity"
  }
else
  function battery_is_charging() { false }
  function battery_pct() {}
fi

function battery_charging() {
  local color_yellow=${BATTERY_COLOR_YELLOW:-%F{yellow}};
  local color_reset=${BATTERY_COLOR_RESET:-%{%f%k%b%}};
  local charging_color=${BATTERY_CHARGING_COLOR:-$color_yellow};
  local charging_symbol=${BATTERY_CHARGING_SYMBOL:-' '};

  local charging='' && battery_is_charging && [[ $(battery_pct) =~ [0-9]+ ]] && charging=${charging_symbol};

  printf ${charging_color//\%/\%\%}$charging${color_reset//\%/\%\%}
}

function battery_pct_prompt() {
  local b=$(battery_pct)
  if [[ $b =~ [0-9]+ ]]; then
    if [ $b -gt 50 ] ; then
      color='green'
    elif [ $b -gt 20 ] ; then
      color='yellow'
    else
      color='red'
    fi
    echo " %{$fg[$color]%}$(battery_pct)%%%{$reset_color%}"
  else
    echo "∞"
  fi
}
