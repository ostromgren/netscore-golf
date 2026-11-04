import Toybox.Lang;

class ScoreCalculator {

    public static function getStrokesOnHole(handicap as Number, hcpIndex as Number, totalHoles as Number) as Number {
        if ((totalHoles != 9 && totalHoles != 18) || handicap < -54 || handicap > 54 ||
            hcpIndex < 1 || hcpIndex > totalHoles) {
            throw new Lang.InvalidValueException("Invalid handicap, hole index, or hole count");
        }

        var absoluteHandicap = (handicap < 0) ? -handicap : handicap;
        var baseStrokes = absoluteHandicap / totalHoles;
        var remainder = absoluteHandicap % totalHoles;
        if (handicap < 0) {
            return 0 - baseStrokes - ((hcpIndex > totalHoles - remainder) ? 1 : 0);
        }
        return baseStrokes + ((hcpIndex <= remainder) ? 1 : 0);
    }

    public static function calculateStablefordPoints(par as Number, grossStrokes as Number, strokesReceived as Number) as Number {
        var points = (par + 2) - (grossStrokes - strokesReceived);
        return (points < 0) ? 0 : points;
    }

    public static function calculateTotalScore(holesData as Array, strokesArray as Array, playingHandicap as Number) as Number {
        var totals = calculateRoundTotals(holesData, strokesArray, playingHandicap);
        return totals["points"] as Number;
    }

    public static function calculateRoundTotals(holesData as Array, strokesArray as Array, playingHandicap as Number) as Dictionary {
        var totalHoles = holesData.size();
        if ((totalHoles != 9 && totalHoles != 18) ||
            strokesArray.size() != totalHoles || playingHandicap < -54 ||
            playingHandicap > 54) {
            throw new Lang.InvalidValueException("Round data must contain 9 or 18 holes and matching scores");
        }

        var handicapHoles = (totalHoles == 9) ? 18 : totalHoles;
        var totalPoints = 0;
        var totalGrossStrokes = 0;
        var totalNetStrokes = 0;
        for (var i = 0; i < totalHoles; i++) {
            var hole = holesData[i] as Dictionary;
            var par = hole["par"] as Number;
            var strokeRankValue = hole["strokeRank"];
            var strokeRank = (strokeRankValue instanceof Number) ?
                strokeRankValue as Number : hole["hcp"] as Number;
            var gross = strokesArray[i] as Number;
            var received = getStrokesOnHole(playingHandicap, strokeRank, handicapHoles);
            totalGrossStrokes += gross;
            totalNetStrokes += gross - received;
            totalPoints += calculateStablefordPoints(par, gross, received);
        }

        return {
            "gross" => totalGrossStrokes,
            "net" => totalNetStrokes,
            "points" => totalPoints
        };
    }

}
