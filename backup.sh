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
  echo "-d [value] | mandatory | path to destination directory (to store backup.tar.gz)"
  echo "-s [value] | mandatory | path to source directory or source file, can be used multiple times"
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

  if [[ -z "${DEST_DIR}" ]]; then
    print_error "destination directory not set (see -d flag)"
    print_usage
    exit 1;
  fi

  if [[ ${#SOURCES[@]} -lt 1 ]]; then
    print_error "no source directories or source files set (see -s flag)"
    print_usage
    exit 1;
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
      exit 1;
    fi
  done

  # check if last character is slash
  if [[ "${DEST_DIR}" =~ .*\/$ ]]; then
    # remove if last character is slash
    DEST_DIR=$(echo "${DEST_DIR}" | sed 's/.\{1\}$//')
  fi

  readonly YEAR=$(date +"%Y")
  readonly WEEK="CW$(date +"%V")"
  readonly DATE_TIME="$(date +"%Y-%m-%d_%H-%M-%S")"

  readonly BACKUP_DIRECTORY="${DEST_DIR}/${YEAR}-${WEEK}"
  readonly BACKUP_FILENAME="${DATE_TIME}.tar.gz"
  readonly SNAPSHOT_FILENAME="${YEAR}-${WEEK}.snapshot"
  readonly BACKUP_FILEPATH="${BACKUP_DIRECTORY}/${BACKUP_FILENAME}"
  readonly BACKUP_LOG_FILEPATH="${BACKUP_FILEPATH}.log"
  readonly SNAPSHOT_FILEPATH="${BACKUP_DIRECTORY}/${SNAPSHOT_FILENAME}"

  if [[ ! -e "${BACKUP_DIRECTORY}" ]]; then
    mkdir -p "${BACKUP_DIRECTORY}" || (echo "could not create destination backup directory" && exit 1)
  fi

  if [[ -e "${BACKUP_FILEPATH}" ]]; then
    print_error "backup file '${BACKUP_FILEPATH}' does already exist"
    exit 1
  fi
}

function create_backup {
  echo "Using following specification"
  echo "destination directory:  ${DEST_DIR}"
  echo "backup filename:        ${BACKUP_FILENAME}"
  echo "sources:                ${SOURCES[*]}"
  echo ""

  if [[ -z "${VERIFY}" ]]; then
    read -r -p "do you really want to execute a backup with above specification: [n|y] " VERIFY
    echo ""
  fi

  if [[ "${VERIFY}" != "y" ]] && [[ "${VERIFY}" != "yes" ]]; then
    print_error "backup verification failed"
    exit 1
  fi

  echo "backup started, this could take a while..."
  tar --listed-incremental="${SNAPSHOT_FILEPATH}" -cvzf "${BACKUP_FILEPATH}" ${SOURCES[*]} > "${BACKUP_LOG_FILEPATH}" || (print_error "backup failed" && exit 1)
  echo "backup successfully, see '${BACKUP_LOG_FILEPATH}' for further investigation"
}

while getopts d:s:v option; do
  case "${option}" in

  d) DEST_DIR=${OPTARG} ;;
  s) SOURCES=( "${SOURCES[@]}" "${OPTARG}" ) ;;
  v) VERIFY=y ;;
  *) print_usage && exit 1 ;;
  esac
done

setup_environment
create_backup
