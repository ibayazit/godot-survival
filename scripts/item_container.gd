extends TextureRect

@onready var item_texture = $ItemTexture

var upgrade = null

func _ready():
	item_texture.texture = load(UpgradeDb.UPGRADES[upgrade]["icon"])
	
