FROM tiredofit/nginx-php-fpm:debian-7.3
LABEL maintainer="Dave Conroy (dave at tiredofit dot ca)"

ENV KOPANO_CORE_VERSION=10.0.6 \
    KOPANO_WEBAPP_VERSION=4.2.0 \
    KOPANO_KDAV_VERSION=master \
    Z_PUSH_VERSION=2.5.2 \
    NGINX_LOG_ACCESS_LOCATION=/logs/nginx \
    NGINX_LOG_ERROR_LOCATION=/logs/nginx \
    NGINX_WEBROOT=/usr/share/kopano-webapp \
    PHP_ENABLE_CREATE_SAMPLE_PHP=FALSE \
    PHP_ENABLE_GETTEXT=TRUE \
    PHP_ENABLE_SIMPLEXML=TRUE \
    PHP_ENABLE_SOAP=TRUE \
    PHP_ENABLE_PDO=TRUE \
    PHP_ENABLE_PDO_SQLITE=TRUE \
    PHP_ENABLE_XMLWRITER=TRUE \
    PHP_ENABLE_TOKENIZER=TRUE \
    PHP_LOG_LOCATION=/logs/php-fpm

RUN set -x && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
                       apt-utils \
                       bc \
                       fail2ban \
                       git \
                       iptables \
                       lynx \
                       php-memcached \
                       php-tokenizer \
                       python3-pip \
                       sqlite3 \
                       && \
    \
    ## Python Deps for Spamd in specific order
    pip3 install wheel && \
    pip3 install setuptools && \
    pip3 install inotify && \
    \
#### Fetch Packages and Create Repositories
### Kopano Dependencies
    mkdir -p /usr/src/kopano-dependencies && \
    curl -L `lynx -listonly -nonumbers -dump https://download.kopano.io/community/dependencies:/ | grep Debian_10-amd64.tar.gz` | tar xvfz - --strip 1 -C /usr/src/kopano-dependencies && \
    cd /usr/src/kopano-dependencies && \
    apt-ftparchive packages ./ > /usr/src/kopano-dependencies/Packages && \
    echo "deb [trusted=yes] file:/usr/src/kopano-dependencies/ /" >> /etc/apt/sources.list.d/kopano-dependencies.list && \
    \
### Kopano Core
    mkdir -p /usr/src/core && \
    kcore_version=`lynx -listonly -nonumbers -dump https://download.kopano.io/community/core:/ | grep -o core-.*-Debian_10-amd64.tar.gz | sed "s/%2B/+/g " | sed "s/-Debian_10.*//g"` && \
    echo "Kopano Core Version: ${kcore_version} on $(date)" >> /.kopano-versions && \
    curl -L `lynx -listonly -nonumbers -dump https://download.kopano.io/community/core:/ | grep Debian_10-amd64.tar.gz` | tar xvfz - --strip 1 -C /usr/src/core && \
    cd /usr/src/core && \
    apt-ftparchive packages ./ > /usr/src/core/Packages && \
    echo "deb [trusted=yes] file:/usr/src/core/ /" >> /etc/apt/sources.list.d/kopano-core.list && \
    \
### Kopano WebApp
    mkdir -p /usr/src/webapp && \
    webapp_version=`lynx -listonly -nonumbers -dump https://download.kopano.io/community/webapp:/ | grep -o webapp-.*-Debian_10-all.tar.gz | sed "s/%2B/+/g" | sed "s/-Debian_10.*//g"` && \
    echo "Kopano Webapp Version: ${webapp_version} on $(date)" >> /.kopano-versions && \
    curl -L `lynx -listonly -nonumbers -dump https://download.kopano.io/community/webapp:/ | grep Debian_10-all.tar.gz` | tar xvfz - --strip 1 -C /usr/src/webapp && \
    cd /usr/src/webapp && \
    apt-ftparchive packages ./ > /usr/src/webapp/Packages && \
    echo "deb [trusted=yes] file:/usr/src/webapp/ /" >> /etc/apt/sources.list.d/kopano-webapp.list && \
    \
