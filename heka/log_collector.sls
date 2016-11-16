{%- if pillar.heka.log_collector is defined %}

include:
- heka._common

{%- from "heka/map.jinja" import log_collector with context %}
{%- set server = log_collector %}
{%- set service_name = "log_collector" %}

{%- include "heka/_service.sls" %}

{%- endif %}
