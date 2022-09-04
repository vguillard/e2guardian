####
### BUILD STAGE
### -----------
###

FROM lsiobase/alpine:amd64-3.8 as builder
SHELL ["/bin/bash", "-c"]

# e2guardian prep and configuration
RUN \
  apk add --update --no-cache curl gcc libc-dev argp-standalone linux-headers && \
  apk add --update --no-cache automake make autoconf g++ zlib-dev openssl openssl-dev
RUN \
  curl -O -s -L https://github.com/e2guardian/e2guardian/archive/v5.3.5.tar.gz && \
  curl -O http://dsi.ut-capitole.fr/blacklists/download/blacklists_for_dansguardian.tar.gz && tar xzf blacklists_for_dansguardian.tar.gz && \
  tar xzf v5.3.5.tar.gz 
RUN \
  cd e2guardian-5.3.5/ && \
  ./autogen.sh && \
  ./configure  '--prefix=/app/' '--sysconfdir=/app/' '--with-sysconfsubdir=etc' '--with-proxyuser=e2guardian' '--with-proxygroup=e2guardian'  '--enable-clamd=yes'  '--localstatedir=/var' '--enable-icap=no' '--enable-commandline=yes' '--enable-email=no' '--enable-ntlm=no' '--mandir=${prefix}/share/man' '--infodir=${prefix}/share/info' '--enable-pcre=no' '--enable-sslmitm=yes' 'CPPFLAGS=-mno-sse2 -g -O2' && \
  make && make install
RUN \
  echo '######## Enable dockermode ########' && \
  sed -i "s|^.\{0,1\}dockermode = off$|dockermode = on|g" /app/etc/e2guardian.conf  && \
  echo '######## Extract blacklist ########' && \
  tar xzf blacklists_for_dansguardian.tar.gz -C /app/etc/lists/ && \
  echo '######## Use some blacklists #####' && \
  echo '.Include</app/etc/lists/blacklists/adult/domains>\n\
.Include</app/etc/lists/blacklists/aggressive/domain>\n\
.Include</app/etc/lists/blacklists/drugs/domains>\n\
.Include</app/etc/lists/blacklists/gambling/domains>\n\
.Include</app/etc/lists/blacklists/porn/domains>\n\
.Include</app/etc/lists/blacklists/violence/domains>\n\
.Include</app/etc/lists/blacklists/virusinfected/domains>\n\
.Include</app/etc/lists/blacklists/warez/domains>\n'\
  >/app/etc/lists/bannedsitelist

COPY conf/lists/* /app/etc/lists/

COPY app/sbin/* /app/sbin/

# Set permissions and backup /config directory
RUN \
    echo '######## Set permissions for /app/sbin scripts ########' && \
    chmod u+x /app/sbin/e2g-mitm.sh /app/sbin/entrypoint.sh 
#    tar czf /app/config.gz /config


###
### RUNTIME STAGE
### -------------
###

FROM alpine:3.8

ENV PATH="${PATH}:/app/sbin" \
    PUID="1000" \
    PGID="1000" \
    E2G_MITM=${E2G_MITM:-"on"}


VOLUME /app/etc/ /app/log /app/etc/lists/blacklists/

COPY --from=builder /app /app

RUN \
    echo '######## Install required packages ########' && \
    apk add --update --no-cache libgcc libstdc++ pcre openssl shadow tini tzdata && \
    \
    echo '######## Modify openssl.cnf ########' && \
    echo -e \
        '[ ca ] \n'\
        'basicConstraints=critical,CA:TRUE \n' \
        >> /etc/ssl/openssl.cnf && \
    \
    echo '######## Create e2guardian account ########' && \
    groupmod -g 1000 users && \
    useradd -u 1000 -U -d /app/e2guardian/config -s /bin/false e2guardian && \
    usermod -G users e2guardian && \
    mkdir /var/log/e2guardian && \
    chown -R e2guardian.e2guardian /var/log/e2guardian/ && \
    \
    echo '######## Clean-up ########' && \
    rm -rf /tmp/* /var/cache/apk/*

EXPOSE 8080

ENTRYPOINT ["/sbin/tini","-vv","-g","--","/app/sbin/entrypoint.sh"]

