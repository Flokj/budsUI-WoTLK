"""Print untranslated visible configuration phrases for translation maintenance."""
from pathlib import Path
from typing import Any
import re
from lupa.lua51 import LuaRuntime, lua_type

ROOT = Path(__file__).resolve().parents[1]
lua: Any = LuaRuntime(unpack_returned_tuples=True)
lua.execute((ROOT / "tests/wow_stub.lua").read_text(encoding="utf-8-sig"))
lua.execute((ROOT / "budsUI_Config/Locales/enUS.lua").read_text(encoding="utf-8-sig"))
lua.execute((ROOT / "budsUI_Config/Controls.lua").read_text(encoding="utf-8-sig"), "budsUI_Config", lua.globals()["configNS"])
for path in sorted((ROOT / "budsUI_Config/Pages").glob("*.lua")):
    try:
        lua.execute(path.read_text(encoding="utf-8-sig"), "budsUI_Config", lua.globals()["configNS"])
    except Exception as exc:
        print("Page load:", path.name, str(exc)[:200])
phrases = set()
fields = ("label", "name", "header", "description", "desc", "text", "confirm", "placeholder", "zeroText")

def visit(schema):
    if schema is None:
        return
    try:
        rows = schema() if lua_type(schema) == "function" else schema
    except Exception:
        return
    for row in rows.values():
        for field in fields:
            value = row[field]
            if isinstance(value, str) and re.search(r"[A-Za-z]", value):
                phrases.add(value)
        values = row["values"]
        if values is not None and lua_type(values) != "function":
            for value in values.values():
                if isinstance(value[2], str):
                    phrases.add(value[2])
for page in lua.globals()["configNS"]["pages"].values():
    if isinstance(page["name"], str):
        phrases.add(page["name"])
    visit(page["schema"])
    if page["tabs"]:
        for tab in page["tabs"].values():
            if isinstance(tab["name"], str):
                phrases.add(tab["name"])
            visit(tab["schema"])
print("Distinct phrases:", len(phrases))
for phrase in sorted(phrases):
    print(repr(phrase))
