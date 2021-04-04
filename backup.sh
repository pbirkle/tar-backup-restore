#!/bin/bash

function print_usage {
  echo "-d [value]  path to destination directory (to store backup.tar.gz)"
  echo "-s [value]  path to source directory or source file, can be used multiple times"
}

function check_environment {
  if [[ -z "${DEST_DIR}" ]]; then
    echo "destination directory not set (see -d flag)"
    print_usage
    exit 1;
  fi

  if [[ ${#SOURCES[@]} -eq 0 ]]; then
    echo "no source directories or source files set (see -s flag)"
    print_usage
    exit 1;
  fi

  for SOURCE in "${SOURCES[@]}"; do
    if [[ ! -e "${SOURCE}" ]]; then
      echo "Source '${SOURCE}' does not exist"
      exit 1;
    fi
  done
}

function prepare_environment {
  if [[ ! -e "${DEST_DIR}" ]]; then
    mkdir -p "${DEST_DIR}" || (echo "could not create destination directory" && exit 1)
  fi

  readonly YEAR=$(date +"%Y")
  readonly WEEK="CW$(date +"%V")"
  readonly DAY_OF_WEEK=$(date +"%u")

  # check if last character is slash
  if [[ "${DEST_DIR}" =~ .*\/$ ]]; then
    # remove if last character is slash
    DEST_DIR=$(echo "${DEST_DIR}" | sed 's/.\{1\}$//')
  fi
  readonly BACKUP_DIRECTORY="${DEST_DIR}/${YEAR}-${WEEK}"
  readonly BACKUP_FILENAME="${YEAR}-${WEEK}-${DAY_OF_WEEK}.tar.gz"
  readonly SNAPSHOT_FILENAME="${YEAR}-${WEEK}.snapshot"

  readonly BACKUP_FILEPATH="${BACKUP_DIRECTORY}/${BACKUP_FILENAME}"
  readonly SNAPSHOT_FILEPATH="${BACKUP_DIRECTORY}/${SNAPSHOT_FILENAME}"

}

function create_backup {
  echo "tar --listed-incremental=\"${SNAPSHOT_FILEPATH}\" -cvzf \"${BACKUP_FILEPATH}\" ${SOURCES[*]}"
}

while getopts d:s: option; do
  case "${option}" in

  d) DEST_DIR=${OPTARG} ;;
  s) SOURCES=( "${SOURCES[@]}" "${OPTARG}" ) ;;
  *) print_usage && exit 1 ;;
  esac
done

echo "DEST_DIR:  ${DEST_DIR}"
echo "SOURCES:   ${SOURCES[*]}"

check_environment
prepare_environment
create_backup