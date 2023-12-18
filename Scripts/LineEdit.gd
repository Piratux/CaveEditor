extends LineEdit


# Filter string, by leaving only following characters:
# 0-9, a-z, A-Z, -, _
func sanitize_string(input_string: String) -> String:
	var sanitized_string = ""

	for i in input_string.length():
		var ch = input_string[i]
		var char_code = input_string.unicode_at(i)
		if (char_code >= 48 and char_code <= 57) or \
			(char_code >= 65 and char_code <= 90) or \
			(char_code >= 97 and char_code <= 122) or \
			ch == "_" or ch == "-":
			sanitized_string += ch
	
	return sanitized_string

func _on_text_changed(new_text):
	var column = get_caret_column()
	set_text(sanitize_string(new_text))
	set_caret_column(column)
