#!/bin/bash

function print_banner() {
  echo ""
  echo " ████████╗ █████╗ ██████╗     ██████╗ ███████╗"
  echo " ╚══██╔══╝██╔══██╗██╔══██╗   ██╔════╝ ╚══███╔╝"
  echo "    ██║   ███████║██████╔╝   ██║  ███╗  ███╔╝"
  echo "    ██║   ██╔══██║██╔══██╗   ██║   ██║ ███╔╝"
  echo "    ██║   ██║  ██║██║  ██║██╗╚██████╔╝███████╗"
  echo "    ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝ ╚═════╝ ╚══════╝"
  echo " ██████╗  █████╗  ██████╗██╗  ██╗██╗   ██╗██████╗"
  echo " ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██║   ██║██╔══██╗"
  echo " ██████╔╝███████║██║     █████╔╝ ██║   ██║██████╔╝"
  echo " ██╔══██╗██╔══██║██║     ██╔═██╗ ██║   ██║██╔═══╝"
  echo " ██████╔╝██║  ██║╚██████╗██║  ██╗╚██████╔╝██║"
  echo " ╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝"
  echo " https://github.com/pbirkle/tar-backup-restore"
  echo ""
}

function print_usage() {
  print_banner

  echo " - backups are created as a compressed tar file (tar.gz, save space on your hard drive)"
  echo " - backups are created on a monthly base"
  echo "   - every first backup (per month) will be an full backup"
  echo "   - every other backup (per month) will be an incremental backup"
  echo " - to restore a backup use 'tar.gz restore'"
  echo ""

  bold='\033[1m'
  reset="\e[0m"
  echo " |----------------------------------------------------------------------------------------------|"
  echo -e " | ${bold}Parameter${reset}  | ${bold}Mandatory${reset} | ${bold}Comment${reset}                                                             |"
  echo " |----------------------------------------------------------------------------------------------|"
  echo " | -d [value] | yes       | path to destination directory (to store *.tar.gz)                   |"
  echo " |----------------------------------------------------------------------------------------------|"
  echo " | -s [value] | yes       | path to source directory or source file, can be used multiple times |"
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

  if [[ -z "${DEST_DIR}" ]]; then
    print_error "destination directory not set (see -d flag)"
    print_usage
    exit 1
  fi

  if [[ ${#SOURCES[@]} -lt 1 ]]; then
    print_error "no source directories or source files set (see -s flag)"
    print_usage
    exit 1
  fi

  # check if first character is slash
  if ! [[ "${DEST_DIR}" =~ ^\/.* ]]; then
    print_error "destination directory '${DEST_DIR}' must be an absolute path"
    exit 1
  fi
  for SOURCE in "${SOURCES[@]}"; do
    if ! [[ "${SOURCE}" =~ ^\/.* ]]; then
      print_error "source '${SOURCE}' must be an absolute path"
      exit 1
    elif [[ ! -e "${SOURCE}" ]]; then
      print_error "source '${SOURCE}' does not exist"
      exit 1
    fi
  done

  # check if last character is slash
  if [[ "${DEST_DIR}" =~ .*\/$ ]]; then
    # remove if last character is slash
    DEST_DIR=$(echo "${DEST_DIR}" | sed 's/.\{1\}$//')
  fi

  readonly YEAR="$(date +"%Y")"
  readonly MONTH="$(date +"%m")"
  readonly DATE_TIME="$(date +"%Y-%m-%d_%H-%M-%S")"
  readonly BACKUP_DIRECTORY="${DEST_DIR}/${YEAR}-${MONTH}"
  readonly BACKUP_FILENAME="${DATE_TIME}.tar.gz"
  readonly BACKUP_FILEPATH="${BACKUP_DIRECTORY}/${BACKUP_FILENAME}"
  readonly SNAPSHOT_FILENAME="${YEAR}-${MONTH}.snapshot"
  readonly SNAPSHOT_FILEPATH="${BACKUP_DIRECTORY}/${SNAPSHOT_FILENAME}"
  readonly LOG_FILEPATH="${BACKUP_FILEPATH}.log"

  if [[ ! -e "${BACKUP_DIRECTORY}" ]]; then
    mkdir -p "${BACKUP_DIRECTORY}" || (print_error "could not create destination backup directory" && exit 1)
  fi

  if [[ -e "${BACKUP_FILEPATH}" ]]; then
    print_error "backup file '${BACKUP_FILEPATH}' does already exist"
    exit 1
  fi
}

function verify() {
  print_log ""
  print_log "backup file:"
  print_log "  - ${BACKUP_FILEPATH}"
  print_log ""
  print_log "backup log (full):"
  print_log "  - ${LOG_FILEPATH}"
  print_log ""
  print_log "sources:"
  for SOURCE in "${SOURCES[@]}"; do
    print_log "  - ${SOURCE}"
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

function create_backup() {
  print_log "backup process started, this could take a while..."
  tar --listed-incremental="${SNAPSHOT_FILEPATH}" -cvzf "${BACKUP_FILEPATH}" ${SOURCES[*]} &>>"${LOG_FILEPATH}" || (print_error "backup failed" && exit 1)
  print_log "backup process successful!"
}

while getopts d:s:v option; do
  case "${option}" in

  d) DEST_DIR=${OPTARG} ;;
  s) SOURCES=("${SOURCES[@]}" "${OPTARG}") ;;
  v) VERIFY=y ;;
  *) print_usage && exit 1 ;;
  esac
done

setup_environment
verify
create_backup
