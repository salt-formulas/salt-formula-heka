{%- from "heka/map.jinja" import server with context %}

heka_packages:
  pkg.latest:
  - names: {{ server.pkgs }}

/usr/share/lma_collector:
  file.recurse:
  - source: salt://heka/files/lua

heka_user:
  user.present:
  - name: heka
  - system: true
  - shell: /bin/nologin
  - groups: {{ server.groups }}
  - require:
    - pkg: heka_packages

heka_acl_log:
  cmd.run:
  - name: "setfacl -R -m g:adm:rx /var/log; setfacl -R -d -m g:adm:rx /var/log"
  - unless: "getfacl /var/log/|grep default:group:adm"

heka_service:
  service.dead:
  - name: heka

