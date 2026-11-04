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
                if (!name.equals("")) {
                    errors.add("Course " + slot.format("%d") + ": no loops configured");
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

    public static function parseHandicapIndex(value as String) as Number {
        for (var candidate = 1; candidate <= 18; candidate++) {
            if (value.equals(candidate.format("%02d")) ||
                value.equals(candidate.format("%d"))) {
                return candidate;
            }
        }
        return 0;
    }

    public static function describeLoopSettingError(value as String) as String {
        var fields = splitString(value, "|");
        if (fields.size() != 2) {
            return "use LoopName|par-index,... or LoopName|par-UT-IN,...";
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

        var usedOutIndexes = [
            false, false, false, false, false, false, false, false, false,
            false, false, false, false, false, false, false, false, false, false
        ];
        var usedInIndexes = [
            false, false, false, false, false, false, false, false, false,
            false, false, false, false, false, false, false, false, false, false
        ];
        var expectedParts = 2;
        for (var i = 0; i < totalHoles; i++) {
            var pair = splitString(holeEntries[i], "-");
            if (totalHoles == 9 && i == 0) {
                if (pair.size() != 2 && pair.size() != 3) {
                    return "9-hole entries use par-index or par-UT-IN-index";
                }
                expectedParts = pair.size();
            }
            if (pair.size() != expectedParts) {
                return "all holes in a loop must use the same index format";
            }

            if (!pair[0].equals("3") && !pair[0].equals("4") &&
                !pair[0].equals("5")) {
                return "hole " + (i + 1).format("%d") + " par [" +
                    pair[0] + "] invalid";
            }

            var outIndex = parseHandicapIndex(pair[1] as String);
            var inIndex = (totalHoles == 9 && expectedParts == 3) ?
                parseHandicapIndex(pair[2] as String) : outIndex;
            if (outIndex == 0 || inIndex == 0) {
                return "indexes must be from 1 to 18";
            }
            if (usedOutIndexes[outIndex] ||
                (totalHoles == 9 && expectedParts == 3 && usedInIndexes[inIndex])) {
                return "indexes must be unique within each set";
            }
            usedOutIndexes[outIndex] = true;
            if (totalHoles == 9 && expectedParts == 3) {
                usedInIndexes[inIndex] = true;
            }
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
        var usedOutIndexes = [
            false, false, false, false, false, false, false, false, false,
            false, false, false, false, false, false, false, false, false, false
        ];
        var usedInIndexes = [
            false, false, false, false, false, false, false, false, false,
            false, false, false, false, false, false, false, false, false, false
        ];
        var nineHoleHasInIndexes = false;
        for (var i = 0; i < totalHoles; i++) {
            var pair = splitString(holeEntries[i], "-");
            if (totalHoles == 9 && i == 0) {
                if (pair.size() != 2 && pair.size() != 3) {
                    return null;
                }
                nineHoleHasInIndexes = pair.size() == 3;
            }
            var expectedParts = (totalHoles == 18 || !nineHoleHasInIndexes) ? 2 : 3;
            if (pair.size() != expectedParts) {
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

            var outIndex = parseHandicapIndex(pair[1] as String);
            var inIndex = (totalHoles == 9 && nineHoleHasInIndexes) ?
                parseHandicapIndex(pair[2] as String) : outIndex;
            if (par == 0 || outIndex == 0 || inIndex == 0 ||
                usedOutIndexes[outIndex] ||
                (totalHoles == 9 && nineHoleHasInIndexes && usedInIndexes[inIndex])) {
                return null;
            }

            usedOutIndexes[outIndex] = true;
            if (totalHoles == 9 && nineHoleHasInIndexes) {
                usedInIndexes[inIndex] = true;
            }
            if (totalHoles == 9) {
                holes.add({
                    "par" => par,
                    "outIndex" => outIndex,
                    "inIndex" => (nineHoleHasInIndexes ? inIndex : 0)
                });
            } else {
                holes.add({ "par" => par, "hcp" => outIndex });
            }
        }

        return {
            "name" => fields[0],
            "totalHoles" => totalHoles,
            "hasInIndexes" => nineHoleHasInIndexes,
            "holes" => holes
        };
    }

    public static function getNineHoleRank(loop as Dictionary, hcpIndex as Number) as Number {
        var holes = loop["holes"] as Array;
        var rank = 1;
        for (var i = 0; i < holes.size(); i++) {
            if (((holes[i] as Dictionary)["outIndex"] as Number) < hcpIndex) {
                rank += 1;
            }
        }
        return rank;
    }

    public static function hasValidCombinedIndexes(loopA as Dictionary, loopB as Dictionary) as Boolean {
        if ((loopA["totalHoles"] as Number) != 9 ||
            (loopB["totalHoles"] as Number) != 9) {
            return false;
        }

        if (usesLocalNineHoleIndexes(loopA, loopB)) {
            return true;
        }

        var usedIndexes = [
            false, false, false, false, false, false, false, false, false,
            false, false, false, false, false, false, false, false, false, false
        ];
        var holesA = loopA["holes"] as Array;
        var holesB = loopB["holes"] as Array;
        for (var i = 0; i < 9; i++) {
            var outIndex = (holesA[i] as Dictionary)["outIndex"] as Number;
            var inIndex = (holesB[i] as Dictionary)["inIndex"] as Number;
            if (outIndex < 1 || outIndex > 18 || inIndex < 1 || inIndex > 18 ||
                usedIndexes[outIndex] || usedIndexes[inIndex]) {
                return false;
            }
            usedIndexes[outIndex] = true;
            usedIndexes[inIndex] = true;
        }

        for (var index = 1; index <= 18; index++) {
            if (!usedIndexes[index]) {
                return false;
            }
        }
        return true;
    }

    public static function usesLocalNineHoleIndexes(loopA as Dictionary, loopB as Dictionary) as Boolean {
        var holesA = loopA["holes"] as Array;
        var holesB = loopB["holes"] as Array;
        if (holesA.size() != 9 || holesB.size() != 9) {
            return false;
        }

        for (var i = 0; i < 9; i++) {
            var outIndex = (holesA[i] as Dictionary)["outIndex"] as Number;
            var inIndex = (holesB[i] as Dictionary)["inIndex"] as Number;
            if (outIndex < 1 || outIndex > 9 || inIndex < 1 || inIndex > 9) {
                return false;
            }
        }
        return true;
    }

    public static function createRound(course as Dictionary, loopA as Dictionary, loopB as Dictionary?, totalHoles as Number, handicap as Number) as Dictionary {
        if ((totalHoles != 9 && totalHoles != 18) || handicap < -54 || handicap > 54 ||
            (totalHoles == 9 && (loopA["totalHoles"] as Number) != 9) ||
            (totalHoles == 18 &&
                ((loopA["totalHoles"] as Number) == 18 && loopB != null ||
                 (loopA["totalHoles"] as Number) == 9 &&
                    (loopB == null || (loopB["totalHoles"] as Number) != 9)))) {
            throw new Lang.InvalidValueException("Invalid round setup");
        }
        if (totalHoles == 18 && (loopA["totalHoles"] as Number) == 9 &&
            !hasValidCombinedIndexes(loopA, loopB as Dictionary)) {
            throw new Lang.InvalidValueException("Combined loop indexes must cover 1 to 18");
        }
        var localNineHoleIndexes = totalHoles == 18 &&
            (loopA["totalHoles"] as Number) == 9 &&
            usesLocalNineHoleIndexes(loopA, loopB as Dictionary);

        var holes = [];
        var strokes = [];
        var usedStrokeRanks = [
            false, false, false, false, false, false, false, false, false,
            false, false, false, false, false, false, false, false, false, false
        ];
        for (var i = 0; i < totalHoles; i++) {
            var selectedLoop = loopA;
            if (totalHoles == 18 && (loopA["totalHoles"] as Number) == 9 && i >= 9) {
                selectedLoop = loopB as Dictionary;
            }

            var sourceHoles = selectedLoop["holes"] as Array;
            var sourceHole = sourceHoles[
                (selectedLoop["totalHoles"] as Number) == 9 ? i % 9 : i
            ] as Dictionary;
            var hcpIndex = 0;
            var strokeRank = 0;
            if (totalHoles == 9) {
                hcpIndex = sourceHole["outIndex"] as Number;
                strokeRank = hcpIndex;
            } else if ((loopA["totalHoles"] as Number) == 9) {
                hcpIndex = (i < 9) ?
                    sourceHole["outIndex"] as Number :
                    sourceHole["inIndex"] as Number;
                if (i >= 9 && localNineHoleIndexes) {
                    hcpIndex += 9;
                }
                strokeRank = hcpIndex;
            } else {
                hcpIndex = sourceHole["hcp"] as Number;
                strokeRank = hcpIndex;
            }
            if (hcpIndex < 1 || hcpIndex > 18 || strokeRank < 1 ||
                strokeRank > 18 || usedStrokeRanks[strokeRank]) {
                throw new Lang.InvalidValueException("Round handicap indexes must be unique and in range");
            }
            usedStrokeRanks[strokeRank] = true;
            holes.add({
                "par" => sourceHole["par"] as Number,
                "hcp" => hcpIndex,
                "strokeRank" => strokeRank
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

    public static function getLastHandicap() as Number {
        var storedValue = Storage.getValue("lastHandicap");
        if (storedValue instanceof Number) {
            var handicap = storedValue as Number;
            if (handicap >= -54 && handicap <= 54) {
                return handicap;
            }
        }
        return 18;
    }

    public static function saveLastHandicap(handicap as Number) as Void {
        if (handicap >= -54 && handicap <= 54) {
            Storage.setValue("lastHandicap", handicap as Application.Storage.ValueType);
        }
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
