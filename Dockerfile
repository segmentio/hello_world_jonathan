# We use a multi stage Docker build. This allows us to use a very small image at runtime by only including dependencies
# needed at runtime, and skipping dependencies that are only need to build our application.
FROM segment/chamber:2 as chamber
FROM golang:1.17 as builder

RUN apt-get update && apt-get install --no-install-recommends -y \
    build-essential \
    ca-certificates \
    git

ENV SRC github.com/segmentio/hello_world_jonathan
ENV GOFLAGS -mod=vendor
ARG VERSION

COPY . /go/src/${SRC}
WORKDIR /go/src/${SRC}

# Normally we produce a binary relative to the current directory. However this depends on the ${SRC} environment variable
# in our Dockerfile, which cannot be used in our subsequent `COPY --from` commands due to https://github.com/moby/moby/issues/34482.
# So we specify a known path so that we can use it in our COPY directive.
RUN BIN=/build/service make build

# We use the Segment scratch as it includes data needed by our programs (e.g. tzdata for Go applications).
FROM 528451384384.dkr.ecr.us-west-2.amazonaws.com/segment-scratch

COPY --from=chamber /chamber /bin/chamber
COPY --from=builder /build/service /bin/service
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

ENTRYPOINT ["/bin/chamber", "exec", "hello_world_jonathan", "--", "/bin/service"]
