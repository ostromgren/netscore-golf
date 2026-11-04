import Toybox.Lang;
import Toybox.Test;

function assertOutIndexes(loop as Dictionary, expectedIndexes as Array) as Void {
    var holes = loop["holes"] as Array;
    Test.assertEqual(holes.size(), expectedIndexes.size());
    for (var holeNumber = 0; holeNumber < expectedIndexes.size(); holeNumber++) {
        Test.assertEqual(
            (holes[holeNumber] as Dictionary)["outIndex"],
            expectedIndexes[holeNumber]
        );
    }
}

(:test)
function testKarlstadSimulatorProperties(logger as Test.Logger) as Boolean {
    var blue = NetScoreGolf.parseLoopSetting(
        "Blue|5-17,3-5,4-1,4-7,3-15,5-9,4-13,4-3,4-11"
    );
    var red = NetScoreGolf.parseLoopSetting(
        "Red|5-3,3-13,4-5,5-17,4-7,4-1,3-11,4-9,4-15"
    );
    var yellow = NetScoreGolf.parseLoopSetting(
        "Yellow|4-01,5-07,3-11,4-3,4-15,3-9,4-13,4-5,5-17"
    );

    Test.assert(blue != null);
    Test.assert(red != null);
    Test.assert(yellow != null);

    var blueLoop = blue as Dictionary;
    var redLoop = red as Dictionary;
    var yellowLoop = yellow as Dictionary;
    assertOutIndexes(blueLoop, [17, 5, 1, 7, 15, 9, 13, 3, 11]);
    assertOutIndexes(redLoop, [3, 13, 5, 17, 7, 1, 11, 9, 15]);
    assertOutIndexes(yellowLoop, [1, 7, 11, 3, 15, 9, 13, 5, 17]);

    Test.assertEqual(NetScoreGolf.parseHandicapIndex("5"), 5);
    Test.assertEqual(NetScoreGolf.parseHandicapIndex("05"), 5);
    Test.assertEqual(NetScoreGolf.getNineHoleRank(blueLoop, 5), 3);
    Test.assertEqual(NetScoreGolf.getNineHoleRank(blueLoop, 17), 9);
    Test.assertEqual(blueLoop["hasInIndexes"], false);
    Test.assert(!NetScoreGolf.hasValidCombinedIndexes(blueLoop, redLoop));
    return true;
}

(:test)
function testNineHoleRoundUsesPublishedOutIndexes(logger as Test.Logger) as Boolean {
    var yellow = NetScoreGolf.parseLoopSetting(
        "Yellow|4-1-2,5-7-8,3-11-12,4-3-4,4-15-16,3-9-10,4-13-14,4-5-6,5-17-18"
    );
    Test.assert(yellow != null);

    var round = NetScoreGolf.createRound(
        { "name" => "Karlstad GK" },
        yellow as Dictionary,
        null as Dictionary?,
        9,
        19
    );
    var scores = [5, 6, 5, 6, 4, 4, 5, 5, 6];
    round["strokes"] = scores;
    NetScoreGolf.completeRound(round);

    var holes = round["holes"] as Array;
    var expectedOutIndexes = [1, 7, 11, 3, 15, 9, 13, 5, 17];
    for (var holeNumber = 0; holeNumber < expectedOutIndexes.size(); holeNumber++) {
        Test.assertEqual(
            (holes[holeNumber] as Dictionary)["strokeRank"],
            expectedOutIndexes[holeNumber]
        );
    }
    Test.assertEqual(round["totalGrossStrokes"], 46);
    Test.assertEqual(round["totalNetStrokes"], 36);
    Test.assertEqual(round["totalPoints"], 18);

    var totalsAtHandicap18 = ScoreCalculator.calculateRoundTotals(holes, scores, 18);
    Test.assertEqual(totalsAtHandicap18["net"], 37);
    Test.assertEqual(totalsAtHandicap18["points"], 17);
    return true;
}

(:test)
function testLastHandicapPersists(logger as Test.Logger) as Boolean {
    NetScoreGolf.saveLastHandicap(19);
    Test.assertEqual(NetScoreGolf.getLastHandicap(), 19);
    NetScoreGolf.saveLastHandicap(-1);
    Test.assertEqual(NetScoreGolf.getLastHandicap(), -1);
    NetScoreGolf.saveLastHandicap(18);
    Test.assertEqual(NetScoreGolf.getLastHandicap(), 18);
    return true;
}

