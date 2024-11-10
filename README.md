# docker-gtypist-run-script

I have written the `gtypist.sh` shell script just to make running *gtypist* (a typing tutor software) in the docker container easier. Maybe someone else will find it useful too.
The script should work well with various Linux distros (at least with those having Bash as a shell), and also with WSL on Windows (the init process needs to be `systemd` though). The only thing you need to take care of is to have Docker installed and operational there.

The script is based on Dockerfile taken from [docker-gtypist](https://github.com/cizra/docker-gtypist) project.
