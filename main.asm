#####################################################################
#
# CSC258H5S Winter 2022 Assembly Final Project
# University of Toronto, St. George
#
# Student: Mark Bedawyi, 1007075479
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 512
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestone is reached in this submission?
# - Milestone 5
#
# Which approved additional features have been implemented?
# Easy:
# 1. Change the direction the frog is pointing
# 2. Have the cars and logs move at different speeds
# 3. Display the number of lives remaining.
# 4. Randomize the size of the logs and cars in the scene.
# 5. Displaying a pause screen or image when the ‘p’ key is pressed, and returning to the game when ‘p’ is pressed again.
# 6. Add a time limit to the game.
# 7. Add sound effects for movement, losing lives, collisions, and reaching the goal.
# 8. Dynamic increase in difficulty (speed, obstacles, etc.) as game progresses
# 9. Add a third row in each of the water and road sections. (I added four of each to fill up the screen)
#
# Hard:
# 10. Display the player’s score at the top of the screen.
#
# Any additional information that the TA needs to know:
# - The increase in difficulty is as folloes: when the number of goals is
#	1: The number of cars doubles
#     	2: The speed of all cars increase
#	3: The speed of all logs increase
#	4: The timer is reset, but now moves faster
# 	5: The number of logs cut in half
#	6: The size of all logs decreases by 1
#	7: The size of all cars increases by 1
#
###################################################################

# TODO: Fix log movement so that the frog can move even if there is an overflow, just that the x coordinate is now zero
# TODO: Have collisions decrease the score by 10
# TODO: Have the pause screen say 'pause'

# Frogger in MIPS
#
# Note that the size of the frog is written in number of pixels
# The size of the display is in number of bytes across (this turned out to be more convenient than number of pixels)
# The size of all other objects is relative to the size of the frog, i.e. a size of num is sizeFrog * num pixels

# The y-coordinate is relative to the number of frogs
# The x-coordinate is relative to the number of pixels

.data
	displayAddress:		.word 0x10008000
	
	lives:			.byte 3
	score:			.word 0
	frogLocation:		.half 12, 15
	startingFrogLocation:	.half 12, 15
	frogDirection:		.byte 0  # Stores the direction the frog is pointing at
					 # 0 is forward, 1 is left, 2 is down, 3 is right

	randomizeSizes:		.byte 1  # Randomize the size of the cars and logs if non-zero
	carLocations:		.byte 28, 12, 0, 16, 28, 12, 0, 16
	carSizes:		.byte 2, 2, 2, 2, 2, 2, 2, 2
	carSpeeds:		.byte 1, 1, 2, 2, 1, 1, 2, 2  # Speeds must be positive
	carWait:		.word 10  # The number of iterations to wait until movement
	currentCarWait:		.word 0
	logLocations:		.byte 8, 24, 4, 20, 8, 24, 4, 20
	logSizes:		.byte 2, 2, 2, 2, 2, 2, 2, 2
	logSpeeds:		.byte -1, -1, -2, -2, -1, -1, -2, -2 # Speeds can be positive or negative
	logWait:		.word 10  # The number of iterations to wait until movement
	currentLogWait:		.word 0
	numCarsTotal:		.byte 4
	numLogsTotal:		.byte 8
	numCarsPerRow:		.byte 1
	numLogsPerRow:		.byte 2
	
	numGoalsFilled:		.byte 0  # Used to decide difficulty
	
	goals:			.byte 0, 0, 0, 0, 0, 0, 0, 0
	numGoals:		.byte 8
	
	scoreColor:		.word 0x00000000
	grassColor: 		.word 0x0000ff00
	waterColor: 		.word 0x000000ff
	safeColor:		.word 0x00ffff00
	roadColor:		.word 0x00808080
	frogColor:		.word 0x00663399
	carColor:		.word 0x00ff0000
	logColor:		.word 0x00b5651d
	lifeColor:		.word 0x00ff0000
	goalColor:		.word 0x00ffffff
	timeColor:		.word 0x00ffc0cb
	pauseColor:		.word 0x0004260c
	
	sizeDisplay:		.half 128  # Num bytes for every row in the display
	pixelsInDisplay:	.byte 32   # Num pixels for every row in the display
	pixelsInDisplayDown:	.byte 64   # Num pixels down the display
	sizeFrog:		.byte 4    # In number of pixels
					   # IMPORTANT: If this is changed, the frog sprite must be updated accordingly
	
	displayBufferSize:	.word  3000  # The space in the display buffer
	displayBuffer:		.space 10000  # The buffer for the display to stop the screen from blinking
					     # Set the display buffer to be pixelsInDisplay * pixelsInDisplayDown * 4
	
	# Everything here is in number of sizeFrogs
	sizeScore:		.byte 3
	sizeGoal:		.byte 1  # Keep this as 1, or goals won't draw properly, everything else can change
	sizeWater:		.byte 4
	sizeSafe:		.byte 2
	sizeRoad:		.byte 4
	sizeStart:		.byte 2
	
	screen:			.byte 0  # Screen = 0 is the game, screen = 1 is the pause menu
	time:			.word 31
	timerSpeed:		.word 50
	timeSoFar:		.word 0
	
	froggerTheme:		.half 66, 66, 62, 62, 66, 66, 62, 62, 67, 67, 66, 66, 64, 0, 67, 67, 66, 66, 64, 64, 71, 71, 69, 67, 66, 64, 62
	froggerThemeLength:	.byte 27
	gameOverTheme:		.half 66, 61, 58, 63, 65, 63, 62, 64, 62, 61, 59, 61
	gameOverThemeLength:	.byte 12
	goalTheme:		.half 62, 64, 66, 67, 69, 66, 62, 64, 66, 64, 62, 62, 64, 66, 67, 69, 66, 69, 67, 66, 64, 62
	goalThemeLength:	.byte 22
	collisionTheme:		.half 67, 66, 65, 64
	collisionThemeLength:	.byte 4
	
	finishSetup:		.byte 1
.text
startSetup:
	lb $t0, randomizeSizes
	beqz $t0, endSetupLogLengths
setupRandomCarLengths:
	la $t0, carSizes  # $t0 is the address of the carSizes
	lb $t1, numCarsTotal  # $t1 is the number of cars left to generate
setupRandomCarLengthsLoop:
	addi $t1, $t1, -1
	
	add $t2, $t1, $t0
	li $v0, 42
	li $a0, 0
	li $a1, 2
	syscall
	addi $a0, $a0, 1
	sb $a0, ($t2)
	
	beqz $t1, endSetupCarLengths
	j setupRandomCarLengthsLoop
endSetupCarLengths:
setupRandomLogLengths:
	la $t0, logSizes  # $t0 is the address of the carSizes
	lb $t1, numLogsTotal  # $t1 is the number of cars left to generate
