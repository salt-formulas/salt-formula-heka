{%- from "heka/map.jinja" import router with context %}
{%- if router.enabled %}

heka_packages:
  pkg.installed:
  - names: {{ heka.pkgs }}

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
  - name: {{ router.service }}

{%- endif %}