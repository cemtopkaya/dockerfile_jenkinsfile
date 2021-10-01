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

RUN apt-get install -y socat \
                        tmux \
                        curl \
                        wget \
                        net-tools \
                        netcat \
                        iputils-ping \
                        sudo


FROM withlinuxtools as withdevelopmenttools
RUN apt-get install -y g++ \
                        gdb \
                        git \
                        cpp-jwt \
                        dkms \
                        python \
                        nano \
                        g3log \
                        default-jre\
                        cppcheck 
#                       rabbitmq-server \
#                       dpdk \
#                       redis-server \
#                       redis-tools \



FROM withdevelopmenttools as withdevelopmentlibs
RUN apt-get install -y  boost-all-dev  \
                        libncurses5-dev  \
                        libreadline-dev  \
                        libsasl2-dev  \
                        libssl-dev  \
                        libxml2  \
                        nettle-dev  \
                        uuid-dev  \
                        libxerces-c-dev  \
                        libevent  \
                        libicu55  \
                        libnghttp2-asio  \
                        libprometheuscpp  \
                        nlohmann-json  \
                        certificate \
                        mongo-c-driver  \
                        mongo-cxx-driver  \
                        librabbitmq4  \
                        libpq5
# cinarcodegenerator \
# cinarloggersink  \

FROM withdevelopmentlibs

USER root
WORKDIR /root
RUN mkdir -p /Source

ENTRYPOINT ["/sbin/init"]
