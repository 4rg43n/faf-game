@tool
class_name LUTPercentile extends Resource

@export var update_all_values_to_sum_to_100 : bool = true

##LUT needs to add up to 100% or 100
@export var percentage_chance : PackedInt32Array = [] :
	set(value):
		var old_size : int = percentage_chance.size()
		var new_size : int = value.size()
		if update_all_values_to_sum_to_100:
			var changed_index : int = -1
			for i : int in new_size:
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
			for i : int in new_size:
				if i == changed_index:
					continue
				var percentage_of_sum : float = value[i] / sum
				value[i] = ceili(value[i] + percentage_of_sum * difference)


		#big num first small num last :3c
		var new_objects : Array[Resource] = []
		new_objects.resize(new_size)
		objects.resize(new_size)
		var pairs : Array = []
		for i in new_size:
			pairs.append([value[i], objects[i]])
		pairs.sort_custom(sort_pairs)
		for i in new_size:
			var pair = pairs[i]
			value[i] = pair[0]
			new_objects[i] = pair[1]

		percentage_chance = value
		objects = new_objects
		property_list_changed.emit()

@export var objects : Array[Resource] = [] :
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

func sort_pairs(a : Array, b : Array) -> bool:
	return a[0] > b[0]
