# UNDER DEVELOPMENT - NOT STABLE or for PRODUCTION USE 
# hub.docker.com/r/tiredofit/kopano


[![Build Status](https://img.shields.io/docker/build/tiredofit/kopano.svg)](https://hub.docker.com/r/tiredofit/kopano)
[![Docker Pulls](https://img.shields.io/docker/pulls/tiredofit/kopano.svg)](https://hub.docker.com/r/tiredofit/kopano)
[![Docker Stars](https://img.shields.io/docker/stars/tiredofit/kopano.svg)](https://hub.docker.com/r/tiredofit/kopano)
[![Docker Layers](https://images.microbadger.com/badges/image/tiredofit/kopano.svg)](https://microbadger.com/images/tiredofit/kopano)

# Introduction

This will build a container for the [Kopano Groupware](https://kopano.io/) suite. 

**At current time this image has the potential of making you cry - Do not use for production use. I am not a Kopano expert yet using this opportunity to understand the in's and out's of the software to potentially use for a non-profit educational institution.**

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

You will also need an external MySQL/MariaDB Container

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

## There are over 550 environment variables - They will be added once image is stable.

| Parameter | Description |
|-----------|-------------|
| `SETUP_TYPE` | Default: `AUTO` to auto generate cofniguration for services on bootup, otherwise let admin control configuration. |
| `MODE` | Type of Install - `AIO` for all packages |

## Maintenance

To be added when image is stable

#### Shell Access

For debugging and maintenance purposes you may want access the containers shell.

```bash
docker exec -it (whatever your container name is e.g.) kopano bash
```
