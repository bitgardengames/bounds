--------------------------------------------------------------
-- THEME — Bounds
-- Centralized color + material language
-- This file encodes *meaning*, not just RGB values.
--------------------------------------------------------------

local Theme = {}

--------------------------------------------------------------
-- PALETTE (raw materials)
-- These should almost never be referenced directly outside
-- this file. Everything below uses *semantic intent*.
--------------------------------------------------------------
Theme.palette = {
    -- Structural neutrals
    outline     = {0.04, 0.05, 0.07, 1},     -- deep navy / ink
    bgDark      = {0.10, 0.12, 0.15, 1},     -- facility shadow
    bgMid       = {0.14, 0.18, 0.22, 1},     -- primary wall tone
    bgLight     = {0.25, 0.29, 0.33, 1},     -- platform tops / highlights

    -- Metals
    metalDark   = {0.23, 0.28, 0.34, 1},
    metalMid    = {0.33, 0.39, 0.46, 1},
    metalLight  = {0.60, 0.68, 0.80, 1},

    -- Accent / logic color (THE orange)
    accent      = {0.98, 0.62, 0.10, 1},

    -- Disabled / inert signal
    inactive    = {0.18, 0.18, 0.18, 1},
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
    -- Background panels
    background   = P.bgMid,

    -- Chamber outer frame
    outer        = P.bgDark,

    -- Solid tiles / collision world
    solid        = P.bgDark,

    -- Platform walkable surface
    platformTop = P.bgLight,

    -- Subtle grid / noise overlays
    grid = {
        P.bgLight[1],
        P.bgLight[2],
        P.bgLight[3],
        0.18,
    },
}

--------------------------------------------------------------
-- DECORATIONS / ENVIRONMENT
--------------------------------------------------------------
Theme.decorations = {
    -- Structural tones
    dark        = P.bgDark,
    background  = P.bgMid,
    outline     = P.outline,

    -- Construction materials
    metal       = P.metalMid,
    panel       = P.metalLight,
    grill       = P.metalDark,
    pipe        = P.metalMid,
    conduit     = {0.42, 0.48, 0.56, 1},
    bracket     = {0.20, 0.25, 0.30, 1},

    -- Moving decor
    fanFill     = {0.78, 0.84, 0.90, 1},

    -- Screens / signage
    signFill    = P.bgDark,
    signText    = Theme.state.active,

    -- Logic visuals
    timerColor      = Theme.state.active,
    conduitEnabled  = Theme.state.active,
    conduitDisabled = Theme.state.inactive,

    -- Platform strip overlay (matches level)
    platformTop = P.bgLight,
}

--------------------------------------------------------------
-- PLAYER (Lumo)
-- Lumo should be the brightest neutral object in the world,
-- but never pure white (reserved for UI/glow effects).
--------------------------------------------------------------
Theme.player = {
    fill    = {0.92, 0.94, 0.97, 1},
    outline = Theme.outline,
}

--------------------------------------------------------------
-- MONITOR / CAMERA
--------------------------------------------------------------
Theme.monitor = {
    lens    = Theme.player.fill,
    arm     = P.metalDark,
    body    = P.metalDark,
    mount   = {0.20, 0.20, 0.22, 1},
    led     = {1, 0.25, 0.25, 1},
    outline = Theme.decorations.outline,
}

--------------------------------------------------------------
-- INTERACTABLES (shared language)
--------------------------------------------------------------
Theme.interactables = {
    outline = Theme.outline,
    base    = P.bgMid,
    accent  = Theme.state.active,
}

--------------------------------------------------------------
-- CUBE
--------------------------------------------------------------
Theme.cube = {
    fill        = {94/255, 106/255, 120/255, 1}, -- light steel blue
    centerFill = Theme.state.active,
    outline     = Theme.outline,
}

--------------------------------------------------------------
-- DOOR / EXIT
--------------------------------------------------------------
Theme.door = {
    frame     = P.metalMid,
    doorFill  = P.bgDark,          -- interior void
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
-- STOMP BUTTON (one-shot)
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
    topcap    = {0.18, 0.20, 0.24, 1},
    bottomcap = {0.24, 0.28, 0.33, 1},
    glass     = {0.40, 0.65, 0.88, 0.28},
    highlight = {1, 1, 1, 0.18},
}

--------------------------------------------------------------
-- SAW / HAZARDS
--------------------------------------------------------------
Theme.saw = {
    track          = Theme.outline,
    bladeFill      = {0.82, 0.78, 0.75, 1},
    bladeHighlight = {1, 1, 1, 0.12},
    rim            = Theme.outline,
    center         = Theme.outline,
}

--------------------------------------------------------------
-- END THEME
--------------------------------------------------------------
return Theme