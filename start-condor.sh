#!/bin/bash

$(condor_config_val MASTER) -f -t  2>&1 >> /var/log/condor/master &
