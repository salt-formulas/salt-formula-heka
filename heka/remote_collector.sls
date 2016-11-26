{%- if pillar.heka.remote_collector is defined %}

include:
- heka._common

{%- from "heka/map.jinja" import remote_collector with context %}
{%- set server = remote_collector %}
{%- set service_name = "remote_collector" %}

{%- include "heka/_service.sls" %}

{%- endif %}
