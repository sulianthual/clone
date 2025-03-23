extends Button

# button with drag and drop of color

func get_image_colors(filename_:String,max_colors:int)->Array[Color]:
	var colors_found: Array[Color]=[]
	if FileAccess.file_exists(filename_):# overwrite an existing file editing a subset
		var _new_img: Image=Image.new()
		_new_img.convert(Image.FORMAT_RGBA8)
		_new_img=image_load(filename_)
		var maxed_out: bool=false
		for _iy in _new_img.get_height():
			if maxed_out:
				break
			for _ix in _new_img.get_width():
				if maxed_out:
					break
				var _col: Color=_new_img.get_pixel(_ix, _iy)
				if _col!=Color.BLACK and _col.a>0 and _col not in colors_found:
					colors_found.append(_col)
					if len(colors_found)>=max_colors:
						maxed_out=true
	return colors_found

func image_load(filename_: String)->Image:# image must be loaded as textures then converted
	if FileAccess.file_exists(filename_):
		var _texture: CompressedTexture2D=load(filename_)
		return _texture.get_image()
	else:
		return Image.new()
