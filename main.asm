.data
	displayAddress:		.word 0x10008000
	

	lives:			.byte 3
	frogLocation:		.byte 14, 7
	carsLocations:		.byte 0, 4, 0, 4
	logsLocations:		.byte 0, 4, 0, 4
	
	grassColor: 		.word 0x0000ff00
	waterColor: 		.word 0x000000ff
	sandColor:		.word 0x00ffff00
	roadColor:		.word 0x00808080
	frogColor:		.word 0x00663399
	
	
	sizeDisplay:		.half 128
	sizeFrog:		.byte 4
	# Relative to the size of the frog
	sizeGoal:		.byte 2
	sizeWater:		.byte 2
	sizeSand:		.byte 1
	sizeRoad:		.byte 2
	sizeStart:		.byte 1

.text
main:
# TODO: Fix the pixels at the x-coordinates
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
	lb $t8, sizeSand
	mult $t9, $t8
	mflo $t9
	add $t9, $t9, $t7
	
	lw $t2, sandColor
	
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
	lb $t1, 0($t0)  # $t1 is the x-coordinate in terms of frog sizes
	lb $t2, 1($t0)  # $t2 is the y-coordinate in terms of frog sizes
	
	lb $t3, sizeFrog
	mult $t1, $t3
	mflo $t1  # $t1 is the x-coordinate in terms of pixels 
	mult $t2, $t3
	mflo $t2  # $t2 is the y-coordinate in terms of pixels
	
	lw $t0, displayAddress  # $t0 holds the display address
	lw $t4, frogColor       # $t4 holds the color of the frog
	
	lh $t5, sizeDisplay  # $t5 is the size of the display
	mult $t5, $t2
	mflo $t6
	add $t6, $t0, $t6
	add $t6, $t6, $t1    # $t6 holds the top left pixel of the frog
	
	
	sw $t4, 0($t6)
	sw $t4, 12($t6)
	add $t6, $t6, $t5
	sw $t4, 0($t6)
	sw $t4, 4($t6)
	sw $t4, 8($t6)
	sw $t4, 12($t6)
	add $t6, $t6, $t5
	sw $t4, 4($t6)
	sw $t4, 8($t6)
	add $t6, $t6, $t5
	sw $t4, 0($t6)
	sw $t4, 4($t6)
	sw $t4, 8($t6)
	sw $t4, 12($t6)
	
drawCars:
drawLogs:

Exit:
	li $v0, 10
	syscall
