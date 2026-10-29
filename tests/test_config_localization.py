"""Exercise translated widgets, user values and all real configuration pages."""
from pathlib import Path
from typing import Any
import unittest

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]


def boot(locale="ruRU"):
    lua: Any = LuaRuntime(unpack_returned_tuples=True)
    for name in ("wow_stub.lua", "config_stub.lua"):
        lua.execute((ROOT / "tests" / name).read_text(encoding="utf-8-sig"))
    lua.globals().Test.locale = locale
    for name in ("Locales/enUS.lua", "Locales/ruRU.lua", "Controls.lua"):
        lua.execute((ROOT / "budsUI_Config" / name).read_text(encoding="utf-8-sig"),
                    "budsUI_Config", lua.globals().configNS)
    return lua


def load_pages(lua):
    for path in sorted((ROOT / "budsUI_Config/Pages").glob("*.lua")):
        lua.execute(path.read_text(encoding="utf-8-sig"), "budsUI_Config", lua.globals().configNS)


class ConfigLocalizationTests(unittest.TestCase):
    def test_description_tooltip_and_button_translate(self):
        lua = boot()
        lua.execute("""
            local ns = configNS
            Test.description = ns.creators.description(UIParent, {description = 'General'})
            Test.button = ns.CreateButton(UIParent, 'Import', 100)
            Test.row = ns.CreateRow(UIParent, {label = 'General', desc = 'Automatic UI scale based on screen resolution.'})
            ns.RowEnter(Test.row)
        """)
        g = lua.globals()
        self.assertEqual(g.Test.description.label.GetText(g.Test.description.label), "Общее")
        self.assertEqual(g.Test.button.GetText(g.Test.button), "Импорт")
        self.assertEqual(g.GameTooltip.GetText(g.GameTooltip), "Общее")
        self.assertIn("масштаб", g.GameTooltip.lines[1][1])

    def test_select_labels_translate_without_translating_stored_enum(self):
        lua = boot()
        lua.execute("""
            Test.entry = {group = 'Unitframe', option = 'PowerFormat', label = 'General',
                values = {{'None', 'None'}, {'Mana', 'Mana'}}}
            Test.row = configNS.creators.select(UIParent, Test.entry)
            Test.row.Refresh()
            Test.row.dropdown.initialize(Test.row.dropdown, 1)
        """)
        g = lua.globals()
        self.assertEqual(g[g.Test.row.dropdown.GetName(g.Test.row.dropdown) + "Text"].GetText(
            g[g.Test.row.dropdown.GetName(g.Test.row.dropdown) + "Text"]), "Нет")
        self.assertEqual(g.Test.menuOptions[2].text, "Мана")
        g.Test.menuOptions[2].func()
        self.assertEqual(g.C.Unitframe.PowerFormat, "Mana")
        self.assertEqual(g.budsUIData.Profiles.Default.Unitframe.PowerFormat, "Mana")
        self.assertEqual(g.Test.entry["values"][2][1], "Mana")
        self.assertEqual(g.Test.entry["values"][2][2], "Mana")

    def test_profile_names_and_blacklist_names_are_not_translated(self):
        lua = boot()
        load_pages(lua)
        lua.execute("""
            for _, page in ipairs(configNS.pages) do
                if page.key == 'Profiles' then
                    Test.profileRow = configNS.creators.select(UIParent, page.schema[3])
                    Test.profileRow.dropdown.initialize(Test.profileRow.dropdown, 1)
                elseif page.key == 'Nameplate' then
                    Test.blacklistRow = configNS.CreateRow(UIParent, page.tabs[2].schema()[4])
                end
            end
        """)
        g = lua.globals()
        self.assertEqual(g.Test.menuOptions[2].text, "General")
        self.assertEqual(g.Test.blacklistRow.label.GetText(g.Test.blacklistRow.label), "General")

    def test_every_page_and_tab_can_render_in_both_locales(self):
        for locale in ("ruRU", "enUS"):
            lua = boot(locale)
            load_pages(lua)
            lua.execute((ROOT / "budsUI_Config/Core.lua").read_text(encoding="utf-8-sig"),
                        "budsUI_Config", lua.globals().configNS)
            for page in lua.globals().configNS.pages.values():
                with self.subTest(locale=locale, page=page.key):
                    if page.tabs:
                        for tab in page.tabs.values():
                            page.activeTabKey = tab.key
                            lua.globals().configNS.Toggle(page.key)
                    else:
                        lua.globals().configNS.Toggle(page.key)
            self.assertTrue(lua.globals().budsUIConfigFrame.IsShown(lua.globals().budsUIConfigFrame))

    def test_case_insensitive_russian_search_uses_visible_captions(self):
        lua = boot()
        load_pages(lua)
        lua.execute((ROOT / "budsUI_Config/Core.lua").read_text(encoding="utf-8-sig"),
                    "budsUI_Config", lua.globals().configNS)
        lua.globals().configNS.Toggle("General")
        lua.globals().configNS.PerformSearch("МАСШТАБ")
        rows = lua.globals().budsUIConfigFrame.rows
        self.assertGreater(len(rows), 2)
        self.assertIn("Результаты", rows[1].label.GetText(rows[1].label))
        captions = [row.label.GetText(row.label) for row in rows.values()]
        self.assertTrue(any("масштаб" in caption.lower() for caption in captions))


if __name__ == "__main__":
    unittest.main()
