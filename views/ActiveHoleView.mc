import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

class ActiveHoleView extends WatchUi.View {
    var _round as Dictionary;
    var _screenWidth as Number = 0;
    var _screenHeight as Number = 0;
    var _marqueeTimer as Timer.Timer;
    var _endRoundTimer as Timer.Timer;
    var _marqueeTick as Number = 0;
    var _marqueeRunning as Boolean = false;
    var _needsMarquee as Boolean = false;

    function initialize(round as Dictionary) {
        View.initialize();
        _round = round;
        _marqueeTimer = new Timer.Timer();
        _endRoundTimer = new Timer.Timer();
    }

    function onHide() as Void {
        if (_marqueeRunning) {
            _marqueeTimer.stop();
            _marqueeRunning = false;
        }
    }

    function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        _screenWidth = dc.getWidth();
        _screenHeight = dc.getHeight();
        _needsMarquee = false;

        var currentHole = _round["currentHole"] as Number;
        var totalHoles = _round["totalHoles"] as Number;
        var holes = _round["holes"] as Array;
        var strokes = _round["strokes"] as Array;
        var hole = holes[currentHole] as Dictionary;
        var par = hole["par"] as Number;
        var hcpIndex = hole["hcp"] as Number;
        var gross = strokes[currentHole] as Number;
        var centerX = _screenWidth / 2;
        var titleY = 17;
        var holeY = 30;
        var parY = 41;
        var grossLabelY = 52;
        var grossY = 68;
        var controlsY = 68;
        var navigationY = 92;
        if (_screenHeight < 320) {
            titleY = 10;
            holeY = 23;
            parY = 36;
            grossLabelY = 49;
            grossY = 68;
            controlsY = 68;
            navigationY = 92;
        }

        _needsMarquee = MarqueeText.draw(dc, _round["courseName"] as String,
            centerX, _screenHeight * titleY / 100,
            _screenWidth * 82 / 100,
            Graphics.FONT_XTINY,
            _marqueeTick);
        dc.drawText(centerX, _screenHeight * holeY / 100, Graphics.FONT_SMALL,
            "Hole " + (currentHole + 1).format("%d") + " / " + totalHoles.format("%d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(centerX, _screenHeight * parY / 100, Graphics.FONT_XTINY,
            "Par " + par.format("%d") + "   Index " + hcpIndex.format("%d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(centerX, _screenHeight * grossLabelY / 100, Graphics.FONT_XTINY,
            "Gross strokes",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(centerX, _screenHeight * grossY / 100,
            Graphics.FONT_NUMBER_MILD, gross.format("%d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.drawText(_screenWidth * 28 / 100, _screenHeight * controlsY / 100,
            Graphics.FONT_SMALL, "-",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(_screenWidth * 72 / 100, _screenHeight * controlsY / 100,
            Graphics.FONT_SMALL, "+",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(_screenWidth / 3, _screenHeight * navigationY / 100,
            Graphics.FONT_XTINY, "PREV",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(_screenWidth * 2 / 3, _screenHeight * navigationY / 100,
            Graphics.FONT_XTINY, "NEXT",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        syncMarqueeTimer();
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

    function adjustStrokes(delta as Number) as Void {
        var currentHole = _round["currentHole"] as Number;
        var strokes = _round["strokes"] as Array;
        var gross = strokes[currentHole] as Number;
        if (delta > 0 && gross < 99) {
            strokes[currentHole] = gross + 1;
        } else if (delta < 0 && gross > 1) {
            strokes[currentHole] = gross - 1;
        }
        GolfScorecard.saveRound(_round);
        WatchUi.requestUpdate();
    }

    function nextHole() as Void {
        var currentHole = _round["currentHole"] as Number;
        var totalHoles = _round["totalHoles"] as Number;
        if (currentHole >= totalHoles - 1) {
            GolfScorecard.completeRound(_round);
            var summaryView = new SummaryView(_round);
            WatchUi.switchToView(summaryView, new SummaryViewDelegate(summaryView), WatchUi.SLIDE_LEFT);
            return;
        }

        _round["currentHole"] = currentHole + 1;
        GolfScorecard.saveRound(_round);
        WatchUi.requestUpdate();
    }

    function showEndRoundConfirmation() as Void {
        var confirmation = new WatchUi.Confirmation("End this round?");
        WatchUi.pushView(
            confirmation,
            new EndRoundConfirmationDelegate(self),
            WatchUi.SLIDE_IMMEDIATE
        );
    }

    function completeRound() as Void {
        GolfScorecard.completeRound(_round);
        var summaryView = new SummaryView(_round);
        WatchUi.switchToView(
            summaryView,
            new SummaryViewDelegate(summaryView),
            WatchUi.SLIDE_IMMEDIATE
        );
    }

    function scheduleRoundCompletion() as Void {
        _endRoundTimer.start(method(:completeRound), 100, false);
    }

    function previousHole() as Boolean {
        var currentHole = _round["currentHole"] as Number;
        if (currentHole > 0) {
            _round["currentHole"] = currentHole - 1;
            GolfScorecard.saveRound(_round);
            WatchUi.requestUpdate();
            return true;
        }
        return false;
    }

    function handleTap(x as Number, y as Number) as Void {
        var relativeY = y * 100 / _screenHeight;
        if (relativeY >= 60 && relativeY < 76) {
            if (x < _screenWidth * 45 / 100) {
                adjustStrokes(-1);
            } else if (x > _screenWidth * 55 / 100) {
                adjustStrokes(1);
            }
        } else if (relativeY >= 88) {
            if (x < _screenWidth / 2) {
                previousHole();
            } else {
                nextHole();
            }
        }
    }
}

class ActiveHoleViewDelegate extends WatchUi.InputDelegate {
    var _view as ActiveHoleView;

    function initialize(view as ActiveHoleView) {
        InputDelegate.initialize();
        _view = view;
    }

    function onKey(keyEvent as KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_UP) {
            _view.adjustStrokes(1);
            return true;
        } else if (key == WatchUi.KEY_DOWN) {
            _view.adjustStrokes(-1);
            return true;
        } else if (key == WatchUi.KEY_ENTER) {
            _view.showEndRoundConfirmation();
            return true;
        } else if (key == WatchUi.KEY_ESC) {
            return true;
        }
        return false;
    }

    function onTap(clickEvent as ClickEvent) as Boolean {
        var coordinates = clickEvent.getCoordinates();
        _view.handleTap(coordinates[0], coordinates[1]);
        return true;
    }

    function onSwipe(swipeEvent as SwipeEvent) as Boolean {
        var direction = swipeEvent.getDirection();
        if (direction == WatchUi.SWIPE_LEFT) {
            _view.nextHole();
            return true;
        } else if (direction == WatchUi.SWIPE_RIGHT) {
            _view.previousHole();
            return true;
        }
        return false;
    }
}

class EndRoundConfirmationDelegate extends WatchUi.ConfirmationDelegate {
    var _view as ActiveHoleView;

    function initialize(view as ActiveHoleView) {
        ConfirmationDelegate.initialize();
        _view = view;
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            _view.scheduleRoundCompletion();
        }
        return true;
    }
}
