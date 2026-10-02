// =============================================================================
// macros specifically for handling charmap maps
// =============================================================================

// =============================================================================
// fill the screen with a specific character
// =============================================================================
.macro ClearScreenDblBuf(charcode) {
        // if buffer A is currently visible, clear B
        lda cm_VisibleBuffer
        cmp #'A'
        bne cleara

        lda #charcode     // Load value charcode into accumulator
        ldx #$00          // Initialize X register to 0
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
        inx               // Increment X register
        bne clear_loopB    // Loop 256 times until X rolls back to 0
        jmp clearDone

cleara:
        lda #charcode     // Load value charcode into accumulator
        ldx #$00          // Initialize X register to 0
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
        
        inx               // Increment X register
        bne clear_loopA    // Loop 256 times until X rolls back to 0
clearDone:
}


// =============================================================================
// Use this macro to draw the current windowed view of the charmap on the screen
// =============================================================================
.macro CMDrawMapWindowed() {
        jsr CMDrawMapWindowed
}

// =============================================================================
//  use this macro to smoothly scroll the map to the left by one pixel
// =============================================================================
.macro CMHorizontalSmoothScrollRightOnePixel() {
//.break
        lda #CM_SCROLL_RIGHT
        sta cm_LeftOrRight
        lda cm_xFineScroll
        cmp #8    
        beq CoarseScroll     // If fine scroll is negative, go to coarse scroll. don't check for zero, we have to draw the screen when the fine scroll is zero
        jmp skipCoarseScroll  // If xscroll is still positive, continue fine scrolling

CoarseScroll:
        // instead of drawing the entire screen we set cm_drawColumnJump to #CM_DISPLAYED_MAP_CHAR_WIDTH
        // Use that value in the CMDrawMapWindowed routine to skip drawing columns that are not needed, in this case only draw the last column
        // for all of the columns except the last one, we copy them to the left to avoid all the pointer calculations and optimize performance
        ldx #1
        stx cm_drawColumnJump

        CMDecMapXCharOffset()                                   // scroll right one character column

        lda cm_VisibleBuffer
        cmp #'A'
        bne doAFirst // B is the back buffer, draw it first
doBFirst:
//.break
        jsr shift_screen_right_clr_start
        jsr shift_screen_right_b         // shift the back buffer left by one char leaving the last column dirty
        CMDrawMapWindowed()             // draw only the last column as specified by cm_drawColumnJump
        jsr shift_screen_right_a         // shift the back buffer left by one char leaving the last column dirty
        CMFlipBuffer()
        CMDrawMapWindowed()             // draw only the last column as specified by cm_drawColumnJump
        jmp resetFineScroll
doAFirst:
        jsr shift_screen_right_clr_start
        jsr shift_screen_right_a         // shift the back buffer left by one char leaving the last column dirty
        CMDrawMapWindowed()             // draw only the last column as specified by cm_drawColumnJump
        jsr shift_screen_right_b         // shift the back buffer left by one char leaving the last column dirty
        CMFlipBuffer()
        CMDrawMapWindowed()             // draw only the last column as specified by cm_drawColumnJump
        jmp resetFineScroll

resetFineScroll:
        // Reset fine scroll hardware register back to 0
        lda #0
        sta cm_xFineScroll
        CMSetFineScroll()
        jmp done

skipCoarseScroll:
        CMSetFineScroll()
        inc cm_xFineScroll
done:
}

// =============================================================================
//  use this macro to smoothly scroll the map to the left by one pixel
// =============================================================================
.macro CMHorizontalSmoothScrollLeftOnePixel() {
        lda #CM_SCROLL_LEFT
        sta cm_LeftOrRight
        lda cm_xFineScroll    
        bmi CoarseScroll     // If fine scroll is negative, go to coarse scroll. don't check for zero, we have to draw the screen when the fine scroll is zero
        jmp skipCoarseScroll  // If xscroll is still positive, continue fine scrolling

CoarseScroll:
        // instead of drawing the entire screen we set cm_drawColumnJump to #CM_DISPLAYED_MAP_CHAR_WIDTH
        // Use that value in the CMDrawMapWindowed routine to skip drawing columns that are not needed, in this case only draw the last column
        // for all of the columns except the last one, we copy them to the left to avoid all the pointer calculations and optimize performance
        ldx #CM_DISPLAYED_MAP_CHAR_WIDTH-1
        stx cm_drawColumnJump

        CMIncMapXCharOffset()                                   // scroll left one character column

        lda cm_VisibleBuffer
        cmp #'A'
        bne doAFirst // B is the back buffer, draw it first
doBFirst:
        jsr shift_screen_left_clr_start
        jsr shift_screen_left_b         // shift the back buffer left by one char leaving the last column dirty
        CMDrawMapWindowed()             // draw only the last column as specified by cm_drawColumnJump
        jsr shift_screen_left_a         // shift the back buffer left by one char leaving the last column dirty
        CMFlipBuffer()
        CMDrawMapWindowed()             // draw only the last column as specified by cm_drawColumnJump
        jmp resetFineScroll
doAFirst:
        jsr shift_screen_left_clr_start
        jsr shift_screen_left_a         // shift the back buffer left by one char leaving the last column dirty
        CMDrawMapWindowed()             // draw only the last column as specified by cm_drawColumnJump
        jsr shift_screen_left_b         // shift the back buffer left by one char leaving the last column dirty
        CMFlipBuffer()
        CMDrawMapWindowed()             // draw only the last column as specified by cm_drawColumnJump
        jmp resetFineScroll

resetFineScroll:
        // Reset fine scroll hardware register back to 7
        lda #7
        sta cm_xFineScroll
        CMSetFineScroll()
        jmp done

skipCoarseScroll:
        CMSetFineScroll()
        dec cm_xFineScroll
done:
}

