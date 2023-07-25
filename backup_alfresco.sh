#!/bin/bash
# Backup script for Alfresco 7.4 
# David Dejmal 2023, based on BF script, SIGNIA, s.r.o.

# if there will be problem with size of RAM, then change max of garbare collector fo GO
#export GOCG=1 

# if there will be problem with usage of CPU then you can set effort and nices

### Backup destination and type of connection
export MOUNT_TO=/media/backup

#Path to main installer 
export ALFFRESCO=/opt/alfresco

#Path where will be created dump, "${ALFFRESCO}"/backup must exist and have enough space!
export PSQL_DUMP="${ALFFRESCO}"/backup/pg-dump.sql
export ALF_DATA="${ALFFRESCO}"/data/alfresco-data

#postgresql password for user alfresco
export PSQL_PASSWORD=alfresco

#set restic enviroment
export RESTIC_REPOSITORY="${MOUNT_TO}"/TEST
export RESTIC_PASSWORD_FILE=/root/restic-password


# Mount destionation 
# if connecton RO (by hands maybe) remount RW, other RW , if error then end
if findmnt --mountpoint "${MOUNT_TO}" -O ro > /dev/null
    then
      mount -o remount,rw "${MOUNT_TO}" || exit 4
  elif findmnt --mountpoint "${MOUNT_TO}" -O rw > /dev/null
    then
      echo "Prover - "${MOUNT_TO}" already RW; continue"
  elif ! findmnt --mountpoint "${MOUNT_TO}"  > /dev/null
    then
      mount -o rw "${MOUNT_TO}" || exit 4
fi

function umountquit {
  umount "${MOUNT_TO}"
  exit 1
}


### Test write and cleanup
TMPDIR_REPO=$(mktemp --directory "${RESTIC_REPOSITORY}"/tmp.XXXXXXXXXX) || umountquit
rm -rf "${TMPDIR_REPO}" || exit 1

echo "MOUNT - OK"

# check of backup
restic -r "${RESTIC_REPOSITORY}" check --read-data   
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "INTEGRITY ERROR!"
	exit retVal
fi

# dump database
docker-compose -f "${ALFFRESCO}"/docker-compose.yml exec postgres pg_dump --username alfresco "${PSQL_PASSWORD}" > "${PSQL_DUMP}"
retVal=$?

if [ $retVal -ne 0 ]; then
    echo "DUMP DATABASE ERROR!"
	exit retVal
fi

echo "DUMP - OK"

# backup itself
restic backup "${ALF_DATA}" "${PSQL_DUMP}" --cleanup-cache  
retVal=$?

# cleand dump
rm "${PSQL_DUMP}"

if [ $retVal -ne 0 ]; then
    echo "RESTIC BACKUP ERROR!"
	exit $retVal
fi

echo "BACKUP - OK"

# policy for clean backup - please configure as you want
restic forget --keep-daily 30 --keep-monthly 3 --prune
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "RESTIC FORGET ERROR!"
	exit $retVal
fi

echo "RESTIC forget - OK"

# check of backup
restic -r "${RESTIC_REPOSITORY}" check --read-data --cleanup-cache   
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "INTEGRITY ERROR AFTER BACKUP!"
	exit $retVal
fi

echo "RESTIC check - OK"

#umount
umount "${MOUNT_TO}"

#happy end
echo "ALL - OK"
exit 0
