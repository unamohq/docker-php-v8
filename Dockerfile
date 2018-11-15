FROM unamo/docker-php

ARG V8_VERSION=6.8.104

RUN apt-get update \
    && mkdir -p /usr/share/man/man1 /usr/share/man/man7 \
    && apt-get install -y libglib2.0-dev patchelf

RUN mkdir /tmp/depot_tools \
    && git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git /tmp/depot_tools

ENV PATH="/tmp/depot_tools:${PATH}"

RUN cd /tmp && fetch v8
RUN cd /tmp/v8 && git checkout ${V8_VERSION}
RUN cd /tmp/v8 && gclient sync
RUN cd /tmp/v8 && tools/dev/v8gen.py -vv x64.release -- is_component_build=true
RUN cd /tmp/v8 && ninja -C out.gn/x64.release/
RUN mkdir -p /opt/v8/lib /opt/v8/include
RUN cd /tmp/v8 && cp out.gn/x64.release/lib*.so out.gn/x64.release/*_blob.bin out.gn/x64.release/icudtl.dat /opt/v8/lib/
RUN cd /tmp/v8 && cp -R include/* /opt/v8/include/
RUN for A in /opt/v8/lib/*.so; do patchelf --set-rpath '$ORIGIN' $A; done

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

RUN rm -r /tmp/*

VOLUME ["/app"]