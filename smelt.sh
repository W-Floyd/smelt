#!/bin/bash

PS4='Line ${LINENO}: '

__sizes=''
__verbose='0'
__very_verbose_pack='0'
__install='0'
__mobile='0'
__quick='1'
__time='0'
__force='0'
__debug='0'
__quiet='0'
__silent='0'
__should_warn='0'
__use_custom_size='0'
__dry='0'
__compress='0'
__clean_xml='0'
__xml_only='0'
__do_not_render='0'
__list_completed='0'
__list_changed='0'
__last_size='0'
__should_optimize='0'
__no_optimize='0'
__ignore_max_optimize='0'
__re_optimize='0'
__show_progress='1'

export __run_dir="$(dirname "$(readlink -f "${0}")")"
export __smelt_setup_bin="${__run_dir}/smelt_setup.sh"

# get set up
source "${__smelt_setup_bin}" &> /dev/null || { echo "Failed to load setup \"${__smelt_setup_bin}\""; exit 1; }

# Print help
__usage () {
echo "$(basename "${0}") <OPTIONS> <SIZE>

Makes the resource pack at the specified size(s) (or using
default list of sizes). Order of options and size(s) are not
important.

Options:
  -h  --help  -?            This help message
  -v  --verbose             Be verbose
  -i  --install             Install to ~/.minecraft folder
  -m  --mobile              Make mobile resource pack as well
  -s  --slow                Use Inkscape instead of rsvg-convert
  -t  --time                Time functions (for debugging)
  -d  --debug               Use debugging mode
  -l  --lengthy             Very verbose debugging mode
  -f  --force-render        Discard pre-rendered data
  -q  --quiet               No output unless specified
      --silent              No output at all
      --no-progress         Do not show a progress report
  -w  --warn                Show warnings
  -c  --compress            Actually compress zip files
  -x  --force-xml           Force resplitting of xml files
      --xml-only            Only split xml files
  -o  --optimize            Optimize final PNG files
  --no-optimize             Do not optimize final PNG files
  --max-optimize <SIZE>     Max size to optimize
  --force-optimize          Optimize any size of final PNG files
  --force-max-optimize      Ensure max-optimize is obeyed
  --re-optimize             Re-process and re-optimize files
                            appropriately
  --optimizer <OPTIMIZER>   Optimize with specified optimizer
  --name <NAME>             Name to use when processing a pack
  --completed               List completed textures, according
                            to the COMMON field in the catalogue
  --changed                 List ITEMS changed since last render\
"
}

################################################################

__force_time "Rendered all" start
__force_time "Processed XML" start

# If there are are options,
if ! [ "${#}" = 0 ]; then

# then let's look at them in sequence.
while ! [ "${#}" = '0' ]; do

    __check_input () {

    case "${1}" in

        "h" | "--help" | "?")
            __usage
            exit 77
            ;;

        "--no-progress")
            __show_progress='0'
            ;;

        "v" | "--verbose")
            __verbose='1'
            __quiet='0'
            ;;

        "l" | "--lengthy")
            __verbose='1'
            __very_verbose_pack='1'
            ;;

        "i" | "--install")
            __install='1'
            ;;

        "m" | "--mobile")
            __mobile='1'
            ;;

        "s" | "--slow")
            __quick='0'
            ;;

        "t" | "--time")
            __time='1'
            ;;

        "d" | "--debug")
            __debug='1'
            ;;

        "f" | "--force-render")
            __force='1'
            ;;

        "q" | "--quiet")
            __quiet='1'
            __verbose='0'
            ;;

        "--silent")
            __silent='1'
            __quiet='1'
            ;;

        "w" | "--warn")
            __should_warn='1'
            ;;

        "c" | "--compress")
            __compress='1'
            ;;

        "x" | "--force-xml")
            __force_warn "Cleaning split xml files"
            __clean_xml='1'
            ;;

        "--xml-only")
            __xml_only='1'
            ;;

        "o" | "--optimize")
            __should_optimize='1'
            ;;

        "--dry")
            __dry='1'
            ;;

        "--completed")
            __list_completed='1'
            ;;

        "--changed")
            __list_changed='1'
            ;;

        "--no-optimize")
            __no_optimize='1'
            ;;

        "--max-optimize")
            ;;

        "--force-max-optimize")
            __ignore_max_optimize='0'
            ;;

        "--force-optimize")
            __should_optimize='1'
            __ignore_max_optimize='1'
            ;;

        "--re-optimize")
            __re_optimize='1'
            ;;

        "--optimizer")
            ;;

        "--name")
            ;;

        [0-9]*)
            if [ -z "${__sizes}" ] || [ "${__use_custom_size}" = '1' ]; then
                __use_custom_size='1'
                __sizes="${__sizes}
