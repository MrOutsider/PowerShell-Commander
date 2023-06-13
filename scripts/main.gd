extends Node

@onready var console_outut = %CONSOLE_OUTPUT

var windows : Dictionary = {}
var LockedAccountsID : int = -1
var listOfLockedUsers : Dictionary = {}

@export var WIN_PING : Window
@export var WIN_IPCONFIG : Window
@export var WIN_AD : Window
@export var WIN_AD_NEW : Window
@export var WIN_DELPROF2 : Window
@export var WIN_PS_LOGGED_ON : Window

func _ready():
	$Main_Window.show()
	
	windows.WIN_PING = WIN_PING
	windows.WIN_IPCONFIG = WIN_IPCONFIG
	windows.WIN_AD = WIN_AD
	windows.WIN_AD_NEW = WIN_AD_NEW
	windows.WIN_DELPROF2 = WIN_DELPROF2
	windows.WIN_PS_LOGGED_ON = WIN_PS_LOGGED_ON
	
	WIN_PING.consoleMSG.connect(addToConsole)
	WIN_IPCONFIG.consoleMSG.connect(addToConsole)
	var _win_pingTab : MenuButton = %IP_COMMAND_TABS
	var _win_pingPop : PopupMenu = _win_pingTab.get_popup()
	_win_pingPop.id_pressed.connect(IPCommandTabMenu)
	
	WIN_AD.consoleMSG.connect(addToConsole)
	var _ADTab : MenuButton = %ACTIVE_DIRECTORY_TABS
	var _ADPop : PopupMenu = _ADTab.get_popup()
	_ADPop.id_pressed.connect(ADTabMenu)
	
	WIN_AD_NEW.consoleMSG.connect(addToConsole)
	
	WIN_DELPROF2.consoleMSG.connect(addToConsole)
	WIN_PS_LOGGED_ON.consoleMSG.connect(addToConsole)
	var _DelTab : MenuButton = %APPS
	var _DelPop : PopupMenu = _DelTab.get_popup()
	_DelPop.id_pressed.connect(AppTabMenu)

func _process(_delta):
	if (Input.is_action_pressed("ui_cancel")):
		if (LockedAccountsID != -1):
			self.get_child(LockedAccountsID).queue_free()
			LockedAccountsID = -1
		for i in windows:
			windows[i].hide()
			windows[i].reset()

func signalClearConsole() -> void:
	clearConsole()

func clearConsole() -> void:
	console_outut.text = ""

func addToConsole(cInput : String) -> void:
	console_outut.text += cInput
	console_outut.text += "\n" + "[center][color=hotpink]<(^^<) (>^^)> (>^^<) ([b]Line Brake[/b]) (>^^<) <(^^<) (>^^)>[/color][/center]" + "\n"

func consoleCommand(cmdArg : PackedStringArray) -> void:
	var _consoleBuffer : Array = []
	OS.execute("POWERSHELL.exe", cmdArg, _consoleBuffer, true)
	var _consoleOutput : String = _consoleBuffer[0]
	addToConsole(_consoleOutput)

func consoleCommandADLocked(cmdArg : PackedStringArray) -> void:
	var _consoleBuffer : Array = []
	OS.execute("POWERSHELL.exe", cmdArg, _consoleBuffer, true)
	var _consoleOutput : String = _consoleBuffer[0]
	
#	Populate Locked Accounts Dict : listOfLockedUsers
	if "SamAccountName" in _consoleOutput:
		listOfLockedUsers.clear()
		var placeHolderLoop : bool = true
#		Username
		var placeHolderAccountName : int = 0
		var placeHolderOffsetAccountName : int = 0
#		Password Expired
		var placeHolderPasswordExpired : int = 0
		var placeHolderOffsetPasswordExpired : int = 0
		
		var numOfLockedUsers : int = 0
		while (placeHolderLoop):
			placeHolderAccountName = _consoleOutput.findn("SamAccountName", placeHolderAccountName) + 1
			placeHolderOffsetAccountName = _consoleOutput.findn("SID", placeHolderAccountName) + 1
			
			placeHolderPasswordExpired = _consoleOutput.findn("PasswordExpired", placeHolderPasswordExpired) + 1
			placeHolderOffsetPasswordExpired = _consoleOutput.findn("PasswordNeverExpires", placeHolderPasswordExpired) + 1
			if (placeHolderAccountName == 0):
				placeHolderLoop = false
				var newWin : Window = Window.new()
				createLockedAccountsWindow(newWin)
			else:
				var user : Dictionary = {
					"SamAccountName" : _consoleOutput.substr(placeHolderAccountName + 23, placeHolderOffsetAccountName - 26 - placeHolderAccountName),
					"PasswordExpired" : _consoleOutput.substr(placeHolderPasswordExpired + 23 , placeHolderOffsetPasswordExpired - 26 - placeHolderPasswordExpired)
					}
				listOfLockedUsers[str(numOfLockedUsers)] = user
				numOfLockedUsers += 1
			
		_consoleOutput = _consoleOutput.replacen("SamAccountName", "[color=green]SamAccountName")
		_consoleOutput = _consoleOutput.replacen("SID", "[/color]SID")
		_consoleOutput = _consoleOutput.replacen("PasswordExpired       : True", "[color=darkred]PasswordExpired       : True[/color]")
		_consoleOutput = _consoleOutput.replacen("PasswordExpired       : False", "[color=darkgreen]PasswordExpired       : False[/color]")
	addToConsole(_consoleOutput)

