#!/bin/bash

docker run -d -v /Users/andy/batchtools:/home/submitter/batchtools -p 8787:8787 --name batchtools-rstudio -h htcondor andypohl/batchtools-dev
sleep 5s
docker exec batchtools-rstudio /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
