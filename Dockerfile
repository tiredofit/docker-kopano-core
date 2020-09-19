FROM tiredofit/nginx-php-fpm:debian-7.4 as core-builder

#### Kopano Core
ARG KOPANO_CORE_VERSION
ARG KOPANO_CORE_REPO_URL
ARG KOPANO_DEPENDENCY_HASH
ARG KOPANO_KCOIDC_REPO_URL
ARG KOPANO_KCOIDC_VERSION

ENV GO_VERSION=1.14 \
    KOPANO_CORE_VERSION=${KOPANO_CORE_VERSION:-"master"} \
    KOPANO_CORE_REPO_URL=${KOPANO_CORE_REPO_URL:-"https://github.com/Kopano-dev/kopano-core.git"} \
    KOPANO_DEPENDENCY_HASH=${KOPANO_DEPENDENCY_HASH:-"b3eaad3"} \
    KOPANO_KCOIDC_REPO_URL=${KOPANO_KCOIDC_REPO_URL:-"https://github.com/Kopano-dev/libkcoidc.git"} \
    KOPANO_KCOIDC_VERSION=${KOPANO_KCOIDC_VERSION:-"v0.9.2"}

ADD build-assets/kopano-core /build-assets

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
    BUILD_DEPS=' \
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
                        zlib1g-dev \
    ' \
    && \
    apt-get install -y --no-install-recommends \
                        ${BUILD_DEPS} \
                        && \
    \
    ### Build libkcoidc
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
    mkdir -p /rootfs/tiredofit && \
    make DESTDIR=/rootfs install && \
    PYTHON="$(which python3)" make DESTDIR=/rootfs python && \
    echo "Kopano kcOIDC ${KOPANO_KCOIDC_VERSION} built from ${KOPANO_KCOIDC_REPO_URL} on $(date)" > /rootfs/tiredofit/kopano-kcoidc.version && \
    echo "Commit: $(cd /usr/src/libkcoidc ; echo $(git rev-parse HEAD))" >> /rootfs/tiredofit/kopano-kcoidc.version && \
    cd /rootfs && \
    tar cvfz /kopano-kcoidc.tar.gz . && \
    cd /usr/src && \
    rm -rf /rootfs && \
    \
    ### Build Kopano Core
    git clone ${KOPANO_CORE_REPO_URL} /usr/src/kopano-core && \
    cd /usr/src/kopano-core && \
    git checkout ${KOPANO_CORE_VERSION} && \
    \
    if [ -d "/build-assets/src" ] ; then cp -R /build-assets/src/* /usr/src/kopano-core ; fi; \
    if [ -f "/build-assets/scripts/kopano-core.sh" ] ; then /build-assets/scripts/kopano-core.sh ; fi; \
    \
    mkdir -p /rootfs/tiredofit && \
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
        PYTHONPATH=/rootfs/usr/lib/python$(python3 --version | awk '{print $2}' | cut -c 1-3)/dist-packages \
        install \
        && \
    \
    ### Hack until I figure out how to send it properly to dist-packages
    cd /rootfs && \
    mv usr/lib/python$(python3 --version | awk '{print $2}' | cut -c 1-3)/site-packages usr/lib/python$(python3 --version | awk '{print $2}' | cut -c 1-3)/dist-packages && \
    ###
    ### Another Hack
    mkdir -p usr/lib/x86_64-linux-gnu && \
    mv usr/lib/lib*.* usr/lib/x86_64-linux-gnu/ && \
    ###
    \
    echo "Kopano Core ${KOPANO_CORE_VERSION} built from ${KOPANO_CORE_REPO_URL} on $(date)" > /rootfs/tiredofit/kopano-core.version && \
    echo "Commit: $(cd /usr/src/kopano-webapp ; echo $(git rev-parse HEAD))" >> /rootfs/tiredofit/kopano-core.version && \
    env | grep KOPANO | sed "/KOPANO_KCOIDC/d" | sort >> /rootfs/tiredofit/kopano-core.version && \
    echo "Dependency Hash '${KOPANO_DEPENDENCY_HASH} from: 'https://download.kopano.io/community/dependencies:'" >> /rootfs/tiredofit/kopano-core.version && \
    tar cvfz /kopano-core.tar.gz . &&\
    \
    ### Cleanup
    apt-get purge -y \
                ${BUILD_DEPS} \
                && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /rootfs/* && \
    rm -rf /usr/src/*

#### Kopano Webapp
FROM tiredofit/alpine:3.12 as webapp-builder

ARG KOPANO_WEBAPP_VERSION
ARG KOPANO_WEBAPP_PLUGIN_DESKTOP_NOTIFICATIONS_REPO_URL
ARG KOPANO_WEBAPP_PLUGIN_DESKTOP_NOTIFICATIONS_VERSION
ARG KOPANO_WEBAPP_PLUGIN_FILEPREVIEWER_REPO_URL
ARG KOPANO_WEBAPP_PLUGIN_FILEPREVIEWER_VERSION
ARG KOPANO_WEBAPP_PLUGIN_FILES_OWNCLOUD_REPO_URL
ARG KOPANO_WEBAPP_PLUGIN_FILES_OWNCLOUD_VERSION
ARG KOPANO_WEBAPP_PLUGIN_FILES_REPO_URL
ARG KOPANO_WEBAPP_PLUGIN_FILES_SEAFILE_REPO_URL
ARG KOPANO_WEBAPP_PLUGIN_FILES_SEAFILE_VERSION
ARG KOPANO_WEBAPP_PLUGIN_FILES_SMB_REPO_URL
ARG KOPANO_WEBAPP_PLUGIN_FILES_SMB_VERSION
ARG KOPANO_WEBAPP_PLUGIN_FILES_VERSION
ARG KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_MINIMALTINY_REPO_URL
ARG KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_MINIMALTINY_VERSION
ARG KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_QUILL_REPO_URL
ARG KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_QUILL_VERSION
ARG KOPANO_WEBAPP_PLUGIN_INTRANET_REPO_URL
ARG KOPANO_WEBAPP_PLUGIN_INTRANET_VERSION
ARG KOPANO_WEBAPP_PLUGIN_MATTERMOST_REPO_URL
ARG KOPANO_WEBAPP_PLUGIN_MATTERMOST_VERSION
ARG KOPANO_WEBAPP_PLUGIN_MDM_REPO_URL
ARG KOPANO_WEBAPP_PLUGIN_MDM_VERSION
ARG KOPANO_WEBAPP_PLUGIN_ROCKETCHAT_REPO_URL
ARG KOPANO_WEBAPP_PLUGIN_ROCKETCHAT_VERSION
ARG KOPANO_WEBAPP_PLUGIN_SMIME_REPO_URL
ARG KOPANO_WEBAPP_PLUGIN_SMIME_VERSION
ARG KOPANO_WEBAPP_REPO_URL

ENV KOPANO_WEBAPP_VERSION=${KOPANO_WEBAPP_VERSION:-"6bb4a9f161204fb5942aff18233256902278955e"} \
#ENV KOPANO_WEBAPP_VERSION=${KOPANO_WEBAPP_VERSION:-"master"} \
#ENV KOPANO_WEBAPP_VERSION=${KOPANO_WEBAPP_VERSION:-"v4.3-rc.1"} \
    KOPANO_WEBAPP_REPO_URL=${KOPANO_WEBAPP_REPO_URL:-"https://github.com/Kopano-dev/kopano-webapp.git"} \
    KOPANO_WEBAPP_PLUGIN_DESKTOP_NOTIFICATIONS_REPO_URL=${KOPANO_WEBAPP_PLUGIN_DESKTOP_NOTIFICATIONS_REPO_URL:-"https://stash.kopano.io/scm/kwa/desktopnotifications.git"} \
    KOPANO_WEBAPP_PLUGIN_DESKTOP_NOTIFICATIONS_VERSION=${KOPANO_WEBAPP_PLUGIN_DESKTOP_NOTIFICATIONS_VERSION:-"tags/v2.0.3"} \
    KOPANO_WEBAPP_PLUGIN_FILEPREVIEWER_REPO_URL=${KOPANO_WEBAPP_PLUGIN_FILEPREVIEWER_REPO_URL:-"https://stash.kopano.io/scm/kwa/filepreviewer.git"} \
    KOPANO_WEBAPP_PLUGIN_FILEPREVIEWER_VERSION=${KOPANO_WEBAPP_PLUGIN_FILEPREVIEWER_VERSION:-"tags/v2.2.0"} \
    KOPANO_WEBAPP_PLUGIN_FILES_OWNCLOUD_REPO_URL=${KOPANO_WEBAPP_PLUGIN_FILES_OWNCLOUD_REPO_URL:-"https://stash.kopano.io/scm/kwa/files-owncloud-backend.git"} \
    KOPANO_WEBAPP_PLUGIN_FILES_OWNCLOUD_VERSION=${KOPANO_WEBAPP_PLUGIN_FILES_OWNCLOUD_VERSION:-"tags/v3.0.0"} \
    KOPANO_WEBAPP_PLUGIN_FILES_REPO_URL=${KOPANO_WEBAPP_PLUGIN_FILES_REPO_URL:-"https://stash.kopano.io/scm/kwa/files.git"} \
    KOPANO_WEBAPP_PLUGIN_FILES_SEAFILE_REPO_URL=${KOPANO_WEBAPP_PLUGIN_FILES_SEAFILE_REPO_URL:-"https://github.com/datamate-rethink-it/kopano-seafile-backend.git"} \
    KOPANO_WEBAPP_PLUGIN_FILES_SEAFILE_VERSION=${KOPANO_WEBAPP_PLUGIN_FILES_SEAFILE_VERSION:-"master"} \
    KOPANO_WEBAPP_PLUGIN_FILES_SMB_REPO_URL=${KOPANO_WEBAPP_PLUGIN_FILES_SMB_REPO_URL:-"https://stash.kopano.io/scm/kwa/files-smb-backend.git"} \
    KOPANO_WEBAPP_PLUGIN_FILES_SMB_VERSION=${KOPANO_WEBAPP_PLUGIN_FILES_SMB_VERSION:-"tags/v3.0.0"} \
    KOPANO_WEBAPP_PLUGIN_FILES_VERSION=${KOPANO_WEBAPP_PLUGIN_FILES_VERSION:-"tags/v3.0.0-beta.4"} \
    KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_MINIMALTINY_REPO_URL=${KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_MINIMALTINY_REPO_URL:-"https://stash.kopano.io/scm/kwa/htmleditor-minimaltiny.git"} \
    KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_MINIMALTINY_VERSION=${KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_MINIMALTINY_VERSION:-"tags/1.0.0"} \
    KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_QUILL_REPO_URL=${KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_QUILL_REPO_URL:-"https://stash.kopano.io/scm/kwa/htmleditor-quill.git"} \
    KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_QUILL_VERSION=${KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_QUILL_VERSION:-"master"} \
    KOPANO_WEBAPP_PLUGIN_INTRANET_REPO_URL=${KOPANO_WEBAPP_PLUGIN_INTRANET_REPO_URL:-"https://stash.kopano.io/scm/kwa/intranet.git"} \
    KOPANO_WEBAPP_PLUGIN_INTRANET_VERSION=${KOPANO_WEBAPP_PLUGIN_INTRANET_VERSION:-"tags/v1.0.1"} \
    KOPANO_WEBAPP_PLUGIN_MATTERMOST_REPO_URL=${KOPANO_WEBAPP_PLUGIN_MATTERMOST_REPO_URL:-"https://stash.kopano.io/scm/kwa/mattermost.git"} \
    KOPANO_WEBAPP_PLUGIN_MATTERMOST_VERSION=${KOPANO_WEBAPP_PLUGIN_MATTERMOST_VERSION:-"tags/v1.0.1"} \
    KOPANO_WEBAPP_PLUGIN_MDM_REPO_URL=${KOPANO_WEBAPP_PLUGIN_MDM_REPO_URL:-"https://stash.kopano.io/scm/kwa/mobile-device-management.git"} \
    KOPANO_WEBAPP_PLUGIN_MDM_VERSION=${KOPANO_WEBAPP_PLUGIN_MDM_VERSION:-"tags/v3.1"} \
    KOPANO_WEBAPP_PLUGIN_ROCKETCHAT_REPO_URL=${KOPANO_WEBAPP_PLUGIN_ROCKETCHAT_REPO_URL:-"https://cloud.siedl.net/nextcloud/index.php/s/3yKYARgGwfSZe2c/download"} \
    KOPANO_WEBAPP_PLUGIN_ROCKETCHAT_VERSION=${KOPANO_WEBAPP_PLUGIN_ROCKETCHAT_VERSION:-"1.0.2-1"} \
    KOPANO_WEBAPP_PLUGIN_SMIME_REPO_URL=${KOPANO_WEBAPP_PLUGIN_SMIME_REPO_URL:-"https://stash.kopano.io/scm/kwa/smime.git"} \
    KOPANO_WEBAPP_PLUGIN_SMIME_VERSION=${KOPANO_WEBAPP_PLUGIN_SMIME_VERSION:-"tags/v2.2.2"}

ADD build-assets/kopano-webapp /build-assets

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
    if [ -d "/build-assets/src" ] ; then cp -R /build-assets/src/* /usr/src/kopano-webapp ; fi; \
    if [ -f "/build-assets/scripts/webapp.sh" ] ; then /build-assets/scripts/webapp.sh ; fi; \
    \
    ### Build
    cd /usr/src/kopano-webapp && \
    ant deploy && \
    ant deploy-plugins && \
    make all && \
    \
    ### Setup RootFS
    mkdir -p /rootfs/tiredofit && \
    mkdir -p /rootfs/usr/share/kopano-webapp && \
    mkdir -p /rootfs/assets/kopano/config/webapp && \
    mkdir -p /rootfs/assets/kopano/plugins/webapp && \
    \
    ### Build Plugins
    ## File Previewer TO BE MERGED INTO MAIN
    git clone ${KOPANO_WEBAPP_PLUGIN_FILEPREVIEWER_REPO_URL} /usr/src/kopano-webapp/plugins/filepreviewer && \
    cd /usr/src/kopano-webapp/plugins/filepreviewer && \
    git checkout ${KOPANO_WEBAPP_PLUGIN_FILEPREVIEWER_VERSION} && \
    if [ -d "/build-assets/plugins/filepreviewer" ] ; then cp -R /build-assets/plugins/filepreviewer/* /usr/src/kopano-webapp/plugins/filepreviewer/ ; fi; \
    if [ -f "/build-assets/scripts/plugin-filepreviewer.sh" ] ; then /build-assets/scripts/plugin-filepreviewer.sh ; fi; \
    ant deploy && \
    cp /usr/src/kopano-webapp/deploy/plugins/filepreviewer/config.php /rootfs/assets/kopano/config/webapp/config-filepreviewer.php && \
    ln -sf /etc/kopano/webapp/config-filepreviewer.php /usr/src/kopano-webapp/deploy/plugins/filepreviewer/config.php && \
    \
    ## Files
    git clone ${KOPANO_WEBAPP_PLUGIN_FILES_REPO_URL} /usr/src/kopano-webapp/plugins/files && \
    cd /usr/src/kopano-webapp/plugins/files && \
    git checkout ${KOPANO_WEBAPP_PLUGIN_FILES_VERSION} && \
    if [ -d "/build-assets/plugins/files" ] ; then cp -R /build-assets/plugins/files/* /usr/src/kopano-webapp/plugins/files/ ; fi; \
    if [ -f "/build-assets/scripts/plugin-files.sh" ] ; then /build-assets/scripts/plugin-files.sh ; fi; \
    ant deploy && \
    cp /usr/src/kopano-webapp/deploy/plugins/files/config.php /rootfs/assets/kopano/config/webapp/config-files.php && \
    ln -sf /etc/kopano/webapp/config-files.php /usr/src/kopano-webapp/deploy/plugins/files/config.php && \
    \
    ## Files Backend: Owncloud
    git clone ${KOPANO_WEBAPP_PLUGIN_FILES_OWNCLOUD_REPO_URL} /usr/src/kopano-webapp/plugins/filesbackendOwncloud && \
    cd /usr/src/kopano-webapp/plugins/filesbackendOwncloud && \
    git checkout ${KOPANO_WEBAPP_PLUGIN_FILES_OWNCLOUD_VERSION} && \
    if [ -d "/build-assets/plugins/filesbackendOwncloud" ] ; then cp -R /build-assets/plugins/filesbackendOwncloud/* /usr/src/kopano-webapp/plugins/filesbackendOwncloud/ ; fi; \
    if [ -f "/build-assets/scripts/plugin-filesbackendOwncloud.sh" ] ; then /build-assets/scripts/plugin-filesbackendOwncloud.sh ; fi; \
    ant deploy && \
    \
    ## Files Backend: SeaFile
    git clone ${KOPANO_WEBAPP_PLUGIN_FILES_SEAFILE_REPO_URL} /usr/src/kopano-webapp/plugins/filesbackendSeafile && \
    cd /usr/src/kopano-webapp/plugins/filesbackendSeafile && \
    git checkout ${KOPANO_WEBAPP_PLUGIN_FILES_SEAFILE_VERSION} && \
    if [ -d "/build-assets/plugins/filesbackendSeafile" ] ; then cp -R /build-assets/plugins/filesbackendSeafile/* /usr/src/kopano-webapp/plugins/filesbackendSeafile/ ; fi; \
    if [ -f "/build-assets/scripts/plugin-filesbackendSeafile.sh" ] ; then /build-assets/scripts/plugin-filesbackendSeafile.sh ; fi; \
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
    if [ -d "/build-assets/plugins/filesbackendSMB" ] ; then cp -R /build-assets/plugins/filesbackendSMB/* /usr/src/kopano-webapp/plugins/filesbackendSMB/ ; fi; \
    if [ -f "/build-assets/scripts/plugin-filesbackendSMB.sh" ] ; then /build-assets/scripts/plugin-filesbackendSMB.sh ; fi; \
    ant deploy && \
    \
    ## HTML Editor: Minimal
    git clone ${KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_MINIMALTINY_REPO_URL} /usr/src/kopano-webapp/plugins/htmleditor-minimaltiny && \
    cd /usr/src/kopano-webapp/plugins/htmleditor-minimaltiny && \
    if [ -d "/build-assets/plugins/htmleditor-minimaltiny" ] ; then cp -R /build-assets/plugins/htmleditor-minimaltiny/* /usr/src/kopano-webapp/plugins/htmleditor-minimaltiny/ ; fi; \
    if [ -f "/build-assets/scripts/plugin-htmleditorminimaltiny.sh" ] ; then /build-assets/scripts/plugin-htmleditorminimaltiny.sh ; fi; \
    ant deploy && \
    \
    ## HTML Editor: Quill
    git clone ${KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_QUILL_REPO_URL} /usr/src/kopano-webapp/plugins/htmleditor-quill && \
    cd /usr/src/kopano-webapp/plugins/htmleditor-quill && \
    if [ -d "/build-assets/plugins/htmleditor-quill" ] ; then cp -R /build-assets/plugins/htmleditor-quill/* /usr/src/kopano-webapp/plugins/htmleditor-quill/ ; fi; \
    if [ -f "/build-assets/scripts/plugin-htmleditor-quill.sh" ] ; then /build-assets/scripts/plugin-htmleditor-qill.sh ; fi; \
    ant deploy && \
    \
    ## Intranet
    git clone ${KOPANO_WEBAPP_PLUGIN_INTRANET_REPO_URL} /usr/src/kopano-webapp/plugins/intranet && \
    cd /usr/src/kopano-webapp/plugins/intranet && \
    git checkout ${KOPANO_WEBAPP_PLUGIN_INTRANET_VERSION} && \
    if [ -d "/build-assets/plugins/intranet" ] ; then cp -R /build-assets/plugins/intranet/* /usr/src/kopano-webapp/plugins/intranet/ ; fi; \
    if [ -f "/build-assets/scripts/plugin-intranet.sh" ] ; then /build-assets/scripts/plugin-intranet.sh ; fi; \
    ant deploy && \
    cp /usr/src/kopano-webapp/deploy/plugins/intranet/config.php /rootfs/assets/kopano/config/webapp/config-intranet.php && \
    ln -sf /etc/kopano/webapp/config-intranet.php /usr/src/kopano-webapp/deploy/plugins/intranet/config.php && \
    \
    ## Mobile Device Management
    git clone ${KOPANO_WEBAPP_PLUGIN_MDM_REPO_URL} /usr/src/kopano-webapp/plugins/mdm && \
    cd /usr/src/kopano-webapp/plugins/mdm && \
    git checkout ${KOPANO_WEBAPP_PLUGIN_MDM_VERSION} && \
    if [ -d "/build-assets/plugins/mdm" ] ; then cp -R /build-assets/plugins/mdm/* /usr/src/kopano-webapp/plugins/mdm/ ; fi; \
    if [ -f "/build-assets/scripts/plugin-mdm.sh" ] ; then /build-assets/scripts/plugin-mdm.sh ; fi; \
    ant deploy && \
    cp /usr/src/kopano-webapp/deploy/plugins/mdm/config.php /rootfs/assets/kopano/config/webapp/config-mdm.php && \
    ln -sf /etc/kopano/webapp/config-mdm.php /usr/src/kopano-webapp/deploy/plugins/mdm/config.php && \
    \
    ## Mattermost
    git clone ${KOPANO_WEBAPP_PLUGIN_MATTERMOST_REPO_URL} /usr/src/kopano-webapp/plugins/mattermost && \
    cd /usr/src/kopano-webapp/plugins/mattermost && \
    git checkout ${KOPANO_WEBAPP_PLUGIN_MATTERMOST_VERSION} && \
    if [ -d "/build-assets/plugins/mattermost" ] ; then cp -R /build-assets/plugins/mattermost/* /usr/src/kopano-webapp/plugins/mattermost/ ; fi; \
    if [ -f "/build-assets/scripts/plugin-mattermost.sh" ] ; then /build-assets/scripts/plugin-mattermost.sh ; fi; \
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
    cp etc/kopano/webapp/config-rchat.php /rootfs/assets/kopano/config/webapp/config-rchat.php && \
    cp -R usr/share/kopano-webapp/plugins/rchat /usr/src/kopano-webapp/deploy/plugins/ && \
    ln -sf /etc/kopano/webapp/config-rchat.php /usr/src/kopano-webapp/deploy/plugins/rchat/config.php && \
    if [ -d "/build-assets/plugins/rocketchat" ] ; then cp -R /build-assets/plugins/rocketchat/* /usr/src/kopano-webapp/deploy/plugins/rchat/ ; fi; \
    if [ -f "/build-assets/scripts/plugin-rocketchat.sh" ] ; then /build-assets/scripts/plugin-rocketchat.sh ; fi; \
    \
    ## S/MIME
    git clone ${KOPANO_WEBAPP_PLUGIN_SMIME_REPO_URL} /usr/src/kopano-webapp/plugins/smime && \
    cd /usr/src/kopano-webapp/plugins/smime && \
    git checkout ${KOPANO_WEBAPP_PLUGIN_SMIME_VERSION} && \
    if [ -d "/build-assets/plugins/smime" ] ; then cp -R /build-assets/plugins/smime/* /usr/src/kopano-webapp/plugins/smime/ ; fi; \
    if [ -f "/build-assets/scripts/plugin-smime.sh" ] ; then /build-assets/scripts/plugin-smime.sh ; fi; \
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
    git clone --depth 1 https://stash.kopano.io/scm/ksc/webapp-tools.git /rootfs/assets/kopano/scripts/webapp-tools && \
    mkdir -p /rootfs/assets/kopano/scripts/webapp-tools/set-default-signature && \
    cp -R /usr/src/kopano-webapp/tools/signatures/* /rootfs/assets/kopano/scripts/webapp-tools/set-default-signature && \
    \
    ### Compress Package
    cd /rootfs/ && \
    echo "Kopano Webapp ${KOPANO_WEBAPP_VERSION} built from ${KOPANO_WEBAPP_REPO_URL} on $(date)" > /rootfs/tiredofit/kopano-webapp.version && \
    echo "Commit: $(cd /usr/src/kopano-webapp ; echo $(git rev-parse HEAD))" >> /rootfs/tiredofit/kopano-webapp.version && \
    env | grep KOPANO | sort >> /rootfs/tiredofit/kopano-webapp.version && \
    tar cvfz /kopano-webapp.tar.gz .

#### Runtime Image
FROM tiredofit/nginx-php-fpm:debian-7.4
LABEL maintainer="Dave Conroy (dave at tiredofit dot ca)"

ADD build-assets/kopano /build-assets

### Move Previously built files from Core image
COPY --from=core-builder /*.tar.gz /usr/src/core/

### Move Previously built files from Webapp image
COPY --from=webapp-builder /*.tar.gz /usr/src/webapp/

ARG KOPANO_DEPENDENCY_HASH
ARG KOPANO_KDAV_VERSION
ARG Z_PUSH_VERSION

ENV KOPANO_DEPENDENCY_HASH=${KOPANO_DEPENDENCY_HASH:-"b3eaad3"} \
    KOPANO_KDAV_VERSION=${KOPANO_KDAV_VERSION:-"master"} \
    Z_PUSH_VERSION=${Z_PUSH_VERSION:-"2.5.2"} \
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
    mkdir -p tiredofit && \
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
    ##### Install Packages
    apt-get update && \
    BUILD_DEPS=' \
                build-essential \
                libev-dev \
                python3-dev \
                unzip \
                \
    ' && \
    apt-get install -y --no-install-recommends \
                       ${BUILD_DEPS} \
                       bc \
                       fail2ban \
                       iptables \
                       libany-uri-escape-perl \
                       libdata-uniqid-perl \
                       libdb5.3++ \
                       libdigest-hmac-perl \
                       libev4 \
                       libfile-copy-recursive-perl \
                       libgsoap-kopano-2.8.102 \
                       libhtml-entities-numbered-perl \
                       libhx28 \
                       libical3 \
                       libimagequant0 \
                       libio-socket-ssl-perl \
                       libio-tee-perl \
                       libjson-perl \
                       libjson-webtoken-perl \
                       libjsoncpp1 \
                       libmail-imapclient-perl \
                       libpython3.7 \
                       libreadonly-perl \
                       libs3-4 \
                       libtidy5 \
                       libunicode-string-perl \
                       libvmime-kopano3 \
                       libvmime1 \
                       libwebpdemux2 \
                       libwebpmux3 \
                       man \
                       php-memcached \
                       php-tokenizer \
                       poppler-utils \
                       python3-bsddb3 \
                       python3-certifi \
                       python3-chardet \
                       python3-configobj \
                       python3-daemon \
                       python3-dateutil \
                       python3-idna \
                       python3-jsonschema \
                       python3-lockfile \
                       python3-magic \
                       python3-olefile \
                       python3-pil \
                       python3-pip \
                       python3-prctl \
                       python3-requests \
                       python3-setproctitle \
                       python3-setuptools \
                       python3-six \
                       python3-tabulate \
                       python3-tz \
                       python3-tzlocal \
                       python3-ujson \
                       python3-urllib3 \
                       python3-wheel \
                       python3-xapian \
                       sqlite3 \
    && \
    \
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
    find /assets/kopano/scripts -name '*.py' -exec chmod +x {} \; && \
    \
    ##### Unpack KCOIDC
    tar xvfz /usr/src/core/kopano-kcoidc.tar.gz -C / && \
    \
    ##### Unpack Core
    tar xvfz /usr/src/core/kopano-core.tar.gz -C / && \
    \
    ##### Unpack WebApp
    tar xvfz /usr/src/webapp/kopano-webapp.tar.gz -C / && \
    chown -R nginx:www-data /assets/kopano/plugins/webapp && \
    chown -R nginx:www-data /usr/share/kopano-webapp && \
    echo "extension=mapi.so" > /etc/php/$(php-fpm -v | head -n 1 | awk '{print $2}' | cut -c 1-3)/fpm/conf.d/20-mapi.ini && \
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
    ln -s /assets/kopano/scripts/core-tools/store-stats/store-stats.py /usr/sbin/store-stats && \
    ln -s /assets/kopano/scripts/webapp-tools/files_admin/files_admin.py /usr/sbin/files-admin && \
    ln -s /assets/kopano/scripts/webapp-tools/webapp_admin/webapp_admin.py /usr/sbin/webapp-admin && \
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
    ### Build Assets Override
    if [ -d "/build-assets/src/" ] ; then cp -R /build-assets/src/* / ; fi; \
    if [ -f "/build-assets/scripts/kopano.sh" ] ; then /build-assets/scripts/kopano.sh ; fi; \
    rm -rf /build-assets/ && \
    \
    ### Fix some issues found by community
    sed -i "s|\"server_ssl\": ssl,|\"server_ssl\": (ssl.lower() == 'true'),|g" /assets/kopano/scripts/webapp-tools/files_admin/files_admin.py && \
    \
    ##### Cleanup
    apt-get purge -y \
                    ${BUILD_DEPS} \
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
    rm -rf /etc/logrotate.d/unattended-upgrades && \
    rm -rf /var/log/* && \
    cd /etc/fail2ban && \
    rm -rf fail2ban.conf fail2ban.d jail.conf jail.d paths-*.conf

### Assets Install
ADD install /
