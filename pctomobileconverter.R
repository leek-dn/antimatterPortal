# dit is een script om de Cookie Clicker save van web/desktop om te zetten naar de mobiele variant
# gescheven door Stop5G!Nu
# this script expects 'backupfolder' being an extracted backup folder of the adb file
# and ../backup being a CookieClicker web save
library(base64enc)
library(jsonlite)
library(XML)
library(rvest)
library(httr)
suppressMessages(library(Hmisc, quietly = TRUE))
suppressMessages(library(clipr, quietly = TRUE))
setwd(".")
cleanNames <- function(names) {
  trimws(gsub(" |-", ".", tolower(names)))
}
cleanNames.js <- function(names) {
  trimws(gsub(" |-", "$", tolower(names)))
}
saveTextToVector <- function(savetext) {
	strsplit(rawToChar(base64decode(sub("!END!$", "", URLdecode(savetext)))), "|", fixed = TRUE)[[1]]
}

if (FALSE)
 orig_full_save <- saveTextToVector(read_clip())
if (FALSE)
 orig_full_save <- saveTextToVector(readLines("../backup", warn = FALSE))
# now the different save lines are stored to orig_full_save
ccsave <- read_json("static_assets/relative_cleansave.json")
version <- orig_full_save[1]
names(orig_full_save) <- c("game.version", "empty", "run.details", "preferences", "miscellaneous.game.data", "building.data",
						   "upgrades", "achievements", "game.buffs", if (length(orig_full_save)==10) "mod.data")
if (!is.na(orig_full_save["mod.data"]))
 plugins_decoded <- parse_json(paste0("{", gsub("\\};", "}", gsub('(\\w+[^"]):\\{', '"\\1":\\{', gsub('(;\\w+[^"]):\\{', ',"\\1":\\{', orig_full_save["mod.data"]))), "}"))