${1}"
            else
                __warn "Overriding render sizes"
                __use_custom_size='1'
                __sizes="${1}"
            fi
            ;;

        *)
            __custom_error "Unknown option \"${1}\""
            __usage
            exit 77
            ;;

    esac

    }

    case "${__last_option}" in

        "--max-optimize")

            if [ "${1}" -eq "${1}" ] 2>/dev/null; then

                __max_optimize="${1}"

            else

                __error "Given input is not a size"

            fi

            ;;

        "--optimizer")

            if __check_optimizer "${1}"; then

                __optimizer="${1}"

            else

                __error "Given input is not a valid optimizer"

            fi

            ;;

        "--name")

            __name="${1}"

            ;;

        *)

            if [ "${1}" = '-' ] || [ "${1}" = '--' ]; then

                __check_input "${1}"

            elif echo "${1}" | grep '^--.*' &> /dev/null; then

                __check_input "${1}"

            elif echo "${1}" | grep '^-.*' &> /dev/null; then

                __letters="$(echo "${1}" | cut -c 2- | sed 's/./& /g')"

                for __letter in ${__letters}; do

                    __check_input "${__letter}"

                done

            else
                __check_input "${1}"
            fi

            if [ "${?}" = '77' ]; then
                exit
            fi

            ;;

    esac

    __last_option="${1}"

    shift

done

fi

__last_option=''

################################################################

if ! [ -d './src' ] && ! [ -e "${__catalogue}" ]; then
    __error "Not a resource pack project folder"
elif ! [ -e "${__catalogue}" ]; then
    __error "Catalogue \"${__catalogue}\" is missing"
elif ! [ -d 'src' ]; then
    __error "Source file directory \"src\" is missing"
fi

if [ "${__list_completed}" = '1' ]; then
    "${__smelt_completed_bin}" "${__catalogue}"
    exit
fi

if [ "${__clean_xml}" = '1' ] && [ -d './src/xml/' ]; then
    rm -r './src/xml/'
fi

################################################################

if [ -z "${__sizes}" ]; then
__sizes="32
64
128
256
512"
fi

__final_size="$(tr ' ' '\n' <<< "${__sizes}" | tail -n1)"

__sizes="$(echo "${__sizes}" | sort -n | uniq)"

if [ -z "${__max_optimize}" ]; then
    __default_max_optimize='512'
    __max_optimize="${__default_max_optimize}"
    if [ "${__should_optimize}" = '1' ] ; then
        __should_warn_size='0'
        while read -r __test_size; do
            if ! [ "${__test_size}" -lt "${__default_max_optimize}" ]; then
                __should_warn_size='1'
                break
            fi
        done <<< "${__sizes}"
        if [ "${__should_warn_size}" = '1' ]; then
            __force_warn "Default maximum optimization size is \"${__default_max_optimize}\", some sizes will not
be optimized. Use --force-optimize to override this, or set a
new maximum with --max-optimize=SIZE"
        fi
    fi
fi

__just_render () {

__options="${1}"

if [ "${__mobile}" = '1' ]; then
    __options="${__options} -m"
fi

if [ "${__quick}" = '0' ]; then
    __options="${__options} -s"
fi

if [ "${__time}" = '1' ]; then
    __options="${__options} -t"
fi

if [ "${__debug}" = '1' ]; then
    __options="${__options} -d"
fi

if [ "${__force}" = '1' ]; then
    __options="${__options} -f"
fi

if [ "${__should_warn}" = '1' ]; then
    __options="${__options} -w"
fi

if [ "${__should_optimize}" = '1' ]; then
    __options="${__options} -o"
fi

if [ "${__show_progress}" = '1' ]; then
    __options="${__options} --progress"
fi

if [ "${__list_changed}" = '1' ]; then
    __options="${__options} --list-changed"
fi

if [ "${__xml_only}" = '1' ]; then
    __options="${__options} --xml-only"
fi

if [ "${__quiet}" = '1' ]; then
        __options="${__options} --quiet"
fi

if [ "${__no_optimize}" = '1' ] || [ "${__ignore_max_optimize}" = '0' -a "${1}" -gt "${__max_optimize}" ]; then
    __options="${__options} --no-optimize"
fi

if [ "${__re_optimize}" = '1' ] && [ "${__should_optimize}" = '1' ]; then
    __options="${__options} --re-optimize"
fi

if [ "${__dry}" = '1' ]; then
    __options="${__options} --dry"
fi

if [ "${__do_not_render}" = '1' ]; then
    __options="${__options} --do-not-render"
fi

if [ "${__very_verbose_pack}" = '1' ]; then
    "${__smelt_render_bin}" ${__options} -l -p "${1}" || __error "Render encountered errors"
elif [ "${__verbose}" = '1' ]; then
    "${__smelt_render_bin}" ${__options} -v -p "${1}" || __error "Render encountered errors, please run with very verbose mode on"
else
    "${__smelt_render_bin}" ${__options} -p "${1}" || __error "Render encountered errors, please run with very verbose mode on"
fi

}

