#!/bin/bash

function check_linux_distro()
{
    local distro="$(source /etc/os-release >/dev/null 2>&1 && echo "${ID}")"
    [[ -z "${distro}" && -f /etc/redhat-release ]] && distro="rhel"
    [[ -z "${distro}" && -f /etc/SuSE-release ]] && distro="sles"
    echo "${distro}"
}

pkgname="ipmitool"

build_dir=${DEST:-/${pkgname}_build}

XCAT_BUILD_DISTRO="$(check_linux_distro)"
echo "[INFO] Start to build $pkgname on $XCAT_BUILD_DISTRO"

cur_path=$(dirname "$0")
cd $cur_path

XCAT_BUILD_DISTRO="$(check_linux_distro)"
case "${XCAT_BUILD_DISTRO}" in
"centos"|"fedora"|"rhel"|"sles"|"rockylinux"|"almalinux")
    buildcmd="./bldipmi.pl"
    dftpath="/tmp/build/"
    pkgtype="rpm"
    ;;
"ubuntu")
    buildcmd="./make_deb.sh"
    dftpath=$cur_path
    pkgtype="deb"
    ;;
*)
    echo "${XCAT_BUILD_DISTRO}: unsupported Linux distribution to build goconserver"
    exit 1
    ;;
esac

$buildcmd |& tee /tmp/build.log
if [ $? != 0 ]; then
    echo "[ERROR] Failed to build $pkgname by command $buildcmd"
    exit 1
fi

buildpath=`find $dftpath -name ${pkgname}*.$pkgtype | xargs ls -t | head -n 1`
if [ -z "$buildpath" ]; then
    echo "[ERROR] Could not find build ${pkgname}*.$pkgtype"
    exit 1
fi

filepath=$(dirname $buildpath)
pathpre=${filepath:${#dftpath}}
build_dir=$build_dir/$pathpre
mkdir -p $build_dir

cp -f $buildpath $build_dir
if [ $? != 0 ]; then
    echo "[ERROR] Failed to copy $buildpath to $build_dir"
    exit 1
fi
cp -f /tmp/build.log $build_dir

buildname=$(basename $buildpath)
echo "[INFO] Package path is $build_dir/$buildname"

exit 0
