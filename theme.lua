--------------------------------------------------------------
-- THEME — Bounds (Micro Luminance Polish)
-- +4% lift on platform tops + interactable accents
--------------------------------------------------------------

local Theme = {}

--------------------------------------------------------------
-- PALETTE (raw materials)
--------------------------------------------------------------
Theme.palette = {
    -- Structural neutrals
    outline  = {0.045, 0.055, 0.075, 1},
    bgDark   = {0.12,  0.14,  0.17,  1},
    bgMid    = {0.20,  0.24,  0.29,  1},

    -- Platform / highlight base (slightly lifted)
    bgLight  = {0.333, 0.385, 0.447, 1}, -- ~4% luminance bump

    -- Metals
    metalDark  = {0.26, 0.31, 0.37, 1},
    metalMid   = {0.40, 0.46, 0.54, 1},
    metalLight = {0.68, 0.75, 0.86, 1},

    -- Accent / logic color (slightly lifted, hue preserved)
    accent   = {1.00, 0.645, 0.115, 1}, -- ~4% luminance bump

    -- Disabled / inert signal
    inactive = {0.22, 0.22, 0.24, 1},
}

local P = Theme.palette

--------------------------------------------------------------
-- GLOBALS / STATES
--------------------------------------------------------------
Theme.outline = P.outline

Theme.state = {
    active   = P.accent,
    inactive = P.inactive,
    locked   = P.bgDark,
}

--------------------------------------------------------------
-- LEVEL / WORLD
--------------------------------------------------------------
Theme.level = {
    -- Inner arena background
    background = P.bgMid,

    -- Outer chamber frame
    outer      = P.bgDark,

    -- Collision solids
    solid      = {0.13, 0.16, 0.20, 1},

    -- Walkable platform surface (primary readability target)
    platformTop = P.bgLight,

    -- Grid / panel noise
    grid = {
        P.bgLight[1],
        P.bgLight[2],
        P.bgLight[3],
        0.16,
    },
}

--------------------------------------------------------------
-- DECORATIONS / ENVIRONMENT
--------------------------------------------------------------
Theme.decorations = {
    dark        = P.bgDark,
    background  = P.bgMid,
    outline     = P.outline,

    metal       = P.metalMid,
    panel       = P.metalLight,
    grill       = P.metalDark,
    pipe        = P.metalMid,
    conduit     = {0.48, 0.54, 0.62, 1},
    bracket     = {0.22, 0.27, 0.32, 1},

    fanFill     = {0.82, 0.88, 0.94, 1},

    signFill    = P.bgDark,
    signText    = Theme.state.active,

    timerColor      = Theme.state.active,
    conduitEnabled  = Theme.state.active,
    conduitDisabled = Theme.state.inactive,

    platformTop = P.bgLight,
}

--------------------------------------------------------------
-- PLAYER (Lumo)
--------------------------------------------------------------
Theme.player = {
    fill    = {0.94, 0.96, 0.99, 1},
    outline = Theme.outline,
}

--------------------------------------------------------------
-- MONITOR / CAMERA
--------------------------------------------------------------
Theme.monitor = {
    lens    = Theme.player.fill,
    arm     = P.metalDark,
    body    = P.metalDark,
    mount   = {0.23, 0.23, 0.25, 1},
    led     = {1, 0.25, 0.25, 1},
    outline = Theme.decorations.outline,
}

--------------------------------------------------------------
-- INTERACTABLES
--------------------------------------------------------------
Theme.interactables = {
    outline = Theme.outline,
    base    = P.bgMid,
    accent  = Theme.state.active, -- now slightly more present
}

--------------------------------------------------------------
-- CUBE
--------------------------------------------------------------
Theme.cube = {
    fill        = {102/255, 118/255, 136/255, 1},
    centerFill = Theme.state.active,
    outline     = Theme.outline,
}

--------------------------------------------------------------
-- DOOR / EXIT
--------------------------------------------------------------
Theme.door = {
    frame     = P.metalMid,
    doorFill  = P.bgDark,
    unlocked  = Theme.state.active,
    locked    = Theme.state.locked,
}

--------------------------------------------------------------
-- PRESSURE PLATE
--------------------------------------------------------------
Theme.pressurePlate = {
    outline    = Theme.interactables.outline,
    button     = Theme.interactables.accent,
    buttonGlow = Theme.interactables.accent,
    base       = Theme.interactables.base,
}

--------------------------------------------------------------
-- STOMP BUTTON
--------------------------------------------------------------
Theme.buttons = {
    outline     = Theme.interactables.outline,
    cap         = Theme.interactables.accent,
    capPressed  = Theme.interactables.accent,
    base        = Theme.interactables.base,
}

--------------------------------------------------------------
-- DROP TUBE
--------------------------------------------------------------
Theme.droptube = {
    topcap    = {0.21, 0.23, 0.27, 1},
    bottomcap = {0.27, 0.31, 0.37, 1},
    glass     = {0.42, 0.70, 0.94, 0.28},
    highlight = {1, 1, 1, 0.18},
}

--------------------------------------------------------------
-- SAW / HAZARDS
--------------------------------------------------------------
Theme.saw = {
    track          = Theme.outline,
    bladeFill      = {0.85, 0.81, 0.78, 1},
    bladeHighlight = {1, 1, 1, 0.14},
    rim            = Theme.outline,
    center         = Theme.outline,
}

--------------------------------------------------------------
-- END THEME
--------------------------------------------------------------
return Theme