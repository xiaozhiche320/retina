.DEFAULT_GOAL = all 

# REPO_ROOT = $(shell git rev-parse --show-toplevel)
REPO_ROOT ?= /workspace

TOOLS_DIR = $(REPO_ROOT)/hack/tools
TOOLS_BIN_DIR = $(TOOLS_DIR)/bin
CONTROLLER_GEN = $(TOOLS_BIN_DIR)/controller-gen
HELM_CRD_DIR = $(REPO_ROOT)/deploy/standard/manifests/controller/helm/retina/crds

.PHONY: generate manifests

all: generate manifests

generate: $(CONTROLLER_GEN)
	$(CONTROLLER_GEN) object paths="./api/..."

manifests: $(CONTROLLER_GEN)
	rm -rf $(HELM_CRD_DIR)
	$(CONTROLLER_GEN) crd paths="./api/..." output:crd:artifacts:config=$(HELM_CRD_DIR)

# $(CONTROLLER_GEN):
# 	@make -C $(REPO_ROOT) $(CONTROLLER_GEN)

$(CONTROLLER_GEN): $(TOOLS_DIR)/go.mod
	@echo "Building controller-gen"
	cd $(TOOLS_DIR); go mod download; go build -tags=tools -o bin/controller-gen sigs.k8s.io/controller-tools/cmd/controller-gen