setupRandomLogLengthsLoop:
	addi $t1, $t1, -1
	
	add $t2, $t1, $t0
	li $v0, 42
	li $a0, 0
	li $a1, 2
	syscall
	addi $a0, $a0, 2
	sb $a0, ($t2)
	
	beqz $t1, endSetupLogLengths
	j setupRandomLogLengthsLoop
endSetupLogLengths:
	li $t0, 0
	sb $t0, finishSetup
endSetup:
	j main


# Plays a line of midi at the address in $a0, where each note has length $a1, using instrument $a2, of length $a3
playMidiFunction:
	move $s0, $a3
	li $s1, 2
	mult $s0, $s1
	mflo $s0
	li $s1, 0
	
	move $s2, $a0
startMidiLoop:
	beq $s0, $s1, endMidiLoop
	add $s3, $s2, $s1
	lh $a0, ($s3)
	li $a3, 127
	li $v0, 33
	syscall
	
	addi $s1, $s1, 2
	j startMidiLoop
endMidiLoop:
	jr $ra
endPlayMidiFunction:
# Draws a rectangle at coordinates (x, y) = ($a0, $a1) of width $a2 in frog sizes and height 1 frog size
# with the color in $a3
drawRectangleFunction:
	# $a3 holds the color of the rectangle
	
	lb $s0, sizeFrog
	mult $a2, $s0
	mflo $a2
	
	la $s1, displayBuffer
	add $s6, $s1, $zero
	addi $s2, $zero, 4
	mult $a0, $s2
	mflo $a0
	add $s1, $s1, $a0
	
	lb $s3, sizeFrog
	mult $s3, $a1
	mflo $a1
	lh $s3, sizeDisplay
	mult $a1, $s3 
	mflo $a1
	add $s1, $s1, $a1  # $s1 holds the byte to start writing at
	add $s6, $s6, $a1
	add $s6, $s6, $s3  # $s6 holds the byte of the beginning of the row to write at

	lb $s2, sizeFrog  # $s2 is the number of rows left to draw
	lh $s7, sizeDisplay  # $s7 is the size of the display
	
	
drawRectangleLoop:
	beqz $s2, drawRectangleFunctionEnd
	addi $s2, $s2, -1
	
	add $s3, $zero, $a2
	addi $s4, $zero, 4
	mult $s4, $s3
	mflo $s3  # $s3 is the byte offset of pixel to draw on the row

drawRectangleRow:
	beqz $s3, drawRectangleRowEnd
	addi $s3, $s3, -4
	
	add $s5, $s3, $s1  # $s5 holds the byte to write at
	
	bge $s5, $s6, fixOverflow
noFixOverflow:
	sw $a3,($s5)
	j endFixOverflow
fixOverflow:
	sub $s5, $s5, $s7
	sw $a3,($s5)
	add $s5, $s5, $s7

endFixOverflow:
	j drawRectangleRow

drawRectangleRowEnd:
	add $s1, $s1, $s7  # Move $s1 down
	add $s6, $s6, $s7  # Move $s6 down

	j drawRectangleLoop
drawRectangleFunctionEnd:
	jr $ra

loseLifeFunction:
	# Lose a life, and end the game if lives are negative
	la $s0, frogLocation  # $t0 points to the location of the frog
	la $s1, startingFrogLocation  # $t1 points to the original location of the frog
	# Reset the location
	lh $s2, ($s1)
	sh $s2, ($s0)
	lh $s2, 2($s1)
	sh $s2, 2($s0)
	
	lb $s0, lives
	addi $s0, $s0, -1
	beqz $s0, dieFunction
	
	la $s1, lives
	sb $s0, ($s1)
	
	sw $ra, ($sp)
	addi $sp, $sp, -4
	
	la $a0, collisionTheme
	li $a1, 500
	li $a2, 1
	lb $a3, collisionThemeLength
	jal playMidiFunction
	
	addi $sp, $sp, 4
	lw $ra, ($sp)
	
	jr $ra
endLoseLifeFunction:

dieFunction:
	# Handle dying
	la $a0, gameOverTheme
	li $a1, 500
	li $a2, 1
	lb $a3, gameOverThemeLength
	jal playMidiFunction

	j Exit
dieFunctionEnd:

checkCollisionFunction:
	# Check if the current location of the frog collides with the rectangle
	# specified in the input.
	
	# The rectangle in the input is specified by (x, y) = ($a0, $a1) as the top left corner
	# $a2 as the width, and $a3 as the height.
	# $v0 is set to zero on no collision, and a non-zero value on collision.
	
	add $s1, $zero, $zero
	la $s2, frogLocation
	lh $s0, ($s2)  # $s0 holds the x coordinate of the frog
	lh $s1, 2($s2)  # $s1 holds the y coordinate of the frog
	lb $s2, sizeFrog  # $s2 holds the frog width
	
	# The frog height is always 1 by definition
	
	add $s3, $a0, $a2
	lb $s4, pixelsInDisplay
	add $s4, $s4, $s0
	bge $s0, $s3, checkCollisionOutOfBounds
	add $s3, $s0, $s2
	ble $s3, $a0, checkCollisionOutOfBounds
	add $s3, $a1, $a3
	bge $s1, $s3, checkCollisionOutOfBounds
	addi $s3, $s1, 1
	ble $s3, $a1, checkCollisionOutOfBounds
		
returnTrueCheckCollision:
	li $v0, 1
	jr $ra
checkCollisionOutOfBounds:
	add $s1, $zero, $zero
	la $s2, frogLocation
	lh $s0, ($s2)
	lb $s7, pixelsInDisplay
	add $s0, $s0, $s7  # $s0 holds the x coordinate of the frog shifted off screen
	lh $s1, 2($s2)  # $s1 holds the y coordinate of the frog
	lb $s2, sizeFrog  # $s2 holds the frog width
	
	# The frog height is always 1 by definition
	
	add $s3, $a0, $a2
	bge $s0, $s3, returnFalseCheckCollision
	add $s3, $s0, $s2
	ble $s3, $a0, returnFalseCheckCollision
	add $s3, $a1, $a3
	bge $s1, $s3, returnFalseCheckCollision
	addi $s3, $s1, 1
	ble $s3, $a1, returnFalseCheckCollision
returnTrueCheckCollisionTwo:
	li $v0, 1
	jr $ra
returnFalseCheckCollision:
	li $v0, 0
	jr $ra
endCheckCollisionFunction:

main:
debugInfoStart:
	# Display score
	
	#lw $a0, score
	#li $v0, 1
	#syscall
