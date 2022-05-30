#!/usr/bin/env bash
# pure sh has no implementation of hash tables, bash is present on x6100

NO_ARGS=0
E_OPTERROR=85

# TODO: unify keys in constants
# ============================== Option descriptions for help output
declare -A description
description["rtty_shift"]="Value of frequecy shift for TTY moded, substituting the \"425\" option, so keep new value three digit"
description["gain_color"]="UI color of VOLUME/SQL THR/RF GAIN value text, hex color value without \"#\" symbol"
description["settings_color"]="UI color of selected radio settings value text, e.g. TX POWER, hex color value without \"#\" symbol"

# ============================== Options address pointers
declare -A addrs
addrs["rtty_shift"]=000946f4
addrs["gain_color"]=00087cfb
addrs["settings_color"]=00087c2b

help()
{
   echo "Script, that patches Xiegu X6100 app binary"
   echo "in order to change some hardcoded values"
   echo
   echo "Keys:"
   echo "-s %key%=%value%"
   echo "-f path/to/x6100_executable"
   echo "-h see this help"
   echo
   echo "Syntax: $0 -s %key%=%value% -f %path/to/x6110_app%"
   echo "takes one %key%=%value% pair at once for now"
   echo
   echo "Available options:"
   for k in "${!description[@]}"
   do
       printf "  - %s\n" "$k: ${description[$k]}"
   done
   echo

   exit 1
}


# ============================== Argparse
if [ $# -eq "$NO_ARGS" ]    # Script invoked with no command-line args?
then
  echo "Arguments required"
  echo
  help
  exit $E_OPTERROR
fi

ARG_REGEX="(.+)=(.+)"

while getopts "s:f:h" arg; do
  case $arg in
    h)
      help
      ;;
    s)
        # TODO: populate a hashtable here and then cycle throug them in a main cycle
        if [[ $OPTARG =~ $ARG_REGEX ]]
        then
            key="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"
        else
            echo "Syntax error at -s parametr"
            exit $E_OPTERROR
        fi
      ;;
    f)
      file="$OPTARG"
      ;;
  esac
done


# ============================== Main code part
hexify_string() {
    # arg1    - value to prepare for inserting into binary
    # returns - hex ascii code
    local value="$1"

    echo "$value" | xxd -ps | head -c-3
}

compose_patchstring() {
    # arg1    - option shorthand
    # arg2    - value in ASCII
    # returns - <addr: hex value> formatted string to use in xxd
    local addr=${addrs["$1"]}
    local val="$2"

    echo "<$addr: $(hexify_string $val)>"
}

patch_bin() {
    # arg1    - prepared binary patch string
    # arg2    - path to the file to parch
    # returns - void
    local patchstring="$1"
    local target="$2"

    echo "$patchstring" | xxd -r - "$target"
}

main(){
    local key=$1
    local val=$2
    local file=$3

    patchstring=$(compose_patchstring $key $val)
    echo "writing $patchstring into $file"
    patch_bin "$patchstring" "$file"
}

# ============================== Sanity checks
# TODO optimize
if [ -z ${file+x} ]; then echo "No file provided"; exit $E_OPTERROR; fi
if [ ! -f "$file" ]; then
    echo "File $file does not exist."
    exit $E_OPTERROR
fi
if [ -z ${key+x} ]; then echo "No key provided"; exit $E_OPTERROR; fi
if [ -z ${value+x} ]; then echo "No value provided"; exit $E_OPTERROR; fi
if [ -z ${addrs["$key"]+x} ]; then
    echo "Wrong key: $key"
    exit $E_OPTERROR
fi

main $key $value $file
