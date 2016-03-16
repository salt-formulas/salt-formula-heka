{%- from "heka/map.jinja" import server with context %}
{%- if server.enabled %}

heka_packages:
  pkg.latest:
  - names: {{ server.pkgs }}

purge-heka-conf-dir:
  file.directory:
  - name: /etc/heka/conf.d/
  - clean: True
  - makedirs: True
  - require:
    - pkg: heka_packages

/etc/heka/conf.d/00-hekad.toml:
  file.managed:
  - source: salt://heka/files/00-hekad.toml
  - template: jinja
  - mode: 640
  - group: heka
  - require:
    - pkg: heka_packages
    - file: purge-heka-conf-dir
    - user: heka_user

{%- if grains.os_family == 'RedHat' %}
/usr/lib/systemd/system/heka.service:
  file.managed:
  - source: salt://heka/files/heka.service
  - require:
    - file: /etc/heka/conf.d/00-hekad.toml

/var/cache/hekad:
  file.directory:
  - user: heka
  - require:
    - user: heka_user

{%- endif %}

heka_service:
  service.running:
  - enable: true
  - name: heka
  - watch:
    - file: /etc/heka/conf.d/00-hekad.toml
  - require:
    - user: heka_user

heka_user:
  user.present:
  - name: heka
  - shell: /bin/nologin
  - groups: {{ server.groups }}
  - require:
    - pkg: heka_packages

{%- for name,values in server.input.iteritems() %}

/etc/heka/conf.d/15-input-{{ name }}-{{ values['engine'] }}.toml:
  file.managed:
  - source: salt://heka/files/input/{{ values['engine'] }}.toml
  - template: jinja
  - mode: 640
  - group: heka
  - require:
    - file: /etc/heka/conf.d/00-hekad.toml
  - watch_in:
    - service: heka_service
  - defaults:
      name: {{ name }}
      values: {{ values }}

{%- endfor %}

{%- for name,values in server.output.iteritems() %}
{%- if values.enabled %}
/etc/heka/conf.d/60-output-{{ name }}-{{ values['engine'] }}.toml:
  file.managed:
  - source: salt://heka/files/output/{{ values['engine'] }}.toml
  - template: jinja
  - mode: 640
  - group: heka
  - require:
    - file: /etc/heka/conf.d/00-hekad.toml
  - watch_in:
    - service: heka_service
  - defaults:
      name: {{ name }}
      values: {{ values }}

{%- endif %}
{%- endfor %}


{%- for name,values in server.filter.iteritems() %}

/etc/heka/conf.d/20-filter-{{ name }}-{{ values['engine'] }}.toml:
  file.managed:
  - source: salt://heka/files/filter/{{ values['engine'] }}.toml
  - template: jinja
  - mode: 640
  - group: heka
  - require:
    - file: /etc/heka/conf.d/00-hekad.toml
  - watch_in:
    - service: heka_service
  - defaults:
      name: {{ name }}
      values: {{ values }}

{%- endfor %}

{%- for name,values in server.splitter.iteritems() %}

/etc/heka/conf.d/30-splitter-{{ name }}-{{ values['engine'] }}.toml:
  file.managed:
  - source: salt://heka/files/splitter/{{ values['engine'] }}.toml
  - template: jinja
  - mode: 640
  - group: heka
  - require:
    - file: /etc/heka/conf.d/00-hekad.toml
  - watch_in:
    - service: heka_service
  - defaults:
      name: {{ name }}
      values: {{ values }}

{%- endfor %}

{%- for name,values in server.encoder.iteritems() %}

/etc/heka/conf.d/40-encoder-{{ name }}-{{ values['engine'] }}.toml:
  file.managed:
  - source: salt://heka/files/encoder/{{ values['engine'] }}.toml
  - template: jinja
  - mode: 640
  - group: heka
  - require:
    - file: /etc/heka/conf.d/00-hekad.toml
  - watch_in:
    - service: heka_service
  - defaults:
      name: {{ name }}
      values: {{ values }}

{%- endfor %}

{%- for name,values in server.decoder.iteritems() %}

/etc/heka/conf.d/10-decoder-{{ name }}-{{ values['engine'] }}.toml:
  file.managed:
  - source: salt://heka/files/decoder/{{ values['engine'] }}.toml
  - template: jinja
  - mode: 640
  - group: heka
  - require:
    - file: /etc/heka/conf.d/00-hekad.toml
  - watch_in:
        - service: heka_service
  - defaults:
      name: {{ name }}
      values: {{ values }}

{%- endfor %}

{%- for service_name, service in pillar.items() %}
{%- for role_name, role in service.iteritems() %}
{%- if role.logging is defined and role.logging.heka is defined %}
{%- if role.logging.heka.get('enabled', False) %}

/etc/heka/conf.d/99-{{ service_name }}-{{ role_name }}.toml:
  file.managed:
  - source: salt://{{ service_name }}/files/heka.toml
  - template: jinja
  - mode: 640
  - group: heka
  - require:
    - file: /etc/heka/conf.d/00-hekad.toml
  - watch_in:
    - service: heka_service

{%- endif %}
{%- endif %}
{%- endfor %}
{%- endfor %}

{%- endif %}
