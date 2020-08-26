FROM tiredofit/debian:buster as core-builder

ENV GO_VERSION=1.15 \
    KOPANO_CORE_VERSION=master \
    KOPANO_CORE_REPO_URL=https://github.com/Kopano-dev/kopano-core.git \
    KOPANO_DEPENDENCY_HASH=51c3a68 \
    KOPANO_KCOIDC_REPO_URL=https://github.com/Kopano-dev/libkcoidc.git \
    KOPANO_KCOIDC_VERSION=v0.9.2

RUN set -x && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
                    apt-utils \
                    && \
    \
    # Fetch Go
    mkdir -p /usr/local/go && \
    curl -sSL https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz | tar xvfz - --strip 1 -C /usr/local/go && \
    \
    # Get kopano-dependencies and create local repository
    mkdir -p /usr/src/deb-kopano-dependencies && \
    curl -sSL https://download.kopano.io/community/dependencies:/kopano-dependencies-${KOPANO_DEPENDENCY_HASH}-Debian_10-amd64.tar.gz | tar xvfz - --strip 1 -C /usr/src/deb-kopano-dependencies/ && \
    cd /usr/src/deb-kopano-dependencies && \
    apt-ftparchive packages . | gzip -c9 > Packages.gz && \
    echo "deb [trusted=yes] file:/usr/src/deb-kopano-dependencies ./" > /etc/apt/sources.list.d/kopano-dependencies.list && \
    \
    apt-get update -y && \
    apt-get install -y --no-install-recommends \
                        autoconf \
                        automake \
                        autotools-dev \
                        binutils \
                        debhelper \
                        devscripts \
                        dh-systemd \
                        flake8 \
                        g++ \
                        gettext \
                        git \
                        gsoap \
                        libcurl4-openssl-dev \
                        libdb++-dev \
                        libgoogle-perftools-dev \
                        libgsoap-dev \
                        libhx-dev \
                        libical-dev \
                        libicu-dev \
                        libjsoncpp-dev \
                        libkcoidc-dev \
                        libkrb5-dev \
                        libldap2-dev \
                        libmariadbclient-dev \
                        libncurses-dev \
                        libpam0g-dev \
                        librrd-dev \
                        libs3-dev \
                        libssl-dev \
                        libtool \
                        libtool-bin \
                        libvmime-dev \
                        libxapian-dev \
                        libxml2-dev \
                        lsb-release \
                        m4 \
                        php-dev \
                        pkg-config \
                        python3-dateutil \
                        python3-dev \
                        python3-pillow \
                        python3-pytest \
                        python3-setuptools \
                        python3-tz \
                        python3-tzlocal \
                        swig \
                        tidy-html5-dev \
                        uuid-dev \
                        unzip \
                        zlib1g-dev

    ### Build libkcoidc
RUN set -x && \
    git clone ${KOPANO_KCOIDC_REPO_URL} /usr/src/libkcoidc && \
    cd /usr/src/libkcoidc && \
    git checkout ${KOPANO_KCOIDC_VERSION} && \
    autoreconf -fiv && \
    ./configure \
                --prefix /usr \
                --exec-prefix=/usr \
                --localstatedir=/var \
                --libdir=/usr/lib \
                GOROOT=/usr/local/go \
                PATH=/usr/local/go/bin:$PATH \
                && \
    make -j $(nproc) && \
    make install && \
    mkdir -p /rootfs && \
    make DESTDIR=/rootfs install && \
    PYTHON="$(which python3)" make DESTDIR=/rootfs python && \
    echo "Kopano kcOIDC built from ${KOPANO_KCOIDC_REPO_URL} on $(date)" > /rootfs/.kopano-kcoidc-version && \
    echo "Commit: $(cd /usr/src/libkcoidc ; echo $(git rev-parse HEAD))" >> /rootfs/.kopano-kcoidc-version && \
    cd /rootfs && \
    tar cvfz /kopano-kcoidc.tar.gz . && \
    cd /usr/src && \
    rm -rf /rootfs

