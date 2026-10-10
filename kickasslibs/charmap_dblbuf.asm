// =============================================================================
// Primary code file for code that displays and manipulates Charmap map data.
//
// This uses look up tables to avoid repeated pointer calculations inside the loops. 
//It can be used by
// uncommenting the imnport line for it in the charmap_import.asm file.  Make sure to
// comment out the other versrion that may be being imported.
// the generated look up tables are in the charmap_tables.asm file
//
// *********** This is MUCH faster than the previous versions. *********** 
//
// this time in addition to using the LUTs we are also reversing the loops for 
// further optimization.  instead of drawing the map from top to bottom and then
// left to right, we draw it in reverse order.  This removes a huge number of 
// calculations per character.  Also we are unrolling some of the loops to further 
// reduce overhead.
// 
// removed a lot of the initialization code that was present in the previous versions
// as well as removing a lot of the zero page variables that are not needed by this code.
//
// I'm sure there are still more optimizations that could be made, but right now I'm
// kind of fried from lookling at it.
// =============================================================================

//============================================================================================================================
// constants specific to this code
//============================================================================================================================
.const CM_MAP_LEVEL_DATA_ADDR = $3a00           // where the map file from charpad gets loaded - 6000 bytes for a 240x25 map
.const CM_CHARSET_ATTRIB_DATA_ADDR = $5400      // where the charset color file from charpad gets loaded - 256 bytes used
.const CM_CHARSET_CHAR_DATA_ADDR = $2800        // where the charset file from charpad gets loaded - 2048 bytes used
.const CM_LOOKUP_TABLES_ADDR = $1000            // where lookup tables are loaded
.const CM_SCROLL_STOP = 5
.const CM_SCROLL_LEFT = 1
.const CM_SCROLL_RIGHT = 0
.const CM_SCROLL_UP = 1                         // TODO: vertical scrolling not yet implemented
.const CM_SCROLL_DOWN = 0

//============================================================================================================================
// Zero-page storage for our calculated 16-bit pointers
// the skipped zero-page locations are used for other purposes by the system and are not safe for our use
//============================================================================================================================
.var cm_CurrentMapCharPointer = $02             // pointer to the map character data
.var cm_CurrentMapCharColorPointer = $04        // pointer to the map color data
.var cm_CurrentScreenCharPointer = $12          // this is the pointer to the current memory location that we need to place a character at
.var cm_CurrentScreenCharColorPointer = $14     // this is the pointer to the current memory location that we need to place a character color at
.var cm_VisibleBuffer = $16                     // which buffer is currently visible, "A" or "B"
.var cm_xFineScroll = $20                       // fine scroll value for horizontal scrolling
.var cm_yFineScroll = $21                       // fine scroll value for vertical scrolling
.var cm_LeftOrRight = $22                       // indicates left or right scrolling direction CM_SCROLL_LEFT/CM_SCROLL_RIGHT
.var cm_UpOrDown = $23                          // indicates up or down scrolling direction CM_SCROLL_UP/CM_SCROLL_DOWN

//============================================================================================================================
// Zero-page storage locations for our variables
// the skipped zero-page locations are used for other purposes by the syhstem and are not safe for our use
//============================================================================================================================
.var cm_calcTemp1 = $42
.var cm_calcTemp2 = $44
.var cm_calcTemp3 = $46
.var cm_calcTemp4 = $48                         // this is used in CMMultiplyTwo8bit which may end up never being used
.var cm_CurrentCharScrollXPosition = $50        // which map column do we display in the left most display column
.var cm_CurrentCharScrollYPosition = $51        // which map row do we display in the top most display row
.var cm_drawColumnJump = $52                    // used to skip drawing columns under certain conditions
.var cm_drawColumnJumpSave = $53                    // used to skip drawing columns under certain conditions

//============================================================================================================================
// init zero-page variables
//============================================================================================================================
CMInitMemoryPointers:
        lda #<CM_CHARSET_ATTRIB_DATA_ADDR
        sta cm_CurrentMapCharColorPointer
        lda #>CM_CHARSET_ATTRIB_DATA_ADDR
        sta cm_CurrentMapCharColorPointer + 1
        lda #'A'
        sta cm_VisibleBuffer
        rts

