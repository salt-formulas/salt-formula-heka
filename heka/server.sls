{%- from "heka/map.jinja" import server with context %}
{%- if server.enabled %}

heka_packages:
  pkg.installed:
  - names: {{ server.pkgs }}

/etc/heka/conf.d/00-hekad.toml:
  file.managed:
  - source: salt://heka/files/00-hekad.toml
  - template: jinja
  - mode: 640
  - require:
    - pkg: heka_packages

heka_service:
  service.running:
  - enable: true
  - name: heka
  {#{ server.service }#}

heka_user:
  user.present:
  - name: heka
  - shell: /bin/false
  - groups: {{ server.groups }}
  - require:
    - pkg: heka_packages

{%- for name,values in server.input.iteritems() %}

/etc/heka/conf.d/10-input-{{ name }}-{{ values['engine'] }}.toml:
  file.managed:
  - source: salt://heka/files/input/{{ values['engine'] }}.toml
  - template: jinja
  - mode: 640
  - require:
    - file: /etc/heka/conf.d/00-hekad.toml
  - defaults:
      name: {{ name }}

{%- endfor %}

{%- endif %}