### Kopano SMIME
    mkdir -p /usr/src/smime && \
    smime_version=`lynx -listonly -nonumbers -dump https://download.kopano.io/community/smime:/ | grep -o smime-.*-Debian_10-amd64.tar.gz | sed "s/%2B/+/g " | sed "s/-Debian_10.*//g"` && \
    echo "Kopano S/MIME Version: ${smime_version} on $(date)" >> /.kopano-versions && \
    curl -L `lynx -listonly -nonumbers -dump https://download.kopano.io/community/smime:/ | grep Debian_10-amd64.tar.gz` | tar xvfz - --strip 1 -C /usr/src/smime && \
    cd /usr/src/smime && \
    apt-ftparchive packages ./ > /usr/src/smime/Packages && \
    echo "deb [trusted=yes] file:/usr/src/smime/ /" >> /etc/apt/sources.list.d/kopano-smime.list && \
    \
### Kopano Archiver
    mkdir -p /usr/src/archiver && \
    archiver_version=`lynx -listonly -nonumbers -dump https://download.kopano.io/community/archiver:/ | grep -o archiver-.*-Debian_10-amd64.tar.gz | sed "s/%2B/+/g " | sed "s/-Debian_10.*//g"` && \
    echo "Kopano Archiver Version: ${archiver_version} on $(date)" >> /.kopano-versions && \
    curl -L `lynx -listonly -nonumbers -dump https://download.kopano.io/community/archiver:/ | grep Debian_10-amd64.tar.gz` | tar xvfz - --strip 1 -C /usr/src/archiver && \
    cd /usr/src/archiver && \
    apt-ftparchive packages ./ > /usr/src/archiver/Packages && \
    echo "deb [trusted=yes] file:/usr/src/archiver/ /" >> /etc/apt/sources.list.d/kopano-archiver.list && \
    \
### Kopano Apps (Calenar)
    mkdir -p /usr/src/kapps && \
    kapps_version=`lynx -listonly -nonumbers -dump https://download.kopano.io/community/kapps:/ | grep -o kapps-.*-Debian_10-amd64.tar.gz | sed "s/%2B/+/g" | sed "s/-Debian_10.*//g"` && \
    echo "Kopano Apps Version: ${kapps_version} on $(date)" >> /.kopano-versions && \
    curl -L `lynx -listonly -nonumbers -dump https://download.kopano.io/community/kapps:/ | grep Debian_10-amd64.tar.gz` | tar xvfz - --strip 1 -C /usr/src/kapps && \
    cd /usr/src/kapps && \
    apt-ftparchive packages ./ > /usr/src/kapps/Packages && \
    echo "deb [trusted=yes] file:/usr/src/kapps/ /" >> /etc/apt/sources.list.d/kopano-kapps.list && \
    \
### Kopano MDM
    mkdir -p /usr/src/mdm && \
    mdm_version=`lynx -listonly -nonumbers -dump https://download.kopano.io/community/mdm:/ | grep -o mdm-.*-Debian_10-all.tar.gz | sed "s/%2B/+/g " | sed "s/-Debian_10.*//g"` && \
    echo "Kopano MDM Version: ${mdm_version} on $(date)" >> /.kopano-versions && \
    curl -L `lynx -listonly -nonumbers -dump https://download.kopano.io/community/mdm:/ | grep Debian_10-all.tar.gz` | tar xvfz - --strip 1 -C /usr/src/mdm && \
    cd /usr/src/mdm && \
    apt-ftparchive packages ./ > /usr/src/mdm/Packages && \
    echo "deb [trusted=yes] file:/usr/src/mdm/ /" >> /etc/apt/sources.list.d/kopano-mdm.list && \
    \
