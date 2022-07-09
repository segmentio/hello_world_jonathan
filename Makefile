ECR_REPO := "528451384384.dkr.ecr.us-west-2.amazonaws.com/hello_world_jonathan"

VERSION := $(shell git rev-parse --short HEAD)
# BUILDKITE_COMMIT_REVISION is typically set in our CI environment.
BUILDKITE_COMMIT_REVISION ?= "unset"

LDFLAGS := -ldflags='-X "main.version=$(VERSION)"'
PKG := ./cmd/service

# Output path for our binary. Configurable so we can specify a custom path in CI.
BIN ?= .build/service

# Formatter to use; select from `gofmt`, `goimports`, or `golines`
FORMATTER := gofmt

# To show commands and test output, run `make Q= <target>` (empty Q)
Q=@

# race detector rquires enabling CGO.
GOTESTFLAGS = -race
ifndef Q
GOTESTFLAGS += -v
endif

export GO111MODULE=on
export CGO_ENABLED = 1
export GOPRIVATE=github.com/segment*

.PHONY: build
build:
	$Qgo build -o $(BIN) $(LDFLAGS) $(PKG)

.PHONY: clean
clean:
	$Qrm $(BIN)

# when running locally against stage (with robo sshuttle), you may also want to seed your environment.
# aws-okta exec stage-privileged -- chamber exec chamber <service> -- make run
.PHONY: run
run:
	$Qgo run $(PKG)

.PHONY: vendor
vendor:
	$Qgo mod vendor

.PHONY: vet
vet:
	$Qgo vet ./...

.PHONY: generate
generate:
	$Qgo generate ./...

.PHONY: test
test: vet fmtchk
	$QCGO_ENABLED=1 go test $(GOTESTFLAGS) -coverpkg="./..." -coverprofile=.coverprofile ./...
	$Qgrep -v 'cmd' < .coverprofile > .covprof && mv .covprof .coverprofile
	$Qgo tool cover -func=.coverprofile

.PHONY: fmtchk
fmtchk: $(FORMATTER)
	$Qexit $(shell $(FORMATTER) -l . | grep -v '^vendor' | wc -l)

.PHONY: fmtfix
fmtfix: $(FORMATTER)
	$Q$(FORMATTER) -w $(shell find . -iname '*.go' | grep -v vendor)

.PHONY: goimports
goimports:
ifeq (, $(shell which goimports))
	$QGO111MODULE=off go get -u golang.org/x/tools/cmd/goimports
endif

.PHONY: golines
golines:
ifeq (, $(shell which golines))
	$QGO111MODULE=off go get -u github.com/segmentio/golines
endif

.PHONY: gofmt
gofmt:

.PHONY: onlyclean
onlyclean:
	$Qgit diff --exit-code
	$Qgit diff --cached --exit-code

.PHONY: docker-build
docker-build:
	docker build --build-arg VERSION=$(VERSION) \
		-t $(ECR_REPO):$(VERSION) \
		-t $(ECR_REPO):$(BUILDKITE_COMMIT_REVISION) \
		.

.PHONY: docker-publish
docker-publish: docker-build
	docker push $(ECR_REPO):$(VERSION)
	docker push $(ECR_REPO):$(BUILDKITE_COMMIT_REVISION)
