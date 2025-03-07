extends ColorRect

@onready var player = get_tree().get_first_node_in_group("player")
@onready var lbl_name = $lbl_name
@onready var lbl_description = $lbl_description
@onready var lbl_level = $lbl_level
@onready var item_icon = $ColorRect/ItemIcon

var mouse_over = false
var item = null

signal selected_upgrade(upgrade)

func _ready():
	connect("selected_upgrade", Callable(player, "upgrade_character"))
	if item == null:
		item = "food"
	lbl_name.text = UpgradeDb.UPGRADES[item]["displayname"]
	lbl_description.text = UpgradeDb.UPGRADES[item]["details"]
	lbl_level.text = UpgradeDb.UPGRADES[item]["level"]
	item_icon.texture = load(UpgradeDb.UPGRADES[item]["icon"])

func _input(event):
	if event.is_action("click"):
		if mouse_over:
			emit_signal("selected_upgrade", item)

func _on_mouse_entered():
	mouse_over = true


func _on_mouse_exited():
	mouse_over = false