//============================================================================================================================
// init zero-page variables
//============================================================================================================================
CMInitZeroPageVariables: {
        lda #$00
        sta cm_CurrentCharScrollXPosition
        sta cm_CurrentCharScrollYPosition
        sta cm_drawColumnJump

        lda #7
        sta cm_xFineScroll

        lda #CM_SCROLL_STOP
        sta cm_LeftOrRight
        sta cm_drawColumnJumpSave
        rts
}

//============================================================================================================================
// This is the routine to draw the map, windowed on the screen.  It draws the entire map window area.
// You normally won't call this except maybe for the first display of the map window.
//============================================================================================================================
CMForceDrawMapWindowed: {
        lda #0                                          // initialize the column jump save to 0
        sta cm_drawColumnJumpSave                       // save the initial column jump value

        // Loop through ROWS first (X register = screen row)
        ldx #CM_DISPLAYED_MAP_Y                         // set X to the number of displayed map rows
        lda #$00                                        // save the number of rows we have drawn so we can correctly calculate the map pointer for the next row
        sta cm_calcTemp1                                // keep track of how many rows have been drawn
CMDrawNextRow:
        ldy cm_drawColumnJumpSave                       // load the saved column jump value into Y
        sty cm_drawColumnJump                           // set the current column jump for this row

        // Calculate screen pointers ONCE per row, x=the row offset then add the screen xoffset
        lda tableScreenPointerLow, x                    // load the low byte of the screen pointer for this row from the lookup table
        clc
        adc #CM_DISPLAYED_MAP_X                         // add the screen column offset to the screen pointer low byte
        sta cm_CurrentScreenCharPointer+0               // store the low byte of the screen pointer
        sta cm_CurrentScreenCharColorPointer+0          // store the low byte of the color pointer

        lda cm_VisibleBuffer                            // load the visible buffer identifier (e.g., 'A' or 'B')
        cmp #'A'                                        // is A the visible buffer?
        bne !+                                          // no, B is the visible buffer
        lda tableCharScreenBPointerHigh, x              // get the high byte of the screen char pointer for buffer B from the lookup table
        sta cm_CurrentScreenCharPointer+1               // store the high byte of the screen pointer
        jmp !++         
!:
        lda tableCharScreenAPointerHigh, x              // get the high byte of the screen char pointer for buffer A from the lookup table
        sta cm_CurrentScreenCharPointer+1               // store the high byte of the screen pointer
!:
        lda tableColorScreenPointerHigh, x              // get the high byte of the color screen pointer for this row from the lookup table
        sta cm_CurrentScreenCharColorPointer+1          // store the high byte of the color pointer
        // figure out what we need to have as an index for the map char pointer
        lda cm_calcTemp1                                // how many rows we have already drawn                   
        sta cm_calcTemp2                                // store the row offset into cm_calcTemp2
        clc
        adc cm_CurrentCharScrollYPosition               // add the row scroll offset, this will have an effect when vertical scrolling is implemented
        sta cm_calcTemp2+0                              // update cm_calcTemp2 to hold the row offset into the map data
        bcc !+                                          // Branch if carry clear (no overflow from low byte), faster than doing the next 3 instructions
        // the carry was set, so we need to increment the high byte as well because we went past $FF in the low byte
        lda cm_calcTemp2+1                              // Load high byte
        adc #$00                                        // Add the carry flag (0 or 1)
        sta cm_calcTemp2+1                              // Save high byte back
!:
        // set the map char pointer to the map row that is at the top of the display area
        ldy cm_calcTemp2                                // use the row offset as an index into the map char pointer lookup table
        lda tableMapCharPointerLow, y                   // get the low byte of the map char pointer for this row from the lookup table
        sta cm_CurrentMapCharPointer+0                  // store the low byte of the map char pointer
        lda tableMapCharPointerHigh, y                  // get the high byte of the map char pointer for this row from the lookup table
        sta cm_CurrentMapCharPointer+1                  // store the high byte of the map char pointer

        lda #0                                          // initialize the column jump to 0 before drawing the scroll left loop
        sta cm_drawColumnJump                           // store the initial column jump value
        jsr draw_full_left_loop

        inc cm_calcTemp1                                // keep track of how many rows have been drawn
        inx                                             // keep track of which screen row we are on

        // check if we have drawn all the rows
        cpx #(CM_DISPLAYED_MAP_Y + CM_DISPLAYED_MAP_CHAR_HEIGHT)       
        bne dojmp // have to do it this way because the branch distance is limited
      
        rts
dojmp: jmp CMDrawNextRow                                     
}

