"""Load-order, locale coverage and Lua 5.1 compiler regression checks."""
from pathlib import Path
from typing import Any
import re
import unittest
import xml.etree.ElementTree as ET

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]


def source(path):
    return path.read_text(encoding="utf-8-sig")


def manifest_files(path):
    if path.suffix == ".toc":
        names = [line.strip() for line in source(path).splitlines()
                 if line.strip() and not line.lstrip().startswith("#")]
    else:
        names = [element.attrib["file"] for element in ET.fromstring(source(path)).iter()
                 if "file" in element.attrib]
    return [path.parent / name.replace(chr(92), "/") for name in names]


class LocaleAndLoadTests(unittest.TestCase):
    def test_every_manifest_entry_resolves_to_a_file(self):
        queue = [ROOT / "budsUI/budsUI.toc", ROOT / "budsUI_Config/budsUI_Config.toc"]
        seen = set()
        missing = []
        while queue:
            path = queue.pop()
            if path in seen:
                continue
            seen.add(path)
            for item in manifest_files(path):
                if not item.is_file():
                    missing.append(str(item.relative_to(ROOT)))
                elif item.suffix in (".toc", ".xml"):
                    queue.append(item)
        self.assertEqual(missing, [], "A broken locale path can prevent the addon from loading")

    def test_all_lua_files_compile_under_lua51(self):
        lua: Any = LuaRuntime(unpack_returned_tuples=True)
        compile_chunk = lua.eval("function(code, name) return loadstring(code, name) end")
        errors = []
        for folder in ("budsUI", "budsUI_Config", "tests"):
            for path in (ROOT / folder).rglob("*.lua"):
                result = compile_chunk(source(path), str(path.relative_to(ROOT)))
                if isinstance(result, tuple) and result[0] is None:
                    errors.append(result[1])
        self.assertEqual(errors, [])

    def test_russian_locale_covers_all_english_keys(self):
        for folder in ("budsUI/Locales", "budsUI_Config/Locales"):
            with self.subTest(folder=folder):
                def keys(name):
                    return set(re.findall(r"(?m)^\s*(L_[A-Za-z0-9_]+)\s*=", source(ROOT / folder / name)))
                self.assertEqual(keys("enUS.lua") - keys("ruRU.lua"), set())

    def test_russian_format_placeholders_keep_argument_types(self):
        for folder in ("budsUI/Locales", "budsUI_Config/Locales"):
            with self.subTest(folder=folder):
                lua: Any = LuaRuntime(unpack_returned_tuples=True)
                lua.execute(source(ROOT / "tests/wow_stub.lua"))
                engine = lua.globals().Engine
                ns = lua.globals().configNS
                is_config = folder.startswith("budsUI_Config")
                lua.execute(source(ROOT / folder / "enUS.lua"), "budsUI_Config" if is_config else "budsUI", ns if is_config else engine)
                english = {key: value for key, value in lua.globals().items()
                           if isinstance(key, str) and key.startswith("L_") and isinstance(value, str)}
                lua.globals().Test.locale = "ruRU"
                lua.execute(source(ROOT / folder / "ruRU.lua"), "budsUI_Config" if is_config else "budsUI", ns if is_config else engine)
                pattern = r"%(?:[-+ #0]*)(?:\d+)?(?:\.\d+)?([cdiouxXeEfgGqs%])"
                def formats(value):
                    return re.findall(pattern, value.replace("%%", ""))
                for key, text in english.items():
                    value = lua.globals()[key]
                    if isinstance(value, str):
                        self.assertEqual(formats(text), formats(value), key)

    def test_ru_locale_does_not_override_english_client(self):
        lua: Any = LuaRuntime(unpack_returned_tuples=True)
        lua.execute(source(ROOT / "tests/wow_stub.lua"))
        lua.execute(source(ROOT / "budsUI/Locales/enUS.lua"), "budsUI", lua.globals().Engine)
        lua.execute(source(ROOT / "budsUI/Locales/ruRU.lua"), "budsUI", lua.globals().Engine)
        self.assertEqual(lua.globals().L_CHAT_COPY, "Copy Chat")
        lua.execute(source(ROOT / "budsUI_Config/Locales/enUS.lua"), "budsUI_Config", lua.globals().configNS)
        lua.execute(source(ROOT / "budsUI_Config/Locales/ruRU.lua"), "budsUI_Config", lua.globals().configNS)
        self.assertEqual(lua.globals().L_GUI_PROFILES, "Profiles")

    def test_config_rows_translate_static_captions_without_changing_values(self):
        lua: Any = LuaRuntime(unpack_returned_tuples=True)
        lua.execute(source(ROOT / "tests/wow_stub.lua"))
        lua.execute("Test.locale = 'ruRU'")
        lua.execute(source(ROOT / "budsUI_Config/Locales/enUS.lua"), "budsUI_Config", lua.globals().configNS)
        lua.execute(source(ROOT / "budsUI_Config/Locales/ruRU.lua"), "budsUI_Config", lua.globals().configNS)
        lua.execute(source(ROOT / "budsUI_Config/Controls.lua"), "budsUI_Config", lua.globals().configNS)
        lua.execute("""
            FrameForLocaleTest = CreateFrame('Frame')
            function FrameForLocaleTest:GetStringHeight() return 12 end
            local oldCreateFontString = FrameForLocaleTest.CreateFontString
            function FrameForLocaleTest:CreateFontString(...)
                local text = oldCreateFontString(self, ...)
                function text:GetStringHeight() return 12 end
                return text
            end
            Test.localizedHeader = configNS.creators.header(FrameForLocaleTest, {header = 'General'})
            Test.option = {label = 'Mana', values = {{'Mana', 'Mana'}, {'None', 'None'}}}
            Test.entry = {label = 'General', type = 'execute', noReset = true, func = function() end}
            Test.localizedRow = configNS.CreateRow(FrameForLocaleTest, Test.entry)
            Test.userEntry = {label = 'General', userContent = true, noReset = true}
            Test.userRow = configNS.CreateRow(FrameForLocaleTest, Test.userEntry)
        """)
        self.assertEqual(lua.globals().Test.localizedHeader.label.GetText(lua.globals().Test.localizedHeader.label), "Общее")
        self.assertEqual(lua.globals().Test.localizedRow.label.GetText(lua.globals().Test.localizedRow.label), "Общее")
        self.assertEqual(lua.globals().Test.userRow.label.GetText(lua.globals().Test.userRow.label), "General")
        self.assertEqual(lua.globals().Test.option["values"][1][1], "Mana")

    def test_manifest_loads_russian_before_runtime_consumers(self):
        # Use the actual manifest order, not the smoke test's explicit load order.
        lua: Any = LuaRuntime(unpack_returned_tuples=True)
        lua.execute(source(ROOT / "tests/wow_stub.lua"))
        lua.globals().Test.locale = "ruRU"
        loaded = []
        for item in manifest_files(ROOT / "budsUI/budsUI.xml"):
            if item.parent.name == "Locales":
                lua.execute(source(item), "budsUI", lua.globals().Engine)
                loaded.append(item.name)
            elif item.name == "Settings.lua":
                break
        self.assertEqual(loaded, ["enUS.lua", "ruRU.lua"])
        self.assertEqual(lua.globals().L_CHAT_COPY, "Копировать чат")
        self.assertEqual(lua.globals().L_SPELLBOOK_SEARCH, "Поиск")


if __name__ == "__main__":
    unittest.main()
