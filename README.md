# htcondor-docker
Dockerfile for building a Docker image with the latest "personal" HTCondor on CentOS 7.  

To use it, go to a directory where you want to have data mounted in a container.  Then start the container with:
```
$ docker run --name htcondor -d -v $(pwd):/submit andypohl/htcondor
```
will start the master, schedd, collector, negotiator, and startd daemons via condor_master and mount the current directory on your computer inside a Docker container named "htcondor" as a directory called "/submit".  Having this started and now detached, you can run commands through the container like:
```
$ docker exec htcondor condor_status
Name               OpSys      Arch   State     Activity LoadAv Mem   ActvtyTime

f9ac001ccefe       LINUX      X86_64 Unclaimed Idle      0.080 2002  0+00:00:04
                     Machines Owner Claimed Unclaimed Matched Preempting

        X86_64/LINUX        1     0       0         1       0          0

               Total        1     0       0         1       0          0
```
You can find the Docker container running with the docker ps command:
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
Now if it were only so simple.  HTCondor prefers submitting to be done non-root.  So there's a token user (by default called "submitter") built into the image.  THe UID and GID of this user is fixed at 1000, to simplify things from the Docker command line.  When executing a condor_submit, it's needed to add -u 1000:1000.  For example, [using the example from CHTC](http://chtc.cs.wisc.edu/helloworld.shtml):
```
$  docker exec -u 1000:1000 htcondor condor_submit hello-chtc.sub
Submitting job(s)...
3 job(s) submitted to cluster 1.
```
It may be worth making condor command aliases on the Docker host computer to make quicker work of those commands.  The docker container name can be fixed and the UID/GID can be fixed, so it's pretty easy:
```
$ alias condor_submit='docker exec -u 1000:1000 htcondor condor_submit'
$ alias condor_q='docker exec -u 1000:1000 htcondor condor_q'
$ condor_submit hello-chtc.sub
Submitting job(s)...
3 job(s) submitted to cluster 3.
$ condor_q


-- Schedd: b3dcc9772a84 : <172.17.0.2:9618?...
 ID      OWNER            SUBMITTED     RUN_TIME ST PRI SIZE CMD
   3.0   submitter       5/24 15:01   0+00:00:02 R  0    0.0 hello-chtc.sh 0
   3.1   submitter       5/24 15:01   0+00:00:00 I  0    0.0 hello-chtc.sh 1
   3.2   submitter       5/24 15:01   0+00:00:00 I  0    0.0 hello-chtc.sh 2

3 jobs; 0 completed, 0 removed, 2 idle, 1 running, 0 held, 0 suspended
```
## Concerns 
I won't pretend I know if this is the best way to do this, but it seems to work.  Please mention any feedback or better yet contribute to the GitHub.
## Child Images
  * The plan is to make a BOSCO-style personal HTCondor that could actually be used in real life to maybe remote submit jobs.  
  * Pegasus is a nice Workflow Management System that runs on top of HTCondor (and some other batch schedulers).
