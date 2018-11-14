FROM unamo/docker-php

ENV BUILD_DEPS gcc make autoconf build-essential
RUN apt-get update \
    && mkdir -p /usr/share/man/man1 /usr/share/man/man7 \
    && apt-get install -y $BUILD_DEPS libglib2.0-dev

RUN mkdir /tmp/depot_tools \
    && git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git /tmp/depot_tools

ENV PATH="/tmp/depot_tools:${PATH}"

RUN cd /tmp && fetch v8
RUN cd /tmp/v8 && gclient sync
RUN cd /tmp/v8 && tools/dev/v8gen.py -vv x64.release -- is_component_build=true
RUN cd /tmp/v8 && ninja -C out.gn/x64.release/
RUN mkdir -p /opt/v8/lib
RUN mkdir /opt/v8/include
RUN cd /tmp/v8 && cp out.gn/x64.release/lib*.so out.gn/x64.release/*_blob.bin /opt/v8/lib/
RUN cd /tmp/v8 && cp -R include/* /opt/v8/include/

RUN mkdir -p /tmp/pear \
    && cd /tmp/pear \
    && pecl bundle v8js \
    && cd v8js \
    && phpize . \
    && ./configure --with-v8js=/opt/v8 LDFLAGS="-lstdc++" \
    && make \
    && make install \
    && cd ~ \
    && rm -rf /tmp/pear \
    && docker-php-ext-enable v8js

RUN apt-get autoremove -y $BUILD_DEPS
RUN rm -r /tmp/depot_tools

VOLUME ["/app"]