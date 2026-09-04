local K, C, L, _ = select(2, ...):unpack()
local LSM = LibStub('LibSharedMedia-3.0')

if LSM == nil then return end

-- LSM Fonts
LSM:Register("border", "budsUI_Border", [[Interface\Tooltips\UI-Tooltip-Border]])
LSM:Register("border", "budsUI_GlowTex", [[Interface\AddOns\]] .. K.Directory .. [[\Media\Textures\GlowTex]])
LSM:Register("font", "budsUI_Damage", [[Interface\AddOns\]] .. K.Directory .. [[\Media\Fonts\Damage.ttf]])
LSM:Register("font", "budsUI_Normal", [[Interface\AddOns\]] .. K.Directory .. [[\Media\Fonts\Normal.ttf]])
LSM:Register("sound", "GameMaster_Whisper", [[Sound\Spells\Simongame_visual_gametick.wav]])
LSM:Register("sound", "budsUI_Whisper", [[Interface\AddOns\]] .. K.Directory .. [[\Media\Sounds\KWhisper.ogg]])
LSM:Register("sound", "Spell_Proc", [[Interface\AddOns\]] .. K.Directory .. [[\Media\Sounds\Proc.ogg]])
LSM:Register("statusbar", "budsUI_StatusBar", [[Interface\TargetingFrame\UI-StatusBar]])