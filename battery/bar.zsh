# SPDX-FileCopyrightText: 2018 - 2022 sudorook <daemon@nullcodon.com>
#
# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-License-Identifier: MIT
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program. If not, see <https://www.gnu.org/licenses/>.

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
elif [[ "$OSTYPE" = freebsd* ]]; then
  function battery_is_charging() {
    [[ $(sysctl -n hw.acpi.battery.state) -eq 2 ]]
  }
  function battery_pct() {
    if (( $+commands[sysctl] )); then
      sysctl -n hw.acpi.battery.life
    fi
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
  local twothird_symbol=${BATTERY_GAUGE_FILLED_SYMBOL:-'▓'};
  local onethird_symbol=${BATTERY_GAUGE_FILLED_SYMBOL:-'▒'};
  local empty_symbol=${BATTERY_GAUGE_EMPTY_SYMBOL:-'░'};

  local battery_remaining_percentage=$(battery_pct);
  local filled=${gauge_slots}
  local twothird=0
  local onethird=0
  local half=0
  local empty=0
  local gauge_color

  if [[ $battery_remaining_percentage =~ [0-9]+ ]]; then
    filled=$(( (battery_remaining_percentage*3) / (300/gauge_slots) ))
    twothird=$(( (battery_remaining_percentage*3 - 300*filled/gauge_slots) > (2*100/gauge_slots) ))
    onethird=$(( (battery_remaining_percentage*3 - 300*filled/gauge_slots > (100/gauge_slots)) ^^ twothird ))
    empty=$((gauge_slots - twothird | onethird - filled));

    if [[ $filled -gt $green_threshold ]]; then
      gauge_color=$color_green;
    elif [[ $((filled + twothird | onethird > yellow_threshold)) ]]; then
      gauge_color=$color_yellow;
    else
      gauge_color=$color_red;
    fi
  else
    filled_symbol=${BATTERY_UNKNOWN_SYMBOL:-''};
  fi

  printf ' '${gauge_color//\%/\%\%}
  [[ $filled -ne 0 ]] && printf ${filled_symbol//\%/\%\%}'%.0s' {1..$filled}
  [[ $twothird -eq 1 ]] && printf ${twothird_symbol//\%/\%\%}'%.0s' {1..$twothird}
  [[ $onethird -eq 1 ]] && printf ${onethird_symbol//\%/\%\%}'%.0s' {1..$onethird}
  [[ $(( $filled + $onethird + $twothird )) -lt $gauge_slots ]] && printf ${empty_symbol//\%/\%\%}'%.0s' {1..$empty}
  printf ${color_reset//\%/\%\%}
}
