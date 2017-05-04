################################################################################
# Functions
################################################################################
#
# <LIST_OF_FILES> | __mext <FILE_1> <FILE_2> <FILE_3> ...
#
# Minus Extension
# Strips last file extension from string.
#
################################################################################

__mext () {

__tmp_mext_sub () {
    echo "${1%.*}"
}

while ! [ "${#}" = '0' ]; do
    __tmp_mext_sub "${1}"
    shift
done

if read -r -t 0; then
    cat | while read -r __value; do
        __tmp_mext_sub "${__value}"
    done
fi

}

################################################################################
#
# <LIST_OF_FILES> | __oext <FILE_1> <FILE_2> <FILE_3> ...
#
# Only Extension
# Returns the final extension of a filename.
# Opposite of __mext.
#
################################################################################

__oext () {

__tmp_oext_sub () {
    echo "${1/*.}"
}

while ! [ "${#}" = '0' ]; do
    __tmp_oext_sub "${1}"
    shift
done

if read -r -t 0; then
    cat | while read -r __value; do
        __tmp_oext_sub "${__value}"
    done
fi

}

################################################################################
#
# __lsdir <DIR>
#
# List directories
# Lists all directories in the current folder, or specified folder.
#
################################################################################

__lsdir () {
if [ -z "${1}" ]; then
    find . -maxdepth 1 -mindepth 1 -type d | sort
else
    find "${1}" -maxdepth 1 -mindepth 1 -type d | sort
fi
}

################################################################################
#
# __empdir
#
# Remove Empty Directories
# Finds all empty directories, until no changes occur.
#
################################################################################

__empdir () {

__listing="$(find .)"

__tmp_empdir_sub () {

find . -type d | while read -r __dir; do
    if ! [ "$(ls -A "${__dir}/")" ]; then
        rmdir "${__dir}"
    fi
done

}

__tmp_empdir_sub

__new_listing="$(find .)"

until [ "${__listing}" = "${__new_listing}" ]; do
    __listing="${__new_listing}"
    __new_listing="$(find .)"
    __tmp_empdir_sub
done

}

################################################################################
# XML Functions
################################################################################
#
# __get_range <FILE> <FIELD_NAME>
#
# Get Range
# Gets the range/s in a <FILE> between each set of <FIELD_NAME>.
#
# When piped version is used, FILE should be omitted.
#
# Example:
#
# __get_range catalogue.xml ITEM
#
# will print
#
# 2,10
# 11,19
# 20,28
# 31,39
#
################################################################################

__get_range () {
grep -n '[</|<]'"${2}"'>' < "${1}" | sed 's/\:.*//' |  sed 'N;s/\n/,/'
}

__get_range_piped () {
cat | grep -n '[</|<]'"${1}"'>' | sed 's/\:.*//' |  sed 'N;s/\n/,/'
}

################################################################################
#
# __read_range <FILE> <RANGE>
#
# Read Range
# Reads the <RANGE> from a <FILE>, as generated by __get_range.
# Must be single line input.
#
# When piped version is used, FILE should be omitted.
#
################################################################################

__read_range () {
sed -e "${2}"'!d' -e 's/^[\t| ]*//' "${1}"
}

__read_range_piped () {
cat | sed -e "${1}"'!d' -e 's/^[\t| ]*//'
}

################################################################################
#
# __get_value/s <DATASET> <FIELD_NAME1> <FIELD_NAME2> ...
#
# Get Value
# Gets the value/s of <FIELD_NAME> from <DATASET>.
# Meant to be used on separated data-sets.
#
# When piped version is used, DATASET should be omitted.
#
# When __get_values* is used, multiple field names may be specified.
#
################################################################################

__get_value () {
pcregrep -M -o1 "<${2}>((\n|.)*)</${2}>" "${1}"
}

__get_value_piped () {
cat | pcregrep -M -o1 "<${1}>((\n|.)*)</${1}>"
}

__get_values () {
local __file="${1}"
shift
for __input in "$@"; do
    pcregrep -M -o1 "<${1}>((\n|.)*)</${1}>" "${__file}"
    shift
done
}

__get_values_piped () {
local __pipe="$(cat)"
for __input in "$@"; do
    pcregrep -M -o1 "<${1}>((\n|.)*)</${1}>" <<< "${__pipe}"
    shift
done
}

################################################################################
#
# __set_value <DATASET> <FIELD_NAME> <VALUE>
#
# Set Value
# Sets the <VALUE> of the specified <FIELD_NAME>.
#
# When piped version is used, VALUE should be omitted.
#
################################################################################

__set_value () {
perl -i -pe "BEGIN{undef $/;} s#<${2}>.*</${2}>#<${2}>${3}</${2}>#sm" "${1}"
}

