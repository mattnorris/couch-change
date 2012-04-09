#!/bin/bash
# Title:        install-couchdb.sh
# Description:  Installs the latest CouchDB version from source, 
#               not from a repository. 
# Author:       Matthew Norris
# Reference:    https://github.com/iriscouch/build-couchdb
#               http://comments.gmane.org/gmane.comp.db.couchdb.user/16292
#               Uninstalling from Ubuntu's repository: 
#                   http://serverfault.com/questions/348044
#                   http://stackoverflow.com/questions/8783621
# Dependencies: git
#

################################################################################
# Packages  
################################################################################

PKGS_COUCH="make gcc zlib1g-dev libssl-dev rake"

################################################################################
# Default locations  
################################################################################

DST_DIR=$HOME/dev/tools

################################################################################
# Helper functions 
################################################################################

# Prints the given error message and exits.
function errorMessage() {
    echo -e "Error: $1. Type '`basename $0` -h' for usage and options."
    exit 1
}

# Prints the given warning message and exits.
function warningMessage() {
    echo -e "Warning: $1."
    exit 2
}

# Prints this script's usage and exists. 
function outputUsage() {
    echo "Usage: `basename $0` [options...]"
    echo "Options:"
    echo "  -h/--help     Prints this message"
    echo "  -d/--dst      Directory to install CouchDB"
    echo "  -r/--remove   Removes CouchDB from system"
    echo "                If CouchDB is installed anywhere besides the "
    echo "                default directory, specify it using the -d option."
    
    exit 1
}

################################################################################
# Installation functions 
################################################################################

# Installs packages and sets up directories and files. 
function installPackages() {
    echo "Installing `basename $0` tools & libraries..."
    sudo apt-get install $PKGS_COUCH -y
    mkdir -p $DST_DIR
    cd $DST_DIR
    git clone git://github.com/iriscouch/build-couchdb
    cd build-couchdb
    git submodule init
    git submodule update
    
    # Wait for the update to finish before building. 
    # http://stackoverflow.com/questions/356100
    wait
    rake 

    echo "Done!"
    echo "cd into '$DST_DIR/build-couchdb/build/bin' and run 'couchdb' to relax and start using CouchDB."
    
    # TODO: Maybe install couchapp too. 
    # http://guide.couchdb.org/draft/managing.html#installing
    # http://couchapp.org/page/installing
    
    exit 0
}

# Removes CouchDB-specific directories and files created. However, all of the 
# packages installed (rather, upgraded) are kept. Other packages are dependent 
# on these files as well, so we don't want to remove them. 
function removePackages() {
    echo "Removing `basename $0` tools & libraries..." 
    rm -fr $DST_DIR/build-couchdb/
    echo "Done." 
    
    # Note: If we were to install from Ubuntu's repository using apt-get, 
    # we'd have to be sure to purge ALL files or we'd see errors when 
    # reinstalling. 
    #
    # http://serverfault.com/a/348082/106402
    # http://stackoverflow.com/questions/8783621/
    
    exit 0
}

################################################################################
# Command line processing
################################################################################

# Parse the command line arguments. 
while [ "$#" -gt "0" ]; do
    case "$1" in
        -d|--dst)
            shift 1 
            DST_DIR="$1" 
            shift 1 
            ;;
        -r|--remove)
            shift 1
            removePackages
            ;;
        -h|--help)
            outputUsage
            ;;
        -*|--*)
            errorMessage "Unknown option $1"
            ;;
        *)
            errorMessage "Unknown parameter $1"
            ;;
    esac
done

################################################################################
# Main
################################################################################

echo "Executing `basename $0`..."
installPackages
echo "Done."