RUN set -x && \
    git clone ${KOPANO_CORE_REPO_URL} /usr/src/kopano-core && \
    cd /usr/src/kopano-core && \
    git checkout ${KOPANO_CORE_VERSION} && \
    mkdir -p /rootfs && \
    cd /usr/src/kopano-core && \
    autoreconf -fiv && \
    ./configure \
                --prefix /usr \
                --exec-prefix=/usr \
                --localstatedir=/var \
                --libdir=/usr/lib \
                --sysconfdir=/etc \
                --sbindir=/usr/bin \
                --datarootdir=/usr/share \
                --includedir=/usr/include \
                --enable-epoll \
                --enable-kcoidc \
                --enable-release \
                --enable-pybind \
                --enable-static \
                PYTHON="$(which python3)" \
                PYTHON_CFLAGS="$(pkg-config python3 --cflags)"\
                PYTHON_LIBS="$(pkg-config python3 --libs)" \
                TCMALLOC_CFLAGS=" " \
                TCMALLOC_LIBS="-ltcmalloc_minimal" \
                && \
    make -j$(nproc) && \
    make \
        DESTDIR=/rootfs \
        PYTHONPATH=/rootfs/usr/lib/python3.7/dist-packages \
        install \
        && \
    \
    cd /rootfs && \
    ### Hack until figure out how to send it properly to dist-packages
    mv usr/lib/python$(python3 --version | awk '{print $2}' | cut -c 1-3)/site-packages usr/lib/python$(python3 --version | awk '{print $2}' | cut -c 1-3)/dist-packages && \
    ###
    echo "Kopano Core built from ${KOPANO_CORE_REPO_URL} on $(date)" > /rootfs/.kopano-core-version && \
    echo "Commit: $(cd /usr/src/kopano-webapp ; echo $(git rev-parse HEAD))" >> /rootfs/.kopano-core-version && \
    env | grep KOPANO | sort >> /rootfs/.kopano-core-version && \
    echo "Dependency Hash '${KOPANO_DEPENDENCY_HASH} from: 'https://download.kopano.io/community/dependencies:'" >> /rootfs/.kopano-core-version && \
    tar cvfz /kopano-core.tar.gz .

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
    git clone ${KOPANO_WEBAPP_REPO_URL} /usr/src/kopano-webapp && \
    cd /usr/src/kopano-webapp && \
    git checkout ${KOPANO_WEBAPP_VERSION} && \
    \
    ### Build
    ant deploy && \
    ant deploy-plugins && \
    make all && \
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
    env | grep KOPANO | sort >> /rootfs/.kopano-webapp-version && \
    tar cvfz /kopano-webapp.tar.gz .

FROM tiredofit/nginx-php-fpm:debian-7.3
LABEL maintainer="Dave Conroy (dave at tiredofit dot ca)"

### Move Previously built Kopano KCOIDCCore into image
COPY --from=core-builder /kopano-kcoidc.tar.gz /usr/src/kopano-kcoidc.tar.gz

### Move Previously built Kopano Core into image
COPY --from=core-builder /kopano-core.tar.gz /usr/src/kopano-core.tar.gz

### Move Previously built Webapp into image
COPY --from=webapp-builder /kopano-webapp.tar.gz /usr/src/kopano-webapp.tar.gz

ENV KOPANO_DEPENDENCY_HASH=51c3a68 \
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
    ### Add user and Group
    addgroup --gid 998 kopano && \
    adduser --uid 998 \
            --gid 998 \
            --gecos "Kopano User" \
            --home /dev/null \
            --no-create-home \
            --shell /sbin/nologin \
            --disabled-login \
            --disabled-password \
            kopano && \
    \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
                       apt-utils \
                       lynx \
                       git \
                       && \
    \
