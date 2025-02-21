build-local:
	docker build -t python-toolkit -f Dockerfile_local_v2 .

build-remote:
	docker build -t python-toolkit -f Dockerfile_remote .