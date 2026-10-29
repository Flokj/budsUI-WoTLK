"""Regression tests for budsUI ports, executed in a real Lua 5.1 runtime.

Run: python -m unittest discover -s tests -v
Only WoW's client API is stubbed; the addon event handlers, border helper,
chat-link wrappers, locales and configuration writes are real production code.
"""
from pathlib import Path
from typing import Any
import unittest

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]


class AddonRuntime:
    def __init__(self, *, locale="enUS", chat=True, enabled=True):
        self.lua: Any = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute((ROOT / "tests/wow_stub.lua").read_text(encoding="utf-8-sig"))
        self.lua.globals().Test.locale = locale
        self.lua.globals().C.Chat.Enable = chat
        self.lua.globals().C.Misc.DeathRecap = enabled

    def load(self, path, *, config=False):
        code = (ROOT / path).read_text(encoding="utf-8-sig")
        self.lua.execute(code, "budsUI_Config" if config else "budsUI-0.7.1",
                         self.lua.globals().configNS if config else self.lua.globals().Engine)

    def boot_recap(self, *, wrappers=True):
        self.load("budsUI/Locales/enUS.lua")
        ru = ROOT / "budsUI/Locales/ruRU.lua"
        if ru.exists():
            self.load("budsUI/Locales/ruRU.lua")
        self.load("budsUI/Core/Border.lua")
        self.load("budsUI/Modules/Misc/DeathRecap.lua")
        if wrappers:
            self.load("budsUI/Modules/Chat/CopyUrl.lua")
            self.load("budsUI/Modules/Tooltip/MultiItemRef.lua")
        self.lua.eval("Fire")("PLAYER_LOGIN")
        self.lua.eval("Fire")("PLAYER_ENTERING_WORLD")

    def damage(self, *, caster_flag=None, dest=None, amount=3000, subevent="SPELL_DAMAGE"):
        """3.3.5 CLEU fixture, optionally with the boolean hideCaster slot."""
        g = self.lua.globals()
        header = [g.Test.now, subevent]
        if caster_flag is not None:
            header.append(caster_flag)
        header.extend(["0x0000000000000002", "Enemy", 0x540,
                       dest or g.Test.playerGUID, "Player", 0x511])
        if subevent == "SWING_DAMAGE":
            payload = [amount, 0, 1, 0, 0, 0, False, False, False]
        elif subevent == "ENVIRONMENTAL_DAMAGE":
            payload = ["FALLING", amount, 0, 1, 0, 0, 0, False]
        else:
            payload = [133, "Fireball", 4, amount, 0, 4, 0, 0, 0, False, False, False]
        self.lua.eval("Fire")("COMBAT_LOG_EVENT_UNFILTERED", *(header + payload))

    def kill(self):
        self.lua.globals().Test.health = 0
        self.lua.eval("Fire")("PLAYER_DEAD")


