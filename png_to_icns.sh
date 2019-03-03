#!/usr/bin/env zsh

set -e

function error {
    echo "${@}" >&2 ; exit 1
}

function standardize_dpi {
    local filename
    local -i ac_dpi to_dpi

    filename="${1}"
    to_dpi=${2}

    ac_dpi=$(
        printf "%.0f" \
            $(identify -units PixelsPerInch -format "%x" ${filename})
    )

    if ! [[ ${ac_dpi} -eq ${to_dpi} || $[${ac_dpi} + 1] -eq ${to_dpi} ]] ; then
        convert -units PixelsPerInch -resample ${to_dpi} \
            "${filename}" "${filename}"
    fi
}

file=${@[1]}
tmp_dir="/tmp/png_to_icns-$(uuidgen)"
iconset="${tmp_dir}/app.iconset"

# DPI 調整するかどうかのフラグ
# DPI の調整で画像サイズが変わってコケるので今は放置
resample=false
# Retina 用に @2 を作るかのフラグ
double_f=true

# Open Photography Forum
unsharp="1.5x1+0.7+0.02"

typeset -a c_size=()
c_size=(512 256 128 32 16)

typeset -i size si_2

if ! [[ -f "${file}" ]] ; then
    error "unable to locate file:" "${file}"
fi

if ! [[ $(identify -format "%m" ${file}) -eq "PNG" ]] ; then
    error "the file is NOT PNG"
fi

case $(identify -format "%wx%h" ${file}) in
    "1024x1024"|"512x512"|"256x256"|"128x128") ;;
    "16x16"|"32x32") error "file size too small, abort" ;;
    *) error "cannot make icns: not appropriate sizes" ;;
esac

mkdir -p "${iconset}"

for size in $c_size ; do
    si_2=$((${size} * 2))

    convert "${file}" \
        -resize ${size}x${size} \
        -unsharp "${unsharp}" \
        "${iconset}/icon_${size}x${size}.png"

    ${double_f} && convert "${file}" \
        -resize ${si_2}x${si_2} \
        -unsharp "${unsharp}" \
        "${iconset}/icon_${size}x${size}@2.png"
done

$resample && for i in $(ls "${iconset}") ; do
    [[ ${i} == *@2* ]] &&
        standardize_dpi "${iconset}/${i}" 144 ||
        standardize_dpi "${iconset}/${i}" 72
done

iconutil -c icns "${iconset}" -o ./app.icns

rm -rf ${tmp_dir}

return 0
