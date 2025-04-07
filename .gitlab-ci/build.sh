#! /bin/bash

set -ex
set -o pipefail

cidir=$(dirname $0)
[ -f ${cidir}/fcenv ] && . ${cidir}/fcenv

case "$OSTYPE" in
    msys) MyPWD=$(pwd -W) ;;
    *BSD) PATH=$PATH:/usr/local/bin ;&
    *) MyPWD=$(pwd) ;;
esac
enable=()
disable=()
distcheck=0
enable_install=1
disable_check=0
clean_build=1
cross=0
buildsys="meson"
type="shared"
arch=""
buildopt=()
SRCDIR=$MyPWD
export MAKE=${MAKE:-make}
export BUILD_ID=${BUILD_ID:-fontconfig-$$}
export PREFIX=${PREFIX:-$MyPWD/prefix}
export BUILDDIR=${BUILDDIR:-$MyPWD/build}

if [ "x$FC_DISTRO_NAME" = "x" ]; then
    . /etc/os-release || :
    FC_DISTRO_NAME=$ID
fi
if [ "x$FC_DISTRO_NAME" = "x" ]; then
    echo "***"
    echo "*** Unable to detect OS. cross-compiling may not work. Please consider setting FC_DISTRO_NAME"
    echo "***"
    sleep 3
fi

while getopts a:cCe:d:hINs:t:X: OPT
do
    case $OPT in
        'a') arch=$OPTARG ;;
        'c') distcheck=1 ;;
        'C') disable_check=1 ;;
        'e') enable+=($OPTARG) ;;
        'd') disable+=($OPTARG) ;;
        'I') enable_install=0 ;;
        'N') clean_build=0 ;;
        's') buildsys=$OPTARG ;;
        't') type=$OPTARG ;;
        'X') backend=$OPTARG ;;
        'h')
            echo "Usage: $0 [-a ARCH] [-c] [-C] [-e OPT] [-d OPT] [-h] [-I] [-N] [-s BUILDSYS] [-t BUILDTYPE] [-X XMLBACKEND]"
            exit 1
            ;;
    esac
done
case x"$FC_BUILD_PLATFORM" in
    'xmingw') cross=1 ;;
    'xandroid') cross=1 ;;
    *) cross=0 ;;
esac

env
r=0

clean_exit() {
    rc=$?
    trap - INT TERM ABRT EXIT
    if [ "x$TASK" != "x" ]; then
        echo "Aborting from \"$TASK\" with the exit code $rc"
    fi
    mv /tmp/fc-build.log . || :
    exit $rc
}

trap clean_exit INT TERM ABRT EXIT

if [ x"$buildsys" == "xautotools" ]; then
    for i in "${enable[@]}"; do
        buildopt+=(--enable-$i)
    done
    for i in "${disable[@]}"; do
        buildopt+=(--disable-$i)
    done
    case x"$backend" in
        'xexpat')
            buildopt+=(--disable-libxml2)
            ;;
        'xlibxml2')
            buildopt+=(--enable-libxml2)
            ;;
    esac
    case x"$type" in
        'xshared')
            buildopt+=(--enable-shared)
            buildopt+=(--disable-static)
            ;;
        'xstatic')
            buildopt+=(--disable-shared)
            buildopt+=(--enable-static)
            ;;
        'both')
            buildopt+=(--enable-shared)
            buildopt+=(--enable-static)
            ;;
    esac
    if [ $cross -eq 1 -a -n "$arch" ]; then
        buildopt+=(--host=$arch)
        if [ ! -f .gitlab-ci/${FC_DISTRO_NAME}-cross.sh ]; then
            echo "No ${FC_DISTRO_NAME}-cross.sh available"
            exit 1
        fi
        . .gitlab-ci/${FC_DISTRO_NAME}-cross.sh
    fi
    if [ $clean_build -eq 1 ]; then
        rm -rf "$BUILDDIR" "$PREFIX" || :
        mkdir "$BUILDDIR" "$PREFIX"
    fi
    cd "$BUILDDIR"
    TASK="autogen.sh"
    ../autogen.sh --prefix="$PREFIX" --disable-cache-build ${buildopt[*]} 2>&1 | tee /tmp/fc-build.log
    TASK="make"
    $MAKE V=1 2>&1 | tee -a /tmp/fc-build.log
    if [ $disable_check -eq 0 ]; then
        TASK="make check"
        $MAKE check V=1 2>&1 | tee -a /tmp/fc-build.log
    fi
    if [ $enable_install -eq 1 ]; then
        TASK="make install"
        $MAKE install V=1 2>&1 | tee -a /tmp/fc-build.log
    fi
    if [ $distcheck -eq 1 ]; then
        TASK="make distcheck"
        $MAKE distcheck V=1 2>&1 | tee -a /tmp/fc-build.log
    fi
elif [ x"$buildsys" == "xmeson" ]; then
    TASK="pip install"
    pip install meson
#   tomli not required for Python >= 3.11
    pip install tomli
    pip install pytest pytest-tap
    for i in "${enable[@]}"; do
        buildopt+=(-D$i=enabled)

        # Update bindgen on Fontations builds to improve support for constants in fcint.h
        if [[ "$i" == "fontations" ]]; then
            TASK="cargo install"
            cargo install bindgen-cli
            # Prepend the cargo bin directory to PATH
            if [[ -d "$HOME/.cargo/bin" ]]; then
                export PATH="$HOME/.cargo/bin:$PATH"
                echo "Cargo bin directory added to PATH."
            else
                echo "Cargo bin directory not found."
            fi
        fi
    done
    TASK=
    for i in "${disable[@]}"; do
        buildopt+=(-D$i=disabled)
    done
    case x"$backend" in
        'xexpat')
            buildopt+=(-Dxml-backend=expat)
            ;;
        'xlibxml2')
            buildopt+=(-Dxml-backend=libxml2)
            ;;
    esac
    if [ $cross -eq 1 -a -n "$arch" ]; then
        buildopt+=(--cross-file)
        buildopt+=(.gitlab-ci/$arch.txt)
        if [ ! -f .gitlab-ci/$FC_DISTRO_NAME-cross.sh ]; then
            echo "No $FC_DISTRO_NAME-cross.sh available"
            exit 1
        fi
        . .gitlab-ci/$FC_DISTRO_NAME-cross.sh
    fi
    buildopt+=(--default-library=$type)
    if [ $clean_build -eq 1 ]; then
        rm -rf $BUILDDIR || :
    fi
    TASK="meson setup"
    meson setup --prefix="$PREFIX" -Dnls=enabled -Dcache-build=disabled -Diconv=enabled ${buildopt[*]} "$BUILDDIR" 2>&1 | tee /tmp/fc-build.log
    TASK="meson compile"
    meson compile -v -C "$BUILDDIR" 2>&1 | tee -a /tmp/fc-build.log
    if [ $disable_check -eq 0 ]; then
        TASK="meson test"
        meson test -v -C "$BUILDDIR" 2>&1 | tee -a /tmp/fc-build.log
    fi
    if [ $enable_install -eq 1 ]; then
        TASK="meson install"
        meson install -C "$BUILDDIR" 2>&1 | tee -a /tmp/fc-build.log
    fi
    if [ $distcheck -eq 1 ]; then
        TASK="meson dist"
        meson dist -C "$BUILDDIR" 2>&1 | tee -a /tmp/fc-build.log
    fi
fi
TASK=
exit $r
