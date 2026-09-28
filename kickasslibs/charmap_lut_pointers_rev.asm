// =============================================================================
// Primary code file for code that displays and manipulates Charmap map data.
//
// This is the third version that uses look up tables to avoid repeated 
// pointer calculations inside the loops. It can be used by
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

//----------------------------------------------------------------------------------------------------------------------------
// constants specific to this code
//----------------------------------------------------------------------------------------------------------------------------
.const CM_MAP_LEVEL_DATA_ADDR = $3a00      // where the map file from charpad gets loaded - 6000 bytes for a 240x25 map
.const CM_CHARSET_ATTRIB_DATA_ADDR = $5400  // where the charset color file from charpad gets loaded - 256 bytes used
.const CM_CHARSET_CHAR_DATA_ADDR = $2800   // where the charset file from charpad gets loaded - 2048 bytes used
.const CM_LOOKUP_TABLES_ADDR = $1000       // where lookup tables are loaded

//----------------------------------------------------------------------------------------------------------------------------
// Zero-page storage for our calculated 16-bit pointers
// the skipped zero-page locations are used for other purposes by the system and are not safe for our use
//----------------------------------------------------------------------------------------------------------------------------
.var cm_CurrentMapCharPointer = $02             // pointer to the map character data
.var cm_CurrentMapCharColorPointer = $04        // pointer to the map color data
.var cm_CurrentScreenCharPointer = $12          // this is the pointer to the current memory location that we need to place a character at
.var cm_CurrentScreenCharColorPointer = $14     // this is the pointer to the current memory location that we need to place a character color at

//----------------------------------------------------------------------------------------------------------------------------
// Zero-page storage locations for our variables
// the skipped zero-page locations are used for other purposes by the syhstem and are not safe for our use
//----------------------------------------------------------------------------------------------------------------------------
.var cm_CurrentCharScrollXPosition = $49        // which map column do we display in the left most display column
.var cm_CurrentCharScrollYPosition = $50        // which map row do we display in the top most display row
.var cm_calcTemp1 = $42
.var cm_calcTemp2 = $44
.var cm_calcTemp3 = $46
.var cm_calcTemp4 = $48 // this is used in CMMultiplyTwo8bit which may end up never being used
.var cm_drawColumnJump = $50                    // used to skip drawing columns under certain conditions

//----------------------------------------------------------------------------------------------------------------------------
// init zero-page variables
//----------------------------------------------------------------------------------------------------------------------------
CMInitMemoryPointers:
        lda #<CM_CHARSET_ATTRIB_DATA_ADDR
        sta cm_CurrentMapCharColorPointer
        lda #>CM_CHARSET_ATTRIB_DATA_ADDR
        sta cm_CurrentMapCharColorPointer + 1
        rts

//----------------------------------------------------------------------------------------------------------------------------
// init zero-page variables
//----------------------------------------------------------------------------------------------------------------------------
CMInitZeroPageVariables:
        lda #$00
        sta cm_CurrentCharScrollXPosition
        sta cm_CurrentCharScrollYPosition
        sta cm_drawColumnJump
        rts


