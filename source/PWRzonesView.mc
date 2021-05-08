using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;

class PWRzonesView extends Ui.DataField {
    // color scheme for active zones on white background
    var colorsActiveWhite = [
        Gfx.COLOR_TRANSPARENT,
        0x0080FF,  // 1 blue
        0x00C000,  // 2 green
        0xFFA000,  // 3 yellow
        0xFF6000,  // 4 orange
        0xFF0000,  // 5 red
        0x5500AA,  // 6 purple
        0x202020,  // 7 dark grey
    ];
    // color scheme for dimmed zones on white background
    // TODO: Make brighter
    var colorsDimmedWhite = [
        Gfx.COLOR_TRANSPARENT,
        0xC0E0FF, // 1 blue
        0xC0FFC0, // 2 green
        0xFFE7C0, // 3 yellow
        0xFFD7C0, // 4 orange
        0xFFC0C0, // 5 red
        0xE0C0FF, // 6 purple
        0xC0C0C0, // 7 light grey
    ];
    // color scheme for active zones on black background
    var colorsActiveBlack = [
        Gfx.COLOR_TRANSPARENT,
        0x00FFFF,  // 1 blue
        0x00FF00,  // 2 green
        0xFFAA00,  // 3 yellow
        0xFF5500,  // 4 orange
        0xFF0000,  // 5 red
        0x5500AA,  // 6 purple
        0xC0C0C0,  // 7 light grey
    ];
    // color scheme for dimmed zones on black background
    var colorsDimmedBlack = [
        Gfx.COLOR_TRANSPARENT,
        0x00557F, // 1 teal
        0x007F00, // 2 green
        0x7F5500, // 3 yellow
        0x7F2A00, // 4 orange
        0x7F0000, // 5 red
        0x2A0055, // 6 purple
        0x202020, // 7 dark grey
    ];
    hidden var pValue;
    hidden var pwrAvg = 0;
    hidden var pwrZoneAvg = 0;
    hidden var zone;
    hidden var zonePercent;
    // variables that store text position and dimensions
    hidden var fWidth = -1;
    hidden var fHeight = -1;
    hidden var yZone;
    hidden var xPower;
    hidden var yPower;
    hidden var yUnit;
    hidden var xHorizontalBar;
    hidden var wHorizontalBar;
    hidden var hHorizontalBar;
    hidden var powerFont = Gfx.FONT_NUMBER_MILD;
    hidden var zoneFont = Gfx.FONT_TINY;
    hidden var unitFont = Gfx.FONT_SMALL;

    // pwrBuffer is used to calculate rolling average of power.
    // Every second (ie. when compute() is called) storing reported power value
    // each second , and then
    var pwrBuffer = new [PWR_BUFFER_SIZE];
    var zoneBuffer = new [ZONE_BUFFER_SIZE];
    hidden var pwrBufOffset;
    hidden var zoneBufOffset;

    function initialize() {
        DataField.initialize();
        pValue = 0.0f;
        // fill power value buffers with zeroes at start
        var i;
        for(i = 0; i < PWR_BUFFER_SIZE; i++) {
            pwrBuffer[i] = 0;
        }
        for(i = 0; i < ZONE_BUFFER_SIZE; i++) {
            zoneBuffer[i] = 0;
        }
        zoneBufOffset = 0; pwrBufOffset = 0;
        zone = 0; zonePercent = 0;
    }

