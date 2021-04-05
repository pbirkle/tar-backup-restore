#!/bin/bash

function print_banner() {
  echo ""
  echo " ████████╗ █████╗ ██████╗     ██████╗ ███████╗"
  echo " ╚══██╔══╝██╔══██╗██╔══██╗   ██╔════╝ ╚══███╔╝"
  echo "    ██║   ███████║██████╔╝   ██║  ███╗  ███╔╝"
  echo "    ██║   ██╔══██║██╔══██╗   ██║   ██║ ███╔╝"
  echo "    ██║   ██║  ██║██║  ██║██╗╚██████╔╝███████╗"
  echo "    ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝ ╚═════╝ ╚══════╝"
  echo " ██████╗ ███████╗███████╗████████╗ ██████╗ ██████╗ ███████╗"
  echo " ██╔══██╗██╔════╝██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗██╔════╝"
  echo " ██████╔╝█████╗  ███████╗   ██║   ██║   ██║██████╔╝█████╗"
  echo " ██╔══██╗██╔══╝  ╚════██║   ██║   ██║   ██║██╔══██╗██╔══╝"
  echo " ██║  ██║███████╗███████║   ██║   ╚██████╔╝██║  ██║███████╗"
  echo " ╚═╝  ╚═╝╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝"
  echo " https://github.com/pbirkle/tar-backup-restore"
  echo ""
}

function print_usage() {
  print_banner

  echo " - backups have to be created with 'tar.gz backup'"
  echo ""

  bold='\033[1m'
  reset="\e[0m"
  echo " |----------------------------------------------------------------------------------------------|"
  echo -e " | ${bold}Parameter${reset}  | ${bold}Mandatory${reset} | ${bold}Comment${reset}                                                             |"
  echo " |----------------------------------------------------------------------------------------------|"
  echo " | -b [value] | yes       | path to backup directory (containing the *.tar.gz files)            |"
  echo " |----------------------------------------------------------------------------------------------|"
  echo " | -d [value] | no        | path to destination directory                                       |"
  echo " |            |           | default: root directory (/)                                         |"
  echo " |----------------------------------------------------------------------------------------------|"
  echo " | -l [value] | no        | filename (!) of last backup file to restore                         |"
  echo " |            |           | default: all files                                                  |"
  echo " |----------------------------------------------------------------------------------------------|"
  echo " | -v         | no        | skip verification (assume everything is set correctly)              |"
  echo " |----------------------------------------------------------------------------------------------|"
}

# $1: error statement
function print_error() {
  red="\e[0;91m"
  reset="\e[0m"
  echo -e "${red}${1}${reset}"
}

# $1: log statement
function print_log() {
  echo "${1}"
  echo "${1}" >>"${LOG_FILEPATH}"
}

function setup_environment() {
  if [[ $(id -u) -ne 0 ]]; then
    print_error "script was not executed with root privileges (use sudo)"
    exit 1
  fi

  if [[ -z "${BACKUP_DIR}" ]]; then
    print_error "backup directory not set (see -b flag)"
    print_usage
    exit 1
  fi
  if [[ -z "${DEST_DIR}" ]]; then
    DEST_DIR="/"
  fi

  # check if first character is slash
  if ! [[ "${BACKUP_DIR}" =~ ^\/.* ]]; then
    print_error "backup directory '${BACKUP_DIR}' must be an absolute path"
    exit 1
  fi
  if ! [[ "${DEST_DIR}" =~ ^\/.* ]]; then
    print_error "destination directory '${DEST_DIR}' must be an absolute path"
    exit 1
  fi

  # check if last character is slash
  if [[ "${BACKUP_DIR}" =~ .*\/$ ]]; then
    # remove if last character is slash
    BACKUP_DIR=$(echo "${BACKUP_DIR}" | sed 's/.\{1\}$//')
  fi

  if [[ -e "${BACKUP_DIR}" ]]; then
    cd "${BACKUP_DIR}" || (print_error "could not switch to backup directory" && exit 1)
  else
    print_error "backup directory not found"
    exit 1
  fi

  readonly REGEX_BACKUP_FILES="^[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}.tar.gz$"
  readonly BACKUP_FILES=( $(find -- * -regextype posix-egrep -regex "${REGEX_BACKUP_FILES}") )

  if [[ "${#BACKUP_FILES[@]}" -lt 1 ]]; then
    print_error "no backups found in backup directory"
    exit 1
  fi

  if ! [[ "${BACKUP_FILES[*]}" =~ ${LAST_BACKUP_FILE} ]]; then
    print_error "last backup file '${LAST_BACKUP_FILE}' could not be found"
    exit 1
  fi

  readonly DATE_TIME="$(date +"%Y-%m-%d_%H-%M-%S")"
  readonly LOG_FILEPATH="/tmp/tar-restore-${DATE_TIME}.log"
}

function verify() {
  print_log ""
  print_log "restore base directory:"
  print_log "  - ${DEST_DIR}"
  print_log ""
  print_log "restore log (full):"
  print_log "  - ${LOG_FILEPATH}"
  print_log ""
  print_log "backup directory:"
  print_log "  - ${BACKUP_DIR}"
  print_log ""
  print_log "backup files:"
  for BACKUP_FILE in "${BACKUP_FILES[@]}"; do
    print_log "  - ${BACKUP_FILE}"
    if [[ "${BACKUP_FILE}" == "${LAST_BACKUP_FILE}" ]]; then
      break;
    fi
  done
  print_log ""

  if [[ -z "${VERIFY}" ]]; then
    read -r -p "do you really want to execute a backup with above specification: [n|y] " VERIFY
    echo ""
  fi

  if [[ "${VERIFY}" != "y" ]] && [[ "${VERIFY}" != "yes" ]]; then
    print_error "backup verification failed"
    exit 1
  fi
}

function restore_backup() {
  print_log "restore process started, this could take a while..."
  COUNT=1
  for BACKUP_FILE in "${BACKUP_FILES[@]}"; do
    BACKUP_FILEPATH="${BACKUP_DIR}/${BACKUP_FILE}"
    print_log "restoring '${BACKUP_FILEPATH}' to '${DEST_DIR}' ..."
    tar --listed-incremental=/dev/null -xvzf "${BACKUP_FILEPATH}" -C "${DEST_DIR}" &>>"${LOG_FILEPATH}"
    if [[ "${BACKUP_FILE}" == "${LAST_BACKUP_FILE}" ]] && [[ ${COUNT} -lt ${#BACKUP_FILES[@]} ]]; then
      print_log "reached last backup file ${LAST_BACKUP_FILE}, skip remaining backup files"
      break;
    fi
    ((COUNT++))
  done
  print_log "restore successful"
}

while getopts b:d:l:s:v option; do
  case "${option}" in

  b) BACKUP_DIR=${OPTARG} ;;
  d) DEST_DIR=${OPTARG} ;;
  l) LAST_BACKUP_FILE=${OPTARG} ;;
  v) VERIFY=y ;;
  *) print_usage && exit 1 ;;
  esac
done

setup_environment
verify
restore_backup