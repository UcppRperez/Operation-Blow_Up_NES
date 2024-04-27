def create_metatiles(raw_data):
    # Split and clean input data
    lines = raw_data.split('\n')
    clean_lines = [line.replace('.byte', '').replace('$', '').strip() for line in lines if line.strip()]

    # Extract tile values and create metatiles
    tiles = [int(x, 16) for line in clean_lines for x in line.split(',') if x.strip()]
    metatiles = []
    metatile_map = []
    metatile_index_map = {}

    # Process complete blocks of tiles
    for i in range(0, len(tiles) - 15, 16):  
        for j in range(0, 16, 4):  
            if i + j + 5 < len(tiles):
                metatile = (tiles[i + j], tiles[i + j + 1], tiles[i + j + 4], tiles[i + j + 5])
                metatile_key = tuple(metatile)
                if metatile_key not in metatile_index_map:
                    metatile_index_map[metatile_key] = len(metatiles)
                    metatiles.append(metatile)
                metatile_map.append(metatile_index_map[metatile_key])

    # Format metatile definitions
    metatile_definitions = [f".byte ${t[0]:02X}, ${t[1]:02X}, ${t[2]:02X}, ${t[3]:02X}" for t in metatiles]

    # Format metatile map with better readability
    max_per_line = 16  # Max number of indices per line for better readability
    map_lines = [f".byte " + ', '.join(f"${x:02X}" for x in metatile_map[i:i+max_per_line])
                 for i in range(0, len(metatile_map), max_per_line)]

    return "\n".join(metatile_definitions), "\n".join(map_lines)

