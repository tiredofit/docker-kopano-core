FROM tiredofit/alpine:3.12 as webapp-builder

ENV KOPANO_WEBAPP_VERSION=v4.2 \
    KOPANO_WEBAPP_PLUGIN_DESKTOP_NOTIFICATIONS_REPO_URL=https://stash.kopano.io/scm/kwa/desktopnotifications.git \
    KOPANO_WEBAPP_PLUGIN_DESKTOP_NOTIFICATIONS_VERSION=tags/v2.0.3 \
    KOPANO_WEBAPP_PLUGIN_FILEPREVIEWER_REPO_URL=https://stash.kopano.io/scm/kwa/filepreviewer.git \
    KOPANO_WEBAPP_PLUGIN_FILEPREVIEWER_VERSION=tags/v2.2.0 \
    KOPANO_WEBAPP_PLUGIN_FILES_OWNCLOUD_REPO_URL=https://stash.kopano.io/scm/kwa/files-owncloud-backend.git \
    KOPANO_WEBAPP_PLUGIN_FILES_OWNCLOUD_VERSION=tags/v3.0.0 \
    KOPANO_WEBAPP_PLUGIN_FILES_REPO_URL=https://stash.kopano.io/scm/kwa/files.git \
    KOPANO_WEBAPP_PLUGIN_FILES_SEAFILE_REPO_URL=https://github.com/datamate-rethink-it/kopano-seafile-backend.git \
    KOPANO_WEBAPP_PLUGIN_FILES_SEAFILE_VERSION=master \
    KOPANO_WEBAPP_PLUGIN_FILES_SMB_REPO_URL=https://stash.kopano.io/scm/kwa/files-smb-backend.git \
    KOPANO_WEBAPP_PLUGIN_FILES_SMB_VERSION=tags/v3.0.0 \
    KOPANO_WEBAPP_PLUGIN_FILES_VERSION=tags/v3.0.0-beta.4 \
    KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_MINIMALTINY_REPO_URL=https://stash.kopano.io/scm/kwa/htmleditor-minimaltiny.git \
    KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_MINIMALTINY_VERSION=tags/1.0.0 \
    KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_QUILL_REPO_URL=https://stash.kopano.io/scm/kwa/htmleditor-quill.git \
    KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_QUILL_VERSION=master \
    KOPANO_WEBAPP_PLUGIN_INTRANET_REPO_URL=https://stash.kopano.io/scm/kwa/intranet.git \
    KOPANO_WEBAPP_PLUGIN_INTRANET_VERSION=tags/v1.0.1 \
    KOPANO_WEBAPP_PLUGIN_MATTERMOST_REPO_URL=https://stash.kopano.io/scm/kwa/mattermost.git \
    KOPANO_WEBAPP_PLUGIN_MATTERMOST_VERSION=tags/v1.0.1 \
    KOPANO_WEBAPP_PLUGIN_MDM_REPO_URL=https://stash.kopano.io/scm/kwa/mobile-device-management.git \
    KOPANO_WEBAPP_PLUGIN_MDM_VERSION=tags/v3.1 \
    KOPANO_WEBAPP_PLUGIN_ROCKETCHAT_REPO_URL=https://cloud.siedl.net/nextcloud/index.php/s/3yKYARgGwfSZe2c/download \
    KOPANO_WEBAPP_PLUGIN_ROCKETCHAT_VERSION=1.0.2-1 \
    KOPANO_WEBAPP_PLUGIN_SMIME_REPO_URL=https://stash.kopano.io/scm/kwa/smime.git \
    KOPANO_WEBAPP_PLUGIN_SMIME_VERSION=tags/v2.2.2 \
    KOPANO_WEBAPP_REPO_URL=https://github.com/Kopano-dev/kopano-webapp.git

