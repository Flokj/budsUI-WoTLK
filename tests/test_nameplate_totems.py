"""Totem nameplate icons (FrostAtomUI Totems port): identify -> icon mode.

The stub's GetSpellInfo returns "Spell <id>", so byName/byEntry tables are
keyed by those synthetic names; tests identify totems through them.
"""
from pathlib import Path
import unittest

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]

PRELUDE = """
C.Nameplate = {
	Enable = true,
	TotemIcons = true, TotemFilter = "important", TotemIconSize = 24,
	TotemTimer = true, TotemPulse = true, TotemPulseHeight = 4,
	TotemPulseColor = { 0.3, 0.75, 1 },
}
C.Media.Blank = "Blank"
COMBATLOG_OBJECT_REACTION_HOSTILE = 64
UnitName = function(unit) return Test.unitNames and Test.unitNames[unit] or nil end
Test.hitRectCalls = {}
Test.mouseover = false
K.NameplateHitRect_Update = nil
"""

PLATE = """
local plate = CreateFrame("Frame")
plate.width, plate.height = 120, 40
local hp = CreateFrame("Frame")
hp.oldname = hp:CreateFontString()
hp.oldname:SetText(Test.plateName)
plate.hp = hp
plate.overlay = CreateFrame("Frame")
plate.cb = CreateFrame("Frame")
Test.plate = plate
K.NameplateTotems_Setup(plate)
"""


def boot():
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute((ROOT / "tests/wow_stub.lua").read_text(encoding="utf-8-sig"))
    lua.execute(PRELUDE)
    for rel in ("budsUI/Modules/Blizzard/NameplateTotemData.lua",
                "budsUI/Modules/Blizzard/NameplateTotems.lua"):
        code = (ROOT / rel).read_text(encoding="utf-8-sig")
        lua.execute(code, "budsUI-0.7.1", lua.globals().Engine)
    # The click-zone recorder: the real secure module lives outside the harness.
    lua.execute("""
        K.NameplateHitRect_Update = function(plate, w, h, hidden)
            Test.hitRectCalls[#Test.hitRectCalls + 1] = { plate = plate, w = w, h = h, hidden = hidden }
        end
    """)
    return lua


def make_plate(lua, name):
    lua.globals().Test.plateName = name
    lua.execute(PLATE)


class TotemDataTests(unittest.TestCase):
    def setUp(self):
        self.lua = boot()

    def test_spell_table_maps_entry_name_and_icon(self):
        self.assertEqual(self.lua.execute("return K.NameplateTotemData.byEntry[2523]"), 3599)
        self.assertEqual(self.lua.execute('return K.NameplateTotemData.byName["Spell 3599"]'), 3599)
        self.assertEqual(self.lua.execute('return K.NameplateTotemData.spells[3599].icon'), "Icon 3599")
        self.assertEqual(self.lua.execute("return K.NameplateTotemData.spells[3599].duration"), 30)

    def test_important_filter_matches_only_key_totems(self):
        self.assertTrue(self.lua.execute("return K.NameplateTotemData.IsImportant(2484)"))  # Earthbind
        self.assertTrue(self.lua.execute("return K.NameplateTotemData.IsImportant(16190)"))  # Mana Tide
        self.assertFalse(self.lua.execute("return K.NameplateTotemData.IsImportant(3599)"))  # Searing

    def test_pulse_data_registers_tick_spells(self):
        self.assertEqual(self.lua.execute("return K.NameplateTotemData.spells[8190].pulse.period"), 2)
        self.assertTrue(self.lua.execute("return K.NameplateTotemData.tickSpells[8187]"))
        self.assertFalse(self.lua.execute("return K.NameplateTotemData.tickSpells[999999] and true"))


