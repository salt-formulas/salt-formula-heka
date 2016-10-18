
{%- set server = salt['pillar.get']('heka:'+service_name) %}

{%- if server.enabled %}

heka_{{ service_name }}_log_file:
  file.managed:
  - name: /var/log/{{ service_name }}.log
  - user: heka
  - mode: 644
  - replace: False

heka_{{ service_name }}_conf_dir:
  file.directory:
  - name: /etc/{{ service_name }}
  - user: heka
  - mode: 750
  - makedirs: true

heka_{{ service_name }}_conf_dir_clean:
  file.directory:
  - name: /etc/{{ service_name }}
  - clean: true

{%- if grains.get('init', None) == 'systemd' %}

heka_{{ service_name }}_service_file:
  file.managed:
  - name: /etc/systemd/system/{{ service_name }}.service
  - source: salt://heka/files/heka.service
  - user: root
  - mode: 644
  - template: jinja

{%- else %}

heka_{{ service_name }}_service_file:
  file.managed:
  - name: /etc/init/{{ service_name }}.conf
  - source: salt://heka/files/heka.service
  - user: root
  - mode: 644
  - defaults:
    service_name: {{ service_name }}
  - template: jinja

heka_{{ service_name }}_service_wrapper:
  file.managed:
  - name: /usr/local/bin/{{ service_name }}
  - source: salt://heka/files/service_wrapper
  - user: root
  - mode: 755
  - defaults:
    service_name: {{ service_name }}
  - template: jinja

{%- endif %}

heka_{{ service_name }}_service:
  service.running:
  - name: {{ service_name }}
  - enable: True

{# Setup basic structure for all roles so updates can apply #}

{%- set service_grains = {
  'log_collector': {
    'decoder': {},
    'input': {},
    'filter': {},
    'splitter': {},
    'encoder': {},
    'output': {}
  },
  'metric_collector': {
    'decoder': {},
    'input': {},
    'filter': {},
    'splitter': {},
    'encoder': {},
    'output': {}
  },
  'remote_collector': {
    'decoder': {},
    'input': {},
    'filter': {},
    'splitter': {},
    'encoder': {},
    'output': {}
  },
  'aggregator': {
    'decoder': {},
    'input': {},
    'filter': {},
    'splitter': {},
    'encoder': {},
    'output': {}
  }
} %}



{# Loading the other services' support metadata for local roles #}

{%- if service_name in ['log_collector', 'metric_collector'] %}

{%- for service_name, service in pillar.iteritems() %}
{%- if service.get('_support', {}).get('heka', {}).get('enabled', False) %}

{%- macro load_grains_file(grains_fragment_file) %}{% include grains_fragment_file %}{% endmacro %}

{%- set grains_fragment_file = service_name+'/meta/heka.yml' %}
{%- set grains_yaml = load_grains_file(grains_fragment_file)|load_yaml %}
{%- set service_grains = salt['grains.filter_by']({'default': service_grains}, merge=grains_yaml) %}

{%- endif %}
{%- endfor %}

{%- endif %}


{# Loading the other services' support metadata from salt-mine #}

{%- if service_name in ['remote_collector', 'aggregator'] %}

{%- for node_name, node_grains in salt['mine.get']('*', 'grains.items').iteritems() %}
{%- if node_grains.heka is defined %}

{%- do service_grains.update(node_grains.heka) %}

{%- endif %}
{%- endfor %}

{%- endif %}


{# Overriding aggregated metadata from user-space pillar data #}

{%- for service_grain_name, service_grain in service_grains.iteritems() %}
{% if salt['pillar.get']('heka:'+service_grain_name) %}

{%- for service_action_name, service_action in service_grain.iteritems() %}
{%- if salt['pillar.get']('heka:'+service_grain_name).get(service_action_name, False) is mapping %}
{%- set grain_action_meta = salt['pillar.get']('heka:'+service_grain_name+':'+service_action_name) %}
{#
{%- set service_grains.get(service_grain_name).get(service_action_name) = salt['grains.filter_by']({'default': service_grains}, merge=grain_action_meta) %}
#}
{%- endif %}
{%- endfor %}



{%- endif %}
{%- endfor %}


heka_{{ service_name }}_grain:
  file.managed:
  - name: /etc/salt/grains.d/heka
  - source: salt://heka/files/heka.grain
  - template: jinja
  - user: root
  - mode: 600
  - defaults:
    service_grains:
      heka: {{ service_grains|yaml }}
  - require:
    - file: heka_grains_dir

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

{%- set service_metadata = service_grains.get(service_name) %}

{%- for decoder_name, decoder in service_metadata.get('decoder', {}).iteritems() %}

/etc/{{ service_name }}/decoder_{{ decoder_name }}.toml:
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

{%- for input_name, input in service_metadata.get('input', {}).iteritems() %}

/etc/{{ service_name }}/input_{{ input_name }}.toml:
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

{%- for filter_name, filter in service_metadata.get('filter', {}).iteritems() %}

/etc/{{ service_name }}/filter_{{ filter_name }}.toml:
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

{%- for splitter_name, splitter in service_metadata.get('splitter', {}).iteritems() %}

/etc/{{ service_name }}/splitter_{{ splitter_name }}.toml:
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

{%- for encoder_name, encoder in service_metadata.get('encoder', {}).iteritems() %}

/etc/{{ service_name }}/encoder_{{ encoder_name }}.toml:
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

{%- for output_name, output in service_metadata.get('output', {}).iteritems() %}

/etc/{{ service_name }}/output_{{ output_name }}.toml:
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

{%- endif %}
