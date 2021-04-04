#!/bin/bash

function print_banner {
  echo ""
  echo "████████╗ █████╗ ██████╗"
  echo "╚══██╔══╝██╔══██╗██╔══██╗"
  echo "   ██║   ███████║██████╔╝"
  echo "   ██║   ██╔══██║██╔══██╗"
  echo "   ██║   ██║  ██║██║  ██║"
  echo "   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝"
  echo "██████╗  █████╗  ██████╗    ██╗██████╗ ███████╗███████╗"
  echo "██╔══██╗██╔══██╗██╔════╝   ██╔╝██╔══██╗██╔════╝██╔════╝"
  echo "██████╔╝███████║██║       ██╔╝ ██████╔╝█████╗  ███████╗"
  echo "██╔══██╗██╔══██║██║      ██╔╝  ██╔══██╗██╔══╝  ╚════██║"
  echo "██████╔╝██║  ██║╚██████╗██╔╝   ██║  ██║███████╗███████║"
  echo "╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝    ╚═╝  ╚═╝╚══════╝╚══════╝"
  echo ""
}

function print_usage {
  print_banner
  echo "Usage:"
  echo "-b [value] | mandatory | path to backup directory (containing the *.tar.gz files)"
  echo "-d [value] | optional  | path to destination directory (if not present files will be extracted corresponding to root directory)"
  echo "-v         | optional  | skip verification (assume everything is set correctly)"
}

function print_error {
  red="\e[0;91m"
  reset="\e[0m"
  echo -e "${red}${1}${reset}"
}

function setup_environment {
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

}

function restore_backup {
  echo "Using following specification"
  echo "backup directory:  ${BACKUP_DIR}"
  echo "backup files:      ${BACKUP_FILES[*]}"
  echo ""

  if [[ -z "${VERIFY}" ]]; then
    read -r -p "do you really want to execute a backup with above specification: [n|y] " VERIFY
    echo ""
  fi

  if [[ "${VERIFY}" != "y" ]] && [[ "${VERIFY}" != "yes" ]]; then
    print_error "backup verification failed"
    exit 1
  fi

  for BACKUP_FILE in "${BACKUP_FILES[@]}"; do
    BACKUP_FILEPATH="${BACKUP_DIR}/${BACKUP_FILE}"
    echo "restoring '${BACKUP_FILEPATH}' to '${DEST_DIR}' ..."
    tar --listed-incremental=/dev/null -xvzf "${BACKUP_FILEPATH}" -C "${DEST_DIR}"
    echo ""
  done
}

while getopts b:d:s:v option; do
  case "${option}" in

  b) BACKUP_DIR=${OPTARG} ;;
  d) DEST_DIR=${OPTARG} ;;
  v) VERIFY=y ;;
  *) print_usage && exit 1 ;;
  esac
done

setup_environment
restore_backup