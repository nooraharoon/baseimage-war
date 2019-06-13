# Strict mode
set -eu

echo "Installing dependencies"
apk update
apk --no-cache add \
  bash \
  bzip2 \
  ca-certificates \
  fontconfig \
  jq \
  openssh \
  openssl \
  python \
  py-jinja2 \
  py-pip \
  unzip \
  wget \
  zip

echo "Install specific version of PyYAML for awscli, fixes version conflict"
rm -rf /usr/lib/python3/dist-packages/PyYAML-*
pip install --ignore-installed 'pyyaml==3.13'  # awscli requires this version. Unfortunately it has CVE-2017-18342

echo "Installing tools for downloading environment configuration during service run script"
pip install --upgrade pip
pip install \
  awscli \
  docker-py \
  j2cli \
  jinja2 \
  jinja2-cli \
  pyasn1 \
  six
rm -rf /root/.cache

echo "Downloading glibc for compiling locale definitions"
GLIBC_VERSION="2.28-r0"
wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub
wget -q https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk
echo "f0a00f56fdee9dc888bafec0bf8f54fb188e99b5346032251abb79ef9c99f079  glibc-${GLIBC_VERSION}.apk" |sha256sum -c
wget -q https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk
echo "b9a0d8359b12a9768f6378156f160d40f8e432e78e0b2aabc9d0a81e216e7f49  glibc-bin-${GLIBC_VERSION}.apk" |sha256sum -c
wget -q https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-i18n-${GLIBC_VERSION}.apk
echo "948aa0a87b2b93cef561d31c02060a162d592a3545af56171c3f8b0d6f918a48  glibc-i18n-${GLIBC_VERSION}.apk" |sha256sum -c

echo "Installing glibc for compiling locale definitions"
apk add \
  glibc-${GLIBC_VERSION}.apk \
  glibc-bin-${GLIBC_VERSION}.apk \
  glibc-i18n-${GLIBC_VERSION}.apk
rm -v glibc-*.apk
/usr/glibc-compat/bin/localedef -i en_US -f UTF-8 en_US.UTF-8
/usr/glibc-compat/bin/localedef -i fi_FI -f UTF-8 fi_FI.UTF-8

echo "Creating cache directories for package managers"
mkdir /root/.m2/
mkdir /root/.ivy2/

echo "Downloading Java JDK"
FILES_URL_PREFIX="https://oph-public-files.s3-eu-west-1.amazonaws.com/${DL_PATH_TOKEN}/jdk"
JDK_PACKAGE="jdk-8u202-linux-x64.tar.gz"
JCE_PACKAGE="jce_policy-8.zip"
wget -c -q -P /tmp/ ${FILES_URL_PREFIX}/${JDK_PACKAGE}
echo "9a5c32411a6a06e22b69c495b7975034409fa1652d03aeb8eb5b6f59fd4594e0  /tmp/${JDK_PACKAGE}" |sha256sum -c
wget -c -q -P /tmp/ ${FILES_URL_PREFIX}/${JCE_PACKAGE}
echo "f3020a3922efd6626c2fff45695d527f34a8020e938a49292561f18ad1320b59  /tmp/${JCE_PACKAGE}" |sha256sum -c

echo "Installing Java JDK"
mkdir -p /usr/java/latest
tar xf /tmp/${JDK_PACKAGE} -C /usr/java/latest --strip-components=1
ln -s /usr/java/latest/bin/* /usr/bin/
unzip -jo -d /usr/java/latest/jre/lib/security /tmp/${JCE_PACKAGE}

echo "Removing unused JDK sources and libraries"
rm /usr/java/latest/jre/lib/security/README.txt
rm -rf /usr/java/latest/*src.zip
rm -rf /usr/java/latest/lib/missioncontrol
rm -rf /usr/java/latest/lib/visualvm
rm -rf /usr/java/latest/lib/*javafx*
rm -rf /usr/java/latest/jre/lib/plugin.jar
rm -rf /usr/java/latest/jre/lib/ext/jfxrt.jar
rm -rf /usr/java/latest/jre/bin/javaws
rm -rf /usr/java/latest/jre/lib/javaws.jar
rm -rf /usr/java/latest/jre/lib/desktop
rm -rf /usr/java/latest/jre/plugin/
rm -rf /usr/java/latest/jre/lib/deploy*
rm -rf /usr/java/latest/jre/lib/*javafx*
rm -rf /usr/java/latest/jre/lib/*jfx*
rm -rf /usr/java/latest/jre/lib/amd64/libdecora_sse.so
rm -rf /usr/java/latest/jre/lib/amd64/libprism_*.so
rm -rf /usr/java/latest/jre/lib/amd64/libfxplugins.so
rm -rf /usr/java/latest/jre/lib/amd64/libglass.so
rm -rf /usr/java/latest/jre/lib/amd64/libgstreamer-lite.so
rm -rf /usr/java/latest/jre/lib/amd64/libjavafx*.so
rm -rf /usr/java/latest/jre/lib/amd64/libjfx*.so

echo "Installing Prometheus jmx_exporter"
JMX_EXPORTER_VERSION="0.3.1"
wget -q https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/${JMX_EXPORTER_VERSION}/jmx_prometheus_javaagent-${JMX_EXPORTER_VERSION}.jar
mv jmx_prometheus_javaagent-${JMX_EXPORTER_VERSION}.jar jmx_prometheus_javaagent.jar
echo "2a25e74e7af7f4e63c227bf5d0d0a4da9b6b146ce521eca58fcde3bf803f1974  jmx_prometheus_javaagent.jar" |sha256sum -c

echo "Installing Prometheus node_exporter"
NODE_EXPORTER_VERSION="0.15.1"
wget -q https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
echo "7ffb3773abb71dd2b2119c5f6a7a0dbca0cff34b24b2ced9e01d9897df61a127  node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz" |sha256sum -c
tar -xvzf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
rm node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
mv node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /root/
rm -rf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64

echo "Init Prometheus config file"
echo "{}" > /root/prometheus.yaml

echo "Installing Tomcat"
TOMCAT_DL_PREFIX="https://archive.apache.org/dist/tomcat/tomcat-7/v7.0.88/bin"
TOMCAT_PACKAGE="apache-tomcat-7.0.88.tar.gz"
wget -c -q -P /tmp/ ${TOMCAT_DL_PREFIX}/${TOMCAT_PACKAGE}
echo "675abed4e71e95793f549a2077d891e28f2f8e3427aca180d2ff6607be8885be  /tmp/${TOMCAT_PACKAGE}" |sha256sum -c
mkdir -p /opt/tomcat
tar xf /tmp/${TOMCAT_PACKAGE} -C /opt/tomcat --strip-components=1
rm -rf /opt/tomcat/webapps/*

echo "Copying Tomcat configuration"
mkdir -p /root/oph-configuration/
mv /tmp/tomcat-config/server.xml /opt/tomcat/conf/
mv /tmp/tomcat-config/ehcache.xml /root/oph-configuration/
mv /tmp/tomcat-config/jars/*.jar /opt/tomcat/lib/

echo "Clearing temp directory"
rm -rf /tmp/tomcat-config
rm -rf /tmp/*.tar.gz
rm -rf /tmp/*.zip
rm -rf /tmp/hsperfdata_root
ls -la /tmp/

echo "Make run script executable"
chmod ug+x /tmp/scripts/run
