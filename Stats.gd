extends MarginContainer

const password = "TETRIS 3000"

const SCORES = [
	[0, 4, 1],
	[1, 8, 2],
	[3, 12],
	[5, 16],
	[8]
]
const LINES_CLEARED_NAMES = ["", "SINGLE", "DOUBLE", "TRIPLE", "TETRIS"]
const T_SPIN_NAMES = ["", "T-SPIN", "MINI T-SPIN"]

var level
var goal
var score
var high_score
var time
var combos

signal flash_text(text)
signal level_up

func _ready():
	var save_game = File.new()
	if not save_game.file_exists("user://high_score.save"):
		high_score = 0
	else:
		save_game.open_encrypted_with_pass("user://high_score.save", File.READ, password)
		high_score = int(save_game.get_line())
		$HBC/VBC1/HighScore.text = str(high_score)
		save_game.close()
	
func new_game():
	level = 0
	goal = 0
	score = 0
	time = 0
	combos = -1
	
func new_level():
	level += 1
	goal += 5 * level
	$HBC/VBC1/Level.text = str(level)
	$HBC/VBC1/Goal.text = str(goal)
	emit_signal("flash_text", "Level\n%d"%$level)
	emit_signal("level_up")

func _on_Clock_timeout():
	var time_elapsed = OS.get_system_time_secs() - time
	var seconds = time_elapsed % 60
	var minutes = int(time_elapsed/60) % 60
	var hours = int(time_elapsed/3600)
	$HBC/VBC1/Time.text = str(hours) + ":%02d"%minutes + ":%02d"%seconds


func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		var save_game = File.new()
		save_game.open_encrypted_with_pass("user://high_score.save", File.WRITE, password)
		save_game.store_line(str(high_score))
		save_game.close()
		get_tree().quit()

func _on_Main_piece_dropped(score):
	score += lines
	$HBC/VBC1/Score.text = str(score)

func _on_Main_piece_locked(lines, t_spin):
	if lines or t_spin:
		if t_spin:
			$FlashText.print(T_SPIN_NAMES[current_piece.t_spin])
		if lines:
			$FlashText.print(LINES_CLEARED_NAMES[lines_cleared])
		var ds = SCORES[lines_cleared][current_piece.t_spin]
		goal -= ds
		$HBC/VBC1/Goal.text = str(goal)
		ds *= 100
		emit_signal("flash_text", str(ds))
		score += ds
		$HBC/VBC1/Score.text = str(score)
		if score > high_score:
			high_score = score
			$HBC/VBC1/HighScore.text = str(high_score)
	# Combos
	if lines:
		combos += 1
		if combos > 0:
			score += (20 if lines==1 else 50) * combos * level
			$HBC/VBC1/Score.text = str(score)
			if $Stats.combos == 1:
				emit_signal("flash_text", "COMBO")
			else:
				emit_signal("flash_text", "COMBO x%d"%$Stats.combos)
	else:
		$Stats.combos = -1
	if $Stats.goal <= 0:
		new_level()