/// A colour matrix that turns whatever colours a sprite has into glowing yellows, keeping its brightness
#define ARCFIEND_YELLOW_TINT list(0.45, 0.41, 0.135, 0.885, 0.805, 0.265, 0.165, 0.15, 0.05)

/// How much nutrition an arcfiend gets for every unit of power they sap, up to being full but never fat
#define ARCFIEND_NUTRITION_PER_POWER 0.25

/// How much charge an ethereal loses for every unit of power an arcfiend drains out of them
#define ARCFIEND_ETHEREAL_CHARGE_PER_POWER 0.5

/// Joules of station energy that one unit of arcfiend power is worth
#define ARCFIEND_JOULES_PER_POWER 2000
/// Joules an SMES loses for each unit of power an arcfiend gets from it, a very inefficient conversion
#define ARCFIEND_SMES_JOULES_PER_POWER (ARCFIEND_JOULES_PER_POWER * 5)

// Power gained per second of Sap Power, by source
#define ARCFIEND_DRAIN_APC 30
#define ARCFIEND_DRAIN_SMES 30
#define ARCFIEND_DRAIN_CABLE 10
#define ARCFIEND_DRAIN_MOB 40
#define ARCFIEND_DRAIN_CYBORG 40
#define ARCFIEND_DRAIN_MACHINE_MAX 8

/// Burn damage per second dealt to a human being sapped
#define ARCFIEND_SAP_MOB_BURN 5
/// Stamina damage per second dealt to a human being sapped
#define ARCFIEND_SAP_MOB_STAMINA 10
/// Burn damage per second dealt to a cyborg being sapped
#define ARCFIEND_SAP_CYBORG_BURN 3
/// Chance per second that sapping an APC breaks it
#define ARCFIEND_SAP_APC_BREAK_PROB 4

/// How much power must be drained from a mind, in total, before it counts towards the arcfiend's unlocks
#define ARCFIEND_MIND_DRAIN_REQUIRED 80

/// Power it costs to enter the cables with Ride the Lightning
#define ARCFIEND_RIDE_ENTRY_COST 75
/// Power it costs to move one tile along the cables
#define ARCFIEND_RIDE_TILE_COST 2
/// Power drained each second while riding the cables, even when standing still
#define ARCFIEND_RIDE_UPKEEP 1
/// How far, in tiles, an arcfiend can see hidden cables
#define ARCFIEND_CABLE_SIGHT_RANGE 5
/// How long it takes to enter or to leave the cables
#define ARCFIEND_RIDE_TRANSITION_TIME (1 SECONDS)
/// How long an arcfiend is stunned for when an EMP throws them out of the cables
#define ARCFIEND_RIDE_EMP_STUN (4 SECONDS)
/// How long an arcfiend is stunned for when a cable is cut out from under them
#define ARCFIEND_RIDE_CUT_STUN (3 SECONDS)

/// How much the dark is lifted by Ampullary Sense. Ordinary night vision is LIGHTING_CUTOFF_HIGH (30).
#define ARCFIEND_NIGHT_VISION_CUTOFF 50
/// How much the dark is lifted by the upgraded Ampullary Sense
#define ARCFIEND_NIGHT_VISION_CUTOFF_UPGRADED 75

/// Burn damage an arcfiend takes from a heavy EMP
#define ARCFIEND_EMP_HEAVY_DAMAGE 20
/// Burn damage an arcfiend takes from a light EMP
#define ARCFIEND_EMP_LIGHT_DAMAGE 10
/// Fraction of its stored power an arcfiend loses to a heavy EMP
#define ARCFIEND_EMP_HEAVY_POWER_LOSS 0.25
/// Fraction of its stored power an arcfiend loses to a light EMP
#define ARCFIEND_EMP_LIGHT_POWER_LOSS 0.1
