#!/bin/bash
# #################################################################################################################### #
# Filename: \Shell Script\Generic\BashScript.sh                                                                        #
# Repository: Code-Templates                                                                                           #
# Created Date: Tuesday, April 15th 2025, 11:36:45 PM                                                                  #
# Last Modified: Saturday, April 19th 2025, 6:23:46 PM                                                                 #
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

# Script functions

function init {
    # Script initialisation function. This function contains the main code and calls to other functions.
    # This function is called automatically at the bottom of the script
    # Append ">&3" to the end of an echo line to print to the console

}

#################################
#                               #
#   REQUIRED SCRIPT VARIABLES   #
#                               #
#################################

# DO NOT REMOVE THESE VARIABLES
# DO NOT LEAVE THESE VARIABLES BLANK

SCRIPT_NAME="" # This is used in the window title and the log name and entries.

################################################
#                                              #
#   DO NOT EDIT ANYTHING BELOW THIS MESSAGE!   #
#                                              #
################################################

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

function initTerminal {
    tput clear
    SCRIPT_NAME="Generic.BashScript.${SCRIPT_NAME// /}"
    [ "$(id -u)" -eq 0 ] && IS_SYSTEM=true || IS_SYSTEM=false
    [ sudo -n true ] 2>/dev/null && IS_ADMIN=true || IS_ADMIN=false
    EXEC_USER=$(whoami)
    PID=$$
    SCRIPT_FILENAME=$(basename "$0")
    len=($((${#SCRIPT_NAME} + 13)) $((${#SCRIPT_FILENAME} + 10)) 20 42 29 40 63 62 61 44)
    for i in "${len[@]}"; do
        if ((i > len_max)); then
            len_max=$i
        fi
    done

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
echo "Script PID: $PID" >&3
echo "Exec User: $EXEC_USER" >&3
init
