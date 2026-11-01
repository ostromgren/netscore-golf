import Toybox.Graphics;
import Toybox.Lang;

class MarqueeText {

    public static function draw(
        dc as Dc,
        text as String,
        centerX as Number,
        y as Number,
        maxWidth as Number,
        font as Graphics.FontType,
        tick as Number
    ) as Boolean {
        var textWidth = dc.getTextWidthInPixels(text, font);
        if (textWidth <= maxWidth) {
            dc.drawText(centerX, y, font, text,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return false;
        }

        var travel = textWidth - maxWidth;
        var hold = 4;
        var cycle = travel * 2 + hold * 2;
        var phase = (tick * 3) % cycle;
        var offset = 0;
        if (phase < travel) {
            offset = phase;
        } else if (phase < travel + hold) {
            offset = travel;
        } else if (phase < travel * 2 + hold) {
            offset = travel * 2 + hold - phase;
        }

        var left = centerX - maxWidth / 2;
        var fontHeight = dc.getFontHeight(font);
        dc.setClip(left, y - fontHeight / 2, maxWidth, fontHeight);
        dc.drawText(left - offset, y, font, text,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.clearClip();
        return true;
    }
}
