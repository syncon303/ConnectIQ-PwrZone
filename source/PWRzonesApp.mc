using Toybox.Application;

var ftpValue = null;  // user FTP value; this value should be set beforehand from Garmin app
var pwrAvgCount = null;  // power value averaging (as seconds)
var zoneAvgCount = null;  // zone value averaging (as seconds)
const PWR_BUFFER_SIZE = 30;  // size of the cyclic buffer for calculation of rolling power average (up to 30s)
const ZONE_BUFFER_SIZE = 100; // size of the cyclic buffer for calculation of rolling power zone average (up to 100s)

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
        if ($.pwrAvgCount == null or $.pwrAvgCount < 1) {
            $.pwrAvgCount = 3;
        }
        $.pwrAvgCount = ($.pwrAvgCount > PWR_BUFFER_SIZE) ? PWR_BUFFER_SIZE: $.pwrAvgCount;
        $.zoneAvgCount = Application.Storage.getValue(ZONEAVG_PROP);
        if ($.zoneAvgCount == null or $.zoneAvgCount < 1) {
            $.zoneAvgCount = 6;
        }
        $.zoneAvgCount = ($.zoneAvgCount > PWR_BUFFER_SIZE) ? ZONE_BUFFER_SIZE: $.zoneAvgCount;
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    //! Return the initial view of your application here
    function getInitialView() {
        return [ new PWRzonesView() ];
    }

}