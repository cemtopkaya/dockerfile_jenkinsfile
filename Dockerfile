# docker build -t cinar/base -f Dockerfile.cinar.base --no-cache .
# docker run --name=cp --rmi -d cinar/prod
# docker exec -it cp bash



# Çınar ve 3rd Parti kütüphanelerin kurulduğu yansıyı multi-stage yapısında bağlıyoruz
FROM ubuntu:xenial as withlinuxtools

RUN echo "deb [trusted=yes] http://192.168.13.173:8080/repos/cinar/ amd64/"  >> /etc/apt/sources.list.d/cinar.list
RUN echo "deb [trusted=yes] http://192.168.13.173:8080/repos/new_interworking/ amd64/"  >> /etc/apt/sources.list.d/cinar.list
RUN echo "deb [trusted=yes] http://192.168.13.173:8080/repos/MC/ amd64/"  >> /etc/apt/sources.list.d/cinar.list
RUN echo "deb [trusted=yes] http://192.168.13.173:8080/repos/thirdparty/ amd64/"  >> /etc/apt/sources.list.d/cinar.list
RUN apt-get update

RUN apt-get install -y curl \
                       iputils-ping \
                       net-tools \
                       netcat \
                       socat \
                       tmux \
                       wget


FROM withlinuxtools as withdevelopmenttools
RUN apt-get install -y cpp-jwt \
                       cppcheck \
                       g++ \
                       g3log \
                       gdb \
                       git \
                       googletest \
                       default-jre \
                       dkms \
                       dpdk \
                       make \
                       nano \
                       python 
                    #    rabbitmq-server
#                      redis-server \
#                      redis-tools \


FROM withdevelopmenttools as withdevelopmentlibs
# RUN apt-get install -y  boost-all-dev \
#                         certificate \
#                         libncurses5-dev \
#                         libreadline-dev \
#                         libsasl2-dev \
#                         libssl-dev \
#                         libxml2 \
#                         libxerces-c-dev \
#                         libevent \
#                         libicu55 \
#                         libnghttp2-asio \
#                         libprometheuscpp \
#                         librabbitmq4 \
#                         libpq5 \
#                         mongo-c-driver \
#                         mongo-cxx-driver \
#                         nettle-dev \
#                         nlohmann-json \
#                         uuid-dev


FROM withdevelopmentlibs as withcinartoolsandlibs

# RUN apt-get install -y  cinarcodegenerator \
#                         cinarloggersink \
#                         cinarcryptolib \
#                         cinarframework-dbg

# RUN apt-get install -y cinarnnrfnfmanagement.15.201906-interworking.dbg \
#                        cinarnnrfnfdiscovery.15.201906-interworking.dbg \
#                        cinarnnrfaccesstoken.15.201906-interworking.dbg
# RUN echo  "/opt/cinar/lib" > /etc/ld.so.conf.d/cinar.conf; ldconfig;


# https://devopscube.com/docker-containers-as-build-slaves-jenkins/#Configure_a_Docker_Host_With_Remote_API_Important
FROM withcinartoolsandlibs

USER root
RUN echo "root:sifre" | chpasswd

# RUN mkdir -p /Source
# WORKDIR /root

# Make sure the package repository 6is up to date.
RUN apt-get -qy full-upgrade && \
# Install a basic SSH server
    apt-get install -qy openssh-server

RUN sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd && \
    mkdir -p /var/run/sshd && \
# Install JDK 8 (latest stable edition at 2019-04-01)
    apt-get install -qy openjdk-8-jdk && \
# Install maven
    # apt-get install -qy maven && \
# Cleanup old packages
    apt-get -qy autoremove

#ADD settings.xml /home/jenkins/.m2/

# RUN apt-get install sudo
# USER jenkins
# Set password for the jenkins user (you may want to alter this).
# Add user jenkins to the image
RUN useradd -rm -d /home/jenkins -s /bin/bash -g root -u 1001  -G sudo jenkins
# RUN adduser --quiet --disabled-password --shell /bin/bash --home /home/jenkins --gecos "jenkins" jenkins
RUN echo "jenkins:jenkins" | chpasswd

RUN mkdir /home/jenkins/.m2

# Copy authorized keys
RUN mkdir -p /home/jenkins/.ssh
RUN echo "" > /home/jenkins/.ssh/authorized_keys
# RUN chown -R jenkins:jenkins /home/jenkins/.m2/ && \
#     chown -R jenkins:jenkins /home/jenkins/.ssh/

# Standard SSH port
EXPOSE 22

# Sadece bir executable için root kullanıcısı gerekmez
# CMD ["/usr/sbin/sshd", "-D"]

# /sbin/init için root kullanıcısıyla devam etmek gerekiyor
USER root
ENTRYPOINT ["/sbin/init"]
