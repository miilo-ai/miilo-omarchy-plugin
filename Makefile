PYTHON ?= python3
.PHONY: check check-native check-typography
check:
	python3 tools/check.py
	python3 -m unittest discover -s tests -v
	node --test tests/*.test.mjs
	bash -n tools/check-native.sh
	bash -n tools/test-typography.sh
	bash -n tools/dev-relaunch.sh tools/install-dev-skill.sh
	bash -n tools/test-configuration.sh
	bash -n tools/qualify-user-config.sh
	bash -n tools/cargo-auth.sh
	bash tools/test-cargo-auth.sh

check-typography:
	bash tools/test-typography.sh
	bash tools/test-configuration.sh

check-native: check
	bash tools/check-native.sh

.PHONY: render-design
render-design:
	$(PYTHON) tools/render-crew.py
