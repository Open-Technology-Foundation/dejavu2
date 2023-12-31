#!/bin/bash

int_list() {
  # Return an ordered list of integers.

  [[ -z "${1:-}" ]] && {
    echo >&2 "${FUNCNAME[0]}: Error: input_string empty."
    return 1
  }

  local -- input_string="$1"
  local -i minVal=${2:-0}
  local -i maxVal=${3:-4294967295}
  local -i revSort=${4:-0}
  local -a range_list=() numlist=()
  local -- string numC
  local -i i stnum=0 endnum=0

  # Convert input_string to a comma-separated string 
  string=$(echo "$input_string" | tr ' ' ',' | sed 's/,,/,/g' | sed 's/^,//' | tr '[:upper:]' '[:lower:]')

  # Split the string into a list of numbers 
  IFS=',' read -ra numlist <<< "$string"
  for numC in "${numlist[@]}"; do
    # Skip empty elements 
    [[ -z $numC ]] && continue
    # Handle 'all' or '-' keyword
    [[ $numC == 'all' || $numC == '-' ]] && {
      range_list+=( $(printf '%s ' $(eval echo {$minVal..$maxVal})) )
      continue
    }
    [[ $numC == '--' ]] && { range_list+=($maxVal); continue; }
    # Handle range notation
    if [[ "${numC:0:2}" == '--' ]]; then
      # --2 --1 --42
      [[ -z "${numC:2}" ]] \
        && stnum=$maxVal \
        || stnum=$((maxVal - 0${numC:2} + 1))
      # Check if the number is within the specified limits
      (( stnum >= minVal && stnum <= maxVal )) \
        && range_list+=($stnum)
    elif [[ $numC == *-* ]]; then
      stnum=${numC%-*}; endnum=${numC#*-}
      # Handle empty start or end values 
      ((stnum))  || stnum=$minVal; ((endnum)) || endnum=$maxVal
      # Convert start and end values to integers 
      stnum=$((stnum)); endnum=$((endnum))
      # Check if the range is within the specified limits 
      if (( stnum < minVal || endnum > maxVal )); then
        echo >&2 "${FUNCNAME[0]}: error: out of range $stnum-$endnum"
        continue
      fi
      # Add the range of numbers to the list 
      for (( i=stnum; i<=endnum; i++ )); do
        range_list+=($i)
      done
    else
      # Handle single numbers 
      stnum=$((numC))
      # Check if the number is within the specified limits 
      (( stnum < minVal || stnum > maxVal )) && continue
      # Add the number to the list 
      range_list+=($stnum)
    fi
  done

  # Check if the range_list is empty 
  ((${#range_list[@]})) || return 1

  # Remove duplicates and sort the list 
  range_list=($(echo "${range_list[@]}" | tr '
    ' '\n' | sort -n | uniq))

  # Reverse sort if revSort is true 
  if ((revSort)); then
    tac < <(printf '%s\n' "${range_list[@]}")
  else
    # Print the range_list 
    echo "${range_list[@]}"
  fi  
}
declare -fx 'int_list'

#fin
