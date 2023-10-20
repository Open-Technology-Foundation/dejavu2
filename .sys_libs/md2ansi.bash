#!/bin/bash
#shellcheck disable=SC2034
set -e
declare -- _ent_0=$(readlink -fn -- "$0") || _ent_0=''
declare -- PRG=${_ent_0##*/}
declare -- PRGDIR=${_ent_0%/*}
declare -- version='0.4.20'

md2ansi() {
  # ANSI Colour Palette
  local -- \
    CODE_BLOCK='\x1b[90m' \
    HORIZONTAL_RULE='\x1b[36m' \
    BLOCKQUOTE='\x1b[35m' \
    ITALICS='\x1b[34m' \
    BOLD='\x1b[31;1m' \
    STRIKETHROUGH='\x1b[2m' \
    INLINE_CODE='\x1b[97m' \
    LIST='\x1b[36m' \
    H1='\x1b[31;1m' \
    H2='\x1b[32;1m' \
    H3='\x1b[33;1m' \
    H4='\x1b[33m' \
    H5='\x1b[34;1m' \
    H6='\x1b[34m' \
    RESET='\x1b[0m'
  local -- line
  while IFS= read -r line; do
    # Check for code block markers
    if [[ "${line:0:3}" == "\`\`\`" ]]; then
      echo -e "${CODE_BLOCK}\`\`\`${line:3}"
      while IFS= read -r line; do
        [[ "${line:0:3}" == "\`\`\`" ]] && break
        echo -e "    ${CODE_BLOCK}${line}"
      done
      echo -e "${CODE_BLOCK}\`\`\`${RESET}"
      continue
    fi

    # Tables
    if [[ $line == "|"* ]]; then
      local -a _cols=() table_row=()
      local -ai _max_widths=()
      local -i _cols_n=0 _i
      local -- _col _row _lineoff=''
      while [[ $line == "|"* ]]; do
        # Remove starting and ending '|', and split the line into columns
        IFS='|' read -ra _cols <<< "${line:1}"
        ((${#_cols[@]})) \
          && [[ "${_cols[@]:1:${#_cols[@]}-1}" == '|' ]] \
          && _cols=("${_cols[@]:1:${#_cols[@]}-1}")
        ((_cols_n)) || _cols_n=${#_cols[@]}
        # Remove leading and trailing spaces from each column
        for _i in "${!_cols[@]}"; do
          _cols[$_i]="$(echo -e "${_cols[$_i]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        done
        # Determine the max width for each column
        for _i in "${!_cols[@]}"; do
          [[ ! -v _max_widths[$_i] ]] && _max_widths[$_i]=0
          ((${#_cols[$_i]} > ${_max_widths[$_i]})) \
            && _max_widths[$_i]=${#_cols[$_i]}
        done
        # Add the columns to table row
        _row='|'
        for((_i=0; _i<_cols_n; _i++)); do
          printf -v _col " %-${_max_widths[$_i]}s |" "${_cols[$_i]}"
          [[ ${_col:0:4} == ' ---' ]] && _col="${_col// /-}"
          _row+="$_col"
        done
        [[ ${_row:0:4} == '|---' && -z "$_lineoff" ]] \
          && { _row="${_row//|/+}"; _lineoff="$_row" ; }
        table_row+=( "$_row" )
        IFS= read -r line
      done
      [[ -n $_lineoff ]] && printf '%s\n' "$_lineoff"
      printf '%s\n' "${table_row[@]}"
      [[ -n $_lineoff ]] && printf '%s\n' "$_lineoff" ""
      unset _cols table_row _max_widths _cols_n _i _col _row _lineoff
      continue
    fi

    # Horizontal Rules
    if [[ ${line:0:3} == '---' ||  ${line:0:3} == '==='  ||  ${line:0:3} == '___' ]]; then
      echo -e "\r$(head -c "$((${COLUMNS:-78} - 1))" < /dev/zero | tr '\0' "${line:0:1}")"
      continue
    fi

    # Blockquotes
    if [[ "$line" =~ ^\> ]]; then
      echo "$line" | sed -E "s/^> (.*)/  ${BLOCKQUOTE}> \1${RESET}/"
      continue
    fi

    # Italics and Bold
    line=$(echo "$line" | sed -E "s/\*\*(.*?)\*\*/${BOLD}\1${RESET}/g")
    line=$(echo "$line" | sed -E "s/\*(.*?)\*/${ITALICS}\1${RESET}/g")

    # Strikethrough
    line=$(echo "$line" | sed -E "s/\~\~(.*?)\~\~/${STRIKETHROUGH}\1${RESET}/g")

    # Inline Code
    line=$(echo "$line" | sed -E "s/\`(.*?)\`/${INLINE_CODE}\1${RESET}/g")

    # Lists
    line=$(echo "$line" | sed -E "s/^[ ]*\* (.*)/    ${LIST}* \1${RESET}/")
    line=$(echo "$line" | sed -E "s/^[ ]*\- (.*)/    ${LIST}- \1${RESET}/")
    if [[ "$line" =~ ^[[:space:]]*[*-] ]]; then
      echo -e "$line"
      continue
    fi

    # Headers
    line=$(echo "$line" | sed -E "s/^###### (.*)/${H6}\1${RESET}/")
    line=$(echo "$line" | sed -E "s/^##### (.*)/${H5}\1${RESET}/")
    line=$(echo "$line" | sed -E "s/^#### (.*)/${H4}\1${RESET}/")
    line=$(echo "$line" | sed -E "s/^### (.*)/${H3}\1${RESET}/")
    line=$(echo "$line" | sed -E "s/^## (.*)/${H2}\1${RESET}/")
    line=$(echo "$line" | sed -E "s/^# (.*)/${H1}\1${RESET}/")

    echo -e "$line"  | fmt -w ${COLUMNS:-78}
  done
}

# In script.sh
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
_main() {
  usage() {
  cat <<EOT
Script  : $PRG vs $version
Desc    : Print formatted ANSI output to terminal from Markdown file.md.
Synopsis: $PRG [file.md [...]] [< md_input_stream]
Examples: $PRG < README.md
        : $PRG < *.md
        : $PRG file1.md
        : $PRG file1.md file2.md file3.md <file4.md
EOT
  }
  local -a args=()
  while(($#)); do case "$1" in
    -V|--version) echo "$PRG $version"; return 0 ;;
    -h|--help)    usage; return 0 ;;
    -?|--*)       >&2 echo "$PRG: Invalid option '$1'"; exit 22 ;;
    *)            args+=( "$1" ) ;;
  esac; shift; done
  if ((${#args[@]})); then
    local -- mdfile md=''
    for mdfile in "${args[@]}"; do
      [[ -f "$mdfile" ]] || { >&2 echo "$PRG: File '$mdfile' not found"; exit 1 ; }
      md+=$(cat -s -- "$mdfile"; echo)
    done
    md2ansi <<<"$md"
  fi
  [[ ! -t 0 ]] && md2ansi
}

_main "$@"
fi
#fin
