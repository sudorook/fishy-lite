#
# Create prompts for displaying battery levels.
#

if [[ "$OSTYPE" = darwin* ]] ; then
  function battery_is_charging() {
    [[ $(ioreg -rc "AppleSmartBattery"| grep '^.*"IsCharging"\ =\ ' | sed -e 's/^.*"IsCharging"\ =\ //') == "Yes" ]]
  }

  function battery_pct() {
    local smart_battery_status="$(ioreg -rc "AppleSmartBattery")"
    typeset -F maxcapacity=$(echo $smart_battery_status | grep '^.*"MaxCapacity"\ =\ ' | sed -e 's/^.*"MaxCapacity"\ =\ //')
    typeset -F currentcapacity=$(echo $smart_battery_status | grep '^.*"CurrentCapacity"\ =\ ' | sed -e 's/^.*CurrentCapacity"\ =\ //')
    integer i=$(((currentcapacity/maxcapacity) * 100))
    echo $i
  }
elif [[ "$OSTYPE" = linux* ]] ; then
  function battery_is_charging() {
    ! [[ $(acpi 2>/dev/null | sed -n 1p | grep -c '^Battery.*Discharging') -gt 0 ]]
  }

  function battery_pct() {
    if (( $+commands[acpi] )) ; then
      echo "$(acpi 2>/dev/null | sed -n 1p | cut -f2 -d ',' | tr -cd '[:digit:]')"
    fi
  }
else
  function battery_is_charging() {}
  function battery_pct() {}
fi

function battery_charging() {
  local color_yellow=${BATTERY_COLOR_YELLOW:-%F{yellow}};
  local charging_color=${BATTERY_CHARGING_COLOR:-$color_yellow};
  local charging_symbol=${BATTERY_CHARGING_SYMBOL:-'⚡'};

  local charging='' && battery_is_charging && charging=${charging_symbol};

  printf ${charging_color//\%/\%\%}$charging${color_reset//\%/\%\%}
}

function battery_level_circlegauge() {
  local color_green=${BATTERY_COLOR_GREEN:-%F{green}};
  local color_yellow=${BATTERY_COLOR_YELLOW:-%F{yellow}};
  local color_red=${BATTERY_COLOR_RED:-%F{red}};
  local color_reset=${BATTERY_COLOR_RESET:-%{%f%k%b%}};
  local filled_symbol=${BATTERY_GAUGE_FILLED_SYMBOL:-'●'};
  local threefourths_symbol=${BATTERY_GAUGE_THREEFOURTHS_SYMBOL:-'◕'};
  local half_symbol=${BATTERY_GAUGE_HALF_SYMBOL:-'◑'};
  local onefourth_symbol=${BATTERY_GAUGE_ONEFOURTH_SYMBOL:-'◔'};
  local empty_symbol=${BATTERY_GAUGE_EMPTY_SYMBOL:-'○'};

  local battery_remaining_percentage=$(battery_pct);

  if [[ $battery_remaining_percentage =~ [0-9]+ ]]; then
    if (( $battery_remaining_percentage >= 88 )); then
      circlegauge=$filled_symbol
    elif (( $battery_remaining_percentage >= 63 )); then
      circlegauge=$threefourths_symbol
    elif (( $battery_remaining_percentage >= 38 )); then
      circlegauge=$half_symbol
    elif (( $battery_remaining_percentage >= 13 )); then
      circlegauge=$onefourth_symbol
    else
      circlegauge=$empty_symbol
    fi
    if (( $battery_remaining_percentage >= 50 )); then
      gauge_color=$color_green
    elif (( $battery_remaining_percentage >= 20 )); then
      gauge_color=$color_yellow
    else
      gauge_color=$color_red
    fi
  else
    gauge_color=$color_green
    circlegauge=${BATTERY_UNKNOWN_SYMBOL:-''};
  fi

  printf ' '${gauge_color//\%/\%\%}$circlegauge${color_reset//\%/\%\%}
}
