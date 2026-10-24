import QtQuick
import QtTest
import "../../ui/components" as Miilo

Item {
    width: 420; height: 180
    Rectangle { anchors.fill: parent; color: "#18202c" }
    Miilo.MiiloWordmark { id: wordmark; x: 10; y: 10; width: 184; height: 72; ink: "#b4d3e8" }
    Miilo.MiiloSymbol { id: symbol; x: 240; y: 10; width: 64; height: 64; ink: "#b4d3e8" }
    TestCase {
        name: "MiiloBrand"
        when: windowShown
        function init() { symbol.width = 64; symbol.height = 64; symbol.ink = "#b4d3e8"; wordmark.ink = "#b4d3e8"; wait(30) }
        function capture(item) { tryCompare(item.children[0], "status", Image.Ready); wait(100); return grabImage(item); }
        function test_transparent_visor_and_theme() {
            var image = capture(symbol);
            compare(image.pixel(32, 38), Qt.color("#18202c"));
            compare(image.pixel(26, 38), Qt.color("#b4d3e8"));
            symbol.ink = "#172027"; wait(30);
            image = capture(symbol);
            compare(image.pixel(26, 38), Qt.color("#172027"));
            compare(image.pixel(32, 38), Qt.color("#18202c"));
        }
        function test_resize_and_nonsquare_bounds() {
            for (var size of [16, 24, 32, 64, 128]) {
                symbol.width = size; symbol.height = size; wait(30);
                var image = capture(symbol);
                compare(image.width, size); compare(image.height, size);
                verify(image.pixel(Math.round(size / 2), Math.round(size * 0.2)) !== Qt.color("#18202c"));
            }
            symbol.width = 96; symbol.height = 64; wait(30);
            var wide = capture(symbol);
            compare(wide.pixel(2, 32), Qt.color("#18202c"));
            compare(wide.pixel(42, 38), Qt.color("#b4d3e8"));
        }
        function test_header_size_retains_smooth_edges() {
            wordmark.width = 86; wordmark.height = 34;
            var image = capture(wordmark), colored = 0, blended = 0;
            for (var x = 0; x < image.width; x++) for (var y = 0; y < image.height; y++) {
                var color = image.pixel(x, y);
                if (color !== Qt.color("#18202c")) colored++;
                if (color.r > 0.1 && color.r < 0.69) blended++;
            }
            verify(colored > 100); verify(blended > 15);
            wordmark.width = 184; wordmark.height = 72;
        }
        function test_wordmark_uses_symbol_and_theme() {
            wordmark.ink = "#ffffff"; wait(30);
            var image = capture(wordmark);
            compare(image.pixel(74, 20), Qt.color("#ffffff"));
            compare(image.pixel(149, 46), Qt.color("#ffffff"));
            compare(image.pixel(155, 46), Qt.color("#18202c"));
        }
    }
}
