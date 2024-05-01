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
    if (( battery_remaining_percentage >= 88 )); then
      circlegauge=$filled_symbol
    elif (( battery_remaining_percentage >= 63 )); then
      circlegauge=$threefourths_symbol
    elif (( battery_remaining_percentage >= 38 )); then
      circlegauge=$half_symbol
    elif (( battery_remaining_percentage >= 13 )); then
      circlegauge=$onefourth_symbol
    else
      circlegauge=$empty_symbol
    fi
    if (( battery_remaining_percentage >= 50 )); then
      gauge_color=$color_green
    elif (( battery_remaining_percentage >= 20 )); then
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
