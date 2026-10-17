.PHONY: check check-native
check:
	python3 tools/check.py
	python3 -m unittest discover -s tests -v
	bash -n tools/check-native.sh

check-native: check
	bash tools/check-native.sh
