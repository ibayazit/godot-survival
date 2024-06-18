extends Area2D

@onready var collision = $CollisionShape2D
@onready var disableTimer = $DisableHitBoxTimer

@export var damage = 1

func tempDisable():
	collision.call_deferred("set", "disabled", true)
	disableTimer.start()


func _on_disable_hit_box_timer_timeout():
	collision.call_deferred("set", "disabled", false)
