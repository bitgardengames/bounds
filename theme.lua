local Theme = {}

--------------------------------------------------------------
-- OUTLINE / GLOBALS
--------------------------------------------------------------
Theme.outline = {0.04, 0.05, 0.07, 1}   -- deep navy outline
Theme.active = {0.98, 0.62, 0.10, 1}

--------------------------------------------------------------
-- LEVEL BACKGROUND + SOLIDS
--------------------------------------------------------------
Theme.level = {
    -- Background wall color (main panels)
    background = {0.14, 0.18, 0.22, 1},      -- dark slate blue

    -- Outer border / frame
    outer      = {0.10, 0.12, 0.15, 1},      -- slightly darker frame

    -- Solid platforms / floor (medium steel)
    solid      = {0.10, 0.12, 0.15, 1},
    platformTop= {0.25, 0.29, 0.33, 1},

    -- Grid / subtle overlays
    grid       = {0.18, 0.22, 0.28, 0.18}, -- 0.18
}

--------------------------------------------------------------
-- DECORATIONS
--------------------------------------------------------------
Theme.decorations = {
    dark     = {0.11, 0.14, 0.17, 1},
    outline  = {0.07, 0.08, 0.12, 1},

    panel    = {0.60, 0.68, 0.80, 1},       -- soft cool highlight panel
    background = {0.14, 0.18, 0.22, 1},

    metal     = {0.33, 0.39, 0.46, 1},      -- muted blue metal
    grill     = {0.23, 0.28, 0.34, 1},
    pipe      = {0.28, 0.32, 0.38, 1},
    conduit   = {0.42, 0.48, 0.56, 1},

    bracket   = {0.20, 0.25, 0.30, 1},

    fanFill   = {0.78, 0.84, 0.90, 1},

    signFill = {0.11, 0.14, 0.17, 1},
    signText = Theme.active,

	platformTop = {0.25, 0.29, 0.33, 1},

	timerColor = Theme.active,
	conduitEnabled = Theme.active,
	conduitDisabled = {0.18, 0.18, 0.18, 1},
}

--------------------------------------------------------------
-- PLAYER (Lumo)
--------------------------------------------------------------
Theme.player = {
    --fill    = {0.95, 0.97, 1.00, 1},         -- soft cool white
    fill    = {0.92, 0.94, 0.97, 1},         -- warm neutral white
    outline = Theme.outline,
}

--------------------------------------------------------------
-- MONITOR
--------------------------------------------------------------
Theme.monitor = {
    lens    = {0.92, 0.94, 0.97, 1},
    arm     = {0.23, 0.28, 0.34, 1},
    led     = {1, 0.25, 0.25, 1},
    mount   = {0.20, 0.20, 0.22, 1},
    body    = {0.23, 0.28, 0.34, 1},
    outline = Theme.decorations.outline,
}

--------------------------------------------------------------
-- CUBE
--------------------------------------------------------------
Theme.cube = {
    fill    = {94/255, 106/255, 120/255, 1},         -- very light blue-grey
    centerFill= {0.98, 0.62, 0.10, 1},         -- very light blue-grey
    outline = Theme.outline,
}

--------------------------------------------------------------
-- DOOR
--------------------------------------------------------------
Theme.door = {
    frame    = {0.33, 0.39, 0.46, 1},        -- steel frame
    --doorFill = {0.98, 0.62, 0.10, 1},        -- warm amber interior (EXIT)
    doorFill = {0.11, 0.14, 0.17, 1},        -- warm amber interior (EXIT)
	unlocked = Theme.active,
	locked = Theme.decorations.dark,
}

--------------------------------------------------------------
-- DROPTUBE
--------------------------------------------------------------
Theme.droptube = {
    topcap   = {0.18, 0.20, 0.24, 1},
    bottomcap= {0.24, 0.28, 0.33, 1},
    glass    = {0.40, 0.65, 0.88, 0.28},
    highlight= {1, 1, 1, 0.18},
}

--------------------------------------------------------------
-- SAW
--------------------------------------------------------------
Theme.saw = {
    track          = Theme.outline,
    bladeFill      = {0.82, 0.78, 0.75, 1},
    bladeHighlight = {1, 1, 1, 0.12},
    rim            = Theme.outline,
    center         = Theme.outline,
}

--------------------------------------------------------------
-- PRESSURE PLATE
--------------------------------------------------------------
Theme.pressurePlate = {
    outline     = Theme.outline,
    button      = Theme.active,
    buttonGlow  = Theme.active,
    base        = {0.14, 0.15, 0.18, 1},
}

--------------------------------------------------------------
-- STOOMP BUTTONS
--------------------------------------------------------------
Theme.buttons = {
    cap         = Theme.active,
    capPressed  = Theme.active,
    base        = {0.14, 0.15, 0.18, 1},
}

return Theme