### Kopano Dependencies
    mkdir -p /usr/src/deb-kopano-dependencies && \
    curl -sSL https://download.kopano.io/community/dependencies:/kopano-dependencies-${KOPANO_DEPENDENCY_HASH}-Debian_10-amd64.tar.gz | tar xvfz - --strip 1 -C /usr/src/deb-kopano-dependencies/ && \
    cd /usr/src/deb-kopano-dependencies && \
    apt-ftparchive packages . | gzip -c9 > Packages.gz && \
    echo "deb [trusted=yes] file:/usr/src/deb-kopano-dependencies ./" > /etc/apt/sources.list.d/kopano-dependencies.list && \
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
    ##### Install Packages
    apt-get update && \
    apt-get install -y --no-install-recommends \
                       #kopano-archiver \
                       #kopano-bash-completion \
                       #kopano-calendar \
                       #kopano-calendar-webapp \
                       #kopano-grapi \
                       #kopano-grapi-bin \
                       #kopano-indexer \
                       #kopano-kapid \
                       #kopano-konnectd \
                       #kopano-kwmserverd \
                       #kopano-meet \
                       #kopano-migration-imap \
                       #kopano-migration-pst \
                       #kopano-python3-extras \
                       #kopano-python3-kopano10 \
                       #kopano-server-packages \
                       #kopano-spamd \
                       #kopano-statsd \
                       #kopano-webapp \
                       #php7-mapi \
                       php-kopano-smime \
                       #python3-grapi.backend.ldap \
                       ## Server \
                       libdb5.3++ \
                       libgsoap-kopano-2.8.102 \
                       libhx28 \
                       libical3 \
                       libjsoncpp1 \
                       libpython3.7 \
                       libs3-4 \
                       libvmime-kopano3 \
                       poppler-utils \
                       python3-bsddb3 \
                       python3-daemon \
                       python3-dateutil \
                       python3-lockfile \
                       python3-magic \
                       python3-mapi \
                       python3-six \
                       python3-tz \
                       python3-tzlocal \
                       python3-xapian \
                       bc \
                       fail2ban \
                       iptables \
                       man \
                       php-memcached \
                       php-tokenizer \
                       python3-pip \
                       python3-wheel \
                       python3-setuptools \
                       sqlite3 \
                       && \
    ## Python Deps for Spamd
    pip3 install inotify && \
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
    ##### Unpack KCOIDC
    tar xvfz /usr/src/kopano-kcoidc.tar.gz -C / && \
    \
    ##### Unpack Core
    tar xvfz /usr/src/kopano-core.tar.gz -C / && \
    \
    ##### Unpack WebApp
    tar xvfz /usr/src/kopano-webapp.tar.gz -C / && \
    chown -R nginx:www-data /assets/kopano/plugins/webapp && \
    chown -R nginx:www-data /usr/share/kopano-webapp && \
    echo "mapi.so" > /etc/php/$(php-fpm -v | head -n 1 | awk '{print $2}' | cut -c 1-3)/fpm/conf.d/20-mapi.ini && \
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
    mkdir -p /var/run/kopano && \
    chown -R kopano /var/run/kopano && \
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

