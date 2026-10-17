"""Optional real Qt component qualification. Requires developer-only PySide6-Essentials.
Uses a test-only Quickshell.env stub; it does not qualify the actual Omarchy shell.
"""
import os
import sys
from pathlib import Path

os.environ.setdefault('QT_QPA_PLATFORM', 'offscreen')
os.environ.setdefault('QT_QUICK_BACKEND', 'software')
os.environ.setdefault('QT_QUICK_CONTROLS_STYLE', 'Basic')
from PySide6.QtCore import QPoint, Qt, QTimer, QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQuick import QQuickWindow
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtTest import QTest

root = Path(__file__).resolve().parents[1]
output = Path(sys.argv[1] if len(sys.argv) > 1 else '/tmp/miilo-crew-preview')
output.mkdir(parents=True, exist_ok=True)
app = QGuiApplication(sys.argv)
engine = QQmlApplicationEngine()
engine.addImportPath(str(root / 'tests/qml/stubs'))
problems = []
engine.warnings.connect(lambda items: problems.extend(item.toString() for item in items))
engine.load(QUrl.fromLocalFile(str(root / 'tests/qml/CrewFixture.qml')))
if not engine.rootObjects():
    raise SystemExit('Crew fixture failed to load')
window = engine.rootObjects()[0]


def capture(name):
    image = window.grabWindow()
    if image.isNull():
        raise AssertionError('Empty QML render')
    image.save(str(output / name))


def validate():
    try:
        capture('crew-dark.png')
        QTest.mouseClick(window, Qt.LeftButton, Qt.NoModifier, QPoint(220, 115))
        QTest.qWait(80)
        def descendants(item):
            yield item
            for child in item.childItems():
                yield from descendants(child)
        capture('crew-expanded.png')
        expanded = [item for item in descendants(window.contentItem()) if item.property('expanded') is True]
        assert expanded, 'Click did not expand an agent row'
        window.setProperty('light', True)
        window.setWidth(360)
        QTest.qWait(100)
        capture('crew-light-narrow.png')
        assert not problems, '\n'.join(problems)
        print('PASS: actual Qt 6 crew render, row expansion and narrow light theme.')
        print('Test-only environment stub; native Omarchy lifecycle remains separate.')
        app.exit(0)
    except Exception as error:
        print(error)
        app.exit(1)


QTimer.singleShot(400, validate)
sys.exit(app.exec())
