FROM centos:centos7

MAINTAINER Andy Pohl <apohl@morgridge.org>

# HTCondor User details:
ENV SUBMIT_USER submitter
ENV GID 1000
ENV UID 1000
ENV PASS octarine

# Build in one RUN
RUN yum -y install \
         yum-utils \
         sudo \
         which \
         openssh-clients \
         wget \
         curl \
         pcre

RUN yum -y groupinstall 'Development Tools'

RUN cd /etc/yum.repos.d && \
    wget http://research.cs.wisc.edu/htcondor/yum/repo.d/htcondor-stable-rhel7.repo && \
    wget http://research.cs.wisc.edu/htcondor/yum/RPM-GPG-KEY-HTCondor && \
    rpm --import RPM-GPG-KEY-HTCondor

RUN yum -y install condor.x86_64

RUN yum clean all

RUN groupadd -g ${GID} ${SUBMIT_USER} && \
    useradd -m -u ${UID} -g ${GID} ${SUBMIT_USER} && \
    usermod -a -G condor ${SUBMIT_USER} && \
    echo ${PASS} | passwd --stdin ${SUBMIT_USER} && \
    mkdir /home/${SUBMIT_USER}/example && \
    sed -i 's/\(^Defaults.*requiretty.*\)/#\1/' /etc/sudoers && \
    rm -f /etc/localtime && \
    ln -s /usr/share/zoneinfo/America/Chicago /etc/localtime

# KNOBS and startup script
COPY condor_config.docker_image /etc/condor/config.d/
COPY start-condor.sh /usr/sbin/

# Signal to User of this image use this directory (run with -v)
VOLUME ["/home/${SUBMIT_USER}/submit"]
WORKDIR /home/${SUBMIT_USER}/submit

# Copy in an example HTCondor submission and fix permissions
COPY hello.s* /home/${SUBMIT_USER}/example/
RUN chown -R ${SUBMIT_USER}:${SUBMIT_USER} /home/${SUBMIT_USER}/example

USER $UID
WORKDIR /home/${SUBMIT_USER}

ENV CONDA_INSTALLER Miniconda3-latest-Linux-x86_64.sh
ENV CONDA_WHERE /home/${SUBMIT_USER}/miniconda3

RUN wget https://repo.anaconda.com/miniconda/${CONDA_INSTALLER}  && \
    bash ${CONDA_INSTALLER} -b -p ${CONDA_WHERE} && \
    rm -f ${CONDA_INSTALLER} && \
    source ${CONDA_WHERE}/etc/profile.d/conda.sh && \
    conda update --yes -n base -c defaults conda && \
    conda init bash && \
    conda create --yes -n octarine python=3.7 && \
    echo "conda activate octarine" >> /home/${SUBMIT_USER}/.bashrc && \
    ln -s /home/${SUBMIT_USER}/.bashrc  /home/${SUBMIT_USER}/.profile

RUN source /home/${SUBMIT_USER}/.profile && \
    pip install --no-cache \
  jupyterlab \
  htcondor \
  htmap \
  numpy \
  matplotlib \
  pytest

RUN source /home/${SUBMIT_USER}/.profile && \
    pip install git+https://github.com/spacetelescope/jwst

# For jupyter lab
# EXPOSE 8888

USER root

# Use this if you're not going to restart HTCondor in the container.
# If you do need to do that, you're better off running the condor_master
# command manually
CMD ["/usr/sbin/start-condor.sh"]
