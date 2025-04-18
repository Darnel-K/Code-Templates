#!/bin/bash
# #################################################################################################################### #
# Filename: \Shell Script\Generic\ShellScript.sh                                                                       #
# Repository: Code-Templates                                                                                           #
# Created Date: Tuesday, April 15th 2025, 11:36:45 PM                                                                  #
# Last Modified: Friday, April 18th 2025, 10:48:01 PM                                                                  #
# Original Author: Darnel Kumar                                                                                        #
# Author Github: https://github.com/Darnel-K                                                                           #
#                                                                                                                      #
# This code complies with: https://gist.github.com/Darnel-K/8badda0cabdabb15359350f7af911c90                           #
#                                                                                                                      #
# License: GNU General Public License v3.0 only - https://www.gnu.org/licenses/gpl-3.0-standalone.html                 #
# Copyright (c) 2025 Darnel Kumar                                                                                      #
#                                                                                                                      #
# This program is free software: you can redistribute it and/or modify                                                 #
# it under the terms of the GNU General Public License as published by                                                 #
# the Free Software Foundation, either version 3 of the License, or                                                    #
# (at your option) any later version.                                                                                  #
#                                                                                                                      #
# This program is distributed in the hope that it will be useful,                                                      #
# but WITHOUT ANY WARRANTY; without even the implied warranty of                                                       #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                                                        #
# GNU General Public License for more details.                                                                         #
# #################################################################################################################### #

SCRIPT_NAME=""

function init {

}

function initTerminal {
    tput clear
    SCRIPT_NAME="Generic.BashScript.${SCRIPT_NAME// /}"

    # Check if the current user is the system user (root)
    [ "$(id -u)" -eq 0 ] && IS_SYSTEM=true || IS_SYSTEM=false

    # Check if the current user is an administrator (has sudo privileges)
    [ sudo -n true ] 2>/dev/null && IS_ADMIN=true || IS_ADMIN=false

    # Get the name of the executing user
    EXEC_USER=$(whoami)

    # Get the process ID of the current script
    PID=$$

}

function initWorkingDir {
    ROOT_DIR="/opt/ABYSS.ORG.UK"
    [ -d $ROOT_DIR ] || mkdir -p $ROOT_DIR
    LOG_DIR="/opt/ABYSS.ORG.UK/logs"
    [ -d $LOG_DIR ] || mkdir -p $LOG_DIR
    INTUNE_DIR="/opt/ABYSS.ORG.UK/Intune"
    [ -d $INTUNE_DIR ] || mkdir -p $INTUNE_DIR
    INTUNE_RESOURCES_DIR="/opt/ABYSS.ORG.UK/Intune/Resources"
    [ -d $INTUNE_RESOURCES_DIR ] || mkdir -p $INTUNE_RESOURCES_DIR
    INTUNE_APPLICATIONS_DIR="/opt/ABYSS.ORG.UK/Intune/Applications"
    [ -d $INTUNE_APPLICATIONS_DIR ] || mkdir -p $INTUNE_APPLICATIONS_DIR
    [ getent group "root" ] >/dev/null 2>&1 && chown -R root:root $ROOT_DIR
    [ getent group "wheel" ] >/dev/null 2>&1 && chown -R root:wheel $ROOT_DIR
    chmod -R 755 $ROOT_DIR
    chmod -R 644 $LOG_DIR
    chmod -R 755 $INTUNE_DIR
    chmod -R 755 $INTUNE_RESOURCES_DIR
    chmod -R 755 $INTUNE_APPLICATIONS_DIR
}

function initLog {
    LOG_FILE=$SCRIPT_NAME"$(date +"%Y%m%d-%H%M%S").log"
    exec 3>&1 1>"$LOG_DIR/$LOG_FILE" 2>&1
    trap "echo 'ERROR: An error occurred during execution, check log $LOG_FILE for details.' >&3" ERR
    trap '{ set +x; } 2>/dev/null; echo -n "[$(date -Is)]  "; set -x' DEBUG
}

initTerminal
initWorkingDir
initLog
init
