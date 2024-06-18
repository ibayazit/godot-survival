extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D

# GUI
@onready var expBar = %ExperienceBar
@onready var lblLevel = %lbl_level
@onready var levelPanel = %LevelUp
@onready var upgradeOptions = %UpgradeOptions
@onready var sndLevelup = %snd_levelup
@onready var itemOption = preload("res://scenes/item_option.tscn")
@onready var healthBar = %HealthBar
@onready var lbl_timer = %lblTimer
@onready var collectedWeapons = %CollectedWeapons
@onready var collectedUpgrades = %CollectedUpgrades
@onready var itemContainer = preload("res://scenes/item_container.tscn")

@onready var deathPanel = %DeathPanel
@onready var lblResult = $GUILayer/GUI/DeathPanel/lbl_Result
@onready var sndVictory = $GUILayer/GUI/DeathPanel/snd_victory
@onready var sndLose = $GUILayer/GUI/DeathPanel/snd_lose

var movement_speed = 40.0
var coordinates = Vector2.ZERO
var maxhp = 100.0
var hp = 40.0
var last_movment = Vector2.UP
var time = 0

var experience = 0
var experience_level = 1
var collected_experience = 0

# Upgrades
var collected_upgrades = []
var upgrade_options = []
var armor = 0
var speed = 0
var spell_cooldown = 0
var spell_size = 0
var additional_attacks = 0

# Attacks
var iceSpear = preload("res://scenes/ice_spear.tscn")
var tornado = preload("res://scenes/tornado.tscn")
var javelin = preload("res://scenes/javelin.tscn")

# Attack Nodes
@onready var iceSpearTimer = %IceSpearTimer
@onready var iceSpearAttackTimer = %IceSpearAttackTimer
@onready var tornadoTimer = %TornadoTimer
@onready var tornadoAttackTimer = %TornadoAttackTimer
@onready var javelinBase = $Attack/javelinBase


# Ice Spear
var icespear_ammo = 0
var icespear_baseammo = 0
var icespear_attack_speed = 1.5
var icespear_level = 0

# Tornado
var tornado_ammo = 0
var tornado_baseammo = 0
var tornado_attackspeed = 3
var tornado_level = 0

# Javelin
var javelin_ammo = 0
var javelin_level = 0

# Enemy Related
var enemy_close = []

signal player_death()

func _ready():
	upgrade_character("icespear1")
	attack()
	set_expbar(experience, calculate_experiencecap())
	_on_hurt_box_hurt(0, 0, 0)

func _physics_process(_delta):
	coordinates.x = Input.get_axis("left", "right")
	coordinates.y = Input.get_axis("up", "down")
	
	if coordinates.x > 0:
		animated_sprite.flip_h = true
	else:
		animated_sprite.flip_h = false
	
	velocity = coordinates.normalized() * movement_speed
	
	if(coordinates != Vector2.ZERO):
		last_movment = coordinates

	move_and_slide()

func attack():
	if icespear_level > 0:
		iceSpearTimer.wait_time = icespear_attack_speed * (1-spell_cooldown)
		if iceSpearTimer.is_stopped():
			iceSpearTimer.start()
	if tornado_level > 0:
		tornadoTimer.wait_time = tornado_attackspeed * (1-spell_cooldown)
		if tornadoTimer.is_stopped():
			tornadoTimer.start()
	if javelin_level > 0:
		spawn_javelin()

func _on_hurt_box_hurt(damage, _angle, _knockback):
	hp -=  clamp(damage - armor, 1.0, 999.0)
	healthBar.max_value = maxhp
	healthBar.value = hp
	
	if hp <= 0:
		death()


func _on_ice_spear_timer_timeout():
	icespear_ammo += icespear_baseammo + additional_attacks
	iceSpearAttackTimer.start()


func _on_ice_spear_attack_timer_timeout():
	if icespear_ammo > 0:
		var icespear_attack = iceSpear.instantiate()
		icespear_attack.position = position
		icespear_attack.target = get_random_target()
		icespear_attack.level = icespear_level
		add_child(icespear_attack)
		icespear_ammo -= 1
		if icespear_ammo > 0:
			iceSpearAttackTimer.start()
		else:
			iceSpearAttackTimer.stop()
	

func _on_tornado_timer_timeout():
	tornado_ammo += tornado_baseammo + additional_attacks
	tornadoAttackTimer.start()


func _on_tornado_attack_timer_timeout():
	if tornado_ammo > 0:
		var tornado_attack = tornado.instantiate()
		tornado_attack.position = position
		tornado_attack.last_movement = last_movment
		tornado_attack.level = tornado_level
		add_child(tornado_attack)
		tornado_ammo -= 1
		if tornado_ammo > 0:
			tornadoAttackTimer.start()
		else:
			tornadoAttackTimer.stop()
	
func spawn_javelin():
	var get_javelin_total = javelinBase.get_child_count()
	var calc_spawns = (javelin_ammo + additional_attacks) - get_javelin_total
	while calc_spawns > 0:
		var javelin_spawn = javelin.instantiate()
		javelin_spawn.global_position = global_position
		javelinBase.add_child(javelin_spawn)
		calc_spawns -= 1
		
	var get_javelins = javelinBase.get_children()
	for i in get_javelins:
		if i.has_method("update_javelin"):
			i.update_javelin()
	
func get_random_target():
	if enemy_close.size() > 0:
		return enemy_close.pick_random().global_position
	else:
		return Vector2.UP