debugInfoEnd:
startPauseMenu:
	lb $t0, screen  # $t0 is 1 if the game is paused
	bne $t0, 1, endPauseMenu
	
	li $a0, 11
	li $a1, 7
	li $a2, 1
	lw $a3, pauseColor
	jal drawRectangleFunction
	li $a0, 11
	li $a1, 8
	li $a2, 1
	lw $a3, pauseColor
	jal drawRectangleFunction
	li $a0, 16
	li $a1, 7
	li $a2, 1
	lw $a3, pauseColor
	jal drawRectangleFunction
	li $a0, 16
	li $a1, 8
	li $a2, 1
	lw $a3, pauseColor
	jal drawRectangleFunction
	
	lw $t8, 0xffff0000
	bne $t8, 1, startUpdateScreen  # $t8 contains whether a key has been pressed

	lw $t3, 0xffff0004  # $t3 contains the ascii value of the key pressed
	beq $t3, 0x70, endPauseGame
	j startUpdateScreen
endPauseGame:
	la $t0, screen
	li $t1, 0
	
	sb $t1, ($t0)
	j endPauseMenu
endPauseMenu:

startCheckCollisionGoals:
	lb $t0, numGoals  # $t0 holds the number of goals to draw left
	la $t1, goals  # $t1 holds the address of the goals
startCheckCollisionGoalsLoop:
	beqz $t0, endCheckCollisionGoals
	addi $t0, $t0, -1

	add $t9, $t1, $t0  # $t2 is the address of the goal to check
	lb $t3, ($t9)  # $t3 holds whether the goal should be drawn
	
	lb $t2, sizeFrog
	mult $t2, $t0
	mflo $a0  # $a0 holds the x coordinate
	
	lb $a1, sizeScore  # $a1 holds the y coordinate
	li $a2, 1  # $a2 holds the width of the rectangle
	li $a3, 1  # $a2 holds the height of the rectangle
	
	jal checkCollisionFunction
	beqz $v0, noCollisionFound
collisionFound:
	# Here colliding with a goal is handled
	la $t0, frogLocation  # $t0 points to the location of the frog
	la $t1, startingFrogLocation  # $t1 points to the original location of the frog
	# Reset the location
	lh $t2, ($t1)
	sh $t2, ($t0)
	lh $t2, 2($t1)
	sh $t2, 2($t0)
	
	bnez $t3, collisionFoundGoalNonEmpty
collisionFoundGoalEmpty:
	# Load a 1 into the goal and increment the score
	li $t2, 1
	sb $t2, ($t9)
	lw $t2, score
	addi $t2, $t2, 100
	sw $t2, score
	
	la $a0, goalTheme
	li $a1, 300
	li $a2, 1
	lb $a3, goalThemeLength
	jal playMidiFunction
	
	# Increment difficulty
	lb $t0, numGoalsFilled
	addi $t0, $t0, 1
	sb $t0, numGoalsFilled
	beq $t0, 1, handleNumGoals1
	beq $t0, 2, handleNumGoals2
	beq $t0, 3, handleNumGoals3
	beq $t0, 4, handleNumGoals4
	beq $t0, 5, handleNumGoals5
	beq $t0, 6, handleNumGoals6
	beq $t0, 7, handleNumGoals7
	j endHandleNumGoals
handleNumGoals1:
	# Double the number of cars
	li $t0, 2
	lb $t1, numCarsTotal
	mult $t1, $t0
	mflo $t1
	sb $t1, numCarsTotal

	lb $t1, numCarsPerRow
	mult $t1, $t0
	mflo $t1
	sb $t1, numCarsPerRow

	j endHandleNumGoals
handleNumGoals2:
	# Increase the speed of cars
	lb $t0, numCarsTotal
handleNumGoals2Loop:
	beqz $t0, handleNumGoals2LoopEnd
	addi $t0, $t0, -1
	
	lb $t1, carSpeeds($t0)
	addi $t1, $t1, 1
	sb $t1, carSpeeds($t0)
	
	j handleNumGoals2Loop
handleNumGoals2LoopEnd:
	j endHandleNumGoals
handleNumGoals3:
	# Decrease the speed of the logs
	lb $t0, numLogsTotal
handleNumGoals3Loop:
	beqz $t0, handleNumGoals3LoopEnd
	addi $t0, $t0, -1
	
	lb $t1, logSpeeds($t0)
	addi $t1, $t1, -1
	sb $t1, logSpeeds($t0)
	
	j handleNumGoals3Loop
handleNumGoals3LoopEnd:
	j endHandleNumGoals
handleNumGoals4:
	# Reset and speed up the timer
	li $t0, 31
	sw $t0, time
	
	lw $t0, timerSpeed
	div $t0, $t0, 2
	sw $t0, timerSpeed
	sw $zero, timeSoFar
	
	j endHandleNumGoals
handleNumGoals5:
	# Half the number of logs
	lb $t1, numLogsTotal
	div $t1, $t1, 2
	sb $t1, numLogsTotal

	lb $t1, numLogsPerRow
	div $t1, $t1, 2
	sb $t1, numLogsPerRow
	
	# Change maybe: The second log's speed is set to -3
	li $t0, -5
	li $t1, 1
	sb $t0, logSpeeds($t1)

	j endHandleNumGoals
handleNumGoals6:
	# Decrease the size of all logs
	lb $t0, numLogsTotal
handleNumGoals6Loop:
	beqz $t0, handleNumGoals6LoopEnd
	addi $t0, $t0, -1
	
	lb $t1, logSizes($t0)
	addi $t1, $t1, -1
	sb $t1, logSizes($t0)
	
	j handleNumGoals6Loop
handleNumGoals6LoopEnd:
	j endHandleNumGoals
handleNumGoals7:
	# Increase the size of all cars
	lb $t0, numCarsTotal
handleNumGoals7Loop:
	beqz $t0, handleNumGoals7LoopEnd
	addi $t0, $t0, -1
	
	lb $t1, carSizes($t0)
	addi $t1, $t1, 1
	sb $t1, carSizes($t0)
	
	j handleNumGoals7Loop
handleNumGoals7LoopEnd:
	j endHandleNumGoals
endHandleNumGoals:
	
collisionFoundGoalNonEmpty:
	j endCheckCollisionGoals
noCollisionFound:
	j startCheckCollisionGoalsLoop
endCheckCollisionGoals:

