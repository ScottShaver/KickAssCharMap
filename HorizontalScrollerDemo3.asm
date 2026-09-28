//=============================================================================================================================
// *** START: Configure and import everything related to our Charmap usage ***
//=============================================================================================================================
//----------------------------------------------------------------------------------------------------------------------------
// The constants below define the dimensions and layout of the map and tiles for this program.
// All names starting with CM_ are related to the Charmap configuration and display settings.
// You must define these BEFORE including the Charmap processing code.
//----------------------------------------------------------------------------------------------------------------------------
.const CM_TILE_CHAR_WIDTH = 1              // width in chars of each map tile in the files (1x1 means no tiles)
.const CM_TILE_CHAR_HEIGHT = 1             // height in chars of each map tile in the files
.const CM_MAP_TILE_WIDTH = 240             // width in tiles of the map in the files
.const CM_MAP_TILE_HEIGHT = 25             // height in tiles of the map in the files

// set these to how you want the map displayed on the screen
.const CM_DISPLAYED_MAP_X = 0               // upper left corner X coordinate of the map display
.const CM_DISPLAYED_MAP_Y = 0               // upper left corner Y coordinate of the map display
.const CM_DISPLAYED_MAP_TILE_WIDTH = 40     // width in tiles of the displayed map area
.const CM_DISPLAYED_MAP_TILE_HEIGHT = 25    // height in tiles of the displayed map area

.const CODE_START_ADDR = $C000          // where the code starts
//=============================================================================================================================
// *** END: Configure and import everything related to our Charmap usage ***
//=============================================================================================================================

//----------------------------------------------------------------------------------------------------------------------------
// Code start for the basic upstart routine
//----------------------------------------------------------------------------------------------------------------------------
* = CODE_START_ADDR "CODE_START_ADDR"
BasicUpstart2(start)

#import "./kickasslibs/charmap_import.asm" // import the Charmap processing code

//----------------------------------------------------------------------------------------------------------------------------
// main program entry point
//----------------------------------------------------------------------------------------------------------------------------
start:
sei
        KillBASIC()                                             // Disable BASIC to free up RAM
        KillKernal()                                            // Disable KERNAL ROM to free up RAM
        KillCharacterGenerator()                                // Disable Character Generator ROM to free up RAM
        ClearScreen($5b)                                        // Clear the screen
        SetColors(YELLOW, BLACK, ORANGE, LIGHT_GREEN, BROWN)    // Set border and background colors that get used for the map chars
        SetMulticolorMode()                                     // Enable multicolor mode
        Set38ColumnMode()                                     // Enable 38-column mode
        SetLowerCaseCharsetMode()                               // make sure we using a charset with upper and lower case characters for the screen codes
        SetCharsetAddress(VIC_SCREEN_CHAR_BANK_OFFSET_10240)    // Set the address of the character set data this offset matches CHARSET_CHAR_DATA_ADDR $2800

        CMInitCharMapCode()                                     // always call this once before using any other charmap macros
        CMDrawMapWindowed()

loop1:
        //------------------------------------------------------------------------------------------------------
        // this is how you use the map without smooth horizontalscrolling
        //------------------------------------------------------------------------------------------------------
        //CMIncMapXCharOffset()                                   // scroll the map to left by one character
        //CMDrawMapWindowed()                                     // draw the map on the screen

        //------------------------------------------------------------------------------------------------------
        // this is how you use the map with smooth horizontal scrolling
        // CMDrawMapWindowed() <- force the map to be drawn immediately or let the smooth scrolling handle it automatically
        //------------------------------------------------------------------------------------------------------
        //jsr sync_vblank
        CMHorizontalSmoothScrollLeftOnePixel()  // when using smooth scrolling the code will automatically draw the screen when needed

        jmp loop1



//----------------------------------------------------------------------------------------------------------------------------
// Map data for the level.
// INCLUDE THE MAP DATA FILES GENERATED BY CHARPAD HERE
//----------------------------------------------------------------------------------------------------------------------------
* = CM_CHARSET_CHAR_DATA_ADDR "CHARSET_CHAR_DATA_ADDR"
.align $100
        .import binary "./charmap/DemoMap1/DemoMap1 - Chars.bin"
* = CM_CHARSET_ATTRIB_DATA_ADDR "CHARSET_ATTRIB_DATA_ADDR"
.align $100
        .import binary "./charmap/DemoMap1/DemoMap1 - CharAttribs.bin"
* = CM_MAP_LEVEL_DATA_ADDR "MAP_LEVEL_DATA_ADDR"
.align $100
        .import binary "./charmap/DemoMap1/DemoMap1 - Map (240x25).bin"
