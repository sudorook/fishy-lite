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
    [[ -f "/sys/class/power_supply/BAT0/capacity" ]] && \
      cat "/sys/class/power_supply/BAT0/capacity"
  }
else
  function battery_is_charging() {}
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

function battery_level_blockgauge() {
  local color_green=${BATTERY_COLOR_GREEN:-%F{green}};
  local color_yellow=${BATTERY_COLOR_YELLOW:-%F{yellow}};
  local color_red=${BATTERY_COLOR_RED:-%F{red}};
  local color_reset=${BATTERY_COLOR_RESET:-%{%f%k%b%}};

  local filled_symbol=${BATTERY_GAUGE_FILLED_SYMBOL:-'█'};
  local seveneighths_symbol=${BATTERY_GAUGE_SEVENEIGHTHS_SYMBOL:-'▇'};
  local threefourths_symbol=${BATTERY_GAUGE_THREEFOURTHS_SYMBOL:-'▆'};
  local fiveeighths_symbol=${BATTERY_GAUGE_FIVEEIGHTHS_SYMBOL:-'▅'};
  local half_symbol=${BATTERY_GAUGE_HALF_SYMBOL:-'▄'};
  local threeeighths_symbol=${BATTERY_GAUGE_THREEEIGHTHS_SYMBOL:-'▃'};
  local onefourth_symbol=${BATTERY_GAUGE_ONEFOURTH_SYMBOL:-'▂'};
  local oneeighth_symbol=${BATTERY_GAUGE_ONEEIGHTH_SYMBOL:-'▁'};
  local empty_symbol=${BATTERY_GAUGE_EMPTY_SYMBOL:-'_'};

  local battery_remaining_percentage=$(battery_pct);

  if [[ $battery_remaining_percentage =~ [0-9]+ ]]; then
    if (( $battery_remaining_percentage >= 93.75 )); then
      blockgauge=$filled_symbol
    elif (( $battery_remaining_percentage >= 81.25 )); then
      blockgauge=$seveneighths_symbol
    elif (( $battery_remaining_percentage >= 68.75 )); then
      blockgauge=$threefourths_symbol
    elif (( $battery_remaining_percentage >= 56.25 )); then
      blockgauge=$fiveeighths_symbol
    elif (( $battery_remaining_percentage >= 43.75 )); then
      blockgauge=$half_symbol
    elif (( $battery_remaining_percentage >= 31.25 )); then
      blockgauge=$threeeighths_symbol
    elif (( $battery_remaining_percentage >= 18.75 )); then
      blockgauge=$onefourth_symbol
    elif (( $battery_remaining_percentage >= 6.25 )); then
      blockgauge=$oneeighth_symbol
    else
      blockgauge=$empty_symbol
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
    blockgauge=${BATTERY_UNKNOWN_SYMBOL:-''};
  fi

  printf ' '${gauge_color//\%/\%\%}$blockgauge${color_reset//\%/\%\%}
}
