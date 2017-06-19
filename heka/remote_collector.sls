{%- if pillar.heka.remote_collector is defined %}

{%- from "heka/map.jinja" import remote_collector with context %}
{%- set service_name = "remote_collector" %}
{%- set server = remote_collector %}

{%- if remote_collector.container_mode %}
{%- include "heka/_container.sls" %}
{%- else %}
include:
- heka._common
{%- endif %}

{%- include "heka/_service.sls" %}

{%- endif %}