//============================================================================================================================
// This is the routine to draw the map, windowed on the screen.  It draws only the left or right columns based on which part 
// of the window needs updating after scrolling.
//============================================================================================================================
CMDrawMapWindowed: {
        lda cm_drawColumnJump                           // load the column jump value
        sta cm_drawColumnJumpSave                       // save the column jump value for later use

        ldx #CM_DISPLAYED_MAP_Y                         // Loop through ROWS first (X register = screen row)
        lda #$00                                        // save the number of rows we have drawn so we can correctly calculate the map pointer for the next row
        sta cm_calcTemp1                                // keep track of how many rows have been drawn
CMDrawNextRow:
        ldy cm_drawColumnJumpSave                       // restore the column jump value
        sty cm_drawColumnJump                           // restore the column jump value

        // Calculate screen pointers ONCE per row, x=the row offset then add the screen xoffset
        lda tableScreenPointerLow, x                    // use the lookup table to get the low byte of the screen pointer for this row
        clc

        // right after this add the pointer is pointing at the left col of the display map window top row as if it is going to redraw the entire map area
        adc #CM_DISPLAYED_MAP_X                         // add the screen x offset to the low byte of the screen pointer
        sta cm_CurrentScreenCharPointer+0               // store the low byte of the screen char pointer
        sta cm_CurrentScreenCharColorPointer+0          // store the low byte of the screen char color pointer

        lda cm_VisibleBuffer                            // load the visible buffer identifier (e.g., 'A' or 'B')
        cmp #'A'                                        // is A the visible buffer? draw to buffer B when A is visible
        bne !+                                          // no, B is the visible buffer, draw to buffer A when B is visible
        lda tableCharScreenBPointerHigh, x              // get the high byte of the screen char pointer for buffer B from the lookup table
        sta cm_CurrentScreenCharPointer+1               // store the high byte of the screen char pointer for buffer B
        jmp !++         
!:
        lda tableCharScreenAPointerHigh, x              // get the high byte of the screen char pointer for buffer A from the lookup table
        sta cm_CurrentScreenCharPointer+1               // store the high byte of the screen char pointer for buffer A
!:
        lda tableColorScreenPointerHigh, x              // get the high byte of the screen color pointer from the lookup table
        sta cm_CurrentScreenCharColorPointer+1          // store the high byte of the screen color pointer
        
        // figure out what we need to have as an index for the map char pointer
        lda cm_calcTemp1                                // how many rows we have already drawn                   
        sta cm_calcTemp2                                // copy the row count to cm_calcTemp2
        clc
        adc cm_CurrentCharScrollYPosition               // add the row scroll offset, this will have an effect when vertical scrolling is implemented
        sta cm_calcTemp2+0                              // update cm_calcTemp2 to hold the row offset into the map data
        bcc !+                                          // Branch if carry clear (no overflow from low byte), faster than doing the next 3 instructions
        // the carry was set, so we need to increment the high byte as well because we went past $FF in the low byte
        lda cm_calcTemp2+1                              // Load high byte
        adc #$00                                        // Add the carry flag (0 or 1)
        sta cm_calcTemp2+1                              // Save high byte back, at this point cm_calcTemp2 holds the full row offset into the map data
!:
        // set the map char pointer to the map row that is at the top of the display area
        ldy cm_calcTemp2                                // use the row offset into the map data as the index for the lookup table
        lda tableMapCharPointerLow, y                   // get the low byte of the map char pointer from the lookup table
        sta cm_CurrentMapCharPointer+0                  // store the low byte of the map char pointer
        lda tableMapCharPointerHigh, y                  // get the high byte of the map char pointer from the lookup table
        sta cm_CurrentMapCharPointer+1                  // store the high byte of the map char pointer

        // decide which scroll direction to draw
        lda cm_LeftOrRight                              // load the current scroll direction
        cmp #CM_SCROLL_LEFT                             // check if the scroll direction is left
        bne !+                                          // if not, branch to the right scroll handling

        lda #(CM_DISPLAYED_MAP_CHAR_WIDTH + CM_DISPLAYED_MAP_X - 1)              // set the column jump for left scroll
        sta cm_drawColumnJump
        jsr draw_scroll_left_loop                       // call the left scroll drawing loop
        jmp !++                                         // jump past the right scroll handling
!:
        lda #1                                          // set the column jump for right scroll
        sta cm_drawColumnJump                           // store the column jump for right scroll
        jsr draw_scroll_right_loop                      // call the right scroll drawing loop
!:
        inc cm_calcTemp1                                // keep track of how many rows have been drawn
        inx                                             // keep track of which screen row we are on

        // check if we have drawn all the rows
        cpx #(CM_DISPLAYED_MAP_Y + CM_DISPLAYED_MAP_CHAR_HEIGHT)       
        bne dojmp // have to do it this way because the branch distance is limited, so we use a below jump instead of a branch
      
        rts
dojmp: jmp CMDrawNextRow                                     
}