### Kopano Files
    mkdir -p /usr/src/files && \
    files_version=`lynx -listonly -nonumbers -dump https://download.kopano.io/community/files:/ | grep -o files-.*-Debian_10-all.tar.gz | sed "s/%2B/+/g " | sed "s/-Debian_10.*//g"` && \
    echo "Kopano Files Version: ${files_version} on $(date)" >> /.kopano-versions && \
    curl -L `lynx -listonly -nonumbers -dump https://download.kopano.io/community/files:/ | grep Debian_10-all.tar.gz` | tar xvfz - --strip 1 -C /usr/src/files && \
    cd /usr/src/files && \
    apt-ftparchive packages ./ > /usr/src/files/Packages && \
    echo "deb [trusted=yes] file:/usr/src/files/ /" >> /etc/apt/sources.list.d/kopano-files.list && \
    \
### Kopano Meet
    mkdir -p /usr/src/meet && \
    meet_version=`lynx -listonly -nonumbers -dump https://download.kopano.io/community/meet:/ | grep -o meet-.*-Debian_10-amd64.tar.gz | sed "s/%2B/+/g " | sed "s/-Debian_10.*//g"` && \
    echo "Kopano Meet Version: ${meet_version} on $(date)" >> /.kopano-versions && \
    curl -L `lynx -listonly -nonumbers -dump https://download.kopano.io/community/meet:/ | grep Debian_10-amd64.tar.gz` | tar xvfz - --strip 1 -C /usr/src/meet && \
    cd /usr/src/meet && \
    apt-ftparchive packages ./ > /usr/src/meet/Packages && \
    echo "deb [trusted=yes] file:/usr/src/meet/ /" >> /etc/apt/sources.list.d/kopano-meet.list && \
    \
##### Install Packages
    apt-get update
RUN apt-get install -y --no-install-recommends \
                       #kopano-archiver \
                       kopano-bash-completion \
                       kopano-calendar \
                       kopano-calendar-webapp \
                       kopano-grapi \
                       kopano-grapi-bin \
                       kopano-indexer \
                       kopano-kapid \
                       kopano-konnectd \
                       kopano-kwmserverd \
                       kopano-meet \
                       kopano-migration-imap \
                       kopano-migration-pst \
                       kopano-python3-extras \
                       kopano-python3-kopano10 \
                       kopano-server-packages \
                       kopano-spamd \
                       kopano-statsd \
                       kopano-webapp \
                       kopano-webapp-plugin-contactfax \
                       kopano-webapp-plugin-desktopnotifications \
                       kopano-webapp-plugin-filepreviewer \
                       kopano-webapp-plugin-files \
                       kopano-webapp-plugin-filesbackend-owncloud \
                       kopano-webapp-plugin-filesbackend-smb \
                       kopano-webapp-plugin-folderwidgets \
                       kopano-webapp-plugin-htmleditor-quill \
                       kopano-webapp-plugin-intranet \
                       kopano-webapp-plugin-mdm \
                       kopano-webapp-plugin-mattermost \
                       kopano-webapp-plugin-meet \
                       kopano-webapp-plugin-pimfolder \
                       kopano-webapp-plugin-quickitems \
                       kopano-webapp-plugin-smime \
                       kopano-webapp-plugin-titlecounter \
                       kopano-webapp-plugin-webappmanual \
                       python3-grapi.backend.ldap \
                       && \
    \
### Z-Push Install
    mkdir /usr/share/zpush && \
    curl -sSL https://github.com/Z-Hub/Z-Push/archive/${Z_PUSH_VERSION}.tar.gz | tar xvfz - --strip 1 -C /usr/share/zpush && \
    ln -s /usr/share/z-push/src/z-push-admin.php /usr/sbin/z-push-admin && \
    ln -s /usr/share/z-push/src/z-push-top.php /usr/sbin/z-push-top && \
    \
### KDAV Install
    git clone -b ${KOPANO_KDAV_VERSION} https://github.com/Kopano-dev/kdav /usr/share/kdav && \
    cd /usr/share/kdav && \
    phpenmod xmlwriter && \
    phpenmod tokenizer && \
    phpenmod pdo-sqlite && \
    composer install && \
    \
