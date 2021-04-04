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
  echo "-d [value]  path to destination directory (to store backup.tar.gz)"
  echo "-s [value]  path to source directory or source file, can be used multiple times"
  echo "-v          skip verification (assume everything is set correctly)"
}

function print_error {
  red="\e[0;91m"
  reset="\e[0m"
  echo -e "${red}${1}${reset}"
}

function check_environment {
  if [[ -z "${DEST_DIR}" ]]; then
    print_error "destination directory not set (see -d flag)"
    print_usage
    exit 1;
  fi

  if [[ ${#SOURCES[@]} -eq 0 ]]; then
    print_error "no source directories or source files set (see -s flag)"
    print_usage
    exit 1;
  fi

  for SOURCE in "${SOURCES[@]}"; do
    if [[ ! -e "${SOURCE}" ]]; then
      print_error "source '${SOURCE}' does not exist"
      exit 1;
    fi
  done
}

function prepare_environment {
  readonly YEAR=$(date +"%Y")
  readonly WEEK="CW$(date +"%V")"
  readonly DATE_TIME="$(date +"%Y-%m-%d_%H-%M-%S")"

  # check if last character is slash
  if [[ "${DEST_DIR}" =~ .*\/$ ]]; then
    # remove if last character is slash
    DEST_DIR=$(echo "${DEST_DIR}" | sed 's/.\{1\}$//')
  fi
  readonly BACKUP_DIRECTORY="${DEST_DIR}/${YEAR}-${WEEK}"
  readonly BACKUP_FILENAME="${DATE_TIME}.tar.gz"
  readonly SNAPSHOT_FILENAME="${YEAR}-${WEEK}.snapshot"

  readonly BACKUP_FILEPATH="${BACKUP_DIRECTORY}/${BACKUP_FILENAME}"
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
  fi

  if [[ "${VERIFY}" != "y" ]] && [[ "${VERIFY}" != "yes" ]]; then
    print_error "backup verification failed"
    exit 1
  fi

  tar --listed-incremental="${SNAPSHOT_FILEPATH}" -cvzf "${BACKUP_FILEPATH}" ${SOURCES[*]} || (print_error "backup failed" && exit 1)
}

while getopts d:s:v option; do
  case "${option}" in

  d) DEST_DIR=${OPTARG} ;;
  s) SOURCES=( "${SOURCES[@]}" "${OPTARG}" ) ;;
  v) VERIFY=y ;;
  *) print_usage && exit 1 ;;
  esac
done

check_environment
prepare_environment
create_backup
