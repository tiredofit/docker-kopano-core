FROM tiredofit/nginx-php-fpm:debian-7.3-buster as core-builder

#### Kopano Core
ARG KOPANO_CORE_VERSION
ARG KOPANO_CORE_REPO_URL
ARG KOPANO_DEPENDENCY_HASH
ARG KOPANO_KCOIDC_REPO_URL
ARG KOPANO_KCOIDC_VERSION

ENV GO_VERSION=1.16.3 \
    KOPANO_CORE_VERSION=${KOPANO_CORE_VERSION:-"master"} \
    KOPANO_CORE_REPO_URL=${KOPANO_CORE_REPO_URL:-"https://github.com/Kopano-dev/kopano-core.git"} \
    KOPANO_DEPENDENCY_HASH=${KOPANO_DEPENDENCY_HASH:-"620ddd9"} \
    KOPANO_KCOIDC_REPO_URL=${KOPANO_KCOIDC_REPO_URL:-"https://github.com/Kopano-dev/libkcoidc.git"} \
    KOPANO_KCOIDC_VERSION=${KOPANO_KCOIDC_VERSION:-"master"}

ADD build-assets/kopano-core /build-assets

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
    ### Package updates
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
    mkdir -p /kopano-dependencies && \
    curl -sSL https://download.kopano.io/community/dependencies:/kopano-dependencies-${KOPANO_DEPENDENCY_HASH}-Debian_10-amd64.tar.gz | tar xvfz - --strip 1 -C /kopano-dependencies/ && \
    cd /kopano-dependencies && \
    apt-ftparchive packages . | gzip -c9 > Packages.gz && \
    echo "deb [trusted=yes] file:/kopano-dependencies ./" > /etc/apt/sources.list.d/kopano-dependencies.list && \
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
                        libmariadb-dev \
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
                        zstd \
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
    tar cavf /kopano-kcoidc.tar.zst . && \
    cd /usr/src && \
    rm -rf /rootfs && \
    \
    ### Build Kopano Core
    git clone ${KOPANO_CORE_REPO_URL} /usr/src/kopano-core && \
    cd /usr/src/kopano-core && \
    git checkout ${KOPANO_CORE_VERSION} && \
    if [ -d "/build-assets/src" ] ; then cp -R /build-assets/src/* /usr/src/kopano-core ; fi; \
    if [ -d "/build-assets/scripts" ] ; then for script in /build-assets/scripts/*.sh; do echo "** Applying $script"; bash $script; done ; fi ;
RUN set -x && \
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
    ### Miscellanious Scripts
    mkdir -p mkdir -p /rootfs/assets/kopano/scripts && \
    git clone --depth 1 https://stash.kopano.io/scm/ksc/Core-tools.git /rootfs/assets/kopano/scripts/core-tools && \
    git clone --depth 1 https://stash.kopano.io/scm/ksc/lab-scripts.git /rootfs/assets/kopano/scripts/lab-scripts && \
    git clone --depth 1 https://stash.kopano.io/scm/ksc/mail-migrations.git /rootfs/assets/kopano/scripts/mail-migrations && \
    git clone --depth 1 https://stash.kopano.io/scm/ksc/support.git /rootfs/assets/kopano/scripts/support && \
    find /rootfs/assets/kopano/scripts -name '*.py' -exec chmod +x {} \; && \
    \
    ## Cleanup some of the scripts
    mkdir -p /rootfs/usr/sbin && \
    ln -s /assets/kopano/scripts/core-tools/store-stats/store-stats.py /rootfs/usr/sbin/store-stats && \
    sed -i "s|kopano.Server|kopano.server|g" /rootfs/assets/kopano/scripts/core-tools/store-stats/store-stats.py && \
    sed -i "s|locale.format|locale.format_string|g" /rootfs/assets/kopano/scripts/core-tools/store-stats/store-stats.py && \

    mkdir -p /rootfs/assets/kopano/config && \
    cp -R /rootfs/etc/kopano/* /rootfs/assets/kopano/config/ && \
    mkdir -p /rootfs/assets/kopano/templates && \
    cp -R /rootfs/etc/kopano/quotamail/* /rootfs/assets/kopano/templates && \
    rm -rf /rootfs/etc/kopano/quotamail && \
    mkdir -p /rootfs/assets/kopano/userscripts && \
    mkdir -p /rootfs/assets/kopano/userscripts/createcompany.d \
             /rootfs/assets/kopano/userscripts/creategroup.d \
             /rootfs/assets/kopano/userscripts/createuser.d \
             /rootfs/assets/kopano/userscripts/deletecompany.d \
             /rootfs/assets/kopano/userscripts/deletegroup.d \
             /rootfs/assets/kopano/userscripts/deleteuser.d && \
    cp -R /rootfs/usr/lib/kopano/userscripts /rootfs/assets/kopano/userscripts && \

    rm -rf /rootfs/etc/kopano && \
    ln -sf /config /rootfs/etc/kopano && \
    ln -s /usr/bin/kopano-autorespond /rootfs/usr/sbin/kopano-autorespond && \

    mkdir -p /var/run/kopano && \
    mkdir -p /var/run/kopano-search && \
    chown -R kopano /var/run/kopano && \
    chown -R kopano /var/run/kopano-search && \
    cd /rootfs && \
    find . -name .git -type d -print0|xargs -0 rm -rf -- && \
    echo "Kopano Core ${KOPANO_CORE_VERSION} built from ${KOPANO_CORE_REPO_URL} on $(date)" > /rootfs/tiredofit/kopano-core.version && \
    echo "Commit: $(cd /usr/src/kopano-core ; echo $(git rev-parse HEAD))" >> /rootfs/tiredofit/kopano-core.version && \
    env | grep KOPANO | sed "/KOPANO_KCOIDC/d" | sort >> /rootfs/tiredofit/kopano-core.version && \
    echo "Dependency Hash '${KOPANO_DEPENDENCY_HASH} from: 'https://download.kopano.io/community/dependencies:'" >> /rootfs/tiredofit/kopano-core.version && \
    tar cavf /kopano-core.tar.zst . &&\
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
FROM tiredofit/nginx-php-fpm:debian-7.3-buster as webapp-builder

ARG KOPANO_WEBAPP_VERSION
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
ARG KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_JODIT_REPO_URL
ARG KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_JODIT_VERSION
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
ARG KOPANO_KDAV_VERSION
ARG Z_PUSH_VERSION

ENV KOPANO_WEBAPP_VERSION=${KOPANO_WEBAPP_VERSION:-"5.1.0"} \
    KOPANO_WEBAPP_PLUGIN_FILES_OWNCLOUD_VERSION=${KOPANO_WEBAPP_PLUGIN_FILES_OWNCLOUD_VERSION:-"tags/v4.0.0"} \
    KOPANO_WEBAPP_PLUGIN_FILES_SEAFILE_VERSION=${KOPANO_WEBAPP_PLUGIN_FILES_SEAFILE_VERSION:-"master"} \
    KOPANO_WEBAPP_PLUGIN_FILES_SEAFILE_VERSION=${KOPANO_WEBAPP_PLUGIN_FILES_SEAFILE_VERSION:-"master"} \
    KOPANO_WEBAPP_PLUGIN_FILES_SMB_VERSION=${KOPANO_WEBAPP_PLUGIN_FILES_SMB_VERSION:-"tags/v4.0.0"} \
    KOPANO_WEBAPP_PLUGIN_FILES_VERSION=${KOPANO_WEBAPP_PLUGIN_FILES_VERSION:-"tags/v4.0.1"} \
    KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_MINIMALTINY_VERSION=${KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_MINIMALTINY_VERSION:-"tags/v2.0"} \
    KOPANO_WEBAPP_PLUGIN_INTRANET_VERSION=${KOPANO_WEBAPP_PLUGIN_INTRANET_VERSION:-"master"} \
    KOPANO_WEBAPP_PLUGIN_JODIT_VERSION=${KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_JODIT_VERSION:-"master"} \
    KOPANO_WEBAPP_PLUGIN_MATTERMOST_VERSION=${KOPANO_WEBAPP_PLUGIN_MATTERMOST_VERSION:-"tags/v1.0.1"} \
    KOPANO_WEBAPP_PLUGIN_MDM_VERSION=${KOPANO_WEBAPP_PLUGIN_MDM_VERSION:-"tags/v3.3.0"} \
    KOPANO_WEBAPP_PLUGIN_MEET_VERSION=${KOPANO_WEBAPP_PLUGIN_MEET_VERSION:-"master"} \
    KOPANO_WEBAPP_PLUGIN_ROCKETCHAT_VERSION=${KOPANO_WEBAPP_PLUGIN_ROCKETCHAT_VERSION:-"1.0.2-1"} \
    KOPANO_WEBAPP_PLUGIN_SMIME_VERSION=${KOPANO_WEBAPP_PLUGIN_SMIME_VERSION:-"tags/v2.2.2"} \
    \
    KOPANO_KDAV_VERSION=${KOPANO_KDAV_VERSION:-"master"} \
    Z_PUSH_VERSION=${Z_PUSH_VERSION:-"2.6.2"} \
    \
    KOPANO_KDAV_REPO_URL=${KOPANO_KDAV_REPO_URL:-"https://github.com/Kopano-dev/kdav"} \
    KOPANO_WEBAPP_REPO_URL=${KOPANO_WEBAPP_REPO_URL:-"https://stash.kopano.io/scm/kw/kopano-webapp.git"} \
    KOPANO_WEBAPP_PLUGIN_FILES_OWNCLOUD_REPO_URL=${KOPANO_WEBAPP_PLUGIN_FILES_OWNCLOUD_REPO_URL:-"https://stash.kopano.io/scm/kwa/files-owncloud-backend.git"} \
    KOPANO_WEBAPP_PLUGIN_FILES_REPO_URL=${KOPANO_WEBAPP_PLUGIN_FILES_REPO_URL:-"https://stash.kopano.io/scm/kwa/files.git"} \
    KOPANO_WEBAPP_PLUGIN_FILES_SEAFILE_REPO_URL=${KOPANO_WEBAPP_PLUGIN_FILES_SEAFILE_REPO_URL:-"https://github.com/datamate-rethink-it/kopano-seafile-backend.git"} \
    KOPANO_WEBAPP_PLUGIN_FILES_SMB_REPO_URL=${KOPANO_WEBAPP_PLUGIN_FILES_SMB_REPO_URL:-"https://stash.kopano.io/scm/kwa/files-smb-backend.git"} \
    KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_MINIMALTINY_REPO_URL=${KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_MINIMALTINY_REPO_URL:-"https://stash.kopano.io/scm/kwa/htmleditor-minimaltiny.git"} \
    KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_QUILL_REPO_URL=${KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_QUILL_REPO_URL:-"https://stash.kopano.io/scm/kwa/htmleditor-quill.git"} \
    KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_QUILL_VERSION=${KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_QUILL_VERSION:-"master"} \
    KOPANO_WEBAPP_PLUGIN_INTRANET_REPO_URL=${KOPANO_WEBAPP_PLUGIN_INTRANET_REPO_URL:-"https://stash.kopano.io/scm/kwa/intranet.git"} \
    KOPANO_WEBAPP_PLUGIN_JODIT_REPO_URL=${KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_JODIT_REPO_URL:-"https://stash.kopano.io/scm/kwa/htmleditor-jodit.git"} \
    KOPANO_WEBAPP_PLUGIN_MATTERMOST_REPO_URL=${KOPANO_WEBAPP_PLUGIN_MATTERMOST_REPO_URL:-"https://stash.kopano.io/scm/kwa/mattermost.git"} \
    KOPANO_WEBAPP_PLUGIN_MDM_REPO_URL=${KOPANO_WEBAPP_PLUGIN_MDM_REPO_URL:-"https://stash.kopano.io/scm/kwa/mobile-device-management.git"} \
    KOPANO_WEBAPP_PLUGIN_MEET_REPO_URL=${KOPANO_WEBAPP_PLUGIN_MEET_REPO_URL:-"https://stash.kopano.io/scm/kwa/meet.git"} \
    KOPANO_WEBAPP_PLUGIN_ROCKETCHAT_REPO_URL=${KOPANO_WEBAPP_PLUGIN_ROCKETCHAT_REPO_URL:-"https://cloud.siedl.net/nextcloud/index.php/s/3yKYARgGwfSZe2c/download"} \
    KOPANO_WEBAPP_PLUGIN_SMIME_REPO_URL=${KOPANO_WEBAPP_PLUGIN_SMIME_REPO_URL:-"https://stash.kopano.io/scm/kwa/smime.git"}

ADD build-assets/kopano-webapp /build-assets

RUN set -x && \
    curl -sSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
    echo "deb https://deb.nodesource.com/node_14.x buster main" > /etc/apt/sources.list.d/nodejs.list && \
    WEBAPP_BUILD_DEPS=' \
                        ant \
                        ant-optional \
                        gettext \
                        git \
                        libxml2-utils \
			            make \
			            openjdk-11-jdk \
                        nodejs \
                        php-common \
                        php-gettext \
                        php-xml \
                        php-zip \
                        python \
                        zstd \
                        ' && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get -y install --no-install-recommends \
                ${WEBAPP_BUILD_DEPS} \
                && \
    php-ext disable opcache && \
    \
    ### Fetch Source
    git clone ${KOPANO_WEBAPP_REPO_URL} /usr/src/kopano-webapp && \
    cd /usr/src/kopano-webapp && \
    git checkout ${KOPANO_WEBAPP_VERSION} && \
    \
    if [ -d "/build-assets/src" ] ; then cp -R /build-assets/src/* /usr/src/kopano-webapp ; fi; \
    if [ -d "/build-assets/scripts" ] ; then for script in /build-assets/scripts/*.sh; do echo "** Applying $script"; bash $script; done && \ ; fi ; \
    \
    # Translations are a source of problems, so we remove for time being other than English
    cd /usr/src/kopano-webapp/server/language && \
    find . -mindepth 1 -maxdepth 1 -type d -not -name en_US* -exec rm -rf '{}' \; && \
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
    ## Files
    git clone ${KOPANO_WEBAPP_PLUGIN_FILES_REPO_URL} /usr/src/kopano-webapp/plugins/files && \
    cd /usr/src/kopano-webapp/plugins/files && \
    git checkout ${KOPANO_WEBAPP_PLUGIN_FILES_VERSION} && \
    if [ -d "/build-assets/plugins/files" ] ; then cp -R /build-assets/plugins/files/* /usr/src/kopano-webapp/plugins/files/ ; fi; \
    if [ -d "/build-assets/scripts/plugin-files" ] ; then for script in /build-assets/scripts/plugin-files/*.sh; do echo "** Applying $script"; bash $script; done && \ ; fi ; \
    ant deploy && \
    cp /usr/src/kopano-webapp/deploy/plugins/files/config.php /rootfs/assets/kopano/config/webapp/config-files.php && \
    ln -sf /etc/kopano/webapp/config-files.php /usr/src/kopano-webapp/deploy/plugins/files/config.php && \
    \
    ## Files Backend: Owncloud
    git clone ${KOPANO_WEBAPP_PLUGIN_FILES_OWNCLOUD_REPO_URL} /usr/src/kopano-webapp/plugins/filesbackendOwncloud && \
    cd /usr/src/kopano-webapp/plugins/filesbackendOwncloud && \
    git checkout ${KOPANO_WEBAPP_PLUGIN_FILES_OWNCLOUD_VERSION} && \
    if [ -d "/build-assets/plugins/filesbackendOwncloud" ] ; then cp -R /build-assets/plugins/filesbackendOwncloud/* /usr/src/kopano-webapp/plugins/filesbackendOwncloud/ ; fi; \
    if [ -d "/build-assets/scripts/plugin-filesbackendOwncloud" ] ; then for script in /build-assets/scripts/plugin-filesbackendOwncloud/*.sh; do echo "** Applying $script"; bash $script; done && \ ; fi ; \
    ant deploy && \
    \
    ## Files Backend: SeaFile
    git clone ${KOPANO_WEBAPP_PLUGIN_FILES_SEAFILE_REPO_URL} /usr/src/kopano-webapp/plugins/filesbackendSeafile && \
    cd /usr/src/kopano-webapp/plugins/filesbackendSeafile && \
    git checkout ${KOPANO_WEBAPP_PLUGIN_FILES_SEAFILE_VERSION} && \
    if [ -d "/build-assets/plugins/filesbackendSeafile" ] ; then cp -R /build-assets/plugins/filesbackendSeafile/* /usr/src/kopano-webapp/plugins/filesbackendSeafile/ ; fi; \
    if [ -d "/build-assets/scripts/plugin-filesbackendSeafile" ] ; then for script in /build-assets/scripts/plugin-filesbackendSeafile/*.sh; do echo "** Applying $script"; bash $script; done && \ ; fi ; \
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
    if [ -d "/build-assets/scripts/plugin-filesbackendSMB" ] ; then for script in /build-assets/scripts/plugin-filesbackendSMB/*.sh; do echo "** Applying $script"; bash $script; done && \ ; fi ; \
    ant deploy && \
    \
    ## HTML Editor: Minimal
    git clone ${KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_MINIMALTINY_REPO_URL} /usr/src/kopano-webapp/plugins/htmleditor-minimaltiny && \
    cd /usr/src/kopano-webapp/plugins/htmleditor-minimaltiny && \
    if [ -d "/build-assets/plugins/htmleditor-minimaltiny" ] ; then cp -R /build-assets/plugins/htmleditor-minimaltiny/* /usr/src/kopano-webapp/plugins/htmleditor-minimaltiny/ ; fi; \
    if [ -d "/build-assets/scripts/plugin-htmleditor-minimaltiny" ] ; then for script in /build-assets/scripts/plugin-htmleditorminimaltiny/*.sh; do echo "** Applying $script"; bash $script; done && \ ; fi ; \
    ant deploy && \
    \
    ## HTML Editor: Jodit
    git clone ${KOPANO_WEBAPP_PLUGIN_JODIT_REPO_URL} /usr/src/kopano-webapp/plugins/htmleditor-jodit && \
    cd /usr/src/kopano-webapp/plugins/htmleditor-jodit && \
    if [ -d "/build-assets/plugins/htmleditor-jodit" ] ; then cp -R /build-assets/plugins/htmleditor-jodit/* /usr/src/kopano-webapp/plugins/htmleditor-jodit/ ; fi; \
    if [ -d "/build-assets/scripts/plugin-htmleditor-jodit" ] ; then for script in /build-assets/scripts/plugin-htmleditorjodit/*.sh; do echo "** Applying $script"; bash $script; done && \ ; fi ; \
    ant deploy && \
    \
    ## HTML Editor: Quill
    git clone ${KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_QUILL_REPO_URL} /usr/src/kopano-webapp/plugins/htmleditor-quill && \
    cd /usr/src/kopano-webapp/plugins/htmleditor-quill && \
    if [ -d "/build-assets/plugins/htmleditor-quill" ] ; then cp -R /build-assets/plugins/htmleditor-quill/* /usr/src/kopano-webapp/plugins/htmleditor-quill/ ; fi; \
    if [ -d "/build-assets/scripts/plugin-htmleditor-quill" ] ; then for script in /build-assets/scripts/plugin-htmleditorquill/*.sh; do echo "** Applying $script"; bash $script; done && \ ; fi ; \
    ant deploy && \
    \
    ## Intranet
    git clone ${KOPANO_WEBAPP_PLUGIN_INTRANET_REPO_URL} /usr/src/kopano-webapp/plugins/intranet && \
    cd /usr/src/kopano-webapp/plugins/intranet && \
    git checkout ${KOPANO_WEBAPP_PLUGIN_INTRANET_VERSION} && \
    if [ -d "/build-assets/plugins/intranet" ] ; then cp -R /build-assets/plugins/intranet/* /usr/src/kopano-webapp/plugins/intranet/ ; fi; \
    if [ -d "/build-assets/scripts/plugin-htmleditor-intranet" ] ; then for script in /build-assets/scripts/plugin-intranet/*.sh; do echo "** Applying $script"; bash $script; done && \ ; fi ; \
    ant deploy && \
    cp /usr/src/kopano-webapp/deploy/plugins/intranet/config.php /rootfs/assets/kopano/config/webapp/config-intranet.php && \
    ln -sf /etc/kopano/webapp/config-intranet.php /usr/src/kopano-webapp/deploy/plugins/intranet/config.php && \
    \
    ## Meet
    git clone ${KOPANO_WEBAPP_PLUGIN_MEET_REPO_URL} /usr/src/kopano-webapp/plugins/meet && \
    cd /usr/src/kopano-webapp/plugins/meet && \
    git checkout ${KOPANO_WEBAPP_PLUGIN_MEET_VERSION} && \
    if [ -d "/build-assets/plugins/meet" ] ; then cp -R /build-assets/plugins/meet/* /usr/src/kopano-webapp/plugins/meet/ ; fi; \
    if [ -d "/build-assets/scripts/plugin-meet" ] ; then for script in /build-assets/scripts/plugin-meet/*.sh; do echo "** Applying $script"; bash $script; done && \ ; fi ; \
    make && \
    mkdir -p /usr/src/kopano-webapp/deploy/plugins/meet && \
    cp -R dist/kopano-webapp-plugin-*/* /usr/src/kopano-webapp/deploy/plugins/meet/ && \
    cp /usr/src/kopano-webapp/deploy/plugins/meet/config.php.dist /rootfs/assets/kopano/config/webapp/config-meet.php && \
    ln -sf /etc/kopano/webapp/config-meet.php /usr/src/kopano-webapp/deploy/plugins/meet/config.php && \
    rm -rf /usr/src/kopano-webapp/deploy/plugins/meet/config.php.dist && \
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
    if [ -d "/build-assets/scripts/plugin-mattermost" ] ; then for script in /build-assets/scripts/plugin-mattermost/*.sh; do echo "** Applying $script"; bash $script; done && \ ; fi ; \
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
    sed -i "/\/\/ The tab in the top tabbar/a \ \ \ \ \ \ site.tabOrderIndex = 30 + i;" /usr/src/kopano-webapp/deploy/plugins/rchat/js/RChatPlugin.js && \
    sed -i "/site: site,/a \ \ \ \ \ \ tabOrderIndex: site.tabOrderIndex," /usr/src/kopano-webapp/deploy/plugins/rchat/js/RChatPlugin.js && \
    if [ -d "/build-assets/plugins/rocketchat" ] ; then cp -R /build-assets/plugins/rocketchat/* /usr/src/kopano-webapp/deploy/plugins/rchat/ ; fi; \
    if [ -d "/build-assets/scripts/plugin-rocketchat" ] ; then for script in /build-assets/scripts/plugin-rocketchat/*.sh; do echo "** Applying $script"; bash $script; done && \ ; fi ; \
    \
    ## S/MIME
    git clone ${KOPANO_WEBAPP_PLUGIN_SMIME_REPO_URL} /usr/src/kopano-webapp/plugins/smime && \
    cd /usr/src/kopano-webapp/plugins/smime && \
    git checkout ${KOPANO_WEBAPP_PLUGIN_SMIME_VERSION} && \
    if [ -d "/build-assets/plugins/smime" ] ; then cp -R /build-assets/plugins/smime/* /usr/src/kopano-webapp/plugins/smime/ ; fi; \
    if [ -d "/build-assets/scripts/plugin-smime" ] ; then for script in /build-assets/scripts/plugin-smime/*.sh; do echo "** Applying $script"; bash $script; done && \ ; fi ; \
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
    chown -R ${NGINX_USER}:${NGINX_GROUP} /rootfs/assets/kopano/plugins/webapp && \
    chown -R ${NGINX_USER}:${NGINX_GROUP} /rootfs/usr/share/kopano-webapp && \
    \
    ### Fetch Additional Scripts
    mkdir -p /rootfs/assets/kopano/scripts && \
    git clone --depth 1 https://stash.kopano.io/scm/ksc/webapp-tools.git /rootfs/assets/kopano/scripts/webapp-tools && \
    find /rootfs/assets/kopano/scripts -name '*.py' -exec chmod +x {} \; && \
    \
    ### Perform modification on scripts
    mkdir -p /rootfs/usr/sbin && \
    ln -s /assets/kopano/scripts/webapp-tools/files_admin/files_admin.py /rootfs/usr/sbin/files-admin && \
    sed -i "s|\"server_ssl\": ssl,|\"server_ssl\": (ssl.lower() == 'true'),|g" /rootfs/assets/kopano/scripts/webapp-tools/files_admin/files_admin.py && \
    sed -i "s|kopano.Server|kopano.server|g" /rootfs/assets/kopano/scripts/webapp-tools/files_admin/files_admin.py && \
    ### Cleanup some webapp issues
    sed -i "s|kopano.Server|kopano.server|g" /rootfs/assets/kopano/scripts/webapp-tools/webapp_admin/kopano-webapp-admin.py && \
    ln -s /assets/kopano/scripts/webapp-tools/webapp_admin/kopano-webapp-admin.py /rootfs/usr/sbin/webapp-admin && \

    ### KDAV Install
    mkdir -p /rootfs/usr/share/kdav && \
    git clone ${KOPANO_KDAV_REPO_URL} /rootfs/usr/share/kdav && \
    cd /rootfs/usr/share/kdav && \
    git checkout ${KOPANO_KDAV_VERSION} && \
    composer install && \
    \
    mkdir -p /rootfs/assets/kdav/config/ && \
    cp -R /rootfs/usr/share/kdav/config.php /rootfs/assets/kdav/config/ && \
    chown -R ${NGINX_USER}:${NGINX_GROUP} /rootfs/usr/share/kdav && \
    chown -R ${NGINX_USER}:${NGINX_GROUP} /rootfs/assets/kdav && \
    \
    ### Z-Push Install
    mkdir -p /rootfs/usr/share/zpush && \
    curl -sSL https://github.com/Z-Hub/Z-Push/archive/${Z_PUSH_VERSION}.tar.gz | tar xvfz - --strip 1 -C /rootfs/usr/share/zpush && \
    mkdir -p /rootfs/usr/sbin && \
    ln -s /usr/share/z-push/src/z-push-admin.php /rootfs/usr/sbin/z-push-admin && \
    ln -s /usr/share/z-push/src/z-push-top.php /rootfs/usr/sbin/z-push-top && \
    mkdir -p /rootfs/assets/zpush/config && \
    cp -R /rootfs/usr/share/zpush/src/config.php /rootfs/assets/zpush/config/ && \
    cp -R /rootfs/usr/share/zpush/src/autodiscover/config.php /rootfs/assets/zpush/config/config-autodiscover.php && \
    cp -R /rootfs/usr/share/zpush/tools/gab2contacts/config.php /rootfs/assets/zpush/config/config-gab2contacts.php && \
    cp -R /rootfs/usr/share/zpush/tools/gab-sync/config.php /rootfs/assets/zpush/config/config-gab-sync.php && \
    mkdir -p /rootfs/assets/zpush/config/backend && \
    mkdir -p /rootfs/assets/zpush/config/backend/ipcmemcached && \
    cp -R /rootfs/usr/share/zpush/src/backend/ipcmemcached/config.php /rootfs/assets/zpush/config/backend/ipcmemcached/ && \
    mkdir -p /rootfs/assets/zpush/config/backend/kopano && \
    cp -R /rootfs/usr/share/zpush/src/backend/kopano/config.php /rootfs/assets/zpush/config/backend/kopano/ && \
    mkdir -p /rootfs/assets/zpush/config/backend/sqlstatemachine && \
    cp -R /rootfs/usr/share/zpush/src/backend/sqlstatemachine/config.php /rootfs/assets/zpush/config/backend/sqlstatemachine/ && \
    chown -R ${NGINX_USER}:${NGINX_GROUP} /rootfs/usr/share/zpush && \
    chown -R ${NGINX_USER}:${NGINX_GROUP} /rootfs/assets/zpush && \
    \
    mkdir -p /rootfs/etc/php/$(php-fpm -v | head -n 1 | awk '{print $2}' | cut -c 1-3)/mods-available/ && \
    echo "extension=mapi.so" > /rootfs/etc/php/$(php-fpm -v | head -n 1 | awk '{print $2}' | cut -c 1-3)/mods-available/mapi.ini && \
    \
    ### Cleanup and Compress Package
    cd /rootfs/ && \
    find . -name .git -type d -print0|xargs -0 rm -rf -- && \
    echo "Kopano Webapp ${KOPANO_WEBAPP_VERSION} built from ${KOPANO_WEBAPP_REPO_URL} on $(date)" > /rootfs/tiredofit/kopano-webapp.version && \
    echo "Commit: $(cd /usr/src/kopano-webapp ; echo $(git rev-parse HEAD))" >> /rootfs/tiredofit/kopano-webapp.version && \
    env | grep KOPANO | sort >> /rootfs/tiredofit/kopano-webapp.version && \
    tar cavf /kopano-webapp.tar.zst . &&\
    \
    ### Cleanup
    apt-get purge -y \
                ${WEBAPP_BUILD_DEPS} \
                && \
    \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /usr/src/* /var/cache/apk/*

#### Runtime Image
FROM tiredofit/nginx-php-fpm:debian-7.3-buster
LABEL maintainer="Dave Conroy (dave at tiredofit dot ca)"

ADD build-assets/container /build-assets

### Move Kopano Dependencies from Core builder
COPY --from=core-builder /kopano-dependencies/* /usr/src/kopano-dependencies/
### Move Previously built files from Core builder
COPY --from=core-builder /*.tar.zst /usr/src/core/

### Move Previously built files from Webapp builder
COPY --from=webapp-builder /*.tar.zst /usr/src/webapp/

ARG KOPANO_DEPENDENCY_HASH

ENV KOPANO_DEPENDENCY_HASH=${KOPANO_DEPENDENCY_HASH:-"620ddd9"} \
    NGINX_LOG_ACCESS_LOCATION=/logs/nginx \
    NGINX_LOG_ERROR_LOCATION=/logs/nginx \
    NGINX_WEBROOT=/usr/share/kopano-webapp \
    PHP_CREATE_SAMPLE_PHP=FALSE \
    PHP_ENABLE_GETTEXT=TRUE \
    PHP_ENABLE_MAPI=TRUE \
    PHP_ENABLE_SIMPLEXML=TRUE \
    PHP_ENABLE_SOAP=TRUE \
    PHP_ENABLE_PDO=TRUE \
    PHP_ENABLE_PDO_SQLITE=TRUE \
    PHP_ENABLE_XMLWRITER=TRUE \
    PHP_ENABLE_TOKENIZER=TRUE \
    PHP_LOG_LOCATION=/logs/php-fpm

RUN set -x && \
    mkdir -p /tiredofit && \
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
                            && \
    \
### Kopano Dependencies
    cd /usr/src/kopano-dependencies && \
    apt-ftparchive packages . | gzip -c9 > Packages.gz && \
    echo "deb [trusted=yes] file:/usr/src/kopano-dependencies ./" > /etc/apt/sources.list.d/kopano-dependencies.list && \
    \
    ##### Install Packages
    apt-get update && \
    BUILD_DEPS=' \
                build-essential \
                libev-dev \
                git \
                python3-dev \
                unzip \
                \
    ' && \
    \
    KOPANO_DEPS=' \
                bc \
                fail2ban \
                iptables \
                libany-uri-escape-perl \
                libdata-uniqid-perl \
                libdb5.3++ \
                libdigest-hmac-perl \
                libev4 \
                libfile-copy-recursive-perl \
                libgsoap-kopano-2.8.109 \
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
                python3-pkg-resources \
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
                ' && \
    \
    apt-get install -y --no-install-recommends \
                       ${BUILD_DEPS} \
                       ${KOPANO_DEPS} \
    && \
    \
    ## Python Deps for Spamd
    pip3 install inotify && \
    \
    ## Webapp Python Scripts
    pip3 install dotty_dict && \
    \
### KDAV Install
    ### Temporary Hack for KDAV - Using Apache along side of Nginx is not what I want to do, but see issues
    ### posted at https://forum.kopano.io/topic/3433/kdav-with-nginx
    apt-get install -y \
                     apache2 \
                     crudini \
                     libapache2-mod-php \
                     php-mbstring \
                     php-sqlite3 \
                     php-xml \
                     php-zip \
                     sqlite \
                     && \
    #php-ext enable corephpdismod opcache && \
    #phpenmod opcache && \
    #phpenmod xmlwriter && \
    #phpenmod tokenizer && \
    rm -rf /etc/apache2/sites-enabled/* && \
    a2disconf other-vhosts-access-log && \
    a2enmod rewrite && \
    echo "Listen 8888" > /etc/apache2/ports.conf && \
    sed -i "s#export APACHE_RUN_USER=www-data#export APACHE_RUN_USER=nginx#g" /etc/apache2/envvars && \
    crudini --set /etc/php/7.3/apache2/php.ini PHP upload_max_filesize 500M && \
    crudini --set /etc/php/7.3/apache2/php.ini PHP post_max_size 500M && \
    crudini --set /etc/php/7.3/apache2/php.ini PHP max_input_vars 1800 && \
    crudini --set /etc/php/7.3/apache2/php.ini Session session.save_path /run/sessions && \
    apt-get remove -y crudini && \
    ##########
    \
    ##### Unpack KCOIDC
    tar xaf /usr/src/core/kopano-kcoidc.tar.zst -C / && \
    \
    ##### Unpack Core
    tar xavf /usr/src/core/kopano-core.tar.zst -C / && \
    \
    ##### Unpack WebApp
    tar xavf /usr/src/webapp/kopano-webapp.tar.zst -C / && \
    \
    ### Build Assets Override
    if [ -d "/build-assets/src" ] ; then cp -R /build-assets/src/* / ; fi; \
    if [ -d "/build-assets/scripts" ] ; then for script in /build-assets/scripts/*.sh; do echo "** Applying $script"; bash $script; done && \ ; fi ; \
    rm -rf /build-assets/ && \
    \
    php-ext enable core && \
    ##### Cleanup
    apt-get purge -y \
                    ${BUILD_DEPS} \
                    apt-utils \
                    && \
    \
    ls -l /usr/src/core/* && \
    ls -l /usr/src/webapp/* && \
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
