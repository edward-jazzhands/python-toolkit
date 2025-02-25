build-local:
	docker build -t python-toolkit -f Dockerfile_local .

sudo-build-local:
	sudo docker build -t python-toolkit -f Dockerfile_local .

build-remote:
	docker build -t python-toolkit -f Dockerfile_remote .

sudo-build-remote:
	sudo docker build -t python-toolkit -f Dockerfile_remote .	