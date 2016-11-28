#!/usr/bin/env bash

## Functions

log_info() {
    echo "[INFO] $*"
}

log_err() {
    echo "[ERROR] $*" >&2
}

_atexit() {
    RETVAL=$?
    trap true INT TERM EXIT

    if [ $RETVAL -ne 0 ]; then
        log_err "Execution failed"
    else
        log_info "Execution successful"
    fi
    return $RETVAL
}

## Main

[ -n "$DEBUG" ] && set -x

LUA_VERSION=$(lua -v 2>&1)
if [[ $? -ne 0 ]]; then
    log_err "No lua interpreter present"
    exit $?
fi
if [[ ! $LUA_VERSION =~ [Lua\ 5\.1] ]]; then
    log_err "Lua version 5.1 is required"
    exit 1
fi

lua5.1 -e "require('lpeg')" > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
    log_err "lua-lpeg is required (run apt-get install lua-lpeg)"
    exit 1
fi

lua5.1 -e "require('cjson')" > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
    log_err "lua-cjson is required (run apt-get install lua-cjson)"
    exit 1
fi

for pgm in "cmake wget curl"; do
    which $pgm > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        log_err "$pgm is required (run apt-get install $pgm)"
        exit 1
    fi
done

if [[ ! -f /usr/lib/x86_64-linux-gnu/liblua5.1.so ]]; then
    log_err "package liblua5.1-0-dev is not installed (run apt-get install liblua5.1-0-dev)"
    exit 1
fi

set -e

curl -s -o lua/mocks/annotation.lua "https://raw.githubusercontent.com/mozilla-services/heka/versions/0.10/sandbox/lua/modules/annotation.lua"
curl -s -o lua/mocks/anomaly.lua "https://raw.githubusercontent.com/mozilla-services/heka/versions/0.10/sandbox/lua/modules/anomaly.lua"
curl -s -o lua/mocks/date_time.lua "https://raw.githubusercontent.com/mozilla-services/lua_sandbox/97331863d3e05d25131b786e3e9199e805b9b4ba/modules/date_time.lua"
curl -s -o lua/mocks/inspect.lua "https://raw.githubusercontent.com/kikito/inspect.lua/master/inspect.lua"

CBUF_COMMIT="bb6dd9f88f148813315b5a660b7e2ba47f958b31"
CBUF_TARBALL_URL="https://github.com/mozilla-services/lua_circular_buffer/archive/${CBUF_COMMIT}.tar.gz"
CBUF_DIR="/tmp/lua_circular_buffer-${CBUF_COMMIT}"
CBUF_SO="${CBUF_DIR}/release/circular_buffer.so"
if [[ ! -f "${CBUF_SO}" ]]; then
    rm -rf ${CBUF_DIR}
    wget -qO - ${CBUF_TARBALL_URL} | tar -zxvf - -C /tmp
    (cd ${CBUF_DIR} && mkdir release && cd release && cmake -DCMAKE_BUILD_TYPE=release .. && make)
    cp ${CBUF_SO} ./
fi

for t in $(ls lua/test_*.lua); do
    lua5.1 $t
done

trap _atexit INT TERM EXIT
