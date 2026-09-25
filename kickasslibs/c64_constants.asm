// =============================================================================
// General constants for C64 programming
// =============================================================================

.const REG_MEMORY_CONFIGURATION_ADDR = $01 // the address of the memory configuration register in the C64 memory map
.const RMC_DEFAULT_BITS = $37                    // default value for the memory configuration register
.const RMC_LORAM_BIT = $01                      // LORAM bit in the memory configuration register. Controls the memory block at $A000–$BFFF. 1 = BASIC ROM visible, 0 = RAM visible
.const RMC_HIRAM_BIT = $02                      // HIRAM bit in the memory configuration register. Controls the memory block at $E000–$FFFF. 1 = KERNAL ROM visible, 0 = RAM visible
.const RMC_CHAREN_BIT = $04                     // CHAREN bit in the memory configuration register. Controls the memory block at $D000–$DFFF. 1 = I/O registers (VIC-II, SID, CIAs) visible, 0 = Character Generator ROM visible
.const RMC_CASSETTE_DATA_OUPUT_BIT = $08    // CASSETTE DATA OUTPUT bit in the memory configuration register. Send data to the cassette
.const RMC_CASSETTE_DATA_INPUT_BIT = $10    // CASSETTE DATA INPUT bit in the memory configuration register. Controls the cassette data input line. 1 = no button pressed, 0 = a button is pressed
.const RMC_CASSETTE_MOTOR_BIT = $20         // CASSETTE MOTOR bit in the memory configuration register. Controls the cassette motor. 1 = motor off, 0 = motor on
.const RMC_UNUSED_BIT = $C0                 // UNUSED bit in the memory configuration register. Typically not used, reserved for future expansion

