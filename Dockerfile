FROM tiredofit/alpine:3.12 as webapp-builder

ENV KOPANO_WEBAPP_VERSION=v4.1
ENV KOPANO_WEBAPP_REPO_URL=https://github.com/Kopano-dev/kopano-webapp \
    KOPANO_WEBAPP_PLUGIN_DESKTOP_NOTIFICATIONS_VERSION=2.0.3 \
    KOPANO_WEBAPP_PLUGIN_FILEPREVIEWER_VERSION=2.2.0 \
    KOPANO_WEBAPP_PLUGIN_FILES_VERSION=3.0.0-beta.4 \
    KOPANO_WEBAPP_PLUGIN_FILES_OWNCLOUD_VERSION=3.0.0 \
    KOPANO_WEBAPP_PLUGIN_FILES_SMB_VERSION=3.0.0 \
    KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_MINIMALTINY_VERSION=1.0.0 \
    KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_QUILL_VERSION=master \
    KOPANO_WEBAPP_PLUGIN_INTRANET_VERSION=1.0.1 \
    KOPANO_WEBAPP_PLUGIN_MATTERMOST_VERSION=1.0.1 \
    KOPANO_WEBAPP_PLUGIN_MDM_VERSION=3.1 \
    KOPANO_WEBAPP_PLUGIN_ROCKETCHAT_VERSION=1.0.2-1 \
    KOPANO_WEBAPP_PLUGIN_SMIME_VERSION=2.2.2

