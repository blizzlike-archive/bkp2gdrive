# bkp2gdrive

this is a lua script to backup your wow server to a google drive account.

## installation

    apt-get install lua-socket lua-sec lua-cjson

### docker

    docker pull blizzlike/bkp2gdrive:latest
    docker run --name b2g -d \
      -v /path/to/config/dir:/home/blizzlike/bkp2gdrive/config \
      blizzlike/bkp2gdrive:latest

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

