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
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestone is reached in this submission?
# - Milestone 2
#
# Which approved additional features have been implemented?
# 1. Change the direction the frog is pointing
# 2. Have the cars and logs move at different speeds
# 2. Add a third row in each of the water and road sections.
# 3. 
#
# Any additional information that the TA needs to know:
# - (write here, if any)
#
###################################################################

# TODO: Add screen buffer

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
	frogLocation:		.half 12, 7
	frogDirection:		.byte 0  # Stores the direction the frog is pointing at
					 # 0 is forward, 1 is left, 2 is down, 3 is right

	carLocations:		.byte 28, 12, 0, 16
	carSizes:		.byte 2, 2, 2, 2
	carSpeeds:		.byte 1, 1, 2, 2  # Speeds must be positive
	logLocations:		.byte 8, 24, 4, 20
	logSizes:		.byte 2, 2, 2, 2
	logSpeeds:		.byte -1, -1, -2, -2  # Speeds can be positive or negative
	numCarsTotal:		.byte 4
	numLogsTotal:		.byte 4
	numCarsPerRow:		.byte 2
	numLogsPerRow:		.byte 2
	
	scoreColor:		.word 0x00000000
	grassColor: 		.word 0x0000ff00
	waterColor: 		.word 0x000000ff
	safeColor:		.word 0x00ffff00
	roadColor:		.word 0x00808080
	frogColor:		.word 0x00663399
	carColor:		.word 0x00ff0000
	logColor:		.word 0x00b5651d
	
	sizeDisplay:		.half 128  # Num bytes for every row in the display
	pixelsInDisplay:	.byte 32   # Num pixels for every row in the display
	pixelsInDisplayDown:	.byte 32   # Num pixels down the display
	sizeFrog:		.byte 4    # In number of pixels
					   # IMPORTANT: If this is changed, the frog sprite must be updated accordingly
	
	displayBufferSize:	.half  4096  # The space in the display buffer
	displayBuffer:		.space 4096  # The buffer for the display to stop the screen from blinking
					     # Set the display buffer to be pixelsInDisplay * pixelsInDisplayDown * 4
	
	# Everything here is in number of sizeFrogs
	sizeScore:		.byte 1
	sizeGoal:		.byte 1
	sizeWater:		.byte 2
	sizeSafe:		.byte 1
	sizeRoad:		.byte 2
	sizeStart:		.byte 1

.text
start:
	j main

# Draws a rectangle at coordinates (x, y) = ($a0, $a1) of width $a2 in frog sizes and height 1 frog size
# with the color in $a3
drawRectangle:
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
	beqz $s2, FunctionEnd
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

FunctionEnd:
	jr $ra

main:
moveFrog:
	lw $t8, 0xffff0000
	bne $t8, 1, endMoveFrog

	lw $t3, 0xffff0004  # $t3 contains the ascii value of the key pressed
	la $t0, frogLocation  # $t0 points to the location of the frog
	la $t4, frogDirection  # $t4 points to the direction of the frog
	lh $t1, ($t0)  # $t1 holds the x coordinate of the frog
	lh $t2, 2($t0)  # $t2 holds the y coordinate of the frog
	lb $t9, pixelsInDisplay
	
	beq $t3, 0x61, handleLeft
	beq $t3, 0x77, handleUp
	beq $t3, 0x64, handleRight
	beq $t3, 0x73, handleDown
	j moveFrog
handleLeft:
	addi $t5, $zero, 3
	sb $t5, ($t4)  # Load the direction

	addi $t1, $t1, -4
	bgez $t1, handleLeftEnd
	addi $t1, $t1, 4
handleLeftEnd:
	sh $t1, ($t0)
	j endMoveFrog
handleUp:
	addi $t5, $zero, 0
	sb $t5, ($t4)  # Load the direction
	
	addi $t2, $t2, -1
	bgez $t2, handleUpEnd
	addi $t2, $t2, 1
handleUpEnd:
	sh $t2, 2($t0)
	
	j endMoveFrog
handleRight:
	addi $t5, $zero, 1
	sb $t5, ($t4)  # Load the direction
	
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

	addi $t2, $t2, 1
	addi $t6, $zero, 4
	mult $t2, $t6
	mflo $t7
	blt $t7, $t9, handleDownEnd
	addi $t2, $t2, -1
handleDownEnd:
	sh $t2, 2($t0)
	
	j endMoveFrog
endMoveFrog:

startDrawScore:
	# Draw a heart for each life on the top left of the screen
endDrawScore:

moveCars:
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
moveCarsEnd:

moveLogs:
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
	beq $t1, $t9, drawObjectsStart

	add $t3, $t0, $t1  # $t3 holds the address + offset: the pixel to draw
	sw $t2, 0($t3)
	addi $t1, $t1, 4

	j drawSceneStartRegion

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
	
	jal drawRectangle
	
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
	
	jal drawRectangle
	
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

# Use the screen buffer to update the screen
# Keep this code at the end
startUpdateScreen:
	la $t0, displayBuffer  # $t0 holds the address of the buffer 
	lw $t1, displayAddress  # $t1 holds the location of the display
	
	addi $t2, $zero, 4  # $t2 holds the number 4, to multiply with below
	lh $t9, displayBufferSize
	mult $t9, $t2
	mflo $t2  # $t2 holds the offset of the earliest undrawn pixel
updateScreenLoop:
	beqz $t2, endUpdateScreenLoop
	
	add $t3, $t2, $t0  # $t3 holds the address of the location in the buffer being drawn
	lw $t4, ($t3)  # $t4 holds the color to draw
	add $t3, $t2, $t1   # $t3 holds the location in memory to draw in
	sw $t4, ($t3)  # Draw onto the screen
	
	addi $t2, $t2, -4
	j updateScreenLoop
endUpdateScreenLoop:

endUpdateScreen:

sleep:
	li $v0, 32
	li $a0, 100
	syscall

restartGameLoop:
	j main

Exit:
	li $v0, 10
	syscall
