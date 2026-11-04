import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

class CourseSelectView extends WatchUi.View {
    var _courses as Array;
    var _errors as Array;
    var _courseIndex as Number = 0;
    var _roundHoles as Number = 9;
    var _loopA as Number = -1;
    var _loopB as Number = -1;
    var _handicap as Number = 18;
    var _selectedField as Number = 0;
    var _screenWidth as Number = 0;
    var _screenHeight as Number = 0;
    var _message as String = "";
    var _marqueeTimer as Timer.Timer;
    var _marqueeTick as Number = 0;
    var _marqueeRunning as Boolean = false;
    var _needsMarquee as Boolean = false;

    function initialize(configuration as Dictionary) {
        View.initialize();
        _handicap = NetScoreGolf.getLastHandicap();
        _marqueeTimer = new Timer.Timer();
        _courses = configuration["courses"] as Array;
        _errors = configuration["errors"] as Array;
        if (_courses.size() > 0) {
            chooseDefaultRound();
            normalizeLoopSelection();
        }
    }

    function onHide() as Void {
        if (_marqueeRunning) {
            _marqueeTimer.stop();
            _marqueeRunning = false;
        }
    }

    function onShow() as Void {
        refreshConfiguration();
    }

    function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        _screenWidth = dc.getWidth();
        _screenHeight = dc.getHeight();
        var centerX = dc.getWidth() / 2;
        _needsMarquee = false;

        drawFittedText(dc, centerX, _screenHeight * 16 / 100, "NETSCORE GOLF",
            dc.getWidth() * 72 / 100);

        if (_courses.size() == 0) {
            var status = (_errors.size() > 0) ?
                "Course settings invalid" : "No courses loaded";
            var advice = (_errors.size() > 0) ?
                "Check settings, then tap to reload" : "Save settings, then tap to reload";
            drawFittedText(dc, centerX, _screenHeight * 42 / 100, status,
                dc.getWidth() * 82 / 100);
            drawFittedText(dc, centerX, _screenHeight * 53 / 100,
                advice,
                dc.getWidth() * 82 / 100);
            if (_errors.size() > 0) {
                drawFittedText(dc, centerX, _screenHeight * 66 / 100,
                    "First error: " + (_errors[0] as String),
                    dc.getWidth() * 82 / 100);
            }
        } else {
            var course = _courses[_courseIndex] as Dictionary;
            var loops = course["loops"] as Array;
            drawRow(dc, centerX, _screenHeight * 28 / 100,
                "Course: " + (course["name"] as String), dc.getWidth() * 84 / 100);
            drawRow(dc, centerX, _screenHeight * 41 / 100,
                "Round: " + _roundHoles.format("%d") + " holes", dc.getWidth() * 84 / 100);

            if (_loopA >= 0 && _loopA < loops.size()) {
                var loopA = loops[_loopA] as Dictionary;
                drawRow(dc, centerX, _screenHeight * 54 / 100,
                    "A: " + (loopA["name"] as String) +
                    " (" + (loopA["totalHoles"] as Number).format("%d") + ")", dc.getWidth() * 88 / 100);
                if (_roundHoles == 18 &&
                    (loopA["totalHoles"] as Number) == 9 &&
                    _loopB >= 0 && _loopB < loops.size()) {
                    var loopB = loops[_loopB] as Dictionary;
                    drawRow(dc, centerX, _screenHeight * 67 / 100,
                        "B: " + (loopB["name"] as String) + " (9)", dc.getWidth() * 88 / 100);
                }
            } else {
                drawRow(dc, centerX, _screenHeight * 54 / 100,
                    "A: no compatible loop", dc.getWidth() * 88 / 100);
            }
        }