//============================================================================================================================
//============================================================================================================================
// This is the routine to draw the map windowed on the screen.  It draws the entire map window area.
// you use this is you are not using a window that stretchs from the column 0 to column 40.  Hardware smooth scrolling is
// useless if you are not using a full-width window.
//============================================================================================================================
//============================================================================================================================
CMDrawMapWindowed: {
        // Loop through ROWS first (X register = screen row)
        ldx #CM_DISPLAYED_MAP_Y
        lda #$00                                        // save the number of rows we have drawn so we can correctly calculate the map pointer for the next row
        sta cm_calcTemp1                                // keep track of how many rows have been drawn
CMDrawNextRow:
        // Calculate screen pointers ONCE per row, x=the row offset then add the screen xoffset
        lda tableScreenPointerLow, x                                        
        clc
        adc #CM_DISPLAYED_MAP_X
        sta cm_CurrentScreenCharPointer+0               
        sta cm_CurrentScreenCharColorPointer+0          
        lda tableCharScreenPointerHigh, x               
        sta cm_CurrentScreenCharPointer+1               
        lda tableColorScreenPointerHigh, x              
        sta cm_CurrentScreenCharColorPointer+1          

        // figure out what we need to have as an index for the map char pointer
        lda cm_calcTemp1                                // how many rows we have already drawn                   
        sta cm_calcTemp2
        clc
        adc cm_CurrentCharScrollYPosition               // add the row scroll offset
        sta cm_calcTemp2+0                              // update cm_calcTemp2 to hold the row offset into the map data
        bcc !+                                          // Branch if carry clear (no overflow from low byte), faster than doing the next 3 instructions
        // the carry was set, so we need to increment the high byte as well because we went past $FF in the low byte
        lda cm_calcTemp2+1                              // Load high byte
        adc #$00                                        // Add the carry flag (0 or 1)
        sta cm_calcTemp2+1                              // Save high byte back
!:
        // set the map char pointer to the map row that is at the top of the display area
        ldy cm_calcTemp2                                            
        lda tableMapCharPointerLow, y                   
        sta cm_CurrentMapCharPointer+0                  
        lda tableMapCharPointerHigh, y                  
        sta cm_CurrentMapCharPointer+1                  
//.break
        .for(var col = 0; col < CM_DISPLAYED_MAP_CHAR_WIDTH; col++) {
//****                lda cm_drawColumnJump
//****                bne !+

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
//****                jmp !++
//****!:                
//****                dec cm_drawColumnJump
//****!:
        }

        inc cm_calcTemp1 // keep track of how many rows have been drawn
        inx // keep track of which screen row we are on

        // check if we have drawn all the rows
        cpx #(CM_DISPLAYED_MAP_Y + CM_DISPLAYED_MAP_CHAR_HEIGHT)       
        bne dojmp // have to do it this way because the branch distance is limited

        rts
dojmp: jmp CMDrawNextRow                                     
}



//--------------------------------------------
// shift the contents of the screen left by one column
//--------------------------------------------
shift_screen_left:
        ldx #0
