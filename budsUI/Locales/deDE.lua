local K, C, L, _ = select(2, ...):unpack()
local Locale = GetLocale()

if (Locale ~= "deDE") then
	return
end

-- AddonList Localization
L_ADDON_DISABLE_ALL = "Alle deaktivieren"
L_ADDON_ENABLE_ALL = "Alle aktivieren"
L_ADDON_LIST = "|cff388bdbAddon-Liste|r"
L_ADDON_RELOAD = "Neu laden"
-- Announce Localization
L_ANNOUNCE_INTERRUPTED = INTERRUPTED
L_ANNOUNCE_PC_ABORTED = "Pull ABGEBROCHEN!"
L_ANNOUNCE_PC_GO = "LOS!"
L_ANNOUNCE_PC_MSG = "Pulling %s in %s.."
L_ANNOUNCE_FP_CAST = "%s wirkt %s."
L_ANNOUNCE_FP_CLICK = "%s wirkt %s. Klicken!"
L_ANNOUNCE_FP_PRE = "%s hat %s vorbereitet."
L_ANNOUNCE_FP_PUT = "%s hat %s platziert."
L_ANNOUNCE_FP_STAT = "%s hat %s vorbereitet - [%s]."
L_ANNOUNCE_FP_USE = "%s benutzt %s."
L_ANNOUNCE_SAPPED = "Kopfnuss!"
L_ANNOUNCE_SAPPED_BY = "Kopfnuss von: "
-- Automation Localization
L_SELL_TRASH = "%d graue Gegenstände für %s verkauft"
L_REPAIR_BANK = "Gildenbank-Reparatur für %s."
L_REPAIRED_FOR = "Repariert für %s."
L_CANT_AFFORD_REPAIR = "Reparatur nicht bezahlbar."
-- Bags Localization
L_BAG_BAGS_BIDS = "Benutzte Taschen: "
L_BAG_BUY_BANKS_SLOT = "Bankfach kaufen (Bank muss geöffnet sein)"
L_BAG_BUY_SLOTS = "Neues Fach kaufen mit /bags purchase yes"
L_BAG_COSTS = "Kosten: %.2f Gold"
L_BAG_NOTHING_SORT = "Nichts zu sortieren."
L_BAG_NO_SLOTS = "Keine weiteren Fächer verfügbar!"
L_BAG_OPEN_BANK = "Du musst zuerst die Bank öffnen."
L_BAG_SHOW_BAGS = "Taschen anzeigen"
L_BAG_SORT = "Sortiert deine Taschen oder Bank, falls geöffnet."
L_BAG_SORTING_BAGS = "Sortierung abgeschlossen."
L_BAG_SORT_MENU = "Sortieren"
L_BAG_SORT_SPECIAL = "Spezial sortieren"
L_BAG_STACK = "Stapelt Gegenstände in Taschen oder Bank, falls geöffnet."
L_BAG_STACK_END = "Stapeln abgeschlossen."
L_BAG_STACK_MENU = "Stapeln"
L_BAG_STACK_SPECIAL = "Spezial stapeln"
L_BAG_RIGHT_CLICK_SEARCH = "Rechtsklick zum Suchen."
L_BAG_RIGHT_CLICK_CLOSE = "Rechtsklick öffnet Menü"
L_BAG_SHOW_KEYRING = "Schlüsselbund anzeigen"
-- Bindings Localization
L_BIND_BINDING = "Belegung"
L_BIND_CLEARED = "Alle Tastenbelegungen gelöscht für"
L_BIND_DISCARD = "Alle neuen Tastenbelegungen wurden verworfen."
L_BIND_INSTRUCT = "Fahre mit der Maus über eine Aktionsleiste, um sie zu belegen. Drücke ESC oder Rechtsklick, um die Belegung zu löschen."
L_BIND_KEY = "Taste"
L_BIND_NO_SET = "Keine Belegungen gesetzt"
L_BIND_SAVED = "Alle Tastenbelegungen wurden gespeichert."
-- Chat Localization
L_CHAT_AFK = "[AFK]"
L_CHAT_BATTLEGROUND	= "SG"
L_CHAT_BATTLEGROUND_LEADER = "SG-Leiter"
L_CHAT_DND = "[BNS]"
L_CHAT_GUILD = "G"
L_CHAT_OFFICER = "O"
L_CHAT_PARTY = "Gr"
L_CHAT_PARTY_LEADER = "Gr-Leiter"
L_CHAT_RAID = "S"
L_CHAT_RAID_LEADER = "S-Leiter"
L_CHAT_RAID_WARNING = "Schlachtzugswarnung"
L_CHAT_SAYS = "sagt"
L_CHAT_WHISPER = "flüstert"
L_CHAT_YELLS = "schreit"
-- BigChat Localization
L_CHAT_BIGCHAT_OFF = "|cffffe02eGroßer Chat-Modus|r: |cFFFF0000Aus|r."
L_CHAT_BIGCHAT_ON = "|cffffe02eGroßer Chat-Modus|r: |cFF008000An|r."
-- Class Localization
L_CLASS_HUNTER_CONTENT = "Dein Begleiter ist zufrieden!"
L_CLASS_HUNTER_HAPPY = "Dein Begleiter ist glücklich!"
L_CLASS_HUNTER_UNHAPPY = "Dein Begleiter ist unglücklich!"
-- Datatext Localization
L_DATATEXT_ALTERAC = "Alteractal"
L_DATATEXT_ANCIENTS = "Strand der Uralten"
L_DATATEXT_ARATHI = "Arathibecken"
L_DATATEXT_BASESASSAULTED = "Basen angegriffen:"
L_DATATEXT_BASESDEFENDED = "Basen verteidigt:"
L_DATATEXT_DEMOLISHERSDESTROYED = "Zerstörer zerstört:"
L_DATATEXT_EYE = "Auge des Sturms"
L_DATATEXT_FLAGSCAPTURED = "Flaggen erobert:"
L_DATATEXT_FLAGSRETURNED = "Flaggen zurückgebracht:"
L_DATATEXT_GATESDESTROYED = "Tore zerstört:"
L_DATATEXT_GRAVEYARDSASSAULTED = "Friedhöfe angegriffen:"
L_DATATEXT_GRAVEYARDSDEFENDED = "Friedhöfe verteidigt:"
L_DATATEXT_ISLE = "Insel der Eroberung"
L_DATATEXT_MEMORY_CLEANED = "|cffffe02eBereinigt:|r "
L_DATATEXT_TOWERSASSAULTED = "Türme angegriffen:"
L_DATATEXT_TOWERSDEFENDED = "Türme verteidigt:"
L_DATATEXT_WARSONG = "Kriegshymnenschlucht"
-- Exp/Rep Bar Localization
L_CURRENT_EXPERIENCE = "Aktuell:"
L_CURRENT_REPUTATION = "Aktuell:"
L_EXPERIENCE_BAR = "Erfahrung:"
L_REMAINING_EXPERIENCE = "Verbleibend:"
L_REMAINING_REPUTATION = "Verbleibend:"
L_REPUTATION_BAR = "Ruf:"
L_RESTED_EXPERIENCE = "Erholt:"
L_STANDING_REPUTATION = "Stufe:"
-- In Combat Localization
L_ERR_NOT_IN_COMBAT = "Das kannst du nicht im Kampf oder während du tot bist."
-- Autoinvite Localization
L_INVITE_ENABLE = "|cffffe02eAuto-Einladung|r: |cFF008000AN|r: "
L_INVITE_DISABLE = "|cffffe02eAuto-Einladung|r: |cFFFF0000AUS|r."
-- Info Localization
L_INFO_DISBAND = "Gruppe wird aufgelöst..."
L_INFO_DUEL = "Duellanfrage abgelehnt von "
L_INFO_ERRORS = "Noch keine Fehler."
L_INFO_DUEL_DECLINE = "Ich nehme momentan keine Duelle an."
L_INFO_INVITE = "Einladung angenommen von "
L_INFO_NOT_INSTALLED = " ist nicht installiert."
L_INFO_SETTINGS_ALL = "Tippe |cff388bdb/settings all|r|cffE8CB3B, um Einstellungen für alle unterstützten Addons anzuwenden"
L_INFO_SETTINGS_BIGWIGS = "Tippe |cff388bdb/settings bigwigs|r|cffE8CB3B, um |cff388bdbBigwigs|r Einstellungen anzuwenden"
L_INFO_SETTINGS_BT4 = "Tippe |cff388bdb/settings bartender4|r|cffE8CB3B, um |cff388bdbBartender4|r Einstellungen anzuwenden"
L_INFO_SETTINGS_BUTTONFACADE = "Tippe |cff388bdb/settings bfacade|r|cffE8CB3B, um |cff388bdbButtonFacade|r Einstellungen anzuwenden"
L_INFO_SETTINGS_CHATCONSOLIDATE = "Tippe |cff388bdb/settings chatfilter|r|cffE8CB3B, um |cff388bdbChatConsolidate|r Einstellungen anzuwenden"
L_INFO_SETTINGS_CLASSCOLOR = "Tippe |cff388bdb/settings color|r|cffE8CB3B, um |cff388bdb!ClassColor|r Einstellungen anzuwenden."
L_INFO_SETTINGS_CLASSTIMER = "Tippe |cff388bdb/settings classtimer|r|cffE8CB3B, um |cff388bdbClassTimer|r Einstellungen anzuwenden"
L_INFO_SETTINGS_MAPSTER = "Tippe |cff388bdb/settings mapster|r|cffE8CB3B, um |cff388bdbMapster|r Einstellungen anzuwenden"
L_INFO_SETTINGS_MSBT = "Tippe |cff388bdb/settings msbt|r|cffE8CB3B, um |cff388bdbMikScrollingBattleText|r Einstellungen anzuwenden"
L_INFO_SETTINGS_PLATES = "Tippe |cff388bdb/settings nameplates|r|cffE8CB3B, um |cff388bdbNameplates|r Einstellungen anzuwenden"
L_INFO_SETTINGS_SKADA = "Tippe |cff388bdb/settings skada|r|cffE8CB3B, um |cff388bdbSkada|r Einstellungen anzuwenden"
L_INFO_SETTINGS_THREATPLATES = "Position der |cff388bdbTidyPlates_ThreatPlates|r Elemente muss angepasst werden"
L_INFO_SETTINGS_XLOOT = "Tippe |cff388bdb/settings xloot|r|cffE8CB3B, um |cff388bdbXLoot|r Einstellungen anzuwenden"
-- Loot Localization
L_LOOT_ANNOUNCE = "Ankündigen"
L_LOOT_CANNOT = "Kann nicht würfeln"
L_LOOT_CHEST = ">> Beute aus Truhe"
L_LOOT_FISH = "Angel-Beute"
L_LOOT_MONSTER = ">> Beute von "
L_LOOT_RANDOM = "Zufälliger Spieler"
L_LOOT_SELF = "Eigene Beute"
L_LOOT_TO_GUILD = " Gilde"
L_LOOT_TO_PARTY = " Gruppe"
L_LOOT_TO_RAID = " Schlachtzug"
L_LOOT_TO_SAY = " Sagen"
-- Mail Localization
L_MAIL_COMPLETE = "Fertig."
L_MAIL_MESSAGES = "Nachrichten"
L_MAIL_NEED = "Benötige Briefkasten."
L_MAIL_STOPPED = "Gestoppt, Inventar ist voll."
L_MAIL_UNIQUE = "Gestoppt. Einzigartiges Duplikat in Tasche oder Bank gefunden."
-- Map Localization
L_MAP_FARMMODE = "|cff388bdbFarm-Modus|r"
-- FarmMode Minimap
L_MINIMAP_FARMMODE_ON = "|cffffe02eFarm-Modus|r: |cFF008000Aktiviert|r."
L_MINIMAP_FARMMODE_OFF = "|cffffe02eFarm-Modus|r: |cFFFF0000Deaktiviert|r."
-- Misc Localization
L_MISC_UI_OUTDATED = "Deine Version von |cff388bdbbudsUI|r ist veraltet. Du kannst die neueste Version von www.github.com/Budtender3000/budsUI/releases herunterladen"
L_MISC_UNDRESS = "Ausziehen"
L_MISC_REPAIR = "Warnung! Du musst deine Ausrüstung so schnell wie möglich reparieren!"
L_MISC_GUILD_CLEANUP_PROMPT = "Bist du sicher, dass du die Gilde bereinigen möchtest? Dies wird potenziell viele Mitglieder entfernen!"
L_MISC_GUILD_CLEANUP_TITLE = "Gilden-Bereinigung"
-- Popup Localization
L_POPUP_ARMORY = "|cffE8CB3BArmory|r"
L_POPUP_INSTALLUI = "|cff388bdbbudsUI|r wird zum ersten Mal mit diesem Charakter verwendet. Du musst das UI neu laden, um es einzurichten."
L_POPUP_RESETUI = "Bist du sicher, dass du alle |cff388bdbbudsUI|r Einstellungen zurücksetzen möchtest?"
L_POPUP_RESTART_GFX = "|cfff02c35WARNUNG:|r UI-Multisampling funktioniert nicht korrekt, Ränder könnten unscharf sein.|n|nJetzt beheben?"
L_POPUP_SETTINGS_ALL = "Einstellungen für alle unterstützten Addons anwenden? |n|n|cff388bdbEmpfohlen!|r"
L_POPUP_SETTINGS_BW = "Position der |cff388bdbBigWigs|r Elemente muss angepasst werden."
L_POPUP_SETTINGS_DBM = "Position der |cff388bdbDBM|r Balken muss angepasst werden."
L_POPUP_BOOSTUI = "|cfff02c35WARNUNG:|r Dies optimiert die Performance durch Reduzierung der Grafikeinstellungen. Nur anwenden bei |cfff02c35FPS|r Problemen!|r"
L_POPUP_RELOADUI = "Installation abgeschlossen. Klicke 'Akzeptieren', um das UI neu zu laden.|n|n|cffffe02eWICHTIGER HINWEIS:|r|nTippe nach dem Neuladen |cff388bdb/buds|r in den Chat, um das Config-Menü zu öffnen und das UI nach deinen Wünschen anzupassen!|n|nViel Spaß mit |cff388bdbbudsUI|r!"
-- Reputation Standing Localization
L_REPUTATION_EXALTED = "Ehrfürchtig"
L_REPUTATION_FRIENDLY = "Freundlich"
L_REPUTATION_HATED = "Hasserfüllt"
L_REPUTATION_HONORED = "Wohlwollend"
L_REPUTATION_HOSTILE = "Feindselig"
L_REPUTATION_NEUTRAL = "Neutral"
L_REPUTATION_REVERED = "Respektvoll"
L_REPUTATION_UNFRIENDLY = "Unfreundlich"
-- Stats Localization
L_STATS_GLOBAL = "Globale Latenz:"
L_STATS_HOME = "Heimlatenz:"
L_STATS_INC = "Eingehend:"
L_STATS_OUT = "Ausgehend:"
L_STATS_SYSTEMLEFT = "|cff388bdbLinksklick: PvE-Frame öffnen|r"
L_STATS_SYSTEMRIGHT = "|cff388bdbRechtsklick: Speicher bereinigen|r"
-- Tooltip Localization
L_TOOLTIP_ACH_COMPLETE = "Dein Status: Abgeschlossen am "
L_TOOLTIP_ACH_INCOMPLETE = "Dein Status: Nicht abgeschlossen"
L_TOOLTIP_ACH_STATUS = "Dein Status:"
L_TOOLTIP_ITEM_COUNT = "Gegenstandsanzahl:"
L_TOOLTIP_ITEM_ID = "Gegenstands-ID:"
L_TOOLTIP_LOADING = "Lädt..."
L_TOOLTIP_NO_TALENT = "Keine Talente"
L_TOOLTIP_SPELL_ID = "Zauber-ID:"
L_TOOLTIP_UNIT_DEAD = "|cffd94545Tot|r"
L_TOOLTIP_UNIT_GHOST = "|cff999999Geist|r"
L_TOOLTIP_WHO_TARGET = "Ziel von"
-- L["Done By"] = "Von: "
-- Total Memory Localization
L_TOTALMEMORY_USAGE = "Gesamter Speicherverbrauch:"
-- WowHead Link Localization
L_WATCH_WOWHEAD_LINK = "|cffE8CB3BWowhead-Link|r"
-- Welcome Localization
L_WELCOME_LINE_1 = "Willkommen bei |cff388bdbbudsUI|r v"
L_WELCOME_LINE_2_1 = ""
L_WELCOME_LINE_2_2 = "Tippe |cff388bdb/uihelp|r für Hilfe oder |cff388bdb/buds|r für Konfiguration"
-- Install Wizard Localization
L_INSTALL_TITLE = "|cff388bdbInstallations-Assistent|r"
L_INSTALL_BTN_PREV = "< Zurück"
L_INSTALL_BTN_NEXT = "Weiter >"
L_INSTALL_BTN_DONE = "Fertig"
L_INSTALL_BTN_SKIP = "Überspringen"
L_INSTALL_STEP_TXT = "Schritt %d von %d"
L_INSTALL_ERROR = "|cffff0000budsUI Install Error:|r "

