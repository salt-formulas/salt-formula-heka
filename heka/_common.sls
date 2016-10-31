{%- from "heka/map.jinja" import server with context %}

heka_packages:
  pkg.latest:
  - names: {{ server.pkgs }}

/usr/share/lma_collector:
  file.recurse:
  - source: salt://heka/files/lua

/usr/share/lma_collector/common/extra_fields.lua:
  file.managed:
  - source: salt://heka/files/extra_fields.lua
  - user: root
  - mode: 644
  - defaults:
      extra_fields: {{ server.extra_fields }}
  - template: jinja

heka_user:
  user.present:
  - name: heka
  - system: true
  - shell: /bin/false
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

heka_grains_dir:
  file.directory:
  - name: /etc/salt/grains.d
  - mode: 700
  - makedirs: true
  - user: root
