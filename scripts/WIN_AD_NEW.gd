extends Window

# TODO:
# 1. Sheriffs -> Sheriff's
# 2. Adding User to Groups

signal consoleMSG(text : String)

@export var first_name : LineEdit
@export var last_name : LineEdit
@export var username : LineEdit
@export var password : LineEdit
@export var badge : LineEdit
@export var user_position : MenuButton

@onready var positions_file : String = "positions.cfg"

var positions : Dictionary = {}

var config : Dictionary = {"distinguishedName" : "", "description" : "", "title" : "", "department" : "",
"company" : ""}
var list_of_groups : Dictionary = {1 : "Patrol Global"}

func _ready():
	Load_Positions_Config()
	
	var user_pos_popup : PopupMenu = user_position.get_popup()
	for n in positions.values():
		user_pos_popup.add_item(n.Name)
	user_pos_popup.id_pressed.connect(User_Position_Menu_Popup)

func _on_close_requested() -> void:
	hide()

func reset() -> void:
	position = Vector2i(50,100)
	list_of_groups = {}
	config.distinguishedName = ""
	config.description = ""
	config.title = ""
	config.department = ""
	config.company = ""
	first_name.text = ""
	last_name.text = ""
	username.text = ""
	password.text = ""
	badge.text = ""
	user_position.text = "Position"

func consoleCommand(cmdArg : PackedStringArray) -> String:
	var _consoleBuffer : Array = []
	OS.execute("POWERSHELL.exe", cmdArg, _consoleBuffer, true)
	return _consoleBuffer[0]

func User_Position_Menu_Popup(id : int) -> void:
	for n in positions.keys():
		if (str_to_var(n) == id):
			user_position.text = positions[n].Name
			config.distinguishedName = positions[n].data.distinguishedName
			config.description = positions[n].data.description
			config.title = positions[n].data.title
			config.department = positions[n].data.department
			config.company = positions[n].data.company
			break

func _on_button_pressed() -> void:
	if (config.distinguishedName != ""):
		var badge_text : String = ""
		if (badge.text != ""):
			badge_text = " #" + badge.text 

		var _textBuffer : String = consoleCommand([
			"New-ADUser",
			"-Name", username.text.to_lower(),
			"-SamAccountName", username.text.to_lower(),
			"-UserPrincipalName", str(username.text + "@kcsdadmn.com").to_lower(),
			"-GivenName", first_name.text,
			"-Surname", last_name.text,
			"-DisplayName", str(first_name.text + "' '" + last_name.text),
			"-EmailAddress", str(first_name.text.left(1) + last_name.text + "@kcgov.us").to_lower(),
			"-AccountPassword", str("(ConvertTo-SecureString -AsPlainText " + password.text + " -Force)"),
			"-CannotChangePassword",  "$false",
			"-ChangePasswordAtLogon", "$true",
			"-Description", str(config.description + badge_text).replace(" ", "' '"),
			"-Title", config.title.replace(" ", "' '"),
			"-Department", config.department.replace(" ", "' '"),
			"-Company", config.company.replace(" ", "' '"),
			"-Path", config.distinguishedName.replace(",", "','"),
			"-Profilepath", str("\\\\kcsdadmn.com\\userfilespace\\UserProfiles\\" + username.text.to_lower()),
			"-Enabled $false"
		])
		
		consoleMSG.emit("User Creation Attempt. \n" + _textBuffer)
		
		for group in list_of_groups.values():
			_textBuffer = consoleCommand(["Add-ADGroupMember", "-Identity", group.replace(" ", "\' \'"), "-Members", username.text])
			consoleMSG.emit(username.text + " Add to " + group + ".")

func Load_Positions_Config() -> void:
	if (FileAccess.file_exists(positions_file)):
		var file = FileAccess.open(positions_file, FileAccess.READ)
		var text : String = file.get_as_text()
		file.open(positions_file, FileAccess.READ)
		var json : JSON = JSON.new()
		var error = json.parse(text)
		if error == OK:
			positions = json.data
			if typeof(positions) == TYPE_ARRAY:
				print(positions) # Prints array
			else:
				print("Unexpected data")
		else:
			print("JSON Parse Error: ", json.get_error_message(), " in ", text, " at line ", json.get_error_line())
		file = null