L_INSTALL_STEP1_TITLE = "Willkommen bei budsUI!"
L_INSTALL_STEP1_DESC = "Dieser Assistent hilft dir, budsUI optimal einzurichten.\n\nWir werden folgende Bereiche konfigurieren:\n\n• Interface-Einstellungen\n• Grafik & Kamera\n• Kampf & Tooltips\n• Chat-Einstellungen\n• Chat-Fenster Layout\n• Verschiedenes\n\nKlicke auf 'Weiter' um zu beginnen."
L_INSTALL_STEP2_TITLE = "Schritt 1: Interface"
L_INSTALL_STEP2_DESC = "Konfiguriere grundlegende Interface-Einstellungen:\n\n• Aktionsleisten immer anzeigen\n• Aktionsleisten sperren\n• Auto-Dismount aktivieren\n• Quest-Tracking aktivieren\n• Loot-Taste auf SHIFT setzen\n• Selbstzauber-Taste auf ALT setzen"
L_INSTALL_STEP3_TITLE = "Schritt 2: Grafik & Kamera"
L_INSTALL_STEP3_DESC = "Optimiere Grafik- und Kamera-Einstellungen:\n\n• Maximale Kameradistanz auf 50\n• Screenshot-Qualität auf Maximum\n• UI-Skalierung automatisch anpassen\n• Gewaltlevel auf Maximum"
L_INSTALL_STEP4_TITLE = "Schritt 3: Kampf & Tooltips"
L_INSTALL_STEP4_DESC = "Konfiguriere Kampf-relevante Einstellungen:\n\n• Buff-Dauer anzeigen\n• Bedrohungswarnung aktivieren\n• Erweiterte Tooltips\n• Klassenfarben in Namensplaketten\n• Buff-Konsolidierung deaktivieren"
L_INSTALL_STEP5_TITLE = "Schritt 4: Chat-Einstellungen"
L_INSTALL_STEP5_DESC = "Optimiere Chat-Funktionen:\n\n• Mausrad-Scrollen aktivieren\n• Klassischen Chat-Stil verwenden\n• Chat-Verzögerung entfernen\n• Spam-Filter konfigurieren"
L_INSTALL_STEP6_TITLE = "Schritt 5: Chat-Fenster"
L_INSTALL_STEP6_DESC = "Richte Chat-Fenster ein:\n\n• 5 Chat-Fenster erstellen\n• Fenster 1: Allgemein (Say, Yell, Emote, System)\n• Fenster 2: Gilden-Log\n• Fenster 3: Beute (Loot, XP, Gold)\n• Fenster 4: Handel\n• Fenster 5: Gruppe (Whisper, Party, Raid, BG)\n• Klassenfarben in allen Kanälen aktivieren"
L_INSTALL_STEP7_TITLE = "Schritt 6: Verschiedenes"
L_INSTALL_STEP7_DESC = "Letzte Einstellungen:\n\n• Minimap-Rotation deaktivieren\n• Anfänger-Tipps ausblenden\n• Tutorials deaktivieren\n• Fehlerberichte konfigurieren"
L_INSTALL_STEP8_TITLE = "Installation abgeschlossen!"
L_INSTALL_STEP8_DESC = "Alle Einstellungen wurden erfolgreich konfiguriert.\n\nbudsUI ist nun einsatzbereit!\n\nKlicke auf 'Fertig' um das Interface neu zu laden.\n\nViel Spaß mit budsUI!\n\nBesuche: |cff388bdbwww.github.com/Budtender3000/budsUI|r"

