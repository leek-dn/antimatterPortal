# antimatterPortal
CookieClicker web save converter to mobile/android platform and info around the process

_________

This repository consist of a HTML page and the result is a self-contained HTML-page that is able to convert the save. Even though it does not convert the other way around, checking this repo will help you in achieving this goal. The same for combining two saves. If you actually implement this on the page I will obviously accept your pull-request.

# How the saves work

The websave is generated using the function Game.WriteSave (in http://orteil.dashnet.org/cookieclicker/main.js?v=4). This function will (in Game) give you an URL-encoded save that ends with `!END!`. Decoding the save converts the last characters back to `!END!` again. The rest of the save is a base64 string. After decoing that base64 string, multiple save categories are shown:
* [X] Game Version
* [X] Empty
* [X] Run Details
* [X] Preferences
* [X] Miscellaneous Game Data
* [X] Building Data
* [X] Upgrades
* [X] Achievements
* [ ] Game Buffs
* [ ] Mod Data

(checked who are fully converted)
(also take into account that android cookieclicker does not have all features the web version has)
These are splitted with a `|`-sign. Within these categories things are splitted with `;`-sign and for the fields that need split that deep, the `,`-sign is used. This is basically how the web save works. For more details on what the sections entail I refer to the Cookie Clicker Wikia: https://cookieclicker.fandom.com/wiki/Save#Save_format

Please note that this wikia is incomplete for the current version, but the information is still usefull. The main.js file can complete our understanding of the save.

The android save is completely different encoded. This is simply a JSON file. The JSON file is stored in a file called `/data/data/{APPID}/files/CookieClickerSave.txt` where **{APPID}** is for the official cookieClicker apk `org.dashnet.cookieclicker`. However without root access this file cannot be opened by any app on your phone but (that version of)CookieClicker. Even though root access to your phone seemed quite logical to me, other people (and android phone vendors) think otherwise. There is however another way to access that file. This is the backup system. By means of the ADB program (android debug bridge). One can make a backup of an app or its data. This option is actually depricated, but still functionall. So by entering `adb backup org.dashnet.cookieclicker -f backup.adb` a backup of the official cookieclicker app is made to the file `backup.adb`.

For many (most convertible) parts of the save are one on one translat
