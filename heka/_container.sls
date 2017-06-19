{%- from "heka/map.jinja" import server as root_server with context %}

{{ server.prefix_dir }}:
  file.directory:
  - mode: 750
  - makedirs: true

{{ server.prefix_dir }}/usr/share/lma_collector:
  file.recurse:
  - source: salt://heka/files/lua
  - file_mode: 640
  - dir_mode: 750
  - require:
    - file: {{ server.prefix_dir }}

{{ server.prefix_dir }}/usr/share/lma_collector/common/extra_fields.lua:
  file.managed:
  - source: salt://heka/files/extra_fields.lua
  - mode: 640
  - defaults:
      extra_fields: {{ root_server.extra_fields }}
  - template: jinja
  - require:
    - file: {{ server.prefix_dir }}/usr/share/lma_collector