//============================================================================================================================
// This is the loop for drawing the map when scrolling to the left. This is just the portion of the code that puts the map 
// characters and their colors on the screen.
//============================================================================================================================
draw_scroll_left_loop: {
        // calculate the column offset with scroll
        lda #CM_DISPLAYED_MAP_CHAR_WIDTH-1
        clc
        adc cm_CurrentCharScrollXPosition

        // Get the char to put on screen
        tay
        lda (cm_CurrentMapCharPointer), y               
        sta cm_calcTemp3 // save the char

        // put the char on screen
        ldy #CM_DISPLAYED_MAP_CHAR_WIDTH-1
        sta (cm_CurrentScreenCharPointer), y            
        
        // use the char as the index to the color
        ldy cm_calcTemp3 
        lda (cm_CurrentMapCharColorPointer), y

        // put color on screen
        ldy #CM_DISPLAYED_MAP_CHAR_WIDTH-1
        sta (cm_CurrentScreenCharColorPointer), y    
        rts
}

draw_full_left_loop: {
        .for(var col = 0; col < CM_DISPLAYED_MAP_CHAR_WIDTH; col++) {
                lda cm_drawColumnJump
                cmp #0
                bne !+

                // calculate the column offset with scroll
                lda #col
                clc
                adc cm_CurrentCharScrollXPosition

                // Get the char to put on screen
                tay
                lda (cm_CurrentMapCharPointer), y               
                sta cm_calcTemp3 // save the char

                // put the char on screen
                ldy #col
                sta (cm_CurrentScreenCharPointer), y            
                
                // use the char as the index to the color
                ldy cm_calcTemp3 
                lda (cm_CurrentMapCharColorPointer), y

                // put color on screen
                ldy #col
                sta (cm_CurrentScreenCharColorPointer), y    
                jmp !++
!:                
                dec cm_drawColumnJump
!:
        }
        rts
}

//============================================================================================================================
// This is the loop for drawing the map when scrolling to the right. This is just the portion of the code that puts the map 
// characters and their colors on the screen.
//============================================================================================================================
draw_scroll_right_loop: {
        // calculate the column offset with scroll
        lda #0
        clc
        adc cm_CurrentCharScrollXPosition

        // Get the char to put on screen
        tay
        lda (cm_CurrentMapCharPointer), y               
        sta cm_calcTemp3 // save the char

        // put the char on screen
        ldy #0
        sta (cm_CurrentScreenCharPointer), y            
        
        // use the char as the index to the color
        ldy cm_calcTemp3 
        lda (cm_CurrentMapCharColorPointer), y

        // put color on screen
        ldy #0
        sta (cm_CurrentScreenCharColorPointer), y    
        rts
}

