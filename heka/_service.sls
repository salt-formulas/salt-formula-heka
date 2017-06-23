{%- if server.enabled is defined and server.enabled %}

heka_{{ service_name }}_conf_dir:
  file.directory:
  - name: {{ server.prefix_dir }}/etc/{{ service_name }}
  - user: heka
  - mode: 750
  - makedirs: true

{%- if not server.container_mode %}
heka_{{ service_name }}_cache_dir:
  file.directory:
  - name: /var/cache/{{ service_name }}
  - user: heka
  - group: heka
  - mode: 750
  - makedirs: true
{% endif %}

heka_{{ service_name }}_conf_dir_clean:
  file.directory:
  - name: {{ server.prefix_dir }}/etc/{{ service_name }}
  - clean: true
  - watch_in:
    - service: heka_{{ service_name }}_service

{%- if not server.container_mode %}

{%- if grains.get('init', None) == 'systemd' %}
{%- set systemd_enabled = True %}
{%- else %}
{%- set systemd_enabled = False %}
{%- endif %}

heka_{{ service_name }}_service_file:
  file.managed:
{%- if systemd_enabled %}
  - name: /etc/systemd/system/{{ service_name }}.service
{%- else %}
  - name: /etc/init/{{ service_name }}.conf
{%- endif %}
  - source: salt://heka/files/heka.service
  - user: root
  - mode: 644
  - defaults:
    service_name: {{ service_name }}
    systemd_enabled: {{ systemd_enabled|lower }}
    max_open_files: 102400
    automatic_starting: {{ server.automatic_starting }}
  - template: jinja

{%- if not systemd_enabled %}

heka_{{ service_name }}_log_file:
  file.managed:
  - name: /var/log/{{ service_name }}.log
  - user: heka
  - mode: 644
  - replace: false

/etc/logrotate.d/{{ service_name }}:
  file.managed:
  - source: salt://heka/files/heka_logrotate.conf
  - template: jinja
  - defaults:
    service_name: {{ service_name }}
  - user: root
  - group: root
  - mode: 644

heka_{{ service_name }}_service_wrapper:
  file.managed:
  - name: /usr/local/bin/{{ service_name }}_wrapper
  - source: salt://heka/files/service_wrapper
  - user: root
  - mode: 755
  - defaults:
    service_name: {{ service_name }}
  - template: jinja

{%- endif %}

