## 2.3.1 2022-01-24 <dave at tiredofit dot ca>

   ### Added
      - Update Kopano Dependencies


## 2.3.0 2021-12-06 <dave at tiredofit dot ca>

   ### Added
      - Add Kopano Prometheus Exporter


## 2.2.3 2021-09-25 <dave at tiredofit dot ca>

   ### Added
      - Update dependencies


## 2.2.2 2021-08-16 <dave at tiredofit dot ca>

   ### Added
      - Readd PHP mapi.ini in a different way


## 2.2.1 2021-08-04 <dave at tiredofit dot ca>

   ### Added
      - Force default Kopano Core to use nginx-php-fpm:7.3 for build


## 2.2.0 2021-08-04 <dave at tiredofit dot ca>

   ### Added
      - Golang 1.16.6 for building kcoidc

   ### Changed
      - Fix stray mkdir appearing in /
      - Stop hardcoding PHP version and rely on PHP_BASE environment variable to introduce multi versioned CI builds
      - Delete stray mapi.ini causing a PHP error on the console


## 2.1.3 2021-07-21 <dave at tiredofit dot ca>

   ### Changed
      - Cleanup Dockerfile


## 2.1.2 2021-05-18 <dave at tiredofit dot ca>

   ### Added
      - Fix and repair some Kopano core-tools addons
      - Create shortcuts for delete-items,find-item,kopano-cleanup,show-item-information


## 2.1.1 2021-05-17 <dave at tiredofit dot ca>

   ### Changed
      - Add fixes to get rid of warnings for kopano.Server in python scripts


## 2.1.0 2021-05-17 <dave at tiredofit dot ca>

   ### Added
      - Kopano Core 11.0.2
      - Kopano build dependencies b1bca6e
      - GO Version 1.16.4


## 2.0.0 2021-04-13 <dave at tiredofit dot ca>

   ### Changed
      - Split image into 3 builds
      - Build Base tiredofit/nginx-php-fpm:7.3-debian-buster
      - Go Version 1.16.3
      - Kopano Dependencies: 620ddd9
      - KCOIDC Version: master
      - Kopano Core Version: master (11.0.1)


