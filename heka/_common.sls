{%- from "heka/map.jinja" import server with context %}

heka_packages:
  pkg.latest:
  - names: {{ server.pkgs }}

/usr/share/lma_collector:
  file.recurse:
  - source: salt://heka/files/lua
  - user: root
  - group: heka
  - file_mode: 640
  - dir_mode: 750
  - require:
    - user: heka_user

/usr/share/lma_collector/common/extra_fields.lua:
  file.managed:
  - source: salt://heka/files/extra_fields.lua
  - user: root
  - group: heka
  - mode: 640
  - defaults:
      extra_fields: {{ server.extra_fields }}
  - template: jinja
  - require:
    - user: heka_user

/usr/local/bin/monitor_heka_queues.sh:
  file.managed:
  - source: salt://heka/files/monitor_heka_queues.sh
  - mode: 755

heka_user:
  user.present:
  - name: heka
  - system: true
  - shell: /bin/false
  - groups: {{ server.groups }}
  - require:
    - pkg: heka_packages

heka_acl_log_dirs:
  cmd.run:
  - name: "find /var/log -type d -exec setfacl -m g:adm:rx '{}' \\; -exec setfacl -d -m g:adm:rx '{}' \\;"

heka_acl_log:
  cmd.run:
  - name: "find /var/log -type f -exec setfacl -m g:adm:r '{}' \\;"

hekad_process:
  process.absent:
  - name: 'hekad -config=/etc/heka'

/etc/init.d/heka:
  file.absent
