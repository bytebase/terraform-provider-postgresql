TEST?=$$(go list ./...)
GOFMT_FILES?=$$(find . -name '*.go')
HOSTNAME=terraform.local
NAMESPACE=bytebase
NAME=postgresql
BINARY=terraform-provider-${NAME}
VERSION=${shell cat ./VERSION}
OS_ARCH=darwin_amd64

default: install

build: fmtcheck
	go build -o ${BINARY}

test: fmtcheck
	go test -i $(TEST) || exit 1
	echo $(TEST) | \
		xargs -t -n4 go test $(TESTARGS) -timeout=30s -parallel=4

testacc_setup: fmtcheck
	@sh -c "'$(CURDIR)/tests/testacc_setup.sh'"

testacc_cleanup: fmtcheck
	@sh -c "'$(CURDIR)/tests/testacc_cleanup.sh'"

testacc: fmtcheck
	@sh -c "'$(CURDIR)/tests/testacc_full.sh'"

vet:
	@echo "go vet ."
	@go vet $$(go list ./...) ; if [ $$? -eq 1 ]; then \
		echo ""; \
		echo "Vet found suspicious constructs. Please check the reported constructs"; \
		echo "and fix them if necessary before submitting the code for review."; \
		exit 1; \
	fi

fmt:
	gofmt -w $(GOFMT_FILES)

fmtcheck:
	@sh -c "'$(CURDIR)/scripts/gofmtcheck.sh'"

.PHONY: build test testacc vet fmt fmtcheck

install: build
	mkdir -p ~/.terraform.d/plugins/${HOSTNAME}/${NAMESPACE}/${NAME}/${VERSION}/${OS_ARCH}
	mv ${BINARY} ~/.terraform.d/plugins/${HOSTNAME}/${NAMESPACE}/${NAME}/${VERSION}/${OS_ARCH}

release:
	goreleaser release --rm-dist --snapshot --skip-publish  --skip-sign
