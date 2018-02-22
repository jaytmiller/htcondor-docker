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
         which \
         openssh-clients && \
    yum -y groupinstall 'Development Tools' && \
    curl -O http://research.cs.wisc.edu/htcondor/yum/RPM-GPG-KEY-HTCondor && \
    rpm --import RPM-GPG-KEY-HTCondor && \
    yum-config-manager --add-repo https://research.cs.wisc.edu/htcondor/yum/repo.d/htcondor-development-rhel7.repo && \
    yum -y install condor-bosco && \
    yum clean all && \
    rm -f RPM-GPG-KEY-HTCondor && \
    groupadd -g ${GID} ${SUBMIT_USER} && \
    useradd -m -u ${UID} -g ${GID} ${SUBMIT_USER} && \
    usermod -a -G condor ${SUBMIT_USER} && \
    echo ${PASS} | passwd --stdin ${SUBMIT_USER} && \
    mkdir /home/${SUBMIT_USER}/example && \
    sed -i 's/\(^Defaults.*requiretty.*\)/#\1/' /etc/sudoers && \
    rm -f /etc/localtime && \
    ln -s /usr/share/zoneinfo/America/Chicago /etc/localtime

# RStudio/Shiny layer (see GitHub keberwein/docker_shiny-server_centos7)
RUN yum -y install epel-release && \
    yum -y install \
        git \
        xml2 \
        libxml2-devel \
        curl \
        curl-devel \
        openssl-devel \
        openssl098e \
        locales \
        java-1.7.0-openjdk-devel \
        tar \
        libcurl-devel \
        pandoc \
        supervisor \
        passwd \
        "R-*" \
        openmpi-devel \
        wget && \
    cd /root && \
    wget https://cran.r-project.org/src/contrib/Rmpi_0.6-6.tar.gz && \
    echo /usr/lib64/openmpi/lib > /etc/ld.so.conf.d/openmpi.conf && \
    ldconfig && \
    R CMD INSTALL Rmpi_0.6-6.tar.gz \
      --configure-args="--with-Rmpi-include=/usr/include/openmpi-x86_64 --with-Rmpi-libpath=/usr/lib64/openmpi/lib --with-Rmpi-type=OPENMPI" \
      --configure-vars="CFLAGS=-I/usr/include/openmpi-x86_64 LDFLAGS='-L/usr/lib64/openmpi/lib -lompi'" && \
    wget https://s3.amazonaws.com/rstudio-dailybuilds/rstudio-server-rhel-1.1.423-x86_64.rpm && \
    yum install -y --nogpgcheck rstudio-server-rhel-1.1.423-x86_64.rpm && \
    wget https://download3.rstudio.org/centos5.9/x86_64/shiny-server-1.5.6.875-rh5-x86_64.rpm && \
    yum install -y --nogpgcheck shiny-server-1.5.6.875-rh5-x86_64.rpm && \
    R -e "install.packages(c('devtools','tidyverse','doMPI','doParallel'), repos='https://cran.rstudio.com')" && \
    mkdir -p /var/log/shiny-server && \
    chown shiny:shiny /var/log/shiny-server && \
	chown shiny:shiny -R /srv/shiny-server && \
	chmod 755 -R /srv/shiny-server && \
	chown shiny:shiny -R /opt/shiny-server/samples/sample-apps && \
    chmod 755 -R /opt/shiny-server/samples/sample-apps 

# KNOBS and startup script
COPY condor_config.docker_image /etc/condor/config.d/
COPY start-condor.sh /usr/sbin/

# Signal to User of this image use this directory (run with -v)
VOLUME ["/home/${SUBMIT_USER}/submit"]
WORKDIR /home/${SUBMIT_USER}/submit

# Copy in an example HTCondor submission and fix permissions
COPY hello.s* /home/${SUBMIT_USER}/example/
RUN chown -R ${SUBMIT_USER}:${SUBMIT_USER} /home/${SUBMIT_USER}/example

# For RStudio/Shiny (step 2) 
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
# For RStudio/Shiny (step 3) 
RUN mkdir -p /var/log/supervisor && \
	chmod 755 -R /var/log/supervisor
# For RStudio/Shiny (step 4) 
EXPOSE 8787 3838

# Use this if you're not going to restart HTCondor in the container.
# If you do need to do that, you're better off running the condor_master
# command manually.  
CMD ["/usr/sbin/start-condor.sh"]

# To start RStudio/Shiny, do
# docker exec <container-ID> /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
