* = CM_LOOKUP_TABLES_ADDR "Maps Tables"
// Pre-calculate pointer offsets for faster access at runtime
tableScreenPointerLow:  .fill VIC_SCREEN_HEIGHT_ROWS, <(i * VIC_SCREEN_WIDTH_COLS)
tableCharScreenPointerHigh: .fill VIC_SCREEN_HEIGHT_ROWS, >((i * VIC_SCREEN_WIDTH_COLS) + VIC_SCREEN_CHAR_MEMORY_ADDR)
tableColorScreenPointerHigh: .fill VIC_SCREEN_HEIGHT_ROWS, >((i * VIC_SCREEN_WIDTH_COLS) + VIC_SCREEN_COLOR_MEMORY_ADDR)
tableMapCharPointerLow: .fill CM_MAP_CHAR_HEIGHT, <((i * CM_MAP_CHAR_WIDTH) + CM_MAP_LEVEL_DATA_ADDR)
tableMapCharPointerHigh: .fill CM_MAP_CHAR_HEIGHT, >((i * CM_MAP_CHAR_WIDTH) + CM_MAP_LEVEL_DATA_ADDR)