__set_value_piped () {
perl -i -pe "BEGIN{undef $/;} s#<${2}>.*</${2}>#<${2}>$(cat)</${2}>#sm" "${1}"
}

################################################################################
#
# __test_field <DATASET> <FIELD>
#
# Test Field
# Tests for a field in a dataset. Returns 0 if it exists, 1 if it does not.
#
################################################################################

__test_field () {
if grep -q "^<${2}>"; then
    return 0
else
    return 1
fi
}

################################################################################
# Other stuff
################################################################################
#
# __emergency_exit
#
# Prints the last known command and exits, to be used when a command fails.
#
# Example:
# cd "${__dir}" || __emergency_exit
#
################################################################################

__emergency_exit () {
echo "Last command run was ["!!"]"
exit 1
}

################################################################################
#
# __hash_folder <FILE> <EXCLUDEDIR>
#
# Hashes the current folder and outputs to <FILE>.
# EXCLUDEDIR is optional (in the form of "xml", not "./xml/").
#
################################################################################

__hash_folder () {
if [ -z "${2}" ]; then
    local __listing="$(find . -type f)"
else
    local __listing="$(find . -not -path "./${2}/*" -type f)"
fi

if ! [ -z "${__listing}" ]; then

    {

    md5sum $(grep -v ' ' <<< "${__listing}") >> "${1}"

    grep ' ' <<< "${__listing}" | sed '/^$/d' | while read -r __file; do
        md5sum "${__file}"
    done

    } > "${1}"
fi

}

################################################################################
#
# __check_hash_folder <FILE> <OUTPUT>
#
# Hashes the current folder and compares to <FILE>, outputting to <OUTPUT>.
#
################################################################################

__check_hash_folder () {
md5sum -c "${1}" > "${2}"
}

################################################################################
#
# __pushd <DIR>
#
# Same as regular pushd, just quiet unless told not to be.
#
################################################################################

__pushd () {
if [ -d "${1}" ]; then
    pushd "${1}" 1> /dev/null
else
    echo "Directory \"${1}\" does not exist!"
    exit 2
fi
}

################################################################################
#
# __popd
#
# Same as regular popd, just quiet unless told not to be.
#
################################################################################

__popd () {
popd 1> /dev/null
}

################################################################################
#
# __strip_ansi
#
# Strips ANSI codes from *piped* input.
#
################################################################################

__strip_ansi () {
cat | perl -pe 's/\e\[?.*?[\@-~]//g'
}

################################################################################
#
# __print_pad
#
# Prints the given number of spaces.
#
################################################################################

__print_pad () {
seq 1 "${1}" | while read -r __line; do
    echo -n ' '
done
}

################################################################################
#
# __format_text <LEADER> <TEXT> <TRAILER>
#
# Pads text to a set length, so multiline warnings, info and errors can be made.
#
################################################################################

__format_text () {
echo -ne "${1}"
local __desired_size='7'
local __leader_size="$(echo -ne "${1}" | __strip_ansi | wc -m)"
local __clipped_size=$((__desired_size-__leader_size-3))
local __front_pad="$(__print_pad "${__clipped_size}") - "
echo -ne "${__front_pad}"
local __pad=''

if [ "$(echo "${2}" | wc -l)" -gt '1' ]; then
    echo "${2}" | head -n -1 | while read -r __line; do
        if [ -z "${__pad}" ]; then
            echo -e "${__pad}${__line}"
            local __pad="$(__print_pad "${__desired_size}")"
        else
            echo -e "${__pad}${__line}"
        fi
    done
    local __pad="$(__print_pad "${__desired_size}")"
    echo -e "${__pad}$(echo "${2}" | tail -n 1)${3}"
else
    echo -e "${2}${3}"
fi

}

################################################################################
#
# __bypass_announce <MESSAGE>
#
# Bypass Announce
# Echos a statement no matter what.
#
################################################################################

__bypass_announce () {
__format_text "\e[32mINFO\e[39m" "${1}" ""
}

################################################################################
#
# __force_announce <MESSAGE>
#
# Force Announce
# Echos a statement, when __quiet is equal to 0.
#
################################################################################

__force_announce () {
if [ "${__quiet}" = '0' ]; then
    __bypass_announce "${1}"
fi
}

################################################################################
#
# __announce <MESSAGE>
#
# Announce
# Echos a statement, only if __verbose is equal to 1.
#
################################################################################

__announce () {
if [ "${__time}" = '0' ] && [ "${__verbose}" = '1' ] && ! [ "${__name_only}" = '1' ] && ! [ "${__list_changed}" = '1' ]; then
    __force_announce "${1}"
fi
}

################################################################################
#
# __force_warn <MESSAGE>
#
# Warn
# Echos a statement when something has gone wrong.
#
################################################################################

__force_warn () {
if ! [ "${__name_only}" = '1' ] && ! [ "${__list_changed}" = '1' ]; then
    __format_text "\e[93mWARN\e[39m" "${1}" ", continuing anyway." 1>&2
fi
}

################################################################################
#
# __warn <MESSAGE>
#
# Warn
# Echos a statement when something has gone wrong, to be used when it is
# tolerable.
#
################################################################################

__warn () {
if [ "${__very_verbose}" = '1' ] || [ "${__should_warn}" = '1' ]; then
if ! [ "${__name_only}" = '1' ] && ! [ "${__list_changed}" = '1' ]; then
    __force_warn "${@}"
fi
fi
}

################################################################################
#
# __custom_error <MESSAGE>
#
# Custom Error
# Echos an error statement without quiting.
#
################################################################################

__custom_error () {
__format_text "\e[31mERRO\e[39m" "${1}" "${2}" 1>&2
}

################################################################################
#
# __error <MESSAGE>
#
# Error
# Echos a statement when something has gone wrong, then exits.
#
################################################################################

__error () {
__custom_error "${1}" ", exiting."
exit 1
}

################################################################################
#
# __force_time <MESSAGE> <start/end>
#
# Force Time
# Times between two occurrences of the function, as set by start or end, only if
# time is on.
#
################################################################################

__force_time () {
local __message="$(echo "${1}" | md5sum | sed 's/ .*//')"

if [ -z "${2}" ] || [ -z "${1}" ]; then
    __force_warn "Missing option in time function."
else

if [ "${2}" = 'start' ]; then
    export "__function_start_time${__message}"="$(date +%s.%N)"
elif [ "${2}" = 'end' ]; then
    export "__function_end_time${__message}"="$(date +%s.%N)"
fi

if ! [ "${__name_only}" = '1' ] && [ "${__time}" = '1' ] && ! [ "${__list_changed}" = '1' ]; then
    if [ -z "${2}" ]; then
        __force_warn "No input to __time function, disabling timer."
        __time='0'
    else

        if [ "${2}" = 'end' ]; then
            local __f_start="__function_start_time${__message}"
            local __f_end="__function_end_time${__message}"

            __format_text "\e[32mTIME\e[39m" "${1} in $(bc <<< "${!__f_end}-${!__f_start}") seconds" ""


        elif ! [ "${2}" = 'start' ]; then
            __force_warn "Invalid input to __time, '${2}'"
        fi

    fi
fi

fi
}