.macro CMSetFineScroll() {
        lda VIC_SCREEN_REG_CONTROL2_ADDR
        and #%11111000
        ora cm_xFineScroll
        sta VIC_SCREEN_REG_CONTROL2_ADDR
}

//--------------------------------------------
// flip which buffer is currently visible and which one is the back buffer
//--------------------------------------------
.macro CMFlipBuffer() {
        // if buffer A is currently visible, switch to B, otherwise switch to A
        lda cm_VisibleBuffer
        cmp #'A'
        bne aBufferCurrentlyVisible

bBufferCurrentlyVisible:
        lda VIC_SCREEN_REG_MEMORY_CONTROL_ADDR
        and #$0F         // Clear the upper 4 bits (keep character memory settings)
        ora #$30         // Set upper 4 bits to %0011 (points screen RAM to $0C00)
        sta VIC_SCREEN_REG_MEMORY_CONTROL_ADDR

        lda #'B'
        sta cm_VisibleBuffer
        jmp flipDone
aBufferCurrentlyVisible:
        lda VIC_SCREEN_REG_MEMORY_CONTROL_ADDR
        and #$0F         // Clear the upper 4 bits (keep character memory settings)
        ora #$10         // Set upper 4 bits to %0001 (points screen RAM to $0400)
        sta VIC_SCREEN_REG_MEMORY_CONTROL_ADDR

        lda #'A'
        sta cm_VisibleBuffer
flipDone:
}

//--------------------------------------------
// Wait for vertical blank
//--------------------------------------------
.macro CMRasterWait() {
rasterWaitLoop:
        lda VIC_SCREEN_RASTER_LINE_ADDR         // Read current VIC-II raster line counter
        cmp #$fb                                // Check if it reached line 251 ($FB)
        bne rasterWaitLoop                      // Keep busy-waiting if it hasn't reached it yet
}

// =============================================================================
// You should call this macro at the start of your program to initialize the 
// charmap code before using any other charmap macros
// =============================================================================
.macro CMInitCharMapCode() {
        jsr CMInitMemoryPointers                      // Initialize memory pointers for screen and map data
        jsr CMInitZeroPageVariables                   // Initialize zero-page variables
}

// =============================================================================
// 
// =============================================================================
.macro CMSetMapCharOffset(x, y) {
        lda x
        sta cm_CurrentCharScrollXPosition
        lda y
        sta cm_CurrentCharScrollYPosition
}

// =============================================================================
// Scroll the map horizontally by one character in the X direction. The map moves
// to left on the screen
// =============================================================================
.macro CMIncMapXCharOffset() {
        inc cm_CurrentCharScrollXPosition
        lda #CM_SCROLL_LEFT
        sta cm_LeftOrRight
}

// =============================================================================
// Scroll the map horizontally by one character in the X direction. The map moves
// to right on the screen
// =============================================================================
.macro CMDecMapXCharOffset() {
        dec cm_CurrentCharScrollXPosition
        lda #CM_SCROLL_RIGHT
        sta cm_LeftOrRight
}

// =============================================================================
// Jump to the horizontal scroll position passed in.
// =============================================================================
.macro CMSetMapXCharOffset(x) {
        lda #x
        sta cm_CurrentCharScrollXPosition
}

// =============================================================================
// Jump to the vertical scroll position passed in.
// =============================================================================
.macro CMSetMapYCharOffset(y) {
        lda y
        sta cm_CurrentCharScrollYPosition
}

// =============================================================================
// 
// =============================================================================
.macro CMSetMapCharOffsetLiterals(x, y) {
        lda #x
        sta cm_CurrentCharScrollXPosition
        lda #y
        sta cm_CurrentCharScrollYPosition
}