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
.const CM_MAP_TILE_HEIGHT = 20             // height in tiles of the map in the files

// set these to how you want the map displayed on the screen
.const CM_DISPLAYED_MAP_X = 0               // upper left corner X coordinate of the map display
.const CM_DISPLAYED_MAP_Y = 5               // upper left corner Y coordinate of the map display
.const CM_DISPLAYED_MAP_TILE_WIDTH = 40     // width in tiles of the displayed map area
.const CM_DISPLAYED_MAP_TILE_HEIGHT = 20    // height in tiles of the displayed map area

.const CODE_START_ADDR = $5500//$C800          // where the code starts
//=============================================================================================================================
// *** END: Configure and import everything related to our Charmap usage ***
//=============================================================================================================================

//----------------------------------------------------------------------------------------------------------------------------
// Code start for the basic upstart routine
//----------------------------------------------------------------------------------------------------------------------------
BasicUpstart2(start)
* = CODE_START_ADDR "CODE_START_ADDR"

#import "./kickasslibs/charmap_import.asm" // import the Charmap processing code

//----------------------------------------------------------------------------------------------------------------------------
// main program entry point
//----------------------------------------------------------------------------------------------------------------------------
start:
sei
        KillBASIC()                                             // Disable BASIC to free up RAM
        KillKernal()                                            // Disable KERNAL ROM to free up RAM
        KillCharacterGenerator()                                // Disable Character Generator ROM to free up RAM
        SetColors(YELLOW, BLACK, ORANGE, LIGHT_GREEN, BROWN)    // Set border and background colors that get used for the map chars
        SetMulticolorMode()                                     // Enable multicolor mode
        Set38ColumnMode()                                     // Enable 38-column mode
        SetLowerCaseCharsetMode()                               // make sure we using a charset with upper and lower case characters for the screen codes
        SetCharsetAddress(VIC_SCREEN_CHAR_BANK_OFFSET_10240)    // Set the address of the character set data this offset matches CHARSET_CHAR_DATA_ADDR $2800
        CMInitCharMapCode()                                     // always call this once before using any other charmap macros

        // Clear the screen using double buffering
        CMClearScreenDblBuf($20)
        CMSetMapXCharOffset(200)
        CMForceDrawMapWindowed()
        CMFlipBuffer()
        CMForceDrawMapWindowed()
        CMFlipBuffer()

//.break
//        jsr initIRQ
//        jmp * // Main loop does nothing; interrupts drive execution 

loop1:
        //------------------------------------------------------------------------------------------------------
        // this is how you use the map without smooth horizontalscrolling
        //------------------------------------------------------------------------------------------------------
        //CMIncMapXCharOffset()                                   // scroll the map to left by one character
        //CMDrawMapWindowed()                                     // draw the map on the screen

        //------------------------------------------------------------------------------------------------------
        // this is how you use the map with smooth horizontal scrolling
        //------------------------------------------------------------------------------------------------------
        //CMHorizontalSmoothScrollLeftOnePixel()  // when using smooth scrolling the code will automatically draw the screen when needed
        CMHorizontalSmoothScrollRightOnePixel()
.break
        jmp loop1
/**/

//-----------------------------------------------------------------------------------------------
// first interrupt handler (irq1) - draw the map and handle smooth scrolling
//-----------------------------------------------------------------------------------------------
irq1:
        // Acknowledge the VIC raster interrupt flag
        asl $d019 

        //****************************************
        //****************************************
        CMHorizontalSmoothScrollLeftOnePixel()
        //****************************************
        //****************************************

        // Jump back to KERNAL interrupt exit routine
        jmp $ea81 

//-----------------------------------------------------------------------------------------------
// 
//-----------------------------------------------------------------------------------------------
initIRQ:
        // Disable interrupts while changing vectors and registers
        sei 

        // Set custom IRQ vector addresses ($0314/$0315)
        lda #<irq1
        sta $0314
        lda #>irq1
        sta $0315

        // Turn off CIA timer interrupts
        lda #$7f
        sta $dc0d
        sta $dd0d

        // Enable VIC raster interrupts
        lda #$81
        sta $d01a 

        // Set high bit of raster line in $d011 (bit 7 for line > 255, clear for < 256)
        lda #$1b
        sta $d011 

        // Choose target raster line 251
        lda #$fb
        sta $d012 

        // Acknowledge pending CIA and VIC flags
        lda $dc0d
        lda $dd0d
        asl $d019 

        // Re-enable maskable interrupts
        cli 

        rts

//----------------------------------------------------------------------------------------------------------------------------
// Map data for the level.
// INCLUDE THE MAP DATA FILES GENERATED BY CHARPAD HERE
//----------------------------------------------------------------------------------------------------------------------------
* = CM_CHARSET_CHAR_DATA_ADDR "CHARSET_CHAR_DATA_ADDR"
.align $100
        .import binary "./charmap/DemoMap2/DemoMap2 - Chars.bin"
* = CM_CHARSET_ATTRIB_DATA_ADDR "CHARSET_ATTRIB_DATA_ADDR"
.align $100
        .import binary "./charmap/DemoMap2/DemoMap2 - CharAttribs.bin"
* = CM_MAP_LEVEL_DATA_ADDR "MAP_LEVEL_DATA_ADDR"
.align $100
        .import binary "./charmap/DemoMap2/DemoMap2 - Map (240x20).bin"