checkCollisionCars:
	lb $t0, numCarsTotal   # $t0 holds the number of cars left to draw
	lb $t1, numCarsPerRow  # $t1 holds the number of cars to draw per row
	la $t2, carLocations   # $t2 holds the address of the location of the cars
	la $t3, carSizes       # $t3 holds the address of the size of the cars

	lb $t5, sizeScore
	add $t4, $zero, $t5
	lb $t5, sizeGoal
	add $t4, $t4, $t5
	lb $t5, sizeWater
	add $t4, $t4, $t5
	lb $t5, sizeSafe
	add $t4, $t4, $t5  # t4 holds the y coordinate of the top of the road	
	lw $t5, carColor  # $t5 holds the color of the car
	lb $t9, sizeRoad  # $t9 holds the size of the road
	
checkCarCollisionsLoop:
	addi $t9, $t9, -1
	beqz $t0, endCheckCollisionCars
	lb $t1, numCarsPerRow
	
checkCarCollisionsInnerLoop:  # Check a row of cars
	beqz $t1, checkCarCollisionsLoop
	
	lb $a0, ($t2) # $a0 holds the x coordinate
	
	add $a1, $zero, $t4
	add $a1, $a1, $t9  # $a1 holds the y coordinate
	
	lb $a2, ($t3)
	lb $t6, sizeFrog
	mult $a2, $t6
	mflo $a2  # $a2 holds the width
	
	li $a3, 1  # $a3 holds the height
	
	jal checkCollisionFunction
	bnez $v0, carCollisionFound
	j carCollisionFoundEnd
carCollisionFound:
	jal loseLifeFunction
carCollisionFoundEnd:
	addi $t2, $t2, 1  # Move to the next car location
	addi $t3, $t3, 1  # Move to the next car size
	addi $t0, $t0, -1
	addi $t1, $t1, -1
	j checkCarCollisionsInnerLoop
endCheckCollisionCars:

checkCollisionLogs:
	lb $t0, numLogsTotal   # $t0 holds the number of logs left to draw
	lb $t1, numLogsPerRow  # $t1 holds the number of logs to draw per row
	la $t2, logLocations   # $t2 holds the address of the location of the logs
	la $t3, logSizes       # $t3 holds the address of the size of the logs

	lb $t5, sizeScore
	add $t4, $zero, $t5
	lb $t5, sizeGoal
	add $t4, $t4, $t5  # t4 holds the y coordinate of the top of the water	
	lw $t5, carColor  # $t5 holds the color of the log
	lb $t9, sizeWater  # $t9 holds the size of the water
	
	la $t7, frogLocation
	lb $t7, 2($t7)  # $t7 holds the y coordinate of the frog
	
	blt $t7, $t4, endCheckCollisionLogs  # Don't check for collisions if the frog is too high
	add $t8, $t9, $t4
	bge $t7, $t8, endCheckCollisionLogs  # Don't check for collisions if the frog is too low
	
	la $t8, logSpeeds  # $t8 points to the speed of the logs
	
checkLogCollisionsLoop:
	addi $t9, $t9, -1
	beqz $t0, checkCollisionLogsNoCollisionFound
	lb $t1, numLogsPerRow

checkLogCollisionsInnerLoop:  # Check a row of logs
	beqz $t1, checkLogCollisionsLoop
	
	lb $a0, ($t2) # $a0 holds the x coordinate
	
	add $a1, $zero, $t4
	add $a1, $a1, $t9  # $a1 holds the y coordinate
	
	lb $a2, ($t3)
	lb $t6, sizeFrog
	mult $a2, $t6
	mflo $a2  # $a2 holds the width
	
	li $a3, 1  # $a3 holds the height
	
	jal checkCollisionFunction
	bnez $v0, waterCollisionFound
	j waterCollisionFoundEnd
waterCollisionFound:
	# Move the frog with the log when it is time to move
	lb $t0, currentLogWait
	lb $t1, logWait
	bne $t0, $t1, endCheckCollisionLogs
	  
	la $t0, frogLocation  # $t0 points to the location of the frog
	lb $t1, ($t0)  # $t1 holds the x coordinate of the frog
	lb $t2, ($t8)  # $t2 holds the speed of the log the frog is on
	add $t1, $t1, $t2
	bgez $t1, endFixOverflowWaterCollision
fixOverflowWaterCollision:
	sub $t1, $t1, $t2
endFixOverflowWaterCollision:
	sb $t1, ($t0)  # Move the frog's location
	j endCheckCollisionLogs
waterCollisionFoundEnd:
	addi $t2, $t2, 1  # Move to the next car location
	addi $t3, $t3, 1  # Move to the next car size
	addi $t0, $t0, -1
	addi $t1, $t1, -1
	addi $t8, $t8, 1
	j checkLogCollisionsInnerLoop
checkCollisionLogsNoCollisionFound:

	jal loseLifeFunction
endCheckCollisionLogs:

moveFrog:
	lw $t8, 0xffff0000
	bne $t8, 1, endMoveFrog

	lw $t3, 0xffff0004  # $t3 contains the ascii value of the key pressed
	la $t0, frogLocation  # $t0 points to the location of the frog
	la $t4, frogDirection  # $t4 points to the direction of the frog
	lh $t1, ($t0)  # $t1 holds the x coordinate of the frog
	lh $t2, 2($t0)  # $t2 holds the y coordinate of the frog
	lb $t9, pixelsInDisplay
	lb $t8, pixelsInDisplayDown
	
	beq $t3, 0x70, pauseGame
	beq $t3, 0x61, handleLeft
	beq $t3, 0x77, handleUp
	beq $t3, 0x64, handleRight
	beq $t3, 0x73, handleDown
	j moveFrog
pauseGame:
	la $t5, screen
	li $t6, 1
	sb $t6, ($t5)
	j endMoveFrog
handleLeft:
	addi $t5, $zero, 3
	sb $t5, ($t4)  # Load the direction
	
	li $a0, 55
	li $a1, 200
	li $a2, 98
	li $a3, 127
	li $v0, 31
	syscall

	addi $t1, $t1, -4
	bgez $t1, handleLeftEnd
	addi $t1, $t1, 4
handleLeftEnd:
	sh $t1, ($t0)
	j endMoveFrog
handleUp:
	addi $t5, $zero, 0
	sb $t5, ($t4)  # Load the direction
	
	# Play sound effect
	li $a0, 70
	li $a1, 200
	li $a2, 98
	li $a3, 127
	li $v0, 31
	syscall
	
	lw $t5, score
	addi $t5, $t5, 1
	sw $t5, score
	
	addi $t3, $zero, 1
	
	addi $t2, $t2, -1
	bge $t2, $t3, handleUpEnd
	addi $t2, $t2, 1
handleUpEnd:
	sh $t2, 2($t0)
	
	j endMoveFrog
handleRight:
	addi $t5, $zero, 1
	sb $t5, ($t4)  # Load the direction
	
	li $a0, 65
	li $a1, 200
	li $a2, 98
	li $a3, 127
	li $v0, 31
	syscall
	
	addi $t1, $t1, 4
	addi $t9, $t9, -3
	blt $t1, $t9, handleRightEnd
	addi $t1, $t1, -4
