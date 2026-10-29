"""URLs must stay clickable no matter where in the chat message they appear."""
from pathlib import Path
import unittest

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]


def boot_with_copy_url():
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute((ROOT / "tests/wow_stub.lua").read_text(encoding="utf-8-sig"))
    for name in ("budsUI/Locales/enUS.lua", "budsUI/Locales/ruRU.lua", "budsUI/Core/Border.lua"):
        lua.execute((ROOT / name).read_text(encoding="utf-8-sig"), "budsUI", lua.globals().Engine)
    lua.execute((ROOT / "budsUI/Modules/Chat/CopyUrl.lua").read_text(encoding="utf-8-sig"),
                "budsUI-0.7.1", lua.globals().Engine)
    return lua


def channel_filter(lua, message):
    lua.globals().Test.filterInput = message
    lua.execute("""
        local f = Test.chatFilters and Test.chatFilters.CHAT_MSG_CHANNEL
        Test.filterOutput = nil
        if f then
            local _, newMsg = f[1](ChatFrame1, "CHAT_MSG_CHANNEL", Test.filterInput, 7)
            Test.filterOutput = newMsg
        end
    """)
    return lua.globals().Test.filterOutput


class ChatLinkTests(unittest.TestCase):
    def test_url_that_is_the_whole_message_is_wrapped(self):
        # A pasted discord invite is usually the entire message; the URL must
        # still be wrapped and clickable when it starts at position 1.
        lua = boot_with_copy_url()
        for message in ("https://discord.gg/inviteXYZ", "discord.gg/inviteXYZ", "www.example.com/test"):
            with self.subTest(message=message):
                result = channel_filter(lua, message)
                self.assertIsNotNone(result, "whole-message URL stayed plain text")
                self.assertIn("|Hurl:" + message + "|h", result)

    def test_url_mid_sentence_is_wrapped(self):
        lua = boot_with_copy_url()
        for message in ("заходи на discord.gg/inviteXYZ брат", "смори https://discord.gg/x тут"):
            with self.subTest(message=message):
                result = channel_filter(lua, message)
                self.assertIsNotNone(result)
                self.assertIn("|Hurl:", result)

    def test_existing_hyperlinks_are_not_corrupted(self):
        lua = boot_with_copy_url()
        result = channel_filter(lua, "|Hitem:123|h[Sword]|h продаю, discord.gg/xyz")
        self.assertIsNotNone(result)
        self.assertIn("|Hitem:123|h[Sword]|h", result)
        self.assertIn("|Hurl:discord.gg/xyz|h", result)

    def test_plain_text_is_untouched(self):
        lua = boot_with_copy_url()
        self.assertIsNone(channel_filter(lua, "привет как дела"))
        self.assertIsNone(channel_filter(lua, "встреча в 12.5"))


if __name__ == "__main__":
    unittest.main()
