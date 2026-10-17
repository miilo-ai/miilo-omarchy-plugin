PYTHON ?= python3
.PHONY: check check-native
check:
	python3 tools/check.py
	python3 -m unittest discover -s tests -v
	node --test tests/onboarding.test.mjs
	bash -n tools/check-native.sh

check-native: check
	bash tools/check-native.sh

.PHONY: render-design
render-design:
	$(PYTHON) tools/render-crew.py
