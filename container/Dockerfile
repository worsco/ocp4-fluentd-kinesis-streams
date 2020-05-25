FROM registry.redhat.io/openshift4/ose-logging-fluentd@sha256:40edd9833d5a4290f63cfbc7a442f6ce5ba4f21c2acd252e0ec4a0db9a25b7c5

MAINTAINER Infra DevOps <scott.c.worthington+quayio@gmail.com>

USER 0

RUN : 'removed yum-config-manager' \
 &&   INSTALL_PKGS="rh-ruby25-ruby-devel  rh-ruby25-rubygems-devel  gcc-c++  make" \
 &&   REMOVE_PKGS="cpp gcc glibc-devel glibc-headers libgomp libmpc libstdc++-devel kernel-headers mpfr" \
 &&   yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS \
 &&   rpm -V $INSTALL_PKGS \
 &&   scl enable rh-ruby25 "/opt/rh/rh-ruby25/root/usr/bin/gem install fluent-plugin-kinesis --verbose" \
 &&   yum remove -y  --setopt=tsflags=nodocs $INSTALL_PKGS $REMOVE_PKGS \
 &&   yum clean all

WORKDIR ${HOME}

CMD ["scl", "enable", "rh-ruby25", "--", "sh", "run.sh"]

LABEL io.k8s.display-name=Fluentd-custom-kinesis

LABEL \
        io.k8s.display-name="Fluentd-custom-kinesis" \
        io.k8s.description="Fluentd custom container for forwarding to AWS kinesis"
