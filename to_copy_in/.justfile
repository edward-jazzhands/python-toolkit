
# The [no-cd] tag is used to tell Just that this command should
# be executed from the directory where the command is run, not from the
# directory where the justfile is located (This is a 'global' justfile)

[no-cd]
console:
	textual console -x EVENT -x SYSTEM -x WORKER

[no-cd]
console-workers:
	textual console -x EVENT -x SYSTEM

# `git reset --hard` is a destructive command that will discard all local changes.
# Use with caution, as it will permanently delete any uncommitted changes.

[no-cd]
hard-sync:
	git fetch upstream
	git checkout main
	git reset --hard upstream/main

[no-cd]
init:
	uv init --package

[no-cd]
prune-branches:
	bash $projects/.scripts/local_branch_pruner.sh

[no-cd]
diff-workflows path:
	bash $projects/.scripts/diff_workflows.sh {{path}}

test-justfile:
	@echo "Successfully accessed your global justfile."