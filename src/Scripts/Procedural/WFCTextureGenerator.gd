extends Object
class_name WFCTextureGenerator

# Generates a procedural ImageTexture using a simplified Wave Function Collapse algorithm.
static func generate_dungeon_stone_texture(width: int = 32, height: int = 32) -> ImageTexture:
	var states = [0, 1, 2, 3]
	
	# Adjacency rules (symmetric for all 4 directions)
	# 0: Dark Stone, 1: Mid Stone, 2: Mossy Stone, 3: Mortar/Crack
	var allowed_neighbors = {
		0: [0, 1, 3],       # Dark Stone can touch Dark, Mid, Mortar
		1: [0, 1, 2, 3],    # Mid Stone can touch all
		2: [1, 2, 3],       # Moss can touch Mid, Moss, Mortar
		3: [0, 1, 2, 3]     # Mortar can touch all
	}
	
	var weights = [10.0, 10.0, 3.0, 1.5] # Favor large stone blocks
	
	var grid = []
	for i in range(width * height):
		grid.append(states.duplicate())
		
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	var is_collapsed = func():
		for cell in grid:
			if cell.size() > 1: return false
		return true
		
	var get_min_entropy_index = func():
		var min_e = 999999.0
		var min_idx = -1
		for i in range(width * height):
			if grid[i].size() > 1:
				var e = float(grid[i].size()) + rng.randf_range(0.0, 0.1)
				if e < min_e:
					min_e = e
					min_idx = i
		return min_idx
	
	var total_cells = width * height
	var collapsed_count = 0
	
	while not is_collapsed.call() and collapsed_count < total_cells:
		var idx = get_min_entropy_index.call()
		if idx == -1: break
		
		var possible = grid[idx]
		if possible.size() == 0:
			print("[WFC] Contradiction reached at index ", idx)
			break
			
		# Weighted random choice
		var total_weight = 0.0
		for s in possible: total_weight += weights[s]
		var r = rng.randf_range(0.0, total_weight)
		var chosen = possible[0]
		var curr_w = 0.0
		for s in possible:
			curr_w += weights[s]
			if r <= curr_w:
				chosen = s
				break
				
		grid[idx] = [chosen]
		collapsed_count += 1
		
		# Propagate
		var stack = [idx]
		while stack.size() > 0:
			var curr = stack.pop_back()
			var cx = curr % width
			var cy = curr / width
			var curr_possible = grid[curr]
			
			var neighbors = []
			if cx > 0: neighbors.append(curr - 1)
			if cx < width - 1: neighbors.append(curr + 1)
			if cy > 0: neighbors.append(curr - width)
			if cy < height - 1: neighbors.append(curr + width)
			
			var valid_next_states = []
			for s in curr_possible:
				for n_s in allowed_neighbors[s]:
					if not valid_next_states.has(n_s):
						valid_next_states.append(n_s)
						
			for n_idx in neighbors:
				var n_possible = grid[n_idx]
				var changed = false
				var new_n_possible = []
				for ns in n_possible:
					if valid_next_states.has(ns):
						new_n_possible.append(ns)
					else:
						changed = true
				if changed:
					grid[n_idx] = new_n_possible
					if not stack.has(n_idx):
						stack.append(n_idx)

	# Convert to Image
	var img = Image.create(width, height, false, Image.FORMAT_RGBA8)
	var colors = [
		Color(0.6, 0.6, 0.65), # 0: Dark Stone
		Color(0.85, 0.85, 0.85), # 1: Mid Stone
		Color(0.5, 0.7, 0.5),    # 2: Mossy Stone
		Color(0.3, 0.3, 0.3)     # 3: Deep Mortar/Crack
	]
	
	for y in range(height):
		for x in range(width):
			var idx = y * width + x
			var c = Color.MAGENTA # Error color
			if grid[idx].size() > 0:
				c = colors[grid[idx][0]]
			img.set_pixel(x, y, c)
			
	# Return fully formed ImageTexture
	return ImageTexture.create_from_image(img)