-- Slash Commands Localization
L_SLASHCMD_HELP = {
	"|cffffffffVerfügbare Slash-Befehle:|r",
	"|cff388bdb/cfg|r - |cffE8CB3BÖffnet |cff388bdbbudsUI|r |cffE8CB3BEinstellungen.|r",
	"|cff388bdb/kb|r - |cffE8CB3BTastenbelegung für|r |cff388bdbbudsUI|r.",
	"|cff388bdb/align|r - |cffE8CB3BRaster zur UI-Ausrichtung.",
	"|cff388bdb/bigchat|r - |cffE8CB3BVergrößert das Chat-Fenster.",
	"|cff388bdb/clc, /clfix|r - |cffE8CB3BRepariert das Kampflog bei Problemen.",
	"|cff388bdb/clearchat, /cc|r - |cffE8CB3BLöscht das aktive Chat-Fenster.",
	"|cff388bdb/clearquests, /clquests|r - |cffE8CB3BLöscht alle deine Quests.",
	"|cff388bdb/dbmtest|r - |cffE8CB3BTestet Deadly Boss Mods.",
	"|cff388bdb/farmmode|r - |cffE8CB3BVergrößert die Minimap.",
	"|cff388bdb/frame|r - |cffE8CB3BZeigt Frame-Infos unter dem Cursor.",
	"|cff388bdb/fs|r - |cffE8CB3BZeigt Framestack. Nützlich für Entwickler.",
	"|cff388bdb/gm|r - |cffE8CB3BÖffnet das GM-Fenster.",
	"|cff388bdb/moveui|r - |cffE8CB3BErlaubt das Verschieben von UI-Elementen.",
	"|cff388bdb/rc|r - |cffE8CB3BAktiviert eine Bereitschaftsprüfung.",
	"|cff388bdb/rd|r - |cffE8CB3BLöst Gruppe oder Schlachtzug auf.",
	"|cff388bdb/resetconfig|r - |cffE8CB3BSetzt |cff388bdbbudsUI|r |cffE8CB3BEinstellungen zurück.|r",
	"|cff388bdb/resetui|r - |cffE8CB3BSetzt |cff388bdbbudsUI|r auf Standardeinstellungen zurück.",
	"|cff388bdb/rl|r - |cffE8CB3BLädt das Interface neu.",
	"|cff388bdb/settings ADDON_NAME|r - |cffE8CB3BWendet Einstellungen für msbt, dbm, skada oder alle Addons an.",
	"|cff388bdb/spec, /ss|r - |cffE8CB3BWechselt zwischen Talentspezialisierungen.",
	"|cff388bdb/teleport|r - |cffE8CB3BTeleportation zu/von zufälligen Dungeons.",
	"|cff388bdb/testa|r - |cffE8CB3BTestet Blizzard-Benachrichtigungen.",
	"|cff388bdb/toparty, /toraid, /convert|r - |cffE8CB3BWandelt Gruppe in Schlachtzug um.",
	"|cff388bdb/tt|r - |cffE8CB3BFlüstert dem Ziel.",
	"|cff388bdb/pc|r - |cffE8CB3BPull-Countdown-Timer.",
}
