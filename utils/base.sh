#!/usr/bin/env bash
# base.sh

function is_retropie() {
    [[ -d "$RP_DIR" && -d "$home/.emulationstation" && -d "/opt/retropie" ]]
}


function is_sudo() {
    [[ "$(id -u)" -eq 0 ]]
}

function truncate() {
    local string="$1"
    if [[ -z "$string" ]]; then
        error_report
        log "Missing a string as the first argument."
        exit 1
    fi
    local N="$2"
    if [[ -z "$N" ]]; then
        error_report
        log "Missing a number as the second argument."
        exit 1
    else
        if [[ ! "$N" =~ ^[0-9]+$ ]]; then
            error_report
            log "Second argument must be a number [0-9]."
            exit 1
        fi
    fi

    echo "$(echo "$1" | cut -c1-"$2")..."
}

function check_dependencies() {
    local pkg
    for pkg in "${DEPENDENCIES[@]}"; do
        if ! dpkg-query -W -f='${Status}' "$pkg" | awk '{print $3}' | grep -q "^installed$"; then
            echo "WHOOPS! The '$pkg' package is not installed!"
            echo "Would you like to install it now?"
            local options=("Yes" "No")
            local option
            select option in "${options[@]}"; do
                case "$option" in
                    Yes)
                        if ! which apt-get > /dev/null; then
                            log "ERROR: Can't install '$pkg' automatically. Try to install it manually."
                            exit 1
                        else
                            if sudo apt-get install "$pkg"; then
                                log "YIPPEE! The '$pkg' package installation was successfull!"
                            fi
                            break
                        fi
                        ;;
                    No)
                        log "ERROR: Can't launch the script if the '$pkg' package is not installed."
                        exit 1
                        ;;
                    *)
                        echo "Invalid option. Choose a number between 1 and ${#options[@]}."
                        ;;
                esac
            done
        fi
    done
}


function check_argument() {
    # Note: this method doesn't accept arguments starting with '-'.
    if [[ -z "$1" ]]; then
        error_report
        log "Missing arguments to check."
        exit 1
    fi
    if [[ -z "$2" || "$2" =~ ^- ]]; then
        log "ERROR: '$1' is missing an argument."
        echo "Try 'sudo $0 --help' for more info." >&2
        return 1
    fi
}


function usage() {
    echo
    underline "$SCRIPT_TITLE"
    echo "$SCRIPT_DESCRIPTION"
    echo
    echo
    echo "USAGE: sudo $0 [OPTIONS]"
    echo
    echo "Use 'sudo $0 --help' to see all the options."
    echo
    exit 0
}


function underline() {
    local dashes
    local string="$1"
    if [[ -z "$string" ]]; then
        error_report
        log "Missing a string as an argument."
        exit 1
    fi
    echo "$string"
    for ((i=1; i<="${#string}"; i+=1)); do [[ -n "$dashes" ]] && dashes+="-" || dashes="-"; done && echo "$dashes"
}


function join_by() {
    #Usage example: join_by , a b c
    local IFS="$1"
    shift
    echo "$*"
}


function error_report() {
    log "ERROR: '${FUNCNAME[1]}' function on line $(caller)"
}


function check_log_file(){
    if [[ ! -f "$LOG_FILE" ]]; then
        touch "$LOG_FILE" && chown -R "$user":"$user" "$LOG_FILE"
    fi
}


function log() {
    check_log_file
    if [[ "$GUI_FLAG" -eq 1 ]] ; then
        #~ echo "$(date +%F\ %T) - (v$SCRIPT_VERSION) GUI: $* << ${FUNCNAME[@]:1:((${#FUNCNAME[@]}-3))} $OPTION" >> "$LOG_FILE" # -2 are log ... get_options main main
        echo "$(date +%F\ %T) - (v$SCRIPT_VERSION) GUI: $* $([[ -n "$OPTION" ]] && echo "<< $OPTION")" >> "$LOG_FILE"
        echo "$*"
    else
        #~ echo "$(date +%F\ %T) - (v$SCRIPT_VERSION) $* << ${FUNCNAME[@]:1:((${#FUNCNAME[@]}-3))} $OPTION" >> "$LOG_FILE" # -2 are log ... get_options main main
        echo "$(date +%F\ %T) - (v$SCRIPT_VERSION) $* $([[ -n "$OPTION" ]] && echo "<< $OPTION")" >> "$LOG_FILE"
        echo "$*" >&2
    fi
}
