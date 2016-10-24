
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
              dimension:
                fs: '/var/lib/nova'
          nova_compute_filesystem_critical:
            description: "The nova instance filesystem's root free space is low."
            severity: warning
            rules:
            - metric: fs_space_percent_free
              relational_operator: '<'
              threshold: 5
              window: 60
              periods: 0
              function: min
              dimension:
                fs: '/var/lib/nova'
        alarm:
          nova_compute_filesystem:
            notifications: False
            alerting: True
            dimension:
              node_role: controller
            triggers:
            - nova_compute_filesystem_warning
            - nova_compute_filesystem_critical
      aggregator:
        alarm_cluster:
          nova_compute_service: # the service_role format
            policy: highest_severity
            group_by: member
            match:
              node_role: compute
            dimension:
              cluster: nova-compute-plane
            members:
            - nova_compute_logs
            - nova_compute_filesystem
            - nova_compute_instances
            - nova_compute_libvirt
            - nova_compute_free_cpu
            - nova_compute_free_mem
            hints:
             - neutron_compute # or contrail_vrouter for contrail nodes
          nova_compute_plane: # the service_role format
            engine: gse
            policy: highest_severity
            group_by: member
            match:
              cluster: nova-compute-plane

Default CPU usage alarms, excerpt from `linux/meta/heka.yml`.

.. code-block:: yaml

      metric_collector:
        trigger:
          linux_system_cpu_critical:
            description: 'The CPU usage is too high.'
            severity: critical
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
            description: 'The CPU wait times are high.'
            severity: critical
            rules:
            - metric: cpu_wait
              relational_operator: >=
              threshold: 15
              window: 120
              periods: 0
              function: avg
        alarm:
          linux_system_cpu:
            notifications: False
            alerting: True
            triggers:
            - linux_system_cpu_warning # will not render if referenced trigger is disabled
            - linux_system_cpu_critical
            dimension:
              node_role: controller


CPU usage override for compute node, excerpt from `nova/meta/heka.yml`.

.. code-block:: yaml

      metric_collector:
        trigger:
          nova_compute_cpu_critical:
            description: 'The CPU wait times are too high.'
            severity: critical
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
        alarm:
          #Alarm can be overriden
          linux_system_cpu:
            triggers:
            - nova_compute_cpu_critical

Alarm override option 2 - reinitialize:

.. code-block:: yaml

      metric_collector:
        alarm:
          ...
          # Alarm is disabled
          linux_system_cpu:
            enabled: False
          # new alarm is created
          nova_compute_cpu:
            engine: afd
            notifications: False
            alerting: True
            triggers:
            - linux_system_cpu_warning # will not render if referenced trigger is disabled
            - nova_compute_cpu_critical
            dimension:
              node_role: controller


Remote collector service
------------------------

Remote API check example, excerpt from `nova/meta/heka.yml`.

.. code-block:: yaml

    heka:
      remote_collector:
        trigger:
          nova_control_api_fail:
            description: 'Endpoint check for nova-api failed.'
            severity: critical
            rules:
            - metric: openstack_check_api
              relational_operator: '=='
              threshold: 0
              window: 60
              periods: 0
              function: last
              dimension:
                service: 'nova-api'
        alarm:
          nova_control_api:
            notifications: False
            alerting: True
            dimension:
              node_role: controller
            triggers:
            - nova_control_api_fail

Corresponding clusters and alarms, excerpt from `nova/meta/heka.yml`.

.. code-block:: yaml

    heka:
      aggregator:
        alarm_cluster:
          nova_control_service:
            policy: highest_severity
            group_by: member
            match:
              node_role: control
            dimension:
              cluster: openstack-control-plane
            members:
            - nova_control_api
            - nova_control_endpoint
            hints:
             - neutron_control # or contrail_vrouter for contrail nodes
             - keystone_control
          openstack_control_plane:
            engine: gse
            policy: highest_severity
            group_by: member
            match:
              cluster: openstack-control-plane

Read more
=========

* https://hekad.readthedocs.org/en/latest/index.html
