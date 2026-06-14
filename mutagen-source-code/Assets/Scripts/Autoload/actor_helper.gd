extends Node
@export var targetters : int = 0 ## count of how many enemies are currently chasing the player


# NPC Actors

# Animation Switching from Triggers

func animate(object : Node, animationName : String, animationNode : String = "AnimatedSprite2D"):
	if object.has_node(animationNode):
		object.get_node(animationNode).play(animationName)
	else:
		print('ACTOR HELPER ISN"T WORKIIIIING')
