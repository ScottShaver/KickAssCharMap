// =============================================================================
// Subroutine: CMMultiplyTwo8bit
// Multiplies 'calcTemp1' by 'calcTemp2', then leaves the result in calcTemp3 and calcTemp4
// Destroys: A, X, calcTemp1, calcTemp3, calcTemp4
// =============================================================================
CMMultiplyTwo8bit: {
    // --- Step 1: Multiply var1 * var2 into temp storage ---
    lda #0
    sta cm_calcTemp3
    sta cm_calcTemp4
    ldx #8                  // Loop 8 times (once for each bit)

loop:
    lsr cm_calcTemp1           // Shift var1 right, dropping the lowest bit into Carry
    bcc no_add              // If Carry is 0, skip adding var2

    // Add var2 to the high byte of our temporary accumulator
    clc
    lda cm_calcTemp4
    adc cm_calcTemp2
    sta cm_calcTemp4

no_add:
    // Shift the entire 16-bit temporary product right
    ror cm_calcTemp4
    ror cm_calcTemp3
    
    dex                     // Decrement bit counter
    bne loop                // Repeat for all 8 bits

    rts
}


// =============================================================================
// Subroutine: a8b
// adds var1 to var2, then leaves the result in calcTemp2
// Destroys: A, calcTemp2
// =============================================================================
.pseudocommand a8b var1:var2 {
    clc
    lda var1
    adc var2
    sta cm_calcTemp2
}

// =============================================================================
// Subroutine: CMAddTwo8Bit
// adds 'calcTemp1' to 'calcTemp2', then leaves the result in calcTemp2
// Destroys: A, calcTemp2
// =============================================================================
/*CMAddTwo8Bit: {
    clc                // Clear the carry flag before adding
    lda cm_calcTemp2           // Load current value of the second variable into accumulator
    adc cm_calcTemp1           // Add the first variable to accumulator
    sta cm_calcTemp2           // Store the result back into the second variable
    
    rts   
}*/