handleRightEnd:
	sh $t1, ($t0)
	
	j endMoveFrog
handleDown:
	addi $t5, $zero, 2
	sb $t5, ($t4)  # Load the direction
	
	li $a0, 50
	li $a1, 200
	li $a2, 98
	li $a3, 127
	li $v0, 31
	syscall

	addi $t2, $t2, 1
	addi $t6, $zero, 4
	mult $t2, $t6
	mflo $t7
	blt $t7, $t8, handleDownEnd
	addi $t2, $t2, -1
handleDownEnd:
	sh $t2, 2($t0)
	
	j endMoveFrog
endMoveFrog:

moveCars:
	la $t0, currentCarWait
	lw $t1, currentCarWait
	
	lw $t2, carWait
	bne $t2, $t1, handleEqualCars
	sb $zero, ($t0)

	lb $t0, numCarsTotal  # $t0 holds the number of cars left to draw
	la $t9, carLocations  # $t9 holds the address of carLocations
	la $t8, carSpeeds  # $t8 holds the address of the carSpeeds
moveCarsLoop:
	beqz $t0, moveCarsEnd
	addi $t0, $t0, -1
	
	add $t7, $t0, $t8
	lb $t1, ($t7)  # $t1 holds the speed of the car
	add $t7, $t0, $t9
	lb $t2, ($t7)  # $t2 holds the location of the car
	add $t2, $t2, $t1
	
	lb $t6, pixelsInDisplay
	div $t2, $t6
	mfhi $t2
	
	sb $t2, ($t7)

	j moveCarsLoop
handleEqualCars:
	addi $t1, $t1, 1
	sw $t1, ($t0)
moveCarsEnd:

moveLogs:
	la $t0, currentLogWait
	lw $t1, currentLogWait
	
	lw $t2, logWait
	bne $t2, $t1, handleEqualLogs
	sb $zero, ($t0)

	lb $t0, numLogsTotal  # $t0 holds the number of logs left to draw
	la $t9, logLocations  # $t9 holds the address of logLocations
	la $t8, logSpeeds  # $t8 holds the address of the logSpeeds
moveLogsLoop:
	beqz $t0, moveLogsEnd
	addi $t0, $t0, -1
	
	add $t7, $t0, $t8
	lb $t1, ($t7)  # $t1 holds the speed of the log
	add $t7, $t0, $t9
	lb $t2, ($t7)  # $t2 holds the location of the log
	add $t2, $t2, $t1
	
	lb $t6, pixelsInDisplay
	bgez $t2, EndHandleNegativeLogs
StartHandleNegativeLogs:
	add $t2, $t6, $t2
EndHandleNegativeLogs:
	div $t2, $t6
	mfhi $t2
	
	sb $t2, ($t7)

	j moveLogsLoop
handleEqualLogs:
	addi $t1, $t1, 1
	sw $t1, ($t0)
moveLogsEnd:

drawScene:
	la $t0, displayBuffer  # $t0 holds the address of the buffer
	add $t1, $zero, $zero   # $t1 holds the current offset of the screen to draw on
drawSceneScoreRegionInit:
	lh $t9, sizeDisplay
	lb $t8, sizeFrog
	mult $t9, $t8
	mflo $t9
	lb $t8, sizeScore
	mult $t9, $t8
	mflo $t9
	
	lw $t2, scoreColor      # $t2 holds the color to draw
drawSceneScoreRegion:
	beq $t1, $t9, drawSceneGoalRegionInit
	
	add $t3, $t0, $t1  # $t3 holds the address + offset: the pixel to draw
	sw $t2, 0($t3)
	addi $t1, $t1, 4
	
	j drawSceneScoreRegion
drawSceneGoalRegionInit:
	add $t7, $t9, $zero
	lh $t9, sizeDisplay
	lb $t8, sizeFrog
	mult $t9, $t8
	mflo $t9
	lb $t8, sizeGoal
	mult $t9, $t8
	mflo $t9
	
	add $t9, $t9, $t7
	
	lw $t2, grassColor      # $t2 holds the color to draw

drawSceneGoalRegion:
	beq $t1, $t9, drawSceneWaterRegionInit
	
	add $t3, $t0, $t1  # $t3 holds the address + offset: the pixel to draw
	sw $t2, 0($t3)
	addi $t1, $t1, 4
	
	j drawSceneGoalRegion

drawSceneWaterRegionInit:
	add $t7, $t9, $zero
	lh $t9, sizeDisplay
	lb $t8, sizeFrog
	mult $t9, $t8
	mflo $t9
	lb $t8, sizeWater
	mult $t9, $t8
	mflo $t9
	add $t9, $t9, $t7
	
	lw $t2, waterColor
drawSceneWaterRegion:
	beq $t1, $t9, drawSceneSafeRegionInit

	add $t3, $t0, $t1  # $t3 holds the address + offset: the pixel to draw
	sw $t2, 0($t3)
	addi $t1, $t1, 4

	j drawSceneWaterRegion

drawSceneSafeRegionInit:
	add $t7, $t9, $zero
	lh $t9, sizeDisplay
	lb $t8, sizeFrog
	mult $t9, $t8
	mflo $t9
	lb $t8, sizeSafe
	mult $t9, $t8
	mflo $t9
	add $t9, $t9, $t7

	lw $t2, safeColor

drawSceneSafeRegion:
	beq $t1, $t9, drawSceneRoadRegionInit

	add $t3, $t0, $t1  # $t3 holds the address + offset: the pixel to draw
	sw $t2, 0($t3)
	addi $t1, $t1, 4

	j drawSceneSafeRegion

drawSceneRoadRegionInit:
	add $t7, $t9, $zero
	lh $t9, sizeDisplay
	lb $t8, sizeFrog
	mult $t9, $t8
	mflo $t9
	lb $t8, sizeRoad
	mult $t9, $t8
	mflo $t9
	add $t9, $t9, $t7
	
	lw $t2, roadColor

drawSceneRoadRegion:
	beq $t1, $t9, drawSceneStartRegionInit

	add $t3, $t0, $t1  # $t3 holds the address + offset: the pixel to draw
	sw $t2, 0($t3)
	addi $t1, $t1, 4

	j drawSceneRoadRegion

drawSceneStartRegionInit:
	add $t7, $t9, $zero
	lh $t9, sizeDisplay
	lb $t8, sizeFrog
	mult $t9, $t8
	mflo $t9
	lb $t8, sizeStart
	mult $t9, $t8
	mflo $t9
	add $t9, $t9, $t7
	
	lw $t2, grassColor
	