__render_and_pack () {

__force_announce "Processing \"${1}\""

__just_render "${1}"

if [ "${__dry}" = '0' ]; then


if [ -a "${2}.zip" ]; then
    rm "${2}.zip"
fi

if [ "${__mobile}" = '1' ] && [ -a "${2}_mobile.zip" ]; then
    rm "${2}_mobile.zip"
fi

__pushd "${2}_cleaned"

if [ "${__compress}" = '1' ]; then

    __force_announce "Compressing resource pack"

    zip -q -9 -r "../${2}" ./

else

    zip -qZ store -r "../${2}" ./

fi

__popd

if [ "${__mobile}" = '1' ]; then
    __pushd "${2}_mobile"

    if [ "${__compress}" = '1' ]; then

        zip -q -9 -r "../${2}_mobile" ./

    else

        zip -qZ store -r "../${2}_mobile" ./

    fi

    __popd
fi

if [ -d "${2}_cleaned" ]; then
    rm -r "${2}_cleaned"
fi

if [ -d "${2}_mobile" ]; then
    rm -r "${2}_mobile"
fi

fi

}

__sub_loop () {

__size="${1}"

__packfile="$("${__smelt_render_bin}" --name-only "${__size}")"

if ! [ "${?}" = 0 ]; then
    echo "${__packfile}"
    exit 1
fi

if [ "${__time}" = '1' ]; then

    __force_time "Rendered size ${__size}" start

    if [ "${__silent}" = '1' ]; then
        __render_and_pack "${__size}" "${__packfile}" 1> /dev/null
    else
        __render_and_pack "${__size}" "${__packfile}"
    fi

    __force_time "Rendered size ${__size}" end

    if [ "${__silent}" = '0' ] && ! [ "${__size}" = "${__final_size}" ]; then
        echo
    fi

else

    if [ "${__silent}" = '1' ]; then
        __render_and_pack "${__size}" "${__packfile}" 1> /dev/null
    else
        __render_and_pack "${__size}" "${__packfile}"
    fi

fi

__dest="${HOME}/.minecraft/resourcepacks/${__packfile}.zip"

if [ "${__install}" = '1' ]; then

    if [ -e "${__dest}" ] ; then
        rm "${__dest}"
    fi

    cp "${__packfile}.zip" "${__dest}"

fi

if [ "${__quiet}" = '0' ] && [ "${__dry}" = '0' ] && [ "${__time}" = '0' ] && ! [ "${__size}" = "${__final_size}" ]; then
    echo
fi

}

if ! [ -z "${__optimizer}" ] && [ "${__should_optimize}" = '1' ] && [ "${__verbose}" = '1' ]; then
    __announce "Using optimizer \"${__optimizer}\""
    echo
fi

if [ "${__xml_only}" = '1' ]; then
    __just_render 32
else

    for __size in ${__sizes}; do
        if [ "${__size}" = "${__final_size}" ]; then
            __last_size='1'
        else
            __last_size='0'
        fi

        if [ "${__list_changed}" = '1' ]; then
            __just_render "${__size}"
            if [ "${__last_size}" = '0' ]; then
                echo
            fi
        else

            if [ "${__size}" -gt "${__max_optimize}" ] && [ "${__ignore_max_optimize}" = '0' ] && [ "${__should_optimize}" = '1' ]; then

                if [ "${__verbose}" = '1' ]; then
                    __force_announce "Size \"${__size}\" is larger than the max optimize size \"${__max_optimize}\", not optimizing."
                fi
            fi

            __sub_loop "${__size}"

        fi
    done
fi

if [ "${__xml_only}" = '0' ]; then
    __force_time "Rendered all" end
else
    __force_time "Processed XML" end
fi

exit