RUN set -x && \
    apk update && \
    apk upgrade && \
    apk add -t .kopano_webapp-build-deps \
                apache-ant \
                build-base \
                coreutils \
                gettext-dev \
                git \
                libxml2-dev \
                libxml2-utils \
                nodejs \
                nodejs-npm \
                openjdk8 \
                openssl-dev \
                php7-dev \
                ruby-dev \
                rsync \
    && \
    \
    gem install compass && \
    \
    ### Fetch Source
    git clone -b ${KOPANO_WEBAPP_VERSION} --depth 1 ${KOPANO_WEBAPP_REPO_URL} /usr/src/kopano-webapp && \
    ### Build
    cd /usr/src/kopano-webapp && \
    ant deploy && \
    ant deploy-plugins && \
    \
    ### Setup RootFS
    mkdir -p /rootfs && \
    mkdir -p /rootfs/usr/share/kopano-webapp && \
    mkdir -p /rootfs/assets/kopano/config/webapp && \
    mkdir -p /rootfs/assets/kopano/plugins/webapp && \
    \
    ### Build Plugins
    ## Desktop Notifications
    git clone ${KOPANO_WEBAPP_PLUGIN_DESKTOP_NOTIFICATIONS_REPO_URL} /usr/src/kopano-webapp/plugins/desktopnotifications && \
    cd /usr/src/kopano-webapp/plugins/desktopnotifications && \
    git checkout ${KOPANO_WEBAPP_PLUGIN_DESKTOP_NOTIFICATIONS_VERSION} && \
    ant deploy && \
    cp /usr/src/kopano-webapp/deploy/plugins/desktopnotifications/config.php /rootfs/assets/kopano/config/webapp/config-desktopnotificatons.php && \
    ln -sf /etc/kopano/webapp/config-desktopnotifications.php /usr/src/kopano-webapp/deploy/plugins/desktopnotifications/config.php && \
    \
    ## File Previewer
    git clone ${KOPANO_WEBAPP_PLUGIN_FILEPREVIEWER_REPO_URL} /usr/src/kopano-webapp/plugins/filepreviewer && \
    cd /usr/src/kopano-webapp/plugins/filepreviewer && \
    git checkout ${KOPANO_WEBAPP_PLUGIN_FILEPREVIEWER_VERSION} && \
    ant deploy && \
    cp /usr/src/kopano-webapp/deploy/plugins/filepreviewer/config.php /rootfs/assets/kopano/config/webapp/config-filepreviewer.php && \
    ln -sf /etc/kopano/webapp/config-filepreviewer.php /usr/src/kopano-webapp/deploy/plugins/filepreviewer/config.php && \
    \
    ## Files
    git clone ${KOPANO_WEBAPP_PLUGIN_FILES_REPO_URL} /usr/src/kopano-webapp/plugins/files && \
    cd /usr/src/kopano-webapp/plugins/files && \
    git checkout ${KOPANO_WEBAPP_PLUGIN_FILES_VERSION} && \
    ant deploy && \
    cp /usr/src/kopano-webapp/deploy/plugins/files/config.php /rootfs/assets/kopano/config/webapp/config-files.php && \
    ln -sf /etc/kopano/webapp/config-files.php /usr/src/kopano-webapp/deploy/plugins/files/config.php && \
    \
    ## Files Backend: Owncloud
    set -x && \
    git clone ${KOPANO_WEBAPP_PLUGIN_FILES_OWNCLOUD_REPO_URL} /usr/src/kopano-webapp/plugins/filesbackendOwncloud && \
    cd /usr/src/kopano-webapp/plugins/filesbackendOwncloud && \
    git checkout ${KOPANO_WEBAPP_PLUGIN_FILES_OWNCLOUD_VERSION} && \
    ant deploy && \
    \
    ## Files Backend: SeaFile
    git clone ${KOPANO_WEBAPP_PLUGIN_FILES_SEAFILE_REPO_URL} /usr/src/kopano-webapp/plugins/filesbackendSeafile && \
    cd /usr/src/kopano-webapp/plugins/filesbackendSeafile && \
    git checkout ${KOPANO_WEBAPP_PLUGIN_FILES_SEAFILE_VERSION} && \
    cp -R php src && \
    make && \
    make deploy && \
    cp /usr/src/kopano-webapp/deploy/plugins/filesbackendSeafile/config.php /rootfs/assets/kopano/config/webapp/config-files-backend-seafile.php && \
    ln -sf /etc/kopano/webapp/config-files-backend-seafile.php /usr/src/kopano-webapp/deploy/plugins/filesbackendSeafile/config.php && \
    \
    ## Files Backend: SMB
    git clone ${KOPANO_WEBAPP_PLUGIN_FILES_SMB_REPO_URL} /usr/src/kopano-webapp/plugins/filesbackendSMB && \
    cd /usr/src/kopano-webapp/plugins/filesbackendSMB && \
    git checkout ${KOPANO_WEBAPP_PLUGIN_FILES_SMB_VERSION} && \
    ant deploy && \
    \
    ## HTML Editor: Minimal
    git clone ${KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_MINIMALTINY_REPO_URL} /usr/src/kopano-webapp/plugins/htmleditor-minimaltiny && \
    cd /usr/src/kopano-webapp/plugins/htmleditor-minimaltiny && \
    ant deploy && \
    \
    ## HTML Editor: Quill
    git clone ${KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_QUILL_REPO_URL} /usr/src/kopano-webapp/plugins/htmleditor-quill && \
    cd /usr/src/kopano-webapp/plugins/htmleditor-quill && \
    ant deploy && \
    \
    ## Intranet
    git clone ${KOPANO_WEBAPP_PLUGIN_INTRANET_REPO_URL} /usr/src/kopano-webapp/plugins/intranet && \
    cd /usr/src/kopano-webapp/plugins/intranet && \
    git checkout ${KOPANO_WEBAPP_PLUGIN_INTRANET_VERSION} && \
    ant deploy && \
    cp /usr/src/kopano-webapp/deploy/plugins/intranet/config.php /rootfs/assets/kopano/config/webapp/config-intranet.php && \
    ln -sf /etc/kopano/webapp/config-intranet.php /usr/src/kopano-webapp/deploy/plugins/intranet/config.php && \
    \
    ## Mobile Device Management
    git clone ${KOPANO_WEBAPP_PLUGIN_MDM_REPO_URL} /usr/src/kopano-webapp/plugins/mdm && \
    cd /usr/src/kopano-webapp/plugins/mdm && \
    git checkout ${KOPANO_WEBAPP_PLUGIN_MDM_VERSION} && \
    ant deploy && \
    cp /usr/src/kopano-webapp/deploy/plugins/mdm/config.php /rootfs/assets/kopano/config/webapp/config-mdm.php && \
    ln -sf /etc/kopano/webapp/config-mdm.php /usr/src/kopano-webapp/deploy/plugins/mdm/config.php && \
    \
    ## Mattermost
    git clone ${KOPANO_WEBAPP_PLUGIN_MATTERMOST_REPO_URL} /usr/src/kopano-webapp/plugins/mattermost && \
    cd /usr/src/kopano-webapp/plugins/mattermost && \
    git checkout ${KOPANO_WEBAPP_PLUGIN_MATTERMOST_VERSION} && \
    ant deploy && \
    cp /usr/src/kopano-webapp/deploy/plugins/mattermost/config.php /rootfs/assets/kopano/config/webapp/config-mattermost.php && \
    ln -sf /etc/kopano/webapp/config-mattermost.php /usr/src/kopano-webapp/deploy/plugins/mattermost/config.php && \
    \
    ## Rocketchat
    cd /usr/src/ && \
    curl -o /usr/src/rocketchat.zip "${KOPANO_WEBAPP_PLUGIN_ROCKETCHAT_REPO_URL}" && \
    unzip -d . rocketchat.zip && \
    cd Rocket.Chat && \
    ar x kopano-rocketchat-${KOPANO_WEBAPP_PLUGIN_ROCKETCHAT_VERSION}.deb && \
    tar xvfJ data.tar.xz && \
    cp etc/kopano/webapp/config-rchat.php /rootfs/assets/kopano/config/webapp/rocketchat.php && \
    cp -R usr/share/kopano-webapp/plugins/rchat /rootfs/assets/kopano/plugins/webapp/rchat && \
    ln -sf /etc/kopano/webapp/config-rchat.php /rootfs/assets/kopano/plugins/webapp/rchat/config.php && \
    \
    ## S/MIME
    git clone ${KOPANO_WEBAPP_PLUGIN_SMIME_REPO_URL} /usr/src/kopano-webapp/plugins/smime && \
    cd /usr/src/kopano-webapp/plugins/smime && \
    git checkout ${KOPANO_WEBAPP_PLUGIN_SMIME_VERSION} && \
    ant deploy && \
    cp /usr/src/kopano-webapp/deploy/plugins/smime/config.php /rootfs/assets/kopano/config/webapp/config-smime.php && \
    ln -sf /etc/kopano/webapp/config-smime.php /usr/src/kopano-webapp/deploy/plugins/smime/config.php && \
    \
    ### Move files to RootFS
    cp -R /usr/src/kopano-webapp/deploy/* /rootfs/usr/share/kopano-webapp/ && \
    cd /rootfs/usr/share/kopano-webapp/ && \
    mv *.dist /rootfs/assets/kopano/config/webapp && \
    ln -sf /etc/kopano/webapp/config.php config.php && \
    mv plugins/* /rootfs/assets/kopano/plugins/webapp/ && \
    cp /rootfs/assets/kopano/plugins/webapp/contactfax/config.php /rootfs/assets/kopano/config/webapp/contactfax.php && \
    ln -sf /etc/kopano/webapp/config-contactfax.php /rootfs/assets/kopano/plugins/webapp/contactfax/config.php && \
    cp /rootfs/assets/kopano/plugins/webapp/gmaps/config.php /rootfs/assets/kopano/config/webapp/gmaps.php && \
    ln -sf /etc/kopano/webapp/config-gmaps.php /rootfs/assets/kopano/plugins/webapp/gmaps/config.php && \
    cp /rootfs/assets/kopano/plugins/webapp/pimfolder/config.php /rootfs/assets/kopano/config/webapp/pimfolder.php && \
    ln -sf /etc/kopano/webapp/config-pimfolder.php /rootfs/assets/kopano/plugins/webapp/pimfolder/config.php && \
    \
    ### Fetch Additional Scripts
    mkdir -p /rootfs/assets/kopano/scripts && \
    git clone --depth 1 https://stash.kopano.io/scm/ksc/webapp-tools.git /assets/kopano/scripts/webapp-tools && \
    \
    ### Compress Package
    cd /rootfs/ && \
    echo "Kopano Webapp built from ${KOPANO_WEBAPP_REPO_URL} on $(date)" > /rootfs/.kopano-webapp-version && \
    echo "Commit: $(cd /usr/src/kopano-webapp ; echo $(git rev-parse HEAD))" >> /rootfs/.kopano-webapp-version && \
    env | grep KOPANO | sort >> /rootfs/.webapp-version && \
    tar cvfz /kopano-webapp.tar.gz .

FROM tiredofit/nginx-php-fpm:debian-7.3
LABEL maintainer="Dave Conroy (dave at tiredofit dot ca)"

### Move Previously built Webapp into image
COPY --from=webapp-builder /kopano-webapp.tar.gz /usr/src/kopano-webapp.tar.gz

ENV KOPANO_CORE_VERSION=10.0.6 \
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
                       man \
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
### Kopano Core
    mkdir -p /usr/src/deb-core && \
    kcore_version=`lynx -listonly -nonumbers -dump https://download.kopano.io/community/core:/ | grep -o core-.*-Debian_10-amd64.tar.gz | sed "s/%2B/+/g " | sed "s/-Debian_10.*//g"` && \
    echo "Kopano Core Version: ${kcore_version} on $(date)" >> /.kopano-versions && \
    curl -L `lynx -listonly -nonumbers -dump https://download.kopano.io/community/core:/ | grep Debian_10-amd64.tar.gz` | tar xvfz - --strip 1 -C /usr/src/deb-core && \
    cd /usr/src/deb-core && \
    apt-ftparchive packages ./ > /usr/src/deb-core/Packages && \
    echo "deb [trusted=yes] file:/usr/src/deb-core/ /" >> /etc/apt/sources.list.d/kopano-core.list && \
    \
######## https://stash.kopano.io/users/jvanderwaa/repos/php-kopano-smime/browse
### Kopano SMIME
    mkdir -p /usr/src/deb-smime && \
    smime_version=`lynx -listonly -nonumbers -dump https://download.kopano.io/community/smime:/ | grep -o smime-.*-Debian_10-amd64.tar.gz | sed "s/%2B/+/g " | sed "s/-Debian_10.*//g"` && \
    echo "Kopano S/MIME Version: ${smime_version} on $(date)" >> /.kopano-versions && \
    curl -L `lynx -listonly -nonumbers -dump https://download.kopano.io/community/smime:/ | grep Debian_10-amd64.tar.gz` | tar xvfz - --strip 1 -C /usr/src/deb-smime && \
    cd /usr/src/deb-smime && \
    apt-ftparchive packages ./ > /usr/src/deb-smime/Packages && \
    echo "deb [trusted=yes] file:/usr/src/deb-smime/ /" >> /etc/apt/sources.list.d/kopano-smime.list && \
    \
