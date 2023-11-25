extends Control

@onready var item_list = get_node("VBoxContainer/ScrollContainer/MarginContainer/ItemList")
@onready var world_container = get_node("VBoxContainer/ScrollContainer/MarginContainer/VBoxContainer")


func _on_create_pressed():
	var button = Button.new()

	# Set the text on the button
	button.text = "Click me!Click me!Click me!Click me!Click me!Click me!Click me!Click me!Click me!Click me!"
	button.custom_minimum_size.x = 380
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT

	# Connect the button's "pressed" signal to a function
#	button.connect("pressed", self, "_on_button_pressed")

	# Add the button as a child of the current node (replace 'self' with the desired parent node)
	world_container.add_child(button)
#	item_list.add_item("New item")


func _on_manage_worlds_button_pressed():
	visible = !visible
