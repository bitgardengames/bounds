local LevelData = {
    tileSize = 48,
}

LevelData.chambers = {
    require("level.chambers.test_chamber_1"),
    require("level.chambers.test_chamber_2"),
    require("level.chambers.test_chamber_3"),
}

return LevelData