FROM alpine
MAINTAINER Paul Pham <docker@aquaron.com>

ENV \
 _etc=/etc/nginx \
 _root=/usr/share/nginx \
 _log=/var/log/nginx \
 _sock=/tmp/cgi.sock \
 PERL5LIB=/usr/share/nginx/lib

COPY conf/nginx.conf $_etc/nginx.conf
COPY conf/conf.d/* $_etc/conf.d/
COPY bin/* /usr/bin/
COPY misc/* /tmp/

RUN apk add --no-cache \
 nginx \
 fcgiwrap \
 perl \
 make \
 curl \
 wget \
 gcc \
 g++ \
 perl-dev \
 mysql-dev \

&& ln -s /usr/bin/perl /usr/local/bin/perl \
&& mkdir -p $_root/cgi; ln -s /usr/bin/printenv $_root/cgi \
&& curl -L http://cpanmin.us -o /usr/bin/cpanm; chmod +x /usr/bin/cpanm \
&& cpanm -n \
 CGI JSON \
 DBD::mysql@4.037 \
 Apache::Session::MySQL \
 Redis \
 Crypt::ScryptKDF \
 Crypt::CBC \
 File::Slurp \
 CSS::Inliner \

&& mv /tmp/bash-prompt ~/.profile \
&& patch -p0 < /tmp/Badger-Debug.patch \
&& apk del g++ gcc make perl-dev curl wget

EXPOSE 8080
VOLUME $_root $_log $_etc
CMD ["/usr/bin/nginx-fcgi"]
