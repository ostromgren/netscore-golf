import Toybox.Application;
import Toybox.Application.Properties;
import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.WatchUi;

class NetScoreGolf {

    public static function loadConfiguredCourses() as Dictionary {
        var courses = [];
        var errors = [];

        for (var slot = 1; slot <= 10; slot++) {
            var nameValue = Properties.getValue("course" + slot.format("%d") + "Name");
            var name = (nameValue instanceof String) ? nameValue as String : "";
            var loops = [];
            var hasNewLoopSettings = false;
            var hasInvalidLoop = false;

            for (var loopSlot = 0; loopSlot < 4; loopSlot++) {
                var loopLetter = ["A", "B", "C", "D"][loopSlot];
                var loopValue = Properties.getValue(
                    "course" + slot.format("%d") + "Loop" + loopLetter
                );
                var loopData = (loopValue instanceof String) ? loopValue as String : "";
                if (!loopData.equals("")) {
                    hasNewLoopSettings = true;
                    var loop = parseLoopSetting(loopData);
                    if (loop == null) {
                        hasInvalidLoop = true;
                        errors.add(
                            "Course " + slot.format("%d") + " Loop " +
                            loopLetter + ": " + describeLoopSettingError(loopData)
                        );
                    } else {
                        loops.add(loop);
                    }
                }
            }

            if (!hasNewLoopSettings) {
                var legacyValue = Properties.getValue("course" + slot.format("%d") + "Loops");
                var legacyData = (legacyValue instanceof String) ? legacyValue as String : "";
                if (name.equals("") && legacyData.equals("")) {
                    continue;
                }

                var legacyCourse = parseCourse(name, legacyData);
                if (legacyCourse != null) {
                    courses.add(legacyCourse);
                } else {
                    errors.add("Course " + slot.format("%d") + ": invalid legacy loop data");
                }
            } else if (name.equals("") || loops.size() == 0 || hasInvalidLoop) {
                if (name.equals("")) {
                    errors.add("Course " + slot.format("%d") + ": course name is blank");
                }
                if (loops.size() == 0 && !hasInvalidLoop) {
                    errors.add("Course " + slot.format("%d") + ": no valid loops found");
                }
            } else {
                courses.add({ "name" => name, "loops" => loops });
            }
        }

        return { "courses" => courses, "errors" => errors };
    }

    public static function splitString(value as String, delimiter as String) as Array<String> {
        var parts = [];
        var remaining = value;
        while (true) {
            var delimiterIndex = remaining.find(delimiter);
            if (delimiterIndex == null) {
                parts.add(remaining);
                break;
            }

            var index = delimiterIndex as Number;
            parts.add(remaining.substring(0, index));
            remaining = remaining.substring(index + delimiter.length(), remaining.length());
        }
        return parts as Array<String>;
    }

    public static function describeLoopSettingError(value as String) as String {
        var fields = splitString(value, "|");
        if (fields.size() != 2) {
            return "use LoopName|par-index,...";
        }
        if (fields[0].equals("")) {
            return "loop name is blank";
        }
        if (fields[1].equals("")) {
            return "hole list is blank";
        }

        var holeEntries = splitString(fields[1], ",");
        var totalHoles = holeEntries.size();
        if (totalHoles != 9 && totalHoles != 18) {
            return "enter exactly 9 or 18 holes";
        }

        var usedIndices = [
            false, false, false, false, false, false, false, false, false,
            false, false, false, false, false, false, false, false, false, false
        ];
        for (var i = 0; i < totalHoles; i++) {
            var pair = splitString(holeEntries[i], "-");
            if (pair.size() != 2) {
                return "each hole must use par-index";
            }

            if (!pair[0].equals("3") && !pair[0].equals("4") &&
                !pair[0].equals("5")) {
                return "hole " + (i + 1).format("%d") + " par [" +
                    pair[0] + "] invalid";
            }

            var hcpIndex = 0;
            for (var candidate = 1; candidate <= totalHoles; candidate++) {
                if (pair[1].equals(candidate.format("%02d")) ||
                    pair[1].equals(candidate.format("%d"))) {
                    hcpIndex = candidate;
                }
            }
            if (hcpIndex == 0) {
                return "index must be 1-" + totalHoles.format("%d");
            }
            if (usedIndices[hcpIndex]) {
                return "handicap indexes must be unique";
            }
            usedIndices[hcpIndex] = true;
        }

        return "invalid loop data";
    }

