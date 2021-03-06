VERSION := $(shell git describe --tags | sed -e 's/^v//g' | awk -F "-" '{print $$1}')
ITERATION := $(shell git describe --tags --long | awk -F "-" '{print $$2}')
GO_VERSION=$(shell gobuild -v)
GO := $(or $(GOROOT),/usr/lib/go)/bin/go
PROCS := $(shell nproc)
cores:
	@echo "cores: $(PROCS)"
test:
	./go.test.sh
bench:
	go test -bench .
bench-record:
	$(GO) test -bench . > "benchmarks/stun-go-$(GO_VERSION).txt"
fuzz-prepare-candidate:
	go-fuzz-build -func FuzzCandidate -o stun-candidate-fuzz.zip github.com/gortc/ice
fuzz-candidate:
	go-fuzz -bin=./stun-candidate-fuzz.zip -workdir=fuzz/stun-setters
lint:
	@golangci-lint run
	@echo "ok"
escape:
	@echo "Not escapes, except autogenerated:"
	@go build -gcflags '-m -l' 2>&1 \
	| grep -v "<autogenerated>" \
	| grep escapes
format:
	goimports -w .
install:
	go get -u github.com/golangci/golangci-lint/cmd/golangci-lint
	go get -u github.com/dvyukov/go-fuzz/go-fuzz-build
	go get github.com/dvyukov/go-fuzz/go-fuzz
test-integration:
	@cd integration-test && bash ./test.sh
prepush: test lint test-integration
check-api:
	api -c api/ice1.txt github.com/gortc/ice