# Sample data, please ensure it is correctly formatted and has the correct number of tiles
raw_data = """
.byte $00, $00, $00, $00
.byte $00, $00, $00, $00
.byte $00, $00, $00, $00
.byte $00, $00, $00, $00
.byte $00, $00, $00, $00
.byte $00, $00, $00, $00
.byte $00, $00, $00, $00
.byte $00, $00, $00, $00
.byte $77, $77, $77, $77
.byte $77, $77, $77, $77
.byte $77, $77, $77, $77
.byte $77, $77, $77, $77
.byte $77, $77, $77, $77
.byte $77, $77, $77, $77
.byte $77, $77, $77, $77
.byte $77, $77, $77, $77
.byte $77, $77, $77, $77
.byte $00, $00, $00, $00
.byte $00, $A3, $00, $A3
.byte $00, $00, $00, $00
.byte $A7, $00, $00, $00
.byte $87, $87, $87, $87
.byte $87, $87, $87, $87
.byte $55, $58, $55, $58
.byte $77, $77, $77, $77
.byte $00, $00, $00, $00
.byte $55, $58, $55, $58
.byte $00, $00, $B8, $B8
.byte $55, $56, $55, $56
.byte $56, $58, $56, $58
.byte $87, $87, $87, $87
.byte $92, $92, $00, $00
.byte $77, $77, $77, $77
.byte $87, $87, $87, $87
.byte $55, $58, $55, $58
.byte $00, $B8, $B8, $B8
.byte $00, $00, $00, $00
.byte $55, $56, $55, $56
.byte $56, $56, $56, $56
.byte $56, $56, $56, $56
.byte $77, $77, $77, $77
.byte $87, $87, $87, $87
.byte $55, $56, $55, $56
.byte $56, $56, $56, $56
.byte $56, $56, $56, $56
.byte $56, $58, $56, $58
.byte $92, $92, $92, $92
.byte $00, $00, $00, $00
.byte $77, $77, $77, $77
.byte $87, $87, $87, $87
.byte $A8, $A8, $A8, $A8
.byte $00, $92, $92, $92
.byte $55, $58, $55, $58
.byte $87, $87, $87, $87
.byte $87, $87, $87, $87
.byte $55, $58, $55, $58
.byte $77, $77, $77, $77
.byte $87, $87, $87, $87
.byte $55, $58, $55, $58
.byte $92, $92, $92, $00
.byte $00, $00, $00, $00
.byte $87, $87, $87, $87
.byte $55, $57, $55, $57
.byte $57, $57, $57, $57
.byte $77, $77, $77, $77
.byte $87, $87, $87, $87
.byte $55, $58, $55, $58
.byte $00, $00, $00, $00
.byte $55, $58, $55, $58
.byte $87, $87, $87, $87
.byte $00, $00, $00, $00
.byte $55, $58, $55, $58
.byte $77, $77, $77, $77
.byte $87, $87, $87, $87
.byte $55, $58, $55, $58
.byte $92, $92, $00, $00
.byte $55, $58, $55, $58
.byte $87, $87, $87, $87
.byte $55, $57, $55, $57
.byte $57, $58, $57, $58
.byte $77, $77, $77, $77
.byte $00, $00, $00, $00
.byte $55, $58, $55, $58
.byte $00, $00, $00, $00
.byte $55, $58, $55, $58
.byte $87, $87, $87, $87
.byte $87, $87, $87, $87
.byte $55, $58, $55, $58
.byte $77, $77, $77, $77
.byte $00, $00, $00, $00
.byte $55, $58, $55, $58
.byte $00, $92, $00, $00
.byte $55, $57, $55, $57
.byte $57, $57, $57, $56
.byte $57, $56, $57, $57
.byte $56, $57, $57, $57
.byte $77, $77, $77, $77
.byte $A8, $A8, $00, $00
.byte $55, $58, $55, $58
.byte $00, $00, $B7, $00
.byte $55, $58, $55, $58
.byte $87, $87, $87, $87
.byte $87, $87, $87, $87
.byte $87, $87, $87, $87
.byte $B2, $A8, $B2, $A8
.byte $00, $00, $00, $00
.byte $55, $58, $55, $58
.byte $B7, $BA, $BA, $00
.byte $87, $87, $87, $87
.byte $87, $87, $87, $87
.byte $55, $58, $55, $58
.byte $87, $87, $87, $87
.byte $77, $77, $77, $77
.byte $77, $77, $77, $77
.byte $77, $77, $77, $77
.byte $77, $77, $77, $77
.byte $77, $77, $77, $77
.byte $77, $77, $77, $77
.byte $77, $77, $77, $77
.byte $77, $77, $77, $77
.byte $00, $00, $00, $00
.byte $00, $00, $00, $00
.byte $00, $00, $00, $00
.byte $00, $00, $00, $00
.byte $00, $00, $00, $00
.byte $00, $00, $00, $00
.byte $00, $00, $00, $00
.byte $00, $00, $00, $00
.byte $77, $77, $77, $77
.byte $77, $77, $77, $77
.byte $77, $77, $77, $77
.byte $77, $77, $77, $77
.byte $77, $77, $77, $77
.byte $77, $77, $77, $77
.byte $77, $77, $77, $77
.byte $77, $77, $77, $77
.byte $92, $92, $92, $00
.byte $00, $00, $00, $00
.byte $00, $00, $00, $00
.byte $55, $58, $55, $58
.byte $87, $87, $87, $87
.byte $00, $00, $00, $00
.byte $00, $00, $00, $00
.byte $55, $58, $55, $58
.byte $92, $00, $A7, $00
.byte $55, $58, $55, $58
.byte $87, $87, $87, $87
.byte $55, $58, $55, $58
.byte $87, $87, $87, $87
.byte $55, $58, $55, $58
.byte $00, $00, $00, $00
.byte $55, $58, $55, $58
.byte $56, $57, $56, $56
.byte $57, $58, $57, $58
.byte $87, $87, $87, $87
.byte $87, $87, $87, $87
.byte $87, $87, $87, $87
.byte $55, $58, $55, $58
.byte $00, $00, $92, $00
.byte $55, $58, $55, $58
.byte $00, $00, $92, $00
.byte $55, $58, $55, $58
.byte $87, $87, $87, $87
.byte $55, $58, $55, $58
.byte $87, $87, $87, $87
.byte $55, $58, $55, $58
.byte $00, $00, $00, $00
.byte $55, $58, $55, $58
.byte $00, $00, $92, $92
.byte $00, $00, $00, $00
.byte $87, $87, $87, $87
.byte $55, $58, $55, $58
.byte $87, $87, $87, $87
.byte $55, $58, $55, $58
.byte $00, $00, $00, $00
.byte $55, $58, $55, $58
.byte $56, $57, $57, $57
.byte $56, $57, $56, $56
.byte $56, $57, $56, $56
.byte $56, $58, $56, $58
.byte $87, $87, $87, $87
.byte $55, $58, $55, $58
.byte $00, $00, $00, $00
.byte $00, $00, $00, $00
.byte $92, $92, $92, $92
.byte $00, $00, $00, $00
.byte $00, $00, $00, $00
.byte $87, $87, $87, $87
.byte $87, $87, $87, $87
.byte $55, $56, $55, $56
.byte $56, $56, $56, $56
.byte $56, $56, $56, $56
.byte $92, $92, $92, $92
.byte $55, $57, $55, $57
.byte $57, $58, $57, $58
.byte $87, $87, $87, $87
.byte $87, $87, $87, $87
.byte $55, $58, $55, $58
.byte $00, $00, $00, $00
.byte $55, $58, $55, $58
.byte $92, $92, $92, $00
.byte $92, $92, $00, $92
.byte $55, $58, $55, $58
.byte $00, $92, $00, $92
.byte $55, $56, $55, $56
.byte $56, $58, $56, $58
.byte $00, $00, $00, $00
.byte $55, $58, $55, $58
.byte $57, $58, $57, $58
.byte $00, $00, $00, $00
.byte $55, $58, $55, $58
.byte $92, $92, $92, $92
.byte $00, $00, $00, $00
.byte $55, $58, $55, $58
.byte $00, $00, $00, $00
.byte $55, $58, $55, $58
.byte $55, $58, $55, $58
.byte $00, $00, $00, $00
.byte $55, $56, $55, $56
.byte $56, $58, $56, $58
.byte $00, $00, $00, $00
.byte $55, $58, $55, $58
.byte $00, $00, $00, $00
.byte $55, $58, $55, $58
.byte $87, $87, $87, $87
.byte $87, $87, $87, $87
.byte $55, $58, $55, $58
.byte $00, $00, $00, $00
.byte $00, $00, $00, $00
.byte $00, $00, $00, $E9
.byte $00, $00, $00, $00
.byte $55, $58, $55, $58
.byte $77, $77, $77, $77
.byte $77, $77, $77, $77
.byte $77, $77, $77, $77
.byte $77, $77, $77, $77
.byte $77, $77, $77, $77
.byte $77, $77, $77, $77
.byte $77, $77, $77, $77
.byte $77, $77, $77, $77
"""

metatile_definitions, metatile_map = create_metatiles(raw_data)
print("Metatile Definitions:")
print(metatile_definitions)
print("\nMetatile Map:")
print(metatile_map)
