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

ARG VERSION=4.10
ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=2000
ARG AGENT_WORKDIR=/home/${user}/agent

# Make sure the package repository 6is up to date.
RUN apt-get -qy full-upgrade && \
# Install a basic SSH server
    apt-get install -qy \
               sudo \
               sshpass \
               openssh-server \
               openjdk-8-jdk && \
# Cleanup old packages
    apt-get -qy autoremove && \
    rm -rf /var/lib/apt/lists/*

RUN sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd && \
    mkdir -p /var/run/sshd

USER root

#---------- SSL SERTİFİKALARI ----------------------------------------------------------------------------------------#
#                                                                                                                     #
# bitbucket.ulakhaberlesme.com.tr adresine https ile giriş yapabilmek için sertifikaları konteyner içine çekiyoruz.   #
# git Bağlantılarında kullanılacak sertifika bitbucket sunucusuyla aynı olmasının ayarını yapıyoruz.                  #
#                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------#
ADD http://192.168.13.47/ssl_certificate/ca-certificate.crt /etc/ssl/certs/
RUN update-ca-certificates
RUN git config --global http.sslCAinfo /etc/ssl/certs/ca-certificates.crt


#---------- SSH GENEL AYARLARI ---------------------------------------------------------------------------------------#
#                                                                                                                     #
# SSH İle bu konteynere root kullanıcısının username & password ile giriş yapabilmesi için ssh ayarlarında            #
# sshd_config ayarını değiştiriyoruz                                                                                  #
#                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------#
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
#---------- SSH root KULLANICI AYARLARI --------------------------------------------------------------------------------------------------------------------------
#                                                                                                                                                                 #
# PUBLIC anahtara ortak, PRIVATE anahtara gizli anahtar diyelim.                                                                                                  #
#                                                                                                                                                                 #
# >>>> mkdir -p /root/.ssh                                                                                                                                        #
# ~/.ssh dizininde private ve public anahtarlar yaratacağız.                                                                             .                        #
#                                                                                                                                                                 #
# >>>> ssh-keygen -q -t rsa -N '' -f /root/.ssh/id_rsa                                                                                                            #
# -t rsa >> Gizli anahtarı RSA şifreleme ile üret                                                                                                                 #
# -f /root/.ssh/id_rsa >> Ürettiğin gizli anahtarı id_rsa adındaki dosyaya, açığı ise id_rsa.pub dosyasına çıkar.                                                 #
# -N '' >> Gizli anahtarı her kullanmak istediğimizde parola sormasın diye şifresiz oluşturacağız                                                                 #
#                                                                                                                                                                 #
# >>>> chmod 600 /root/.ssh/id_rsa                                                                                                                                #
# Gizli anahtara sadece sahibi erişip okuyabilir veya silebilir (silinmez olması daha iyi olur).                                                                  #
# -rw------- /root/.ssh/id_rsa                                                                                                                                    #
#                                                                                                                                                                 #
# >>>> chown -R root:root /root/.ssh                                                                                                                              #
# .ssh Dizinine sadece kullanıcı sahip olmalı                                                                                                                     #
# Ayar dosyasını sadece sahibi erişip değiştirebilir ama diğerleri okuyabilir                                                                                     #
# -rw-r--r-- /root/.ssh/config                                                                                                                                    #
#                                                                                                                                                                 #
# Ortak anahtarı, SSH ile oturum açabilmek istediğiniz uzak bir sunucuya kopyalayacağız.                                                                          #
# Bitbucket, github gibi sunucularda kullanıcı doğrulaması için açık anahtarı kullanıcı bilgisi olarak kullancağız.                                               #
# Uzun ve karışık olduğu için kullanıcı adı olarak kullanılabilir ayrıca sunucu bu anahtarı kullanarak şifreli olarak veri akışını gerçekleştirecek.              #
#                                                                                                                                                                 #
# ~/.ssh/config DOSYASININ İÇERİĞİ                                                                                                                                #
# Ref: https://www.cyberciti.biz/faq/create-ssh-config-file-on-linux-unix/                                                                                        #
#                                                                                                                                                                 #
# Host bitbucket.ulakhaberlesme.com.tr                                                                                                                            #
#   HostName 192.168.10.14                                                                                                                                        #
#   IdentityFile ~/.ssh/id_rsa_bb                                                                                                                                 #
#   StrictHostKeyChecking no                                                                                                                                      #
#                                                                                                                                                                 #
# git clone ssh://git_kullanici_adi@alanadi.com/kod_deposu_adı/kodDeposu.git komutu şunlara neden olur:                                                           #
#  - ssh protokolü yapılacakmış (ssh://...)                                                                                                                       #
#  - ~/.ssh/config dosyasını oku ve alanadi.com adresiyle tanımlı ayarlara eriş                                                                                   #
#    o) Varsayılan olarak uzak sunucuyu bilinen "bilinen sunucular (known_hosts)" dosyasında sorgular                                                             #
#       StrictHostKeyChecking no  >> ayarıyla sunucunun IP bilgisini "bilinen sunucular (known_hosts)" dosyasında aramaz                                          #
#       StrictHostKeyChecking yes >> olsaydı ve ~/.ssh/known_hosts dosyasında kayıtlı olmasaydı aşağıdaki hatayı alırdık:                                         #
#                                                                                                                                                                 #
#           No RSA host key is known for [192.168.10.14]:7999 and you have requested strict checking.                                                             #
#           Host key verification failed.                                                                             .                                           #
#           fatal: Could not read from remote repository.                                                                             .                           #
#                                                                                                                                                                 #
#    o) IdentityFile ~/.ssh/id_rsa_bb >> hangi açık anahtar ile bu bağlantıyı doğrulamasını istediğimizi belirtiriz.                                              #
#       IdentityFile belirtilmezse varsayılan dosyayı (~/.ssh/id_rsa) kullanır                                                                                    #
#                                                                                                                                                                 #
#    o) HostName  192.168.10.14  >> ister bağlantı kuracağımız uzak makinanın adı (ulakhaberlesme.com.tr ister IP adresi olur)                                    #
#                                                                                                                                                                 #
# Anahtar, oturum açacağınız kullanıcı hesabındaki özel bir dosyaya eklenir.                                                                             .        #
# Bir istemci SSH anahtarlarını kullanarak kimlik doğrulamayı denediğinde, sunucu istemcinin özel anahtara sahip olup olmadığını test edebilir.                   #
# İstemci özel anahtarın sahibi olduğunu kanıtlayabilirse, bir kabuk oturumu oluşturulur veya istenen komut yürütülür.                                            #
#                                                                                                                                                                 #
# Bilinen Sunucular (known_hosts)                                                                                                                                 #
# bitbucket.ulakhaberlesme.com.tr Adresini known_hosts içinden çıkar                                                                                              #
# RUN sh 'ssh-keyscan -R bitbucket.ulakhaberlesme.com.tr'                                                                                                         #
#                                                                                                                                                                 #
# bitbucket.ulakhaberlesme.com.tr Adresini known_hosts'a ekle                                                                                                     #
# RUN sh 'ssh-keyscan -H bitbucket.ulakhaberlesme.com.tr >> ~/.ssh/known_hosts'                                                                                   #
#                                                                                                                                                                 #
# git clone ssh://kullanici@alanadi/repo_adresi/repo.git   komutu da alanadi adresini known_hosts'a ekleyecektir                                                  #
# git clone ssh://git@bitbucket.ulakhaberlesme.com.tr:7999/cin/yaml.git                                                                                           #
# Cloning into 'yaml'...                                                                                                                                          #
# Warning: Permanently added '[192.168.10.14]:7999' (RSA) to the list of known hosts.                                                                             #
# ......                                                                                                                                                          #
# cat /root/.ssh/known_hosts                                                                                                                                      #
# |1|2kMBR/fnEbbStRIffpMxkipQnH0=|YraZZ6qcAiOToZj06rDvfiSN63E= ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDLQUxlwuPRWM1atW3aPulUmwpR4paC1Zxae0ZMqSNSCkaGyBMqyjlKmy9eg  #
#                                                                                                                                                                 #
#                                                                                                                                                                 #
# JENKINS ÜSTüNDEN GIT CLONE                                                                                                                                      #
# Jenkins MASTER ve SLAVE üstünden git işlemini yapabiliriz                                                                                                       #
# MASTER üstünden shell script ile veya git plugin'ini kullanarak git clone işlemi yapabiliriz:                                                                   #
#  1) sh 'git clone ssh://git@......'                                                                                                                             #
#     sh Nerede çalışıyorsa (master veya slave) o sistem üstünde ssh ayarlarını okuyarak doğrulama yapacaktır                                                     #
#     - Kullanıcı adı ve şifresini sizden girmenizi bekleyerek doğrulama yaparsa JENKINS çakılır çünkü arka planda çalışacağı için sizin girişiniz mümkün olmaz   #
#     - ~/.ssh/config içinde tanımlanmış IdentityFile ile belirtilmiş açık-gizli anahtarı kendisi bulup doğrulama yapabilir.                                      #
#                                                                                                                                                                 #
#  2) git changelog: false, credentialsId: 'aa', poll: false, url: 'ssh://git@bitbucket.ulakhaberlesme.com.tr:7999/cin/yaml.git'                                  #
#     plugin jenkins master üstünde çalışarak credential manager kısmında tanımlı aa kullanıcı bilgilerine göre doğrulama yaparak git clone ile indirdiği veriyi  #
#     slave olan jenkins agent'a kendi dizinini bağladığı yol ile paylaşır. Aşağıda master Jenkins agent Jenkinsfile içinde agent olarak docker agent yaratır:    #
#                                                                                                                                                                 #
#     pipeline {                                                                                                                                                  #
#        agent {                                                                                                                                                  #
#            docker {                                                                                                                                             #
#                image 'slave_agent_yansi'                                                                                                                        #
#            }                                                                                                                                                    #
#        }                                                                                                                                                        #
#        stages {                                                                                                                                                 #
#            stage('Test') {                                                                                                                                      #
#                steps {                                                                                                                                          #
#                    git credentialsId: 'aa', url: 'ssh://git@bitbucket.ulakhaberlesme.com.tr:7999/cin/yaml.git'                                                  #
#                }                                                                                                                                                #
#            }                                                                                                                                                    #
#        }                                                                                                                                                        #
#     }                                                                                                                                                           #
#                                                                                                                                                                 #
#     - SSH bağlantı için "SSH username with private key" türünde "aa" adında bir credential Jenkins üstünde oluşturulur                                          #
#     - Job çalıştırıldığında önce agent için docker yansısından bir konteyner oluşturulur ve WORKDIR olarak /var/jenkins_home_workspace/pipe3 dizinine geçilir   #
#     - Master Jenkins içindeki dışarıya VOLUME ile açılmış dizin aynı dizin yoluyla --volumes-from anahtarıyla bu konteynere bağlanır:                           #
#        -> docker inspect 25fd9afdc822563ed2cad1cde288a3e45e193e04d06c4b9ca91e9a7d9d607d3f komutunu çalıştırıp dışarıya açılmış volume gözlenir:                 #
#        -> "Volumes": {                                                                                                                                          #
#               "/var/jenkins_home": {}                                                                                                                           #
#           },                                                                                                                                                    #
#                                                                                                                                                                 #
#     docker run -t -d -u 0:0                                                                                                                                     #
#            -w /var/jenkins_home/workspace/pipe3                                                                                                                 #
#            --volumes-from 25fd9afdc822563ed2cad1cde288a3e45e193e04d06c4b9ca91e9a7d9d607d3f -e ******** ...                                                      #
#            slave_agent_yansi cat                                                                                                                                #
#                                                                                                                                                                 #
#     - Kısaca, git eklentisi kod havuzunu MASTER JENKINS içindeki /var/jenkins_home/workspace/pipe3 dizinine indirir ve konteyner içine bu dizini map ettiği için#
#       konteyner içinde erişilebilir olur. Ama JENKINS master 10.10.0.1 makinasında ve DOCKER_HOST bilgisi 10.10.10.100 makinasını işaret ediyorsa, konteyner    #
#       .100 makinasında oluşacağı için --volumes-from ile dizin bağlama çalışmayacaktır. Kod havuzu MASTER içindeki /var/jenkins_home/workspace/pipe3 dizinine   #
#       indirilecek ancak DOCKER_HOST ile belirtilmiş makinaya bağlanmadığı için konteynere bağlanamayacak.                                                       #
#                                                                                                                                                                 #
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------#

# root kullanıcısı için public & private anahtar üretip değiştirilmez olarak işaretliyoruz
RUN mkdir -p /root/.ssh
RUN ssh-keygen -q -t rsa -N '' -f /root/.ssh/id_rsa_bb
RUN chmod 600 /root/.ssh/id_rsa_bb
RUN chown -R root:root /root/.ssh

RUN cat << EOF > /root/.ssh/config \
Host bitbucket.ulakhaberlesme.com.tr\
    HostName 192.168.10.14\
    IdentityFile ~/.ssh/id_rsa_bb\
    StrictHostKeyChecking no\
EOF


# jenkins Kullanıcısı -------------------------#
#                                              #
# Kullanıcı adı: jenkins                       #
# Grubu: jenkins                               #
# Şifresi: jenkins                             #
# SSH Gizli Anahtarı: ~/jenkins/.ssh/id_rsa    #
#                                              #
#----------------------------------------------#
# RUN adduser --quiet --disabled-password --shell /bin/bash --home /home/jenkins --gecos "jenkins" jenkins
RUN groupadd -g ${gid} ${group}

# -m : ev dizini oluştur (/home/kullanıcı_adı)
# -M : ev dizini yaratma
# -N : kullanıcı oluştur, grup oluşturma
# -r : Sistem kullanıcısı oluştur
# -d : /home/kullanıcı_adı haricinde bir başka yerde ev dizini yarat (-d /var/jenkins)
# -g : Grup yarat (-g yazilimci > yazilimci grubu yaratır)
# -G : Oluşturulan kullanıcıyı gruplara ekle (-G sudo,developers,muhasebeciler)
# -s : Varsaylan shell ataması yap (-s /bin/sh > kullanıcı girdiğinde sh konsolu olur)
RUN useradd -c "Jenkins kullanicisi" -d /home/${user} -u ${uid} -g ${gid} -m -G sudo -s /bin/bash ${user}
RUN echo "jenkins:jenkins" | chpasswd

# sudoer olarak ekle ve sudo komutları için şifre sorma
RUN echo "jenkins  ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers.d/jenkins
RUN chmod 0440 /etc/sudoers.d/jenkins

USER jenkins
#---------- SSH ANAHTARLARI ---------------#

#---------- ~/.ssh/authorized_keys -----------------------------------------------------------------------------------------#
# Eğer bu makinaya jenkins kullanıcısıyla SSH üstünden                                                                      #
# erişim sağlanmak istenirse kullanıcı doğrulama açık/gizli                                                                 #
# anahtar üstünden yapılacaksa, doğrulamada kullanılacak                                                                    #
# açık anahtar .ssh/authorized_keys dosyasına yazılabilir                                                                   #
#                                                                                                                           #
# Master Jenkins node bu agent'a SSH üstünden erişmek isterse                                                               #
# authorized_keys dosyasına MASTER JENKINS'in açık anahtarını yazmak gerekir                                                #
#                                                                                                                           #
# authorized_keys DOSYASININ İÇERİĞİ                                                                                        #
#                                                                                                                           #
# # 192.168.2.* aralığındaki herekese (tüm alt ağa -subnet-) izin ver                                                       #
# # 192.168.2.0/24 >> 8 bit (192 için) + 8 bit (168 için) + 8 bit (2 için) = 24                                             #
# # Tüm alt ağa sadece bu adrese izin verme: 192.168.2.25                                                                   #
# from="!192.168.2.25,192.168.2.*" ssh-ed25519 açık_anahtarı_buraya_yapıştır uzak_bağlantı_yapacak_kullanıcı_adı@makina_adı #
#                                                                                                                           #
# # Aynı şekilde IP aralığı yerine alan adına izin verebiliriz:                                                             #
# # *.sweet.home alanına izin VER ama router.sweet.home alanına VERME                                                       #
# from="!router.sweet.home,*.sweet.home" ssh-ed25519 my_random_pub_key_here jenkins@172.17.0.2                              #
#                                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------#
# RUN echo "from="!192.168.2.25,192.168.2.*" ssh-ed25519 xxxx jenkins@localhost" >> /home/jenkins/.ssh/authorized_keys

RUN mkdir -p /home/jenkins/.ssh
RUN echo "" > /home/jenkins/.ssh/authorized_keys

RUN ssh-keygen -q -t rsa -N '' -f /home/jenkins/.ssh/id_rsa_bb
RUN chown -R jenkins /home/jenkins/.ssh
RUN chmod 600 /home/jenkins/.ssh/id_rsa_bb
RUN cat << EOF > /root/.ssh/config \
Host bitbucket.ulakhaberlesme.com.tr\
    HostName 192.168.10.14\
    Port 7999\
    IdentityFile ~/.ssh/id_rsa_bb\
    StrictHostKeyChecking no\
EOF



#---------- DNS ÇÖZÜMLEMESİ -------------------------------------------#
#                                                                      #
# repo adresi olan alanadi.com.tr adresine erişmesi için /etc/hosts    #
# dosyasına `echo "192.168.16.12 alanadi" >> /etc/hosts` komutuyla     #
# /etc/hosts dosyasına girdi yapsak bile konteyner oluşturulurken      #
# geri alınacağı için konteyner oluşturma komutuna arguman olarak      #
# gireceğiz:                                                           #
#   --add-host alanadi.com.tr:192.168.16.12                            #
#                                                                      #
#----------------------------------------------------------------------#
# RUN echo "192.168.10.14 bitbucket.ulakhaberlesme.com.tr" >> /etc/hosts

RUN mkdir -p /home/jenkins/workspace
RUN chown -R jenkins:jenkins /home/jenkins/workspace

USER root
RUN curl --create-dirs -fsSLo /usr/share/jenkins/agent.jar \
        https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${VERSION}/remoting-${VERSION}.jar
RUN chown -R jenkins:jenkins /usr/share/jenkins
RUN chmod 755 /usr/share/jenkins
RUN chmod 644 /usr/share/jenkins/agent.jar
RUN ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar

# RUN sudo cat <<EOT >> /etc/systemd/jenkins-slave.service \
RUN sudo echo -e "[Unit]\n\
Description=Jenkins Slave\n\
Wants=network.target\n\
After=network.target\n\
\n\
[Service]\n\
ExecStart=/usr/bin/java -jar /usr/share/jenkins/agent.jar\n\
#ExecStart=/usr/bin/java -Xms512m -Xmx512m -jar /usr/share/jenkins/agent.jar\n\
#ExecStart=/usr/bin/java -Xms512m -Xmx512m -jar /usr/share/jenkins/agent.jar -jnlpUrl http://192.168.13.38:8080/slave-agent.jnlp -secret ${SECRET}\n\
User=root\n\
Restart=always\n\
RestartSec=10\n\
StartLimitInterval=0\n\
\n\
[Install]\n\
WantedBy=multi-user.target" >  /etc/systemd/system/jenkins-slave.service

RUN systemctl enable jenkins-slave.service


# Sadece bir executable için root kullanıcısı gerekmez
# CMD ["/usr/sbin/sshd", "-D"]

# /sbin/init için root kullanıcısıyla devam etmek gerekiyor
# USER jenkins

USER ${user}
ENV AGENT_WORKDIR=${AGENT_WORKDIR}
RUN mkdir /home/${user}/.jenkins && mkdir -p ${AGENT_WORKDIR}

VOLUME /home/${user}/.jenkins
VOLUME ${AGENT_WORKDIR}
WORKDIR /home/${user}

# Standard SSH port
EXPOSE 22/tcp
EXPOSE 8080/tcp

ENTRYPOINT ["/sbin/init"]
