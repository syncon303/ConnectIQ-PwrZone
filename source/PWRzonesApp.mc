using Toybox.Application;

var ftpValue = null;  // user FTP value; this value should be set beforehand from Garmin app
var pwrAvgCount = null;  // power value averaging (as seconds)
var zoneAvgCount = null;  // zone value averaging (as seconds)
var drawVerticalBar = false;  // zone value averaging (as seconds)
const PWR_BUFFER_SIZE = 100;
const ZONE_BUFFER_SIZE = 100;

class PWRzonesApp extends Application.AppBase {

    static const FTP_PROP = "ftp_prop";
    static const PWRAVG_PROP = "average_prop";
    static const ZONEAVG_PROP = "zone_average_prop";
    static const DRAW_VERT_PROP = "draw_vert_bar_prop";

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
        // read FTP data from storage (app options)
        $.ftpValue = Application.Storage.getValue(FTP_PROP);
        if ($.ftpValue == null) {
            $.ftpValue = 220;
        }
        $.pwrAvgCount = Application.Storage.getValue(PWRAVG_PROP);
        if ($.pwrAvgCount == null or $.pwrAvgCount < 1 or $.pwrAvgCount >= PWR_BUFFER_SIZE) {
            $.pwrAvgCount = 3;
        }
        $.zoneAvgCount = Application.Storage.getValue(ZONEAVG_PROP);
        if ($.zoneAvgCount == null or $.zoneAvgCount < 1 or $.zoneAvgCount >= ZONE_BUFFER_SIZE) {
            $.zoneAvgCount = 6;
        }
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    //! Return the initial view of your application here
    function getInitialView() {
        return [ new PWRzonesView() ];
    }

}