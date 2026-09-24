.struct GameVars {
	scroll_x,         // Hardware scroll register value (7 to 0)
	map_column,       // Current column index in our map data
	scroll_speed,     // Adjust for faster or slower scrolling
    map_width         // Width of the map in columns
}

.struct GamePointers {
    map_char_pointer,
    //map_color_pointer,
    screen_char_pointer,
    screen_color_pointer,
    charset_char_pointer,
    charset_color_pointer
}