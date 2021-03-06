#!/bin/bash

if ! which "${5}" &> /dev/null; then
    __error "\"${5}\" could not be found, please install the graphviz package"
fi

__graph_tmp_dir="/tmp/furnace/graph${6}"

if [ -d "${__graph_tmp_dir}" ]; then

    rm -r "${__graph_tmp_dir}"

fi

mkdir -p "${__graph_tmp_dir}"

__catalogue="/tmp/${__name}_catalogue"

__clean_pack < "${2}" > "${__catalogue}"

__graph="${__graph_tmp_dir}/${4}"

if ! [ -z "${3}" ]; then
    __files="${3}"
fi

if [ -z "${__files}" ]; then
    __use_files='0'
else
    __use_files='1'
fi

__dep_list=''

__options='    overlap=scalexy;
    center=true
    splines=true;
    sep="0.3";'

echo \
    "digraph pack {
${__options}" > "${__graph}"

__list="$(cat './src/xml/list')"

__pushd './src/xml/tmp_deps/'

if [ "${__use_files}" = '1' ]; then

    while read -r __item; do
        if ! grep -xq "${__item}" <<< "${__list}"; then
            __force_warn "Item \"${__item}\" does not exist"
        else
            __matches="$(grep -x "${__item}" <<< "${__list}")"
            while read -r __match; do
                __dep_list="$(cat "${__match}")
${__dep_list}"
            done <<< "${__matches}"
        fi
    done <<< "${__files}"

else
    __files="${__list}"
    while read -r __item; do

        __dep_list="$(cat "${__item}")
${__dep_list}"

    done <<< "${__list}"
fi

__popd

echo "
    node [style=filled, shape=record, color=\"black\" fillcolor=\"lightgray\" ];
" >> "${__graph}"

grep -v "${__files}" <<< "${__dep_list}" | grep -v '^$' | sed 's/.*/    "&";/' | sort | uniq >> "${__graph}"

__dep_list="$(grep -x "${__files}" <<< "${__list}")
${__dep_list}"

__dep_list="$(grep -v '^$' <<< "${__dep_list}")"

if [ "${__use_files}" = '1' ] && [ "${7}" = '0' ]; then
    echo "
    node [style=filled, shape=record, color=\"blue\" fillcolor=\"lightblue\"];
" >> "${__graph}"
fi

if ! [ -z "${__dep_list}" ]; then

    __dep_list="$(grep -v '^$' <<< "${__dep_list}" | sort | uniq)"

    echo "${__dep_list}" > "${__graph_tmp_dir}/dep_list"

    __tmp_func() {

        __deps="$({
            __get_value "${__graph_tmp_dir}/readrangetmp" DEPENDS
            __get_value "${__graph_tmp_dir}/readrangetmp" SCRIPT
            __get_value "${__graph_tmp_dir}/readrangetmp" CLEANUP
        } | sed '/^$/d')"

        if ! [ -z "${__deps}" ]; then

            while read -r __dep; do
                if ! [ "${__dep}" = "${__name}" ]; then
                    echo "    \"${__dep}\" -> \"${__name}\";"
                fi
            done <<< "${__deps}" | sort | uniq >> "${__graph}"

        fi

    }

    for __range in $(__get_range "${__catalogue}" ITEM); do

        __read_range "${__catalogue}" "${__range}" > "${__graph_tmp_dir}/readrangetmp"

        __name="$(__get_value "${__graph_tmp_dir}/readrangetmp" NAME)"

        if [ "${__use_files}" = '1' ]; then

            if grep -Fxq "${__dep_list}" <<< "${__name}"; then
                __tmp_func
            fi

        else

            __tmp_func

        fi

    done

    echo '}' >> "${__graph}"

    cp "${__graph}" "./$(basename "${__graph}")"

    __graph "${1}" "${6}" "./$(basename "${__graph}")"

    rm "./$(basename "${__graph}")"

else

    __custom_error "No valid items specified."

fi

if [ "${__debug}" = '0' ]; then

    rm -r "${__graph_tmp_dir}"

    rm "${__catalogue}"

fi

exit
