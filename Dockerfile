FROM alpine:3.2
MAINTAINER The Prometheus Authors <prometheus-developers@googlegroups.com>

ENV GOPATH=/go \
    REPO_PATH=github.com/prometheus/prometheus \
    REFRESH=2015-06-22
COPY . /go/src/github.com/prometheus/prometheus

RUN apk add --update -t build-deps go git mercurial \
    && apk add -u musl && rm -rf /var/cache/apk/* \
    && go get github.com/tools/godep \
    && cd /go/src/github.com/prometheus/prometheus/cmd/prometheus \
    && $GOPATH/bin/godep restore && go get -d \
    && go build -ldflags " \
            -X main.buildVersion  $(cat ../../version/VERSION) \
            -X main.buildRevision $(git rev-parse --short HEAD) \
            -X main.buildBranch   $(git rev-parse --abbrev-ref HEAD) \
            -X main.buildUser     root \
            -X main.buildDate     $(date +%Y%m%d-%H:%M:%S) \
            -X main.goVersion     $(go version | awk '{print substr($3,3)}') \
        " -o /bin/prometheus \
    && cd /go/src/github.com/prometheus/prometheus/tools/rule_checker \
    && go build -o /bin/rule_checker \
    && cd /go/src/github.com/prometheus/prometheus \
    && mkdir -p /etc/prometheus \
    && mkdir /prometheus \
    && mv ./documentation/examples/prometheus.yml /etc/prometheus/prometheus.yml \
    && mv ./console_libraries/ ./consoles/ /etc/prometheus/ \
    && rm -rf /go \
    && apk del --purge build-deps

EXPOSE     9090
WORKDIR    /prometheus
ENTRYPOINT [ "/bin/prometheus" ]
CMD        [ "-config.file=/etc/prometheus/prometheus.yml", \
             "-storage.local.path=/prometheus", \
             "-web.console.libraries=/etc/prometheus/console_libraries", \
             "-web.console.templates=/etc/prometheus/consoles", \
             "-log.level=debug"]
