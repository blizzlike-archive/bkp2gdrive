# bkp2gdrive

this is a lua script to backup your wow server to a google drive account.

## installation

### google drive

First of all you have to enable the google drive api via the
[developer console](https://console.developers.google.com)
and create a service account with role **editor**.
After that browse to your google drive and create a new directory
and change the ownership to the service mail address of your
service account (attention: this may take a while).

    https://drive.google.com/drive/folders/<folder-id>

Now just copy the id from the folders url in your browsers address bar
and insert it into the `rc.lua`.

### debian / ubuntu

    apt-get install lua-socket lua-sec lua-cjson

### docker

    docker pull blizzlike/bkp2gdrive:master
    docker run --name b2g -d \
      -v /path/to/config/dir:/home/blizzlike/bkp2gdrive/config \
      blizzlike/bkp2gdrive:master

### mysql user

    CREATE USER 'backup':'%';
    GRANT SELECT, SHOW VIEW, LOCK TABLES ON *.* TO 'backup'@'%';
    ALTER USER 'backup'@'%' IDENTIFIED BY '<password>'

    FLUSH PRIVILEGES;

## usage

    make keys
    lua5.2 ./bkp2gdrive [<configfile>]

## credits

the base64url part is used from [ee_base64](https://github.com/ErnieE5/ee5_base64).
Unfortunately there is no license file attached. I suspect that it is public domain.