### Webapp Rocketchat Plugin
    curl -o /usr/src/rocketchat.zip "https://cloud.siedl.net/nextcloud/index.php/s/3yKYARgGwfSZe2c/download" && \
    cd /usr/src/ && \
    unzip -d . rocketchat.zip && \
    dpkg -i /usr/src/Rocket.Chat/kopano-rocketchat-1.0.2-1.deb && \
    chmod -R 777 /usr/share/kopano-webapp/plugins/rchat && \
    \
### Webapp Seafile Plugin
    git clone https://github.com/datamate-rethink-it/kopano-seafile-backend /usr/share/kopano-webapp/plugins/filesbackendSeafile && \
    \
### Miscellanious Scripts
    mkdir -p /assets/kopano/scripts && \
    git clone --depth 1 https://stash.kopano.io/scm/ksc/Core-tools.git /assets/kopano/scripts/core-tools && \
    git clone --depth 1 https://stash.kopano.io/scm/ksc/lab-scripts.git /assets/kopano/scripts/lab-scripts && \
    git clone --depth 1 https://stash.kopano.io/scm/ksc/mail-migrations.git /assets/kopano/scripts/mail-migrations && \
    git clone --depth 1 https://stash.kopano.io/scm/ksc/support.git /assets/kopano/scripts/support && \
    git clone --depth 1 https://stash.kopano.io/scm/ksc/webapp-tools.git /assets/kopano/scripts/webapp-tools && \
    \
##### Configuration
    mkdir -p /assets/kopano/config && \
    cp -R /etc/kopano/* /assets/kopano/config/ && \
    mkdir -p /assets/kopano/templates && \
    cp -R /etc/kopano/quotamail/* /assets/kopano/templates && \
    rm -rf /etc/kopano/quotamail && \
    mkdir -p /assets/kopano/userscripts && \
    cp -R /etc/kopano/userscripts/* /assets/kopano/userscripts && \
    rm -rf /etc/kopano/userscripts && \
    mkdir -p /assets/kdav/config/ && \
    cp -R /usr/share/kdav/config.php /assets/kdav/config/ && \
    mkdir -p /assets/kopano/webapp-plugins && \
    mv /usr/share/kopano-webapp/plugins/* /assets/kopano/webapp-plugins && \
    mkdir -p /assets/zpush/config && \
    cp -R /usr/share/zpush/src/config.php /assets/zpush/config/ && \
    cp -R /usr/share/zpush/src/autodiscover/config.php /assets/zpush/config/config-autodiscover.php && \
    cp -R /usr/share/zpush/tools/gab2contacts/config.php /assets/zpush/config/config-gab2contacts.php && \
    cp -R /usr/share/zpush/tools/gab-sync/config.php /assets/zpush/config/config-gab-sync.php && \
    mkdir -p /assets/zpush/config/backend && \
    mkdir -p /assets/zpush/config/backend/ipcmemcached && \
    cp -R /usr/share/zpush//src/backend/ipcmemcached/config.php /assets/zpush/config/backend/ipcmemcached/ && \
    mkdir -p /assets/zpush/config/backend/kopano && \
    cp -R /usr/share/zpush/src/backend/kopano/config.php /assets/zpush/config/backend/kopano/ && \
    mkdir -p /assets/zpush/config/backend/sqlstatemachine && \
    cp -R /usr/share/zpush/src/backend/sqlstatemachine/config.php /assets/zpush/config/backend/sqlstatemachine/ && \
    rm -rf /etc/kopano && \
    ln -sf /config /etc/kopano && \
    \
    ##### Cleanup
    apt-get purge -y \
                      apt-utils \
                      git \
                      lynx \
                      && \
    \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /usr/src/* && \
    rm -rf /var/log/* && \
    cd /etc/fail2ban && \
    rm -rf fail2ban.conf fail2ban.d jail.conf jail.d paths-*.conf

### Assets Install
ADD install /
