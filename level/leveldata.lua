local LevelData = {
    tileSize = 48,
}

LevelData.chambers = {
    require("level.chambers.test_chamber_1"),
    require("level.chambers.test_chamber_2"),
}

return LevelData