    function isSingleFieldLayout() {
        return (DataField.getObscurityFlags() == OBSCURE_TOP | OBSCURE_LEFT | OBSCURE_BOTTOM | OBSCURE_RIGHT);
    }

    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info) {
        if(info has :currentPower){
            if(info.currentPower != null){
                pValue = info.currentPower;
            } else {
                pValue = 0;
            }
        }
        else {
            return;
        }
        // store current power value into both buffers and increment pointers
        pwrBuffer[pwrBufOffset] = pValue;
        zoneBuffer[zoneBufOffset] = pValue;
        pwrBufOffset++;
        pwrBufOffset = (pwrBufOffset == pwrAvgCount) ? 0 : pwrBufOffset;
        zoneBufOffset++;
        zoneBufOffset = (zoneBufOffset == zoneAvgCount) ? 0 : zoneBufOffset;

        // get rolling average of power for display of power
        pwrAvg = 0;
        for (var i = 0; i < pwrAvgCount; i++) {
            pwrAvg += pwrBuffer[i];
        }
        pwrAvg = pwrAvg / pwrAvgCount;

        // get rolling average of power for zone calculation
        pwrZoneAvg = 0;
        for (var i = 0; i < zoneAvgCount; i++) {
            pwrZoneAvg += zoneBuffer[i];
        }
        pwrZoneAvg = pwrZoneAvg / zoneAvgCount;

        // calculate zone and zone percentage
        calculateZone(pwrZoneAvg);
    }

    function updateFieldDimensions(dc) {
        fWidth = dc.getWidth();
        fHeight = dc.getHeight();

        // get maximum size of all text fields
        var sizePower = dc.getTextDimensions("00", powerFont);
        var sizeZone = dc.getTextDimensions("Z4", zoneFont);
        var sizeZone2 = dc.getTextDimensions("99%", zoneFont);
        var sizeUnit = dc.getTextDimensions("W", unitFont);

        // calculate spacing between edge of the field and text, assuming we leave no pixels between
        // both lines of text
        var hSpacing = ((fHeight - sizeZone[1] - sizePower[1] - 0) / 2.0).toNumber();
        hSpacing = (hSpacing < -1) ? -1 : hSpacing;

        // calculate text and zone bar positions
        yZone = hSpacing;
        yPower = fHeight - hSpacing - sizePower[1] + 3;
        yUnit = fHeight - hSpacing - sizeUnit[1] - 1;
        xPower = (fWidth/2 + sizePower[0]/2 + 0.5).toNumber();
        xHorizontalBar = sizeZone[0] + 2;
        wHorizontalBar = fWidth - sizeZone[0] - sizeZone2[0] - 4;
        hHorizontalBar = sizeZone[1];
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();

        // update all coordinates if size of the field changes. This should be called only on initial run and
        // when switching screens if the field is used on different screens at different size.
        if (width != fWidth or height != fHeight) {
            updateFieldDimensions(dc);
        }

        var backgroundColor = getBackgroundColor();
        var foregroundColor = (backgroundColor == Gfx.COLOR_BLACK) ? Gfx.COLOR_WHITE: Gfx.COLOR_BLACK;

        // Color the background color
        // dc.setColor(foregroundColor, backgroundColor);
        // dc.clear();
        dc.setColor(backgroundColor, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, width, height);

        var zValue = "";
        var showZoneBar = false;
        if (zone == null) {
            zValue = "__";
        }
        else if (zonePercent == null) {
            zValue = pwrAvgCount.format("%d") + "s Power";
        }
        else {
            showZoneBar = true;
            // limit percent display to 99 to save a some space and make horizontal bar more centered on field
            zonePercent = (zonePercent > 99) ? 99 : zonePercent;
        }
        // var debug_testPalette = true;
        // if (debug_testPalette) {
        //     debug_displayPalette();
        // }
        // var debug_testFonts = true;
        // if (debug_testFonts) {
        //   debug_printFonts();
        //   return;
        // }

        if (showZoneBar) {
            drawPowerZoneBar(dc, zone, zonePercent, xHorizontalBar, yZone+2, wHorizontalBar, hHorizontalBar);
        }
        // Draw the power and zone information
        dc.setColor(foregroundColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(xPower, yPower, powerFont, pwrAvg.format("%d"), Gfx.TEXT_JUSTIFY_RIGHT);
        dc.drawText(xPower+2, yUnit, Gfx.FONT_SMALL, "W", Gfx.TEXT_JUSTIFY_LEFT);
        if (showZoneBar) {
            dc.drawText(1, yZone, zoneFont, "Z" + zone.format("%d"), Gfx.TEXT_JUSTIFY_LEFT);
            dc.drawText(fWidth - 1, yZone, zoneFont, zonePercent.format("%2d") + "%", Gfx.TEXT_JUSTIFY_RIGHT);
        }
        else {
            dc.drawText(fWidth / 2, yZone, zoneFont, zValue, Gfx.TEXT_JUSTIFY_CENTER);
        }
    }

    // Draws a sliding horizontal bar
    function drawPowerZoneBar(dc, zone, value, x, y, w, h) {
        var backgroundColor = getBackgroundColor();
        var colorsActive = (backgroundColor == Gfx.COLOR_BLACK) ? colorsActiveBlack : colorsActiveWhite;
        var colorsInactive = (backgroundColor == Gfx.COLOR_BLACK) ? colorsDimmedBlack : colorsDimmedWhite;
        var outlineColor = (backgroundColor == Gfx.COLOR_BLACK) ? Gfx.COLOR_WHITE: Gfx.COLOR_BLACK;
        if (zone == 0) {
            return;
        }
        var yBarPos = y + h / 8;
        var yBarSize = h * 5 / 8;
        // try to fit two whole zones on screen (this will usually mean one full and two partial zones are displayed)
        var zoneWidth = (w.toFloat() / 2.0).toNumber() - 2;
        var radius = (zoneWidth / 4 < h) ? zoneWidth / 8 : w / 2;
        var xOffset = (value.toFloat() * (zoneWidth).toFloat() / 100.0 + 0.5).toNumber();
        var xBarPos = x + w / 2.0 - xOffset;

        // draw current zone
        dc.setColor(colorsActive[zone], colorsInactive[zone]);
        dc.fillRoundedRectangle(xBarPos, yBarPos, zoneWidth, yBarSize, radius);
        dc.setClip(x + w/2, y, zoneWidth - xOffset, h);  // using clip to fill the dimmed portion
        dc.setColor(colorsInactive[zone], Gfx.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(xBarPos, yBarPos, zoneWidth, yBarSize, radius);
        dc.clearClip();

        // outline current zone
        dc.setColor(outlineColor, Gfx.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(xBarPos, yBarPos, zoneWidth, yBarSize, radius);

        // draw adjacent zones (if any)
        dc.setClip(x, y, w, h);  // clip to bar borders so we don't overwrite something else
        if (zone > 1) {
            dc.setColor(colorsActive[zone-1], Gfx.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(xBarPos-zoneWidth-1, yBarPos, zoneWidth, yBarSize, radius);
        }
        if (zone < 7) {
            dc.setColor(colorsInactive[zone+1], Gfx.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(xBarPos + zoneWidth+1, yBarPos, zoneWidth, yBarSize, radius);
        }
        dc.clearClip();

        // draw pointer and vertical line at the middle of the bar
        var xPointer = (x + w / 2).toNumber();
        var yPointer = (y + h * 6 / 8) + 1;
        var hPointer = (h / 6.0 + 0.5).toNumber();
        var wHalf = hPointer;
        var coordPoly = [[xPointer, yPointer], [xPointer - wHalf, yPointer + hPointer],
                         [xPointer + wHalf, yPointer + hPointer], [xPointer, yPointer]];
        dc.setColor(outlineColor, Gfx.COLOR_TRANSPARENT);
        dc.fillPolygon(coordPoly);
        dc.drawLine(xPointer, y, xPointer, yPointer + hPointer);
    }

    //
    function calculateZone(power) {
        if (power == null or $.ftpValue == null) {
            // no power data, return dummy value
            zone = 0; zonePercent = null;
            return;
        }
        var ratio = power.toFloat() / $.ftpValue.toFloat();
        if (ratio > 1.5) {
            // max effort zone is open-ended by definition, but we limit it to 1500W
            zone = 7;
            var ratioMax = (1500.0 - 1.5 * $.ftpValue.toFloat()) / $.ftpValue.toFloat();
            zonePercent = 100.0 * (ratio - 1.5) / ratioMax;
        }
        else if (ratio > 1.2) {
            zone = 6;
            zonePercent = 100.0 * (ratio - 1.2) / (1.5 - 1.2);
        }
        else if (ratio > 1.05) {
            zone = 5;
            zonePercent = 100.0 * (ratio - 1.05) / (1.2 - 1.05);
        }
        else if (ratio > 0.9) {
            zone = 4;
            zonePercent = 100.0 * (ratio - 0.9) / (1.05 - 0.9);
        }
        else if (ratio > 0.75) {
            zone = 3;
            zonePercent = 100.0 * (ratio - 0.75) / (0.9 - 0.75);
        }
        else if (ratio > 0.55) {
            zone = 2;
            zonePercent = 100.0 * (ratio - 0.55) / (0.75 - 0.55);
        }
        else {
            zone = 1;
            zonePercent = 100.0 * ratio / 0.55;
        }
        zonePercent = zonePercent.toNumber();
    }

    // -----------------------------------------------------------------------------------------------------------
    // DEBUG function - testing palette colors for zone display
    function debug_displayPalette() {
        var ddw = 10;
        debug_testColors(dc, 1, 0, 30, ddw, fHeight-30);
        debug_testColors(dc, 2, ddw, 30, ddw, fHeight-30);
        debug_testColors(dc, 3, ddw*2, 30, ddw, fHeight-30);
        debug_testColors(dc, 4, ddw*3, 30, ddw, fHeight-30);
        debug_testColors(dc, 5, fWidth-ddw*3, 30, ddw, fHeight-30);
        debug_testColors(dc, 6, fWidth-ddw*2, 30, ddw, fHeight-30);
        debug_testColors(dc, 7, fWidth-ddw, 30, ddw, fHeight-30);
    }

    function debug_testColors(dc, zone, x, y, w, h) {
        var backgroundColor = getBackgroundColor();
        var colorsActive = (backgroundColor == Gfx.COLOR_BLACK) ? colorsActiveBlack : colorsActiveWhite;
        var colorsInactive = (backgroundColor == Gfx.COLOR_BLACK) ? colorsDimmedBlack : colorsDimmedWhite;
        dc.setColor(colorsInactive[zone], Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(x, y, w, h/2);
        dc.setColor(colorsActive[zone], Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(x, y+h/2, w, h/2);
    }
    // DEBUG function - test fonts
    function debug_printFonts() {
        var ddw = 10;
        debug_drawFont(dc, 0, yPower, "0", Gfx.FONT_SYSTEM_NUMBER_MILD);
        debug_drawFont(dc, 25, yPower, "0", Gfx.FONT_NUMBER_MILD);
        debug_drawFont(dc, 50, yPower, "0", Gfx.FONT_NUMBER_MEDIUM);
        debug_drawFont(dc, 75, yPower, "0", Gfx.FONT_NUMBER_MILD);
        debug_drawFont(dc, 100, yPower, "0", Gfx.FONT_SYSTEM_LARGE);
        debug_drawFont(dc, 125, yPower, "0", Gfx.FONT_GLANCE_NUMBER);
        debug_drawFont(dc, 150, yPower, "0", Gfx.FONT_SYSTEM_NUMBER_MEDIUM);
        debug_drawFont(dc, 0, yZone, "Z1 100%", Gfx.FONT_XTINY);
        debug_drawFont(dc, 50, yZone, "Z1 100%", Gfx.FONT_TINY);
        debug_drawFont(dc, 100, yZone, "Z1 100%", Gfx.FONT_GLANCE);
    }

    function debug_drawFont(dc, x, y, text, font) {
        var outlineColor = (getBackgroundColor() == Gfx.COLOR_BLACK) ? Gfx.COLOR_WHITE: Gfx.COLOR_BLACK;
        dc.setColor(outlineColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, text, Gfx.TEXT_JUSTIFY_LEFT);
    }

}