RUN set -x && \
    apk update && \
    apk upgrade && \
    apk add -t .kopano_webapp-build-deps \
                apache-ant \
                build-base \
                coreutils \
                git \
                libxml2-dev \
                libxml2-utils \
                nodejs \
                nodejs-npm \
                openjdk8 \
                openssl-dev \
                php7-dev \
                ruby-dev \
                && \
    \
    ### Fetch Source
    git clone -b ${KOPANO_WEBAPP_VERSION} --depth 1 ${KOPANO_WEBAPP_REPO_URL} /usr/src/kopano-webapp && \
    ### Build
    cd /usr/src/kopano-webapp && \
    ant deploy && \
    ant deploy-plugins && \
    ### Create RootFS
    mkdir -p /rootfs && \
    mkdir -p /rootfs/usr/share/kopano-webapp && \
    mkdir -p /rootfs/assets/kopano/config/webapp && \
    mkdir -p /rootfs/assets/kopano/plugins/webapp && \
    cp -R /usr/src/kopano-webapp/deploy/* /rootfs/usr/share/kopano-webapp/ && \
    cd /rootfs/usr/share/kopano-webapp/ && \
    mv *.dist /rootfs/assets/kopano/config/webapp && \
    ln -sf /etc/kopano/webapp/config.php config.php && \
    mv plugins/* /rootfs/assets/kopano/plugins/webapp/ && \
    cp /rootfs/assets/kopano/plugins/webapp/contactfax/config.php /rootfs/assets/kopano/config/webapp/contactfax.php && \
    ln -sf /etc/kopano/webapp/contactfax.php /rootfs/assets/kopano/plugins/webapp/contactfax/config.php && \
    cp /rootfs/assets/kopano/plugins/webapp/gmaps/config.php /rootfs/assets/kopano/config/webapp/gmaps.php && \
    ln -sf /etc/kopano/webapp/gmaps.php /rootfs/assets/kopano/plugins/webapp/gmaps/config.php && \
    cp /rootfs/assets/kopano/plugins/webapp/pimfolder/config.php /rootfs/assets/kopano/config/webapp/pimfolder.php && \
    ln -sf /etc/kopano/webapp/pimfolder.php /rootfs/assets/kopano/plugins/webapp/pimfolder/config.php && \
    \
    ## Plugins
    ## Desktop Notifications
    mkdir -p /rootfs/assets/kopano/plugins/webapp/desktopnotifications && \
    curl -sSL "https://stash.kopano.io/rest/api/latest/projects/KWA/repos/desktopnotifications/archive?at=refs%2Ftags%2Fv${KOPANO_WEBAPP_PLUGIN_DESKTOP_NOTIFICATIONS_VERSION}&format=tar.gz" | tar xvfz - -C /rootfs/assets/kopano/plugins/webapp/desktopnotifications && \
    cp /rootfs/assets/kopano/plugins/webapp/desktopnotifications/config.php /rootfs/assets/kopano/config/webapp/desktopnotifications.php && \
    ln -sf /etc/kopano/webapp/desktopnotifications.php /rootfs/assets/kopano/plugins/webapp/desktopnotifications/config.php && \
    \
    ## File Previewer
    mkdir -p /rootfs/assets/kopano/plugins/webapp/filepreviewer && \
    curl -sSL "https://stash.kopano.io/rest/api/latest/projects/KWA/repos/filepreviewer/archive?at=refs%2Ftags%2Fv${KOPANO_WEBAPP_PLUGIN_FILEPREVIEWER_VERSION}&format=tar.gz"  | tar xvfz - -C /rootfs/assets/kopano/plugins/webapp/filepreviewer && \
    cp /rootfs/assets/kopano/plugins/webapp/filepreviewer/config.php /rootfs/assets/kopano/config/webapp/filepreviewer.php && \
    ln -sf /etc/kopano/webapp/filepreviewer.php /rootfs/assets/kopano/plugins/webapp/filepreviewer/config.php && \
    \
    ## Files
    mkdir -p /rootfs/assets/kopano/plugins/webapp/files && \
    curl -sSL "https://stash.kopano.io/rest/api/latest/projects/KWA/repos/files/archive?at=refs%2Ftags%2Fv${KOPANO_WEBAPP_PLUGIN_FILES_VERSION}&format=tar.gz" | tar xvfz - -C /rootfs/assets/kopano/plugins/webapp/files && \
    cp /rootfs/assets/kopano/plugins/webapp/files/config.php /rootfs/assets/kopano/config/webapp/files.php && \
    ln -sf /etc/kopano/webapp/files.php /rootfs/assets/kopano/plugins/webapp/files/config.php && \
    \
    ## Files Backend: Owncloud
    mkdir -p /rootfs/assets/kopano/plugins/webapp/filesbackendOwncloud && \
    curl -sSL "https://stash.kopano.io/rest/api/latest/projects/KWA/repos/files-owncloud-backend/archive?at=refs%2Ftags%2Fv${KOPANO_WEBAPP_PLUGIN_FILES_OWNCLOUD_VERSION}&format=tar.gz" | tar xvfz - -C /rootfs/assets/kopano/plugins/webapp/filesbackendOwncloud && \
    \
    ## Files Backend: SMB
    mkdir -p /rootfs/assets/kopano/plugins/webapp/files-smb-backend && \
    curl -sSL "https://stash.kopano.io/rest/api/latest/projects/KWA/repos/files-smb-backend/archive?at=refs%2Ftags%2Fv${KOPANO_WEBAPP_PLUGIN_FILES_SMB_VERSION}&format=tar.gz" | tar xvfz - -C /rootfs/assets/kopano/plugins/webapp/files-smb-backend && \
    \
    ## Files Backend: Seafile
    git clone --depth 1 https://github.com/datamate-rethink-it/kopano-seafile-backend /rootfs/assets/kopano/plugins/webapp/filesbackendSeafile && \
    cd /rootfs/assets/kopano/plugins/webapp/filesbackendSeafile && \
    make && \
    cp /rootfs/assets/kopano/plugins/webapp/filesbackendSeafile/config.php /rootfs/assets/kopano/config/webapp/files-seafile-backend.php && \
    ln -sf /etc/kopano/webapp/files-seafile-backend.php /rootfs/assets/kopano/plugins/webapp/filesbackendSeafile/config.php && \
    \
    ## HTML Editor: Minimal
    mkdir -p /rootfs/assets/kopano/plugins/webapp/htmleditor-minimaltiny && \
    curl -sSL "https://stash.kopano.io/rest/api/latest/projects/KWA/repos/htmleditor-minimaltiny/archive?at=refs%2Ftags%2Fv${KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_MINIMALTINY_VERSION}&format=tar.gz" | tar xvfz - -C /rootfs/assets/kopano/plugins/webapp/htmleditor-minimaltiny && \
    \
    ## HTML Editor: Quill
    mkdir -p /rootfs/assets/kopano/plugins/webapp/htmleditor-quill && \
    curl -sSL "https://stash.kopano.io/rest/api/latest/projects/KWA/repos/htmleditor-quill/archive?format=tar.gz" | tar xvfz - -C /rootfs/assets/kopano/plugins/webapp/htmleditor-quill && \
    \
    ## Intranet
    mkdir -p /rootfs/assets/kopano/plugins/webapp/intranet && \
    curl -sSL "https://stash.kopano.io/rest/api/latest/projects/KWA/repos/intranet/archive?at=refs%2Ftags%2Fv${KOPANO_WEBAPP_PLUGIN_INTRANET_VERSION}&format=tar.gz" | tar xvfz - -C /rootfs/assets/kopano/plugins/webapp/intranet && \
    cp /rootfs/assets/kopano/plugins/webapp/intranet/config.php /rootfs/assets/kopano/config/webapp/intranet.php && \
    ln -sf /etc/kopano/webapp/intranet.php /rootfs/assets/kopano/plugins/webapp/intranet/config.php && \
    \
    ## Mobile Device Management
    mkdir -p /rootfs/assets/kopano/plugins/webapp/mdm && \
    curl -sSL "https://stash.kopano.io/rest/api/latest/projects/KWA/repos/mobile-device-management/archive?at=refs%2Ftags%2Fv${KOPANO_WEBAPP_PLUGIN_MDM_VERSION}&format=tar.gz" | tar xvfz - -C /rootfs/assets/kopano/plugins/webapp/mdm && \
    cp /rootfs/assets/kopano/plugins/webapp/mdm/config.php /rootfs/assets/kopano/config/webapp/mdm.php && \
    ln -sf /etc/kopano/webapp/mdm.php /rootfs/assets/kopano/plugins/webapp/mdm/config.php && \
    \
    ## Mattermost
    mkdir -p /rootfs/assets/kopano/plugins/webapp/mattermost && \
    curl -sSL "https://stash.kopano.io/rest/api/latest/projects/KWA/repos/mattermost/archive?at=refs%2Ftags%2Fv${KOPANO_WEBAPP_PLUGIN_MATTERMOST_VERSION}&format=tar.gz" | tar xvfz - -C /rootfs/assets/kopano/plugins/webapp/mattermost && \
    cp /rootfs/assets/kopano/plugins/webapp/mattermost/config.php /rootfs/assets/kopano/config/webapp/mattermost.php && \
    ln -sf /etc/kopano/webapp/mattermost.php /rootfs/assets/kopano/plugins/webapp/mattermost/config.php && \
    \
    ## Rocketchat
    cd /usr/src/ && \
    curl -o /usr/src/rocketchat.zip "https://cloud.siedl.net/nextcloud/index.php/s/3yKYARgGwfSZe2c/download" && \
    unzip -d . rocketchat.zip && \
    cd Rocket.Chat && \
    ar x kopano-rocketchat-${KOPANO_WEBAPP_PLUGIN_ROCKETCHAT_VERSION}.deb && \
    tar xvfJ data.tar.xz && \
    cp etc/kopano/webapp/config-rchat.php /rootfs/assets/kopano/config/webapp/rocketchat.php && \
    cp -R usr/share/kopano-webapp/plugins/rchat /rootfs/assets/kopano/plugins/webapp/rchat && \
    ln -sf /etc/kopano/webapp/rocketchat.php /rootfs/assets/kopano/plugins/webapp/rchat/config.php && \
    \
    ## S/MIME
    mkdir -p /rootfs/assets/kopano/plugins/webapp/smime && \
    curl -sSL "https://stash.kopano.io/rest/api/latest/projects/KWA/repos/smime/archive?at=refs%2Ftags%2Fv${KOPANO_WEBAPP_PLUGIN_SMIME_VERSION}&format=tar.gz" | tar xvfz - -C /rootfs/assets/kopano/plugins/webapp/smime && \
    cp /rootfs/assets/kopano/plugins/webapp/smime/config.php /rootfs/assets/kopano/config/webapp/smime.php && \
    ln -sf /etc/kopano/webapp/smime.php /rootfs/assets/kopano/plugins/webapp/smime/config.php && \
    \
    ### Fetch Additional Scripts
    mkdir -p /rootfs/assets/kopano/scripts && \
    git clone --depth 1 https://stash.kopano.io/scm/ksc/webapp-tools.git /assets/kopano/scripts/webapp-tools && \
    \
    ### Compress Package
    cd /rootfs/ && \
    echo "Kopano Webapp built from ${KOPANO_WEBAPP_REPO_URL} on $(date)" > /rootfs/.webapp-version && \
    echo "Commit: $(cd /usr/src/kopano-webapp ; echo $(git rev-parse HEAD))" >> /rootfs/.webapp-version && \
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
### Kopano Meet
    mkdir -p /usr/src/deb-meet && \
    meet_version=`lynx -listonly -nonumbers -dump https://download.kopano.io/community/meet:/ | grep -o meet-.*-Debian_10-amd64.tar.gz | sed "s/%2B/+/g " | sed "s/-Debian_10.*//g"` && \
    echo "Kopano Meet Version: ${meet_version} on $(date)" >> /.kopano-versions && \
    curl -L `lynx -listonly -nonumbers -dump https://download.kopano.io/community/meet:/ | grep Debian_10-amd64.tar.gz` | tar xvfz - --strip 1 -C /usr/src/deb-meet && \
    cd /usr/src/deb-meet && \
    apt-ftparchive packages ./ > /usr/src/deb-meet/Packages && \
    echo "deb [trusted=yes] file:/usr/src/deb-meet/ /" >> /etc/apt/sources.list.d/kopano-meet.list && \
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
    mkdir -p createcompany.d  creategroup.d	createuser.d  deletecompany.d  deletegroup.d  deleteuser.d && \
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
    rm -rf /usr/src/* && \
    rm -rf /var/log/* && \
    cd /etc/fail2ban && \
    rm -rf fail2ban.conf fail2ban.d jail.conf jail.d paths-*.conf

### Assets Install
ADD install /
