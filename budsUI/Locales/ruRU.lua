-- Russian localization; enUS remains the fallback for other clients.
local K, C, L, _ = select(2, ...):unpack()
if GetLocale() ~= "ruRU" then return end

-- Addon list
L_ADDON_DISABLE_ALL = "Отключить все"
L_ADDON_ENABLE_ALL = "Включить все"
L_ADDON_LIST = "|cff388bdbСписок аддонов|r"
L_ADDON_RELOAD = "Перезагрузить"
-- Announcements
L_ANNOUNCE_FP_CAST = "%s применяет %s."
L_ANNOUNCE_FP_CLICK = "%s применяет %s. Нажмите!"
L_ANNOUNCE_FP_PRE = "%s приготовил(а) %s."
L_ANNOUNCE_FP_PUT = "%s поставил(а) %s."
L_ANNOUNCE_FP_STAT = "%s приготовил(а) %s — [%s]."
L_ANNOUNCE_FP_USE = "%s использует %s."
L_ANNOUNCE_INTERRUPTED = INTERRUPTED
L_ANNOUNCE_PC_ABORTED = "Атака ОТМЕНЕНА!"
L_ANNOUNCE_PC_GO = "В БОЙ!"
L_ANNOUNCE_PC_MSG = "Атакуем %s через %s.."
L_ANNOUNCE_SAPPED = "Ошеломлён"
L_ANNOUNCE_SAPPED_BY = "Ошеломил: "
-- Automation
L_SELL_TRASH = "Продано серых предметов: %d%s, на сумму %s"
L_REPAIR_BANK = "Ремонт за счёт гильдии: %s."
L_REPAIRED_FOR = "Стоимость ремонта: %s."
L_CANT_AFFORD_REPAIR = "Недостаточно денег на ремонт."
-- Bags
L_BAG_BAGS_BIDS = "Используются сумки: "
L_BAG_BUY_BANKS_SLOT = "купить ячейку банка (банк должен быть открыт)."
L_BAG_BUY_SLOTS = "Купить новую ячейку: /bags purchase yes"
L_BAG_COSTS = "Стоимость: %.2f золота"
L_BAG_NOTHING_SORT = "Нечего сортировать."
L_BAG_NO_SLOTS = "Больше ячеек купить нельзя!"
L_BAG_OPEN_BANK = "Сначала откройте банк."
L_BAG_RIGHT_CLICK_CLOSE = "Правая кнопка мыши: открыть меню"
L_BAG_SHOW_BAGS = "Показать сумки"
L_BAG_SORT = "сортировать сумки или банк, если он открыт."
L_BAG_SORTING_BAGS = "Сортировка завершена."
L_BAG_SORT_MENU = "Сортировать"
L_BAG_SORT_SPECIAL = "Сортировать специальные сумки"
L_BAG_SHOW_KEYRING = "Показать связку ключей"
L_BAG_STACK = "объединить неполные стопки в сумках или открытом банке."
L_BAG_RIGHT_CLICK_SEARCH = "Правая кнопка мыши: поиск."
L_BAG_STACK_END = "Объединение стопок завершено."
L_BAG_STACK_MENU = "Объединить стопки"
L_BAG_STACK_SPECIAL = "Объединить в специальных сумках"
-- Key bindings
L_BIND_BINDING = "Назначение"
L_BIND_CLEARED = "Все назначения клавиш удалены для"
L_BIND_DISCARD = "Все новые назначения клавиш отменены."
L_BIND_INSTRUCT = "Наведите мышь на кнопку способности и нажмите нужную клавишу. Escape или правая кнопка мыши удаляют назначение."
L_BIND_KEY = "Клавиша"
L_BIND_NO_SET = "Клавиши не назначены"
L_BIND_SAVED = "Все назначения клавиш сохранены."
-- Chat
L_CHAT_AFK = "AFK"
L_CHAT_BATTLEGROUND = "БГ"
L_CHAT_BATTLEGROUND_LEADER = "ЛБГ"
L_CHAT_DND = "DND"
L_CHAT_GUILD = "Г"
L_CHAT_OFFICER = "О"
L_CHAT_PARTY = "Гр"
L_CHAT_PARTY_LEADER = "ЛГр"
L_CHAT_RAID = "Р"
L_CHAT_RAID_LEADER = "ЛР"
L_CHAT_RAID_WARNING = "ОР"
L_CHAT_SAYS = "говорит"
L_CHAT_WHISPERS = "шепчет"
L_CHAT_YELLS = "кричит"
L_CHAT_BIGCHAT_OFF = "|cffffe02eУвеличенный чат|r: выключен"
L_CHAT_BIGCHAT_ON = "|cffffe02eУвеличенный чат|r: включён"
L_CHAT_HISTORY_SEPARATOR = "— сообщения до перезагрузки —"
L_CHAT_COPY = "Копировать чат"
L_CHAT_COPY_HINT = "|cff00ff00Левая кнопка:|r копировать\n|cff00ff00Правая кнопка:|r меню чата\n|cff00ff00Средняя кнопка:|r /roll 1-100"
-- Classes
L_CLASS_HUNTER_CONTENT = "Ваш питомец доволен!"
L_CLASS_HUNTER_HAPPY = "Ваш питомец счастлив!"
L_CLASS_HUNTER_UNHAPPY = "Ваш питомец несчастлив!"
-- Data texts
L_DATATEXT_ALTERAC = "Альтеракская долина"
L_DATATEXT_ANCIENTS = "Берег Древних"
L_DATATEXT_ARATHI = "Низина Арати"
L_DATATEXT_BASESASSAULTED = "Захвачено баз:"
L_DATATEXT_BASESDEFENDED = "Защищено баз:"
L_DATATEXT_DEMOLISHERSDESTROYED = "Уничтожено разрушителей:"
L_DATATEXT_EYE = "Око Бури"
L_DATATEXT_FLAGSCAPTURED = "Захвачено флагов:"
L_DATATEXT_FLAGSRETURNED = "Возвращено флагов:"
L_DATATEXT_GATESDESTROYED = "Разрушено ворот:"
L_DATATEXT_GRAVEYARDSASSAULTED = "Захвачено кладбищ:"
L_DATATEXT_GRAVEYARDSDEFENDED = "Защищено кладбищ:"
L_DATATEXT_ISLE = "Остров Завоеваний"
L_DATATEXT_MEMORY_CLEANED = "|cffffe02eОсвобождено:|r "
L_DATATEXT_TOWERSASSAULTED = "Захвачено башен:"
L_DATATEXT_TOWERSDEFENDED = "Защищено башен:"
L_DATATEXT_WARSONG = "Ущелье Песни Войны"
-- Experience and reputation
L_CURRENT_EXPERIENCE = "Текущий опыт: "
L_CURRENT_REPUTATION = "Текущая репутация: "
L_EXPERIENCE_BAR = "Опыт: "
L_REMAINING_EXPERIENCE = "Осталось опыта: "
L_REMAINING_REPUTATION = "Осталось репутации: "
L_REPUTATION_BAR = "Репутация: "
L_RESTED_EXPERIENCE = "Отдых: "
L_STANDING_REPUTATION = "Отношение: "
-- Combat and invites
L_ERR_NOT_IN_COMBAT = "Это действие недоступно в бою или после смерти."
L_INVITE_ENABLE = "|cffffe02eАвтоприглашение|r |cFF008000ВКЛ|r: "
L_INVITE_DISABLE = "|cffffe02eАвтоприглашение|r |cFFFF0000ВЫКЛ|r"
-- Information
L_INFO_DISBAND = "Роспуск группы..."
L_INFO_DUEL = "Отклонён вызов на дуэль от "
L_INFO_ERRORS = "Ошибок пока нет."
L_INFO_INVITE = "Принято приглашение от "
L_INFO_NOT_INSTALLED = " не установлен."
L_INFO_SETTINGS_ALL = "Введите |cff388bdb/settings all|r|cffffe02e, чтобы применить настройки всех поддерживаемых аддонов."
L_INFO_SETTINGS_BT4 = "Введите |cff388bdb/settings bartender4|r|cffffe02e, чтобы настроить |cff388bdbBartender4|r"
L_INFO_SETTINGS_BUTTONFACADE = "Введите |cff388bdb/settings bfacade|r|cffffe02e, чтобы настроить |cff388bdbButtonFacade|r"
L_INFO_SETTINGS_CHATCONSOLIDATE = "Введите |cff388bdb/settings chatfilter|r|cffffe02e, чтобы настроить |cff388bdbChatConsolidate|r"
L_INFO_SETTINGS_CLASSCOLOR = "Введите |cff388bdb/settings color|r|cffffe02e, чтобы настроить |cff388bdb!ClassColor|r"
L_INFO_SETTINGS_CLASSTIMER = "Введите |cff388bdb/settings classtimer|r|cffffe02e, чтобы настроить |cff388bdbClassTimer|r"
L_INFO_SETTINGS_GRID = "Введите |cff388bdb/settings bartender4|r|cffffe02e, чтобы применить настройки |cff388bdbGrid4|r"
L_INFO_SETTINGS_MAPSTER = "Введите |cff388bdb/settings mapster|r|cffffe02e, чтобы настроить |cff388bdbMapster|r"
L_INFO_SETTINGS_MSBT = "Введите |cff388bdb/settings msbt|r|cffffe02e, чтобы настроить |cff388bdbMikScrollingBattleText|r"
L_INFO_SETTINGS_PLATES = "Введите |cff388bdb/settings nameplates|r|cffffe02e, чтобы настроить |cff388bdbNameplates|r"
L_INFO_SETTINGS_SKADA = "Введите |cff388bdb/settings skada|r|cffffe02e, чтобы настроить |cff388bdbSkada|r"
L_INFO_SETTINGS_THREATPLATES = "Введите |cff388bdb/settings threatplates|r|cffffe02e, чтобы настроить |cff388bdbTidyPlates_ThreatPlates|r"
L_INFO_SETTINGS_XLOOT = "Введите |cff388bdb/settings xloot|r|cffffe02e, чтобы настроить |cff388bdbXLoot|r"
-- Loot
L_LOOT_ANNOUNCE = "Объявить в"
L_LOOT_CANNOT = "Нельзя бросить кости"
L_LOOT_CHEST = ">> Добыча из сундука"
L_LOOT_FISH = "Улов"
L_LOOT_MONSTER = ">> Добыча с "
L_LOOT_RANDOM = "Случайный игрок"
L_LOOT_SELF = "Моя добыча"
L_LOOT_TO_GUILD = " гильдию"
L_LOOT_TO_PARTY = " группу"
L_LOOT_TO_RAID = " рейд"
L_LOOT_TO_SAY = " сказать"
-- Mail
L_MAIL_COMPLETE = "Готово."
L_MAIL_MESSAGES = "писем"
L_MAIL_NEED = "Нужен почтовый ящик."
L_MAIL_STOPPED = "Остановлено: сумки заполнены."
L_MAIL_UNIQUE = "Остановлено: в сумках или банке уже есть такой уникальный предмет."
-- Map
L_MAP_BOUNDS = "За пределами карты!"
L_MAP_CURSOR = "Курсор: "
-- Miscellaneous
L_MISC_UI_OUTDATED = "Ваша версия |cff388bdbbudsUI|r устарела. Новая версия: |cffffe02ewww.github.com/Budtender3000/budsUI/releases|r"
L_MISC_UNDRESS = "Снять экипировку"
L_MISC_REPAIR = "Внимание! Необходимо как можно скорее починить экипировку!"
L_MISC_GUILD_CLEANUP_PROMPT = "Очистить состав гильдии? Это может исключить много участников!"
L_MISC_GUILD_CLEANUP_TITLE = "Очистка гильдии"
-- Trainer
L_TRAIN_ALL = "Изучить всё"
L_TRAIN_ALL_TOOLTIP_PLURAL = "Изучить навыки (%d) за %s"
L_TRAIN_ALL_TOOLTIP_SINGLE = "Изучить навык за %s"
-- Popups
L_POPUP_ARMORY = "|cffffe02eОружейная|r"
L_POPUP_COPY_URL = "Ctrl+C — копировать"
L_POPUP_BOOSTUI = "|cfff02c35ВНИМАНИЕ:|r настройки графики будут снижены для повышения производительности. Подтверждайте только при проблемах с |cfff02c35FPS|r!"
L_POPUP_INSTALLUI = "Спасибо, что выбрали |cff388bdbbudsUI|r!|n|nПодтвердите установку, чтобы применить настройки."
L_POPUP_RELOADUI = "Установка завершена. Нажмите «Принять», чтобы перезагрузить интерфейс.|n|n|cffffe02eВАЖНО:|r после загрузки введите |cff388bdb/buds|r, чтобы открыть настройки.|n|nПриятной игры с |cff388bdbbudsUI|r!"
L_POPUP_RESETUI = "Сбросить все настройки |cff388bdbbudsUI|r?"
L_POPUP_RESTART_GFX = "|cfff02c35ВНИМАНИЕ:|r некорректная настройка gxMultisample может размывать границы интерфейса.|n|nИсправить сейчас?"
L_POPUP_SETTINGS_ALL = "|cfff02c35ВНИМАНИЕ:|r будут применены настройки всех поддерживаемых аддонов. Настройки отсутствующих аддонов не изменятся."
L_POPUP_SETTINGS_DBM = "Необходимо изменить положение полос |cff388bdbDBM|r."
-- Reputation standings
L_REPUTATION_EXALTED = "Превознесение"
L_REPUTATION_FRIENDLY = "Дружелюбие"
L_REPUTATION_HATED = "Ненависть"
L_REPUTATION_HONORED = "Уважение"
L_REPUTATION_HOSTILE = "Враждебность"
L_REPUTATION_NEUTRAL = "Равнодушие"
L_REPUTATION_REVERED = "Почтение"
L_REPUTATION_UNFRIENDLY = "Неприязнь"
-- Stats
L_STATS_GLOBAL = "Общая задержка:"
L_STATS_HOME = "Задержка сервера:"
L_STATS_INC = "Входящие:"
L_STATS_OUT = "Исходящие:"
L_STATS_SYSTEMLEFT = "|cff388bdbЛевая кнопка: открыть окно PvE|r"
L_STATS_SYSTEMRIGHT = "|cff388bdbПравая кнопка: очистить память|r"
-- Tooltips
L_TOOLTIP_ACH_COMPLETE = "Ваш результат: выполнено "
L_TOOLTIP_ACH_INCOMPLETE = "Ваш результат: не выполнено"
L_TOOLTIP_ACH_STATUS = "Ваш результат:"
L_TOOLTIP_ITEM_COUNT = "Количество предметов:"
L_TOOLTIP_ITEM_ID = "ID предмета:"
L_TOOLTIP_LOADING = "Загрузка..."
L_TOOLTIP_NO_TALENT = "Нет талантов"
L_TOOLTIP_SPELL_ID = "ID заклинания:"
L_TOOLTIP_UNIT_DEAD = "|cffd94545Мёртв|r"
L_TOOLTIP_UNIT_GHOST = "|cff999999Призрак|r"
L_TOOLTIP_WHO_TARGET = "Цель для"
L_TOTALMEMORY_USAGE = "Общее использование памяти:"
L_WATCH_WOWHEAD_LINK = "|cffffe02eСсылка на Wowhead|r"
-- Welcome
L_WELCOME_LINE_1 = "Добро пожаловать в |cff388bdbbudsUI|r v"
L_WELCOME_LINE_2_1 = ""
L_WELCOME_LINE_2_2 = "Введите |cff388bdb/uihelp|r |cffffe02eдля справки или|r |cff388bdb/buds|r |cffffe02eдля настройки|r"
-- Installation wizard
L_INSTALL_TITLE = "|cff388bdbМастер установки|r"
L_INSTALL_BTN_PREV = "< Назад"
L_INSTALL_BTN_NEXT = "Далее >"
L_INSTALL_BTN_DONE = "Завершить"
L_INSTALL_BTN_SKIP = "Пропустить"
L_INSTALL_STEP_TXT = "Шаг %d из %d"
L_INSTALL_ERROR = "|cffff0000Ошибка установки budsUI:|r "
L_INSTALL_STEP1_TITLE = "Добро пожаловать в budsUI!"
L_INSTALL_STEP1_DESC = "Мастер поможет настроить budsUI.\n\nБудут настроены:\n\n• Интерфейс\n• Графика и камера\n• Бой и подсказки\n• Чат\n• Окна чата\n• Дополнительные параметры\n\nНажмите «Далее», чтобы начать."
L_INSTALL_STEP2_TITLE = "Шаг 1: Интерфейс"
L_INSTALL_STEP2_DESC = "Основные настройки интерфейса:\n\n• Всегда показывать панели действий\n• Закрепить кнопки действий\n• Автоматически спешиваться\n• Отслеживать задания\n• Клавиша добычи — SHIFT\n• Клавиша применения на себя — ALT"
L_INSTALL_STEP3_TITLE = "Шаг 2: Графика и камера"
L_INSTALL_STEP3_DESC = "Настройки графики и камеры:\n\n• Максимальная дистанция камеры — 50\n• Максимальное качество снимков экрана\n• Автоматический масштаб интерфейса\n• Максимальный уровень эффектов крови"
L_INSTALL_STEP4_TITLE = "Шаг 3: Бой и подсказки"
L_INSTALL_STEP4_DESC = "Боевые настройки:\n\n• Показывать длительность эффектов\n• Предупреждать об угрозе\n• Подробные подсказки\n• Цвета классов на индикаторах имён\n• Отключить объединение баффов"
L_INSTALL_STEP5_TITLE = "Шаг 4: Чат"
L_INSTALL_STEP5_DESC = "Настройки чата:\n\n• Прокрутка колёсиком мыши\n• Классический стиль чата\n• Убрать задержку чата\n• Настроить фильтр спама"
L_INSTALL_STEP6_TITLE = "Шаг 5: Окна чата"
L_INSTALL_STEP6_DESC = "Настройка окон чата:\n\n• Создать 5 окон\n• Окно 1: общее (сказать, крик, эмоции, система)\n• Окно 2: гильдия\n• Окно 3: добыча, опыт, золото\n• Окно 4: торговля\n• Окно 5: личные сообщения, группа, рейд, БГ\n• Включить цвета классов во всех каналах"
L_INSTALL_STEP7_TITLE = "Шаг 6: Дополнительно"
L_INSTALL_STEP7_DESC = "Последние настройки:\n\n• Отключить вращение миникарты\n• Скрыть подсказки новичкам\n• Отключить обучение\n• Настроить сообщения об ошибках"
L_INSTALL_STEP8_TITLE = "Установка завершена!"
L_INSTALL_STEP8_DESC = "Все настройки применены.\n\nbudsUI готов к работе!\n\nНажмите «Завершить», чтобы перезагрузить интерфейс.\n\nПриятной игры!\n\nСайт: |cff388bdbwww.github.com/Budtender3000/budsUI|r"
-- Runtime strings must be loaded before SpellBook and proc frames capture them.
L_SPELLBOOK_SEARCH = "Поиск"
L_SPELLBOOK_HIDE_PASSIVE = "Скрыть пассивные способности"
L_SPELLBOOK_HIDE_AURAS = "Скрыть ауры"
L_SPELLBOOK_HIDE_TOTEMS = "Скрыть тотемы"
L_SPELLBOOK_SEARCH_COMBAT = "Поиск применяется после боя"
L_SPELLBOOK_EMPTY = "Ничего не найдено"
L_UNKNOWN_TRINKET = "Неизвестный аксессуар"
L_UNKNOWN_TRINKET_DESC = "Появится после первого срабатывания."
L_ICD_FORMAT = "Внутренний кулдаун: %d сек."
-- Death recap
L_RECAP_TITLE = "Причина смерти"
L_RECAP_YOU_DIED = "Вы погибли."
L_RECAP_EMPTY = "Смертей пока не записано"
L_RECAP_MELEE = "Ближний бой"
L_RECAP_BURST = "-%s за %.1f сек."
L_RECAP_HEAL = "%d исцеления"
L_RECAP_DAMAGE_SCHOOL = "%d урона (%s)"
L_RECAP_DAMAGE = "%d урона"
L_RECAP_CRITICAL = "Критический удар"
L_RECAP_OVERKILL = "%d избыточного урона"
L_RECAP_ABSORBED = "%d поглощено"
L_RECAP_RESISTED = "%d сопротивления"
L_RECAP_BLOCKED = "%d заблокировано"
L_RECAP_SOURCE = "%s — %s"
L_RECAP_KILLING_BLOW = "Смертельный удар при %d%% здоровья"
L_RECAP_BEFORE_DEATH = "За %.1f сек. до смерти при %d%% здоровья"
L_RECAP_PHYSICAL = "Физический"
L_RECAP_HOLY = "Свет"
L_RECAP_FIRE = "Огонь"
L_RECAP_NATURE = "Природа"
L_RECAP_FROST = "Лёд"
L_RECAP_SHADOW = "Тьма"
L_RECAP_ARCANE = "Тайная магия"
L_RECAP_FALLING = "Падение"
L_RECAP_DROWNING = "Утопление"
L_RECAP_FATIGUE = "Усталость"
L_RECAP_LAVA = "Лава"
L_RECAP_SLIME = "Слизь"
L_RECAP_SCHOOLS = {
    [1] = L_RECAP_PHYSICAL, [2] = L_RECAP_HOLY, [4] = L_RECAP_FIRE,
    [8] = L_RECAP_NATURE, [16] = L_RECAP_FROST, [32] = L_RECAP_SHADOW,
    [64] = L_RECAP_ARCANE,
}
L_RECAP_ENVIRONMENT = {
    FALLING = L_RECAP_FALLING, DROWNING = L_RECAP_DROWNING,
    FATIGUE = L_RECAP_FATIGUE, FIRE = L_RECAP_FIRE,
    LAVA = L_RECAP_LAVA, SLIME = L_RECAP_SLIME,
}
-- Slash command help; commands themselves are not translated.
L_SLASHCMD_HELP = {
    "|cffffffffДоступные команды:|r",
    "|cff388bdb/align|r — |cffffe02eсетка для выравнивания интерфейса.",
    "|cff388bdb/bigchat|r — |cffffe02eувеличить окно чата.",
    "|cff388bdb/cfg|r — |cffffe02eоткрыть настройки |cff388bdbbudsUI|r.",
    "|cff388bdb/clc, /clfix|r — |cffffe02eвосстановить журнал боя.",
    "|cff388bdb/clearchat, /cc|r — |cffffe02eочистить выбранное окно чата.",
    "|cff388bdb/clearquests, /clquests|r — |cffffe02eотменить все задания.",
    "|cff388bdb/dbmtest|r — |cffffe02eпроверить полосы Deadly Boss Mods.",
    "|cff388bdb/frame|r — |cffffe02eсведения о фрейме под курсором.",
    "|cff388bdb/fs|r — |cffffe02eпоказать стек фреймов.",
    "|cff388bdb/gm|r — |cffffe02eоткрыть окно помощи GM.",
    "|cff388bdb/moveui|r — |cffffe02eпереместить элементы интерфейса.",
    "|cff388bdb/rc|r — |cffffe02eпроверка готовности.",
    "|cff388bdb/rd|r — |cffffe02eраспустить группу или рейд.",
    "|cff388bdb/resetconfig|r — |cffffe02eсбросить настройки |cff388bdbbudsUI|r.",
    "|cff388bdb/resetui|r — |cffffe02eвернуть стандартные настройки интерфейса.",
    "|cff388bdb/rl|r — |cffffe02eперезагрузить интерфейс.",
    "|cff388bdb/settings ADDON_NAME|r — |cffffe02eприменить настройки msbt, dbm, skada или всех аддонов.",
    "|cff388bdb/spec, /ss|r — |cffffe02eсменить специализацию.",
    "|cff388bdb/teleport|r — |cffffe02eтелепортироваться в случайное подземелье или обратно.",
    "|cff388bdb/testa|r — |cffffe02eпроверить уведомления Blizzard.",
    "|cff388bdb /toraid, /convert|r — |cffffe02eпреобразовать группу в рейд.",
    "|cff388bdb/tt|r — |cffffe02eшепнуть текущей цели.",
    "|cff388bdb/pc|r — |cffffe02eначать отсчёт перед атакой.",
    "|cff388bdb/recap|r — |cffffe02eоткрыть последнюю причину смерти.",
}
