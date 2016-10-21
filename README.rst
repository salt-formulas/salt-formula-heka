
============
Heka Formula
============

Heka is an open source stream processing software system developed by Mozilla. Heka is a Swiss Army Knife type tool for data processing.

Sample pillars
==============

Metric collector service
------------------------

Local alarm definition for nova compute role, excerpt from `nova/meta/heka.yml`.

.. code-block:: yaml

    heka:
      metric_collector:
        trigger:
          nova_compute_filesystem_warning:
            engine: afd
            enabled: True  # implicit
            description: "The nova instance filesystem's root free space is low."
            severity: warning
            logical_operator: or # implicit
            rules:
            - metric: fs_space_percent_free
              relational_operator: '<'
              threshold: 10
              window: 60
              periods: 0
              function: min
              fs: '/var/lib/nova'
          nova_compute_filesystem_critical:
            engine: afd
            enabled: True  # implicit
            description: "The nova instance filesystem's root free space is low."
            severity: warning
            logical_operator: or # implicit
            rules:
            - metric: fs_space_percent_free
              relational_operator: '<'
              threshold: 5
              window: 60
              periods: 0
              function: min
              fs: '/var/lib/nova'
        filter:
          nova_compute_service:
            engine: afd
            notifications: False
            alerting: True
            trigger:
              vip:
              - nova_compute_filesystem_warning
              - nova_compute_filesystem_critical
              - nova_compute_filesystem_critical
      aggregator:
        filter:
          nova_compute: # the service_role format
            engine: gse
            policy: highest_severity
            group_by: member
            members:
            - nova_compute_logs
            - nova_compute_service
            - nova_compute_instances
            - nova_compute_libvirt
            - nova_compute_free_cpu
            - nova_compute_free_mem
            hints:
             - neutron_compute # or contrail_vrouter for contrail nodes

Default CPU usage alarms, excerpt from `linux/meta/heka.yml`.

.. code-block:: yaml

      metric_collector:
        trigger:
          linux_system_cpu_critical:
            engine: afd
            enabled: True  # implicit
            description: 'The CPU usage is too high.'
            severity: critical
            label:
              hostname: '$match_by.hostname'
              node_role: controller
            match_by: ['hostname']
            rules:
            - metric: cpu_wait
              relational_operator: >=
              threshold: 35
              window: 120
              periods: 0
              function: avg
            - metric: cpu_idle
              relational_operator: <=
              threshold: 5
              window: 120
              function: avg
          linux_system_cpu_warning:
            engine: afd
            enabled: True  # implicit
            description: 'The CPU wait times are high.'
            severity: critical
            label:
              hostname: '$match_by.hostname'
              node_role: controller
            match_by: ['hostname']
            rules:
            - metric: cpu_wait
              relational_operator: >=
              threshold: 15
              window: 120
              periods: 0
              function: avg
        filter:
          linux_system_cpu:
            engine: afd
            notifications: False
            alerting: True
            trigger:
              vip:
              - linux_system_cpu_warning # will not render if referenced trigger is disabled
              - linux_system_cpu_critical

CPU usage override for compute node, excerpt from `nova/meta/heka.yml`.

.. code-block:: yaml

      metric_collector:
        trigger:
          nova_compute_cpu_critical:
            engine: afd
            enabled: True  # implicit
            description: 'The CPU wait times are too high.'
            severity: critical
            label:
              hostname: '$match_by.hostname'
              node_role: controller
            match_by: ['hostname']
            rules:
            - metric: cpu_wait
              relational_operator: >=
              threshold: 35
              window: 120
              periods: 0
              function: avg

.. code-block:: yaml

Alarm override option 1 - override:

.. code-block:: yaml

      metric_collector:
        trigger:
          # Trigger can be disable
          linux_system_cpu_critical:
            enabled: False
        filter:
          #Alarm can be overriden
          linux_system_cpu:
            trigger:
              vip:
              - nova_compute_cpu_critical

Alarm override option 2 - reinitialize:

.. code-block:: yaml

      metric_collector:
        filter:
          ...
          # Alarm is disabled
          linux_system_cpu:
            enabled: False
          # new alarm is created
          nova_compute_cpu:
            engine: afd_alarm
            notifications: False
            alerting: True
            trigger:
              vip:
              - linux_system_cpu_warning # will not render if referenced trigger is disabled
              - nova_compute_cpu_critical


Remote collector service
------------------------

Remote API check example, excerpt from `nova/meta/heka.yml`.

.. code-block:: yaml

    heka:
      remote_collector:
        trigger:
          nova_control_api_fail:
            engine: afd
            description: 'Endpoint check for nova-api failed.'
            severity: critical
            alerting: True
            label:
              hostname: '$match_by.hostname'
              node_role: controller
            match_by: ['hostname']
            rules:
            - metric: openstack_check_api
              relational_operator: '=='
              threshold: 0
              window: 60
              periods: 0
              function: last
              service: 'nova-api'
        filter:
          nova_control_api:
            engine: afd
            notifications: False
            alerting: True
            trigger:
              vip:
              - nova_control_api_fail

Corresponding clusters and alarms, excerpt from `nova/meta/heka.yml`.

.. code-block:: yaml

    heka:
      aggregator:
        filter:
          nova_compute: # the service_role format
            engine: gse
            policy: highest_severity
            group_by: member
            members:
            - nova_control_api
            - nova_control_endpoint
            hints:
             - neutron_control # or contrail_vrouter for contrail nodes
             - keystone_control


Read more
=========

* https://hekad.readthedocs.org/en/latest/index.html
