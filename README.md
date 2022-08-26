# antimatterPortal
CookieClicker web save converter to mobile/android platform and info around the process

_________

This repository consist of a HTML page and the result is a self-contained HTML-page that is able to convert the save. Even though it does not convert the other way around, checking this repo will help you in achieving this goal. The same for combining two saves. If you actually implement this on the page I will obviously accept your pull-request.

## How the saves work

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

The android save is completely different encoded. This is simply a JSON file. The JSON file is stored in a file called `/data/data/{APPID}/files/CookieClickerSave.txt` where **{APPID}** is for the official cookieClicker apk `org.dashnet.cookieclicker`. However without root access this file cannot be opened by any app on your phone but (that version of)CookieClicker. Even though root access to your phone seemed quite logical to me, other people (and android phone vendors) think otherwise. There is however another way to access that file. This is the backup system. By means of the ADB program (android debug bridge) (refer to https://www.xda-developers.com/install-adb-windows-macos-linux/ if you want to download the program). One can make a backup of an app or its data. This option is actually depricated, but still functional. So by entering `adb backup org.dashnet.cookieclicker -f backup.adb` a backup of the official cookieclicker app is made to the file `backup.adb`. `adb restore backup.adb` will restore that backup to the device. Now the backup format is actually a header of 24 characters, then zlib compression of the rest of the data. Having decompressed the rest results in a `.tar` file, a Tape ARchive. This is just a file format to describe multiple files within one file. So basically anyone knows .zip and .zip is compressing (using less data to still describe the same data) and combining files. The .adb file is conceptually the same, but now it has a header and uses different techiniques (tar for combining and zlib for compressing). Now there is one more thing to know to grasp this format and that is that the order of the files in the tar/adb file matters! If the order is not correct, files will not be restored and nothing (seems to) happens. So it is very important to remain the order.

### Android header
```
ANDROID BACKUP
5
1
none
```

It ends with a newline and the newlines are linefeed.
Older backup might work different and have a different header, but this seems to work.

### Alpha save

The alpha save is called `/data/data/{APPID}/files/CookieClickerSaveTest.txt` by the way. In some folder (/apps/{APPID}/r/app_webview/Default/Local Storage/leveldb in the backup, there is stored in the localstorage of the browser that runs the webapp in the app. It is saved in the leveldb format from Google. This format is hard to parse oneself but there are tools to do this. My approach for giving users the option to load alpha mode was to provide the files in that directory that resembles alpha from an alpha backup. This will probably not work with a own backup provided, but this in fact is a non-issue for then one should be able to switch to whichever mode it wants to, and then backup.

## how it is sort of done

### building the HTML file

The HTML file is build using a bash/zsh script. This script uses `sed`, `tr` and `fold`. At the end of the file I end with pygmentize and firefox, but these lines only have the purpose of viewing the end result, so if these fail or are not available, then that is still fine. The build file (build.sh) is far from a most optimized way of doing things, but it works. The general priciple is to search for some give pattern in uppercase (like PAKO JS) and replace that with the actual contents of the script (pako.js). This replacement is done by means of `sed`. The downside of this approach is that the file will be part of the arguments (to `sed`) and therefore must it fit in the stack. This is not the case for d3. d3 is therefore split(using fold) in 15 parts. The `D3 JS` marker is split in 15 parts as well (`D3 1 JS` to `D3 15 JS`) and normal replacement is applied. How the different JavaScript libraries fit in all of this is described lower or in source code, but here is a table of the other files:

| marker name         | description                                                                              | based upon     | filename                              |
|---------------------|------------------------------------------------------------------------------------------|----------------|---------------------------------------|
| UPGRADES AVAILABLE  | the available upgrades id’s in mobile cc                                                 | CC android APK | static_assets/upgrades.available      |
| RELATIVE CLEAN SAVE | a (JSON android) save that (should) consist of the initial state when one starts to play | own backup     | static_assets/relative_cleansave.json |
| BUILDINGS CSV       | table with buildings info                                                                | Wikia          | static_assets/buildings.csv           |
| TABLES JSON         | JSON with the tables the web save consist of                                             | Wikia          | static_assets/tables.json             |
| FILELIST            | depricated in future: list of right order of files                                       | own backup     | static_assets/filelist                |
| CONVERSION CSV      | conversion table                                                                         | handmade       | static_assets/conversion.csv          |

`BUILDINGS CSV`, `CONVERSION CSV` and `TABLES JSON` are all halfly generated by R code. Because all of the scripts and required files (except for the user save of course) are in the HTML file, it will always work (if it works).

### Save specific
For many (most convertible) parts of the save are one on one translatable to settings in the JSON a table is made. This table describes the property name as used in the Wikia and the property name as used in the JSON. For buildings the properties are the same across different buildings. In the table, the pattern `$.$` or `.$.` is used to describe the building name. A specific function is used to translate all settings. Some settings, like season-related things currently do not have a corresponding key. The tables that the program uses are derived from Wikia and settings are mapped to their names. This is done somewhat differently across sections because they all require different forms of data stored. Also not all upgrades are available in mobile Cookie Clicker. This is generally not a problem, except for permanent upgrades. If a permanent upgrade is set to a not exsistent upgrade in mobile, it is no longer possible to ascend, or check your heavenly upgrades (for obvious reasons). Out of the JavaScript files from the mobile app a list of 'available upgrades' is made, that will bypass this problem.

### backup file

For the backup file does not really contain much user relevant information it is generally not userfriendly and meaningfull to let the user submit (symbolically, for nothing will at all be processed at a server) so a specific crafted backup file is included in the HTML where the save will be loaded into. The save itself will, as JSON be also part of the HTML file. Settings will be stored on this file. There has been made sure that all settings results in default values in this JSON file.

### libraries

At first my aproach to handle ADB files was to use a Java program. CheerpJ would assist me to run that in the browser. I used https://github.com/rustyx/android-backup-extractor/. This is a fork from the official program that even allowed to do the tar part of the work. I really wanted to do it that way for I did not have to care about the format. Now some problems rose by using that approach:

* I needed to compile the program. When I did, it just works fine.
* Using CheerpJ did now allow me to detect when the program is loaded. I can only call functions in the Java program when it is loaded and I did not want to change CheerpJ (or the Java program) to adjust that for me. Actually calling functions does have callbacks so *then* I can detect when it is done.
  * This was bypassed by changing the 'console output' to some div, and putting a listener on that div to fire every time there is written on. If I launch the program without arguments it will write a little message to the console and the follow-up code will be executed when in the div is written the last line of that text. It seemed to me that the program should be loaded then.
* CheerpJ did take a lot of time to load. I implemented a countdown timer, but it took about a minute to load. Also it loaded al sorts of files (mainly JavaScript) from their servers, which is fine, but I like to be able to present them with the HTML (or inside) and that wasn't really documented.
* They have a filesystem as a localstorage which is hard to work with if you know only half of the details. Giving them(the program) files is actually okay, but recieving files means making your own filesystem functions.
* Eventually, when almost everything worked, the CheerpJ thing stopped wanted to compress tar. There was no (or strange) error and the debugger showed a stack trace, but not in human language. It also did crash my browser a couple of times.

So then I decided to use another approach to the backup file. In the end I implemented a lot of things around the CheerpJ things just to work around a little more care-taking of the actual file stucture, which eventually didn't made sense anymore. So I used pako (https://nodeca.github.io/pako/) for zlib compression and decompression and I used tarts(https://github.com/tart/tartJS) for creating tape archives. I used untar.js (https://github.com/antimatter15/untar.js/) for 'untarring'(I changed a few things so it works in the browser instead of nodejs) and I put the android header in a JavaScript string. Now I have 3 dependencies instead of 2, but it actually works, so thats something at least.

| marker name   | description                                   | filename                    |
|---------------|-----------------------------------------------|-----------------------------|
| PAKO JS       | zlib compression/decompression                | static_assets/pako.js       |
| FILESAVER JS  | wrapper around save a file API of the browser | static_assets/FileSaver.js  |
| BYTESTREAM JS | required for untar                            | static_assets/bytestream.js |
| UNTAR JS      | extracting tars                               | static_assets/untar.js      |
| TARTS JS      | creating tars                                 | static_assets/tarts.js      |
| D3 JS         | parsing CSV’s                                 | static_assets/d3.js         |


### buildings
How the building csv looks like
```
"parameter$name","value$example","description"
"amount$owned","600","Amount of this building currently owned"
"amount$bought","950","Amount of this building bought this ascension, including those that have been sold (ex. if you bought 10, sold 10, and bought 10 again, this value would be 20)"
"cookies$produced","4.593698631478832e+40","Cookies produced from this building this ascension"
"level","1","Level of this building"
"minigame$data","to do",NA
"muted","0","Is this building muted? (0: no, 1: yes)"
```

The buildings.csv file is generated from the Wikia and is a table that resembles the items in a building save item. Because this is a csv, it is parsed using d3, a library that focuses mostly on generating figures.

## updates of Cookie Clicker

If Orteil updates one of both versions, this program needs an update as well.
If Orteil updates web version, probably hardly anything will be needed to update, for new settings will always follow old settings and most settings are in web cc and less are in android. (Unless this was about assigning wrinklers a specific amount of cookies eaten...) `tables.json` and `buildings.csv` might be updated to reflect the changes. The latter should hardly, if ever be updated, because there are hardly reasons to give buildings more properties. The best is to change the Wikia `Save` page and load the changes back using the R script. However I do not have a Wikia account.
If Orteil updates android version, some things might be convertable that weren't before. Then one need to change `conversion.csv`. If the setting or save item is not 1 on 1 convertable one needs to edit `verwerkSave` function in the HTML file as well. Also the new setting(s) can result in a new clean save being made. So `relative_cleansave.json` might/must also be updated. If new updates are possible in the mobile save, `updates.available` should also be updated. This last file can be updated fully by means of a script.

Don't expect me to change all these files stoically. If you want to convert your save, which you probably want for you are reading this, changing these files a little is but a simple action in respect to setting this all up. (as long as you have read the relevant pieces of information on this page, you probably get the idea). So feel free to make a pull request with new changes.
