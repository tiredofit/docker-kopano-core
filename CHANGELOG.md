## 0.24.0 2020-08-07 <dave at tiredofit dot ca>

   ### Changed
      - Fix Quick Items and Contact Fax plugin configuration


## 0.23.0 2020-08-06 <dave at tiredofit dot ca>

   ### Added
      - Enable DOMPurify by Default for Webapp


## 0.22.0 2020-08-05 <dave at tiredofit dot ca>

   ### Added
      - Add python3-setuptools


## 0.21.0 2020-08-04 <dave at tiredofit dot ca>

   ### Added
      - Allow to cherrypick which services to run for multi container usage


## 0.20.0 2020-08-04 <dave at tiredofit dot ca>

   ### Added
      - Add environment variables to enable or disable individual webapp plugins


## 0.19.0 2020-07-31 <dave at tiredofit dot ca>

   ### Added
      - Add custom assets support (drop files into /assets/custom following folder structure in relation to / to overwrite it)


## 0.18.0 2020-06-27 <dave at tiredofit dot ca>

   ### Changed
      - Run shellcheck against scripts adding quotes around variables
      - Fix misspelled environment variables
      - Fix issue with LDAP_MODE=FUSIONDIRECTORY not picking up groups


## 0.17.0 2020-06-21 <dave at tiredofit dot ca>

   ### Changed
      - DAgent Raw Message directory fix


## 0.16.0 2020-06-21 <dave at tiredofit dot ca>

   ### Changed
      - Fix DAgent Plugin Setting


## 0.15.0 2020-06-21 <dave at tiredofit dot ca>

   ### Added
      - Cleanup Dockerfile


## 0.14.1 2020-06-21 <dave at tiredofit dot ca>

   ### Changed
      - Cleanup Dockerfile


## 0.14.0 2020-06-21 <dave at tiredofit dot ca>

   ### Changed
      - Fix Environment variables for Webapp Plugin Defaults


## 0.13.0 2020-06-21 <dave at tiredofit dot ca>

   ### Added
      - Reduce size of Docker Image by enabling cleanup routines


## 0.0.12 2020-06-21 <dave at tiredofit dot ca>

   ### Changed
      - Fix fail2ban startup
      - Don't look for Kopano Server socket before starting Konnect


## 0.0.11 2020-06-20 <dave at tiredofit dot ca>

   ### Changed
      - Fix generating Konnect PKEY


## 0.0.10 2020-06-20 <dave at tiredofit dot ca>

   ### Changed
      - Updates to Server Backend


## 0.0.9 2020-06-20 <dave at tiredofit dot ca>

   ### Changed
      - Fix for broken case statement


## 0.0.8 2020-06-20 <dave at tiredofit dot ca>

   ### Added
      - Allow "DB" backend


## 0.0.7 2020-06-20 <dave at tiredofit dot ca>

   ### Added
      - Support tiredofit/fusiondirectory-plugin-kopano plugin with hardcoded LDAP attributes (LDAP_TYPE=FUSIONDIRECTORY)


## 0.0.6 2020-06-12 <dave at tiredofit dot ca>

   ### Changed
      - Shuffle around some environment variables for Webapp Plugins


## 0.0.5 2020-06-11 <dave at tiredofit dot ca>

   ### Added
      - Finish off DAgent Configuration
      - Finish off Gateway Configuration
      - Don't create log files if not set to do so
      - Support StartTLS for LDAP
      - Cleanup Dockerfile
      - Misc fixes


## 0.0.4 2020-06-10 <dave at tiredofit dot ca>

   ### Added
      - Allow GRAPI, KAPI, KWMServer, Konnect to Log to File


## 0.0.3 2020-06-10 <dave at tiredofit dot ca>

   ### Added
      - Added checks to hold on starting services until sockets are ready

   ### Changed
      - Removed Backticks in scripting instead using $()


## 0.0.2 2020-06-10 <dave at tiredofit dot ca>

   ### Changed
      - Load all defaults and functions instead of just Kopano for things like nginx / php setup / tweaks


## 0.0.1 2020-05-20 <dave at tiredofit dot ca>

   ### Added
      - Initial Commit


