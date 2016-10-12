{%- macro service_config(service_name) %}

{%- set server = salt['pillar.get']('heka:'+service_name) %}

{%- if server.enabled %}

heka_{{ service_name }}_log_file:
  file.managed:
  - name: /var/log/{{ service_name }}.log
  - user: heka
  - mode: 750
  - replace: False

heka_{{ service_name }}_conf_dir:
  file.directory:
  - name: /etc/{{ service_name }}
  - user: root
  - mode: 750
  - makedirs: true

heka_{{ service_name }}_conf_dir_clean:
  file.directory:
  - name: /etc/{{ service_name }}
  - clean: true

{%- if grains.get('init', None) == 'systemd' %}

heka_{{ service_name }}_service_file:
  file.managed:
  - name: /etc/init/{{ service_name }}.conf
  - user: root
  - mode: 644
  - template: jinja

{%- else %}

heka_{{ service_name }}_service_file:
  file.managed:
  - name: /etc/init/{{ service_name }}.conf
  - user: root
  - mode: 644
  - template: jinja

heka_{{ service_name }}_service_wrapper:
  file.managed:
  - name: /usr/local/bin/{{ service_name }}.log
  - user: root
  - mode: 755
  - template: jinja

{%- endif %}

/etc/{{ service_name }}/global.toml:
  file.managed:
  - source: salt://heka/files/toml/global.toml
  - template: jinja
  - mode: 640
  - group: heka
  - defaults:
    service_name: {{ service_name }}
  - require:
    - file: heka_{{ service_name }}_conf_dir
  - require_in:
    - file: heka_{{ service_name }}_conf_dir_clean
  - watch_in:
    - service: heka_{{ service_name }}_service

{%- for decoder_name, decoder in server.decoder.iteritems() %}

/etc/{{ service_name }}/10-decoder-{{ decoder_name }}-{{ decoder.engine }}.toml:
  file.managed:
  - source: salt://heka/files/toml/decoder/{{ decoder.engine }}.toml
  - template: jinja
  - mode: 640
  - group: heka
  - require:
    - file: heka_{{ service_name }}_conf_dir
  - require_in:
    - file: heka_{{ service_name }}_conf_dir_clean
  - watch_in:
    - service: heka_{{ service_name }}_service
  - defaults:
      decoder_name: {{ decoder_name }}
      decoder: {{ decoder|yaml }}

{%- endfor %}

{%- for input_name, input in server.input.iteritems() %}

/etc/{{ service_name }}/15-input-{{ input_name }}-{{ input.engine }}.toml:
  file.managed:
  - source: salt://heka/files/toml/input/{{ input.engine }}.toml
  - template: jinja
  - mode: 640
  - group: heka
  - require:
    - file: heka_{{ service_name }}_conf_dir
  - require_in:
    - file: heka_{{ service_name }}_conf_dir_clean
  - watch_in:
    - service: heka_{{ service_name }}_service
  - defaults:
      input_name: {{ input_name }}
      input: {{ input|yaml }}

{%- endfor %}

{%- for filter_name, filter in server.filter.iteritems() %}

/etc/{{ service_name }}/20-filter-{{ filter_name }}-{{ filter.engine }}.toml:
  file.managed:
  - source: salt://heka/files/toml/filter/{{ filter.engine }}.toml
  - template: jinja
  - mode: 640
  - group: heka
  - require:
    - file: heka_{{ service_name }}_conf_dir
  - require_in:
    - file: heka_{{ service_name }}_conf_dir_clean
  - watch_in:
    - service: heka_{{ service_name }}_service
  - defaults:
      filter_name: {{ filter_name }}
      filter: {{ filter|yaml }}

{%- endfor %}

{%- for splitter_name, splitter in server.splitter.iteritems() %}

/etc/{{ service_name }}/30-splitter-{{ splitter_name }}-{{ splitter.engine }}.toml:
  file.managed:
  - source: salt://heka/files/toml/splitter/{{ splitter.engine }}.toml
  - template: jinja
  - mode: 640
  - group: heka
  - require:
    - file: heka_{{ service_name }}_conf_dir
  - require_in:
    - file: heka_{{ service_name }}_conf_dir_clean
  - watch_in:
    - service: heka_{{ service_name }}_service
  - defaults:
      splitter_name: {{ splitter_name }}
      splitter: {{ splitter|yaml }}

{%- endfor %}

{%- for encoder_name, encoder in server.encoder.iteritems() %}

/etc/{{ service_name }}/40-encoder-{{ encoder_name }}-{{ encoder.engine }}.toml:
  file.managed:
  - source: salt://heka/files/toml/encoder/{{ encoder.engine }}.toml
  - template: jinja
  - mode: 640
  - group: heka
  - require:
    - file: heka_{{ service_name }}_conf_dir
  - require_in:
    - file: heka_{{ service_name }}_conf_dir_clean
  - watch_in:
    - service: heka_{{ service_name }}_service
  - defaults:
      encoder_name: {{ encoder_name }}
      encoder: {{ encoder|yaml }}

{%- endfor %}

{%- for output_name, output in server.output.iteritems() %}

/etc/{{ service_name }}/60-output-{{ output_name }}-{{ output.engine }}.toml:
  file.managed:
  - source: salt://heka/files/toml/output/{{ output.engine }}.toml
  - template: jinja
  - mode: 640
  - group: heka
  - require:
    - file: heka_{{ service_name }}_conf_dir
  - require_in:
    - file: heka_{{ service_name }}_conf_dir_clean
  - watch_in:
    - service: heka_{{ service_name }}_service
  - defaults:
      output_name: {{ output_name }}
      output: {{ output|yaml }}

{%- endfor %}

{%- for service_name, service in pillar.items() %}
{%- if service.get('_support', {}).get('heka', {}).get('enabled', False) %}

/etc/{{ service_name }}/99-{{ service_name }}.toml:
  file.managed:
  - source: salt://{{ service_name }}/files/heka.toml
  - template: jinja
  - mode: 640
  - group: heka
  - require:
    - file: heka_{{ service_name }}_conf_dir
  - require_in:
    - file: heka_{{ service_name }}_conf_dir_clean
  - watch_in:
    - service: heka_{{ service_name }}_service

{%- endif %}
{%- endfor %}

{%- endif %}

{%- endmacro %}