//.namespace VIC { //D000-D02E
//    .namespace SCREEN {
        .const VIC_SCREEN_CHAR_BANK_OFFSET_0000 = %0000 // 0 $0000-$07FF (0-2047) First 2KB of bank
        .const VIC_SCREEN_CHAR_BANK_OFFSET_0800 = %0010 // 2 $0800-$0FFF (2048-4095) Second 2KB block
        .const VIC_SCREEN_CHAR_BANK_OFFSET_4096 = %0100 // 4 $1000-$17FF (4096-6143) Default Character ROM (in Banks 0 & 2)
        .const VIC_SCREEN_CHAR_BANK_OFFSET_6144 = %0110 // 6 $1800-$1FFF (6144-8191) Upper half of lower block
        .const VIC_SCREEN_CHAR_BANK_OFFSET_8192 = %1000 // 8 $2000-$27FF (8192-10239) Custom RAM charset option
        .const VIC_SCREEN_CHAR_BANK_OFFSET_10240 = %1010 // 10 $2800-$2FFF (10240-12287) Custom RAM charset option
        .const VIC_SCREEN_CHAR_BANK_OFFSET_12888 = %1100 // 12 $3000-$37FF (12888-14335) Recommended custom RAM location in Bank 0
        .const VIC_SCREEN_CHAR_BANK_OFFSET_14336 = %1110 // 14 $3800-$3FFF (14336-16383) Top 2KB of bank

        .const VIC_SCREEN_CHAR_MEMORY_ADDR = $0400 // the start of the screen character memory
        .const VIC_SCREEN_COLOR_MEMORY_ADDR = $D800 // the start of the screen color memory
        .const VIC_SCREEN_COLOR_MEMORY_OFFSET = VIC_SCREEN_COLOR_MEMORY_ADDR - VIC_SCREEN_CHAR_MEMORY_ADDR
        //.const CHARSET_MEMORY_ADDR = $4800 // the start of the character set memory
        //.const CUSTOM_CHARSET_MEMORY_ADDR = $3800 // the start of the character set memory
        //.const CUSTOM_MAP_MEMORY_ADDR = $8000 // the start of the charpad map memory
        .const VIC_SCREEN_WIDTH_COLS = 40 // the width of the screen in characters
        .const VIC_SCREEN_HEIGHT_ROWS = 25 // the height of the screen in characters
        .const VIC_SCREEN_SIZE_CHARS = VIC_SCREEN_WIDTH_COLS * VIC_SCREEN_HEIGHT_ROWS // the total number of characters on the screen
        .const VIC_SCREEN_MEMORY_SIZE = VIC_SCREEN_SIZE_CHARS // the total size of the screen memory in characters
        .const VIC_SCREEN_COLOR_MEMORY_SIZE = VIC_SCREEN_SIZE_CHARS // the total size of the screen color memory in characters
        .const VIC_SCREEN_BORDER_COLOR_ADDR = $D020 // the address of the border color register in the VIC-II chip
        .const VIC_SCREEN_BACKGROUND_COLOR0_ADDR = $D021 // the address of the background color register in the VIC-II chip
        .const VIC_SCREEN_BACKGROUND_COLOR1_ADDR = $D022 // the address of the background color register in the VIC-II chip
        .const VIC_SCREEN_BACKGROUND_COLOR2_ADDR = $D023 // the address of the background color register in the VIC-II chip
        .const VIC_SCREEN_BACKGROUND_COLOR3_ADDR = $D024 // the address of the background color register in the VIC-II chip
    //}

    .namespace SPRITE {
        .const MEMORY_ADDR = $07F8 // the start of the sprite memory
        .const MEMORY_SIZE = 64 // the total size of the sprite memory in bytes
        .const MEMORY_END_ADDR = MEMORY_ADDR + MEMORY_SIZE // the end of the sprite memory
        .const X0 = $D000 // the X coordinate of sprite 0
        .const Y0 = $D001 // the Y coordinate of sprite 0
        .const X1 = $D002 // the X coordinate of sprite 0
        .const Y1 = $D003 // the Y coordinate of sprite 0
        .const X2 = $D004 // the X coordinate of sprite 0
        .const Y2 = $D005 // the Y coordinate of sprite 0
        .const X3 = $D006 // the X coordinate of sprite 0
        .const Y3 = $D007 // the Y coordinate of sprite 0
        .const X4 = $D008 // the X coordinate of sprite 0
        .const Y4 = $D009 // the Y coordinate of sprite 0
        .const X5 = $D00A // the X coordinate of sprite 0
        .const Y5 = $D00B // the Y coordinate of sprite 0
        .const X6 = $D00C // the X coordinate of sprite 0
        .const Y6 = $D00D // the Y coordinate of sprite 0
        .const X7 = $D00E // the X coordinate of sprite 0
        .const Y7 = $D00F // the Y coordinate of sprite 0
        .const X_MSB_ADDR = $D010 // the most significant bit of the X coordinate for all sprites

        .const REG_SPRITES_2X_VERT_ADDR = $D017 // the register used to enable 2x vertical size for sprites in the VIC-II chip
        .namespace REG_SPRITES_2X_VERT_BITS {
            .const SPRITE0_BIT = $01 // the bit used to enable 2x vertical size for sprite 0 in the VIC-II chip
            .const SPRITE1_BIT = $02 // the bit used to enable 2x vertical size for sprite 1 in the VIC-II chip
            .const SPRITE2_BIT = $04 // the bit used to enable 2x vertical size for sprite 2 in the VIC-II chip
            .const SPRITE3_BIT = $08 // the bit used to enable 2x vertical size for sprite 3 in the VIC-II chip
            .const SPRITE4_BIT = $10 // the bit used to enable 2x vertical size for sprite 4 in the VIC-II chip
            .const SPRITE5_BIT = $20 // the bit used to enable 2x vertical size for sprite 5 in the VIC-II chip
            .const SPRITE6_BIT = $40 // the bit used to enable 2x vertical size for sprite 6 in the VIC-II chip
            .const SPRITE7_BIT = $80 // the bit used to enable 2x vertical size for sprite 7 in the VIC-II chip
        }   

        .const SPRITE_BG_DISP_PRIORITY_ADDR = $D01B // the register used to hold the sprite background display priority in the VIC-II chip, 1 = sprite in front of background, 0 = sprite behind background

        .const SPRITES_MULTICOLOR_MODE_ADDR = $D01C // the register used to control the multicolor mode for sprites in the VIC-II chip
        .namespace SPRITES_MULTICOLOR_MODE_BITS {
            .const SPRITE0_BIT = $01 // the bit used to enable multicolor mode for sprite 0 in the VIC-II chip, 1=multicolor mode enabled, 0=multicolor mode disabled
            .const SPRITE1_BIT = $02 // the bit used to enable multicolor mode for sprite 1 in the VIC-II chip, 1=multicolor mode enabled, 0=multicolor mode disabled
            .const SPRITE2_BIT = $04 // the bit used to enable multicolor mode for sprite 2 in the VIC-II chip, 1=multicolor mode enabled, 0=multicolor mode disabled
            .const SPRITE3_BIT = $08 // the bit used to enable multicolor mode for sprite 3 in the VIC-II chip, 1=multicolor mode enabled, 0=multicolor mode disabled
            .const SPRITE4_BIT = $10 // the bit used to enable multicolor mode for sprite 4 in the VIC-II chip, 1=multicolor mode enabled, 0=multicolor mode disabled
            .const SPRITE5_BIT = $20 // the bit used to enable multicolor mode for sprite 5 in the VIC-II chip, 1=multicolor mode enabled, 0=multicolor mode disabled
            .const SPRITE6_BIT = $40 // the bit used to enable multicolor mode for sprite 6 in the VIC-II chip, 1=multicolor mode enabled, 0=multicolor mode disabled
            .const SPRITE7_BIT = $80 // the bit used to enable multicolor mode for sprite 7 in the VIC-II chip, 1=multicolor mode enabled, 0=multicolor mode disabled
        }   

        .const REG_SPRITES_2X_HORIZ_ADDR = $D01D // the register used to enable 2x horizontal size for sprites in the VIC-II chip
        .namespace REG_SPRITES_2X_HORIZ_BITS {
            .const SPRITE0_BIT = $01 // the bit used to enable 2x vertical size for sprite 0 in the VIC-II chip
            .const SPRITE1_BIT = $02 // the bit used to enable 2x vertical size for sprite 1 in the VIC-II chip
            .const SPRITE2_BIT = $04 // the bit used to enable 2x vertical size for sprite 2 in the VIC-II chip
            .const SPRITE3_BIT = $08 // the bit used to enable 2x vertical size for sprite 3 in the VIC-II chip
            .const SPRITE4_BIT = $10 // the bit used to enable 2x vertical size for sprite 4 in the VIC-II chip
            .const SPRITE5_BIT = $20 // the bit used to enable 2x vertical size for sprite 5 in the VIC-II chip
            .const SPRITE6_BIT = $40 // the bit used to enable 2x vertical size for sprite 6 in the VIC-II chip
            .const SPRITE7_BIT = $80 // the bit used to enable 2x vertical size for sprite 7 in the VIC-II chip
        }   

        .const SPRITE_SPRITE_COLLISION_DETECT_ADDR = $D01E // the register used to detect collisions between sprites in the VIC-II chip
        .const SPRITE_BG_COLLISION_DETECT_ADDR = $D01F // the register used to detect collisions between sprites and the background in the VIC-II chip
        .const REG0_SPRITE_MULTICOLOR_ADDR = $D025 // the register used to enable multicolor mode for sprites in the VIC-II chip
        .const REG1_SPRITE_MULTICOLOR_ADDR = $D026 // the register used to enable multicolor mode for sprites in the VIC-II chip

        .const SPRITE0_COLOR_ADDR = $D027 // the address of the color register for sprite 0 in the VIC-II chip
        .const SPRITE1_COLOR_ADDR = $D028 // the address of the color register for sprite 1 in the VIC-II chip
        .const SPRITE2_COLOR_ADDR = $D029 // the address of the color register for sprite 2 in the VIC-II chip
        .const SPRITE3_COLOR_ADDR = $D02A // the address of the color register for sprite 3 in the VIC-II chip
        .const SPRITE4_COLOR_ADDR = $D02B // the address of the color register for sprite 4 in the VIC-II chip
        .const SPRITE5_COLOR_ADDR = $D02C // the address of the color register for sprite 5 in the VIC-II chip
        .const SPRITE6_COLOR_ADDR = $D02D // the address of the color register for sprite 6 in the VIC-II chip
        .const SPRITE7_COLOR_ADDR = $D02E // the address of the color register for sprite 7 in the VIC-II chip
    }

    .const VIC_SCREEN_REG_CONTROL1_ADDR = $D011 // a control register of the VIC-II chip
    //.namespace VIC_SCREEN_REG_CONTROL1_BITS {
        .const VSRC1B_RASTER_COMPARE_BIT = $80 // the bit used for raster compare in the VIC-II chip
        .const VSRC1B_EXTENDED_COLOR_TEXT_MODE_BIT = $40 // the bit used to enable extended color text mode in the VIC-II chip, 1=enabled
        .const VSRC1B_BITMAP_MODE_BIT = $20 // the bit used to enable bitmap mode in the VIC-II chip, 1=enabled
        .const VSRC1B_BLANK_TO_BORDER_BIT = $10 // the bit used to enable blank to border in the VIC-II chip, 0=blank
        .const VSRC1B_ROW_SELECT_BIT = $08 // the bit used to select 24/25 rows in the VIC-II chip, 1=25 rows
        .const VSRC1B_SMOOTH_SCROLLY_BITS = $07 // the bits used to scroll to Y dot poisition in the VIC-II chip
    //}

    .const VIC_SCREEN_RASTER_LINE_ADDR = $D012 // the current raster line of the VIC-II chip

    .const VIC_SCREEN_REG_SPRITE_DISPLAY_ENABLE_ADDR = $D015 // the register used to enable sprite display in the VIC-II chip, 1=enabled
    .namespace VIC_SCREEN_REG_SPRITE_DISPLAY_ENABLE_BITS {
        .const ENABLE_BIT = $01 // the bit used to enable sprite display in the VIC-II chip, 1=enabled
    }

    .const VIC_SCREEN_REG_CONTROL2_ADDR = $D016 // a control register of the VIC-II chip
    //.namespace VIC_SCREEN_REG_CONTROL2_BITS {
        .const VSRC2B_UNUSED_BITS = $C0 // the unused bits in VIC-II control register 2
        .const VSRC2B_ALWAYS_ZERO_BIT = $20 // the bit that is always zero in VIC-II control register 2
        .const VSRC2B_MULTICOLOR_MODE_BIT = $10 // the bit used to enable multicolor mode in the VIC-II control register 2, 1=enabled
        .const VSRC2B_COLUMN_SELECT_BIT = $08 // the bit used to select the number of columns in the VIC-II control register 2, 1=40 columns, 0=38 columns
        .const VSRC2B_SMOOTH_SCROLLX_BITS = $07 // the bits used to scroll to X dot poisition in the VIC-II chip
    //}

    .const VIC_SCREEN_REG_MEMORY_CONTROL_ADDR = $D018 // the register used to control memory configuration in the VIC-II chip
    //.namespace VIC_SCREEN_REG_MEMORY_CONTROL_BITS {
        .const VSRMCB_UNUSED_BIT = $01 // the unused bit in the VIC-II memory control register
        .const VSRMCB_UPPER_LOWER_BIT = $02 // the bit used to select the upper or lower case character set in the VIC-II memory control register, 1=lower, 0=upper
        .const VSRMCB_CHAR_DOT_DATA_ADDR_BITS = $0E // the bits used for the character dot data address in the VIC-II memory control register
        .const VSRMCB_VIDEO_MATRIX_BASE_ADDR_BITS = $F0 // the bits used for the VIC-II memory base address in the VIC-II memory control register. Multiplies by $0400 (1024 bytes) to determine the offset from the start of the current 16KB VIC bank.
    //}

    .const VIC_SCREEN_REG_IRPT_FLAG_ADDR = $D019 // the register used to hold the interrupt flags in the VIC-II chip
    //.namespace VIC_SCREEN_REG_IRPT_FLAG_BITS {
        .const VSRIFB_IRQ_OCCCURRED_BIT = $80 // the bit indicating that an interrupt request has occurred, 1=IRQ occurred, 0=no IRQ
        .const VSRIFB_LIGHTPEN_TRIGGERED_BIT = $08 // the bit indicating that the lightpen has been triggered, 1=triggered, 0=not triggered
        .const VSRIFB_SPRITE_SPRITE_COLLISION_BIT = $04 // the bit indicating that a sprite to sprite collision has occurred, 1=collision occurred, 0=no collision
        .const VSRIFB_SPRITE_BG_COLLISION_BIT = $02 // the bit indicating that a sprite to backgropund collision has occurred, 1=collision occurred, 0=no collision
        .const VSRIFB_RASTER_COMPARE_BIT = $01 // the bit indicating that the raster compare has occurred, 1=compare occurred, 0=not occurred
    //}

    .const VIC_IRQ_MASK_REG_ADDR = $D01A // the register used to hold the interrupt mask in the VIC-II chip
    .const VIMRB_RASTER_IRQ_BIT = $01 // the bit used to enable raster interrupts in the VIC-II interrupt mask register
    .const VIMRB_SPRITE_COLLISION_IRQ_BIT = $02 // the bit used to enable sprite to background collision interrupts in the VIC-II interrupt mask register
    .const VIMRB_SPRITE_SPRITE_COLLISION_IRQ_BIT = $04 // the bit used to enable sprite to sprite collision interrupts in the VIC-II interrupt mask register
    .const VIMRB_LIGHTPEN_IRQ_BIT = $08 // the bit used to enable lightpen interrupts in the VIC-II interrupt mask register
    .const VIMRB_UNUSED_BIT = $F0 // the unused bit in the VIC-II interrupt mask register
//}

.namespace SID { //D400-D7FF
    .const REG_CONTROL_ADDR = $D400 // the address of the SID control register
}

.namespace CIA1 { //DC00-DCFF
}

.namespace CIA2 { //DD00-DDFF
}