################################################################################
#
# __time <MESSAGE> <start/end>
#
# Time
# Times between two occurrences of the function, as set by start or end, only if
# verbose is on.
#
################################################################################

__time () {
if [ "${__verbose}" = '1' ]; then
    __force_time "${1}" "${2}"
fi
}

################################################################################
#
# __log2 <NUMBER>
#
# Log base 2
# Finds the log2 of a number, or rounds up to the next power of 2.
#
# Shamelessly stolen from:
# https://bobcopeland.com/blog/2010/09/log2-in-bash/
#
################################################################################

__log2 () {
local x=0
for (( y=$1-1 ; $y > 0; y >>= 1 )) ; do
    let x=$x+1
done
echo $x
}

################################################################################
#
# ... | __strip_zero
#
# Strip Zero
# From pipe, strips trailing zeros and dangling decimal place.
#
################################################################################

__strip_zero () {
cat | sed -e 's/\([^0]*\)0*$/\1/' -e 's/\.$//'
}

################################################################################
#
# ... | __clean_pack
#
# Clean Pack
# From pipe, strips leading spaces and tabs, deletes lines that then start with
# a # after leaders have been stripped.
#
################################################################################

__clean_pack () {
cat | sed -e 's/^[ |\t]*//' -e '/^#/d' | sed '/^$/d'
}

################################################################################
#
# ... | __funiq
#
# First uniq
# like uniq, but does not need to be sorted, and so retains ordering.
#
################################################################################

__funiq () {

cat | sed '/^$/d' | awk '!cnts[$0]++'

}

################################################################################
# Function Functions
################################################################################
#
# These will be used to choose alternative methods of doing things (optimize,
# vector render, etc.)
#
################################################################################

################################################################################
#
# __list_functions <PREFIX>
#
# List Functions
# Lists functions that use the given prefix (that is, "__<PREFIX>_<COMMAND>")
#
# For example:
#
# $ __list_functions vector_render
#
# might return
#
# > inkscape
# > rsvg-convert
#
# having matched with '__vector_render_inkscape' and
# '__vector_render_rsvg-convert'
#
# Note the output format - it is cleaned to the command name itself.
#
################################################################################

__list_functions () {

compgen -A function | grep "^__${1}_" | sort | sed "s/^__${1}_//"

}


################################################################################
#
# __test_function <PREFIX> <COMMAND>
#
# Test Function
# Tests a function, both for existence of a function, and for the existence of
# the corresponding internal command. Returns 0 on success, 1 all other cases.
#
################################################################################

