
collectd_client_state_run:
  salt.state:
    - tgt: 'I@collectd:client'
    - tgt_type: compound
    - sls: collectd.client

heka_client_state_run:
  salt.state:
    - tgt: 'I@heka:metric_collector'
    - tgt_type: compound
    - sls: heka.log_collector,heka.metric_collector

salt_minion_grains:
  salt.state:
    - tgt: '*'
    - sls: salt.minion.grains

mine_flush:
  salt.function:
    - name: mine.flush
    - tgt: '*'

mine_update:
  salt.function:
    - name: mine.update
    - tgt: '*'

heka_server_state_run:
  salt.state:
    - tgt: 'I@heka:aggregator'
    - tgt_type: compound
    - sls: heka.aggregator
