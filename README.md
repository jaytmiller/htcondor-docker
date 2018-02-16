# htcondor-docker
Dockerfile for building a Docker image with the latest "personal" HTCondor on CentOS 7.  To run the test:
```
me@laptop$ docker run -d -h htcondor --name htcondor andypohl/htcondor
63929dc053607d52071c99933520ff0bbda887e125c4bd5866ae976283626b5a
me@laptop$ docker exec -ti -u 1000:1000 htcondor bash
[submitter@htcondor submit]$ cd ../example/
[submitter@htcondor example]$ condor_status
Name           OpSys      Arch   State     Activity LoadAv Mem   ActvtyTime

slot1@htcondor LINUX      X86_64 Unclaimed Idle      0.000  999  0+00:00:03
slot2@htcondor LINUX      X86_64 Unclaimed Idle      0.000  999  0+00:00:03

                     Machines Owner Claimed Unclaimed Matched Preempting  Drain

        X86_64/LINUX        2     0       0         2       0          0      0

               Total        2     0       0         2       0          0      0
[submitter@htcondor example]$ condor_submit hello.sub
Submitting job(s).
1 job(s) submitted to cluster 1.
```

### Versioning
The [andypohl/htcondor](https://hub.docker.com/r/andypohl/htcondor/) Docker image from the Docker Hub may or may not be the current HTCondor version.  If you build the image yourself, you should be fetching the recent development release of HTCondor as well as recent versions of Centos7, etc.  To build yourself:

```
me@laptop$ git clone https://github.com/andypohl/htcondor-docker.git
me@laptop$ cd htcondor-docker/
me@laptop$ docker build -t me/htcondor .
```

If the build worked, you should be able to repeat the commands above substituting the image name you specified instead of `andypohl/htcondor`.

## BOSCO

[BOSCO](https://bosco.opensciencegrid.org/) is a useful interface to HTCondor.  It moves some of the HTCondor interactivity from a submit server (which you still use) to your personal workstation.  It also allows you to gather the output files directly on your computer.  But because BOSCO requires a personal HTCondor installation, it's well-suited to Docker containers.

The workflow for using BOSCO is a little different.  Starting from a running personal HTCondor container, you'll set up the "BOSCO cluster".  Note that I'm using a real login and submit server hostname because it's easier to illustrate.  You'll need to substitute appropriately with your favorite HTCondor submit node (accessible via ssh) and your username.  

**Note**: You will be prompted for a password at this step but not later, because an ssh key is created and added to your `~/.ssh/authorized_keys` file on the submit node.  This ssh key file makes it possible for BOSCO/HTCondor in the Docker container to interact with the submit node **without a password**.  Be aware that this file exists in the container.  When you remove the container, the key file is gone, but because this procedure creates keyfile credentials in a place outside of your local `.ssh`, be careful!! 

```
me@laptop$ docker exec -ti -u 1000:1000 htcondor bosco_cluster -a aapohl@submit-5.chtc.wisc.edu condor
Enter the password to copy the ssh keys to aapohl@submit-5.chtc.wisc.edu:
The authenticity of host 'submit-5.chtc.wisc.edu (128.104.101.92)' can't be established.
RSA key fingerprint is SHA256:4MtidqOkAhzySKFQJF7AAj32Pj1h5Ny/tHzRvkQSNGc.
RSA key fingerprint is MD5:93:c5:b6:0c:f6:e5:7d:07:bc:7c:ff:55:4f:56:49:fd.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'submit-5.chtc.wisc.edu,128.104.101.92' (RSA) to the list of known hosts.
aapohl@submit-5.chtc.wisc.edu's password: 
Downloading for aapohl@submit-5.chtc.wisc.edu....
Unpacking.
Sending libraries to aapohl@submit-5.chtc.wisc.edu.
You are not running as the factory user. BOSCO Glideins disabled.
Installing on cluster aapohl@submit-5.chtc.wisc.edu.
Installation complete
The cluster aapohl@submit-5.chtc.wisc.edu has been added to BOSCO
It is available to run jobs submitted with the following values:
> universe = grid
> grid_resource = batch condor aapohl@submit-5.chtc.wisc.edu
```

**Important**: At this stage, the container has private information in it.  If a Docker image is to be made from this container with `docker commit`, you **should not `docker push` or `docker export` it anywhere**.  

Though I do it myself, I'm not going to demonstrate starting an HTCondor Docker container with a BOSCO cluster already installed.  In this example, our container was started before the BOSCO cluster was installed.  Instead I'll continue the demonstration from our container.

Running jobs with BOSCO:
```
me@laptop$ docker exec -ti -u 1000:1000 htcondor bash
[submitter@htcondor submit]$ cd ../example
[submitter@htcondor example]$ sed -i 's/vanilla/grid\ngrid_resource = batch condor aapohl@submit-5.chtc.wisc.edu/' hello.sub
[submitter@htcondor example]$ condor_submit hello.sub 
Submitting job(s)...
3 job(s) submitted to cluster 1.
```
This sends the jobs to the submit node.  If I'm logged-in to that, I can see these jobs appear:

```
[aapohl@submit-5:~]$ condor_q
-- Schedd: submit-5.chtc.wisc.edu : <128.104.101.92:9618?... @ 02/15/18 18:24:26
OWNER  BATCH_NAME              SUBMITTED   DONE   RUN    IDLE  TOTAL JOB_IDS
aapohl CMD: condor_exec.exe   2/15 18:24      _      _      1      1 55050221.0
aapohl CMD: condor_exec.exe   2/15 18:24      _      _      1      1 55050222.0
aapohl CMD: condor_exec.exe   2/15 18:24      _      _      1      1 55050223.0

3 jobs; 0 completed, 0 removed, 3 idle, 0 running, 0 held, 0 suspended
```

These appear different inside our Docker container:

```
[submitter@htcondor example]$ condor_q


-- Schedd: htcondor : <172.17.0.2:42611?... @ 02/15/18 18:27:43
OWNER     BATCH_NAME       SUBMITTED   DONE   RUN    IDLE  TOTAL JOB_IDS
submitter CMD: hello.sh   2/15 18:23      _      _      3      3 1.0-2

Total for query: 3 jobs; 0 completed, 0 removed, 3 idle, 0 running, 0 held, 0 suspended 
Total for submitter: 3 jobs; 0 completed, 0 removed, 3 idle, 0 running, 0 held, 0 suspended 
Total for all users: 3 jobs; 0 completed, 0 removed, 3 idle, 0 running, 0 held, 0 suspended
```

When the jobs finish, the files created appear inside our Docker container in the submit directory alongside the submit file:

```
[submitter@htcondor example]$ ls -l
total 24
-rw-r--r-- 1 submitter submitter    0 Feb 15 18:29 hello_1_0.err
-rw-r--r-- 1 submitter submitter   63 Feb 15 18:29 hello_1_0.out
-rw-r--r-- 1 submitter submitter    0 Feb 15 18:29 hello_1_1.err
-rw-r--r-- 1 submitter submitter   69 Feb 15 18:29 hello_1_1.out
-rw-r--r-- 1 submitter submitter    0 Feb 15 18:29 hello_1_2.err
-rw-r--r-- 1 submitter submitter   63 Feb 15 18:29 hello_1_2.out
-rw-r--r-- 1 submitter submitter 2325 Feb 15 18:29 hello_1.log
-rwxr-xr-x 1 submitter submitter  121 Feb 15 15:16 hello.sh
-rw-r--r-- 1 submitter submitter 1435 Feb 15 18:23 hello.sub
```