class TotemIconModeTests(unittest.TestCase):
    def setUp(self):
        self.lua = boot()

    def test_identified_totem_replaces_plate_with_clickable_icon(self):
        make_plate(self.lua, "Spell 2484")  # Earthbind Totem, important
        self.lua.execute("K.NameplateTotems_Update(Test.plate)")
        self.assertEqual(self.lua.execute("return Test.plate.totem.shown"), True)
        self.assertEqual(self.lua.execute("return Test.plate.hp.alpha"), 0)
        self.assertEqual(self.lua.execute("return Test.plate.totem.icon.texture"), "Icon 2484")
        # Stock hover highlight is neutralized: empty texture, hidden.
        self.assertEqual(self.lua.execute("return Test.plate.overlay.texture"), "")
        self.assertEqual(self.lua.execute("return Test.plate.overlay.shown"), False)
        # Icon-sized clickable zone with slack: 24 + inset*2 + hitPadding*2.
        self.assertEqual(self.lua.execute("return Test.hitRectCalls[#Test.hitRectCalls].w"), 38)
        self.assertEqual(self.lua.execute("return Test.hitRectCalls[#Test.hitRectCalls].h"), 38)
        self.assertEqual(self.lua.execute("return Test.hitRectCalls[#Test.hitRectCalls].hidden"), False)

    def test_important_filter_conceals_unimportant_totem_entirely(self):
        make_plate(self.lua, "Spell 3599")  # Searing Totem, not important
        self.lua.execute("K.NameplateTotems_Update(Test.plate)")
        self.assertEqual(self.lua.execute("return Test.plate.totemConcealed"), True)
        self.assertEqual(self.lua.execute("return Test.plate.totem.shown"), False)
        # The plate UI itself is hidden too (no stuck bars from filtered totems).
        self.assertEqual(self.lua.execute("return Test.plate.hp.alpha"), 0)
        self.assertEqual(self.lua.execute("return Test.hitRectCalls[#Test.hitRectCalls].hidden"), True)
        # Switching the filter to "all" brings the icon back and un-zeros the zone.
        self.lua.execute('C.Nameplate.TotemFilter = "all"')
        self.lua.execute("K.NameplateTotems_Update(Test.plate)")
        self.assertEqual(self.lua.execute("return Test.plate.totemConcealed"), None)
        self.assertEqual(self.lua.execute("return Test.plate.totem.shown"), True)
        self.assertEqual(self.lua.execute("return Test.plate.hp.alpha"), 0)  # icon mode
        self.assertEqual(self.lua.execute("return Test.hitRectCalls[#Test.hitRectCalls].hidden"), False)

    def test_master_toggle_off_restores_the_full_plate(self):
        make_plate(self.lua, "Spell 2484")
        self.lua.execute("K.NameplateTotems_Update(Test.plate)")
        self.lua.execute("C.Nameplate.TotemIcons = false")
        self.lua.execute("K.NameplateTotems_Update(Test.plate)")
        self.assertEqual(self.lua.execute("return Test.plate.hp.alpha"), 1)
        self.assertEqual(self.lua.execute("return Test.plate.totem.shown"), False)
        # The stock hover highlight comes back with the plate.
        self.assertEqual(self.lua.execute("return Test.plate.overlay.texture"), 1)
        # The stock 120x40 click zone comes back.
        self.assertEqual(self.lua.execute("return Test.hitRectCalls[#Test.hitRectCalls].w"), 120)
        self.assertEqual(self.lua.execute("return Test.hitRectCalls[#Test.hitRectCalls].h"), 40)
        self.assertEqual(self.lua.execute("return Test.hitRectCalls[#Test.hitRectCalls].hidden"), False)

    def test_non_totem_plate_stays_a_regular_nameplate(self):
        make_plate(self.lua, "Spell 9999999")
        self.lua.execute("K.NameplateTotems_Update(Test.plate)")
        self.assertEqual(self.lua.execute("return Test.plate.totem.shown"), False)
        self.assertEqual(self.lua.execute("return Test.plate.hp.alpha"), None)
        self.assertEqual(self.lua.execute("return #Test.hitRectCalls"), 0)

    def test_target_gets_the_1_2x_bump(self):
        make_plate(self.lua, "Spell 2484")
        self.lua.execute("Test.unitNames = { target = 'Spell 2484' }")
        self.lua.execute("K.NameplateTotems_Update(Test.plate)")
        width = self.lua.execute("return Test.hitRectCalls[#Test.hitRectCalls].w")
        self.assertAlmostEqual(width, 24 * 1.2 + 14, places=6)
        self.lua.execute("K.NameplateTotems_Update(Test.plate)")
        # Second pass runs with the debounced target state already set.
        self.assertAlmostEqual(self.lua.execute("return Test.plate.totem.iconSize"), 24 * 1.2, places=6)

    def test_combat_log_summon_binds_timer_and_destroy_releases(self):
        make_plate(self.lua, "Spell 2484")
        self.lua.execute("""
            Fire("COMBAT_LOG_EVENT_UNFILTERED", 0, "SPELL_SUMMON",
                "0x01000000000001", "Caster", 0xA48, "0xF130000002DA0", "Spell 2484", 64, 2484)
        """)
        # refreshNamed runs on summon: the plate flipped to icon mode with the timer bound.
        self.assertEqual(self.lua.execute("return Test.plate.totem.shown"), True)
        self.assertEqual(self.lua.execute("return Test.plate.totem.timer.shown"), True)
        self.assertEqual(self.lua.execute("return Test.plate.totemSummon"), "0xF130000002DA0")
        self.lua.execute("""
            Fire("COMBAT_LOG_EVENT_UNFILTERED", 0, "UNIT_DESTROYED",
                nil, nil, nil, "0xF130000002DA0", "Spell 2484", 64)
        """)
        self.assertEqual(self.lua.execute("return Test.plate.totem.timer.shown"), False)

    def test_visible_plate_reassigned_from_totem_restores_mob(self):
        for name, icon_shown in (("Spell 2484", True), ("Spell 3599", False)):
            with self.subTest(name=name):
                make_plate(self.lua, name)
                self.lua.execute("K.NameplateTotems_Update(Test.plate)")
                state = "return Test.plate.totem:IsShown(), Test.plate.hp.alpha"
                self.assertEqual(self.lua.execute(state), (icon_shown, 0))

                self.lua.execute('Test.plate.hp.oldname:SetText("Wolf")')
                self.lua.execute("K.NameplateTotems_Update(Test.plate)")  # No OnHide/OnShow.
                self.assertEqual(self.lua.execute(state), (False, 1))
                self.assertEqual(self.lua.execute("""
                    local hit = Test.hitRectCalls[#Test.hitRectCalls]
                    return hit.w, hit.h, hit.hidden
                """), (120, 40, False))

    def test_visible_plate_reassigned_to_another_totem_binds_its_timer(self):
        make_plate(self.lua, "Spell 2484")
        self.lua.execute("""
            Fire("COMBAT_LOG_EVENT_UNFILTERED", GetTime(), "SPELL_SUMMON",
                "CasterGUID", "Caster", 0, "earthbind", "Spell 2484", 64, 2484)
            Fire("COMBAT_LOG_EVENT_UNFILTERED", GetTime(), "SPELL_SUMMON",
                "CasterGUID", "Caster", 0, "mana-tide", "Spell 16190", 64, 16190)
        """)
        self.assertEqual(self.lua.eval("Test.plate.totemSummon"), "earthbind")

        self.lua.execute('Test.plate.hp.oldname:SetText("Spell 16190")')
        self.lua.execute("K.NameplateTotems_Update(Test.plate)")
        self.lua.execute("""
            Fire("COMBAT_LOG_EVENT_UNFILTERED", GetTime(), "UNIT_DESTROYED",
                nil, nil, nil, "earthbind", "Spell 2484", 64)
        """)
        self.assertEqual(self.lua.execute("""
            local p = Test.plate
            return p.totem.icon:GetTexture(), p.totemSummon, p.totem.timer:IsShown(), p.totem.pulse:IsShown()
        """), ("Icon 16190", "mana-tide", True, True))

    def test_visible_rename_ignores_guid_bound_to_previous_name(self):
        make_plate(self.lua, "Spell 2484")
        self.lua.execute("""
            local p = Test.plate
            p.guid, p.boundName = "0xF130000A46000001", "Spell 2484"
            K.NameplateTotems_Update(p)
            p.hp.oldname:SetText("Wolf")
            K.NameplateTotems_Update(p)
        """)
        self.assertEqual(self.lua.execute("return Test.plate.totem:IsShown(), Test.plate.hp.alpha"), (False, 1))

    def test_plate_hide_releases_the_claim_for_recycling(self):
        make_plate(self.lua, "Spell 2484")
        self.lua.execute("K.NameplateTotems_Update(Test.plate)")
        self.lua.execute("K.NameplateTotems_OnPlateHide(Test.plate)")
        self.assertEqual(self.lua.execute("return Test.plate.totemSpell"), None)
        self.assertEqual(self.lua.execute("return Test.plate.totem.shown"), False)
        # The full plate is skinned again for the recycled stock frame.
        self.assertEqual(self.lua.execute("return Test.plate.hp.alpha"), 1)

    def test_blacklisted_totem_never_shows_the_icon(self):
        make_plate(self.lua, "Spell 2484")
        self.lua.execute("K.NameplateTotems_Update(Test.plate)")
        self.lua.execute("Test.plate.hide = true")
        self.lua.execute("K.NameplateTotems_OnPlateHide(Test.plate); Test.plate.hide = nil")
        self.lua.execute("""
            Fire("COMBAT_LOG_EVENT_UNFILTERED", 0, "SPELL_SUMMON",
                "0x01000000000002", "Caster", 0xA48, "0xF130000002DA0", "Spell 2484", 64, 2484)
            K.NameplateTotems_OnBlacklisted(Test.plate)
        """)
        self.assertEqual(self.lua.execute("return Test.plate.totem.shown"), False)
        self.assertEqual(self.lua.execute("return Test.plate.totemConcealed"), True)


if __name__ == "__main__":
    unittest.main()