__test_function () {

if which "${2}" &> /dev/null && [ "$(type -t "__${1}_${2}")" = 'function' ]; then
    return 0
else
    return 1
fi

}

################################################################################
#
# __test_routine <PREFIX>
#
# Test Routine
# Tests to see if a routine is available for the given PREFIX, assumes that
# __choose_function has already been run.
#
################################################################################

__test_routine () {

local __function_name="__function_${1}"

if [ -z "${!__function_name}" ]; then

    return 1

else

    return 0

fi

}

################################################################################
#
# __choose_function <OPTIONAL_FLAGS> <PREFIX>
#
# Choose Function
# Chooses a function that exists, given the prefix of the function.
# NOTE - It is important to declare the PREFIX *LAST*
#
# Optional flags include:
#   -e                  Error out if missing
#   -d <DESCRIPTION>    Description to be used when reporting that no function
#                       was found.
#   -p <LIST>           Line and/or space separated list of functions in order
#                       of preference (hence, -p)
#   -f                  Force choose. That is, ignore the currently chosen
#                       routine and choose a new one. Otherwise, uses existing
#                       choice by default, if valid, else, chooses a new one.
#
# Sets a variable __function_${__function_prefix}"="${__function}"
#
# So, for example, with vector rendering, inkscape and rsvg-convert are supposed
# to be possible candidates, with rsvg-convert being prefered (speed is far
# better). So an example might be like follows:
#
# $ __choose_function vector_render -e -d 'vector rendering' -p 'rsvg-convert'
#
# That means, in words: search for functions that begin with __vector_render_
# (prefix), putting rsvg-convert first in order of preference
# (-p 'rsvg-convert'). Should a successful routine be found (checking for both
# rsvg-convert as an excecutable, AND __vector_render_rsvg-convert as a
# function), __function_vector_render will be set to 'rsvg-convert'. If
# no routine is found that works, then amessage stating "No valid routine for
# vector rendering found" is printed (-d 'vector rendering'), before erroring
# out (-e).
#
################################################################################

__choose_function () {
local __should_error='0'
local __should_force='0'
local __preference_list=''
local __description=''
local __function_prefix=''
local __function_name=''

if ! [ "${#}" = 0 ]; then

    while ! [ "${#}" = '0' ]; do

        case "${__last_option}" in

            "-p")

                __preference_list+="
${1}"

                ;;

            "-d")

                __description="${1}"

                ;;

            *)

                case "${1}" in

                    "-e")
                        __should_error='1'
                        ;;

                    "-f")
                        __should_force='1'
                        ;;

                     "-p")
                        ;;

                     "-d")
                        ;;

	                *)
	                    __function_prefix="${1}"
	                    __function_name="__function_${__function_prefix}"
# Neat trick I found here:
# http://stackoverflow.com/questions/14049057/bash-expand-variable-in-a-variable
# Means no more eval sodomy :3
	                    if ! [ -z "${!__function_name}" ] && [ "${__should_force}" = '0' ] && __test_function "${__function_prefix}" "${!__function_name}"; then
                            return 0
                        fi

                        ;;

                esac
                ;;

        esac

        local __last_option="${1}"

        shift

    done

else

    __error "No options passed"

fi

export "__function_${__function_prefix}"="$(
{
echo "${__preference_list}"
__list_functions "${__function_prefix}"
} | tr ' ' '\n' | __funiq | while read -r __function; do

    if __test_function "${__function_prefix}" "${__function}"; then
        echo "${__function}"
        break
    fi

done
)"

if ! __test_routine "${__function_prefix}"; then

    if [ -z "${__description}" ]; then
        __description="${__function_prefix}"
    fi

    local __message="No valid routine for ${__description} found"

    if [ "${__should_error}" = '1' ]; then
        __error "${__message}"
    else
        __force_warn "${__message}"
    fi

fi

}

################################################################################
#
# __run_routine <PREFIX> <ALL_OTHER_OPTIONS>
#
# Run Routine
# Verifies and runs the routine for the given PREFIX.
# For example, rather than typing it out yourself, you can do:
#
# $ __run_routine vector_render file.svg
#
# Finds that __vector_render_rsvg-convert is the blessed routine, and passes
# 'file.svg' to it.
#
# And so the rabbit hole begins...
#
################################################################################

__run_routine () {

local __function_prefix="${1}"
shift

__choose_function "${__function_prefix}"

local __function_name="__function_${__function_prefix}"

local __routine_name="__${__function_prefix}_${!__function_name}"

"${__routine_name}" "${@}"

}

################################################################################
# Export functions
################################################################################
#
# Do this so that any child shells have these functions.
#
################################################################################
for __function in $(compgen -A function); do
	export -f ${__function}
done
