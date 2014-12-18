FROM ubuntu:14.04

MAINTAINER Andrew Fecheyr <andrew@bedesign.be>

ENV PHANTOMJS_VERSION 1.9.7
ENV NODE_VERSION 0.11.14
ENV NPM_VERSION 2.1.3
ENV RUBY_VERSION ruby2.1

ENV REDIS_VERSION 2.8.17
ENV REDIS_DOWNLOAD_SHA1 913479f9d2a283bfaadd1444e17e7bab560e5d1e

RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y build-essential autoconf imagemagick libmysqlclient-dev
RUN apt-get install -y wget libfreetype6 libfontconfig bzip2 git

# Install phantomjs
# From https://github.com/cmfatih/dockerhub
RUN \
  wget -q --no-check-certificate -O /tmp/phantomjs-$PHANTOMJS_VERSION-linux-x86_64.tar.bz2 https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-$PHANTOMJS_VERSION-linux-x86_64.tar.bz2 && \
  tar -xjf /tmp/phantomjs-$PHANTOMJS_VERSION-linux-x86_64.tar.bz2 -C /tmp && \
  rm -f /tmp/phantomjs-$PHANTOMJS_VERSION-linux-x86_64.tar.bz2 && \
  cp /tmp/phantomjs-$PHANTOMJS_VERSION-linux-x86_64/bin/phantomjs /usr/bin/phantomjs && \
  rm -rf /tmp/phantomjs-$PHANTOMJS_VERSION-linux-x86_64/

# Install Ruby
# From http://brightbox.com/docs/ruby/ubuntu/
RUN \
  apt-get install -y software-properties-common && \
  apt-add-repository ppa:brightbox/ruby-ng && \
  apt-get update && \
  apt-get install -y $RUBY_VERSION $RUBY_VERSION-dev && \
  gem install bundler --no-document

# Install NPM
# From https://github.com/docker-library/node
# TODO: This leaves dirty bits in /usr/local
# verify gpg and sha256: http://nodejs.org/dist/v0.10.31/SHASUMS256.txt.asc
# gpg: aka "Timothy J Fontaine (Work) <tj.fontaine@joyent.com>"
RUN gpg --keyserver pgp.mit.edu --recv-keys 7937DFD2AB06298B2293C3187D33FF9D0246406D
RUN \
  wget -q "http://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz" && \
  wget -q "http://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" && \
  gpg --verify SHASUMS256.txt.asc && \
  grep " node-v$NODE_VERSION-linux-x64.tar.gz\$" SHASUMS256.txt.asc | sha256sum -c - && \
  tar -xzf "node-v$NODE_VERSION-linux-x64.tar.gz" -C /usr/local --strip-components=1 && \
  rm "node-v$NODE_VERSION-linux-x64.tar.gz" SHASUMS256.txt.asc && \
  npm install -g npm@"$NPM_VERSION" && \
  npm cache clear

# Install MySQL
# From https://github.com/sameersbn/docker-mysql
RUN \
 apt-get install -y mysql-server && \
 rm -rf /var/lib/mysql/mysql && \
 rm -rf /var/lib/apt/lists/* # 20140918

# Install Redis
# From https://github.com/docker-library/redis
RUN \
	mkdir -p /usr/src/redis && \
	wget -q -O redis.tar.gz http://download.redis.io/releases/redis-$REDIS_VERSION.tar.gz && \
	echo "$REDIS_DOWNLOAD_SHA1 *redis.tar.gz" | sha1sum -c - && \
	tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1 && \
	rm redis.tar.gz && \
	make -C /usr/src/redis && \
	make -C /usr/src/redis install && \
	rm -r /usr/src/redis

# Install npms
RUN npm install -g testem ember-cli bower && npm cache clear

# Default values for MySQL
ENV DB_NAME box
ENV DB_USER box
ENV DB_PASS box

ADD start-mysql.sh /start-mysql.sh
ADD start-services.sh /start-services.sh

# Default command
CMD "/start-services.sh"

