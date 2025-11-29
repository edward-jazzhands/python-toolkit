# Programming Toolkit Roadmap

[X] Set up S6-Overlay as container service manager
[X] Create build stage to make image smaller
[X] Configure password as ENV variable
[X] Configure $PUID/$PGID as ENV variables using init script
[X] Configure all tools to move their install and data folders outside of the home dir
[X] Install Code-Server
[X] Install PTK Admin Panel
[-] Turn PTK Admin Panel and PTK Help into built python packages
[-] Make S6-Overlay mark container as unhealthy if it fails to start
[-] Make init script check if default configs exist before copying (for bind mounts)
[-] Prepare for bind mounting the entire home dir
[-] Fix problems with GNU Pass
[-] Fix PATH for Golang
[-] Switch installer for S6 to curl
[-] Upload Docker image to dockerhub when ready
[-] Provide commands for running directly with docker and docker-compose
