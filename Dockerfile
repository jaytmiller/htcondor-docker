FROM centos:centos7

MAINTAINER Andy Pohl <apohl@morgridge.org>

# HTCondor User details:
ENV SUBMIT_USER submitter
ENV GID 1000
ENV UID 1000
ENV PASS 123456

# Build in one RUN
RUN yum -y install \
         yum-utils \
         sudo \
         openssh-clients && \
    curl -O http://research.cs.wisc.edu/htcondor/yum/RPM-GPG-KEY-HTCondor && \
    rpm --import RPM-GPG-KEY-HTCondor && \
    yum-config-manager --add-repo https://research.cs.wisc.edu/htcondor/yum/repo.d/htcondor-development-rhel7.repo && \
    yum -y install condor && \
    yum clean all && \
    rm -f RPM-GPG-KEY-HTCondor && \
    groupadd -g ${GID} ${SUBMIT_USER} && \
    useradd -m -u ${UID} -g ${GID} ${SUBMIT_USER} && \
    usermod -a -G condor ${SUBMIT_USER} && \
    echo ${PASS} | passwd --stdin ${SUBMIT_USER}    

# KNOBS and startup script
COPY condor_config.docker_image /etc/condor/config.d/
COPY start-condor.sh /usr/sbin/

# Signal to User of this image use this directory (run with -v)
VOLUME ["/home/${SUBMIT_USER}/submit"]
WORKDIR /home/${SUBMIT_USER}/submit

CMD ["/usr/sbin/start-condor.sh"]
