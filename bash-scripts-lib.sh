#! /bin/bash

###############################################################
# This script contains the Bash code portions commonly 
# used in other Yannek-JS Bash projects.
#
# Visit https://github.com/Yannek-JS/bash-scripts-lib
# for the most recent script release
############################################################### 

# the colours definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
LRED='\033[1;31m'
LGREEN='\033[1;32m'
YELLOW='\033[1;33m'
SC='\033[0m' # Standard colour


function draw_line() {  
    # It draws a line made of 80 hyphens in colour specified as a parameter.
    # Parameters:
    #   $1 - a colour to set for drawing a line
    #   $2 - a colour to set after the line has been drawn
    if [ $# -eq 2 ]; then stopColour=$2; else stopColour=${SC}; fi
    if [ $# -ge 1 ]; then startColour=$1; else startColour=${SC}; fi
    echo -e $startColour
    for num in $(seq 0 79); do echo -n '-'; done
    echo -e $stopColour
}


function quit_now { # displays nice message and quit the script
    echo -e ${BLUE}'\nI am quitting now. Have a nice day.'${YELLOW}' :-)\n'${SC}
        exit
}


function yes_or_not() {  # gives you a choice: to continue or to quit this script
#echo -e '\nIf you want to continue type '${LRED}'Yes'${SC}'. Otherwise type '{LGREEN}'No'${SC}'.'
    yn='no'
    while [[ ! "${yn,,}" == "yes" ]]
    do
        echo -e -n '\nIf you want to continue type '${LRED}'Yes'${SC}'. Otherwise type '${LGREEN}'No'${SC}': '
        read yn
        if [[ "${yn,,}" == "no" ]]; then quit_now; fi
    done
}


function check_if_root() {  # checks if script is being run by a user having root privileges
    if [ ! $(id -u) -eq 0 ]
    then
        echo -e ${ORANGE}'\nYou must have a root privileges to run this script !!!'${SC}
        quit_now
    fi
}


function press_any_key() {
    echo -e -n ${ORANGE}'\n Press any key to continue...'${SC}
    read -n1 -s anyKey
}


function complete_message() {
    # It completes a message (that begins like 'Starting very important process :P ...') due to 
    # an exit code passed as $1 parameter. 
    # Parameters:
    #   $1 - an exit code
    #   $2 - a message if exit code == 0
    #   $3 - a message if exit code != 0
    #   $4 - if 'EXIT', the script is quitted
    if [ $1 -ne 0 ]
    then
        echo -e -n "$3"
        if [ "$4" == 'EXIT' ]; then quit_now; fi
    else
        echo -e -n "$2"
    fi
}


elevate_privileges() {
    # It checks if a user that runs this script has got their privileges elevated. If not, it tries to elevate it.
    # Parameters:
    #   $1 - a message for the user
    
    if [ $(id --user) -ne 0 ]
    then
        echo -e "$1"
        sudo id --user > /dev/null
    fi
    if [ $? -ne 0 ]; then quit_now; fi
}
