FROM zimbra/zcs-dev:8.8.8ga


# ************************************************************************
# The following is required for Genesis tests to be run.
# 1. Disable setting that prevents users from writing to current terminal device
# 2. Symlink in /bin/env (some genesis tests expect it to be there)
# ************************************************************************
RUN sed -i.bak 's/^mesg/# mesg/' /root/.profile && \
    ln -s /usr/bin/env /bin/env && \
    echo 'PATH=/usr/local/staf/bin/:$PATH' >> /root/.bashrc

# ************************************************************************
# Install STAF to /usr/local/staf
#
# Add the STAF libraries to the END of the list of places where libraries are searched
# Some of the libraries included with STAF are wonky and will bork normal commands
# if they are loaded first.
# ************************************************************************
RUN apt-get install -y openjdk-8-jdk
RUN apt-get install -y unzip
# Caching the STAF binary in S3 due to intermittent reliability issues with sourceforge
# Original URL: http://downloads.sourceforge.net/project/staf/staf/V3.4.26/STAF3426-setup-linux-amd64-NoJVM.bin
RUN curl -k -L -o /tmp/staf-setup.bin 'https://docker.zimbra.com.s3.amazonaws.com/staf/STAF3426-setup-linux-amd64-NoJVM.bin' && \
    chmod +x /tmp/staf-setup.bin && \
    /tmp/staf-setup.bin -i silent \
       -DACCEPT_LICENSE=1 \
       -DCHOSEN_INSTALL_SET=Custom \
       -DCHOSEN_INSTALL_FEATURE_LIST=STAF,ExtSvcs,Langs,Codepage && \
    rm /tmp/staf-setup.bin && \
    echo /usr/local/staf/lib > /etc/ld.so.conf.d/zzz-staf.conf && \
    ldconfig
