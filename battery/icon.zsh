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

function battery_level_icongauge() {
  local color_green=${BATTERY_COLOR_GREEN:-%F{green}};
  local color_yellow=${BATTERY_COLOR_YELLOW:-%F{yellow}};
  local color_red=${BATTERY_COLOR_RED:-%F{red}};
  local color_reset=${BATTERY_COLOR_RESET:-%{%f%k%b%}};

  local empty_symbol=${BATTERY_GAUGE_EMPTY_SYMBOL:-''};
  local level1_symbol=${BATTERY_GAUGE_LEVEL1_SYMBOL:-''};
  local level2_symbol=${BATTERY_GAUGE_LEVEL2_SYMBOL:-''};
  local level3_symbol=${BATTERY_GAUGE_LEVEL3_SYMBOL:-''};
  local level4_symbol=${BATTERY_GAUGE_LEVEL4_SYMBOL:-''};
  local level5_symbol=${BATTERY_GAUGE_LEVEL5_SYMBOL:-''};
  local level6_symbol=${BATTERY_GAUGE_LEVEL6_SYMBOL:-''};
  local level7_symbol=${BATTERY_GAUGE_LEVEL7_SYMBOL:-''};
  local level8_symbol=${BATTERY_GAUGE_LEVEL8_SYMBOL:-''};
  local level9_symbol=${BATTERY_GAUGE_LEVEL9_SYMBOL:-''};
  local full_symbol=${BATTERY_GAUGE_FULL_SYMBOL:-''};

  local battery_remaining_percentage=$(battery_pct);

  if [[ $battery_remaining_percentage =~ [0-9]+ ]]; then
    if (( battery_remaining_percentage >= 99 )); then
      icongauge=$full_symbol
    elif (( battery_remaining_percentage >= 88 )); then
      icongauge=$level9_symbol
    elif (( battery_remaining_percentage >= 77 )); then
      icongauge=$level8_symbol
    elif (( battery_remaining_percentage >= 66 )); then
      icongauge=$level7_symbol
    elif (( battery_remaining_percentage >= 55 )); then
      icongauge=$level6_symbol
    elif (( battery_remaining_percentage >= 44 )); then
      icongauge=$level5_symbol
    elif (( battery_remaining_percentage >= 33 )); then
      icongauge=$level4_symbol
    elif (( battery_remaining_percentage >= 22 )); then
      icongauge=$level3_symbol
    elif (( battery_remaining_percentage >= 11 )); then
      icongauge=$level2_symbol
    elif (( battery_remaining_percentage >= 0 )); then
      icongauge=$level1_symbol
    else
      icongauge=$empty_symbol
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
    icongauge=${BATTERY_UNKNOWN_SYMBOL:-''};
  fi

  printf ' '${gauge_color//\%/\%\%}$icongauge${color_reset//\%/\%\%}
}
