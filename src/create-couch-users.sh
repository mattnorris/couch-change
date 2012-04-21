#!/bin/bash
# Title:        create-couch-users.sh
# Description:  Creates the given list of users in CouchDB
# Author:       matthew
# Reference:    http://tldp.org/LDP/abs/html/string-manipulation.html
#               http://tldp.org/LDP/abs/html/arrays.html
#               http://comments.gmane.org/gmane.comp.db.couchdb.user/8950
#

################################################################################
# Defaults  
################################################################################

# CouchDB's users databases are prefixed with this by default. 
USER_PREFIX="org.couchdb.user:" 
USER_DATA='{"_id":"$USER_PREFIX$USERNAME","name":"$USERNAME","type":"user","roles":[]}'

# CouchDB's attributes. 
PROTOCOL="http"
HOST="localhost"
PORT="5984"

################################################################################
# Helper functions 
################################################################################

# Prints the given error message and exits.
function errorMessage() {
    echo -e "\n\nError: $1...\n\nType '`basename $0` -h' for usage and options."
    exit 1
}

# Prints the given warning message and exits.
function warningMessage() {
    echo -e "Warning: $1."
    exit 2
}

# Prints this script's usage and exists. 
function outputUsage() {
    echo "Usage: `basename $0` USER_LIST [options...]"
    echo "Options:"
    echo "  -h/--help    Prints this message"
    echo "  -f/--file    File containing a list of usernames"
    echo "  -u/--user    Specifies CouchDB username and password" 
    echo "               Expects this format: -u username password"
    
    exit 1
}

################################################################################
# Core functions 
################################################################################

# Echos a CouchDB instance string similar to this: 
#   http://username:password@localhost:5984
# If no authorization credentials are passed, it looks like this: 
#   http://localhost:5984
function echoCouchDB() {
    if [ -n "$1" ] && [ -n "$2" ]; then
        AUTH="$1:$2@"
    fi
    
    echo "$PROTOCOL://$AUTH$HOST:$PORT"
}

function echoUserData() {
    echo "{\"_id\":\"$1$2\",\"name\":\"$2\",\"type\":\"user\",\"roles\":[]}"
}

function readFile() {

    echo "Not implemented yet!"
    exit 1

    filecontent=( `cat "$1" `)

    for line in "${filecontent[@]}"
    do
        echo $line
    done
}

function getUsers() {
    echo "Not implemented"
    # TODO: Refactor duplicate code in createUsers and deleteUsers. 
}

function createUsers() {

    # Strip the preceding comma. 
    USERS=${USERS:1}
    # Create a new array. 
    USERS=$(echo $USERS | tr "," "\n")

    # Get the right CouchDB name.     
    COUCHDB=`echoCouchDB $COUCH_USER $PASSWORD`

    for USERNAME in $USERS
    do
        echo "Creating $USER_PREFIX$USERNAME..."
        data=`echoUserData $USER_PREFIX $USERNAME`
        RESULT=$(curl -s -X PUT $COUCHDB/_users/$USER_PREFIX$USERNAME -d $data) 
        if [[ "$RESULT" == *error* ]]; then
            echo -e "\nError: $RESULT"
        else 
            echo "Done."
        fi
    done
}

function deleteUsers() {

    # Strip the preceding comma. 
    USERS=${USERS:1}
    # Create a new array. 
    USERS=$(echo $USERS | tr "," "\n")
    
    USER_COUNT=0
    for USERNAME in $USERS
    do 
        echo $USERNAME
        let "USER_COUNT+=1"
    done
    
    echo "$USER_COUNT users are about to be deleted."
    
    # If there are no users to delete, exit gracefully. 
    if [ $USER_COUNT -eq 0 ]; then
        exit 0
    fi
    
    echo -e "\nWARNING! DELETING IS IRREVERSIBLE.\n"
    echo -n "Are you sure you want to DELETE these users? y|n "
    read CONTINUE
    CONTINUE=${CONTINUE,,}

    # Get the right CouchDB name.     
    COUCHDB=`echoCouchDB $COUCH_USER $PASSWORD`

    if [ $CONTINUE == "y" -o $CONTINUE == "yes" ]; then 
        for USERNAME in $USERS
        do
            echo "Deleting $USER_PREFIX$USERNAME..."
            
            # Get the _rev first, otherwise you won't be able to delete. 
            userData=$(curl -s -X GET $COUCHDB/_users/$USER_PREFIX$USERNAME)
            pairs=$(echo $userData | tr "," "\n")
            for pair in $pairs
            do
                if [[ "$pair" == *_rev* ]]; then
                    # Strip the quotes and the "_rev:" part of the string. 
                    revID=${pair//[\"]/}
                    revID=${revID: 5}
                    break
                fi
            done
            
            RESULT=$(curl -s -X DELETE $COUCHDB/_users/$USER_PREFIX$USERNAME?rev=$revID) 
            if [[ "$RESULT" == *error* ]]; then
                echo -e "Error: $RESULT"
                echo -e "Make sure you are logged in.\n"
            else 
                echo "Done."
            fi
        done
    fi
}

################################################################################
# Command line processing
################################################################################

# This script requires at least one argument. If none are provided, print usage.
if [ $# -eq 0 ]; then
    outputUsage
fi

# Parse the command line arguments. 
while [ "$#" -gt "0" ]; do
    case "$1" in
        # -f|--file)
        #    shift 1
        #    readFile "$1"
        #    shift 1
        #    ;;
        -u|--user) 
            shift 1
            COUCH_USER="$1"
            PASSWORD="$2"
            shift 2
            ;;
        -r|--remove) 
            shift 1
            REMOVE=1
            ;;
        -h|--help)
            outputUsage
            ;;
        -*|--*)
            errorMessage "Unknown option $1"
            ;;
        *)
            # We've encountered a username, so add it to the list. 
            USERS="$USERS,$1"
            shift 1
            ;;
    esac
done

################################################################################
# Main
################################################################################

if [ $REMOVE ]; then
    deleteUsers
else
    createUsers
fi