shift_char_start:  
        // Pull byte from column+1 and write it to current column
        lda VIC_SCREEN_CHAR_MEMORY_ADDR + (0 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_CHAR_MEMORY_ADDR + (0 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_CHAR_MEMORY_ADDR + (1 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_CHAR_MEMORY_ADDR + (1 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_CHAR_MEMORY_ADDR + (2 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_CHAR_MEMORY_ADDR + (2 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_CHAR_MEMORY_ADDR + (3 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_CHAR_MEMORY_ADDR + (3 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_CHAR_MEMORY_ADDR + (4 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_CHAR_MEMORY_ADDR + (4 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_CHAR_MEMORY_ADDR + (5 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_CHAR_MEMORY_ADDR + (5 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_CHAR_MEMORY_ADDR + (6 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_CHAR_MEMORY_ADDR + (6 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_CHAR_MEMORY_ADDR + (7 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_CHAR_MEMORY_ADDR + (7 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_CHAR_MEMORY_ADDR + (8 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_CHAR_MEMORY_ADDR + (8 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_CHAR_MEMORY_ADDR + (9 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_CHAR_MEMORY_ADDR + (9 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_CHAR_MEMORY_ADDR + (10 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_CHAR_MEMORY_ADDR + (10 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_CHAR_MEMORY_ADDR + (11 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_CHAR_MEMORY_ADDR + (11 * VIC_SCREEN_WIDTH_COLS), x
        inx
        cpx #VIC_SCREEN_WIDTH_COLS - 1 // Shift 39 columns wide
        bne shift_char_start
        ldx #0
shift_char_finish:
        lda VIC_SCREEN_CHAR_MEMORY_ADDR + (12 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_CHAR_MEMORY_ADDR + (12 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_CHAR_MEMORY_ADDR + (13 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_CHAR_MEMORY_ADDR + (13 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_CHAR_MEMORY_ADDR + (14 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_CHAR_MEMORY_ADDR + (14 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_CHAR_MEMORY_ADDR + (15 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_CHAR_MEMORY_ADDR + (15 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_CHAR_MEMORY_ADDR + (16 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_CHAR_MEMORY_ADDR + (16 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_CHAR_MEMORY_ADDR + (17 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_CHAR_MEMORY_ADDR + (17 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_CHAR_MEMORY_ADDR + (18 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_CHAR_MEMORY_ADDR + (18 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_CHAR_MEMORY_ADDR + (19 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_CHAR_MEMORY_ADDR + (19 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_CHAR_MEMORY_ADDR + (20 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_CHAR_MEMORY_ADDR + (20 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_CHAR_MEMORY_ADDR + (21 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_CHAR_MEMORY_ADDR + (21 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_CHAR_MEMORY_ADDR + (22 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_CHAR_MEMORY_ADDR + (22 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_CHAR_MEMORY_ADDR + (23 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_CHAR_MEMORY_ADDR + (23 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_CHAR_MEMORY_ADDR + (24 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_CHAR_MEMORY_ADDR + (24 * VIC_SCREEN_WIDTH_COLS), x
        inx
        cpx #VIC_SCREEN_WIDTH_COLS - 1 // Shift 39 columns wide
        bne shift_char_finish

        ldx #0
shift_clr_start:
        // Pull byte from column+1 and write it to current column
        lda VIC_SCREEN_COLOR_MEMORY_ADDR + (0 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_COLOR_MEMORY_ADDR + (0 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_COLOR_MEMORY_ADDR + (1 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_COLOR_MEMORY_ADDR + (1 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_COLOR_MEMORY_ADDR + (2 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_COLOR_MEMORY_ADDR + (2 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_COLOR_MEMORY_ADDR + (3 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_COLOR_MEMORY_ADDR + (3 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_COLOR_MEMORY_ADDR + (4 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_COLOR_MEMORY_ADDR + (4 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_COLOR_MEMORY_ADDR + (5 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_COLOR_MEMORY_ADDR + (5 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_COLOR_MEMORY_ADDR + (6 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_COLOR_MEMORY_ADDR + (6 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_COLOR_MEMORY_ADDR + (7 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_COLOR_MEMORY_ADDR + (7 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_COLOR_MEMORY_ADDR + (8 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_COLOR_MEMORY_ADDR + (8 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_COLOR_MEMORY_ADDR + (9 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_COLOR_MEMORY_ADDR + (9 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_COLOR_MEMORY_ADDR + (10 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_COLOR_MEMORY_ADDR + (10 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_COLOR_MEMORY_ADDR + (11 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_COLOR_MEMORY_ADDR + (11 * VIC_SCREEN_WIDTH_COLS), x
        inx
        cpx #VIC_SCREEN_WIDTH_COLS - 1 // Shift 39 columns wide
        bne shift_clr_start
        ldx #0
shift_clr_finish:
        lda VIC_SCREEN_COLOR_MEMORY_ADDR + (12 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_COLOR_MEMORY_ADDR + (12 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_COLOR_MEMORY_ADDR + (13 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_COLOR_MEMORY_ADDR + (13 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_COLOR_MEMORY_ADDR + (14 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_COLOR_MEMORY_ADDR + (14 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_COLOR_MEMORY_ADDR + (15 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_COLOR_MEMORY_ADDR + (15 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_COLOR_MEMORY_ADDR + (16 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_COLOR_MEMORY_ADDR + (16 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_COLOR_MEMORY_ADDR + (17 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_COLOR_MEMORY_ADDR + (17 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_COLOR_MEMORY_ADDR + (18 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_COLOR_MEMORY_ADDR + (18 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_COLOR_MEMORY_ADDR + (19 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_COLOR_MEMORY_ADDR + (19 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_COLOR_MEMORY_ADDR + (20 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_COLOR_MEMORY_ADDR + (20 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_COLOR_MEMORY_ADDR + (21 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_COLOR_MEMORY_ADDR + (21 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_COLOR_MEMORY_ADDR + (22 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_COLOR_MEMORY_ADDR + (22 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_COLOR_MEMORY_ADDR + (23 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_COLOR_MEMORY_ADDR + (23 * VIC_SCREEN_WIDTH_COLS), x
        lda VIC_SCREEN_COLOR_MEMORY_ADDR + (24 * VIC_SCREEN_WIDTH_COLS) + 1, x
        sta VIC_SCREEN_COLOR_MEMORY_ADDR + (24 * VIC_SCREEN_WIDTH_COLS), x
        inx
        cpx #VIC_SCREEN_WIDTH_COLS - 1 // Shift 39 columns wide
        bne shift_clr_finish
        rts