class_name ArrayUtils

# Shifts the array's values by a specified amount.
# Positive amount shifts right while negative shifts left.
static func shift_array(array : Array, amount : int):
	var right = bool(sign(amount) * 0.5 + 0.5)
	for i in abs(amount):
		var value
		if right:
			value = array.pop_back()
			array.push_front(value)
		else:
			value = array.pop_front()
			array.push_back(value)


# Splits the array between a and b at index.
static func split_array(array : Array, index : int, a : Array, b : Array):
	for i in range(0, index):
		a.append(array[i])

	for i in range(index, array.size()):
		b.append(array[i])

# Converts array to dictionary
static func to_dictionary(array : Array) -> Dictionary:
	var dict = {}
	for i in array.size():
		dict[i] = array[i]
	return dict
