FROM docker.io/tiredofit/nginx-php-fpm:debian-7.3-buster as kopano-core-builder

#### Kopano Core
ARG KOPANO_CORE_VERSION
ARG KOPANO_CORE_REPO_URL
ARG KOPANO_DEPENDENCY_HASH
ARG KOPANO_KCOIDC_REPO_URL
ARG KOPANO_KCOIDC_VERSION
ARG KOPANO_PROMETHEUS_EXPORTER_REPO_URL
ARG KOPANO_PROMETHEUS_EXPORTER_VERSION

ENV GO_VERSION=1.17.6 \
    KOPANO_CORE_VERSION=${KOPANO_CORE_VERSION:-"kopanocore-11.0.2"} \
    KOPANO_CORE_REPO_URL=${KOPANO_CORE_REPO_URL:-"https://github.com/Kopano-dev/kopano-core.git"} \
    KOPANO_DEPENDENCY_HASH=${KOPANO_DEPENDENCY_HASH:-"398ec61"} \
    KOPANO_KCOIDC_REPO_URL=${KOPANO_KCOIDC_REPO_URL:-"https://github.com/Kopano-dev/libkcoidc.git"} \
    KOPANO_KCOIDC_VERSION=${KOPANO_KCOIDC_VERSION:-"master"} \
    KOPANO_PROMETHEUS_EXPORTER_REPO_URL=${KOPANO_PROMETHEUS_EXPORTER_REPO_URL:-"https://github.com/Kopano-dev/prometheus-kopano-exporter.git"} \
    KOPANO_PROMETHEUS_EXPORTER_REPO_VERSION=${KOPANO_PROMETHEUS_EXPORTER_REPO_VERSION:-"master"}