    public static function parseLoopSetting(value as String) as Dictionary? {
        var fields = splitString(value, "|");
        if (fields.size() != 2 || fields[0].equals("") || fields[1].equals("")) {
            return null;
        }

        var holeEntries = splitString(fields[1], ",");
        var totalHoles = holeEntries.size();
        if (totalHoles != 9 && totalHoles != 18) {
            return null;
        }

        var holes = [];
        var usedIndices = [
            false, false, false, false, false, false, false, false, false,
            false, false, false, false, false, false, false, false, false, false
        ];
        for (var i = 0; i < totalHoles; i++) {
            var pair = splitString(holeEntries[i], "-");
            if (pair.size() != 2) {
                return null;
            }

            var par = 0;
            if (pair[0].equals("3")) {
                par = 3;
            } else if (pair[0].equals("4")) {
                par = 4;
            } else if (pair[0].equals("5")) {
                par = 5;
            }

            var hcpIndex = 0;
            for (var candidate = 1; candidate <= totalHoles; candidate++) {
                if (pair[1].equals(candidate.format("%02d")) ||
                    pair[1].equals(candidate.format("%d"))) {
                    hcpIndex = candidate;
                }
            }
            if (par == 0 || hcpIndex == 0 || usedIndices[hcpIndex]) {
                return null;
            }

            usedIndices[hcpIndex] = true;
            holes.add({ "par" => par, "hcp" => hcpIndex });
        }

        return {
            "name" => fields[0],
            "totalHoles" => totalHoles,
            "holes" => holes
        };
    }

    public static function parseCourse(name as String, data as String) as Dictionary? {
        if (name.equals("") || data.equals("")) {
            return null;
        }

        var records = splitString(data, ";");
        if (records.size() > 4) {
            return null;
        }

        var loops = [];
        for (var i = 0; i < records.size(); i++) {
            var fields = splitString(records[i], "~");
            if (fields.size() != 3 || fields[0].equals("")) {
                return null;
            }

            var totalHoles = 0;
            if (fields[1].equals("9")) {
                totalHoles = 9;
            } else if (fields[1].equals("18")) {
                totalHoles = 18;
            }
            if (totalHoles == 0) {
                return null;
            }

            var holeData = fields[2];
            if (holeData.length() != totalHoles * 3) {
                return null;
            }

            var holes = [];
            var usedIndices = [
                false, false, false, false, false, false, false, false, false,
                false, false, false, false, false, false, false, false, false, false
            ];
            for (var holeIndex = 0; holeIndex < totalHoles; holeIndex++) {
                var offset = holeIndex * 3;
                var parTextValue = holeData.substring(offset, offset + 1);
                var hcpTextValue = holeData.substring(offset + 1, offset + 3);
                if (!(parTextValue instanceof String) ||
                    !(hcpTextValue instanceof String)) {
                    return null;
                }
                var parText = parTextValue as String;
                var hcpText = hcpTextValue as String;
                var par = 0;
                if (parText.equals("3")) {
                    par = 3;
                } else if (parText.equals("4")) {
                    par = 4;
                } else if (parText.equals("5")) {
                    par = 5;
                }

                var hcpIndex = 0;
                for (var candidate = 1; candidate <= totalHoles; candidate++) {
                    if (hcpText.equals(candidate.format("%02d"))) {
                        hcpIndex = candidate;
                    }
                }
                if (par == 0 || hcpIndex == 0 || usedIndices[hcpIndex]) {
                    return null;
                }

                usedIndices[hcpIndex] = true;
                holes.add({ "par" => par, "hcp" => hcpIndex });
            }

            loops.add({
                "name" => fields[0],
                "totalHoles" => totalHoles,
                "holes" => holes
            });
        }

        return { "name" => name, "loops" => loops };
    }

