// =============================================================================
// macros specifically for handling charmap maps.  mnost of these just jsr
// to call the corresponding subroutines defined in the charmap code.
// =============================================================================

// =============================================================================
// Default game initialization macro for setting up the C64 environment and charmap
// This macro sets up the C64 environment, including disabling BASIC, KERNAL, and 
// the character generator, setting colors, enabling multicolor and 38-column modes, 
// setting the charset address, and initializing the charmap code. 
// =============================================================================
.macro SmoothGameInit() {
        sei
        KillBASIC()                                             // Disable BASIC to free up RAM
        KillKernal()                                            // Disable KERNAL ROM to free up RAM
        KillCharacterGenerator()                                // Disable Character Generator ROM to free up RAM
        SetColors(BLACK, BLUE, ORANGE, LIGHT_GREEN, BROWN)     // Set border and background colors that get used for the map chars
        SetMulticolorMode()                                     // Enable multicolor mode
        Set38ColumnMode()                                       // Enable 38-column mode
        SetLowerCaseCharsetMode()                               // make sure we using a charset with upper and lower case characters for the screen codes
        SetCharsetAddress(VIC_SCREEN_CHAR_BANK_OFFSET_10240)    // Set the address of the character set data this offset matches CHARSET_CHAR_DATA_ADDR $2800
        CMInitCharMapCode()                                     // always call this once before using any other charmap macros

        // Clear the screen using double buffering
        CMClearScreenDblBuf($20)
        CMClearScreenDblBuf($20)
        CMForceDrawMapWindowed()
        CMFlipBuffer()                         
        CMForceDrawMapWindowed()
        CMFlipBuffer()                         
}

.macro CoarseGameInit() {
        sei
        KillBASIC()                                             // Disable BASIC to free up RAM
        KillKernal()                                            // Disable KERNAL ROM to free up RAM
        KillCharacterGenerator()                                // Disable Character Generator ROM to free up RAM
        SetColors(BLACK, BLUE, ORANGE, LIGHT_GREEN, BROWN)     // Set border and background colors that get used for the map chars
        SetMulticolorMode()                                     // Enable multicolor mode
        SetLowerCaseCharsetMode()                               // make sure we using a charset with upper and lower case characters for the screen codes
        SetCharsetAddress(VIC_SCREEN_CHAR_BANK_OFFSET_10240)    // Set the address of the character set data this offset matches CHARSET_CHAR_DATA_ADDR $2800
        CMInitCharMapCode()                                     // always call this once before using any other charmap macros

        // Clear the screen using double buffering
        CMClearScreenDblBuf($20)
        CMClearScreenDblBuf($20)
        CMForceDrawMapWindowed()
        CMFlipBuffer()                         
        CMForceDrawMapWindowed()
        CMFlipBuffer()                         
}

// =============================================================================
// Fill the entire back buffer with a specific character and then flip the buffer to 
// make it visible. So if you want to clear the front and back buffers, call 
// this macro twice with the desired character code.
// =============================================================================
.macro CMClearScreenDblBuf(charcode) {
        lda cm_VisibleBuffer            // load the currently visible buffer ('A' or 'B')
        cmp #'A'                        // compare with 'A' to check if buffer A is visible
        bne cleara                      // if not 'A', then buffer B is visible, so clear A instead

        lda #charcode                   // Load value charcode into accumulator
        ldx #$00                        // Initialize X register to 0
clear_loopB:
        // Write 0 to 4 blocks of 250/256 bytes covering 1000 screen bytes
        sta VIC_SCREENB_CHAR_MEMORY_ADDR, x
        sta VIC_SCREENB_CHAR_MEMORY_ADDR + $100, x
        sta VIC_SCREENB_CHAR_MEMORY_ADDR + $200, x
        sta VIC_SCREENB_CHAR_MEMORY_ADDR + $300, x
        sta VIC_SCREEN_COLOR_MEMORY_ADDR, x
        sta VIC_SCREEN_COLOR_MEMORY_ADDR + $100, x
        sta VIC_SCREEN_COLOR_MEMORY_ADDR + $200, x
        sta VIC_SCREEN_COLOR_MEMORY_ADDR + $300, x
        inx                             // Increment X register, to move to the next screen column
        bne clear_loopB                 // Loop 256 times until X rolls back to 0
        jmp clearDone

cleara:
        lda #charcode                   // Load value charcode into accumulator
        ldx #$00                        // Initialize X register to 0
clear_loopA:
        // Write 0 to 4 blocks of 250/256 bytes covering 1000 screen bytes
        sta VIC_SCREEN_CHAR_MEMORY_ADDR, x
        sta VIC_SCREEN_CHAR_MEMORY_ADDR + $100, x
        sta VIC_SCREEN_CHAR_MEMORY_ADDR + $200, x
        sta VIC_SCREEN_CHAR_MEMORY_ADDR + $300, x
        sta VIC_SCREEN_COLOR_MEMORY_ADDR, x
        sta VIC_SCREEN_COLOR_MEMORY_ADDR + $100, x
        sta VIC_SCREEN_COLOR_MEMORY_ADDR + $200, x
        sta VIC_SCREEN_COLOR_MEMORY_ADDR + $300, x
        
        inx                             // Increment X register, to move to the next screen column
        bne clear_loopA                 // Loop 256 times until X rolls back to 0
clearDone:
        jsr CMFlipBuffer                  // Flip the visible buffer to show the cleared screen

}