drawSceneStartRegion:
	beq $t1, $t9, endDrawScenes

	add $t3, $t0, $t1  # $t3 holds the address + offset: the pixel to draw
	sw $t2, 0($t3)
	addi $t1, $t1, 4

	j drawSceneStartRegion
endDrawScenes:

drawTimer:
	la $t0, displayBuffer  # $t0 holds the display buffer address
	lw $t1, time
	li $t2, 4
	mult $t2, $t1
	mflo $t1   # $t1 holds the number of pixels across to draw
	lw $t2, timeColor  # $t2 holds the color of the pixels
	lh $t3, sizeDisplay  # $t3 holds the number of pixels to jump downwards
	
	move $t4, $t0  # $t4 holds the address of the beginning of the row to draw
	lh $t5, sizeDisplay
	li $t6, 9
	mult $t5, $t6
	mflo $t5
	add $t4, $t4, $t5
	li $t6, 2  # $t6 holds the number of rows to draw
drawTimerOuterLoop:
	beqz $t6, drawTimerOuterLoopEnd
	li $t5, 4  # $t5 holds the current offset of the row to draw on
drawTimerInnerLoop:
	beq $t5, $t1, drawTimerInnerLoopEnd
	
	add $t7, $t4, $t5
	sw $t2, ($t7)
	
	addi $t5, $t5, 4
	j drawTimerInnerLoop
drawTimerInnerLoopEnd:
	add $t4, $t4, $t3
	add $t6, $t6, -1
	j drawTimerOuterLoop
drawTimerOuterLoopEnd:
drawTimerEnd:

handleTimer:
	lw $t0, timeSoFar
	lw $t1, timerSpeed
	
	addi $t0, $t0, 1
	la $t2, timeSoFar
	sw $t0, ($t2)
	bne $t0, $t1, handleTimerEnd
	
	sw $zero, ($t2)
	la $t0, time
	lw $t1, time
	addi $t1, $t1, -1
	sw $t1, ($t0)
	
	bnez $t1, handleTimerEnd
	j dieFunction
handleTimerEnd:

drawGoals:
	lb $t0, numGoals  # $t0 holds the number of goals to draw left
	la $t1, goals  # $t1 holds the address of the goals
drawGoalsLoop:
	beqz $t0, endDrawGoals
	addi $t0, $t0, -1

	add $t2, $t1, $t0  # $t2 is the address of the goal to check
	lb $t3, ($t2)  # $t3 holds whether the goal should be drawn
	beqz $t3, drawGoalsLoop
	
	lb $t2, sizeFrog
	mult $t2, $t0
	mflo $a0  # $a0 holds the x coordinate
	
	lb $a1, sizeScore  # $a1 holds the y coordinate
	li $a2, 1  # $a2 holds the width of the rectangle
	lb $a3, goalColor  # $a2 holds the color
	
	jal drawRectangleFunction
	j drawGoalsLoop
endDrawGoals:

drawObjectsStart:
drawCarsInit:
	lb $t0, numCarsTotal   # $t0 holds the number of cars left to draw
	lb $t1, numCarsPerRow  # $t1 holds the number of cars to draw per row
	la $t2, carLocations   # $t2 holds the address of the location of the cars
	la $t3, carSizes       # $t3 holds the address of the size of the cars

	lb $t5, sizeScore
	add $t4, $zero, $t5
	lb $t5, sizeGoal
	add $t4, $t4, $t5
	lb $t5, sizeWater
	add $t4, $t4, $t5
	lb $t5, sizeSafe
	add $t4, $t4, $t5  # t4 holds the y coordinate of the top of the road	
	lw $t5, carColor  # $t5 holds the color of the car
	lb $t9, sizeRoad  # $t9 holds the size of the road
	
drawCars:
	addi $t9, $t9, -1
	beqz $t0, drawLogsInit
	lb $t1, numCarsPerRow
	
drawCarsRow:  # Draw a row of cars
	beqz $t1, drawCars
	
	lb $a0, ($t2) # $a0 holds the x coordinate
	
	add $a1, $zero, $t4
	add $a1, $a1, $t9  # $a1 holds the y coordinate
	
	lb $a2, ($t3)  # $a2 holds the width
	
	add $a3, $zero, $t5  # $a3 is the color
	
	jal drawRectangleFunction
	
	addi $t2, $t2, 1  # Move to the next car location
	addi $t3, $t3, 1  # Move to the next car size
	addi $t0, $t0, -1
	addi $t1, $t1, -1
	j drawCarsRow
	
drawLogsInit:
	lb $t0, numLogsTotal   # $t0 holds the number of logs left to draw
	lb $t1, numLogsPerRow  # $t1 holds the number of logs to draw per row
	la $t2, logLocations   # $t2 holds the address of the location of the logs
	la $t3, logSizes       # $t3 holds the address of the size of the logs

	lb $t5, sizeScore
	add $t4, $zero, $t5
	lb $t5, sizeGoal
	add $t4, $t4, $t5 # t4 holds the y coordinate of the top of the water
	
	lw $t5, logColor  # $t5 holds the color of the car
	
	lb $t9, sizeWater  # $t9 holds the size of the water
	
drawLogs:
	addi $t9, $t9, -1
	beqz $t0, drawFrog
	lb $t1, numLogsPerRow
	
drawLogsRow:  # Draw a row of logs
	beqz $t1, drawLogs
	
	lb $a0, ($t2) # $a0 holds the x coordinate
	
	add $a1, $zero, $t4
	add $a1, $a1, $t9  # $a1 holds the y coordinate
	
	lb $a2, ($t3)  # $a2 holds the width
	
	add $a3, $zero, $t5  # $a3 is the color
	
	jal drawRectangleFunction
	
	addi $t2, $t2, 1  # Move to the next log location
	addi $t3, $t3, 1  # Move to the next log size
	addi $t0, $t0, -1
	addi $t1, $t1, -1
	j drawLogsRow

drawFrog:
	la $t0, frogLocation  # $t0 is the address of frogLocation
	lh $t1, 0($t0)  # $t1 is the x-coordinate
	lh $t2, 2($t0)  # $t2 is the y-coordinate
	
	lb $t3, sizeFrog
	mult $t1, $t3
	mflo $t1
	mult $t2, $t3
	mflo $t2
	# $t1 and $t2 now represent the bit offset
	
	la $t0, displayBuffer  # $t0 now holds the address of the buffer
	lw $t4, frogColor       # $t4 holds the color of the frog
	
	lh $t5, sizeDisplay  # $t5 is the size of the display
	mult $t5, $t2
	mflo $t6
	add $t6, $t0, $t6
	add $t6, $t6, $t1
	
	# $t6 holds the top left pixel of the frog
	# $t5 holds the number of bytes in one row of pixels
	# $t4 holds the color of the frog

	lb $t7, frogDirection  # $t7 is the direction of the frog
	beq $t7, 0, drawFrogUp
	beq $t7, 1, drawFrogRight
	beq $t7, 2, drawFrogDown
	beq $t7, 3, drawFrogLeft
