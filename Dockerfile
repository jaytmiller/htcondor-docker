FROM centos:centos7

MAINTAINER Andy Pohl <apohl@morgridge.org>

RUN yum -y install \
         yum-utils \
         sudo && \
    curl -O http://research.cs.wisc.edu/htcondor/yum/RPM-GPG-KEY-HTCondor && \
    rpm --import RPM-GPG-KEY-HTCondor && \
    yum-config-manager --add-repo https://research.cs.wisc.edu/htcondor/yum/repo.d/htcondor-stable-rhel7.repo && \
    yum -y install condor && \
    yum clean all && \
    rm -f RPM-GPG-KEY-HTCondor

COPY condor_config.local /etc/condor/
COPY start-condor.sh /usr/sbin/

CMD ["/usr/sbin/start-condor.sh"]
