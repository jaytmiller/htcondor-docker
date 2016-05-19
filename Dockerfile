FROM centos:centos7

MAINTAINER Andy Pohl <apohl@morgridge.org>

# Pick a username.  I will be "htandy"
ENV USER htandy

RUN yum -y install \
         yum-utils \
         wget \
         jyum \
         install \
         sudo \
         which && \
    wget http://research.cs.wisc.edu/htcondor/yum/RPM-GPG-KEY-HTCondor && \
    rpm --import RPM-GPG-KEY-HTCondor && \
    yum-config-manager --add-repo https://research.cs.wisc.edu/htcondor/yum/repo.d/htcondor-stable-rhel7.repo && \
    yum -y install --enablerepo=centosplus condor.x86_64 && \
    echo -e "TRUST_UID_DOMAIN = True\n" >> /etc/condor/condor_config.local && \
    echo -e "ALLOW_WRITE = *\n" >> /etc/condor/condor_config.local && \
    useradd -m ${USER} && \
    # setting the password with useradd like that doesn't work for some reason. \
    echo 123456 | passwd --stdin ${USER} && \
    usermod -a -G condor ${USER} && \
    echo -e ${USER}" ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    chmod -R g+w /var/{lib,log,lock,run}/condor && \   
    yum clean all

USER ${USER}

RUN echo -e "export USER=$(whoami)" >> /home/${USER}/.bashrc && \
    echo -e "condor_master 2>&1" >> /home/${USER}/.bashrc

WORKDIR /home/${USER}
 
CMD [ "/bin/bash" ]
