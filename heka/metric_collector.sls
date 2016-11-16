{%- if pillar.heka.metric_collector is defined %}

include:
- heka._common

{%- from "heka/map.jinja" import metric_collector with context %}
{%- set server = metric_collector %}
{%- set service_name = "metric_collector" %}

{%- include "heka/_service.sls" %}

{%- endif %}
