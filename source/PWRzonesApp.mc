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

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
        fetchSettings();
    }

    function onSettingsChanged() {
        fetchSettings();
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    //! Return the initial view of your application here
    function getInitialView() {
        return [ new PWRzonesView() ];
    }

    function fetchSettings() {
        // read FTP data from storage (app properties)
        $.ftpValue = Application.Properties.getValue(FTP_PROP);
        // System.println("FTP loaded = " + $.ftpValue);
        if ($.ftpValue == null) {
            $.ftpValue = 250;
        }
        $.pwrAvgCount = Application.Properties.getValue(PWRAVG_PROP);
        // System.println("PwrAvg loaded = " + $.pwrAvgCount);
        if ($.pwrAvgCount == null or $.pwrAvgCount < 1) {
            $.pwrAvgCount = 3;
        }
        else if ($.pwrAvgCount > PWR_BUFFER_SIZE) {
            $.pwrAvgCount = PWR_BUFFER_SIZE;
        }

        $.zoneAvgCount = Application.Properties.getValue(ZONEAVG_PROP);
        // System.println("ZoneAvg loaded = " + $.zoneAvgCount);
        if ($.zoneAvgCount == null or $.zoneAvgCount < 1) {
            $.zoneAvgCount = 6;
        }
        else if ($.zoneAvgCount > ZONE_BUFFER_SIZE) {
            $.zoneAvgCount = ZONE_BUFFER_SIZE;
        }
    }
}