#FROM tiredofit/debian:buster as meet-builder
#
#ENV GO_VERSION=1.15 \
#    GRAPI_REPO_URL=https://github.com/Kopano-dev/grapi \
#    GRAPI_VERSION=v10.5.0
#    KAPI_REPO_URL=https://github.com/Kopano-dev/kapi \
#    KAPI_VERSION=v0.15.0
#    KONNECT_REPO_URL=https://github.com/Kopano-dev/konnect \
#    KONNECT_VERSION=v0.33.5 \
#    KWMBRIDGE_REPO_URL=https://github.com/Kopano-dev/kwmbridge \
#    KWMBRIDGE_VERSION=v0.10.0
#    KWMSERVER_REPO_URL=https://github.com/Kopano-dev/kwmserver \
#    KWMSERVER_VERSION=v1.20.0
#
#RUN set -x && \
#    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
#    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
#    apt-get update && \
#    apt-get upgrade -y && \
#    apt-get install -y \
#		            apt-utils \
#                    build-essential \
#                    gettext-base \
#                    git \
#                    imagemagick \
#		            nodejs \
#		            python-scour \
#                    yarn \
#                    && \
#    \
#    # Fetch Go
#    mkdir -p /usr/local/go && \
#    curl -sSL https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz | tar xvfz - --strip 1 -C /usr/local/go && \
#    \
#    ### Build Konnect
#    git clone ${KONNECT_REPO_URL} /usr/src/konnect && \
#    cd /usr/src/konnect && \
#    git checkout ${KONNECT_VERSION}
#RUN    make && \
#    echo "Konnnect built from  ${KONNECT_REPO_URL} on $(date)" > /rootfs/.konnect-version && \
#    echo "Commit: $(cd /usr/src/konnect ; echo $(git rev-parse HEAD))" >> /rootfs/.konnect-version && \
#    cd /rootfs && \
#    tar cvfz /konnect.tar.gz . && \
#    cd /usr/src && \
#    rm -rf /rootfs
#
#    ### Build KAPI
#RUN    git clone ${KAPI_REPO_URL} /usr/src/kapi && \
#    cd /usr/src/kapi && \
#    git checkout ${KAPI_VERSION} && \
#    make && \
#    echo "KAPI built from  ${KAPI_REPO_URL} on $(date)" > /rootfs/.kapi-version && \
#    echo "Commit: $(cd /usr/src/kapi ; echo $(git rev-parse HEAD))" >> /rootfs/.kapi-version && \
#    cd /rootfs && \
#    tar cvfz /kapi.tar.gz . && \
#    cd /usr/src && \
#    rm -rf /rootfs
#
#    ### Build KWMServer
#RUN git clone ${KWMSERVER_REPO_URL} /usr/src/kwmserver && \
#    cd /usr/src/kwmserver && \
#    git checkout ${KWMSERVER_VERSION} && \
#    make && \
#    echo "KWMServer built from  ${KWMSERVER_REPO_URL} on $(date)" > /rootfs/.kwmserver-version && \
#    echo "Commit: $(cd /usr/src/kwmserver ; echo $(git rev-parse HEAD))" >> /rootfs/.kwmserver-version && \
#    cd /rootfs && \
#    tar cvfz /kwmserver.tar.gz . && \
#    cd /usr/src && \
#    rm -rf /rootfs
#
#    ### Build KWMBridge
#RUN git clone ${KWMBRIDGE_REPO_URL} /usr/src/kwmbridge && \
#    cd /usr/src/kwmbridge && \
#    git checkout ${KWMBRIDGE_VERSION} && \
#    make && \
#    echo "KWMBridge built from  ${KWMBRIDGE_REPO_URL} on $(date)" > /rootfs/.kwmbridge-version && \
#    echo "Commit: $(cd /usr/src/kwmbridge ; echo $(git rev-parse HEAD))" >> /rootfs/.kwmbridge-version && \
#    cd /rootfs && \
#    tar cvfz /kwmbridge.tar.gz . && \
#    cd /usr/src && \
#    rm -rf /rootfs
#
#    ### Build GRAPI
#RUN  apt-get install -y \
#                flake8 \
#                isort \
#                libcap-dev \
#                libdb-dev \
#                libev-dev \
#                libldap2-dev \
#                libpcap-dev \
#                libsasl2-dev \
#                python3-dev \
#                python3-pip \
#                python3-pytest \
#                python3-pytest-cov \
#                python3-wheel
#RUN git clone ${GRAPI_REPO_URL} /usr/src/grapi && \

#    cd /usr/src/grapi && \
#    git checkout ${GRAPI_VERSION} && \
#    make && \
#    echo "GRAPI built from  ${GRAPI_REPO_URL} on $(date)" > /rootfs/.grapi-version && \
#    echo "Commit: $(cd /usr/src/grapi ; echo $(git rev-parse HEAD))" >> /rootfs/.grapi-version && \
#    cd /rootfs && \
#    tar cvfz /grapi.tar.gz . && \
#    cd /usr/src && \
#    rm -rf /rootfs
