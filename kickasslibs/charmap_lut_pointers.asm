// =============================================================================
// Primary code file for code that displays and manipulates Charmap map data.
//
// this is the second version that uses look up tables to avoid repeated 
// pointer calculations inside the loops- it can be used by
// uncommenting the imnport line for it in the charmap_import.asm file.  Make sure to
// comment out the other versrion that may be being imported.
//
// the generated look up tables are in the charmap_tables.asm file
// =============================================================================

//----------------------------------------------------------------------------------------------------------------------------
// constants specific to this code
//----------------------------------------------------------------------------------------------------------------------------
.const CM_MAP_TILES_DATA_ADDR = $5300      // where the tiles file from charpad gets loaded - ???
.const CM_MAP_LEVEL_DATA_ADDR = $3a00      // where the map file from charpad gets loaded - 6000 bytes for a 240x25 map
.const CM_CHARSET_ATTRIB_DATA_ADDR = $5400  // where the charset color file from charpad gets loaded - 256 bytes used
.const CM_CHARSET_CHAR_DATA_ADDR = $2800   // where the charset file from charpad gets loaded - 2048 bytes used
.const CM_LOOKUP_TABLES_ADDR = $1000       // where lookup tables are loaded

//----------------------------------------------------------------------------------------------------------------------------
// Zero-page storage for our calculated 16-bit pointers
// the skipped zero-page locations are used for other purposes by the system and are not safe for our use
//----------------------------------------------------------------------------------------------------------------------------
.var cm_CurrentMapCharPointer = $02             // pointer to the map character data CM_MAP_LEVEL_DATA_ADDR
.var cm_CurrentMapCharColorPointer = $04        // pointer to the map color data
.var cm_MapTileDataPointer = $0A                // pointer to the map tile data
.var cm_CurrentScreenCharPointer = $12          // this is the pointer to the current memory location that we need to place a character at
.var cm_CurrentScreenCharColorPointer = $14     // this is the pointer to the current memory location that we need to place a character color at

//----------------------------------------------------------------------------------------------------------------------------
// Zero-page storage locations for our variables
// the skipped zero-page locations are used for other purposes by the syhstem and are not safe for our use
//----------------------------------------------------------------------------------------------------------------------------
.var cm_TileCharWidth = $20                     // The width of each map tile in characters 0
.var cm_TileCharHeight = $21                    // The height of each map tile in characters 1
.var cm_MapWidthInChars = $26                   // The width of the map in characters 40 
.var cm_MapHeightInChars = $FB                  // The height of the map in characters 25 
.var cm_CurrentMapCharX = $35                   // which column of the map we are currently processing
.var cm_CurrentMapCharY = $36                   // which row of the map we are currently processing
.var cm_CurrentDisplayX = $37                   // which column of the display area we are currently processing
.var cm_CurrentDisplayY = $38                   // which row of the display area we are currently processing
.var cm_calcTemp1 = $40
.var cm_calcTemp2 = $41
.var cm_calcTemp3 = $42
.var cm_calcTemp4 = $43
.var cm_CurrentCharScrollXPosition = $45        // which map column do we display in the left most display column
.var cm_CurrentCharScrollYPosition = $46        // which map row do we display in the top most display row

CMInitMemoryPointers:
        // init map color pointer to point to the start of level colors
        lda #<CM_CHARSET_ATTRIB_DATA_ADDR
        sta cm_CurrentMapCharColorPointer
        lda #>CM_CHARSET_ATTRIB_DATA_ADDR
        sta cm_CurrentMapCharColorPointer + 1

        // init map char pointer to point to the start of level chars
        lda #<CM_MAP_LEVEL_DATA_ADDR
        sta cm_CurrentMapCharPointer
        lda #>CM_MAP_LEVEL_DATA_ADDR
        sta cm_CurrentMapCharPointer + 1

        // todo: deal with this when we handle tiles
        // init map char pointer to point to the start of level chars
        lda #<$0000
        sta cm_MapTileDataPointer
        lda #>$0000
        sta cm_MapTileDataPointer + 1

        lda #<VIC_SCREEN_CHAR_MEMORY_ADDR
        sta cm_CurrentScreenCharPointer
        lda #>VIC_SCREEN_CHAR_MEMORY_ADDR
        sta cm_CurrentScreenCharPointer + 1

        lda #<VIC_SCREEN_COLOR_MEMORY_ADDR
        sta cm_CurrentScreenCharColorPointer
        lda #>VIC_SCREEN_COLOR_MEMORY_ADDR
        sta cm_CurrentScreenCharColorPointer + 1

        rts

//----------------------------------------------------------------------------------------------------------------------------
// init zero-page variables
//----------------------------------------------------------------------------------------------------------------------------
CMInitZeroPageVariables:
        lda #CM_TILE_CHAR_WIDTH     // this is how many chars wide each map tile is
        sta cm_TileCharWidth    

        lda #CM_TILE_CHAR_HEIGHT    // this is how many chars tall each map tile is
        sta cm_TileCharHeight

        lda #CM_MAP_CHAR_WIDTH      // this is how many chars wide the map is
        sta cm_MapWidthInChars

        lda #CM_MAP_CHAR_HEIGHT     // this is how many chars tall the map is
        sta cm_MapHeightInChars

        lda #$00
        sta cm_CurrentMapCharX
        sta cm_CurrentMapCharY
        sta cm_CurrentCharScrollXPosition
        sta cm_CurrentCharScrollYPosition
        sta cm_CurrentMapCharX       
        sta cm_CurrentMapCharY

        lda #CM_DISPLAYED_MAP_X
        sta cm_CurrentDisplayX
        lda #CM_DISPLAYED_MAP_Y
        sta cm_CurrentDisplayY

        rts

