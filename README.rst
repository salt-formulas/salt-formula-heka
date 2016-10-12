
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
        enabled: true
        output:
          elasticsearch01:
            engine: elasticsearch
            host: localhost
            port: 9200
            encoder: es_json
            message_matcher: TRUE

Metric collector service

.. code-block:: yaml

    heka:
      metric_collector:
        enabled: true
        output:
          elasticsearch01:
            engine: elasticsearch
            host: localhost
            port: 9200
            encoder: es_json
            message_matcher: TRUE
          dashboard01:
            engine: dashboard
            ticker_interval: 30

Aggregator service

.. code-block:: yaml

    heka:
      aggregator:
        enabled: true
        output:
          elasticsearch01:
            engine: elasticsearch
            host: localhost
            port: 9200
            encoder: es_json
            message_matcher: TRUE
          dashboard01:
            engine: dashboard
            ticker_interval: 30


Read more
=========

* https://hekad.readthedocs.org/en/latest/index.html
