local Theme = {}

Theme.outline = {0, 0, 0, 1}

Theme.level = {
    background = {69 / 255, 89 / 255, 105 / 255, 1},
    outer = {32 / 255, 38 / 255, 45 / 255, 1},
    solid = {164 / 255, 171 / 255, 172 / 255, 1},
    grid = {45 / 255, 66 / 255, 86 / 255, 0.15},
}

Theme.decorations = {
    dark = {0.075, 0.075, 0.085, 1},
    outline = {35 / 255, 52 / 255, 70 / 255, 1},
    panel = {0.90, 0.90, 0.93, 1},
    background = {69 / 255, 89 / 255, 105 / 255, 1},
    metal = {96 / 255, 118 / 255, 134 / 255, 1},
    grill = {72 / 255, 91 / 255, 104 / 255, 1},
    fanFill = {0.88, 0.88, 0.92, 1},
    pipe = {70 / 255, 82 / 255, 96 / 255, 1},
    signShadow = {0, 0, 0, 0.3},
    signText = {0.1, 0.1, 0.1, 1},
}

Theme.player = {
    fill = {236 / 255, 247 / 255, 255 / 255, 1},
    outline = Theme.outline,
}

Theme.cube = {
    fill = {0.95, 0.95, 0.98, 1},
        bolt = {96 / 255, 118 / 255, 134 / 255, 1},
        seam = {0.075, 0.075, 0.085, 1},
    outline = Theme.outline,
}

Theme.door = {
	frame = {0.80, 0.84, 0.86, 1},
	doorFill = {68/255, 83/255, 97/255, 1},
}

Theme.saw = {
    track = Theme.outline,
    bladeFill = {0.85, 0.80, 0.75, 1},
    bladeHighlight = {1, 1, 1, 0.10},
    rim = Theme.outline,
    center = Theme.outline,
}

Theme.pressurePlate = {
    outline = Theme.outline,
    button = {0.94, 0.33, 0.33, 1},
    buttonGlow = {1, 0.8, 0.8, 0.3},
    base = {0.20, 0.20, 0.22, 1},
}

return Theme
