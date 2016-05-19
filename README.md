# htcondor-docker
Dockerfile for making an image with a personal HTCondor.

To use it, pick a username you like (I like "htandy"), and build it yourself:
```
$ docker build -t <your-image-name> .
$ docker run -ti <your-image-name>
[htandy ~]$ condor_on -all
Sent "Spawn-All-Daemons" command to master htandy@d2a59693633
[htandy ~]$ condor_status
```
and so on.  Or just pull it from Docker Hub and live with the htandy username:
```
$ docker pull andypohl/htcondor
$ docker run -ti andypohl/htcondor
[htandy ~]$ condor_on -all
```
To use mount a non-container directory inside the container, use -v, e.g. to mount the current dir:
```
$ docker run -ti --rm -v $(pwd):/home/htandy/thisdir andypohl/htcondor
```
Personally, I almost always just stick to the root user in Docker containers so it's strange not to.  I had trobule starting condor without errors unless I used an older condor on an older CentOs, e.g. [this one](https://hub.docker.com/r/jimwhite/condor-centos6/).  Having the htandy user is a little strange to me and I'm not 100% sure it's perfectly not screwy but so far it seems ok.  