        if (_courses.size() > 0) {
            drawHandicapControls(dc, centerX, _screenHeight * 78 / 100);
        }
        var actionLabel = (_courses.size() > 0) ? "START" : "RELOAD";
        dc.drawText(centerX, _screenHeight * 91 / 100, Graphics.FONT_MEDIUM, actionLabel,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        if (_courses.size() > 0 && _errors.size() > 0 && _message.equals("")) {
            dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_BLACK);
            drawFittedText(dc, centerX, _screenHeight * 84 / 100,
                "Check: " + (_errors[0] as String),
                dc.getWidth() * 65 / 100);
        }
        if (!_message.equals("") && _courses.size() > 0) {
            dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_BLACK);
            drawFittedText(dc, centerX, _screenHeight * 84 / 100, _message,
                    dc.getWidth() * 65 / 100);
        }
        syncMarqueeTimer();
    }

    function drawFittedText(dc as Dc, centerX as Number, y as Number, text as String, maxWidth as Number) as Void {
        var needsMarquee = MarqueeText.draw(dc, text, centerX, y, maxWidth,
            Graphics.FONT_XTINY,
            _marqueeTick);
        if (needsMarquee) {
            _needsMarquee = true;
        }
    }

    function drawRow(dc as Dc, centerX as Number, y as Number, text as String, maxWidth as Number) as Void {
        drawFittedText(dc, centerX, y, text, maxWidth);
    }

    function drawHandicapControls(dc as Dc, centerX as Number, y as Number) as Void {
        var handicapText = (_handicap < 0) ?
            "+" + (-_handicap).format("%d") : _handicap.format("%d");
        dc.drawText(_screenWidth * 25 / 100, y, Graphics.FONT_MEDIUM, "-",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(centerX, y, Graphics.FONT_XTINY,
            "PHCP " + handicapText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(_screenWidth * 75 / 100, y, Graphics.FONT_MEDIUM, "+",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function advanceMarquee() as Void {
        _marqueeTick += 1;
        WatchUi.requestUpdate();
    }

    function syncMarqueeTimer() as Void {
        if (_needsMarquee && !_marqueeRunning) {
            _marqueeTimer.start(method(:advanceMarquee), 100, true);
            _marqueeRunning = true;
        } else if (!_needsMarquee && _marqueeRunning) {
            _marqueeTimer.stop();
            _marqueeRunning = false;
        }
    }

    function refreshConfiguration() as Void {
        var selectedName = "";
        if (_courses.size() > 0 && _courseIndex < _courses.size()) {
            selectedName = (_courses[_courseIndex] as Dictionary)["name"] as String;
        }

        var configuration = NetScoreGolf.loadConfiguredCourses();
        _courses = configuration["courses"] as Array;
        _errors = configuration["errors"] as Array;
        _courseIndex = 0;
        for (var i = 0; i < _courses.size(); i++) {
            if ((_courses[i] as Dictionary)["name"] == selectedName) {
                _courseIndex = i;
                break;
            }
        }
        _loopA = -1;
        _loopB = -1;
        if (_courses.size() > 0) {
            chooseDefaultRound();
            normalizeLoopSelection();
        }
        _message = "";
        _marqueeTick = 0;
        WatchUi.requestUpdate();
    }

    function chooseDefaultRound() as Void {
        var course = _courses[_courseIndex] as Dictionary;
        var loops = course["loops"] as Array;
        var hasNine = false;
        for (var i = 0; i < loops.size(); i++) {
            if ((loops[i] as Dictionary)["totalHoles"] == 9) {
                hasNine = true;
            }
        }
        _roundHoles = hasNine ? 9 : 18;
    }

    function normalizeLoopSelection() as Void {
        if (_courses.size() == 0) {
            _loopA = -1;
            _loopB = -1;
            return;
        }

        var course = _courses[_courseIndex] as Dictionary;
        var loops = course["loops"] as Array;
        if (_loopA < 0 || _loopA >= loops.size() ||
            !isValidFirstLoop(loops[_loopA] as Dictionary)) {
            _loopA = findFirstLoop(0);
        }

        _loopB = -1;
        if (_roundHoles == 18 && _loopA >= 0) {
            var loopA = loops[_loopA] as Dictionary;
            if ((loopA["totalHoles"] as Number) == 9) {
                _loopB = findSecondLoop(0);
            }
        }
    }

    function isValidFirstLoop(loop as Dictionary) as Boolean {
        var count = loop["totalHoles"] as Number;
        return (_roundHoles == 9 && count == 9) ||
            (_roundHoles == 18 && (count == 9 || count == 18));
    }

    function findFirstLoop(start as Number) as Number {
        var loops = (_courses[_courseIndex] as Dictionary)["loops"] as Array;
        for (var offset = 0; offset < loops.size(); offset++) {
            var candidate = (start + offset) % loops.size();
            if (isValidFirstLoop(loops[candidate] as Dictionary)) {
                return candidate;
            }
        }
        return -1;
    }

    function findSecondLoop(start as Number) as Number {
        var loops = (_courses[_courseIndex] as Dictionary)["loops"] as Array;
        for (var offset = 0; offset < loops.size(); offset++) {
            var candidate = (start + offset) % loops.size();
            if (candidate != _loopA &&
                ((loops[candidate] as Dictionary)["totalHoles"] as Number) == 9) {
                return candidate;
            }
        }
        return -1;
    }

    function canSelectSecondLoop() as Boolean {
        if (_roundHoles != 18 || _loopA < 0) {
            return false;
        }

        var course = _courses[_courseIndex] as Dictionary;
        var loops = course["loops"] as Array;
        var loopA = loops[_loopA] as Dictionary;
        return (loopA["totalHoles"] as Number) == 9;
    }

    function adjustSelectedField(delta as Number) as Void {
        changeField(_selectedField, delta);
    }

    function cycleField() as Void {
        changeField((_selectedField + 1) % 5, 0);
    }

    function changeField(field as Number, delta as Number) as Void {
        _selectedField = field;
        if (_courses.size() > 0) {
            if (field == 0 && delta != 0) {
                _courseIndex = (_courseIndex + delta + _courses.size()) % _courses.size();
                _loopA = -1;
                chooseDefaultRound();
                normalizeLoopSelection();
            } else if (field == 1 && delta != 0) {
                _roundHoles = (_roundHoles == 9) ? 18 : 9;
                _loopA = -1;
                normalizeLoopSelection();
            } else if (field == 2 && delta != 0) {
                var loops = (_courses[_courseIndex] as Dictionary)["loops"] as Array;
                if (loops.size() > 0) {
                    var start = (_loopA < 0) ? 0 : (_loopA + delta + loops.size()) % loops.size();
                    _loopA = findFirstLoop(start);
                    normalizeLoopSelection();
                }
            } else if (field == 3 && delta != 0 && canSelectSecondLoop()) {
                var loops = (_courses[_courseIndex] as Dictionary)["loops"] as Array;
                var start = (_loopB < 0) ? 0 : (_loopB + delta + loops.size()) % loops.size();
                _loopB = findSecondLoop(start);
            } else if (field == 4) {
                _handicap += delta;
                if (_handicap < -54) {
                    _handicap = -54;
                } else if (_handicap > 54) {
                    _handicap = 54;
                }
                NetScoreGolf.saveLastHandicap(_handicap);
            }
        }

        _message = "";
        WatchUi.requestUpdate();
    }

    function handleTap(x as Number, y as Number) as Void {
        if (_courses.size() == 0 || y < _screenHeight * 22 / 100) {
            refreshConfiguration();
            return;
        }

        var relativeY = y * 100 / _screenHeight;
        if (relativeY < 35) {
            changeField(0, x < _screenWidth / 2 ? -1 : 1);
        } else if (relativeY < 48) {
            changeField(1, 1);
        } else if (relativeY < 61) {
            changeField(2, x < _screenWidth / 2 ? -1 : 1);
        } else if (relativeY < 74) {
            if (_roundHoles == 18 && canSelectSecondLoop()) {
                changeField(3, x < _screenWidth / 2 ? -1 : 1);
            }
        } else if (relativeY < 86) {
            if (x < _screenWidth * 45 / 100) {
                changeField(4, -1);
            } else if (x > _screenWidth * 55 / 100) {
                changeField(4, 1);
            }
        } else if (relativeY > 87) {
            startRound();
        }
    }

    function startRound() as Void {
        if (_courses.size() == 0) {
            refreshConfiguration();
            return;
        }

        var course = _courses[_courseIndex] as Dictionary;
        var loops = course["loops"] as Array;
        if (_loopA < 0 || _loopA >= loops.size()) {
            _message = "No loop matches this round length";
            WatchUi.requestUpdate();
            return;
        }

        var loopA = loops[_loopA] as Dictionary;
        var loopB = null as Dictionary?;
        if (_roundHoles == 18 && (loopA["totalHoles"] as Number) == 9) {
            if (_loopB < 0 || _loopB >= loops.size() || _loopB == _loopA) {
                _message = "Select a second nine-hole loop";
                WatchUi.requestUpdate();
                return;
            }
            loopB = loops[_loopB] as Dictionary;
            if (!NetScoreGolf.hasValidCombinedIndexes(loopA, loopB as Dictionary)) {
                _message = "Combined indexes must cover 1-18";
                WatchUi.requestUpdate();
                return;
            }
        }

        var round = NetScoreGolf.createRound(course, loopA, loopB, _roundHoles, _handicap);
        var activeView = new ActiveHoleView(round);
        WatchUi.switchToView(
            activeView,
            new ActiveHoleViewDelegate(activeView),
            WatchUi.SLIDE_LEFT
        );
    }
}

class CourseSelectViewDelegate extends WatchUi.InputDelegate {
    var _view as CourseSelectView;

    function initialize(view as CourseSelectView) {
        InputDelegate.initialize();
        _view = view;
    }

    function onKey(keyEvent as KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_ENTER) {
            _view.startRound();
            return true;
        } else if (key == WatchUi.KEY_UP) {
            _view.adjustSelectedField(1);
            return true;
        } else if (key == WatchUi.KEY_DOWN) {
            _view.adjustSelectedField(-1);
            return true;
        } else if (key == WatchUi.KEY_MENU) {
            _view.cycleField();
            return true;
        }
        return false;
    }

    function onTap(clickEvent as ClickEvent) as Boolean {
        var coordinates = clickEvent.getCoordinates();
        _view.handleTap(coordinates[0], coordinates[1]);
        return true;
    }
}
