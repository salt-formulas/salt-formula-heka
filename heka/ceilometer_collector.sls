{%- if pillar.heka.ceilometer_collector is defined %}

include:
- heka._common

{%- from "heka/map.jinja" import ceilometer_collector with context %}
{%- set server = ceilometer_collector %}
{%- set service_name = "ceilometer_collector" %}

{%- include "heka/_service.sls" %}

{%- endif %}
