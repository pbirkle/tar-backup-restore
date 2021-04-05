# tar-backup-restore

simply create and restore backups incrementally in tar.gz files
- backups are created as a compressed tar file (tar.gz, save space on your hard drive)
- backups are created on a monthly base
   - every first backup (per month) will be an full backup
   - every other backup (per month) will be an incremental backup
   - if you are not familiar with full and / or incremental backups you can inform yourself [here](https://nakivo.medium.com/backup-types-explained-full-incremental-differential-synthetic-and-forever-incremental-e2d0ed7bc115)

## Getting started
- Be aware that both `backup.sh` and `restore.sh` have to be executed as an user with `root` privileges (e.g. use `sudo`)!
- Only absolute paths are allowed

```
git clone https://github.com/pbirkle/tar-backup-restore.git
cd tar-backup-restore.git
chmod +x backup.sh
chmod +x restore.sh
```

## Backup
Use `backup.sh` with following parameters to execute an backup. Some of them are not mandatory.

| Parameter  | Mandatory | Comment                                                             |
|------------|-----------|---------------------------------------------------------------------|
| `-d [value]` | `yes`      | path to destination directory (to store *.tar.gz)                   |
| `-s [value]` | `yes`       | path to source directory or source file, can be used multiple times |
| `-v`         | `no`        | skip verification (assume everything is set correctly)              |

Be aware that in your provided destination path (`-d`) there will be always created an subfolder which contains `[YEAR]-[MONTH]` (e.g. `2021-04`) in which the backups will be located. Everytime a new month begins, a new 'full'-backup will be created in corresponding folder. All following backups (for this month) will be incremental backups.

#### Example

With following command you can create a backup for multiple directories:
- Backup files will be stored at `/backup/seafile` in corresponding subfolder (e.g. `2021-04`)
- Sources are:
  - `/data/docker/seafile` which in this example contains `docker-compose.yaml`
  - `/var/lib/docker/volumes/seafile_seafile-data/_data` which in this example contains seafile data
  - `/var/lib/docker/volumes/seafile_seafile-mariadb/_data` which in this example contains seafile database
  - `/var/lib/docker/volumes/seafile_seahub-custom/_data` which in this example contains seahub custom
  - `/var/lib/docker/volumes/seafile_seahub-avatars/_data` which in this example contains seahub avatars
- Verification process will be skipped (e.g. good for automation)

```
/backup/tar-backup-restore/backup.sh \
  -d /backup/seafile \
  -s /data/docker/seafile \
  -s /var/lib/docker/volumes/seafile_seafile-data/_data \
  -s /var/lib/docker/volumes/seafile_seafile-mariadb/_data \
  -s /var/lib/docker/volumes/seafile_seahub-custom/_data \
  -s /var/lib/docker/volumes/seafile_seahub-avatars/_data \
  -v
```

## Restore
Use `restore.sh` with following parameters to execute an restore. Some of them are not mandatory. Be aware that this script has to be executed as an user with `root` privileges (e.g. use `sudo`)!

| Parameter  | Mandatory | Comment                                                        |
|------------|-----------|----------------------------------------------------------------|
| `-b [value]` | `yes`       | path to backup directory (containing the *.tar.gz files)       |
| `-d [value]` | `no`        | path to destination directory <br />default: root directory (`/`)      |
| `-l [value]` | `no`        | filename (!) of last backup file to restore <br />default: all files |
| `-v`         | `no`        | skip verification (assume everything is set correctly)         |

#### Example

With following command you can restore an existing backup (created in [backup](#backup) section):
- Backup files will be restored from older backups (full and all incremental, from corresponding month)

```
/backup/tar-backup-restore/restore.sh \
  -b /backup/seafile/2021-04
```
