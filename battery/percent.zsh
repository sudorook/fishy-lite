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

function battery_pct_prompt() {
  local b=$(battery_pct)
  if [[ $b =~ [0-9]+ ]]; then
    if (( b > 50 )); then
      color='green'
    elif (( b > 20 )); then
      color='yellow'
    else
      color='red'
    fi
    echo " %{$fg[$color]%}$(battery_pct)%%%{$reset_color%}"
  fi
}
