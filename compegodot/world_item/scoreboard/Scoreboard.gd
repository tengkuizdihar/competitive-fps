extends Spatial

export (String) var scoreboard_prefix = "HIT COUNT: "

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Util.handle_err(Score.connect("score_changed", self, "_on_scoreboard_hit_count"))
	$Scoreboard.text = "SHOOT TARGETS TO START THE COUNT"


func _on_scoreboard_hit_count(value: int) -> void:
	$Scoreboard.text = scoreboard_prefix + str(value)
	$DingPlayer.play()
