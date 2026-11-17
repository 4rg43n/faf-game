@tool
class_name LUTPercentile extends Resource

##LUT needs to add up to 100% or 100
@export var percentage_chance : PackedInt32Array = [] :
	set(value):
		var old_size : int = percentage_chance.size()
		var new_size : int = value.size()
		print("old_size ", old_size)
		print("new_size ", new_size)
		var changed_index : int = -1
		for i in new_size:
			if i >= old_size:
				break
			if value[i] != percentage_chance[i]:
				changed_index = i
				break

		#does not include new value
		var sum : float = 0
		for i in new_size:
			if i == changed_index:
				continue
			sum += value[i]

		var difference : float = 100 - (sum + value[changed_index])
		for i in new_size:
			if i == changed_index:
				continue
			var percentage_of_sum : float = value[i] / sum
			value[i] = ceili(value[i] + percentage_of_sum * difference)

		percentage_chance = value

		#big num first small num last :3c
		percentage_chance.sort()
		percentage_chance.reverse()
		objects.resize(new_size)

		#keep objects sorted with percentage_chance
		var left_4_dead := percentage_chance.duplicate()
		for i in new_size:
			var index_to_swap_from := left_4_dead.find(value[i])
			left_4_dead.erase(value[i])
			var old_value = objects[index_to_swap_from]
			objects[index_to_swap_from] = objects[i]
			objects[i] = old_value
		property_list_changed.emit()

@export var objects : Array = [] :
	set(value):
		objects = value
		percentage_chance.resize(objects.size())
		property_list_changed.emit()

func roll_for_object() -> Variant:
	if objects.is_empty():
		return null
	var roll : int = randf_range(0, 100)
	var index_chosen : int = 0
	var size : int = percentage_chance.size()
	for i in size:
		var max_value : int = percentage_chance[i]
		if roll > max_value:
			roll -= max_value
			continue
		index_chosen = i
		break
	return objects[index_chosen]
