# Frogger in MIPS
#
# Note that the size of the frog is written in number of pixels
# The size of the display is in number of bytes across (this turned out to be more convenient than number of pixels)
# The size of all other objects is relative to the size of the frog, i.e. a size of num is sizeFrog * num pixels

.data
	displayAddress:		.word 0x10008000
	
	lives:			.byte 3
	frogLocation:		.half 14, 7

	carLocations:		.byte 0, 16, 0, 16
	carSizes:		.byte 2, 2, 2, 2
	logLocations:		.byte 0, 16, 0, 16
	logSizes:		.byte 2, 2, 2, 2
	numCarsTotal:		.byte 4
	numLogsTotal:		.byte 4
	numCarsPerRow:		.byte 2, 2
	numLogsPerRow:		.byte 2, 2
	
	grassColor: 		.word 0x0000ff00
	waterColor: 		.word 0x000000ff
	safeColor:		.word 0x00ffff00
	roadColor:		.word 0x00808080
	frogColor:		.word 0x00663399
	carColor:		.word 0x00ff0000
	logColor:		.word 0x00ff00ff
	
	sizeDisplay:		.half 128  # Num bytes for every row in the display
	sizeFrog:		.byte 4    # In number of pixels
					   # IMPORTANT: If this is changed, the frog sprite must be updated accordingly
	# Everything here is in number of sizeFrogs
	sizeGoal:		.byte 2
	sizeWater:		.byte 2
	sizeSafe:		.byte 1
	sizeRoad:		.byte 2
	sizeStart:		.byte 1

.text
main:
# TODO: Create a draw at location function to simplify all of this
drawScene:
	lw $t0, displayAddress # $t0 holds the displayAddress
	add $t1, $zero, $zero  # $t1 holds the current offset of the screen to draw on
	lw $t2, grassColor     # $t2 holds the color to draw
	
drawSceneGoalRegionInit:
	lh $t9, sizeDisplay
	lb $t8, sizeFrog
	mult $t9, $t8
	mflo $t9
	lb $t8, sizeGoal
	mult $t9, $t8
	mflo $t9

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
	
	
drawSceneWaterRegion:
	lw $t2, waterColor
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
	
	lw $t0, displayAddress  # $t0 now holds the display address
	lw $t4, frogColor       # $t4 holds the color of the frog
	
	lh $t5, sizeDisplay  # $t5 is the size of the display
	mult $t5, $t2
	mflo $t6
	add $t6, $t0, $t6
	add $t6, $t6, $t1
	
	# $t6 holds the top left pixel of the frog
	# $t5 holds the number of bytes in one row of pixels
	# $t4 holds the color of the frog
	
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
	
drawCarsInit:
	lb $t0, numCarsTotal   # $t0 holds the number of cars left to draw
	lb $t1, numCarsPerRow  # $t1 holds the number of cars to draw per row
	la $t2, carLocations   # $t2 holds the address of the location of the cars
	la $t3, carSizes       # $t3 holds the address of the size of the cars
	
	lb $t5, sizeGoal
	add $t4, $zero, $t5
	lb $t5, sizeWater
	add $t4, $t4, $t5
	lb $t5, sizeSafe
	add $t4, $t4, $t5

	mult $t4, $t5
	mflo $t4
	lw $t6, sizeDisplay
	mult $t4, $t6
	mflo $t4  # $t4 holds the byte to start writing at
	
	lw $t5, carColor  # $t5 holds the color of the car
	
drawCars:
	beqz $t0, drawLogs
	lb $t1, numCarsPerRow
	
drawCarsRow:  # Draw a row of cars
	beqz $t1, drawCars
	
	
	
	addi $t0, $t0, -1
	addi $t1, $t1, -1
	j drawCarsRow
	
drawLogs:

Exit:
	li $v0, 10
	syscall
