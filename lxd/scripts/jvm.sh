#!/usr/bin/env bash
source /etc/os-release
JAVA_11_URL="https://travis-java-archives.s3.amazonaws.com/binaries/${ID}/${VERSION_ID}/$(uname -m)/linux-openjdk11.tar.bz2"

set -o errexit

source /tmp/__common-lib.sh

main() {
  set -o xtrace
  export DEBIAN_FRONTEND='noninteractive'
  __install_packages
  call_build_function func_name="__java"
}

__install_packages() {
  apt-get update -yqq
  apt-get install -yqq --no-install-suggests --no-install-recommends  \
  libasound2 libcups2 libfontconfig1 libxrender1 libxext6 libx11-6 \
  libnss3 libgcc1 util-linux zlib1g libstdc++6 libpcsclite1 libfreetype6 libjpeg8 liblcms2-2 libxtst6 wget;
}

__install_java(){
  JAVA_URL="JAVA_${JAVA_VERSION}_URL"

  if [ -z ${!JAVA_URL} ];then
    echo "There is no JAVA in version ${JAVA_VERSION}"
    exit 1
  fi

  mkdir -p /usr/local/lib/java${JAVA_VERSION}
  curl -s ${!JAVA_URL} | tar xjf - -C /usr/local/lib/java${JAVA_VERSION} --strip-components 1
}


__java(){
  __install_java
  __setup_jvm
}

__setup_jvm(){
  echo "if [[ -d /usr/local/lib/java${JAVA_VERSION} ]]; then
  export JAVA_HOME=/usr/local/lib/java${JAVA_VERSION}
  export PATH="\$JAVA_HOME/bin:\$PATH"
fi
" > /home/travis/.bash_profile.d/travis-java.bash
  chmod 644 /home/travis/.bash_profile.d/travis-java.bash
  chown travis:travis /home/travis/.bash_profile.d/travis-java.bash
}

#bionic
__java_bionic(){
  echo "No installing java on bionic"
}


__java_xenial_ppc64le(){
  echo "No installing java on xenial ppc64le"
}


main "$@"