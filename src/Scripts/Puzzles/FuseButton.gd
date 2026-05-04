extends StaticBody3D

var fuse_parent = null
var grid_index = 0

func interact():
	if fuse_parent:
		fuse_parent.toggle_fuse(grid_index, self)
