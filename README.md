# htcondor-docker
Dockerfile for making an image with a personal HTCondor.

To use it, go to a directory where you want to have data mounted in a container.  Then start the container with:
```
$ docker run --name htcondor -d -v $(pwd):/scratch andypohl/htcondor
```
will start the master, schedd, collector, negotiator, and startd daemons via condor_master and mount the current directory on your computer inside a Docker container named "htcondor" as a directory called "/scratch".  Having this started and now detached, enter the container to run some condor commands like:
```
$ docker exec -ti htcondor bash
```
You can check the status of the personal HTCondor pool with condor_status:
```
[root@f9ac001ccefe ~]# condor_status
Name               OpSys      Arch   State     Activity LoadAv Mem   ActvtyTime

f9ac001ccefe       LINUX      X86_64 Unclaimed Idle      0.080 2002  0+00:00:04
                     Machines Owner Claimed Unclaimed Matched Preempting

        X86_64/LINUX        1     0       0         1       0          0

               Total        1     0       0         1       0          0
```
and you can change to the /scratch directory to find local submit files, etc. and go from there.  You can find the Docker container running with the docker ps command:
```
$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
bcbb3e39a286        andypohl/htcondor   "/usr/sbin/start-cond"   16 minutes ago      Up 2 minutes                            htcondor
```
and stop and remove the container by doing:
```
$ docker stop htcondor
$ docker rm htcondor
```
## Concerns 
I won't pretend I know if this is the best way to do this, but it seems to work.  Please mention any feedback or better yet contribute to the GitHub.
## Child Images
  * The plan is to make a BOSCO-style personal HTCondor that could actually be used in real life to maybe remote submit jobs.  
  * Pegasus is a nice Workflow Management System that runs on top of HTCondor (and some other batch schedulers).
