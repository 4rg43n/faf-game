class_name FishSpawner extends Node3D

@export var spawnFrequency: float
@export var maxFishesPerSpawn: int
@export var minFishesPerSpawn: int
@export var spawnRadius: float

var spawnTimer : float = 0

var _initialized: bool
var _connected: bool

func _ready() -> void:
	self._initialized = false
	self._connected = false

func _process(_delta: float) -> void:
	if self._connected:
		return
	self._initialized = false
	LobbyManager.instance.lobby_created_succesfully.connect(mark_as_initialized)
	LobbyManager.instance.started_single_player.connect(mark_as_initialized)
	self._connected = true

func mark_as_initialized():
	self._initialized = true
	self.spawnTimer = self.spawnFrequency
