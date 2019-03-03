#!/usr/bin/env zsh

set -e

function error {
    echo "${@}" >&2 ; exit 1
}

file=${@[1]}
tmp_dir="/tmp/svg_to_icns-$(uuidgen)"
iconset="${tmp_dir}/app.iconset"

# Retina 用に @2 を作るかのフラグ
double_f=true

if ! [[ -f "${file}" ]] ; then
    error "unable to locate file:" "${file}"
fi

typeset -a c_size=()
typeset -i size si_2
c_size=(512 256 128 32 16)

mkdir -p "${iconset}"

for size in $c_size ; do
    si_2=$[${size} * 2]

    rsvg-convert "${file}" \
        -f "png" -d 72 -p 72 \
        -w ${size} -h ${size} \
        -o "${iconset}/icon_${size}x${size}.png"

    ${double_f} && rsvg-convert ${file} \
        -f "png" -d 144 -p 144 \
        -w ${si_2} -h ${si_2} \
        -o "${iconset}/icon_${size}x${size}@2.png"
done

iconutil -c icns "${iconset}" -o ./app.icns

rm -rf ${tmp_dir}

return 0
