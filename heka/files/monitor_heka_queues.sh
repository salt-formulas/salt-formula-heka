#!/bin/bash -e
#
# This script reports the size of each Heka output queue.

for q in /var/cache/*/output_queue/*;
do
  DATA=$(du -sb "$q")
  SIZE=$(echo $DATA | cut -d " " -f 1)
  QUEUE=$(echo $DATA | cut -d " " -f 2)
  if [[ -n "${SIZE}" && -n "${QUEUE}" ]]; then
    echo "heka_output_queue_size,queue=${QUEUE} value=${SIZE}"
  fi
done
