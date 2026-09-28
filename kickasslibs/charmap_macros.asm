// =============================================================================
// macros specifically for handling charmap maps
// =============================================================================

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
        lda VIC_SCREEN_REG_CONTROL2_ADDR
        and VSRC2B_SMOOTH_SCROLLX_BITS  // Mask out the fine scroll bits (0-7)
        beq coarse_scroll_right
        inc VIC_SCREEN_REG_CONTROL2_ADDR // Fine scroll: just increment the register value to move pixels right

coarse_scroll_right:
        CMDecMapXCharOffset()
        CMDrawMapWindowed()

        // Reset fine scroll hardware register back to 7
        lda VIC_SCREEN_REG_CONTROL2_ADDR
        eor #VSRC2B_SMOOTH_SCROLLX_BITS
        sta VIC_SCREEN_REG_CONTROL2_ADDR
done:
}

// =============================================================================
//  use this macro to smoothly scroll the map to the left by one pixel
// =============================================================================
.macro CMHorizontalSmoothScrollLeftOnePixel() {
        lda VIC_SCREEN_REG_CONTROL2_ADDR
        and #VSRC2B_SMOOTH_SCROLLX_BITS  // Mask out the fine scroll bits (0-7)
        beq coarse_scroll_left
        dec VIC_SCREEN_REG_CONTROL2_ADDR // Fine scroll: just decrement the register value to move pixels left
        jmp done

coarse_scroll_left:
        CMIncMapXCharOffset()
        jsr shift_screen_left

        // instead of drawing the entire screen we set cm_drawColumnJump to #CM_DISPLAYED_MAP_CHAR_WIDTH
        // Use that value in the CMDrawMapWindowed routine to skip drawing columns that are not needed, in this case only draw the last column
//****        lda #CM_DISPLAYED_MAP_CHAR_WIDTH-1
//****        sta cm_drawColumnJump
        
        CMDrawMapWindowed()

        // then we set cm_drawColumnJump back to zero
//****        lda #$00
//****        sta cm_drawColumnJump

        // Reset fine scroll hardware register back to 7
        lda VIC_SCREEN_REG_CONTROL2_ADDR
        eor #VSRC2B_SMOOTH_SCROLLX_BITS
        sta VIC_SCREEN_REG_CONTROL2_ADDR
done:
}

//--------------------------------------------
// Wait for vertical blank
//--------------------------------------------
/*sync_vblank:
        lda VIC_SCREEN_REG_CONTROL1_ADDR
        bpl sync_vblank
!:      lda VIC_SCREEN_REG_CONTROL1_ADDR
        bmi !-
        rts
*/
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
}

// =============================================================================
// Scroll the map horizontally by one character in the X direction. The map moves
// to right on the screen
// =============================================================================
.macro CMDecMapXCharOffset() {
        dec cm_CurrentCharScrollXPosition
}

// =============================================================================
// Jump to the horizontal scroll position passed in.
// =============================================================================
.macro CMSetMapXCharOffset(x) {
        lda x
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