heka_{{ service_name }}_service:
{%- if server.automatic_starting %}
  service.running:
  - enable: True
  - watch:
    - file: {{ server.prefix_dir }}/usr/share/lma_collector
    - file: {{ server.prefix_dir }}/usr/share/lma_collector/*
    - file: {{ server.prefix_dir }}/etc/{{ service_name }}/*
{%- else %}
  service.disabled:
{%- endif %}
  - name: {{ service_name }}

{%- else %}
{# Fake service state to satisfy the requisites #}
heka_{{ service_name }}_service:
  test.nop

{%- endif %}

{# Setup basic structure for all roles so updates can apply #}
{%- set service_grains = {
  'log_collector': {
    'decoder': {},
    'input': {},
    'trigger': {},
    'filter': {},
    'splitter': {},
    'encoder': {},
    'output': {},
  },
  'metric_collector': {
    'decoder': {},
    'input': {},
    'trigger': {},
    'alarm': {},
    'filter': {},
    'splitter': {},
    'encoder': {},
    'output': {},
  },
  'remote_collector': {
    'decoder': {},
    'input': {},
    'trigger': {},
    'alarm': {},
    'filter': {},
    'splitter': {},
    'encoder': {},
    'output': {},
  },
  'aggregator': {
    'decoder': {},
    'input': {},
    'trigger': {},
    'alarm_cluster': {},
    'filter': {},
    'splitter': {},
    'encoder': {},
    'output': {},
  },
  'ceilometer_collector': {
    'decoder': {},
    'input': {},
    'filter': {},
    'splitter': {},
    'encoder': {},
    'output': {},
  }
} %}

{%- if service_name in ('remote_collector', 'aggregator') %}

{# Load the other services' support metadata from salt-mine #}

{%- for node_name, node_grains in salt['mine.get']('*', 'grains.items').iteritems() %}
{%- if node_grains.heka is defined %}
{% for service, data in node_grains.heka.items() %}
  {%- if service in ('remote_collector', 'aggregator') %}
    {%- do salt['grains.filter_by']({'default': service_grains[service]}, merge=data) %}
  {%- endif %}
{% endfor %}
{% endif %}
{%- endfor %}

{%- endif %}

{# Overriding aggregated metadata from user-space pillar data #}

{# Loading the other services' support metadata for local roles #}
{%- macro load_support_file(support_fragment_file) %}{% include support_fragment_file ignore missing %}{% endmacro %}
{%- for svc_name, svc in pillar.iteritems() %}
  {%- if svc.get('_support', {}).get('heka', {}).get('enabled', False) %}
    {%- set heka_fragment_file = svc_name+'/meta/heka.yml' %}
    {%- set heka_yaml = load_support_file(heka_fragment_file)|load_yaml %}
    {%- set service_grains = salt['grains.filter_by']({'default': service_grains}, merge=heka_yaml) %}
  {%- endif %}
{%- endfor %}

{%- if service_name in ('remote_collector', 'aggregator') %}

{# Load the other services' support metadata from salt-mine #}

{%- for node_name, node_grains in salt['mine.get']('*', 'grains.items').iteritems() %}
{%- if node_grains.heka is defined %}
{% for service, data in node_grains.heka.items() %}
  {%- if service in ('remote_collector', 'aggregator') %}
    {%- do salt['grains.filter_by']({'default': service_grains[service]}, merge=data) %}
  {%- endif %}
{% endfor %}
{% endif %}
{%- endfor %}

{%- endif %}

{# Overriding aggregated metadata from user-space pillar data #}
{%- for service_grain_name, service_grain in service_grains.iteritems() %}
{% if salt['pillar.get']('heka:'+service_grain_name) %}

{%- for service_action_name, service_action in service_grain.iteritems() %}
{%- if salt['pillar.get']('heka:'+service_grain_name).get(service_action_name, None) is mapping %}

{%- set grain_action_meta = salt['pillar.get']('heka:'+service_grain_name+':'+service_action_name) %}
{%- do service_grains.get(service_grain_name).get(service_action_name).update(grain_action_meta) %}

{%- endif %}
{%- endfor %}

{%- endif %}
{%- endfor %}

{{ server.prefix_dir }}/etc/{{ service_name }}/global.toml:
  file.managed:
  - source: salt://heka/files/toml/global.toml
  - template: jinja
  - mode: 640
  - group: heka
  - defaults:
    service_name: {{ service_name }}
    poolsize: {{ server.poolsize }}
  - require:
    - file: heka_{{ service_name }}_conf_dir
  - require_in:
    - file: heka_{{ service_name }}_conf_dir_clean

{%- set service_metadata = service_grains.get(service_name) %}

{%- for decoder_name, decoder in service_metadata.get('decoder', {}).iteritems() %}

{{ server.prefix_dir }}/etc/{{ service_name }}/decoder_{{ decoder_name }}.toml:
  file.managed:
  - source: salt://heka/files/toml/decoder/{{ decoder.engine }}.toml
  - template: jinja
  - mode: 640
  - group: heka
  - require:
    - file: heka_{{ service_name }}_conf_dir
  - require_in:
    - file: heka_{{ service_name }}_conf_dir_clean
  - defaults:
      decoder_name: {{ decoder_name }}
      decoder: {{ decoder|yaml }}

{%- endfor %}

{%- for input_name, input in service_metadata.get('input', {}).iteritems() %}

{{ server.prefix_dir }}/etc/{{ service_name }}/input_{{ input_name }}.toml:
  file.managed:
  - source: salt://heka/files/toml/input/{{ input.engine }}.toml
  - template: jinja
  - mode: 640
  - group: heka
  - require:
    - file: heka_{{ service_name }}_conf_dir
  - require_in:
    - file: heka_{{ service_name }}_conf_dir_clean
  - defaults:
      input_name: {{ input_name }}
      input: {{ input|yaml }}

{%- endfor %}

{%- if server.alarms_enabled %}
{%- for alarm_name, alarm in service_metadata.get('alarm', {}).iteritems() %}

{%- if alarm.get('enabled', True) %}
{{ server.prefix_dir }}/etc/{{ service_name }}/filter_afd_{{ alarm_name }}.toml:
  file.managed:
  - source: salt://heka/files/toml/filter/afd_alarm.toml
  - template: jinja
  - mode: 640
  - group: heka
  - require:
    - file: heka_{{ service_name }}_conf_dir
  - require_in:
    - file: heka_{{ service_name }}_conf_dir_clean
  - defaults:
      alarm_name: {{ alarm_name }}
      alarm: {{ alarm|yaml }}
      trigger: {{ service_metadata.get('trigger', {})|yaml }}
      {%- if service_name != 'remote_collector' %}
      hostname: {{ grains.host }}
      {%- endif %}

{{ server.prefix_dir }}/usr/share/lma_collector/common/lma_{{ alarm_name|replace('-', '_') }}.lua:
  file.managed:
  - source: salt://heka/files/lma_alarm.lua
  - template: jinja
  - mode: 640
  - group: heka
  - require:
    - file: {{ server.prefix_dir }}/usr/share/lma_collector
  - defaults:
      alarm_name: {{ alarm_name }}
      alarm: {{ alarm|yaml }}
      trigger: {{ service_metadata.get('trigger', {})|yaml }}
{%- endif %}

{%- endfor %}
{%- endif %}

{%- set policy = service_metadata.get('policy') %}
{%- if policy %}
{{ server.prefix_dir }}/usr/share/lma_collector/common/gse_policies.lua:
  file.managed:
  - source: salt://heka/files/gse_policies.lua
  - template: jinja
  - mode: 640
  - group: heka
  - require:
    - file: {{ server.prefix_dir }}/usr/share/lma_collector
  - defaults:
    policy: {{ policy|yaml }}
{%- endif %}

{%- for alarm_cluster_name, alarm_cluster in service_metadata.get('alarm_cluster', {}).iteritems() %}

{%- if alarm_cluster.get('enabled', True) %}
{{ server.prefix_dir }}/etc/{{ service_name }}/filter_gse_{{ alarm_cluster_name }}.toml:
  file.managed:
  - source: salt://heka/files/toml/filter/gse_alarm_cluster.toml
  - template: jinja
  - mode: 640
  - group: heka
  - require:
    - file: heka_{{ service_name }}_conf_dir
  - require_in:
    - file: heka_{{ service_name }}_conf_dir_clean
  - defaults:
      alarm_cluster_name: {{ alarm_cluster_name }}
      alarm_cluster: {{ alarm_cluster|yaml }}

{{ server.prefix_dir }}/usr/share/lma_collector/common/gse_{{ alarm_cluster_name|replace('-', '_') }}_topology.lua:
  file.managed:
  - source: salt://heka/files/gse_topology.lua
  - template: jinja
  - mode: 640
  - group: heka
  - require:
    - file: {{ server.prefix_dir }}/usr/share/lma_collector
  - defaults:
      alarm_cluster_name: {{ alarm_cluster_name }}
      alarm_cluster: {{ alarm_cluster|yaml }}
{%- endif %}

{%- endfor %}

{%- for filter_name, filter in service_metadata.get('filter', {}).iteritems() %}

{{ server.prefix_dir }}/etc/{{ service_name }}/filter_{{ filter_name }}.toml:
  file.managed:
  - source: salt://heka/files/toml/filter/{{ filter.engine }}.toml
  - template: jinja
  - mode: 640
  - group: heka
  - require:
    - file: heka_{{ service_name }}_conf_dir
  - require_in:
    - file: heka_{{ service_name }}_conf_dir_clean
  - defaults:
      filter_name: {{ filter_name }}
      filter: {{ filter|yaml }}

{%- endfor %}

{%- for splitter_name, splitter in service_metadata.get('splitter', {}).iteritems() %}

{{ server.prefix_dir }}/etc/{{ service_name }}/splitter_{{ splitter_name }}.toml:
  file.managed:
  - source: salt://heka/files/toml/splitter/{{ splitter.engine }}.toml
  - template: jinja
  - mode: 640
  - group: heka
  - require:
    - file: heka_{{ service_name }}_conf_dir
  - require_in:
    - file: heka_{{ service_name }}_conf_dir_clean
  - defaults:
      splitter_name: {{ splitter_name }}
      splitter: {{ splitter|yaml }}

{%- endfor %}

{%- for encoder_name, encoder in service_metadata.get('encoder', {}).iteritems() %}

{{ server.prefix_dir }}/etc/{{ service_name }}/encoder_{{ encoder_name }}.toml:
  file.managed:
  - source: salt://heka/files/toml/encoder/{{ encoder.engine }}.toml
  - template: jinja
  - mode: 640
  - group: heka
  - require:
    - file: heka_{{ service_name }}_conf_dir
  - require_in:
    - file: heka_{{ service_name }}_conf_dir_clean
  - defaults:
      encoder_name: {{ encoder_name }}
      encoder: {{ encoder|yaml }}

{%- endfor %}

{%- for output_name, output in service_metadata.get('output', {}).iteritems() %}

{{ server.prefix_dir }}/etc/{{ service_name }}/output_{{ output_name }}.toml:
  file.managed:
  - source: salt://heka/files/toml/output/{{ output.engine }}.toml
  - template: jinja
  - mode: 640
  - group: heka
  - require:
    - file: heka_{{ service_name }}_conf_dir
  - require_in:
    - file: heka_{{ service_name }}_conf_dir_clean
  - defaults:
      output_name: {{ output_name }}
      output: {{ output|yaml }}

{%- endfor %}

{%- endif %}