func calculate_experience(gem_exp):
	var exp_required = calculate_experiencecap()
	collected_experience += gem_exp
	
	if experience + collected_experience >= exp_required:
		collected_experience -= exp_required - experience
		experience = 0
		experience_level += 1
		exp_required = calculate_experiencecap()
		level_up()
	else:
		experience += collected_experience
		collected_experience = 0
		
	set_expbar(experience, exp_required)
	
func calculate_experiencecap():
	var exp_cap = experience_level
	
	if experience_level < 20:
		exp_cap = experience_level * 5
	elif experience_level < 40:
		exp_cap = 95 * (experience_level-19)*8
	else:
		exp_cap = 255 + (experience_level-39)*12
		
	return exp_cap
	
func set_expbar(set_value = 1, set_max_value = 100):
	expBar.value = set_value
	expBar.max_value = set_max_value
	
func level_up():
	sndLevelup.play()
	lblLevel.text = "Level:" + str(experience_level)
	
	levelPanel.position = Vector2(100,100)
	levelPanel.visible = true
	
	var options = 0
	var optionsMax = 3
	while  options < optionsMax:
		var optionChoice = itemOption.instantiate()
		optionChoice.item = get_random_item()
		upgradeOptions.add_child(optionChoice)
		options += 1
		
	
	get_tree().paused = true
	
func upgrade_character(upgrade):
	match upgrade:
		"icespear1":
			icespear_level = 1
			icespear_baseammo += 1
		"icespear2":
			icespear_level = 2
			icespear_baseammo += 1
		"icespear3":
			icespear_level = 3
		"icespear4":
			icespear_level = 4
			icespear_baseammo += 2
		"tornado1":
			tornado_level = 1
			tornado_baseammo += 1
		"tornado2":
			tornado_level = 2
			tornado_baseammo += 1
		"tornado3":
			tornado_level = 3
			tornado_attackspeed -= 0.5
		"tornado4":
			tornado_level = 4
			tornado_baseammo += 1
		"javelin1":
			javelin_level = 1
			javelin_ammo = 1
		"javelin2":
			javelin_level = 2
		"javelin3":
			javelin_level = 3
		"javelin4":
			javelin_level = 4
		"armor1","armor2","armor3","armor4":
			armor += 1
		"speed1","speed2","speed3","speed4":
			movement_speed += 20.0
		"tome1","tome2","tome3","tome4":
			spell_size += 0.10
		"scroll1","scroll2","scroll3","scroll4":
			spell_cooldown += 0.05
		"ring1","ring2":
			additional_attacks += 1
		"food":
			hp += 20
			hp = clamp(hp,0,maxhp)
			
	adjust_gui_collection(upgrade)
	attack()
	
	var option_children = upgradeOptions.get_children()
	for i in option_children:
		i.queue_free()
	upgrade_options.clear()
	collected_upgrades.append(upgrade)
	levelPanel.visible = false
	levelPanel.position = Vector2(-500, 0)
	get_tree().paused = false
	calculate_experience(0)
	
func get_random_item():
	var dbList = []
	for i in UpgradeDb.UPGRADES:
		if i in collected_upgrades:
			pass
		elif i in upgrade_options:
			pass
		elif UpgradeDb.UPGRADES[i]["type"] == "item":
			pass
		elif UpgradeDb.UPGRADES[i]["prerequisite"].size() > 0:
			var to_add = true
			for n in UpgradeDb.UPGRADES[i]["prerequisite"]:
				if not n in collected_upgrades:
					to_add = false

			if to_add:
				dbList.append(i)
		else:
			dbList.append(i)
	if dbList.size() > 0:
		var randomItem = dbList.pick_random()
		upgrade_options.append(randomItem)
		return randomItem
	else:
		return null
		
func change_time(argtime = 0):
	time = argtime
	var get_m = int(time/60.0)
	var get_s = time % 60
	
	if get_m < 10:
		get_m = str(0, get_m)
		
	if get_s < 10:
		get_s = str(0, get_s)
		
	lbl_timer.text = str(get_m, ":", get_s)
	
func adjust_gui_collection(upgrade):
	var get_upgrade_displayname = UpgradeDb.UPGRADES[upgrade]["displayname"]
	var get_type = UpgradeDb.UPGRADES[upgrade]["type"]
	
	if get_type != "item":
		var get_collected_displaynames = []
		for i in collected_upgrades:
			get_collected_displaynames.append(UpgradeDb.UPGRADES[i]["displayname"])
		if not get_upgrade_displayname in get_collected_displaynames:
			var new_item = itemContainer.instantiate()
			new_item.upgrade = upgrade
			match get_type:
				"weapon":
					collectedWeapons.add_child(new_item)
				"upgrade":
					collectedUpgrades.add_child(new_item)

func death():
	deathPanel.visible = true
	emit_signal("player_death")
	get_tree().paused = true
	deathPanel.position = Vector2(100,100)
	
	if time >= 300:
		sndVictory.play()
		lblResult.text = "You Win!"
	else:
		sndLose.play()
		lblResult.text = "You Lose!"
	
func _on_enemy_detection_area_body_entered(body):
	if not enemy_close.has(body):
		enemy_close.append(body)


func _on_enemy_detection_area_body_exited(body):
	if enemy_close.has(body):
		enemy_close.erase(body)



func _on_grap_area_area_entered(area):
	if area.is_in_group("loot"):
		area.target = self


func _on_collect_area_area_entered(area):
	if area.is_in_group("loot"):
		var gem_exp = area.collect()
		calculate_experience(gem_exp)


func _on_button_click_end():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