func createLockedAccountsWindow(_win : Window) -> void:
	if (LockedAccountsID != -1):
		self.get_child(LockedAccountsID).queue_free()
		await (get_tree().create_timer(0.25).timeout)
	self.add_child(_win)
	LockedAccountsID = _win.get_index()
	_win.name = "Locked_Accounts"
	_win.title = "Locked Accounts"
	_win.position = Vector2(50, 100)
	_win.min_size = Vector2(500, 100)
	_win.size = Vector2(500, 200)
	var closeWin := func() -> void:
		LockedAccountsID = -1
		_win.queue_free()
	_win.close_requested.connect(closeWin)
	var margin : MarginContainer = MarginContainer.new()
	_win.add_child(margin)
	margin.anchors_preset = 15 # PRESET_FULL_RECT
	var margin_value = 10
	margin.add_theme_constant_override("margin_top", margin_value)
	margin.add_theme_constant_override("margin_left", margin_value)
	margin.add_theme_constant_override("margin_bottom", margin_value)
	margin.add_theme_constant_override("margin_right", margin_value)
	var scroll : ScrollContainer = ScrollContainer.new()
	margin.add_child(scroll)
	scroll.anchors_preset = 15 # PRESET_FULL_RECT
	var hBox : HBoxContainer = HBoxContainer.new()
	scroll.add_child(hBox)
	hBox.anchors_preset = 15 # PRESET_FULL_RECT
	hBox.add_theme_constant_override("separation", 20)
	var vBoxUser : VBoxContainer = VBoxContainer.new()
	var vBoxPass : VBoxContainer = VBoxContainer.new()
	hBox.add_child(vBoxUser)
	hBox.add_child(vBoxPass)
	vBoxUser.add_theme_constant_override("separation", 10)
	vBoxPass.add_theme_constant_override("separation", 10)
	vBoxUser.anchors_preset = 15 # PRESET_FULL_RECT
	vBoxPass.anchors_preset = 15 # PRESET_FULL_RECT
	var itemUsernameTitle : Label = Label.new()
	vBoxUser.add_child(itemUsernameTitle)
	itemUsernameTitle.text = "Usernames"
	var vBoxPassTitle : Label = Label.new()
	vBoxPass.add_child(vBoxPassTitle)
	vBoxPassTitle.text = "Password Expired"
		
	for users in listOfLockedUsers:
		var itemUsername : Label = Label.new()
		vBoxUser.add_child(itemUsername)
		itemUsername.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		itemUsername.text = listOfLockedUsers[users]["SamAccountName"]
		
		var userItemColor : ColorRect = ColorRect.new()
		itemUsername.add_child(userItemColor)
		userItemColor.anchors_preset = 15 # PRESET_FULL_RECT
		userItemColor.color = Color(0.5, 0.5, 0.5, 0.5)
		userItemColor.show_behind_parent = true
		
		var changeUserItemSize := func() -> void:
			userItemColor.size = itemUsername.size
		itemUsername.resized.connect(changeUserItemSize)
		
		var itemPassword : Label = Label.new()
		vBoxPass.add_child(itemPassword)
		itemPassword.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		itemPassword.text = listOfLockedUsers[users]["PasswordExpired"]
		
		var passItemColor : ColorRect = ColorRect.new()
		itemPassword.add_child(passItemColor)
		passItemColor.anchors_preset = 15 # PRESET_FULL_RECT
		passItemColor.color = Color(0.5, 0.5, 0.5, 0.5)
		passItemColor.show_behind_parent = true
		
		var changePassItemSize := func() -> void:
			passItemColor.size = itemPassword.size
		itemPassword.resized.connect(changePassItemSize)
		
	_win.show()

func IPCommandTabMenu(id : int) -> void:
	match id:
		0:
			WIN_PING.hide()
			WIN_PING.reset()
			WIN_PING.show()
		1:
			WIN_IPCONFIG.hide()
			WIN_IPCONFIG.reset()
			WIN_IPCONFIG.show()

func ADTabMenu(id : int) -> void:
	match id:
		0:
			WIN_AD_NEW.hide()
			WIN_AD_NEW.reset()
			WIN_AD_NEW.show()
		1:
			WIN_AD.hide()
			WIN_AD.reset()
			WIN_AD.show()
		2:
			consoleCommandADLocked(["Search-AdAccount", "-LockedOut"])

func AppTabMenu(id : int) -> void:
	match id:
		1:
			WIN_DELPROF2.hide()
			WIN_DELPROF2.reset()
			WIN_DELPROF2.show()
		2:
			WIN_PS_LOGGED_ON.hide()
			WIN_PS_LOGGED_ON.reset()
			WIN_PS_LOGGED_ON.show()
