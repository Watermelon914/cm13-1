#define CHANGETURF_DEFER_CHANGE		(1<<0)
#define CHANGETURF_IGNORE_AIR		(1<<1) // This flag prevents changeturf from gathering air from nearby turfs to fill the new turf with an approximation of local air
#define CHANGETURF_FORCEOP			(1<<2)
#define CHANGETURF_SKIP				(1<<3) // A flag for PlaceOnTop to just instance the new turf instead of calling ChangeTurf. Used for uninitialized turfs NOTHING ELSE

#define IS_OPAQUE_TURF(turf) (turf.directional_opacity == ALL_CARDINALS)

/// Marks a turf as organic. Used for alien wall and membranes.
#define TURF_ORGANIC (1<<0)

/// Hides a turf on the minimap
#define TURF_MINIMAP_HIDE (1<<1)
