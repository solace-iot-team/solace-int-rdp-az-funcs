#!/bin/bash
# ---------------------------------------------------------------------------------------------
# Copyright (c) 2020, Solace Corporation, Ricardo Gomez-Ulmke (ricardo.gomez-ulmke@solace.com).
# All rights reserved.
# Licensed under the MIT License.
# ---------------------------------------------------------------------------------------------

###############################################################################################
# sets the env for the project
#
# call: source ./run.project-env.sh
#

export AS_SAMPLES_SCRIPT_NAME=$(basename $(test -L "$0" && readlink "$0" || echo "$0"));
export AS_SAMPLES_SCRIPT_PATH=$(cd $(dirname "$0") && pwd);

export AS_SAMPLES_PROJECT_HOME="$AS_SAMPLES_SCRIPT_PATH"

# test for python interpreter
if [ -z "${ANSIBLE_PYTHON_INTERPRETER-unset}" ]; then
    echo; echo ">>> ERR: env var: ANSIBLE_PYTHON_INTERPRETER is set to the empty string. Either unset or set properly."; echo; echo;
    exit 1
fi
if [ -z "$ANSIBLE_PYTHON_INTERPRETER" ]; then
    DEFAULT="/usr/bin/python"
    echo; echo ">>> WARN: env var: ANSIBLE_PYTHON_INTERPRETER is not set. Default: $DEFAULT."
    echo ">>> Ensure this is the correct version:";
    export AS_SAMPLES_PYTHON_VERSION=$($DEFAULT --version)
    read -n 1 -p ">>> Press key to continue, CTRL-C to exit ..." x
else
  export AS_SAMPLES_PYTHON_VERSION=$($ANSIBLE_PYTHON_INTERPRETER --version)
fi

source $AS_SAMPLES_PROJECT_HOME/.lib/functions.sh

###
# The End.