// =============================================================================
// Use this macro to draw the current windowed view of the charmap on the screen
// back buffer. This will only draw either the right or left column of the visible
// map area 
// =============================================================================
.macro CMDrawMapWindowed() {
        jsr CMDrawMapWindowed
}

// =============================================================================
// Use this macro to draw the current windowed view of the charmap on the screen
// back buffer. This will draw the entire visible map area, regardless of 
// cm_drawColumnJump value.
// =============================================================================
.macro CMForceDrawMapWindowed() {
        jsr CMForceDrawMapWindowed
}


// =============================================================================
// This macro sets the fine scroll hardware register based on the current value
// of cm_xFineScroll.
//
// NOTE: You would normally not call this directly it is use internally by the 
// charmap code.
// =============================================================================
.macro CMSetFineScroll() {
        lda VIC_SCREEN_REG_CONTROL2_ADDR
        and #%11111000
        ora cm_xFineScroll
        sta VIC_SCREEN_REG_CONTROL2_ADDR
}

// =============================================================================
// Use this macro to smoothly scroll the map to the left by one pixel. By left
// I mean the map will visually move to the left, revealing new columns on the 
// right side of the screen.  In game this typically happens when the player moves 
// to the right.
//
// When a full new column is displayed the existing screen contents are copied
// to the left by one column and the emptied column on the right is filled with 
// new data. To maintain a smooth scrolling effect the hardware fine scroll 
// register is used.
// =============================================================================
.macro CMHorizontalSmoothScrollLeft() {
        jsr CMHorizontalSmoothScrollLeft
}

.macro CMHorizontalScrollLeft() {
        jsr CMHorizontalScrollLeft
}

// =============================================================================
// Use this macro to smoothly scroll the map to the right by one pixel. By right
// I mean the map will visually move to the right, revealing new columns on the 
// left side of the screen.  In game this typically happens when the player moves 
// to the left.
//
// When a full new column is displayed the existing screen contents are copied
// to the right by one column and the emptied column on the left is filled with 
// new data. To maintain a smooth scrolling effect the hardware fine scroll 
// register is used.
// =============================================================================
.macro CMHorizontalSmoothScrollRight() {
        jsr CMHorizontalSmoothScrollRight
} 

.macro CMHorizontalScrollRight() {
        jsr CMHorizontalScrollRight
}

// =============================================================================
// Flip which screen buffer is currently visible and which one is the back buffer.
//
// NOTE: You would normally not call this directly it is use internally by the 
// charmap code.
// =============================================================================
.macro CMFlipBuffer() {
        jsr CMFlipBuffer
}

// =============================================================================
// Wait for vertical blank
// TODO make this take an argument
// =============================================================================
.macro CMRasterWait() {
rasterWaitLoop:
        lda VIC_SCREEN_RASTER_LINE_ADDR         // Read current VIC-II raster line counter
        cmp #$fb                                // Check if it reached line 251 ($FB)
        bne rasterWaitLoop                      // Keep busy-waiting if it hasn't reached it yet
}

// =============================================================================
// You should call this macro at the start of your program to initialize the 
// charmap code before using any other charmap macros.  This will set up 
// necessary memory pointers and zero-page variables.
// =============================================================================
.macro CMInitCharMapCode() {
        jsr CMInitMemoryPointers                      // Initialize memory pointers for screen and map data
        jsr CMInitZeroPageVariables                   // Initialize zero-page variables
}

// =============================================================================
// TODO:
// =============================================================================
.macro CMSetMapCharOffset(x, y) {
        lda x
        sta cm_CurrentCharScrollXPosition
        lda y
        sta cm_CurrentCharScrollYPosition
}

// =============================================================================
// Scroll the map horizontally by one column in the X direction. The map moves
// to left on the screen
//
// NOTE: You would normally not call this directly it is use internally by the 
// charmap code.
// =============================================================================
.macro CMIncMapXCharOffset() {
        inc cm_CurrentCharScrollXPosition
        lda #CM_SCROLL_LEFT
        sta cm_LeftOrRight
}

// =============================================================================
// Scroll the map horizontally by one column in the X direction. The map moves
// to right on the screen.
//
// NOTE: You would normally not call this directly it is use internally by the 
// charmap code.
// =============================================================================
.macro CMDecMapXCharOffset() {
        dec cm_CurrentCharScrollXPosition
        lda #CM_SCROLL_RIGHT
        sta cm_LeftOrRight
}

// =============================================================================
// Force the map to jump to the specified horizontal scroll position. The map 
// will be redrawn accordingly.
// =============================================================================
.macro CMSetMapXCharOffset(x) {
        lda #x
        sta cm_CurrentCharScrollXPosition
        jsr CMForceDrawMapWindowed
        jsr CMFlipBuffer
        jsr CMForceDrawMapWindowed
}

// =============================================================================
// Force the map to jump to the specified vertical scroll position. The map 
// will be redrawn accordingly.
// =============================================================================
.macro CMSetMapYCharOffset(y) {
        lda #y
        sta cm_CurrentCharScrollYPosition
        jsr CMForceDrawMapWindowed
        jsr CMFlipBuffer
        jsr CMForceDrawMapWindowed
}

// =============================================================================
// TODO: 
// =============================================================================
.macro CMSetMapCharOffsetLiterals(x, y) {
        lda #x
        sta cm_CurrentCharScrollXPosition
        lda #y
        sta cm_CurrentCharScrollYPosition
}