import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class SummaryView extends WatchUi.View {
    var _round as Dictionary;

    function initialize(round as Dictionary) {
        View.initialize();
        _round = round;
    }

    function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        var totalGrossStrokes = _round["totalGrossStrokes"] as Number;
        var totalNetStrokes = _round["totalNetStrokes"] as Number;
        var totalPoints = _round["totalPoints"] as Number;
        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;
        dc.drawText(centerX, centerY - dc.getHeight() * 14 / 100,
            Graphics.FONT_MEDIUM,
            "Gross: " + totalGrossStrokes.format("%d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(centerX, centerY,
            Graphics.FONT_MEDIUM,
            "Net: " + totalNetStrokes.format("%d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(centerX, centerY + dc.getHeight() * 14 / 100,
            Graphics.FONT_MEDIUM,
            "Pts: " + totalPoints.format("%d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function resetRound() as Void {
        GolfScorecard.clearRound();
        var configuration = GolfScorecard.loadConfiguredCourses();
        var view = new CourseSelectView(configuration);
        WatchUi.switchToView(view, new CourseSelectViewDelegate(view), WatchUi.SLIDE_RIGHT);
    }
}

class SummaryViewDelegate extends WatchUi.InputDelegate {
    var _view as SummaryView;

    function initialize(view as SummaryView) {
        InputDelegate.initialize();
        _view = view;
    }

    function onKey(keyEvent as KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_ESC) {
            _view.resetRound();
            return true;
        }
        return false;
    }

    function onTap(clickEvent as ClickEvent) as Boolean {
        _view.resetRound();
        return true;
    }
}
