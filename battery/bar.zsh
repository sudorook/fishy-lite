#
# Create prompts for displaying battery levels.
#

if [[ "$OSTYPE" = darwin* ]]; then
  function battery_is_charging() {
    ioreg -rc AppleSmartBattery | command grep -q '^.*"ExternalConnected"\ =\ Yes'
  }

  function battery_pct() {
    pmset -g batt | grep -Eo "\d+%" | cut -d% -f1
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

function battery_level_gauge() {
  local gauge_slots=${BATTERY_GAUGE_SLOTS:-5};
  local green_threshold=${BATTERY_GREEN_THRESHOLD:-2};
  local yellow_threshold=${BATTERY_YELLOW_THRESHOLD:-1};
  local color_green=${BATTERY_COLOR_GREEN:-%F{green}};
  local color_yellow=${BATTERY_COLOR_YELLOW:-%F{yellow}};
  local color_red=${BATTERY_COLOR_RED:-%F{red}};
  local color_reset=${BATTERY_COLOR_RESET:-%{%f%k%b%}};

  local filled_symbol=${BATTERY_GAUGE_FILLED_SYMBOL:-'█'};
  local half_symbol=${BATTERY_GAUGE_HALF_SYMBOL:-'▓'};
  local empty_symbol=${BATTERY_GAUGE_EMPTY_SYMBOL:-'░'};

  local battery_remaining_percentage=$(battery_pct);

  if [[ $battery_remaining_percentage =~ [0-9]+ ]]; then
    local filled=$(( ( ($battery_remaining_percentage + $((100 / $gauge_slots / 2)) - 1) / $((100 / $gauge_slots)) ) ));
    local half=$(( ( ($battery_remaining_percentage + $((100 / $gauge_slots)) - 1) / $((100 / $gauge_slots)) ) - $filled ));
    local empty=$(($gauge_slots - $half - $filled));

    if [[ $filled -gt $green_threshold ]]; then local gauge_color=$color_green;
    elif [[ $(($filled + $half)) -gt $yellow_threshold ]]; then local gauge_color=$color_yellow;
    else local gauge_color=$color_red;
    fi
  else
    local filled=$gauge_slots;
    local empty=0;
    local half=0;
    filled_symbol=${BATTERY_UNKNOWN_SYMBOL:-''};
  fi

  printf ' '${gauge_color//\%/\%\%}
  [[ $filled -ne 0 ]] && printf ${filled_symbol//\%/\%\%}'%.0s' {1..$filled}
  [[ $half -eq 1 ]] && printf ${half_symbol//\%/\%\%}'%.0s' {1..$half}
  [[ $(( $filled + $half )) -lt $gauge_slots ]] && printf ${empty_symbol//\%/\%\%}'%.0s' {1..$empty}
  printf ${color_reset//\%/\%\%}
}
