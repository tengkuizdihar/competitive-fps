extends Spatial

export (String) var scoreboard_prefix = "HIT COUNT: "

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	State.connect("STATE_SCOREBOARD_HIT_COUNT", self, "_on_scoreboard_hit_count")
	$Scoreboard.text = "SHOOT TARGETS TO START THE COUNT"


func _on_scoreboard_hit_count(value: int) -> void:
	$Scoreboard.text = scoreboard_prefix + str(value)
	$DingPlayer.play()
