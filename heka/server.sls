{%- from "heka/map.jinja" import server with context %}
{%- if server.enabled %}

heka_packages:
  pkg.installed:
  - names: {{ server.pkgs }}

/etc/heka/conf.d/00-hekad.toml:
  file.managed:
  - source: salt://heka/files/00-hekad.toml
  - template: jinja
  - mode: 755
  - require:
    - pkg: heka_packages
  - watch_in:
    - service: heka_service

heka_service:
  service.running:
  - enable: true
  - name: {{ server.service }}

heka_user:
  user.present:
  - name: heka
  - shell: /bin/false
  - groups: {{ server.groups }}
  - require:
    - pkg: heka_packages

{#%- for name,engine in server.input.iteritems() %}

/etc/heka/conf.d/10-input-{{ name }}.toml:
  file.managed:
  - source: salt://heka/files/input/{{ engine }}.toml
  - template: jinja
  - mode: 755
  - require:
    - file: /etc/heka/conf.d/00-hekad.toml 

{%- endfor %#}                                                                                                                                                                                          
{%- endif %}

