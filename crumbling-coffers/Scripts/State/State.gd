@abstract
class_name State
extends Node

signal transitioned

# Enter state, update state, exit state cycle
@abstract func enter()
@abstract func exit()
@abstract func update(delta: float)
@abstract func physics_update(delta: float)
