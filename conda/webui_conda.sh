#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [[ -z "${python_cmd}" ]]
then
  python_cmd="python3.10"
fi
if [[ ! -x "$(command -v "${python_cmd}")" ]]
then
  python_cmd="python3"
fi

if [[ -z "${LAUNCH_SCRIPT}" ]]
then
    LAUNCH_SCRIPT="launch.py"
fi

# this script cannot be run as root by default
can_run_as_root=0

# read any command line flags to the webui.sh script
while getopts "f" flag > /dev/null 2>&1
do
    case ${flag} in
        f) can_run_as_root=1;;
        *) break;;
    esac
done

# Disable sentry logging
export ERROR_REPORTING=FALSE

# Do not reinstall existing pip packages on Debian/Ubuntu
export PIP_IGNORE_INSTALLED=0

# Pretty print
delimiter="################################################################"

printf "\n%s\n" "${delimiter}"
printf "\e[1m\e[32mInstall script for stable-diffusion + Web UI\n"
printf "\e[1m\e[34mTested on Debian 11 (Bullseye), Fedora 34+ and openSUSE Leap 15.4 or newer.\e[0m"
printf "\n%s\n" "${delimiter}"

# Do not run as root
if [[ $(id -u) -eq 0 && can_run_as_root -eq 0 ]]
then
    printf "\n%s\n" "${delimiter}"
    printf "\e[1m\e[31mERROR: This script must not be launched as root, aborting...\e[0m"
    printf "\n%s\n" "${delimiter}"
    exit 1
else
    printf "\n%s\n" "${delimiter}"
    printf "Running on \e[1m\e[32m%s\e[0m user" "$(whoami)"
    printf "\n%s\n" "${delimiter}"
fi

if [[ $(getconf LONG_BIT) = 32 ]]
then
    printf "\n%s\n" "${delimiter}"
    printf "\e[1m\e[31mERROR: Unsupported Running on a 32bit OS\e[0m"
    printf "\n%s\n" "${delimiter}"
    exit 1
fi

if [[ -d "$SCRIPT_DIR/.git" ]]
then
    printf "\n%s\n" "${delimiter}"
    printf "Repo already cloned, using it as install directory"
    printf "\n%s\n" "${delimiter}"
    install_dir="${SCRIPT_DIR}/../"
    clone_dir="${SCRIPT_DIR##*/}"
fi

# Check prerequisites
gpu_info=$(lspci 2>/dev/null | grep -E "VGA|Display")


# Try using TCMalloc on Linux
prepare_tcmalloc() {
    if [[ "${OSTYPE}" == "linux"* ]] && [[ -z "${NO_TCMALLOC}" ]] && [[ -z "${LD_PRELOAD}" ]]; then
        # check glibc version
        LIBC_VER=$(echo $(ldd --version | awk 'NR==1 {print $NF}') | grep -oP '\d+\.\d+')
        echo "glibc version is $LIBC_VER"
        libc_vernum=$(expr $LIBC_VER)
        # Since 2.34 libpthread is integrated into libc.so
        libc_v234=2.34
        # Define Tcmalloc Libs arrays
        TCMALLOC_LIBS=("libtcmalloc(_minimal|)\.so\.\d" "libtcmalloc\.so\.\d")
        # Traversal array
        for lib in "${TCMALLOC_LIBS[@]}"
        do
            # Determine which type of tcmalloc library the library supports
            TCMALLOC="$(PATH=/sbin:/usr/sbin:$PATH ldconfig -p | grep -P $lib | head -n 1)"
            TC_INFO=(${TCMALLOC//=>/})
            if [[ ! -z "${TC_INFO}" ]]; then
                echo "Check TCMalloc: ${TC_INFO}"
                # Determine if the library is linked to libpthread and resolve undefined symbol: pthread_key_create
                if [ $(echo "$libc_vernum < $libc_v234" | bc) -eq 1 ]; then
                    # glibc < 2.34 pthread_key_create into libpthread.so. check linking libpthread.so...
                    if ldd ${TC_INFO[2]} | grep -q 'libpthread'; then
                        echo "$TC_INFO is linked with libpthread,execute LD_PRELOAD=${TC_INFO[2]}"
                        # set fullpath LD_PRELOAD (To be on the safe side)
                        export LD_PRELOAD="${TC_INFO[2]}"
                        break
                    else
                        echo "$TC_INFO is not linked with libpthread will trigger undefined symbol: pthread_Key_create error"
                    fi
                else
                    # Version 2.34 of libc.so (glibc) includes the pthread library IN GLIBC. (USE ubuntu 22.04 and modern linux system and WSL)
                    # libc.so(glibc) is linked with a library that works in ALMOST ALL Linux userlands. SO NO CHECK!
                    echo "$TC_INFO is linked with libc.so,execute LD_PRELOAD=${TC_INFO[2]}"
                    # set fullpath LD_PRELOAD (To be on the safe side)
                    export LD_PRELOAD="${TC_INFO[2]}"
                    break
                fi
            fi
        done
        if [[ -z "${LD_PRELOAD}" ]]; then
            printf "\e[1m\e[31mCannot locate TCMalloc. Do you have tcmalloc or google-perftool installed on your system? (improves CPU memory usage)\e[0m\n"
        fi
    fi
}

KEEP_GOING=1
export SD_WEBUI_RESTART=tmp/restart
while [[ "$KEEP_GOING" -eq "1" ]]; do
    if [[ ! -z "${ACCELERATE}" ]] && [ ${ACCELERATE}="True" ] && [ -x "$(command -v accelerate)" ]; then
        printf "\n%s\n" "${delimiter}"
        printf "Accelerating launch.py..."
        printf "\n%s\n" "${delimiter}"
        prepare_tcmalloc
        accelerate launch --num_cpu_threads_per_process=6 "${LAUNCH_SCRIPT}" "$@"
    else
        printf "\n%s\n" "${delimiter}"
        printf "Launching launch.py..."
        printf "\n%s\n" "${delimiter}"
        prepare_tcmalloc
        "${python_cmd}" -u "${LAUNCH_SCRIPT}" "$@"
    fi

    if [[ ! -f tmp/restart ]]; then
        KEEP_GOING=0
    fi
done
