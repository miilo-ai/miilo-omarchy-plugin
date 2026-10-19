.PHONY: check check-native check-typography
check:
	node tools/test-render-invalidation.cjs
	node tools/check-no-python.cjs
	node --test tools/no-python.test.cjs
	node tools/check.cjs
	node --test tests/*.test.mjs
	bash -n uninstall.sh tools/check-native.sh
	bash -n tools/test-typography.sh
	bash -n tools/dev-relaunch.sh tools/install-dev-skill.sh
	bash -n tools/shell-lifecycle.sh
	bash -n tools/test-configuration.sh
	bash -n tools/qualify-user-config.sh
	bash -n tools/cargo-auth.sh
	bash tools/test-cargo-auth.sh

check-typography: check-plain-text
	bash tools/test-typography.sh
	bash tools/test-configuration.sh

check-native: check
	bash tools/check-native.sh

.PHONY: render-design
render-design:
	node tools/render-crew.cjs

.PHONY: check-canvas-clock
check-canvas-clock:
	node tools/test-canvas-clock.cjs

check-typography: check-canvas-clock
.PHONY: check-plain-text
check-plain-text:
	node tools/test-plain-text.cjs

.PHONY: benchmark-rendering
benchmark-rendering:
	node tools/benchmark-native-rendering.cjs