# laad een tabel met de save informatie in van wikia
save_page <- gsub("<svg.+?</svg>", "", GET("https://cookieclicker.fandom.com/wiki/Save"), perl = TRUE)
save_page <- htmlParse(save_page)
invisible(removeNodes(getNodeSet(save_page, "//a")))
meta_save_tables <- setNames(readHTMLTable(save_page, TRUE), c("global.save", "buildings", "game.buffs"))
meta_save_tables_js <- Map(function(x) {
	x <- setNames(x, cleanNames.js(colnames(x)))
	x$`parameter$name` <- cleanNames.js(x$`parameter$name`)
	x
}, meta_save_tables)
meta_save_tables <- Map(function(x) {
	x <- setNames(x, cleanNames(colnames(x)))
	x$parameter.name <- cleanNames(x$parameter.name)
	x
}, meta_save_tables)
write.csv(meta_save_tables_js$buildings, "static_assets/buildings.csv", row.names = FALSE)
rm(save_page)
# splits de tabel in meerdere
save_tables <- meta_save_tables$global.save
save_tables_js <- meta_save_tables_js$global.save
start_table <- sapply(names(orig_full_save), function(x) grep(paste0("^", x, "$"), save_tables$parameter.name, ignore.case = T)[1])
suppressWarnings(start_table$mod.data <- NA)
start_table <- as.data.frame(t(t(start_table)))
colnames(start_table) <- "start"
start_table$end <- -1
start_table <- start_table[!is.na(start_table$start),]
start_table$end <- unlist(c(start_table$start[-1], nrow(save_tables)))-1
start_table$start <- unlist(start_table$start)+1
save_tables <- apply(start_table, 1, function(x) save_tables[x['start']:x['end'],])
save_tables_js <- apply(start_table, 1, function(x) save_tables_js[x['start']:x['end'],])
sliceBuilding <- save_tables$building.data[2,]
save_tables$building.data <- rbind(save_tables$building.data, c("javascript.consoles", NA, NA))
save_tables$building.data <- rbind(save_tables$building.data, c("idleverses", NA, NA))
save_tables$building.data <- save_tables$building.data$parameter.name
save_tables_js$building.data <- gsub("\\.", "$", save_tables$building.data)
write_json(setNames(Map(function(a) {
	mytext <- ""
	tc <- textConnection("mytext", "wa", TRUE)
	write.csv(a, tc, row.names = FALSE)
	close(tc)
	paste0(mytext[-1], collapse = "\n")
}, save_tables_js), gsub(".", "$", names(save_tables_js), fixed = TRUE)), "static_assets/tables.json", auto_unbox = TRUE)
writeLines(gsub("\\.", "$", save_tables_js$building.data), "oldfiles/buildings.list")
# lees de conversion tabel in
conversions <- read.csv("static_assets/conversion.csv", sep = "|")
easy_conv <- function(name, split = ";") {
	# wat als de save file niet overeenkomt met het formaat op wikia
	if (length(save_tables[[name]]$value.example)!=length(unlist(strsplit(orig_full_save[name], split)))) {
		message(name, " bevat een ander aantal records dan de save file...")
	}
	if (is.data.frame(save_tables[[name]])) {
		save_tables[[name]]$value.example <<- unlist(strsplit(orig_full_save[name], split))[1:length(save_tables[[name]]$value.example)]
		save_tables[[name]] <<- as.list(setNames(save_tables[[name]]$value.example, save_tables[[name]]$parameter.name))
	}
	conversions.selection <- conversions[grep(name, conversions$web),]
	message("Converted about ", length(Filter(Negate(is.null), apply(conversions.selection, 1, function(x) {
		if (x["mobile"]!="") {
			the_code <- paste0("ccsave$", x["mobile"], " <<- save_tables$", x["web"])
			if (x["type"]=="num") {
				the_code <- sub("(<<- )(.*)$", "\\1 as.numeric(\\2)", the_code)
				the_code <- paste0(the_code, "\nsave_tables$", x["web"], " <<- as.numeric(save_tables$", x["web"], ")")
			}
			# toont enkel de tekst
			#cat(the_code, "\n")
			# zet het daadwerkelijk om
			eval(parse(text = the_code), parent.frame())
		} else {
			if (x["type"]=="num") {
				the_code <- paste0("save_tables$", x["web"], " <<- as.numeric(save_tables$", x["web"], ")")
				eval(parse(text = the_code), parent.frame())
				cat(the_code, "\n")
				NULL
			}
		}
		}))), " items")
	return (invisible(nrow(conversions.selection)))
}
easy_conv("run.details")
easy_conv("miscellaneous.game.data")
easy_conv("preferences", "")
normalWrinklers <- save_tables$miscellaneous.game.data$number.of.wrinklers-save_tables$miscellaneous.game.data$number.of.shiny.wrinklers
if (save_tables$miscellaneous.game.data$number.of.shiny.wrinklers>0) {
	for (x in 1:save_tables$miscellaneous.game.data$number.of.shiny.wrinklers) {
		ccsave$wrinklers[[x]]$t <- 1
		ccsave$wrinklers[[x]]$s <- save_tables$miscellaneous.game.data$cookies.in.shiny.wrinklers/save_tables$miscellaneous.game.data$number.of.shiny.wrinklers
	}
}
for (x in (save_tables$miscellaneous.game.data$number.of.shiny.wrinklers+1):save_tables$miscellaneous.game.data$number.of.wrinklers) {
	ccsave$wrinklers[[x]]$t <- 0
	ccsave$wrinklers[[x]]$s <- save_tables$miscellaneous.game.data$cookies.sucked.by.wrinklers/normalWrinklers
}
upgradeIdsAvailable <- as.integer(readLines("upgrades.available"))
ccsave$permanentUpgrades <- as.numeric(unlist(ccsave$permanentUpgrades))
pum <- FALSE
for (x in 1:length(ccsave$permanentUpgrades)) {
	if (ccsave$permanentUpgrades[x]!=-1) {
		if (ccsave$permanentUpgrades[x] %in% upgradeIdsAvailable) {
			# prima upgrade
		} else {
			if (!pum) {
				message("Er is een upgrade die nog niet beschikbaar is in CC mobile, die je wel als permanente upgade")
				message("hebt gebruikt. Dit hebben we voorkomen. Als we dat niet hadden gedaan werkte je save wel, maar")
				message("kun je nooit meer ascenden door een error (tot orteil deze upgrade beschikbaar maakt natuurlijk)")
				pum <- TRUE
			}
			message("(", ccsave$permanentUpgrades[x], ")")
			ccsave$permanentUpgrades[x] <- -1
		}
	}
}
# researchTime
save_tables$building.data <- Map(function(x) meta_save_tables$buildings, c(save_tables$building.data, "javascript.consoles", "idleverses"))
# name <- "building.data"
# subgroup <- "cursors"
# convert  building data
naamAlsInMobileCC <- function(name) {
	sub("\\.", " ", upFirst(sub("s$", "", sub("ies$", "y", name))))
}
vervangSG <- function(sg, text) {
	sub("(^|\\$).\\$", sg, text)
}
invisible(Map(function(subgroup) {
	message(subgroup)
	if (is.data.frame(save_tables$building.data[[subgroup]])) {
		save_tables$building.data[[subgroup]]$value.example <<- unlist(strsplit(unlist(strsplit(orig_full_save['building.data'], ";"))[
			grep(subgroup, names(save_tables$building.data))], ","))[1:length(save_tables$building.data[[subgroup]]$value.example)]
		save_tables$building.data[[subgroup]] <<- as.list(setNames(save_tables$building.data[[subgroup]]$value.example, save_tables$building.data[[subgroup]]$parameter.name))
	}

	conversions.selection <- conversions[grep("building.data", conversions$web),]
	# ook hier moet de functie vernieuwd worden
	message("Converted about ", length(Filter(
		Negate(is.null), apply(conversions.selection, 1, function(x) {
			code_for_to_int <- paste0("save_tables$", vervangSG(paste0("$", subgroup, "$"), x["web"]), " <<- as.numeric(save_tables$", vervangSG(paste0("$", subgroup, "$"), x["web"]), ")")
			if (x["mobile"]!="") {
				the_code <- paste0("ccsave$", vervangSG(paste0("\\1`", naamAlsInMobileCC(subgroup), "`$"), x["mobile"]),
								   " <<- save_tables$", vervangSG(paste0("\\1", subgroup, "$"), x["web"]))
				if (x["type"]=="num") {
					the_code <- sub("(<<- )(.*)$", "\\1 as.numeric(\\2)", the_code)
					the_code <- paste0(the_code, "\n", code_for_to_int)
				}
				cat(the_code, "\n")
				eval(parse(text = the_code), parent.frame())
				1
			} else {
				if (x["type"]=="num") {
					the_code <- code_for_to_int
					eval(parse(text = the_code), parent.frame())
					cat(the_code, "\n")
					NULL
				}
		}
		}))), " items")

	NULL
}, cleanNames(sub("ys$", "ies", paste0(names(ccsave$buildings), "s")))))
save_tables$upgrades <- setNames(as.data.frame(matrix(as.numeric(charToRaw(orig_full_save[['upgrades']]))-as.numeric(charToRaw("0")), ncol = 2, byrow = TRUE)), c("unlocked", "bought"))
save_tables$upgrades$mobile.format <- setNames(with(save_tables$upgrades, (unlocked*2)+bought), as.character(1:nrow(save_tables$upgrades)))
for (x in names(ccsave$upgrades)) {
	ccsave$upgrades[[x]] <- save_tables$upgrades$mobile.format[as.numeric(x)+1]
}
ccsave$researchTM <- 1000 * 60 * 30 / if (save_tables$upgrades$bought[141+1]==1) 10 else 1
if (ccsave$researchUpgrade==0) ccsave$researchUpgrade = -1
save_tables$achievements <- as.numeric(charToRaw(orig_full_save[['achievements']]))-as.numeric(charToRaw("0"))
save_tables$achievements <- setNames(save_tables$achievements, 1:length(save_tables$achievements)-1)
for (x in names(ccsave$achievs)) {
	ccsave$achievs[[x]] <- unname(save_tables$achievements[sub("undefined", "0", x)])
}
writeLines(toJSON(ccsave, digits = 12, auto_unbox = T), "backupfolder/apps/org.dashnet.cookieclickertrix/f/CookieClickerSave.txt")
system("kdesu -c 'java -jar ../android-backup-extractor/target/abe.jar c bu.tar backupfolder/'")
system("java -jar ../android-backup-extractor/target/abe.jar pack bu.tar bu.adb")
werkte <- system("adb restore bu.adb")
if (werkte==255) {
	lipPoort <- readline("ip:poort: ")
	werkte <- system(paste0("adb connect ", lipPoort))
	if (werkte==0) {
		system("adb restore bu.adb")
	} else {
		stop("cannot connect with device")
	}
}