### Kopano Archiver
    mkdir -p /usr/src/deb-archiver && \
    archiver_version=`lynx -listonly -nonumbers -dump https://download.kopano.io/community/archiver:/ | grep -o archiver-.*-Debian_10-amd64.tar.gz | sed "s/%2B/+/g " | sed "s/-Debian_10.*//g"` && \
    echo "Kopano Archiver Version: ${archiver_version} on $(date)" >> /.kopano-versions && \
    curl -L `lynx -listonly -nonumbers -dump https://download.kopano.io/community/archiver:/ | grep Debian_10-amd64.tar.gz` | tar xvfz - --strip 1 -C /usr/src/deb-archiver && \
    cd /usr/src/deb-archiver && \
    apt-ftparchive packages ./ > /usr/src/deb-archiver/Packages && \
    echo "deb [trusted=yes] file:/usr/src/deb-archiver/ /" >> /etc/apt/sources.list.d/kopano-archiver.list && \
    \
### Kopano Apps (Calendar)
    mkdir -p /usr/src/deb-kapps && \
    kapps_version=`lynx -listonly -nonumbers -dump https://download.kopano.io/community/kapps:/ | grep -o kapps-.*-Debian_10-amd64.tar.gz | sed "s/%2B/+/g" | sed "s/-Debian_10.*//g"` && \
    echo "Kopano Apps Version: ${kapps_version} on $(date)" >> /.kopano-versions && \
    curl -L `lynx -listonly -nonumbers -dump https://download.kopano.io/community/kapps:/ | grep Debian_10-amd64.tar.gz` | tar xvfz - --strip 1 -C /usr/src/deb-kapps && \
    cd /usr/src/deb-kapps && \
    apt-ftparchive packages ./ > /usr/src/deb-kapps/Packages && \
    echo "deb [trusted=yes] file:/usr/src/deb-kapps/ /" >> /etc/apt/sources.list.d/kopano-kapps.list && \
    \
    ### Kopano Meet
    mkdir -p /usr/src/deb-meet && \
    meet_version=`lynx -listonly -nonumbers -dump https://download.kopano.io/community/meet:/ | grep -o meet-.*-Debian_10-amd64.tar.gz | sed "s/%2B/+/g " | sed "s/-Debian_10.*//g"` && \
    echo "Kopano Meet Version: ${meet_version} on $(date)" >> /.kopano-versions && \
    curl -L `lynx -listonly -nonumbers -dump https://download.kopano.io/community/meet:/ | grep Debian_10-amd64.tar.gz` | tar xvfz - --strip 1 -C /usr/src/deb-meet && \
    cd /usr/src/deb-meet && \
    apt-ftparchive packages ./ > /usr/src/deb-meet/Packages && \
    echo "deb [trusted=yes] file:/usr/src/deb-meet/ /" >> /etc/apt/sources.list.d/kopano-meet.list && \
    \
    ### Kopano Webapp
    mkdir -p /usr/src/deb-webapp && \
    meet_version=`lynx -listonly -nonumbers -dump https://download.kopano.io/community/webapp:/ | grep -o meet-.*-Debian_10-all.tar.gz | sed "s/%2B/+/g " | sed "s/-Debian_10.*//g"` && \
    echo "Kopano Webapp Version: ${meet_version} on $(date)" >> /.kopano-versions && \
    curl -L `lynx -listonly -nonumbers -dump https://download.kopano.io/community/webapp:/ | grep Debian_10-all.tar.gz` | tar xvfz - --strip 1 -C /usr/src/deb-webapp && \
    cd /usr/src/deb-webapp && \
    apt-ftparchive packages ./ > /usr/src/deb-webapp/Packages && \
    echo "deb [trusted=yes] file:/usr/src/deb-webapp/ /" >> /etc/apt/sources.list.d/kopano-webapp.list && \
    \
    ##### Install Packages
    apt-get update && \
    apt-get install -y --no-install-recommends \
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
                       #kopano-webapp \
                       php7-mapi \
                       php-kopano-smime \
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
    composer install && \
    \
    ### Miscellanious Scripts
    mkdir -p /assets/kopano/scripts && \
    git clone --depth 1 https://stash.kopano.io/scm/ksc/Core-tools.git /assets/kopano/scripts/core-tools && \
    git clone --depth 1 https://stash.kopano.io/scm/ksc/lab-scripts.git /assets/kopano/scripts/lab-scripts && \
    git clone --depth 1 https://stash.kopano.io/scm/ksc/mail-migrations.git /assets/kopano/scripts/mail-migrations && \
    git clone --depth 1 https://stash.kopano.io/scm/ksc/support.git /assets/kopano/scripts/support && \
    \
    ##### Unpack WebApp
    tar xvfz /usr/src/kopano-webapp.tar.gz -C / && \
    \
    ##### Configuration
    mkdir -p /assets/kopano/config && \
    cp -R /etc/kopano/* /assets/kopano/config/ && \
    mkdir -p /assets/kopano/templates && \
    cp -R /etc/kopano/quotamail/* /assets/kopano/templates && \
    rm -rf /etc/kopano/quotamail && \
    mkdir -p /assets/kopano/userscripts && \
    mkdir -p /assets/kopano/userscripts/createcompany.d \
             /assets/kopano/userscripts/creategroup.d \
             /assets/kopano/userscripts/createuser.d \
             /assets/kopano/userscripts/deletecompany.d \
             /assets/kopano/userscripts/deletegroup.d \
             /assets/kopano/userscripts/deleteuser.d && \
    cp -R /usr/lib/kopano/userscripts /assets/kopano/userscripts && \
    mkdir -p /assets/kdav/config/ && \
    cp -R /usr/share/kdav/config.php /assets/kdav/config/ && \
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
    rm -rf /etc/apt/sources.list.d/kopano*.list && \
    rm -rf /usr/src/* && \
    rm -rf /var/log/* && \
    cd /etc/fail2ban && \
    rm -rf fail2ban.conf fail2ban.d jail.conf jail.d paths-*.conf

### Assets Install
ADD install /
