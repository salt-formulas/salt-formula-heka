
============
Heka Formula
============

Heka is an open source stream processing software system developed by Mozilla. Heka is a Swiss Army Knife type tool for data processing.

Sample pillars
==============

Log collector service

.. code-block:: yaml

    heka:
      log_collector:
        automatic_starting: true
        elasticsearch_host: 172.16.10.253
        elasticsearch_port: 9200
        enabled: true
        metric_collector_host: 127.0.0.1
        metric_collector_port: 5567
        poolsize: 100

Default values:

* ``automatic_starting: true``
* ``elastisearch_port: 9200``
* ``enabled: false``
* ``metric_collector_host: 127.0.0.1``
* ``metric_collector_port: 5567``
* ``poolsize: 100``

Local Metric collector service

.. code-block:: yaml

    heka:
      metric_collector:
        aggregator_host: 172.16.20.253
        aggregator_port: 5565
        automatic_starting: true
        enabled: true
        influxdb_database: lma
        influxdb_host: 172.16.10.101
        influxdb_password: lmapass
        influxdb_port: 8086
        influxdb_time_precision: ms
        influxdb_timeout: 500
        influxdb_username: lma
        nagios_host: 172.16.20.253
        nagios_host_dimension_key: nagios_host
        nagios_password: secret
        nagios_port: 5601
        nagios_username: nagiosadmin
        poolsize: 100

Default values:

* ``aggregator_port: 5565``
* ``automatic_starting: true``
* ``enabled: false``
* ``influxdb_port: 8086``
* ``influxdb_time_precision: ms``
* ``influxdb_timeout: 5000``
* ``nagios_port: 8001``
* ``poolsize: 100``

Remote Metric Collector service

.. code-block:: yaml

    heka:
      remote_collector:
        aggregator_host: 172.16.20.253
        aggregator_port: 5565
        amqp_exchange: nova
        amqp_host: 172.16.10.254
        amqp_password: workshop
        amqp_port: 5672
        amqp_user: openstack
        amqp_vhost: /openstack
        automatic_starting: false
        elasticsearch_host: 172.16.10.253
        elasticsearch_port: 9200
        enabled: true
        influxdb_database: lma
        influxdb_host: 172.16.10.101
        influxdb_password: lmapass
        influxdb_port: 8086
        influxdb_time_precision: ms
        influxdb_username: lma
        poolsize: 100

Default values:

* ``aggregator_port: 5565``
* ``amqp_exchange: nova``
* ``automatic_starting: true``
* ``elastisearch_port: 9200``
* ``enabled: false``
* ``influxdb_port: 8086``
* ``influxdb_time_precision: ms``
* ``influxdb_timeout: 5000``
* ``poolsize: 100``

Aggregator service

.. code-block:: yaml

    heka:
      aggregator:
        automatic_starting: false
        enabled: true
        influxdb_database: lma
        influxdb_host: 172.16.10.101
        influxdb_password: lmapass
        influxdb_port: 8086
        influxdb_time_precision: ms
        influxdb_username: lma
        nagios_default_host_alarm_clusters: 00-clusters
        nagios_host: 172.16.20.253
        nagios_host_dimension_key: nagios_host
        nagios_password: secret
        nagios_port: 5601
        nagios_username: nagiosadmin
        poolsize: 100

Default values:

* ``automatic_starting: true``
* ``enabled: false``
* ``influxdb_port: 8086``
* ``influxdb_time_precision: ms``
* ``influxdb_timeout: 5000``
* ``nagios_port: 8001``
* ``nagios_default_host_alarm_clusters: 00-clusters``
* ``poolsize: 100``

Ceilometer service

.. code-block:: yaml

    heka:
      ceilometer_collector:
        elasticsearch_host: 172.16.10.253
        elasticsearch_port: 9200
        enabled: true
        influxdb_database: lma
        influxdb_host: 172.16.10.101
        influxdb_password: lmapass
        influxdb_port: 8086
        influxdb_time_precision: ms
        influxdb_username: lma
        resource_decoding: false
        rabbit_host: 172.16.10.253
        rabbit_port: 5672
        rabbit_queue: metering.sample
        rabbit_vhost: /openstack

Default values:

* ``elastisearch_port: 9200``
* ``enabled: false``
* ``influxdb_port: 8086``
* ``influxdb_time_precision: ms``
* ``influxdb_timeout: 5000``
* ``rabbit_port: 5672``
* ``rabbit_vhost: /openstack``
* ``rabbit_queue: metering.sample``
* ``resource_decoding: false``

Read more
=========

* https://hekad.readthedocs.org/en/latest/index.html
