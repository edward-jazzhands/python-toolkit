#!/bin/bash

# runs the python welcome script
# this will get developed to be interactive with time
(cd ~/.py_help && uv run main.py)

# start the bash shell
exec /usr/bin/bash