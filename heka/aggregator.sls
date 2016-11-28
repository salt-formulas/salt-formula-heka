{%- if pillar.heka.aggregator is defined %}

include:
- heka._common

{%- from "heka/map.jinja" import aggregator with context %}
{%- set server = aggregator %}
{%- set service_name = "aggregator" %}

{%- include "heka/_service.sls" %}

{%- endif %}
