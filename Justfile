build:
	sudo docker build -t programming-toolkit -f Dockerfile .

init-subs:
	git submodule update --init --recursive

update-subs:
    git submodule update --remote --merge
    git add ptk-admin-panel