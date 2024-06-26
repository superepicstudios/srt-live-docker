# Build

FROM alpine:latest as builder
RUN apk update && apk upgrade
RUN apk add --no-cache linux-headers alpine-sdk cmake tcl openssl-dev zlib-dev

WORKDIR /tmp
RUN git clone https://github.com/superepicstudios/srt-live
RUN git clone https://github.com/haivision/srt

WORKDIR /tmp/srt
RUN ./configure && make && make install

WORKDIR /tmp/srt-live
RUN echo "#include <ctime>"|cat - slscore/common.cpp > /tmp/out && mv /tmp/out slscore/common.cpp
RUN make

# Run

FROM alpine:latest as runner
ENV LD_LIBRARY_PATH /lib:/usr/lib:/usr/local/lib64

RUN apk update && apk upgrade
RUN apk add --no-cache openssl libstdc++
RUN adduser -D srt

RUN mkdir /etc/sls
VOLUME /etc/sls

RUN mkdir /logs && chown srt /logs
VOLUME /logs

COPY --from=builder /usr/local/bin/srt-* /usr/local/bin/
COPY --from=builder /usr/local/lib/libsrt* /usr/local/lib/
COPY --from=builder /tmp/srt-live/bin/* /usr/local/bin/
COPY sls.conf /etc/sls/

EXPOSE 1935/udp
USER srt
WORKDIR /home/srt
ENTRYPOINT [ "sls", "-c", "/etc/sls/sls.conf"]