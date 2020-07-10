@lazyglobal off.

parameter export.
export("create_maneuver", create_maneuver@).

// Convenience wrapper around a maneuver node
local function create_maneuver {
    parameter destination, epoch_time, deltav.

    local maneuver is node(epoch_time, deltav:x, deltav:y, deltav:z).
    add maneuver.

    return lexicon(
        "delete", delete@:bind(maneuver),
        "departure_time", departure_time@:bind(maneuver),
        "deltav", get_deltav@:bind(maneuver),
        "patch_time", patch_time@:bind(maneuver),
        "osv_at_destination_soi", osv_at_destination_soi@:bind(destination, maneuver),
        "distance_to_periapsis", distance_to_periapsis@:bind(destination, maneuver)
        //"time_to_periapsis", time_to_periapsis@:bind(destination, maneuver),
    ).
}

local function delete {
    parameter maneuver.

    remove maneuver.
}

local function departure_time {
    parameter maneuver.

    return time():seconds + maneuver:eta.
}

local function get_deltav {
    parameter maneuver.    

    return maneuver:deltav:mag.
}

// TODO: There may be a accidental moon intercept.
local function patch_time {
    parameter maneuver.    

    return time():seconds + maneuver:orbit:nextpatcheta.
}

// Returns the predicted time and velocity of the ship when it will enter
// the destination's SOI.
local function osv_at_destination_soi {
    parameter destination, maneuver.

    local orbit is maneuver:orbit.

    until not orbit:hasnextpatch {
        local arrival_time is time():seconds + orbit:nextpatcheta.
        set orbit to orbit:nextpatch.

        if orbit:body = destination {
            local arrival_velocity is velocityat(ship, arrival_time):orbit.

            // When the destination is a moon (rather than a planet) then
            // "velocityat" returns value relative to the parent planet *not*
            // the moon, even though ship is within moon's SOI at 'arrival_time'.
            if destination:body:hasbody {
                local adjustment is velocityat(destination, arrival_time):orbit.
                set arrival_velocity to arrival_velocity - adjustment.
            }

            return lexicon(
                "success", true,
                "time", arrival_time,
                "velocity", arrival_velocity
            ).
        }
    }

    return lexicon("success", false).
}

local function distance_to_periapsis {
    parameter destination, maneuver, final_orbit_periapsis.

    local orbit is maneuver:orbit.

    until not orbit:hasnextpatch {
        set orbit to orbit:nextpatch.

        if orbit:body = destination {
            return abs(orbit:periapsis - final_orbit_periapsis).
        }
    }

    return "max".
}

// TODO: There may be a accidental moon intercept.
// or not enough patches to get and "exit" point for average.
local function time_to_periapsis {
    parameter destination, maneuver.

    local orbit is maneuver:orbit.

    until not orbit:hasnextpatch {
        local start is orbit:nextpatcheta.
        set orbit to orbit:nextpatch.
        local end is orbit:nextpatcheta.

        if orbit:body = destination {
            return time():seconds + (start + end) / 2.
        }
    }

    return "max".
}