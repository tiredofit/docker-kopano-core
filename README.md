# UNDER DEVELOPMENT - NOT STABLE or for PRODUCTION USE 
# hub.docker.com/r/tiredofit/kopano


[![Build Status](https://img.shields.io/docker/build/tiredofit/kopano.svg)](https://hub.docker.com/r/tiredofit/kopano)
[![Docker Pulls](https://img.shields.io/docker/pulls/tiredofit/kopano.svg)](https://hub.docker.com/r/tiredofit/kopano)
[![Docker Stars](https://img.shields.io/docker/stars/tiredofit/kopano.svg)](https://hub.docker.com/r/tiredofit/kopano)
[![Docker Layers](https://images.microbadger.com/badges/image/tiredofit/kopano.svg)](https://microbadger.com/images/tiredofit/kopano)

# Introduction

This will build a container for the [Kopano Groupware](https://kopano.io/) suite. 

**At current time this image has the potential of making you cry - Do not use for production use. I am not a Kopano expert yet using this opportunity to understand the ins and outs of the software to potentially use for a non-profit educational institution. I am constantly relying on the expertise of the community in the Kopano.io Community forums and the manuals, and still have a long way to go**

* Installs latest nightly builds from community build offering
* Automatic configuration of various services
* Automatic certificate and CA generation
* Kopano Core (backup, dagent, gateway, ical, monitor, server, spamd, spooler, webapp)
* Various Webapp plugins installed
* Kopano Meet (grapi, kapi, kwmserver, konnect, meet)
* Z-Push for CalDAV,CardDAV
* Everything configurable via environment variables

* This Container uses a [customized Debian Linux base](https://hub.docker.com/r/tiredofit/alpine) which includes [s6 overlay](https://github.com/just-containers/s6-overlay) enabled for PID 1 Init capabilities, [zabbix-agent](https://zabbix.org) for individual container monitoring, Cron also installed along with other tools (bash,curl, less, logrotate, nano, vim) for easier management. It also supports sending to external SMTP servers.
* This container also relies on [customized Nginx base](https://hub.docker.com/tiredofit/r/nginx) and a [customized PHP-FPM base](https://hub.docker.com/r/tiredofit/nginx-php-fpm). Each of the above images have their own unique configuration settings that are carried over to this image.

*This is an incredibly complex piece of software that will tries to get you up and running with sane defaults, you will need to switch eventually over to manually configuring the configuration file when depending on your usage case. My defaults do not necessary follow the normal defaults as per the instruction manuals. This is intended as a preview for peer review*

[Changelog](CHANGELOG.md)

# Authors

- [Dave Conroy](https://github.com/tiredofit)

# Table of Contents

- [Introduction](#introduction)
    - [Changelog](CHANGELOG.md)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
    - [Data Volumes](#data-volumes)
    - [Environment Variables](#environmentvariables)
- [Maintenance](#maintenance)
    - [Shell Access](#shell-access)

# Prerequisites

This image assumes that you are using a reverse proxy such as 
[jwilder/nginx-proxy](https://github.com/jwilder/nginx-proxy) and optionally the [Let's Encrypt Proxy 
Companion @ 
https://github.com/JrCs/docker-letsencrypt-nginx-proxy-companion](https://github.com/JrCs/docker-letsencrypt-nginx-proxy-companion), or [Traefik](https://github.com/tiredofit/docker-traefik) (preferred)
in order to serve your pages. However, it will run just fine on it's own if you map appropriate ports.

You will also need an external MySQL/MariaDB Container.

# Installation

Automated builds of the image are available on [Docker Hub](https://hub.docker.com/r/tiredofit/kopano) and is the recommended
method of installation.


```bash
docker pull tiredofit/kopano:latest
```

# Quick Start

* The quickest way to get started is using [docker-compose](https://docs.docker.com/compose/). See the examples folder for a working [docker-compose.yml](examples/docker-compose.yml) that can be modified for development or production use.

* Set various [environment variables](#environment-variables) to understand the capabiltiies of this image.
* Map [persistent storage](#data-volumes) for access to configuration and data files for backup.

# Configuration

## Data-Volumes

The following directories are used for configuration and can be mapped for persistent storage.

| Directory | Description |
|-----------|-------------|
| `/certs` | Certificates for services and CA. Do not mount your external certificates here say from Letsencrypt |
| `/config/` | If you wish to use your own configuration files with `SETUP_TYPE=MANUAL` map this. |
| `/data/` | Persistent Data for services
| `/logs/` | Logfiles for various services (Fail2ban, Kopano, Nginx, Z-Push)

## Environment Variables

Along with the Environment Variables from the [Base image](https://hub.docker.com/r/tiredofit/debian), [Nginx image](https://hub.docker.com/r/tiredofit/nginx), and [PHP-FPM](https://hub.docker.com/r/tiredofit/nginx-php-fpm),below is the complete list of available options that can be used to customize your installation.

## There are over 550 environment variables that can be set - They will be added once image is stable.

**Container Options**

| Parameter | Description | Default |
|-----------|-------------|---------|
| `SETUP_TYPE` | `MANUAL` or `AUTO` to auto generate cofniguration for services on bootup, otherwise let admin control configuration. | `AUTO`
| `MODE` | Type of Install - `STANDALONE` for all packages | `STANDALONE` |

**Logging Options**
| Parameter | Description | Default |
|-----------|-------------|---------|
| `LOG_PATH_KOPANO` | Logfiles for Kopano Services | `/logs/kopano/`
| `LOG_PATH_WEBAPP` | Logfiles for Kopano Webapp Users | `/logs/kopano/webapp-users`
| `LOG_PATH_ZPUSH` | Logfiles for Z-Push | `/logs/zpush/`
| `LOG_TYPE` | Log to `FILE` or `CONSOLE` | `FILE` |
| `LOG_TIMESTAMPS` | Include timestamps in logs | `TRUE` |
| `LOG_LEVEL` | Logging Level `NONE` `CRITICAL` `ERROR` `WARN` `NOTICE` `INFO` `DEBUG` `ERROR` | `INFO` |

**Autorespond Options** (needs work)
| Parameter | Description | Default |
|-----------|-------------|---------|

**Backup Options**
| Parameter | Description | Default |
|-----------|-------------|---------|
| `BACKUP_SSL_CERT_FILE` | Backup SSL Certificate File | `/certs/backup.crt` |
| `BACKUP_SSL_KEY_FILE` | Backup SSL Key File | `/certs/backup.pem` |
| `BACKUP_WORKER_PROCESSES` | Amount of processes for backup | `1` |
| `LOG_FILE_BACKUP` | Logfile Name | `backup.log` |

**Calendar Options** (needs work)
| Parameter | Description | Default |
|-----------|-------------|---------|

**DAgent Options** (needs work)
| Parameter | Description | Default |
|-----------|-------------|---------|
| `DAGENT_SSL_CERT_FILE` | Backup SSL Certificate File | `/certs/backup.crt` |
| `DAGENT_SSL_KEY_FILE` | Backup SSL Key File | `/certs/backup.pem` |
| `DAGENT_LISTEN_HOST` | LMTP Listen address (insecure) | `*` |
| `DAGENT_LISTEN_PORT` | LMTP Listen port (insecure) | `2003` |


**Database Options**
| Parameter | Description | Default |
|-----------|-------------|---------|
| `DB_HOST` | Host or container name of MariaDB Server ||
| `DB_PORT` | MariaDB Port | `3306` |
| `DB_NAME` | MariaDB Database name ||
| `DB_USER` | MariaDB Username for above Database e.g. `asterisk` ||
| `DB_PASS` | MariaDB Password for above Database e.g. `password`||


**Gateway Options** (needs work)
| Parameter | Description | Default |
|-----------|-------------|---------|
| `GATEWAY_BYPASS_AUTHENTICATION_ADMIN` | Bypass authentication for Admins on local socket | `FALSE` |
| `GATEWAY_ENABLE_IMAP_SECURE` | Enable IMAP (secure) | `TRUE` |
| `GATEWAY_ENABLE_IMAP` | Enable IMAP (insecure) | `FALSE` |
| `GATEWAY_ENABLE_POP3` | Enable POP3 (insecure) | `FALSE` |
| `GATEWAY_ENABLE_POP3S` | Enable POP3 (secure) | `TRUE` |
| `GATEWAY_GREETING_SHOW_HOSTNAME` | Show hostiname in greeting | `FALSE`
| `GATEWAY_HOSTNAME` | Greeting Hostname | `example.com` |
| `GATEWAY_HTML_SAFETY_FILTER` | Use HTML Safety Filter | `FALSE` |
| `GATEWAY_IMAP_MAX_MESSAGE_SIZE` | Maximum Message Size to Process for POP3/IMAP | `25M` |
| `GATEWAY_LISTEN_HOST_IMAP_SECURE` | Listen address (secure) | `*` |
| `GATEWAY_LISTEN_HOST_IMAP` | Listen address (insecure) | `*` |
| `GATEWAY_LISTEN_HOST_POP3_SECURE` | Listen address (secure) | `*` |
| `GATEWAY_LISTEN_HOST_POP3` | Listen address (insecure) | `*` |
| `GATEWAY_LISTEN_PORT_IMAP_SECURE` | Listen port (insecure) | `993` |
| `GATEWAY_LISTEN_PORT_IMAP` | Listen port (insecure) | `143` |
| `GATEWAY_LISTEN_PORT_POP3_SECURE` | Listen port (insecure) | `995` |
| `GATEWAY_LISTEN_PORT_POP3` | Listen port (insecure) | `143` |
| `GATEWAY_SSL_CERT_FILE` | Gateway SSL Certificate File | `/certs/gateway.crt` |
| `GATEWAY_SSL_KEY_FILE` | Gateway SSL Key File | `/certs/gateway.pem` |
| `GATEWAY_SSL_PREFER_SERVER_CIPHERS` | Prefer Server Ciphers when using SSL | `TRUE` |
| `GATEWAY_SSL_REQUIRE_PLAINTEXT_AUTH` | Require SSL when using AUTHPLAIN  | `TRUE` |

| `LOG_FILE_GATEWAY` | Logfile Name | `gateway.log` |

**GRAPI Options**
| Parameter | Description | Default |
|-----------|-------------|---------|
| `GRAPI_WORKERS` | Amount of Worker Processes | `8` |
| `GRAPI_PATH` | Path for Storing GRAPI Data | `/data/grapi/` |
| `GRAPI_CONFIG_FILE` | Configuration File | `grapi.cfg` |
| `GRAPI_DISABLE_TLS_VALIDATION` | Don't validate client certificates | `FALSE` |
| `GRAPI_ENABLE_EXPERIMENTAL_ENDPOINTS` | Enable experimental endpoints | `FALSE` |
| `SOCKET_GRAPI` | Socket file | `/var/run/kopano-grapi` |

**ICAL Options** (needs work)
| Parameter | Description | Default |
|-----------|-------------|---------|
| `ICAL_LISTEN_HOST` | Listen address (insecure) | `*` |
| `ICAL_LISTEN_HOST_SECURE` | Listen address (secure) | `*` |
| `ICAL_LISTEN_PORT` | Listen port (insecure) | `8080` |
| `ICAL_LISTEN_PORT_SECURE` | Listen port (insecure) | `8443` |
| `ICAL_SSL_CERT_FILE` | ICAL SSL Certificate File | `/certs/ical.crt` |
| `ICAL_SSL_KEY_FILE` | ICAL SSL Key File | `/certs/ical.pem` |
| `LOG_FILE_ICAL` | Logfile Name | `ical.log` |

**KDAV Options** (needs work)
| Parameter | Description | Default |
|-----------|-------------|---------|
| `KDAV_CONFIG_FILE` | Configuration File | `kdav.php` |
| `KDAV_HOSTNAME` | DAV Service Hostname ||
| `KDAV_REALM` | KDAV Realm ||
| `LOG_FILE_KDAV` | Logfile Name | `kdav.log` |

**LDAP Options** (needs work)
| Parameter | Description | Default |
|-----------|-------------|---------|
| `LDAP_TYPE` | Type of LDAP Server for defaults `AD` `OPENLDAP` | `OPENLDAP` |
| `LDAP_HOST` | URI for LDAP Server - Can include port number ||
| `LDAP_ATTRIBUTE_USER_UNIQUE` | Unique ID for user ||
| `LDAP_BASE_DN` | Base Distringuished Name (e =dc=hostname,dc=com |
| `LDAP_BIND_DN` | User to Bind to LDAP (e.g. cn=admin,dc=orgname,dc=org) ||
| `LDAP_BIND_PASS` | Password for Above Bind User (e.g. password) ||
| `LDAP_FILTER_USER_SEARCH` | Filter for searching for a user ||
| `LDAP_OBJECT_ATTRIBUTE_TYPE_GROUP` | Object Name for Kopano Users | `` |
| `LDAP_OBJECT_ATTRIBUTE_TYPE_USER` | Object Name for Kopano Users | `kopano-user` |
| `LDAP_PAGE_SIZE` | Page size for LDAP Operations | `1000` |
| `LDAP_SCOPE` | Scope of searches | `sub`
| `LDAP_STARTTLS` | Use StartTLS when connecting to `LDAP_HOST` | `FALSE` |
| `LDAP_TIMEOUT` | Timeout in seconds for operations | `30` |


**KAPI Options** (needs work)
| Parameter | Description | Default |
|-----------|-------------|---------|
| `KAPI_CONFIG_FILE` | Configuration File | `kapi.cfg` |

**Konnect Options** (needs work)
| Parameter | Description | Default |
|-----------|-------------|---------|
| `KONNECT_CONFIG_FILE` | Configuration File | `konnect.cfg` |
| `KONNECT_BACKEND` | Konnect Backend | `KC` |
| `KONNECT_HOSTNAME` | Konnect Service Hostname | |
| `LOG_FILE_KONNECT` | Logfile Name | `konnect.log` |

**KWM Server Options** (needs work)
| Parameter | Description | Default |
|-----------|-------------|---------|
| `KWM_CONFIG_FILE` | Configuration File | `kwm.cfg` |

**Meet Options** (needs work)
| Parameter | Description | Default |
|-----------|-------------|---------|
| `MEET_CONFIG_FILE` | Configuration File | `meet.json` |
| `MEET_HOSTNAME` | Hostname to use for Kopano Meet | 

**Monitor Options**
| Parameter | Description | Default |
|-----------|-------------|---------|
| `MONITOR_QUOTA_CHECK_INTERVAL` | Check Quotas in minutes interval | `15` |
| `MONITOR_QUOTA_RESEND_INTERVAL` | Resend Notifications in minutes interval | `-1` |
| `MONITOR_SSL_CERT_FILE` | Monitor SSL Certificate File | `/certs/monitor.crt` |
| `MONTIOR_SSL_KEY_FILE` | Monitor SSL Key File | `/certs/monitor.pem` |
| `LOG_FILE_MONITOR` | Logfile Name | `monitor.log` |

**Search Options** (needs work)
| Parameter | Description | Default |
|-----------|-------------|---------|
| `SEARCH_ENABLE_HTTP` | Enable HTTP Communications to Search Socket | `FALSE` |
| `SEARCH_ENABLE_HTTPS` | Enable TLS Communications to Search Socket | `FALSE` |
| `SEARCH_SSL_CERT_FILE` | Search SSL Certificate File | `/certs/search.crt` |
| `SEARCH_SSL_KEY_FILE` | Search SSL Key File | `/certs/search.pem` |
|
| `SEARCH_SSL_LISTEN_CERT_FILE` | Search Listen SSL Certificate File | `/certs/search-listen.crt` |
| `SEARCH_SSL_LISTEN_KEY_FILE` | Search Listen SSL Key File | `/certs/search-listen.pem` |
|
| `LOG_FILE_SEARCH` | Logfile Name | `search.log` |

**Server Options** (needs work)
| Parameter | Description | Default |
|-----------|-------------|---------|
| `LOG_FILE_SERVER` | Logfile Name | `server.log` |
| `SERVER_ENABLE_GAB` | Enable Global Address Book | `TRUE` |
| `SERVER_ENABLE_HTTPS` | Enable TLS Communications to Server Socket | `FALSE` |
| `SERVER_ENABLE_HTTP` | Enable HTTP Communications to Server Socket | `FALSE` |
| `SERVER_SSL_KEY_PASS` | Set password set on SSL Key || 
| `SERVER_GAB_HIDE_EVERYONE` | Hide everyone from GAB | `FALSE` |
| `SERVER_GAB_HIDE_SYSTEM` | Hide System Account from GAB | `FALSE` |
| `SEVER_ADDITIONAL_ARGS` | Pass additional arguments to server process ||
| `SERVER_OIDC_IDENTIFIER` | URL to OIDC Provider ||
| `SERVER_ATTACHMENT_BACKEND` | Files Backend `FILES` `FILES_V2` `S3` |
| `SERVER_ENABLE_SSO` | Enable SSO Functionality w/Server | `FALSE` |
| `SERVER_SSL_CERT_FILE` | Server SSL Certificate File | `/certs/server.crt` |
| `SERVER_SSL_KEY_FILE` | Server SSL Key File | `/certs/server.pem` |
|

**SpamD Options** (needs work)
| Parameter | Description | Default |
|-----------|-------------|---------|
| `LOG_FILE_SPAMD` | Logfile Name | `spamd.log` |
| `SPAMD_SSL_CERT_FILE` | SpamD SSL Certificate File | `/certs/spamd.crt` |
| `SPAMD_SSL_KEY_FILE` | SpamD SSL Key File | `/certs/spamd.pem` |
|

**Spooler Options** (needs work)
| Parameter | Description | Default |
|-----------|-------------|---------|
| `LOG_FILE_SPOOLER` | Logfile Name | `spooler.log` |
| `SPOOLER_SMTP_HOST` | Host that can provide outbound MTA functionality ||
| `SPOOLER_SMTP_PORT` | Port to connect to on `SMTP_HOST` | 25 |
| `SPOOLER_SSL_CERT_FILE` | Spooler SSL Certificate File | `/certs/spooler.crt` |
| `SPOOLER_SSL_KEY_FILE` | Spooler SSL Key File | `/certs/spooler.pem` |
|


**Webapp Options** (needs work)
| Parameter | Description | Default |
|-----------|-------------|---------|
| `WEBAPP_HOSTNAME` | Hostname of Webmail service | `webapp.example.com` |
| `WEBAPP_THEME` | Set Default Theme ||
| `WEBAPP_TITLE` | Browser Title of WebApp | `Kopano WebApp` |
| `WEBAPP_ENABLE_ADVANCED_SETTINGS` | Enable Advanced Settings ||
| `WEBAPP_COOKIE_NAME` | Cookie Name | `KOPANO_WEBAPP`
| `WEBAPP_ICONSET` | Set Default Icons | `breeze` |
| `WEBAPP_CROSS_DOMAIN_AUTHENTICATION_ALLOWED_DOMAINS` | Cross Domain Authentication Domains ||
| `WEBAPP_LOGINNAME_STRIP_DOMAIN` | Strip Doman/ Prefix from username ||
| `WEBAPP_ENABLE_REMOTE_PASSWORD` | Perform hack to allow $_SERVER_REMOTE_PASS to auto login user | `FALSE` |

**Webapp Plugin: Intranet Options** (needs work)
| Parameter | Description | Default |
|-----------|-------------|---------|
| `WEBAPP_PLUGIN_INTRANET1_TITLE` | Service Name to appear in Header Bar ||
| `WEBAPP_PLUGIN_INTRANET1_URL` | URL to load for service ||
| `WEBAPP_PLUGIN_INTRANET1_AUTOSTART` | Auto start service upon login ||
| `WEBAPP_PLUGIN_INTRANET1_ICON` | Icon to load for service ||


**Z-Push Options** (needs work)
| Parameter | Description | Default |
|-----------|-------------|---------|

### Networking

The following ports are exposed.

| Port      | Description       |
|-----------|-------------------|
| `80`      | HTTP              |
| `110`     | Gateway - POP3    |
| `143`     | Gateway - IMAP    |
| `236`     | Server            |
| `237`     | Server - Secure   |
| `993`     | Gateway - IMAPs   |
| `995`     | Gateway - POPs    |
| `1238`    | Search            |
| `2003`    | DAgent LMTP       |
| `8039`    | KAPI              |
| `8080`    | ICal              |
| `8443`    | ICal - Secure     |
| `8777`    | Konnect           |
| `8778`    | KWM Server        |

## Maintenance

To be added when image is stable

#### Shell Access

For debugging and maintenance purposes you may want access the containers shell.

```bash
docker exec -it (whatever your container name is e.g.) kopano bash
```
