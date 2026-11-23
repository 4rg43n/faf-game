class_name Damageable extends Node

signal damaged(amount: float, source: Node)
signal died(source: Node)

@export var maxHealth: float = 100.0
@export var iFramesEnabled: bool = true
@export var iFrameDuration: float = 1.0

var health: float
var inIFrames: bool = false

var iFrameTimer: float = 0.0

func _ready() -> void:
	health = maxHealth


func take_damage(amount: float, source: Node) -> void:
	if inIFrames:
		return
	health -= amount
	damaged.emit(amount, source)
	if iFramesEnabled:
		inIFrames = true
		iFrameTimer = iFrameDuration
	if health <= 0.0:
		died.emit(source)


func _process(delta: float) -> void:
	if not inIFrames:
		return
	iFrameTimer -= delta
	if iFrameTimer <= 0.0:
		inIFrames = false
