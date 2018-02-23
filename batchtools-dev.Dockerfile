FROM andypohl/htcondor

MAINTAINER Andy Pohl <apohl@morgridge.org>
# R layer
COPY texlive.profile /root
RUN yum -y install \
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
        openmpi-devel \
        wget \
        perl-Digest-MD5 \
        bzip2-devel \
        cairo-devel \
        lapack-devel \
        libjpeg-devel \
        libpng-devel \
        readline-devel \
        udunits2-devel && \
    yum clean all && \
    cd /root && \
    wget https://cran.rstudio.com/src/base/R-latest.tar.gz && \
    wget http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz && \
    wget https://ftp.gnu.org/gnu/texinfo/texinfo-6.5.tar.gz && \
    tar xfz R-latest.tar.gz && \
    tar xfz install-tl-unx.tar.gz && \
    tar xfz texinfo-6.5.tar.gz && \
    rm -f *.gz && \
    xdir=$(ls -1 | grep install-tl) && \
    cd $xdir && \
    mv ../texlive.profile . && \
    ./install-tl -profile texlive.profile && \
    tlmgr install inconsolata && \
    tlmgr install framed && \
    tlmgr install titling && \
    cd ../texinfo-6.5 && \
    ./configure && make && make install && \
    cd /root && \
    rm -rf /root/install-tl* /root/texinfo-6.5 && \
    xdir=$(ls -1 | grep R) && \
    cd $xdir && \
    ./configure \
        --without-x \
        --with-cairo \
        --with-jpeglib \
        --with-libpng \
        --with-readline \
        --with-blas \
        --with-lapack \
        --enable-R-profiling \
        --enable-R-shlib \
        --enable-memory-profiling && \
    make && make install && \
    localedef -i en_US -f UTF-8 en_US.UTF-8 && \
    cd ../ && \
    rm -rf /root/R-* 

# Layer for extra R packages
COPY Rprofile.site /usr/local/lib64/R/etc
RUN echo /usr/lib64/openmpi/lib > /etc/ld.so.conf.d/openmpi.conf && \
    ldconfig && \
    R -e "install.packages('Rmpi', configure.args='--with-Rmpi-include=/usr/include/openmpi-x86_64 --with-Rmpi-libpath=/usr/lib64/openmpi/lib --with-Rmpi-type=OPENMPI')" && \
    R -e "install.packages(c('devtools', 'tidyverse', 'roxygen2', 'foreach', 'testthat', 'XML', 'jsonlite', 'httr', 'covr', 'knitr', 'doMPI', 'doParallel', 'rmarkdown', 'backports', 'base64url', 'brew', 'checkmate', 'digest', 'data.table', 'R6', 'Rcpp', 'rappdirs', 'stringi', 'stringr', 'withr', 'progress', 'fs', 'debugme', 'e1071', 'parallelMap', 'ranger', 'snow', 'BBmisc', 'codetools', 'microbenchmark', 'future.batchtools'))"

# RStudio Server layers
RUN cd /root && \
    wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
    rpm -ivh epel-release-latest-7.noarch.rpm && \
    yum install -y \
        ghostscript \
        qpdf \
        supervisor && \
    groupadd rstudio && \
    usermod -a -G rstudio ${SUBMIT_USER} && \
    wget https://s3.amazonaws.com/rstudio-dailybuilds/rstudio-server-rhel-1.1.423-x86_64.rpm && \
    yum install -y --nogpgcheck rstudio-server-rhel-1.1.423-x86_64.rpm && \
    rm -rf /root/* && \
    yum clean all && \
    mkdir -p /var/log/supervisor && \
	chmod 755 -R /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
EXPOSE 8787

# To start RStudio, do
# docker exec <container-ID> /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
