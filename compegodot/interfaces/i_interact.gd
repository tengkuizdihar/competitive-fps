extends Node
class_name IInteract

# interactor should be the "player" or "npc" that's interacting with this button.
signal interacted(interactor)

func interact(interactor) -> void:
	emit_signal("interacted", interactor)
