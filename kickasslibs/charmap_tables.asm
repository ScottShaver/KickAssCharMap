* = CM_LOOKUP_TABLES_ADDR "Maps Tables"
// Pre-calculate every possible 8-bit outcome at compile time
//table_low:  .fill 256, <(i * CONSTANT_NUM)
//table_high: .fill 256, >(i * CONSTANT_NUM)