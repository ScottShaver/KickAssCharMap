// =============================================================================
// Primary code file for code that displays and manipulates Charmap map data.
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

//----------------------------------------------------------------------------------------------------------------------------
// init all of the memory pointers used to point to various data sections to the start of their respective memory areas
//----------------------------------------------------------------------------------------------------------------------------
CMInitMemoryPointers:
        CMResetMapPointers()
        CMResetTilePointers()
        CMResetPrintCharPointers()
        rts
.macro CMResetTilePointers() {
        // init map tile data pointer to point to the start of level_chars
        lda #<CM_MAP_TILES_DATA_ADDR
        sta cm_MapTileDataPointer
        lda #>CM_MAP_TILES_DATA_ADDR
        sta cm_MapTileDataPointer + 1
        //rts
}
.macro CMResetMapPointers() {
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
        // adjust the map char pointer by the X offset, how far to the right we are scrolled
        lda cm_CurrentMapCharPointer    // Load low byte
        clc                     // Clear carry flag
        adc cm_CurrentCharScrollXPosition      // Add the map char X offset to the pointer
        sta cm_CurrentMapCharPointer    // Save low byte back
        lda cm_CurrentMapCharPointer+1  // Load high byte
        adc #$00                        // Add the carry flag (0 or 1)
        sta cm_CurrentMapCharPointer+1  //   Save high byte back
        // adjust the map char pointer by the Y offset, how far down we are scrolled
        lda cm_CurrentCharScrollYPosition
        sta cm_calcTemp1
        lda #CM_MAP_CHAR_WIDTH
        sta cm_calcTemp2
        jsr CMMultiplyTwo8bit
        lda cm_CurrentMapCharPointer    // Load low byte
        clc                     // Clear carry flag
        adc cm_calcTemp3           // Add the map char X offset to the pointer
        sta cm_CurrentMapCharPointer    // Save low byte back
        lda cm_CurrentMapCharPointer+1  // Load high byte
        adc cm_calcTemp4           // Add the carry flag (0 or 1)
        sta cm_CurrentMapCharPointer+1  //   Save high byte back
        //rts
}
.macro CMResetPrintCharPointers() {
        // reset the pointers for where to write to on the screen
        lda #<(VIC_SCREEN_CHAR_MEMORY_ADDR + CM_DISPLAYED_MAP_X + (VIC_SCREEN_WIDTH_COLS * CM_DISPLAYED_MAP_Y))
        sta cm_CurrentScreenCharPointer
        lda #>(VIC_SCREEN_CHAR_MEMORY_ADDR + CM_DISPLAYED_MAP_X +(VIC_SCREEN_WIDTH_COLS * CM_DISPLAYED_MAP_Y))
        sta cm_CurrentScreenCharPointer + 1

        // make screen_color_pointer point to the start of screen color memory
        lda #<(VIC_SCREEN_COLOR_MEMORY_ADDR + CM_DISPLAYED_MAP_X +(VIC_SCREEN_WIDTH_COLS * CM_DISPLAYED_MAP_Y))
        sta cm_CurrentScreenCharColorPointer
        lda #>(VIC_SCREEN_COLOR_MEMORY_ADDR + CM_DISPLAYED_MAP_X +(VIC_SCREEN_WIDTH_COLS * CM_DISPLAYED_MAP_Y))
        sta cm_CurrentScreenCharColorPointer + 1
        //rts
}

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
        sta cm_CurrentCharScrollXPosition
        sta cm_CurrentMapCharY
        sta cm_CurrentCharScrollYPosition

        lda #CM_DISPLAYED_MAP_X
        sta cm_CurrentDisplayX
        lda #CM_DISPLAYED_MAP_Y
        sta cm_CurrentDisplayY

        rts

//----------------------------------------------------------------------------------------------------------------------------
// utils
//----------------------------------------------------------------------------------------------------------------------------

