#! /bin/bash

##################################################################################
# This script builds and runs gtypist Docker container 
# that based on a Dockerfile.
##################################################################################

SCRIPT_PATH=$(dirname $(realpath $0))    # An absolute path leading to this script
IMAGE_TAG='gtypist:latest'      # your favourite gtypist docker image tag
CONTAINER_NAME='gtypist'        # your favourite gtypist docker container name 
DOCKER_ACTIVE_AT_START='active' # A variable helpful to control if Docker service might need to be stopped after
                                # gtypist container had been stopped.

##################################################################################
# This script uses Yannek-JS Bash library; 
# it checks whether this library (bash-scripts-lib.sh) is present; 
# if not, the script is quitted.
# You can download this library from https://github.com/Yannek-JS/bash-scripts-lib
##################################################################################
if [ -f ${SCRIPT_PATH}/bash-scripts-lib.sh ]
then
    source ${SCRIPT_PATH}/bash-scripts-lib.sh
else
    echo -e "\n Failure ! 'bash-script-lib.sh' is missing. Download it from 'https://github.com/Yannek-JS/bash-scripts-lib' into directory where this script is located.\n"
    exit
fi
##################################################################################


function say_hello() {
    draw_line ${YELLOW}
    echo -e "\nThis script builds and runs ${ORANGE}gtypist${SC} in a Docker container."
    echo -e 'If you are not a root user (that is OK), or not in the docker group,'
    echo -e "it may need to elevate the privileges for running ${BLUE}docker${SC} and/or ${BLUE}systemctl${SC} commands."
    draw_line ${YELLOW} ${SC}
}


function is_docker_user() {
    # checks if user that runs the script is belonging to the docker user group.
    # It returns '1' if so.
    if $(id | grep --silent --word-regexp 'docker'); then echo '1'; else echo '0'; fi
}


function get_docker_command() {
    # returns 'docker' command if the user running the script is in the 'docker' user group, 
    # and 'sudo docker', if they are not.
    if [ $(is_docker_user) -eq 1 ] ; then echo 'docker'; else echo 'sudo docker'; fi
}


function is_docker_running() {

    systemctl status docker > /dev/null 2>&1
    dockerStatus=$?
    # When docker.service is inactive the status check returns 3.
    if [ $dockerStatus -ne 0 ] && [ $dockerStatus -ne 3 ]
    then
        echo -e "${LRED}\nEither the OS init process is not ${BLUE}systemd${LRED} or ${BLUE}Docker${LRED} is not installed. Please verify that.${SC}"
        echo -e "${LRED}\n\nThis script works just on the platforms where ${BLUE}systemd${LRED} is an init process and ${BLUE}systemctl${LRED} tool is present.${SC}"
        echo -e "${LRED}However, you can try to modify this script to get ${ORANGE}gtypist${LRED} running with another init process.${SC}\n"
        quit_now
    fi 

    # checks if docker is running
    systemctl is-active docker.service > /dev/null 2>&1
    if [ $? -ne 0 ]
    then
        elevate_privileges '\nDocker service seems to be inactive at the moment. To start it, your privileges need to be elevated...'
        echo -e -n '\n Starting Docker service.....'
        sudo systemctl start docker > /dev/null 2>&1
        complete_message $? '.' "${LRED}failed${SC}\n" 'EXIT'
        systemctl is-active docker.service > /dev/null 2>&1
        complete_message $? "${LGREEN}ok${SC}\n" "${LRED}failed${SC}\n" 'EXIT'
        DOCKER_ACTIVE_AT_START='inactive'
    else
        DOCKER_ACTIVE_AT_START='active'
    fi
}


function run_gtypist() {
    # It runs gtypist Docker container. If container image is not available, 
    # it builds it using Dockerfile 
    # It checks if the user who runs the script belongs to the 'docker' user group. If not, it elevates their rights.
    if [ $(is_docker_user) -ne 1 ]
    then
        elevate_privileges "\nTo build a Docker image and/or run a Docker container, your privileges need to be elevated..."
    fi
    if $($dockerCommand container list --all | grep --quiet --regexp "${CONTAINER_NAME}")
    then
        echo -e -n "\nRunning ${BLUE}${CONTAINER_NAME}${SC} docker container....."
        $dockerCommand container start ${CONTAINER_NAME} > /dev/null 2>&1
        complete_message $? ".\n" "${LRED}failed${SC}\n" 'EXIT'
        $dockerCommand container exec --tty --interactive ${CONTAINER_NAME} /gtypist/bin/gtypist
        complete_message $? "${LGREEN}Done${SC}\n" "${LRED}failed${SC}\n" 'EXIT'
    else
        if ! $($dockerCommand image list | \
            grep --quiet --regexp "$(echo ${IMAGE_TAG} | gawk --field-separator ':' '{print $1}')")
        then
            echo -e "\nStarting buildin Docker image ${ORANGE}${IMAGE_TAG}${SC}....."
            sleep 1
            $dockerCommand image build --file ./Dockerfile --tag ${IMAGE_TAG} .
            complete_message $? "${LGREEN}Docker image built OK${SC}\n" "${LRED}Docker image build failed${SC}\n" 'EXIT'
        fi
        echo -e -n "\nRunning ${BLUE}${CONTAINER_NAME}${SC} docker container.....\n"
        $dockerCommand container run --tty --interactive --name ${CONTAINER_NAME} ${IMAGE_TAG}
        complete_message $? "${LGREEN}Done${SC}\n" "${LRED}failed${SC}\n" 'EXIT'
    fi
}


function housekeeping {
    # It stops gtypist docker container, and docker itself (if it has been started by this script)
    # It checks if the user who runs the script belongs to the 'docker' user group. If not, it elevates their rights.
    if [ $(is_docker_user) -ne 1 ]
    then
        elevate_privileges "\nTo stop ${BLUE}${CONTAINER_NAME}${SC} docker container, your privileges need to be elevated..."
    fi
    echo -e -n "\nStopping ${BLUE}${CONTAINER_NAME}${SC} docker container....."
    $dockerCommand container stop ${CONTAINER_NAME} > /dev/null 2>&1
    complete_message $? "${LGREEN}ok${SC}\n" "${LRED}failed${SC}\n"
    if [ "${DOCKER_ACTIVE_AT_START}" == 'inactive' ]
    then
        draw_line ${YELLOW}
        echo -e "\nDocker service had been inactive before ${ORANGE}gtypist${SC} was started."
        echo 'Do you want to continue to stop it now ?'
        yes_or_not        
        elevate_privileges '\nTo stop Docker, your privileges need to be elevated...'
        echo -e -n '\nStopping Docker socket.....'
        sudo systemctl stop docker.socket > /dev/null 2>&1
        complete_message $? "${LGREEN}ok${SC}\n" "${LRED}failed${SC}\n"
        echo -e -n '\nStopping Docker service.....'
        sudo systemctl stop docker.service > /dev/null 2>&1
        complete_message $? "${LGREEN}ok${SC}\n" "${LRED}failed${SC}\n"       
    fi
}


say_hello           # some info for the users
dockerCommand=$(get_docker_command)   # gets 'docker' or 'sudo docker' command
is_docker_running   # checks if docker service is running, and starts it if it is stopped
run_gtypist         # runs gtypist (if it is needed, builds image, and/or starts gtypist container)
housekeeping        # stops gtypist docker container, and docker itself (if it has been started by this script)
quit_now
