#!/bin/bash

# Define installation directory
install_dir=/Users/william/Documents/tt09-verilog-tem

# Set environment variables
export OPENLANE_ROOT=$install_dir/tt_openlane
export PDK_ROOT=$install_dir/tt_pdk
export PDK=sky130A
export OPENLANE_TAG=2024.04.02
export OPENLANE_IMAGE_NAME=efabless/openlane:2024.04.02

# Confirm the variables are set
echo "Environment variables set:"
echo "OPENLANE_ROOT=$OPENLANE_ROOT"
echo "PDK_ROOT=$PDK_ROOT"
echo "PDK=$PDK"
echo "OPENLANE_TAG=$OPENLANE_TAG"
echo "OPENLANE_IMAGE_NAME=$OPENLANE_IMAGE_NAME"