
============
Heka Formula
============

Heka is an open source stream processing software system developed by Mozilla. Heka is a Swiss Army Knife type tool for data processing

Sample pillars
==============

.. code-block:: yaml

    heka:
      router:
        enabled: true
        bind:
          address: 0.0.0.0
          port: 4352
        output:
          elasticsearch01:
            engine: elasticsearch
            host: localhost
            port: 9200
        input:
          rabbitmq:
            engine: amqp
            host: localhost
            user: guest
            password: guest


Read more
=========

* https://hekad.readthedocs.org/en/latest/index.html