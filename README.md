## NOTE: This is a personal toolkit container and a work in progress. My goal is to eventually make this easy for other people to use.

VERSION: 0.1.0   
OS BASE: Debian Slim   

### Python Toolkit Container

Based on Debian Slim, includes UV for Python.   
Note that there is no Python environment or global python install in
the container. This is meant to be for folks who prefer to keep the environment
folder inside the project folder. Mount your home/projects folder into the
container's /root/workspace folder. Also note that this container does not have any
persistence of its own - That is by design. I might consider adding container
persistence in the future, but the point is for your toolbox to be version controlled.

### USAGE

Connect to the container locally with:   
`docker exec -it <container_id> /bin/bash`

VS Code can also detect the container locally and connect to it.   
Use the 'Attach to Running Container' option in the Remote Containers extension.

### BEFORE BUILDING

Use the Justfile or Makefile to build the container.

Make sure you have a .dockerignore that contains (assuming you're using git):
```
.git
.gitignore
Dockerfile*
anything else you need to ignore.
```
You can choose which python versions you wish to install by changing the PYTHON_VERSIONS argument:   
`docker build --build-arg PYTHON_VERSIONS="3.10 3.11 3.12 3.13" -t python-toolkit`   
(NOTE TO SELF: UPDATE THIS IN THE JUSTFILE)   

By default it installs 3.10, 3.11, 3.12, and 3.13.

# SSH Setup For remote access

#### The sshd_config should include the following:
```
Port 2222
PermitRootLogin no 
PasswordAuthentication no   
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
AllowUsers devuser
LogLevel VERBOSE
```
#### id_rsa_devuser.pub is the public key for the SSH authentication. To generate one:

On your local machine, run:   
`ssh-keygen -t rsa -b 4096 -f id_rsa_devuser`

This creates two files:   
`id_rsa_devuser` (private key) — Copy this to your local ~/.ssh folder.   
`id_rsa_devuser.pub` (public key) — This will be copied into the authorized_keys file.   

The .pub file looks like this:   
`ssh-rsa AAAAB3...rest_of_the_key... user@host`   

To connect to the container, you’ll need the private key (id_rsa_devuser) on your local machine. Use:   
`ssh -i id_rsa_devuser devuser@<container_ip>`   

If you use an app that reads from ~/.ssh/config, you can add the following to it:
```
Host python-toolkit
    HostName <container_ip>
    User devuser
    IdentityFile ~/.ssh/id_rsa_devuser
    Port 2222
```
(NOTE to self: Consider using Docker Secrets for more pro setup)