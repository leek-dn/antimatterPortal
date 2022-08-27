#!/bin/zsh
inputFile=${1:-cookieClickerWebToAndroid.html}
outputFile=${2:-${inputFile%*.html}_build.html}

vervangAMetScriptB() {
	A="$1"
	B="$2"
	sed -i "s/$A/$(sed -e '1h;2,$H;$!d;g' -e 's/\\/\\\\/g' -e 's/\n/\\n/g' < "$B" | sed -e 's/\//\\\//g' -e 's/&/\\\&/g' )/" "$outputFile"
}

vervangAMetb64B() {
	A="$1"
	B="$2"
	sed -i "s/$A/$(base64 -w0 < "$B"|sed 's/\//\\\//g' )/" "$outputFile"
}
sed 's/UPGRADES AVAILABLE/'$(tr \\n , < static_assets/upgrades.available|sed 's/,$//')/ "$inputFile" > "$outputFile"
# TODO: standaard tar inladen van website
# vervang textual files die nodig zijn om het programma te laten werken
vervangAMetb64B "RELATIVE CLEAN SAVE" static_assets/relative_cleansave.json
sed -i "s/BUILDINGS CSV/$(tr '\n' '@' < static_assets/buildings.csv | sed -e 's/"/\\\\"/g' -e 's/@/\\\\n/' )/" "$outputFile"
vervangAMetb64B "TABLES JSON" static_assets/tables.json
vervangAMetb64B "FILELIST" static_assets/filelist
vervangAMetb64B "CONVERSION CSV" static_assets/conversion.csv
# first split d3 in multiple files because d3 is substituted as a argument to sed
# therefore the file lands on the stack. However the size of that is limited
# else one gets an aguments too large errorh
[ ! -f static_assets/d3_1.js ] && {
 fold -w $((278580/15)) static_assets/d3.js|sed -n '1,2p' > static_assets/d3_1.js
 for x in {3..16};do
  fold -w $((278580/15)) static_assets/d3.js|sed -n ${x}p > static_assets/d3_$((x-1)).js
 done
}
sed -i "s/D3 JS/$(seq 1 15|sed 's/.*/D3 & JS/'|tr -d '\n')/" "$outputFile"
# JavaScript files
vervangAMetScriptB "PAKO JS" static_assets/pako.js
vervangAMetScriptB "FILESAVER JS" static_assets/FileSaver.js
vervangAMetScriptB "BYTESTREAM JS" static_assets/bytestream.js
vervangAMetScriptB "UNTAR JS" static_assets/untar.js
vervangAMetScriptB "TARTS JS" static_assets/tarts.js
for x in {1..15};do
 vervangAMetScriptB "D3 $x JS" static_assets/d3_$x.js
done

pygmentize -l html "$outputFile"
firefox "$outputFile"
