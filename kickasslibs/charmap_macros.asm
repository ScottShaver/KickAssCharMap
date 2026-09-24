// =============================================================================
// macros specifically for handling charmap maps
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
// 
// =============================================================================
.macro CMSetMapXCharOffset(x) {
        lda x
        sta cm_CurrentCharScrollXPosition
}

// =============================================================================
// 
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