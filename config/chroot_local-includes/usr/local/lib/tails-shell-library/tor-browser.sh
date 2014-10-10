#!/bin/sh

TBB_INSTALL=/usr/local/lib/tor-browser
TBB_PROFILE=/etc/tor-browser/profile
TBB_EXT="${TBB_INSTALL}/extensions"

exec_firefox() {
    LD_LIBRARY_PATH="${TBB_INSTALL}"/Browser
    export LD_LIBRARY_PATH
    exec "${TBB_INSTALL}"/Browser/firefox "${@}"
}
