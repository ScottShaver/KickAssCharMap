// =============================================================================
// General macros for C64 programming
// =============================================================================

// =============================================================================
// 
// =============================================================================
// You must clear the flag at the end of your interrupt service routine
.macro ClearIRQRegister() {
    lda #$ff
    sta VIC_SCREEN_REG_IRPT_FLAG_ADDR
}

// =============================================================================
// fill the screen with a specific character
// =============================================================================
.macro ClearScreen(charcode) {
    lda #charcode     // Load value charcode into accumulator
    ldx #$00          // Initialize X register to 0

clear_loop:
    // Write 0 to 4 blocks of 250/256 bytes covering 1000 screen bytes
    sta VIC_SCREEN_CHAR_MEMORY_ADDR, x
    sta VIC_SCREEN_CHAR_MEMORY_ADDR + $100, x
    sta VIC_SCREEN_CHAR_MEMORY_ADDR + $200, x
    sta VIC_SCREEN_CHAR_MEMORY_ADDR + $300, x
    
    inx               // Increment X register
    bne clear_loop    // Loop 256 times until X rolls back to 0
}


/*
border - the border color
bg0 - the background color of hires and multicolor mode characters
bg1 - if you are using charpad, this is the color when you have the character color selected
bg2 - if you are using charpad, this is the multi-color 2
bg3 - if you are using charpad, this is the multi-color 1

BLACK	0
WHITE	1
RED	2
CYAN	3
PURPLE	4
GREEN	5
BLUE	6
YELLOW	7
ORANGE	8
BROWN	9
LIGHT_RED	10
DARK_GRAY/DARK_GREY	11
GRAY/GREY	12
LIGHT_GREEN	13
LIGHT_BLUE	14
LIGHT_GRAY/LIGHT_GREY	15
*/
// =============================================================================
// 
// =============================================================================
.macro SetColors(border, bg0, bg1, bg2, bg3) {
        lda #border
        sta VIC_SCREEN_BORDER_COLOR_ADDR
        lda #bg0
        sta VIC_SCREEN_BACKGROUND_COLOR0_ADDR
        lda #bg1
        sta VIC_SCREEN_BACKGROUND_COLOR1_ADDR
        lda #bg2
        sta VIC_SCREEN_BACKGROUND_COLOR2_ADDR
        lda #bg3
        sta VIC_SCREEN_BACKGROUND_COLOR3_ADDR
}

// =============================================================================
// 
// =============================================================================
.macro SetLowerCaseCharsetMode() {
        lda VIC_SCREEN_REG_MEMORY_CONTROL_ADDR
        ora #VSRMCB_UPPER_LOWER_BIT
        sta VIC_SCREEN_REG_MEMORY_CONTROL_ADDR
}

// =============================================================================
// 
// =============================================================================
.macro SetExtendedColorTextMode() {    
        lda VIC_SCREEN_REG_CONTROL1_ADDR
        ora #VSRC1B_EXTENDED_COLOR_TEXT_MODE_BIT
        sta VIC_SCREEN_REG_CONTROL1_ADDR
}

// =============================================================================
// 
// =============================================================================
.macro SetCharsetAddress(bank_offset) {
        lda VIC_SCREEN_REG_MEMORY_CONTROL_ADDR
        and #%11110001
        ora #bank_offset // must be before $4000 and be a multiple of $400
        sta VIC_SCREEN_REG_MEMORY_CONTROL_ADDR
}

// =============================================================================
// 
// =============================================================================
.macro SetMulticolorMode() {
        // Force multicolor mode
        lda VIC_SCREEN_REG_CONTROL2_ADDR
        ora #VSRC2B_MULTICOLOR_MODE_BIT
        sta VIC_SCREEN_REG_CONTROL2_ADDR
}

// =============================================================================
// 
// =============================================================================
.macro Set38ColumnMode() {
        // Force 38-column mode for clean horizontal scrolling
        lda VIC_SCREEN_REG_CONTROL2_ADDR
        and #$F7
        sta VIC_SCREEN_REG_CONTROL2_ADDR
}

// =============================================================================
/*
Kill off BASIC so we have that RAM to use for our program. To make the BASIC work area ($0000–$008F) safely available for your 
own variables, pointers, and machine language routines, you must disable the BASIC ROM interpreter.

Free High RAM: 
Beyond unlocking the zero-page BASIC work area, this swap converts the entire memory block from $A000 to $BFFF
from read-only BASIC ROM into 8KB of completely usable RAM for your program code or data graphics.

Do Not Call BASIC Routines: 
Do not execute a JSR to any memory addresses in the $A000–$BFFF block. The interpreter is no longer there, and 
calling its vectors will instantly crash your system.

KERNAL and Interrupts Remain Intact: 
Because you only flipped off the BASIC bit, standard KERNAL routines (like keyboard scanning and hardware 
interrupts) still work perfectly. They will safely look right past your custom zero-page values without corrupting them.
*/
// =============================================================================
.macro KillBASIC() {

        lda #$36     // Load the value to disable BASIC ($A000-$BFFF becomes RAM)
        sta $0001    // Write to the 6510 processor port
}