class DeathRecapTests(unittest.TestCase):
    def test_url_popup_uses_global_handler_without_touching_chat_draft(self):
        rt = AddonRuntime()
        rt.boot_recap()
        rt.lua.globals().SetItemRef("url:https://example.com", "[URL]", "LeftButton", rt.lua.globals().ChatFrame1)
        self.assertEqual(rt.lua.globals().Test.lastPopupKey, "BUDSUI_COPY_URL")
        self.assertEqual(rt.lua.globals().TestPopupEditBox.GetText(rt.lua.globals().TestPopupEditBox), "https://example.com")
        self.assertEqual(rt.lua.globals().Test.refCalls, 0)

    def test_native_cleu_damage_produces_chat_link(self):
        # Catches prepending frame/event to a handler that expects the CLEU tuple.
        rt = AddonRuntime()
        rt.boot_recap()
        rt.damage()
        rt.kill()
        messages = list(rt.lua.globals().Test.messages.values())
        self.assertEqual(len(messages), 1, "Player death must print one recap link")
        self.assertIn("|Hbudsrecap:1|h", messages[0])
        frame = rt.lua.globals().budsUI_DeathRecap
        self.assertIsNotNone(frame, "PvP auto-open must show a recorded death")
        self.assertTrue(frame.IsShown(frame))
        self.assertEqual(frame.entries[1].amount, 3000)
        self.assertEqual(frame.entries[1].source, "Enemy")
        self.assertEqual(frame.entries[1].spellId, 133)

    def test_death_message_prints_the_addon_prefix_only_once(self):
        # K.Print already prefixes "budsUI:"; the recap line must not embed a second one.
        rt = AddonRuntime()
        rt.boot_recap()
        rt.damage()
        rt.kill()
        messages = list(rt.lua.globals().Test.messages.values())
        self.assertEqual(len(messages), 1)
        self.assertEqual(messages[0].count("budsUI"), 1, messages[0])

    def test_hidecaster_cleu_damage_has_correct_fields(self):
        rt = AddonRuntime()
        rt.boot_recap()
        rt.damage(caster_flag=False)
        rt.kill()
        frame = rt.lua.globals().budsUI_DeathRecap
        self.assertIsNotNone(frame, "The hideCaster tuple must also record player damage")
        self.assertEqual(frame.entries[1].amount, 3000)
        self.assertEqual(frame.entries[1].school, 4)

    def test_swing_and_environmental_damage_are_recorded(self):
        rt = AddonRuntime()
        rt.boot_recap()
        rt.damage(subevent="SWING_DAMAGE", amount=1400)
        rt.lua.globals().Test.now = 100.5
        rt.damage(subevent="ENVIRONMENTAL_DAMAGE", amount=4200, caster_flag=True)
        rt.kill()
        frame = rt.lua.globals().budsUI_DeathRecap
        self.assertIsNotNone(frame)
        self.assertEqual(len(frame.entries), 2)
        self.assertEqual(frame.entries[1].environment, "FALLING")
        self.assertEqual(frame.entries[2].spellId, 6603)

    def test_other_players_damage_does_not_make_a_recap(self):
        rt = AddonRuntime()
        rt.boot_recap()
        rt.damage(dest="0x0000000000000003")
        rt.kill()
        self.assertEqual(len(rt.lua.globals().Test.messages), 0)
        self.assertIsNone(rt.lua.globals().budsUI_DeathRecap)

    def test_empty_window_has_dark_background_after_real_border_helper(self):
        rt = AddonRuntime()
        rt.boot_recap()
        rt.lua.globals().K.OpenDeathRecap()
        frame = rt.lua.globals().budsUI_DeathRecap
        color = frame.GetBackdropColor(frame)
        self.assertLess(color[0], 0.1, "CreateBorder must not reset the backdrop to white")
        self.assertAlmostEqual(color[3], 0.9)
        self.assertIsNotNone(frame.BorderTextures)

    def test_recap_link_opens_exact_id_through_existing_tooltip_wrapper(self):
        # Prefix length must not include the first digit of the recap ID.
        rt = AddonRuntime()
        rt.boot_recap()
        rt.lua.execute("K.OpenDeathRecap = function(id) Test.openedId = id end")
        rt.lua.globals().SetItemRef("budsrecap:17", "[Death recap]", "LeftButton", rt.lua.globals().ChatFrame1)
        self.assertEqual(rt.lua.globals().Test.openedId, 17)
        self.assertEqual(rt.lua.globals().Test.refCalls, 0)

    def test_direct_tooltip_recap_link_opens_exact_id(self):
        rt = AddonRuntime()
        rt.boot_recap()
        rt.lua.execute("K.OpenDeathRecap = function(id) Test.openedId = id end")
        tooltip = rt.lua.globals().ItemRefTooltip
        tooltip.SetHyperlink(tooltip, "budsrecap:8")
        self.assertEqual(rt.lua.globals().Test.openedId, 8)
        self.assertIsNone(tooltip.lastLink)

    def test_chat_disabled_does_not_disable_recap_link(self):
        rt = AddonRuntime(chat=False)
        rt.boot_recap()
        rt.lua.execute("K.OpenDeathRecap = function(id) Test.openedId = id end")
        rt.lua.globals().SetItemRef("budsrecap:12", "[Death recap]", "LeftButton", rt.lua.globals().ChatFrame1)
        self.assertEqual(rt.lua.globals().Test.openedId, 12)

    def test_normal_links_are_forwarded_without_losing_arguments(self):
        rt = AddonRuntime()
        rt.boot_recap(wrappers=False)
        result = rt.lua.globals().SetItemRef("item:123", "[Item]", "RightButton", rt.lua.globals().ChatFrame1)
        self.assertEqual(result, "standard-ref")
        self.assertEqual(rt.lua.globals().Test.refArgs[1], "item:123")
        self.assertEqual(rt.lua.globals().Test.refArgs[3], "RightButton")

    def test_invalid_recap_link_does_not_open_unrelated_last_death(self):
        rt = AddonRuntime()
        rt.boot_recap()
        rt.lua.execute("K.OpenDeathRecap = function(id) Test.openedId = id or -1 end")
        rt.lua.globals().SetItemRef("budsrecap:abc", "[Death recap]", "LeftButton", rt.lua.globals().ChatFrame1)
        self.assertIsNone(rt.lua.globals().Test.openedId)
        self.assertEqual(rt.lua.globals().Test.refCalls, 0)

    def test_disabled_recap_does_not_subscribe_to_combat_log(self):
        rt = AddonRuntime(enabled=False)
        rt.boot_recap(wrappers=False)
        frames = rt.lua.globals().Test.frames
        subscribed = [f for f in frames.values() if f.IsEventRegistered(f, "COMBAT_LOG_EVENT_UNFILTERED")]
        self.assertEqual(subscribed, [], "A disabled module must not process every CLEU event")

    def test_config_toggle_unregisters_recording_and_restores_it(self):
        rt = AddonRuntime()
        rt.boot_recap(wrappers=False)
        rt.load("budsUI_Config/Controls.lua", config=True)
        rt.load("budsUI_Config/Pages/Misc.lua", config=True)
        rt.lua.execute("""
            local page = configNS.pages[#configNS.pages]
            for _, entry in ipairs(page.schema) do
                if entry.group == "Misc" and entry.option == "DeathRecap" then
                    configNS.Set(entry, false)
                end
            end
        """)
        subscribed = [f for f in rt.lua.globals().Test.frames.values()
                      if f.IsEventRegistered(f, "COMBAT_LOG_EVENT_UNFILTERED")]
        self.assertEqual(subscribed, [])
        rt.lua.execute("""
            for _, entry in ipairs(configNS.pages[#configNS.pages].schema) do
                if entry.group == "Misc" and entry.option == "DeathRecap" then
                    configNS.Set(entry, true)
                end
            end
        """)
        rt.damage()
        rt.kill()
        self.assertEqual(len(rt.lua.globals().Test.messages), 1)

    def test_heals_without_overhealing_and_recent_burst_are_kept(self):
        rt = AddonRuntime()
        rt.boot_recap()
        rt.damage(amount=1200)
        rt.lua.globals().Test.now = 100.4
        rt.lua.eval("Fire")("COMBAT_LOG_EVENT_UNFILTERED", 100.4, "SPELL_HEAL",
                            "0x0000000000000004", "Healer", 0x511,
                            rt.lua.globals().Test.playerGUID, "Player", 0x511,
                            2061, "Flash Heal", 2, 1500, 500, 0, False)
        rt.lua.globals().Test.now = 100.8
        rt.damage(amount=2800)
        rt.kill()
        frame = rt.lua.globals().budsUI_DeathRecap
        self.assertIsNotNone(frame)
        self.assertEqual(len(frame.entries), 3)
        self.assertEqual(frame.entries[2].kind, "heal")
        self.assertEqual(frame.entries[2].amount, 1000)
        self.assertEqual(frame.killIndex, 1)
        self.assertIn("4.0k", frame.title.GetText(frame.title))

    def test_second_death_does_not_reuse_first_deaths_hits(self):
        rt = AddonRuntime()
        rt.boot_recap()
        rt.damage()
        rt.kill()
        rt.lua.globals().Test.now = 120
        rt.damage(amount=900)
        rt.kill()
        frame = rt.lua.globals().budsUI_DeathRecap
        self.assertIsNotNone(frame)
        self.assertEqual(len(frame.entries), 1)
        self.assertEqual(frame.entries[1].amount, 900)
        self.assertIn("|Hbudsrecap:2|h", rt.lua.globals().Test.messages[2])

    def test_ru_environment_and_damage_school_are_translated(self):
        rt = AddonRuntime(locale="ruRU")
        rt.boot_recap()
        rt.damage(subevent="ENVIRONMENTAL_DAMAGE", amount=4000)
        rt.kill()
        frame = rt.lua.globals().budsUI_DeathRecap
        self.assertEqual(frame.entries[1].name, "Падение")
        row = frame.rows[1]
        row.GetScript(row, "OnEnter")(row)
        lines = list(rt.lua.globals().GameTooltip.lines.values())
        self.assertIn("Физический", lines[0][1])

    def test_ru_death_recap_window_and_message_are_translated(self):
        rt = AddonRuntime(locale="ruRU")
        rt.boot_recap()
        rt.damage()
        rt.kill()
        messages = list(rt.lua.globals().Test.messages.values())
        self.assertEqual(len(messages), 1)
        self.assertIn("Причина смерти", messages[0])
        self.assertIn("Причина смерти", rt.lua.globals().budsUI_DeathRecap.title.GetText(rt.lua.globals().budsUI_DeathRecap.title))


if __name__ == "__main__":
    unittest.main()
