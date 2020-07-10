FROM registry.redhat.io/openshift4/ose-logging-fluentd:v4.3.28-202006290519.p0

MAINTAINER Infra DevOps <scott.c.worthington+quayio@gmail.com>

USER 0

RUN \
      INSTALL_PKGS="rh-ruby25-ruby-devel  rh-ruby25-rubygems-devel  gcc-c++  make" \
 &&   REMOVE_PKGS="cpp gcc glibc-devel glibc-headers libgomp libmpc libstdc++-devel kernel-headers mpfr" \
 &&   yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS \
 &&   rpm -V $INSTALL_PKGS \
 &&   scl enable rh-ruby25 "/opt/rh/rh-ruby25/root/usr/bin/gem install fluent-plugin-kinesis --verbose" \
 &&   yum remove -y  --setopt=tsflags=nodocs $INSTALL_PKGS $REMOVE_PKGS \
 &&   yum clean all

WORKDIR ${HOME}

#CMD ["scl", "enable", "rh-ruby25", "--", "sh", "run.sh"]
CMD ["scl", "enable", "rh-ruby25", "bash"]

LABEL io.k8s.display-name=Fluentd-custom-kinesis

LABEL \
        io.k8s.description="Fluentd custom container for forwarding to AWS kinesis" \
        License="GPLv2+" \
        version="v4.0.0" \
        architecture="x86_64" \
        release="0.0.0.0"

# Other labels you may want to add:
# vendor="Your Company"
# name="yourcontainerrepo/fluentd-custom-kinesis"