drawFrogUp:
	# Row 1 of the frog
	sw $t4, 0($t6)
	sw $t4, 12($t6)
	add $t6, $t6, $t5
	
	# Row 2 of the frog
	sw $t4, 0($t6)
	sw $t4, 4($t6)
	sw $t4, 8($t6)
	sw $t4, 12($t6)
	add $t6, $t6, $t5
	
	# Row 3 of the frog
	sw $t4, 4($t6)
	sw $t4, 8($t6)
	add $t6, $t6, $t5
	
	# Row 4 of the frog
	sw $t4, 0($t6)
	sw $t4, 4($t6)
	sw $t4, 8($t6)
	sw $t4, 12($t6)
	
	j drawFrogEnd
drawFrogRight:
	# Row 1 of the frog
	sw $t4, 0($t6)
	sw $t4, 8($t6)
	sw $t4, 12($t6)
	add $t6, $t6, $t5
	
	# Row 2 of the frog
	sw $t4, 0($t6)
	sw $t4, 4($t6)
	sw $t4, 8($t6)
	add $t6, $t6, $t5
	
	# Row 3 of the frog
	sw $t4, 0($t6)
	sw $t4, 4($t6)
	sw $t4, 8($t6)
	add $t6, $t6, $t5
	
	# Row 4 of the frog
	sw $t4, 0($t6)
	sw $t4, 8($t6)
	sw $t4, 12($t6)
	
	j drawFrogEnd
drawFrogDown:
	# Row 1 of the frog
	sw $t4, 0($t6)
	sw $t4, 4($t6)
	sw $t4, 8($t6)
	sw $t4, 12($t6)
	add $t6, $t6, $t5
	
	# Row 2 of the frog
	sw $t4, 4($t6)
	sw $t4, 8($t6)
	add $t6, $t6, $t5
	
	# Row 3 of the frog
	sw $t4, 0($t6)
	sw $t4, 4($t6)
	sw $t4, 8($t6)
	sw $t4, 12($t6)
	add $t6, $t6, $t5
	
	# Row 4 of the frog
	sw $t4, 0($t6)
	sw $t4, 12($t6)
	
	j drawFrogEnd
drawFrogLeft:
	# Row 1 of the frog
	sw $t4, 0($t6)
	sw $t4, 4($t6)
	sw $t4, 12($t6)
	add $t6, $t6, $t5
	
	# Row 2 of the frog
	sw $t4, 4($t6)
	sw $t4, 8($t6)
	sw $t4, 12($t6)
	add $t6, $t6, $t5
	
	# Row 3 of the frog
	sw $t4, 4($t6)
	sw $t4, 8($t6)
	sw $t4, 12($t6)
	add $t6, $t6, $t5
	
	# Row 4 of the frog
	sw $t4, 0($t6)
	sw $t4, 4($t6)
	sw $t4, 12($t6)
drawFrogEnd:

startDrawLives:
	# Draw a heart for each life on the top left of the screen
	la $t0, displayBuffer  # $t0 holds the displayBuffer
	lb $t1, lives  # $t1 holds the number of hearts to draw
	
	li $t2, 260 # $t2 is the current offset
	addi $t3, $zero, 16  # $t3 holds the offset to add in number of bytes per life
	
	lh $t4, sizeDisplay  # $t4 holds the display size in bytes
	lw $t5, lifeColor  # $t5 holds the color to draw

drawLivesLoop:
	beqz $t1, endDrawLives
	
	addi $t9, $t2, 0
	sw $t5, displayBuffer($t9)
	addi $t9, $t9, 4
	addi $t9, $t9, 4
	sw $t5, displayBuffer($t9)
	add $t9, $t4, $t9
	addi $t9, $t9, -8
	sw $t5, displayBuffer($t9)
	addi $t9, $t9, 4
	sw $t5, displayBuffer($t9)
	addi $t9, $t9, 4
	sw $t5, displayBuffer($t9)
	add $t9, $t4, $t9
	addi $t9, $t9, -4
	sw $t5, displayBuffer($t9)
	
	add $t2, $t2, $t3
	addi $t1, $t1, -1
	j drawLivesLoop
endDrawLives:

startDrawScore:
	lw $t5, score  # $t5 holds the current score
	li $t6, 3  # $t6 is the number of numbers left to draw
	
	li $t1, 236  # $t1 holds the top left of the place to draw
startDrawScoreLoop:
	beqz $t6, endDrawScoreLoop
	addi $t6, $t6, -1

	li $t7, 10  # $t7 holds the value 10 for use in finding the digit
	beq $t6, 2, findFirstDigit
	beq $t6, 1, findSecondDigit
	beq $t6, 0, findThirdDigit
findFirstDigit:
	div $t5, $t7
	mfhi $t0
	j endFindDigit
findSecondDigit:
	div $t8, $t5, $t7
	div $t8, $t7
	mfhi $t0
	j endFindDigit
findThirdDigit:
	div $t0, $t5, 100
endFindDigit:
	lw $t2, goalColor  # $t2 holds the color to draw
	lh $t9, sizeDisplay  # $t9 holds the size of the display in bytes
	beq $t0, 0, drawZero
	beq $t0, 1, drawOne
	beq $t0, 2, drawTwo
	beq $t0, 3, drawThree
	beq $t0, 4, drawFour
	beq $t0, 5, drawFive
	beq $t0, 6, drawSix
	beq $t0, 7, drawSeven
	beq $t0, 8, drawEight
	beq $t0, 9, drawNine
drawZero:
	move $t3, $t1  # $t3 holds the current location to draw
	move $t4, $t1  # $t4 holds the location of the beginning of the row
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	add $t4, $t9, $t4
	move $t3, $t4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 12
	sw $t2, displayBuffer($t3)
	add $t4, $t9, $t4
	move $t3, $t4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 12
	sw $t2, displayBuffer($t3)
	
	add $t4, $t9, $t4
	move $t3, $t4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 12
	sw $t2, displayBuffer($t3)
	add $t4, $t9, $t4
	
	move $t3, $t4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	j endDrawNumber