CMHorizontalScrollRight:{
        lda #CM_SCROLL_RIGHT
        sta cm_LeftOrRight
CoarseScroll:
        // instead of drawing the entire screen we set cm_drawColumnJump to #CM_DISPLAYED_MAP_CHAR_WIDTH
        // Use that value in the CMDrawMapWindowed routine to skip drawing columns that are not needed, in this case only draw the last column
        // for all of the columns except the last one, we copy them to the left to avoid all the pointer calculations and optimize performance
        ldx #0
        stx cm_drawColumnJump

        CMDecMapXCharOffset()                                   // scroll right one character column

        lda cm_VisibleBuffer
        cmp #'A'
        bne doAFirst // B is the back buffer, draw it first
doBFirst:
        jsr shift_screen_right_clr_start
        jsr shift_screen_right_b         // shift the back buffer left by one char leaving the last column dirty
        CMDrawMapWindowed()             // draw only the last column as specified by cm_drawColumnJump
        jsr shift_screen_right_a         // shift the back buffer left by one char leaving the last column dirty
        jsr CMFlipBuffer
        CMDrawMapWindowed()             // draw only the last column as specified by cm_drawColumnJump
        jmp done
doAFirst:
        jsr shift_screen_right_clr_start
        jsr shift_screen_right_a         // shift the back buffer left by one char leaving the last column dirty
        CMDrawMapWindowed()             // draw only the last column as specified by cm_drawColumnJump
        jsr shift_screen_right_b         // shift the back buffer left by one char leaving the last column dirty
        jsr CMFlipBuffer
        CMDrawMapWindowed()             // draw only the last column as specified by cm_drawColumnJump
 
done:
        rts
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
CMHorizontalSmoothScrollRight:{
        lda #CM_SCROLL_RIGHT
        sta cm_LeftOrRight
        lda cm_xFineScroll
        cmp #7
        beq CoarseScroll     // If fine scroll is 7, go to coarse scroll.
        jmp skipCoarseScroll  // If xscroll is still positive, continue fine scrolling

CoarseScroll:
        // instead of drawing the entire screen we set cm_drawColumnJump to #CM_DISPLAYED_MAP_CHAR_WIDTH
        // Use that value in the CMDrawMapWindowed routine to skip drawing columns that are not needed, in this case only draw the last column
        // for all of the columns except the last one, we copy them to the left to avoid all the pointer calculations and optimize performance
        ldx #0
        stx cm_drawColumnJump

        CMDecMapXCharOffset()                                   // scroll right one character column

        lda cm_VisibleBuffer
        cmp #'A'
        bne doAFirst // B is the back buffer, draw it first
doBFirst:
        jsr shift_screen_right_clr_start
        jsr shift_screen_right_b         // shift the back buffer left by one char leaving the last column dirty
        CMDrawMapWindowed()             // draw only the last column as specified by cm_drawColumnJump
        jsr shift_screen_right_a         // shift the back buffer left by one char leaving the last column dirty
        jsr CMFlipBuffer
        CMDrawMapWindowed()             // draw only the last column as specified by cm_drawColumnJump
        jmp resetFineScroll
doAFirst:
        jsr shift_screen_right_clr_start
        jsr shift_screen_right_a         // shift the back buffer left by one char leaving the last column dirty
        CMDrawMapWindowed()             // draw only the last column as specified by cm_drawColumnJump
        jsr shift_screen_right_b         // shift the back buffer left by one char leaving the last column dirty
        jsr CMFlipBuffer
        CMDrawMapWindowed()             // draw only the last column as specified by cm_drawColumnJump
        jmp resetFineScroll

resetFineScroll:
        // Reset fine scroll hardware register back to 0
        lda #0
        sta cm_xFineScroll
        CMSetFineScroll()
        inc cm_xFineScroll
        jmp done

skipCoarseScroll:
        CMSetFineScroll()
        inc cm_xFineScroll
done:
        rts
}

CMHorizontalScrollLeft:  {
        lda #CM_SCROLL_LEFT
        sta cm_LeftOrRight
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
        jsr CMFlipBuffer
        CMDrawMapWindowed()             // draw only the last column as specified by cm_drawColumnJump
        jmp done
doAFirst:
        jsr shift_screen_left_clr_start
        jsr shift_screen_left_a         // shift the back buffer left by one char leaving the last column dirty
        CMDrawMapWindowed()             // draw only the last column as specified by cm_drawColumnJump
        jsr shift_screen_left_b         // shift the back buffer left by one char leaving the last column dirty
        jsr CMFlipBuffer
        CMDrawMapWindowed()             // draw only the last column as specified by cm_drawColumnJump
done:
        rts
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
CMHorizontalSmoothScrollLeft:  {
        lda #CM_SCROLL_LEFT
        sta cm_LeftOrRight
        lda cm_xFineScroll    
        beq CoarseScroll     // If fine scroll is zero, go to coarse scroll. 
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
        jsr CMFlipBuffer
        CMDrawMapWindowed()             // draw only the last column as specified by cm_drawColumnJump
        jmp resetFineScroll
doAFirst:
        jsr shift_screen_left_clr_start
        jsr shift_screen_left_a         // shift the back buffer left by one char leaving the last column dirty
        CMDrawMapWindowed()             // draw only the last column as specified by cm_drawColumnJump
        jsr shift_screen_left_b         // shift the back buffer left by one char leaving the last column dirty
        jsr CMFlipBuffer
        CMDrawMapWindowed()             // draw only the last column as specified by cm_drawColumnJump
        jmp resetFineScroll

resetFineScroll:
        // Reset fine scroll hardware register back to 7
        lda #7
        sta cm_xFineScroll
        CMSetFineScroll()
        dec cm_xFineScroll
        jmp done

skipCoarseScroll:
        CMSetFineScroll()
        dec cm_xFineScroll
done:
        rts
}

// =============================================================================
// Flip which screen buffer is currently visible and which one is the back buffer.
//
// NOTE: You would normally not call this directly it is use internally by the 
// charmap code.
// =============================================================================
CMFlipBuffer: {
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
        rts
}

//============================================================================================================================
// shift the contents of the screen left by one column (buffer A)
// These routines only shift the portion of the screen trhat the map area covers.
//============================================================================================================================
shift_screen_left_a: { 
        ldx #0 + CM_DISPLAYED_MAP_X
shift_screen_left_a_char_start:  
        .for(var row = CM_DISPLAYED_MAP_Y ; row <= CM_DISPLAYED_MAP_Y+(CM_DISPLAYED_MAP_CHAR_HEIGHT/2); row++) {
                lda #row
                // Pull byte from column+1 and write it to current column
                lda VIC_SCREEN_CHAR_MEMORY_ADDR + ((row * VIC_SCREEN_WIDTH_COLS) + 1), x
                sta VIC_SCREEN_CHAR_MEMORY_ADDR + (row * VIC_SCREEN_WIDTH_COLS), x
        }
        inx
        cpx #CM_DISPLAYED_MAP_CHAR_WIDTH-1+CM_DISPLAYED_MAP_X
        bne shift_screen_left_a_char_start
        ldx #0 + CM_DISPLAYED_MAP_X
shift_screen_left_a_char_start2:  
        .for(var row = floor(CM_DISPLAYED_MAP_Y+(CM_DISPLAYED_MAP_CHAR_HEIGHT/2))+1 ; row < CM_DISPLAYED_MAP_Y+(CM_DISPLAYED_MAP_CHAR_HEIGHT); row++) {
                // Pull byte from column+1 and write it to current column
                lda VIC_SCREEN_CHAR_MEMORY_ADDR + ((row * VIC_SCREEN_WIDTH_COLS) + 1), x
                sta VIC_SCREEN_CHAR_MEMORY_ADDR + (row * VIC_SCREEN_WIDTH_COLS), x
        }
        inx
        cpx #CM_DISPLAYED_MAP_CHAR_WIDTH-1+CM_DISPLAYED_MAP_X
        bne shift_screen_left_a_char_start2
        rts
}

//============================================================================================================================
// shift the contents of the screen left by one column (buffer B)
// These routines only shift the portion of the screen trhat the map area covers.
//============================================================================================================================
shift_screen_left_b: { 
        ldx #0 + CM_DISPLAYED_MAP_X
shift_screen_left_b_char_start:  
        .for(var row = CM_DISPLAYED_MAP_Y ; row <= CM_DISPLAYED_MAP_Y+(CM_DISPLAYED_MAP_CHAR_HEIGHT/2); row++) {
                // Pull byte from column+1 and write it to current column
                lda VIC_SCREENB_CHAR_MEMORY_ADDR + (row * VIC_SCREEN_WIDTH_COLS) + 1, x
                sta VIC_SCREENB_CHAR_MEMORY_ADDR + (row * VIC_SCREEN_WIDTH_COLS), x
        }
        inx
        cpx #CM_DISPLAYED_MAP_CHAR_WIDTH-1+CM_DISPLAYED_MAP_X
        bne shift_screen_left_b_char_start
        ldx #0 + CM_DISPLAYED_MAP_X
shift_screen_left_b_char_start2:  
        .for(var row = floor(CM_DISPLAYED_MAP_Y+(CM_DISPLAYED_MAP_CHAR_HEIGHT/2))+1 ; row < CM_DISPLAYED_MAP_Y+(CM_DISPLAYED_MAP_CHAR_HEIGHT); row++) {
                // Pull byte from column+1 and write it to current column
                lda VIC_SCREENB_CHAR_MEMORY_ADDR + (row * VIC_SCREEN_WIDTH_COLS) + 1, x
                sta VIC_SCREENB_CHAR_MEMORY_ADDR + (row * VIC_SCREEN_WIDTH_COLS), x
        }
        inx
        cpx #CM_DISPLAYED_MAP_CHAR_WIDTH-1+CM_DISPLAYED_MAP_X
        bne shift_screen_left_b_char_start2
        rts
}

//============================================================================================================================
// shift the contents of the screen left by one column (color memory)
// These routines only shift the portion of the screen trhat the map area covers.
//============================================================================================================================
shift_screen_left_clr_start: { 
        ldx #0 + CM_DISPLAYED_MAP_X
shift_screen_left_clr_start_loop:
        .for(var row = CM_DISPLAYED_MAP_Y ; row <= CM_DISPLAYED_MAP_Y+(CM_DISPLAYED_MAP_CHAR_HEIGHT/2); row++) {
                // Pull byte from column+1 and write it to current column
                lda VIC_SCREEN_COLOR_MEMORY_ADDR + (row * VIC_SCREEN_WIDTH_COLS) + 1, x
                sta VIC_SCREEN_COLOR_MEMORY_ADDR + (row * VIC_SCREEN_WIDTH_COLS), x
        }
        inx
        cpx #CM_DISPLAYED_MAP_CHAR_WIDTH-1+CM_DISPLAYED_MAP_X
        bne shift_screen_left_clr_start_loop
        ldx #0 + CM_DISPLAYED_MAP_X
shift_screen_left_clr_start_loop2:
        .for(var row = floor(CM_DISPLAYED_MAP_Y+(CM_DISPLAYED_MAP_CHAR_HEIGHT/2))+1 ; row < CM_DISPLAYED_MAP_Y+(CM_DISPLAYED_MAP_CHAR_HEIGHT); row++) {
                // Pull byte from column+1 and write it to current column
                lda VIC_SCREEN_COLOR_MEMORY_ADDR + (row * VIC_SCREEN_WIDTH_COLS) + 1, x
                sta VIC_SCREEN_COLOR_MEMORY_ADDR + (row * VIC_SCREEN_WIDTH_COLS), x
        }
        inx
        cpx #CM_DISPLAYED_MAP_CHAR_WIDTH-1+CM_DISPLAYED_MAP_X
        bne shift_screen_left_clr_start_loop2
        rts
}

//============================================================================================================================
// shift the contents of the screen right by one column (buffer A)
// These routines only shift the portion of the screen trhat the map area covers.
//============================================================================================================================
shift_screen_right_a: {
        ldx #0 + CM_DISPLAYED_MAP_X + CM_DISPLAYED_MAP_CHAR_WIDTH-2
shift_screen_right_a_char_start:  
        .for(var row = CM_DISPLAYED_MAP_Y ; row <= CM_DISPLAYED_MAP_Y+(CM_DISPLAYED_MAP_CHAR_HEIGHT/2); row++) {
                // Pull byte from column and write it to column-1
                lda VIC_SCREEN_CHAR_MEMORY_ADDR + (row * VIC_SCREEN_WIDTH_COLS), x
                sta VIC_SCREEN_CHAR_MEMORY_ADDR + (row * VIC_SCREEN_WIDTH_COLS) + 1, x
        }
        dex
        cpx #CM_DISPLAYED_MAP_X
        bpl shift_screen_right_a_char_start
        ldx #0 + CM_DISPLAYED_MAP_X + CM_DISPLAYED_MAP_CHAR_WIDTH-2
shift_screen_right_a_char_start2:  
        .for(var row = floor(CM_DISPLAYED_MAP_Y+(CM_DISPLAYED_MAP_CHAR_HEIGHT/2))+1 ; row < CM_DISPLAYED_MAP_Y+(CM_DISPLAYED_MAP_CHAR_HEIGHT); row++) {
                // Pull byte from column and write it to column-1
                lda VIC_SCREEN_CHAR_MEMORY_ADDR + (row * VIC_SCREEN_WIDTH_COLS), x
                sta VIC_SCREEN_CHAR_MEMORY_ADDR + (row * VIC_SCREEN_WIDTH_COLS) + 1, x
        }
        dex
        cpx #CM_DISPLAYED_MAP_X
        bpl shift_screen_right_a_char_start2
        rts
}

//============================================================================================================================
// shift the contents of the screen right by one column (buffer B)
// These routines only shift the portion of the screen trhat the map area covers.
//============================================================================================================================
shift_screen_right_b: {
        ldx #0 + CM_DISPLAYED_MAP_X + CM_DISPLAYED_MAP_CHAR_WIDTH-2
shift_screen_right_b_char_start:  
        .for(var row = CM_DISPLAYED_MAP_Y ; row <= CM_DISPLAYED_MAP_Y+(CM_DISPLAYED_MAP_CHAR_HEIGHT/2); row++) {
                // Pull byte from column+1 and write it to column
                lda VIC_SCREENB_CHAR_MEMORY_ADDR + (row * VIC_SCREEN_WIDTH_COLS), x
                sta VIC_SCREENB_CHAR_MEMORY_ADDR + (row * VIC_SCREEN_WIDTH_COLS) + 1, x
        }
        dex
        cpx #CM_DISPLAYED_MAP_X
        bpl shift_screen_right_b_char_start
        ldx #0 + CM_DISPLAYED_MAP_X + CM_DISPLAYED_MAP_CHAR_WIDTH-2
shift_screen_right_b_char_start2:  
        .for(var row = floor(CM_DISPLAYED_MAP_Y+(CM_DISPLAYED_MAP_CHAR_HEIGHT/2))+1 ; row < CM_DISPLAYED_MAP_Y+(CM_DISPLAYED_MAP_CHAR_HEIGHT); row++) {
                // Pull byte from column+1 and write it to column
                lda VIC_SCREENB_CHAR_MEMORY_ADDR + (row * VIC_SCREEN_WIDTH_COLS), x
                sta VIC_SCREENB_CHAR_MEMORY_ADDR + (row * VIC_SCREEN_WIDTH_COLS) + 1, x
        }
        dex
        cpx #CM_DISPLAYED_MAP_X
        bpl shift_screen_right_b_char_start2
        rts
}

//============================================================================================================================
// shift the contents of the screen right by one column (color memory)
// These routines only shift the portion of the screen trhat the map area covers.
//============================================================================================================================
shift_screen_right_clr_start: {
        ldx #0 + CM_DISPLAYED_MAP_X + CM_DISPLAYED_MAP_CHAR_WIDTH-2
shift_screen_right_clr_start_loop:
        .for(var row = CM_DISPLAYED_MAP_Y ; row <= CM_DISPLAYED_MAP_Y+(CM_DISPLAYED_MAP_CHAR_HEIGHT/2); row++) {
                // Pull byte from column+1 and write it to current column
                lda VIC_SCREEN_COLOR_MEMORY_ADDR + (row * VIC_SCREEN_WIDTH_COLS), x
                sta VIC_SCREEN_COLOR_MEMORY_ADDR + (row * VIC_SCREEN_WIDTH_COLS) + 1, x
        }
        dex
        cpx #CM_DISPLAYED_MAP_X
        bpl shift_screen_right_clr_start_loop
        ldx #0 + CM_DISPLAYED_MAP_X + CM_DISPLAYED_MAP_CHAR_WIDTH-2
shift_screen_right_clr_start_loop2:
        .for(var row = floor(CM_DISPLAYED_MAP_Y+(CM_DISPLAYED_MAP_CHAR_HEIGHT/2))+1 ; row < CM_DISPLAYED_MAP_Y+(CM_DISPLAYED_MAP_CHAR_HEIGHT); row++) {
                // Pull byte from column+1 and write it to current column
                lda VIC_SCREEN_COLOR_MEMORY_ADDR + (row * VIC_SCREEN_WIDTH_COLS), x
                sta VIC_SCREEN_COLOR_MEMORY_ADDR + (row * VIC_SCREEN_WIDTH_COLS) + 1, x
        }
        dex
        cpx #CM_DISPLAYED_MAP_X
        bpl shift_screen_right_clr_start_loop2
        rts
}
