@tool extends Control

@export var select_generated_mesh:bool = true
@export var unselect_other_nodes:bool = true
@export var show_preview:bool = true
@export var origin_name:String = ""

var ei:EditorInterface
var generated_mesh:ArrayMesh

func _enter_tree() -> void:
	## find editor interface
	ei = EditorPlugin.new().get_editor_interface()
	return

func _input(event):
	var t:String = ""
	## build string for selected node list
	var sna:Array = ei.get_selection().get_selected_nodes()
	for n in sna:
		if n is MeshInstance3D:
			t += n.name + "\n"
	t.strip_edges()
	$Panel/ScrollContainer/SelectedNodeList.text = t
	return

func _on_join_button_pressed() -> void:
	## get the selected nodes
	var sna:Array = ei.get_selection().get_selected_nodes()
	
	## collect mesh data from each meshinstance3D selected
	var ma:Array[MeshInstance3D] = []
	for n in sna:
		if is_instance_of(n, MeshInstance3D):
			ma.append(n)
	
	## test if any meshes are selected at all
	if ma.is_empty():
		printerr("MeshReunionPlugin: no MeshInstance3D selected!")
		return
	
	## record name of first mesh in a global variable
	origin_name = ma[0].name
	
	## commit each surface array from each mesh to a single mesh
	var am:ArrayMesh = ArrayMesh.new()
	var surf_count:int = 0
	var mc:int = 0 ## make sure the correct material is applied to the correct surface
	for i in ma.size():
		var m:Mesh = ma[i].mesh
		for sc in m.get_surface_count():
			var sa = m.surface_get_arrays(sc)
			## move vertices to match intended position for each object
			for vi in sa[Mesh.ARRAY_VERTEX].size():
				sa[Mesh.ARRAY_VERTEX][vi] += ma[i].position - ma[0].position
			am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, sa)
			am.surface_set_material(mc, m.surface_get_material(sc))
			mc += 1
	## record mesh in a global variable
	generated_mesh = am
	
	## skip preview and create mesh if desired
	if !show_preview:
		_on_preview_confirm()
		return
	
	## set up preview
	var a:AcceptDialog = AcceptDialog.new()
	add_child(a)
	
	## show preview of combined mesh
	var pa:Array[Texture2D] = ei.make_mesh_previews([am], 1000)
	
	## draw the texture rect
	var c:Control = Control.new()
	var t:TextureRect = TextureRect.new()
	t.anchor_left = 0
	t.anchor_top = 0
	t.anchor_right = 1
	t.anchor_bottom = 1
	t.texture = pa[0]
	t.expand_mode = t.EXPAND_IGNORE_SIZE
	var cr:ColorRect = ColorRect.new()
	cr.color = Color(0.0, 0.0, 0.0, 1.0)
	cr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cr.add_child(t)
	c.add_child(cr)
	
	## draw text
	var l:Label = Label.new()
	c.add_child(l)
	l.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	l.text = "Does this look okay?"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.set("theme_override_font_sizes/font_size", 24)
	cr.offset_bottom -= l.size.y
	
	a.add_child(c)
	a.popup_centered_ratio()
	a.title = "NEW MESH PREVIEW JUST DROPPED!!!"
	a.add_cancel_button("No")
	a.confirmed.connect(_on_preview_confirm)
	return

func _on_preview_confirm() -> void:
	## create meshinstance3D and hand it to the edited scene
	var gm:MeshInstance3D = MeshInstance3D.new()
	gm.mesh = generated_mesh
	
	## name the mesh
	gm.name = origin_name
	if !$NameLine.text.is_empty():
		gm.name = $NameLine.text
	## increment integer at the end of the name string until no sibling shares an identical name
	var siblings:PackedStringArray = []
	for n in ei.get_edited_scene_root().get_children():
		siblings.append(n.name)
	var i:int = 0
	var gmn:String = gm.name
	var gmni:String = ""
	
	while i < gmn.length() && gmn[-i - 1].is_valid_int():
		i += 1
	
	gmni = gmn.substr(gmn.length() - i, -1)
	i = 0
	while gmni[i] == "0":
		i += 1
	gmni = gmni.erase(0, i)
	gmn = gmn.erase(gmn.length() - gmni.length(), gmni.length())
	var c:int = int(gmni)
	
	while siblings.has(gmn + gmni):
		c += 1
		gmni = str(c)
	gmn += gmni
	gm.name = gmn
	
	ei.get_edited_scene_root().add_child(gm)
	gm.owner = ei.get_edited_scene_root()
	ei.edit_node(gm)
	ei.get_selection()
	
	var es:EditorSelection = ei.get_selection()
	
	## remove other nodes from selection if desired
	var sna:Array = es.get_selected_nodes()
	if unselect_other_nodes:
		for n in sna:
			es.remove_node(n)
	
	## select newly created MeshInstance3D if desired
	if select_generated_mesh:
		es.add_node(gm)
	
	return

func _exit_tree() -> void:
	return


func _on_select_mesh_box_toggled(toggled_on):
	select_generated_mesh = toggled_on
	return

func _on_unselect_nodes_box_toggled(toggled_on):
	unselect_other_nodes = toggled_on
	return

func _on_show_preview_box_toggled(toggled_on):
	show_preview = toggled_on
	return