drawOne:
	move $t3, $t1  # $t3 holds the current location to draw
	move $t4, $t1  # $t4 holds the location of the beginning of the row
	addi $t3, $t3, 8
	sw $t2, displayBuffer($t3)
	
	add $t4, $t9, $t4
	move $t3, $t4
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)

	add $t4, $t9, $t4
	move $t3, $t4
	addi $t3, $t3, 8
	sw $t2, displayBuffer($t3)
	
	add $t4, $t9, $t4
	move $t3, $t4
	addi $t3, $t3, 8
	sw $t2, displayBuffer($t3)
	
	add $t4, $t9, $t4
	move $t3, $t4
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	j endDrawNumber
drawTwo:
	move $t3, $t1  # $t3 holds the current location to draw
	move $t4, $t1  # $t4 holds the location of the beginning of the row
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	
	add $t4, $t9, $t4
	move $t3, $t4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 12
	sw $t2, displayBuffer($t3)

	add $t4, $t9, $t4
	move $t3, $t4
	addi $t3, $t3, 8
	sw $t2, displayBuffer($t3)
	
	add $t4, $t9, $t4
	move $t3, $t4
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	
	add $t4, $t9, $t4
	move $t3, $t4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	j endDrawNumber
drawThree:
	move $t3, $t1  # $t3 holds the current location to draw
	move $t4, $t1  # $t4 holds the location of the beginning of the row
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	
	add $t4, $t9, $t4
	move $t3, $t4
	addi $t3, $t3, 12
	sw $t2, displayBuffer($t3)

	add $t4, $t9, $t4
	move $t3, $t4
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	
	add $t4, $t9, $t4
	move $t3, $t4
	addi $t3, $t3, 12
	sw $t2, displayBuffer($t3)
	
	add $t4, $t9, $t4
	move $t3, $t4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	j endDrawNumber
drawFour:
	move $t3, $t1  # $t3 holds the current location to draw
	move $t4, $t1  # $t4 holds the location of the beginning of the row
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 12
	sw $t2, displayBuffer($t3)
	
	add $t4, $t9, $t4
	move $t3, $t4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 12
	sw $t2, displayBuffer($t3)

	add $t4, $t9, $t4
	move $t3, $t4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	
	add $t4, $t9, $t4
	move $t3, $t4
	addi $t3, $t3, 12
	sw $t2, displayBuffer($t3)
	
	add $t4, $t9, $t4
	move $t3, $t4
	addi $t3, $t3, 12
	sw $t2, displayBuffer($t3)
	j endDrawNumber
drawFive:
	move $t3, $t1  # $t3 holds the current location to draw
	move $t4, $t1  # $t4 holds the location of the beginning of the row
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	
	add $t4, $t9, $t4
	move $t3, $t4
	sw $t2, displayBuffer($t3)

	add $t4, $t9, $t4
	move $t3, $t4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	
	add $t4, $t9, $t4
	move $t3, $t4
	addi $t3, $t3, 12
	sw $t2, displayBuffer($t3)
	
	add $t4, $t9, $t4
	move $t3, $t4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	j endDrawNumber
drawSix:
	move $t3, $t1  # $t3 holds the current location to draw
	move $t4, $t1  # $t4 holds the location of the beginning of the row
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	
	add $t4, $t9, $t4
	move $t3, $t4
	sw $t2, displayBuffer($t3)

	add $t4, $t9, $t4
	move $t3, $t4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	
	add $t4, $t9, $t4
	move $t3, $t4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 12
	sw $t2, displayBuffer($t3)
	
	add $t4, $t9, $t4
	move $t3, $t4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	j endDrawNumber
drawSeven:
	move $t3, $t1  # $t3 holds the current location to draw
	move $t4, $t1  # $t4 holds the location of the beginning of the row
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	
	add $t4, $t9, $t4
	move $t3, $t4
	addi $t3, $t3, 12
	sw $t2, displayBuffer($t3)

	add $t4, $t9, $t4
	move $t3, $t4
	addi $t3, $t3, 12
	sw $t2, displayBuffer($t3)
	
	add $t4, $t9, $t4
	move $t3, $t4
	addi $t3, $t3, 12
	sw $t2, displayBuffer($t3)
	
	add $t4, $t9, $t4
	move $t3, $t4
	addi $t3, $t3, 12
	sw $t2, displayBuffer($t3)
	j endDrawNumber
drawEight:
	move $t3, $t1  # $t3 holds the current location to draw
	move $t4, $t1  # $t4 holds the location of the beginning of the row
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	
	add $t4, $t9, $t4
	move $t3, $t4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 12
	sw $t2, displayBuffer($t3)

	add $t4, $t9, $t4
	move $t3, $t4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	
	add $t4, $t9, $t4
	move $t3, $t4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 12
	sw $t2, displayBuffer($t3)
	
	add $t4, $t9, $t4
	move $t3, $t4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	j endDrawNumber
drawNine:
	move $t3, $t1  # $t3 holds the current location to draw
	move $t4, $t1  # $t4 holds the location of the beginning of the row
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	
	add $t4, $t9, $t4
	move $t3, $t4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 12
	sw $t2, displayBuffer($t3)

	add $t4, $t9, $t4
	move $t3, $t4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	
	add $t4, $t9, $t4
	move $t3, $t4
	addi $t3, $t3, 12
	sw $t2, displayBuffer($t3)
	
	add $t4, $t9, $t4
	move $t3, $t4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	addi $t3, $t3, 4
	sw $t2, displayBuffer($t3)
	j endDrawNumber
endDrawNumber:
	addi $t1, $t1, -20
	j startDrawScoreLoop
endDrawScoreLoop:
endDrawScore:

# Use the screen buffer to update the screen
# Keep this code at the end
startUpdateScreen:
	la $t0, displayBuffer  # $t0 holds the address of the buffer 
	lw $t1, displayAddress  # $t1 holds the location of the display
	
	addi $t2, $zero, 4  # $t2 holds the number 4, to multiply with below
	lw $t9, displayBufferSize
	mult $t9, $t2
	mflo $t2  # $t2 holds the offset of the earliest undrawn pixel
updateScreenLoop:
	addi $t2, $t2, -4
	lw $t4, displayBuffer($t2)  # $t4 holds the color to draw
	add $t3, $t2, $t1  # $t3 holds the location in memory to draw in
	sw $t4, ($t3)  # Draw onto the screen
	
	beqz $t2, endUpdateScreenLoop
	j updateScreenLoop
endUpdateScreenLoop:
	
	lb $t0, finishSetup
	beqz $t0, endUpdateScreen
endOfSetupPhase:
	li $t0, 0
	sb $t0, finishSetup
playTheme:
	la $a0, froggerTheme
	li $a1, 300
	li $a2, 1
	lb $a3, froggerThemeLength
	jal playMidiFunction
	
endUpdateScreen:

sleep:
	li $v0, 32
	li $a0, 10
	syscall

restartGameLoop:
	j main

Exit:
	li $v0, 20
	syscall
