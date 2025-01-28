.DEFAULT_GOAL = all 

REPO_ROOT = $(shell git rev-parse --show-toplevel)
# Manually set REPO_ROOT to the current directory
# ifneq ($(REPO_ROOT_GIT),)
#   REPO_ROOT = $(REPO_ROOT_GIT)
#   $(info REPO_ROOT set by git: $(REPO_ROOT))
# else
#   REPO_ROOT = ..
#   $(info REPO_ROOT set manually: $(REPO_ROOT))
# endif

TOOLS_DIR = $(REPO_ROOT)/hack/tools
TOOLS_BIN_DIR = $(TOOLS_DIR)/bin
# TOOLS_BIN_DIR = $(TOOLS_DIR)
CONTROLLER_GEN = $(TOOLS_BIN_DIR)/controller-gen
HELM_CRD_DIR = $(REPO_ROOT)/deploy/legacy/manifests/controller/helm/retina/crds

.PHONY: generate manifests

all: generate manifests

generate: $(CONTROLLER_GEN)
	$(CONTROLLER_GEN) object paths="./api/..."

manifests: $(CONTROLLER_GEN)
	rm -rf $(HELM_CRD_DIR)
	$(CONTROLLER_GEN) crd paths="./api/..." output:crd:artifacts:config=$(HELM_CRD_DIR)

$(CONTROLLER_GEN):
	@make -C $(REPO_ROOT) $(CONTROLLER_GEN)
