* = CM_LOOKUP_TABLES_ADDR "CM_LOOKUP_TABLES_ADDR"
// Pre-calculate pointer offsets for faster access at runtime
tableScreenPointerLow:  .fill VIC_SCREEN_HEIGHT_ROWS, <(i * VIC_SCREEN_WIDTH_COLS)
.align $100
tableCharScreenAPointerHigh: .fill VIC_SCREEN_HEIGHT_ROWS, >((i * VIC_SCREEN_WIDTH_COLS) + VIC_SCREEN_CHAR_MEMORY_ADDR)
.align $100
tableCharScreenBPointerHigh: .fill VIC_SCREEN_HEIGHT_ROWS, >((i * VIC_SCREEN_WIDTH_COLS) + VIC_SCREENB_CHAR_MEMORY_ADDR)
.align $100
tableColorScreenPointerHigh: .fill VIC_SCREEN_HEIGHT_ROWS, >((i * VIC_SCREEN_WIDTH_COLS) + VIC_SCREEN_COLOR_MEMORY_ADDR)
.align $100
tableMapCharPointerLow: .fill CM_MAP_CHAR_HEIGHT, <((i * CM_MAP_CHAR_WIDTH) + CM_MAP_LEVEL_DATA_ADDR)
.align $100
tableMapCharPointerHigh: .fill CM_MAP_CHAR_HEIGHT, >((i * CM_MAP_CHAR_WIDTH) + CM_MAP_LEVEL_DATA_ADDR)