    public static function createRound(course as Dictionary, loopA as Dictionary, loopB as Dictionary?, totalHoles as Number, handicap as Number) as Dictionary {
        if ((totalHoles != 9 && totalHoles != 18) || handicap < 0 ||
            (totalHoles == 9 && (loopA["totalHoles"] as Number) != 9) ||
            (totalHoles == 18 &&
                ((loopA["totalHoles"] as Number) == 18 && loopB != null ||
                 (loopA["totalHoles"] as Number) == 9 &&
                    (loopB == null || (loopB["totalHoles"] as Number) != 9)))) {
            throw new Lang.InvalidValueException("Invalid round setup");
        }

        var holes = [];
        var strokes = [];
        for (var i = 0; i < totalHoles; i++) {
            var selectedLoop = loopA;
            if (totalHoles == 18 && (loopA["totalHoles"] as Number) == 9 && i >= 9) {
                selectedLoop = loopB as Dictionary;
            }

            var sourceHoles = selectedLoop["holes"] as Array;
            var sourceHole = sourceHoles[
                (selectedLoop["totalHoles"] as Number) == 9 ? i % 9 : i
            ] as Dictionary;
            var hcpIndex = sourceHole["hcp"] as Number;
            if (totalHoles == 18 &&
                (loopA["totalHoles"] as Number) == 9 && i >= 9) {
                hcpIndex += 9;
            }
            holes.add({
                "par" => sourceHole["par"] as Number,
                "hcp" => hcpIndex
            });
            strokes.add(sourceHole["par"] as Number);
        }

        var courseName = course["name"] as String;
        courseName += " - " + (loopA["name"] as String);
        if (loopB != null) {
            courseName += " / " + (loopB["name"] as String);
        }

        var round = {
            "courseName" => courseName,
            "totalHoles" => totalHoles,
            "handicap" => handicap,
            "holes" => holes,
            "strokes" => strokes,
            "currentHole" => 0,
            "completed" => false
        };
        Storage.setValue("activeRound", round as Application.Storage.ValueType);
        return round;
    }

    public static function getActiveRound() as Dictionary? {
        var round = Storage.getValue("activeRound");
        return (round instanceof Dictionary) ? round as Dictionary : null;
    }

    public static function saveRound(round as Dictionary) as Void {
        Storage.setValue("activeRound", round as Application.Storage.ValueType);
    }

    public static function completeRound(round as Dictionary) as Void {
        var totals = ScoreCalculator.calculateRoundTotals(
            round["holes"] as Array,
            round["strokes"] as Array,
            round["handicap"] as Number
        );
        round["totalGrossStrokes"] = totals["gross"] as Number;
        round["totalNetStrokes"] = totals["net"] as Number;
        round["totalPoints"] = totals["points"] as Number;
        round["completed"] = true;
        Storage.setValue("activeRound", round as Application.Storage.ValueType);
    }

    public static function clearRound() as Void {
        Storage.deleteValue("activeRound");
    }
}

class NetScoreGolfApp extends Application.AppBase {
    var _courseSelectView as CourseSelectView?;

    function initialize() {
        AppBase.initialize();
        _courseSelectView = null;
    }

    function onSettingsChanged() as Void {
        if (_courseSelectView != null) {
            (_courseSelectView as CourseSelectView).refreshConfiguration();
        }
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        _courseSelectView = null;
        var round = NetScoreGolf.getActiveRound();
        if (round != null) {
            if (round["completed"] as Boolean) {
                NetScoreGolf.completeRound(round);
                var summaryView = new SummaryView(round);
                return [summaryView, new SummaryViewDelegate(summaryView)];
            }

            var currentHole = round["currentHole"] as Number;
            var totalHoles = round["totalHoles"] as Number;
            if (currentHole >= 0 && currentHole < totalHoles) {
                var activeView = new ActiveHoleView(round);
                return [activeView, new ActiveHoleViewDelegate(activeView)];
            }
            NetScoreGolf.clearRound();
        }

        var configuration = NetScoreGolf.loadConfiguredCourses();
        var courseView = new CourseSelectView(configuration);
        _courseSelectView = courseView;
        return [courseView, new CourseSelectViewDelegate(courseView)];
    }
}
