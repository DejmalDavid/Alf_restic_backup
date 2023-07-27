# Alf_restic_backup
Alfresco Docker local backup via Restic

Tested on Ubuntu 22.04, Alfresco 7.4, Restic 0.15.2

Script is build on Alfresco from installer from https://github.com/Alfresco/alfresco-docker-installer  
All path in script are absolute and configure throw variables.  
All backups are made on own risk!  
Backup only contentstore and postgresql database. (I do reindex Solr after restore and all conf have in own GIT repo...)

---

### Install steps of backup script:

1. Prepare mount
2. Restic install
3. Create restic repository
4. Prepare password file
5. Fill script properties
6. Test backup
7. Set crontab
8. Restore

Install and running script need root permissions... 

---
### TODOs:
- add Restore step-by-step
- set run under other user than root
- add support for sftp or other file storage
- and much more...
---

### Example for CIFS

`mkdir -p /root/.ssh/cifs_credentials/`  
`chmod 700  /root/.ssh /root/.ssh/cifs_credentials`  
`touch /root/.ssh/cifs_credentials/cifscredentials_ip_sharedFolderName.txt`  

fill with username and password, for example:  
`username=jmeno`  
`password=Password can have spaces, use withOUT quotation marks`

`chmod 600 /root/.ssh/cifs_credentials/cifscredentials_ip_sharedFolderName.txt`  
`mkdir -p /media/backup`  

edit `/etc/fstab`  
`//ip/mount/folder /media/backup cifs credentials=/root/.ssh/cifs_credentials/cifscredentials_ip_sharedFolderName.txt,ro,iocharset=utf8,noauto`  

and test it  

`mount /media/backup`  
`umount /media/backup`

---
## Restic install
follow https://restic.readthedocs.io/en/stable/020_installation.html

`apt-get install restic`  
`restic version`

**WARNING**  
on ubuntu 22.04 is installing:
restic 0.12.1 compiled with go1.18.1 on linux/amd64
(which is released 8.2021 = very old)

on other hand you can after update via restic itself
restic self-update  
but i thing after this update apt updagrade will not work in future  
then you can configure restic or can have default configuration

---
## Create restic repository

https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html


When you create repo use **good name**!  
Use **strong password**!  
Dont **lose** used password!  

`mount /media/backup`  
`restic init --repo /media/backup/TEST`

then test  
`restic -r /media/backup/TEST check`

---
## Prepare password file

`mkdir -p /root/restic_passwords`  
`chmod 700  /root/restic_passwords`  
`touch /root/restic_passwords/repo_name.txt`  

fill file with password in plaintext  

`chmod 600 /root/restic_passwords/repo_name.txt`  

---
## Fill script properties

properly set all properties:  
`MOUNT_TO`  
`ALFFRESCO`  
`PSQL_DUMP`  
`ALF_DATA`  
`PSQL_PASSWORD`  
`RESTIC_REPOSITORY`  
`RESTIC_PASSWORD_FILE`  

---
## Test backup

`./path/to/script/backup_alfresco.sh`  
`restic -r /media/backup/TEST snapshots`  

---
## Set crontab

`sudo crontab -e`  
`20 04 * * * /path/to/script/backup_alfresco.sh`  

---
## Restore 

`restic -r /media/backup/TEST restore latest --target /tmp/restore`

and then make restore by Alfresco docs:
https://docs.alfresco.com/content-services/latest/admin/backup-restore/
