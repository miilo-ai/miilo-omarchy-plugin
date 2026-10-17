.PHONY: check check-native check-typography
check:
	python3 tools/check.py
	python3 -m unittest discover -s tests -v
	node --test tests/*.test.mjs
	bash -n tools/check-native.sh
	bash -n tools/test-typography.sh

check-typography:
	bash tools/test-typography.sh

check-native: check
	bash tools/check-native.sh