ADD build-assets /build-assets

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
    # Fetch Go
    mkdir -p /usr/local/go && \
    curl -sSLk https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz | tar xvfz - --strip 1 -C /usr/local/go && \
    \
    # Get kopano-dependencies and create local repository
    mkdir -p /usr/src/kopano-dependencies && \
    curl -sSLk https://download.kopano.io/community/dependencies:/kopano-dependencies-${KOPANO_DEPENDENCY_HASH}-Debian_10-amd64.tar.gz | tar xvfz - --strip 1 -C /usr/src/kopano-dependencies/ && \
    cd /usr/src/kopano-dependencies && \
    apt-ftparchive packages . | gzip -c9 > Packages.gz && \
    echo "deb [trusted=yes] file:/usr/src/kopano-dependencies ./" > /etc/apt/sources.list.d/kopano-dependencies.list && \
    \
    apt-get update -y && \
    BUILD_DEPS=" \
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
                        php${PHP_BASE}-dev \
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
    " \
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
    mkdir -p /rootfs/assets/.changelogs/ && \
    make DESTDIR=/rootfs install && \
    PYTHON="$(which python3)" make DESTDIR=/rootfs python && \
    echo "Kopano kcOIDC ${KOPANO_KCOIDC_VERSION} built from ${KOPANO_KCOIDC_REPO_URL} on $(date)" > /rootfs/assets/.changelogs/kopano-kcoidc.version && \
    echo "Commit: $(cd /usr/src/libkcoidc ; echo $(git rev-parse HEAD))" >> /rootfs/assets/.changelogs/kopano-kcoidc.version && \
    cd /rootfs && \
    mkdir -p /kopano-core/ && \
    tar cavf /kopano-core/kopano-kcoidc.tar.zst . && \
    cd /usr/src && \
    rm -rf /rootfs && \
    \
    ### Build Prometheus Exporter
    git clone ${KOPANO_PROMETHEUS_EXPORTER_REPO_URL} /usr/src/prometheus-exporter && \
    cd /usr/src/prometheus-exporter && \
    git checkout ${KOPANO_PROMETHEUS_EXPORTER_REPO_VERSION} && \
    GOROOT=/usr/local/go PATH=/usr/local/go/bin:$PATH make -j $(nproc) && \
    mkdir -p /rootfs/assets/.changelogs/ && \
    echo "Kopano Prometheus ${KOPANO_PROMETHEUS_EXPORTER_REPO_VERSION} built from ${KOPANO_PROMETHEUS_EXPORTER_REPO_URL} on $(date)" > /rootfs/assets/.changelogs/kopano-prometheus-exporter.version && \
    echo "Commit: $(cd /usr/src/prometheus-exporter ; echo $(git rev-parse HEAD))" >> /rootfs/assets/.changelogs/kopano-prometheus-exporter.version && \
    mkdir -p /rootfs/usr/sbin && \
    cp /usr/src/prometheus-exporter/bin/prometheus-kopano-exporter /rootfs/usr/sbin/ && \
    cd /rootfs && \
    mkdir -p /kopano-prometheus-exporter/ && \
    tar cavf /kopano-prometheus-exporter/kopano-prometheus-exporter.tar.zst . && \
    cd /usr/src && \
    rm -rf /rootfs && \
    \
    ### Build Kopano Core
    git clone ${KOPANO_CORE_REPO_URL} /usr/src/kopano-core && \
    cd /usr/src/kopano-core && \
    git checkout ${KOPANO_CORE_VERSION} && \
    if [ -d "/build-assets/src" ] ; then cp -Rp /build-assets/src/* /usr/src/kopano-core ; fi; \
    if [ -d "/build-assets/scripts" ] ; then for script in /build-assets/scripts/*.sh; do echo "** Applying $script"; bash $script; done ; fi ; \
    mkdir -p /rootfs/assets/.changelogs/ && \
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
    echo "** Starting to build Kopano Core with '$(php -v | head -n1)'" && \
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
    mkdir -p /rootfs/assets/kopano/scripts && \
    git clone --depth 1 https://stash.kopano.io/scm/ksc/Core-tools.git /rootfs/assets/kopano/scripts/core-tools && \
    git clone --depth 1 https://stash.kopano.io/scm/ksc/lab-scripts.git /rootfs/assets/kopano/scripts/lab-scripts && \
    git clone --depth 1 https://stash.kopano.io/scm/ksc/mail-migrations.git /rootfs/assets/kopano/scripts/mail-migrations && \
    git clone --depth 1 https://stash.kopano.io/scm/ksc/support.git /rootfs/assets/kopano/scripts/support && \
    find /rootfs/assets/kopano/scripts -name '*.py' -exec chmod +x {} \; && \
    \
    ## Cleanup some of the scripts
    sed -i "s|kopano.Server|kopano.server|g" /rootfs/assets/kopano/scripts/core-tools/store-stats/store-stats.py && \
    sed -i "s|kopano.Server|kopano.server|g" /rootfs/assets/kopano/scripts/core-tools/Import-ics/import-ics.py && \
    sed -i "s|kopano.Server|kopano.server|g" /rootfs/assets/kopano/scripts/core-tools/contacts2csv/contact2csv.py && \
    sed -i "s|kopano.Server|kopano.server|g" /rootfs/assets/kopano/scripts/core-tools/show-item-information/show-item-information.py && \
    sed -i "s|/usr/bin/env python|/usr/bin/env python3|g" /rootfs/assets/kopano/scripts/core-tools/delete-items/delete-items.py && \
    sed -i "s|locale.format|locale.format_string|g" /rootfs/assets/kopano/scripts/core-tools/store-stats/store-stats.py && \
    sed -i "s|# \!/usr/bin/env python|#\!/usr/bin/env python3|g" /rootfs/assets/kopano/scripts/core-tools/kopano-cleanup/kopano-cleanup.py && \
    mkdir -p /rootfs/usr/sbin && \
    ln -s /assets/kopano/scripts/core-tools/store-stats/store-stats.py /rootfs/usr/sbin/store-stats && \
    ln -s /assets/kopano/scripts/core-tools/delete-items/delete-items.py /rootfs/usr/sbin/delete-items && \
    ln -s /assets/kopano/scripts/core-tools/find-item/find-item.py /rootfs/usr/sbin/find-item && \
    ln -s /assets/kopano/scripts/core-tools/kopano-cleanup/kopano-cleanup.py /rootfs/usr/sbin/kopano-cleanup && \
    ln -s /assets/kopano/scripts/core-tools/show-item-information/show-item-information.py /rootfs/usr/sbin/show-item-information && \
    \
    mkdir -p /rootfs/assets/kopano/config && \
    cp -Rp /rootfs/etc/kopano/* /rootfs/assets/kopano/config/ && \
    mkdir -p /rootfs/assets/kopano/templates && \
    cp -Rp /rootfs/etc/kopano/quotamail/* /rootfs/assets/kopano/templates && \
    rm -rf /rootfs/etc/kopano/quotamail && \
    mkdir -p /rootfs/assets/kopano/userscripts && \
    mkdir -p /rootfs/assets/kopano/userscripts/createcompany.d \
             /rootfs/assets/kopano/userscripts/creategroup.d \
             /rootfs/assets/kopano/userscripts/createuser.d \
             /rootfs/assets/kopano/userscripts/deletecompany.d \
             /rootfs/assets/kopano/userscripts/deletegroup.d \
             /rootfs/assets/kopano/userscripts/deleteuser.d && \
    cp -Rp /rootfs/usr/lib/kopano/userscripts /rootfs/assets/kopano/userscripts && \
    \
    rm -rf /rootfs/etc/kopano && \
    mkdir -p /rootfs/etc/php/${PHP_BASE}/mods-available/ && \
    mv /rootfs/etc/php/${PHP_BASE}/cli/conf.d/mapi.ini /rootfs/etc/php/${PHP_BASE}/mods-available/ && \
    echo ";priority=20" >> /rootfs/etc/php/${PHP_BASE}/mods-available/mapi.ini && \
    ln -sf /config /rootfs/etc/kopano && \
    ln -s /usr/bin/kopano-autorespond /rootfs/usr/sbin/kopano-autorespond && \
    \
    mkdir -p /var/run/kopano && \
    mkdir -p /var/run/kopano-search && \
    chown -R kopano /var/run/kopano && \
    chown -R kopano /var/run/kopano-search && \
    cd /rootfs && \
    find . -name .git -type d -print0|xargs -0 rm -rf -- && \
    echo "Kopano Core ${KOPANO_CORE_VERSION} built from ${KOPANO_CORE_REPO_URL} on $(date)" > /rootfs/assets/.changelogs/kopano-core.version && \
    echo "Commit: $(cd /usr/src/kopano-core ; echo $(git rev-parse HEAD))" >> /rootfs/assets/.changelogs/kopano-core.version && \
    env | grep KOPANO | sed "/KOPANO_KCOIDC/d" | sort >> /rootfs/assets/.changelogs/kopano-core.version && \
    echo "Dependency Hash '${KOPANO_DEPENDENCY_HASH} from: 'https://download.kopano.io/community/dependencies:'" >> /rootfs/assets/.changelogs/kopano-core.version && \
    tar cavf /kopano-core/kopano-core.tar.zst . && \
    cd /usr/src/kopano-dependencies && \
    mkdir -p /kopano-dependencies && \
    tar cavf /kopano-dependencies/kopano-dependencies.tar.zst . && \
    ### Cleanup
    apt-get purge -y \
                ${BUILD_DEPS} \
                && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /rootfs/* && \
    rm -rf /usr/src/*

FROM scratch
LABEL maintainer="Dave Conroy (github.com/tiredofit)"

COPY --from=kopano-core-builder /kopano-core/* /kopano-core/
COPY --from=kopano-core-builder /kopano-dependencies/* /kopano-dependencies/
COPY --from=kopano-core-builder /kopano-prometheus-exporter/* /kopano-prometheus-exporter/
ADD CHANGELOG.md /tiredofit_docker-kopano-core.md