(:test)
function testPlusHandicapUsesHighestIndexes(logger as Test.Logger) as Boolean {
    Test.assertEqual(ScoreCalculator.getStrokesOnHole(-1, 18, 18), -1);
    Test.assertEqual(ScoreCalculator.getStrokesOnHole(-1, 17, 18), 0);
    Test.assertEqual(ScoreCalculator.getStrokesOnHole(-2, 17, 18), -1);
    Test.assertEqual(ScoreCalculator.getStrokesOnHole(-2, 16, 18), 0);
    Test.assertEqual(ScoreCalculator.calculateStablefordPoints(4, 3, -1), 2);

    var holes = [];
    var scores = [];
    for (var index = 1; index <= 18; index++) {
        holes.add({ "par" => 4, "strokeRank" => index });
        scores.add(4);
    }
    var totals = ScoreCalculator.calculateRoundTotals(holes, scores, -1);
    Test.assertEqual(totals["net"], 73);
    Test.assertEqual(totals["points"], 35);
    return true;
}

(:test)
function testBrynganSimulatorProperties(logger as Test.Logger) as Boolean {
    var bryngan = NetScoreGolf.parseLoopSetting(
        "18|3-07,4-05,4-11,4-03,5-15,3-13,4-01,4-09,5-17,3-14,5-4,4-12,4-2,4-10,3-18,5-6,4-16,4-8"
    );
    Test.assert(bryngan != null);

    var brynganLoop = bryngan as Dictionary;
    var holes = brynganLoop["holes"] as Array;
    var expectedIndexes = [7, 5, 11, 3, 15, 13, 1, 9, 17, 14, 4, 12, 2, 10, 18, 6, 16, 8];
    Test.assertEqual(brynganLoop["totalHoles"], 18);
    Test.assertEqual(holes.size(), expectedIndexes.size());
    for (var holeNumber = 0; holeNumber < expectedIndexes.size(); holeNumber++) {
        Test.assertEqual(
            (holes[holeNumber] as Dictionary)["hcp"],
            expectedIndexes[holeNumber]
        );
    }
    return true;
}

(:test)
function testOutInLoopCombination(logger as Test.Logger) as Boolean {
    var firstLoop = NetScoreGolf.parseLoopSetting(
        "First|4-1-2,4-3-4,4-5-6,4-7-8,4-9-10,4-11-12,4-13-14,4-15-16,4-17-18"
    );
    var secondLoop = NetScoreGolf.parseLoopSetting(
        "Second|4-1-2,4-3-4,4-5-6,4-7-8,4-9-10,4-11-12,4-13-14,4-15-16,4-17-18"
    );
    Test.assert(firstLoop != null);
    Test.assert(secondLoop != null);
    Test.assert(NetScoreGolf.hasValidCombinedIndexes(
        firstLoop as Dictionary,
        secondLoop as Dictionary
    ));
    return true;
}

(:test)
function testLocalIndexesNormalizeForEighteenHoles(logger as Test.Logger) as Boolean {
    var firstLoop = NetScoreGolf.parseLoopSetting(
        "First|4-1-1,4-2-2,4-3-3,4-4-4,4-5-5,4-6-6,4-7-7,4-8-8,4-9-9"
    );
    var secondLoop = NetScoreGolf.parseLoopSetting(
        "Second|4-1-1,4-2-2,4-3-3,4-4-4,4-5-5,4-6-6,4-7-7,4-8-8,4-9-9"
    );
    Test.assert(firstLoop != null);
    Test.assert(secondLoop != null);

    var first = firstLoop as Dictionary;
    var second = secondLoop as Dictionary;
    Test.assert(NetScoreGolf.hasValidCombinedIndexes(first, second));

    var round = NetScoreGolf.createRound(
        { "name" => "Local indexes" },
        first,
        second,
        18,
        18
    );
    var holes = round["holes"] as Array;
    Test.assertEqual((holes[0] as Dictionary)["hcp"], 1);
    Test.assertEqual((holes[8] as Dictionary)["hcp"], 9);
    Test.assertEqual((holes[9] as Dictionary)["hcp"], 10);
    Test.assertEqual((holes[17] as Dictionary)["hcp"], 18);
    return true;
}