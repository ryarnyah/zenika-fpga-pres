BASE=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))

ifeq ($(PLATFORM), Darwin)
  CONDA_INSTALLER = Miniconda3-latest-MacOSX-x86_64.sh
else
  CONDA_INSTALLER = Miniconda3-latest-Linux-x86_64.sh
endif

CONDA_HOME = $(HOME)/.miniconda
CONDA_BIN_DIR = $(CONDA_HOME)/bin
CONDA = $(CONDA_BIN_DIR)/conda

ENV_NAME = xc7
CONDA_REQUIREMENTS = $(BASE)/../environment.yml

install-conda: conda_install conda_env_create

conda_install:
	@echo 'installing the conda package manager'
	@echo
	wget https://repo.continuum.io/miniconda/$(CONDA_INSTALLER)
	bash $(CONDA_INSTALLER) -b -p $(CONDA_HOME)
	$(CONDA) install --yes conda-build
	$(CONDA) install --yes argcomplete
	@echo

conda_env_create:
	@echo 'creating the '$(ENV_NAME)' environment'
	@echo
	$(CONDA) env create --file $(CONDA_REQUIREMENTS)
	@echo