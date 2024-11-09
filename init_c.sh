#!/bin/bash

# Function to create config directory and initial config file
create_config() {
    mkdir -p config
    cat > config/mf.cfg << EOF
{
    "compiler": "gcc",
    "output_name": "program"
}
EOF
}

# Function to show help
show_help() {
    cat << 'EOF'
Usage: mkinit [options]
Creates a Makefile in the current directory.

Options:
    -h, --help      Show this help message
    -c, --compiler  Set initial compiler (default: gcc)
    -n, --name      Set initial output name (default: program)

Example:
    mkinit -c clang -n myproject
EOF
}

# Parse command line arguments
COMPILER="gcc"
OUTPUT_NAME="program"

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -c|--compiler)
            COMPILER="$2"
            shift 2
            ;;
        -n|--name)
            OUTPUT_NAME="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Create the Makefile
cat > Makefile << 'EOF'
# Read configuration values
def_compiler := $(shell cat config/mf.cfg | jq -r .compiler)
def_output_name := $(shell cat config/mf.cfg | jq -r .output_name)

# Shared flags and directories
BUILD_DIR := build
SRC_DIR := src
CONFIG_DIR := config
INCLUDE_DIR := src/include

# Compiler flags for different builds
DEBUG_FLAGS := -g
RELEASE_FLAGS := -O3

# Default target
default: prepare
        $(def_compiler) -o $(BUILD_DIR)/$(def_output_name) $(SRC_DIR)/*

# Debug build
dbg: prepare
        $(def_compiler) $(DEBUG_FLAGS) -o $(BUILD_DIR)/dbg_$(def_output_name) $(SRC_DIR)/*

# Release build
release: prepare
        $(def_compiler) $(RELEASE_FLAGS) -o $(BUILD_DIR)/release_$(def_output_name) $(SRC_DIR)/*

# Update config file - handles both compiler and name in one command
config:
        @if [ -n "$(compiler)" ] || [ -n "$(name)" ]; then \
                cat $(CONFIG_DIR)/mf.cfg | jq \
                        $(if $(compiler),'.compiler = "$(compiler)"') \
                        $(if $(name),'.output_name = "$(name)"') \
                        > $(CONFIG_DIR)/mf.cfg.tmp && \
                mv $(CONFIG_DIR)/mf.cfg.tmp $(CONFIG_DIR)/mf.cfg; \
        fi

# Create necessary directories
prepare:
        @mkdir -p $(BUILD_DIR)

# Clean build artifacts
clean:
        @rm -rf $(BUILD_DIR)

# Initialize config file if it doesn't exist
init:
        @mkdir -p $(CONFIG_DIR)
        @[ -f $(CONFIG_DIR)/mf.cfg ] || echo '{"compiler":"gcc","output_name":"program"}' > $(CONFIG_DIR)/mf.cfg

.PHONY: default dbg release config prepare clean init
EOF

# Create config directory and initial config file
create_config

# Create initial directory structure
mkdir -p src/include build

# Create an example source file
cat > src/main.c << 'EOF'
#include <stdio.h>

int main() {
    printf("Hello, World!\n");
    return 0;
}
EOF

# Create an example header file
cat > src/include/main.h << 'EOF'
#pragma once

//header things...
EOF

# Update config with command line values
if [ "$COMPILER" != "gcc" ] || [ "$OUTPUT_NAME" != "program" ]; then
    cat > config/mf.cfg << EOF
{
    "compiler": "$COMPILER",
    "output_name": "$OUTPUT_NAME"
}
EOF
fi

echo "Project initialized successfully!"
echo "Directory structure created:"
echo "  ./src/                  - Source files"
echo "  ./src/include/  - Header files"
echo "  ./build/                - Build output"
echo "  ./config/               - Build configuration"
echo ""
echo "Usage:"
echo "  make     - Regular build"
echo "  make dbg     - Debug build"
echo "  make release - Release build"
echo "  make clean   - Clean build files"
echo ""
echo "To change settings:"
echo "  make config compiler=gcc name=myprogram"
