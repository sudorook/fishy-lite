#
# Create prompts for displaying battery levels.
#

function battery_is_charging() {
  ! [[ $(acpi 2>/dev/null | sed -n 1p | grep -c '^Battery.*Discharging') -gt 0 ]]
}

function battery_charging() {
  local color_yellow=${BATTERY_COLOR_YELLOW:-%F{yellow}};
  local charging_color=${BATTERY_CHARGING_COLOR:-$color_yellow};
  local charging_symbol=${BATTERY_CHARGING_SYMBOL:-'⚡'};

  local charging='' && battery_is_charging && charging=${charging_symbol};

  printf ${charging_color//\%/\%\%}$charging${color_reset//\%/\%\%}
}

function battery_pct() {
  if (( $+commands[acpi] )) ; then
    echo "$(acpi 2>/dev/null | sed -n 1p | cut -f2 -d ',' | tr -cd '[:digit:]')"
  fi
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
