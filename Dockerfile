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

# Make sure the package repository 6is up to date.
RUN apt-get -qy full-upgrade && \
# Install a basic SSH server
    apt-get install -qy \
               sshpass \
               openssh-server \
               openjdk-8-jdk && \
# Cleanup old packages
    apt-get -qy autoremove

RUN sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd && \
    mkdir -p /var/run/sshd

USER root

#---------- SSL SERTİFİKALARI -----------------#
#                                              #
# bitbucket.ulakhaberlesme.com.tr adresine     #
# https ile giriş yapabilmek için sertifikaları#
# konteyner içine çekiyoruz.                   #
#                                              #
# git Bağlantılarında kullanılacak sertifika   #
# bitbucket sunucusuyla aynı olmasının ayarını #
# yapıyoruz.                                   #
#                                              #
#----------------------------------------------#
ADD http://192.168.13.47/ssl_certificate/ca-certificate.crt /etc/ssl/certs/
RUN update-ca-certificates
RUN git config --global http.sslCAinfo /etc/ssl/certs/ca-certificates.crt


#---------- SSH GENEL AYARLARI ----------------#
#                                              #
# SSH İle bu konteynere root kullanıcısının    #
# username & password ile giriş yapabilmesi    # 
# için ssh ayarlarında sshd_config ayarını     #
# değiştiriyoruz                               #
#                                              #
#----------------------------------------------#
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config


#---------- KULLANICI TANIMLARI ---------------#
#                                              #
# root ve jenkins Kullanıcılarını yansıya ekle #
#                                              #
#----------------------------------------------#

# root Kullanıcısı ----------------------------#
#                                              #
# Kullanıcı adı: root                          #
# Grubu: root                                  #
# Şifresi: cicd123                             #
# SSH Gizli Anahtarı: /root/.ssh/id_rsa        #
#                                              #
#----------------------------------------------#

RUN echo "root:cicd123" | chpasswd
# root kullanıcısı için public & private anahtar üretip değiştirilmez olarak işaretliyoruz
RUN mkdir -p /root/.ssh
RUN ssh-keygen -q -t rsa -N '' -f /root/.ssh/id_rsa
RUN chmod 600 /root/.ssh/id_rsa 
RUN chown -R root:root /root/.ssh

# Eğer bitbucket.ulakhaberlesme.com.tr adresine SSH yapıldığında hangi ayarların olacağını girelim:
# - bağlantı kurulduğunda sunucu bilgisinin known_hosts dosyasında olup olmadığını kontrol etme
RUN echo -e "Host bitbucket.ulakhaberlesme.com.tr\n\tStrictHostKeyChecking no\n" >> /root/.ssh/config 


# jenkins Kullanıcısı -------------------------#
#                                              #
# Kullanıcı adı: jenkins                       #
# Grubu: jenkins                               #
# Şifresi: jenkins                             #
# SSH Gizli Anahtarı: ~/jenkins/.ssh/id_rsa    #
#                                              #
#----------------------------------------------#
# RUN adduser --quiet --disabled-password --shell /bin/bash --home /home/jenkins --gecos "jenkins" jenkins
RUN groupadd -g 1000 jenkins
RUN useradd -rm -d /home/jenkins -s /bin/bash -g jenkins -u 1000 jenkins
RUN echo "jenkins:jenkins" | chpasswd
USER jenkins
#---------- SSH ANAHTARLARI ---------------#
# jenkinskullanıcısı için public & private anahtar üretip değiştirilmez olarak işaretliyoruz
RUN mkdir -p /home/jenkins/.ssh

#---------- ~/.ssh/authorized_keys ---------------#
# Ortak anahtar, SSH ile oturum açabilmek istediğiniz uzak bir sunucuya yüklenir. 
# Anahtar, oturum açacağınız kullanıcı hesabındaki özel bir dosyaya eklenir.
# Bir istemci SSH anahtarlarını kullanarak kimlik doğrulamayı denediğinde, sunucu istemcinin özel anahtara sahip olup olmadığını test edebilir.
# İstemci özel anahtarın sahibi olduğunu kanıtlayabilirse, bir kabuk oturumu oluşturulur veya istenen komut yürütülür.
RUN echo "" > /home/jenkins/.ssh/authorized_keys
# 
RUN ssh-keygen -q -t rsa -N '' -f /home/jenkins/.ssh/id_rsa
RUN chmod 600 /home/jenkins/.ssh/id_rsa
RUN chown -R jenkins /home/jenkins/.ssh    
# Eğer bitbucket.ulakhaberlesme.com.tr adresine SSH yapıldığında hangi ayarların olacağını girelim:
# - bağlantı kurulduğunda sunucu bilgisinin known_hosts dosyasında olup olmadığını kontrol etme
RUN echo -e "Host bitbucket.ulakhaberlesme.com.tr\n\tStrictHostKeyChecking no\n" >> /home/jenkins/.ssh/config 


# USER root
#---------- DNS ÇÖZÜMLEMESİ -------------------#
#                                              #
# repo adresi olan alanadi.com.tr adresine     #
# erişmesi için /etc/hosts dosyasına           #
# echo "192.168.16.12 alanadi" >> /etc/hosts   #
# /etc/hosts dosyasına girdi yapsak bile       #
# konteyner oluşturulurken geri alınacağı için #
# konteyner oluşturma komutuna arguman olarak  #
# gireceğiz:                                   #
#   --add-host alanadi.com.tr:192.168.16.12    #
#                                              #
#----------------------------------------------#
# RUN echo "192.168.10.14 bitbucket.ulakhaberlesme.com.tr" >> /etc/hosts 

RUN mkdir -p /home/jenkins/workspace
RUN chown -R jenkins:jenkins /home/jenkins/workspace

RUN curl --create-dirs -fsSLo /usr/share/jenkins/agent.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${VERSION}/remoting-${VERSION}.jar 
RUN chown -R jenkins:jenkins /usr/share/jenkins
RUN chmod 755 /usr/share/jenkins
RUN chmod 644 /usr/share/jenkins/agent.jar
RUN ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar 

# Standard SSH port
EXPOSE 22

# Sadece bir executable için root kullanıcısı gerekmez
# CMD ["/usr/sbin/sshd", "-D"]

# /sbin/init için root kullanıcısıyla devam etmek gerekiyor
USER jenkins
WORKDIR /home/jenkins
ENTRYPOINT ["/sbin/init"]
