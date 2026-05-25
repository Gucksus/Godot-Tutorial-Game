extends Label

var score = 0

func increaseScore():
	score += 1
	text = "SCORE: " + str(score)