// draw map to the screen
CMDrawMapWindowedLUTPointers: {
        // draw the map one column at a time moving left to right
        ldy #CM_DISPLAYED_MAP_X          // Y register is the screen column 
        lda #CM_DISPLAYED_MAP_X
        sta cm_CurrentDisplayX

        lda #$00  // keep track of which column in the visible map screen window we are on
        sta cm_calcTemp2

drawNextCol: // loop through the columns of the map window
//.break
        sty cm_CurrentDisplayX                  // store the current display column
        
        jsr CMDrawMapRowsWindowedLUTPointers     // draw all rows for the current column
//.break
        ldy cm_calcTemp2 ; iny ; sty cm_calcTemp2 // keep track of which column in the visible map screen window we are on

        ldy cm_CurrentDisplayX
        iny                                     // move to the next display column
        cpy #(CM_DISPLAYED_MAP_X + CM_DISPLAYED_MAP_CHAR_WIDTH)  // have we reached the last display column? 

        bne drawNextCol                            // if we have not reached the last column, continue the column loop

        rts                                     // finished drawing the map window
}

// loop through the rows from top to bottom filling in the column for the current display X position
CMDrawMapRowsWindowedLUTPointers: {
        // set the initial LUT pointer for the current row based on the display Y and scroll position
        ldx #CM_DISPLAYED_MAP_Y // X register is the screen row 
        stx cm_CurrentDisplayY // store the current display row
        
        lda #$00  // keep track of which row in the visible map screen window we are on
        sta cm_calcTemp1

drawNextCol: // loop through the columns of the map window
//.break
        // use the LUT pointers to set the current screen char and color pointers the low byte LUT table can be used for both char and color pointers
        // the screen locations are always based off the cm_CurrentDisplayY (row) and cm_CurrentDisplayX (column offsett from the start of the row) positions
        lda tableScreenPointerLow, x            // low byte for row
        sta cm_CurrentScreenCharPointer+0       //store low byte of screen char pointer
        sta cm_CurrentScreenCharColorPointer+0  // store low byte of screen color pointer
        lda tableCharScreenPointerHigh, x       // high byte for char row
        sta cm_CurrentScreenCharPointer+1       // store high byte of screen char pointer
        lda tableColorScreenPointerHigh, x      // high byte for color row
        sta cm_CurrentScreenCharColorPointer+1  // store high byte of screen color pointer
        // now we have the pointers to the screen char and color locations to place the next characters and colors on the screen

        // get the pointer to map on the correct row based on the current vertical scroll position
        // the map pointer is based on the (cm_CurrentCharScrollYPosition+cm_calcTemp1) (row) and (cm_CurrentCharScrollXPosition + cm_calcTemp2) (column) positions
        lda cm_CurrentCharScrollYPosition
        clc
        adc cm_calcTemp1
        tax
        lda tableMapCharPointerLow, x           // low byte for map char row
        sta cm_CurrentMapCharPointer+0          // store low byte of map char pointer
        lda tableMapCharPointerHigh, x          // high byte for map char row
        sta cm_CurrentMapCharPointer+1          // store high byte of map char pointer

        // we are now pointing to the correct row in the map data but we need to use the column offset to get the exact map char within this row
        ldx cm_CurrentDisplayY                  // restore the X register for the display row loop

        //--------------------------------------------------------------------------------------------------
        // use indirect indexing with y register to place column char on screen
        //--------------------------------------------------------------------------------------------------

        lda cm_CurrentCharScrollXPosition
        clc
        adc cm_calcTemp2
        tay
        //ldy cm_CurrentCharScrollXPosition //#$00
        lda (cm_CurrentMapCharPointer), y               // load the map char
        ldy cm_CurrentDisplayX
        sta (cm_CurrentScreenCharPointer), y            // place map char on screen

        //--------------------------------------------------------------------------------------------------
        // use indirect indexing with y register to place column color on screen
        //--------------------------------------------------------------------------------------------------
        tay                                             // move it into y reg
        lda (cm_CurrentMapCharColorPointer), y          // load the map color code using the y reg as an offest from the front, so the char code is the offset into the color data
        ldy cm_CurrentDisplayX                          // no offset/index
        sta (cm_CurrentScreenCharColorPointer), y       // store the color code into screeen color memory

        ldy cm_calcTemp1 ; iny ; sty cm_calcTemp1 // keep track of which row in the visible map screen window we are on

        inx                                                             // move to the next row in the LUT pointers
        stx cm_CurrentDisplayY                                          // store the current display row
        cpx #(CM_DISPLAYED_MAP_Y + CM_DISPLAYED_MAP_CHAR_HEIGHT)        // have we reached the last display row? <-------------------------------------------------------
        bne drawNextCol                                                 // if we have not reached the last row, continue the row loop

        ldy cm_CurrentDisplayX                                          // restore the Y register for the display column loop
        rts
}
