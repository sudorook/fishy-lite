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
