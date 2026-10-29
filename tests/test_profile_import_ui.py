"""The Profiles import row must keep its Import button inside the config window."""
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
from test_config_localization import boot, load_pages

ROOT = Path(__file__).resolve().parents[1]


class ImportRowTests(unittest.TestCase):
    def build_import_row(self):
        lua = boot()
        load_pages(lua)
        lua.execute("""
            for _, page in ipairs(configNS.pages) do
                if page.key == 'Profiles' then
                    for _, entry in ipairs(page.schema) do
                        if entry.type == 'custom' then
                            Test.importRow = configNS.creators.custom(UIParent, entry)
                        end
                    end
                end
            end
            assert(Test.importRow, 'Profiles page must have the import row')
            Test.hasButton = (Test.importRow.importButton ~= nil)
            Test.rowHeight = Test.importRow:GetHeight()
            if Test.hasButton then
                Test.boxAnchors = {}
                for i = 1, #Test.importRow.ioBox.points do
                    local p = Test.importRow.ioBox.points[i]
                    Test.boxAnchors[i] = p[1] .. ' ' .. p[3] .. ' ' .. p[4] .. ' ' .. p[5]
                end
                local bp = Test.importRow.importButton.points[1]
                Test.buttonAnchor = bp[1] .. ' ' .. bp[3] .. ' ' .. bp[4] .. ' ' .. bp[5]
            end
        """)
        return lua

    def test_import_button_is_created_below_the_paste_box_inside_the_row(self):
        lua = self.build_import_row()
        g = lua.globals()
        self.assertTrue(g.Test.hasButton, "the Import button must exist on the import row")
        # Row content area is 550 px wide; the paste box must anchor to the row's
        # right edge instead of a fixed width that pushes the button off-screen.
        self.assertIn("TOPRIGHT TOPRIGHT -6 -3", list(g.Test.boxAnchors.values()))
        self.assertEqual(g.Test.buttonAnchor, "TOPRIGHT BOTTOMRIGHT 0 -4")
        self.assertEqual(g.Test.rowHeight, 104)

    def test_button_click_imports_pasted_profile_text(self):
        lua = self.build_import_row()
        lua.execute("""
            K.ImportProfile = function(name, data)
                Test.importName = name
                Test.importData = data
                budsUIData.Profiles[name] = {}
                return true
            end
            K.SetProfile = function(name) Test.setProfile = name end
            Test.reloads = 0
            Test.importRow.ioBox:SetText('  BUDS1:abc  ')
            Test.importRow.importButton:Click()
        """)
        g = lua.globals()
        self.assertEqual(g.Test.importName, "Default (Import)")
        self.assertEqual(g.Test.importData, "BUDS1:abc")
        self.assertEqual(g.Test.setProfile, "Default (Import)")
        self.assertEqual(g.Test.reloads, 1)

    def test_blank_paste_does_nothing(self):
        lua = self.build_import_row()
        lua.execute("""
            K.ImportProfile = function() error('must not be called for blank input') end
            Test.importRow.ioBox:SetText('   ')
            Test.importRow.importButton:Click()
            Test.survived = true
        """)
        self.assertTrue(lua.globals().Test.survived)


if __name__ == "__main__":
    unittest.main()
