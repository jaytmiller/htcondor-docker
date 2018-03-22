#!/bin/bash

/usr/sbin/sshd -D > /var/log/sshd.log 2>&1 &
$(condor_config_val MASTER) -f -t >> /var/log/condor/MasterLog 2>&1 
