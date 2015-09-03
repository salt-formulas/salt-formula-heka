
include:
{% if pillar.heka.router is defined %}
- heka.router
{% endif %}
