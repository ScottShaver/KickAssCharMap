// =============================================================================
// just to make it easier to include all necessary Charmap-related files in one place
// include this file in your game program to have access to all Charmap-related functionality
// =============================================================================

// the constants below are derived from the tile and map dimensions that you must define in the program before including this file
.const CM_MAP_CHAR_WIDTH = CM_MAP_TILE_WIDTH * CM_TILE_CHAR_WIDTH              // width in chars of the map file
.const CM_MAP_CHAR_HEIGHT = CM_MAP_TILE_HEIGHT * CM_TILE_CHAR_HEIGHT             // height in chars of the map file
.const CM_DISPLAYED_MAP_CHAR_WIDTH = CM_DISPLAYED_MAP_TILE_WIDTH * CM_TILE_CHAR_WIDTH         // width in chars of the displayed map area
.const CM_DISPLAYED_MAP_CHAR_HEIGHT = CM_DISPLAYED_MAP_TILE_HEIGHT * CM_TILE_CHAR_HEIGHT      // height in chars of the displayed map area

#import "c64_constants.asm"
#import "c64_macros.asm"
#import "structs.asm" 
//#import "charmap.asm" // this set of code is a basic working version of the Charmap functionality, but it is very slow.
#import "charmap_lut_pointers.asm" // this set of code uses lookup tables for faster pointer calculations
#import "charmap_tables.asm"
#import "charmap_macros.asm"
#import "charmap_subroutines.asm"