//----------------------------------------------------------------------------------------------------------------------------
// render the map on to the screen
//----------------------------------------------------------------------------------------------------------------------------
CMDrawMapWindowed: {
        CMResetPrintCharPointers()
        CMResetMapPointers()
        CMResetTilePointers()

        ldy cm_CurrentCharScrollYPosition      // instead of starting at 0 we start at how far down we are scrolled #$00
        sty cm_CurrentMapCharY            // store the map char y position we are going to read from
        lda #CM_DISPLAYED_MAP_Y
        sta cm_CurrentDisplayY          // store the screen Y position that the next char needs to go on
drawmap_windowed_row:
        jsr MoveMapAndPrintPointersForNewRow
drawmap_windowed_col:
        //-------------------------------------------------
        // draw next character to screen char memory and
        // its corresponding color to the screen clr memory
        //-------------------------------------------------
        // use indirect indexing with y register to place column char on screen
        ldy #$00
        lda (cm_CurrentMapCharPointer), y // load the map char
        sta (cm_CurrentScreenCharPointer), y // place map char on screen

        // use indirect indexing with y register to place column color on screen
        ldy #$00
        lda (cm_CurrentMapCharPointer), y // load the map char code
        tay // move it into y reg
        lda (cm_CurrentMapCharColorPointer), y // load the map color code using the y reg as an offest from the front, so the char code is the offset into the color data
        ldy #$00
        sta (cm_CurrentScreenCharColorPointer), y // store the color code into screeen color memory

        //-------------------------------------------------
        // we have put the character on the screen and
        // set the color, now move the relavant pointers forward
        // one byte each for the print char, print color, and 
        // map char pointers
        //-------------------------------------------------
        // move the print char pointer forward one byte
        lda cm_CurrentScreenCharPointer      // Load low byte
        clc                         // Clear carry flag
        adc #$01                    // Add 1
        sta cm_CurrentScreenCharPointer      // Save low byte back
        lda cm_CurrentScreenCharPointer+1    // Load high byte
        adc #$00                    // Add the carry flag (0 or 1)
        sta cm_CurrentScreenCharPointer+1    //   Save high byte back

        // move the print color pointer forward one byte
        lda cm_CurrentScreenCharColorPointer    // Load low byte
        clc                             // Clear carry flag
        adc #$01                        // Add 1
        sta cm_CurrentScreenCharColorPointer    // Save low byte back
        lda cm_CurrentScreenCharColorPointer+1  // Load high byte
        adc #$00                        // Add the carry flag (0 or 1)
        sta cm_CurrentScreenCharColorPointer+1  //   Save high byte back

        // move the map char pointer forward one byte
        lda cm_CurrentMapCharPointer        // Load low byte
        clc                         // Clear carry flag
        adc #$01                    // Add 1
        sta cm_CurrentMapCharPointer        // Save low byte back
        lda cm_CurrentMapCharPointer+1      // Load high byte
        adc #$00                    // Add the carry flag (0 or 1)
        sta cm_CurrentMapCharPointer+1      //   Save high byte back

        //-------------------------------------------------
        // store the screen X position that the next char needs to go on
        //-------------------------------------------------
        ldx cm_CurrentDisplayX
        inx
        stx cm_CurrentDisplayX
        //inx // move to next column
        //-------------------------------------------------
        // store the map char x position we are going to read from
        //-------------------------------------------------
        ldx cm_CurrentMapCharX
        inx // move to next column
        stx cm_CurrentMapCharX

        lda cm_CurrentCharScrollXPosition
        sta cm_calcTemp1
        lda #CM_DISPLAYED_MAP_CHAR_WIDTH
        sta cm_calcTemp2
        jsr CMAddTwo8Bit

        cpx cm_calcTemp2 // have we reached the last display column?
        bne drawmap_windowed_col // if not reached the last column, continue the column loop

        //-------------------------------------------------
        // store the screen Y position that the next char needs to go on
        //-------------------------------------------------
        ldy cm_CurrentDisplayY
        iny
        sty cm_CurrentDisplayY
        //-------------------------------------------------
        // store the map char Y position we are going to read from
        //-------------------------------------------------
        ldy cm_CurrentMapCharY
        iny // move to the next row
        sty cm_CurrentMapCharY

        lda #CM_DISPLAYED_MAP_CHAR_HEIGHT
        sta cm_calcTemp1
        lda cm_CurrentCharScrollYPosition
        sta cm_calcTemp2
        jsr CMAddTwo8Bit
        //-------------------------------------------------
        // check if we have reached the last row of the map display
        //-------------------------------------------------
        cpy cm_calcTemp2 //  have reached the last row
        bne drawmap_windowed_row
        rts

MoveMapAndPrintPointersForNewRow:
        // Starting a new row set the X values to the start of the row
        lda cm_CurrentCharScrollXPosition               // instead of starting at 0 we start at how far right we are scrolled #$00
        sta cm_CurrentMapCharX                          // store the map char y position we are going to read from

        lda #CM_DISPLAYED_MAP_X
        sta cm_CurrentDisplayX                          // cm_CurrentDisplayX is always CM_DISPLAYED_MAP_X based

        lda cm_CurrentMapCharY
        cmp cm_CurrentCharScrollYPosition
        beq skipsub2

        // move the map_char_pointer to the start of the correct row
        // first add the map char width, which get us into the next row
        clc
        lda cm_CurrentMapCharPointer                    // Load pointer low byte
        adc #CM_MAP_CHAR_WIDTH                          // Add width in bytes of the map 
        sta cm_CurrentMapCharPointer                    // Store back to pointer low byte
        lda cm_CurrentMapCharPointer+1                  // Load pointer high byte
        adc #$00                                        // Add 0 high byte (plus any carry)
        sta cm_CurrentMapCharPointer+1                  // Store back to pointer high byte

        // next subtract the display map width to get to the correct column within the row
        lda cm_CurrentMapCharY
        cmp cm_CurrentCharScrollYPosition
        beq skipsub1
        sec                                             // Set carry for subtraction
        lda cm_CurrentMapCharPointer                    // Load low byte of pointer
        sbc #CM_DISPLAYED_MAP_CHAR_WIDTH                // Subtract display map char width
        sta cm_CurrentMapCharPointer                    // Store back to low byte
        lda cm_CurrentMapCharPointer+1                  // Load high byte of pointer
        sbc #$00                                        // Subtract 0 high byte (with borrow)
        sta cm_CurrentMapCharPointer+1                  // Store back to high byte
skipsub1:
        // move the print char pointer to the start of the correct row on screen
        // first add the screen char width, which get us into the next row
        lda cm_CurrentMapCharY
        cmp cm_CurrentCharScrollYPosition
        beq skipsub2
        clc
        lda cm_CurrentScreenCharPointer                 // Load pointer low byte
        adc #VIC_SCREEN_WIDTH_COLS                      // Add screen char width
        sta cm_CurrentScreenCharPointer                 // Store back to pointer low byte
        lda cm_CurrentScreenCharPointer+1               // Load pointer high byte
        adc #$00                                        // Add 0 high byte (plus any carry)
        sta cm_CurrentScreenCharPointer+1               // Store back to pointer high byte

        // next subtract the display map width to get to the correct column within the row
        lda cm_CurrentMapCharY
        cmp cm_CurrentCharScrollYPosition
        beq skipsub2
        sec                                             // Set carry for subtraction
        lda cm_CurrentScreenCharPointer                 // Load low byte of pointer
        sbc #CM_DISPLAYED_MAP_CHAR_WIDTH                // Subtract total x offset
        sta cm_CurrentScreenCharPointer                 // Store back to low byte
        lda cm_CurrentScreenCharPointer+1               // Load high byte of pointer
        sbc #$00                                        // Subtract 0 high byte (with borrow)
        sta cm_CurrentScreenCharPointer+1               // Store back to high byte
skipsub2:
        // instead of recalculating the color pointer from scratch, we just add the color
        // memory offset to the cm_CurrentScreenCharPointer because they are the exact 
        // same size
        clc
        lda cm_CurrentScreenCharPointer                 // Load pointer low byte
        adc #<$D400                                     // Add product low byte
        sta cm_CurrentScreenCharColorPointer            // Store back to pointer low byte
        lda cm_CurrentScreenCharPointer+1               // Load pointer high byte
        adc #>$D400                                     // Add 0 high byte (plus any carry)
        sta cm_CurrentScreenCharColorPointer+1          // Store back to pointer high byte

        // move the print char pointer to the start of the correct row on screen
        // first add the screen char width, which get us into the next row
/*        lda cm_CurrentMapCharY
        cmp cm_CurrentCharScrollYPosition
        beq skipsub3
        clc
        lda cm_CurrentScreenCharColorPointer     // Load pointer low byte
        adc #VIC_SCREEN_WIDTH_COLS       // Add product low byte
        sta cm_CurrentScreenCharColorPointer     // Store back to pointer low byte
        lda cm_CurrentScreenCharColorPointer+1   // Load pointer high byte
        adc #$00                         // Add 0 high byte (plus any carry)
        sta cm_CurrentScreenCharColorPointer+1   // Store back to pointer high byte

        // next subtract the display map width to get to the correct column within the row
        lda cm_CurrentMapCharY
        cmp cm_CurrentCharScrollYPosition
        beq skipsub3
        sec                              // Set carry for subtraction
        lda cm_CurrentScreenCharColorPointer     // Load low byte of pointer
        sbc #CM_DISPLAYED_MAP_CHAR_WIDTH         // Subtract low byte of constant
        sta cm_CurrentScreenCharColorPointer     // Store back to low byte
        lda cm_CurrentScreenCharColorPointer+1   // Load high byte of pointer
        sbc #$00                         // Subtract 0 high byte (with borrow)
        sta cm_CurrentScreenCharColorPointer+1   // Store back to high byte
*/
skipsub3:
row_zero_skip:
        rts
}