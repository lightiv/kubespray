ANSIBLE_INVENTORY ?= inventory/akash-provider
INVENTORY_FILE ?= cluster.yml
KUBE_SPRAY_DIR ?= ../../../kubernetes-sigs/kubespray/
# TODO: Configure IP addresses(space-separated) for `build-inventor` target
IPS ?= 10.240.0.0

# Pip3 setup
# OS Packages to install: python3-pip, python3-venv

PIP_ENV ?= pipenv

.PHONY: pip-init
pip-init:
	# Create virtualenv: https://packaging.python.org/guides/installing-using-pip-and-virtual-environments/#creating-a-virtual-environment
	python3 -m venv "$(PIP_ENV)"

.PHONY: pip-activate-cmd
pip-activate-cmd:
	@echo "run$ . ./$(PIP_ENV)/bin/activate"

.PHONY: pip-requirements
pip-install-requirements:
	pip3 install -r requirements.txt

.PHONY: build-inventory
build-inventory:
	CONFIG_FILE="$(ANSIBLE_INVENTORY)/hosts.yaml" python3 contrib/inventory_builder/inventory.py $(IPS)

.PHONY: ansible-deploy
ansible-deploy:
	# Deploy Kubespray with Ansible Playbook - run the playbook as root
	# The option `--become` is required, as for example writing SSL keys in /etc/,
	# installing packages and interacting with various systemd daemons.
	# Without --become the playbook will fail to run!
	# ansible-playbook -i "$(ANSIBLE_INVENTORY)/hosts.yaml" --diff --check -vvvv --become --become-user=root "$(INVENTORY_FILE)"
	ansible-playbook -i "$(ANSIBLE_INVENTORY)/hosts.yaml" --diff --become --become-user=root "$(INVENTORY_FILE)"

.PHONY: ansible-tags
ansible-tags:
	ansible-playbook -i "$(ANSIBLE_INVENTORY)/hosts.yaml" --check --diff -vvvv --list-tags --become --become-user=root "$(INVENTORY_FILE)"

.PHONY: ansible-hosts
ansible-hosts:
	ansible-playbook -i "$(ANSIBLE_INVENTORY)/hosts.yaml" --check --diff -vvvv --list-hosts --become --become-user=root "$(INVENTORY_FILE)"

.PHONY: ansible-tasks
ansible-tasks:
	ansible-playbook -i "$(ANSIBLE_INVENTORY)/hosts.yaml" --check --diff -vvvv --list-tasks --become --become-user=root "$(INVENTORY_FILE)"

.PHONY: ansible-facts
ansible-facts:
	ansible -i "$(ANSIBLE_INVENTORY)/hosts.yaml" node1 -m setup

mitogen:
	ansible-playbook -c local mitogen.yml -vv
clean:
	rm -rf dist/
	rm *.retry
