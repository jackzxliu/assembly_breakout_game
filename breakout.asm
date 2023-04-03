################ CSC258H1F Fall 2022 Assembly Final Project ##################
# This file contains our implementation of Breakout.
#
# Student 1: Jack, 1008012124
# Student 2: Natalie, 1008009986
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    256
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

.data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL: .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD: .word 0xffff0000

##############################################################################
# Mutable Data
##############################################################################

# ANY COLOR YOU LIKE
CURR_COLOR: .word 0x000000
GREY: .word 0xaaaaaa
WHITE: .word 0xffffff
# BLACK: .word 0x00000000    proof that Jack is stupid and forgot $zero exists

# THESE COLOURS ARE DIVIDED BY 3
RED: .word 0x44050f
ORANGE: .word 0x4d2c07
YELLOW: .word 0x55550d
GREEN: .word 0x2a420f
BLUE: .word 0x26404a
PURPLE: .word 0x21192e

#
DARK_BLUE: .word 0x2f3699

# DIAMOND
DIAMOND1: .word 0x2b8abd
DIAMOND2: .word 0x37b1e5
DIAMOND3: .word 0x00b7ef
DIAMOND4: .word 0x61e2ff
DIAMOND5: .word 0xb0f7ff

# byte 0 represents game state: 0 = in game, 1 = main menu, 2 = paused, 3 = end screen
# byte 1 indicates which level is being selected
# byte 2-3 stores current score
STATS: .word 0x00000001

# Paddle: x, y at byte 0, 1. x is centered on paddle (not top-left).
# health at byte 2. byte 3 indicates whether ball has been launched (0 if yes, 1 if no)
PADDLE: .word 0x01031e10

# Ball: x, y at byte 0, 1. x vel, y vel at byte 2, 3.
# Note that x, y will be shifted right by 1 (divided by 2) before drawing the ball. This allows the direction to be more variable.
BALL: .word 0xfe00001f

COUNTER: .word 0

# Settings to initialize bricks into memory.
# This int represents number of bricks to draw/calculate. It may differ based on different initializations.
NUM_BRICKS: .word 50

# Bricks Struct: x, y at byte 0, 1. width, height at byte 2, 3. (lil endian)
# Additional Attributes: type at byte 4. 0 if wall, 1 if regular brick.
# 			 color at byte 5. 0 is grey. 1-6 represent red, orange, yellow, green, blue, purple respectively. 
#            7 is white. 8, 9, 10, 11, 12 represents the 5 diamond colours.
#			 health at byte 6. blocks die at 0 health and will not be used in collision calculation.
#			 byte 7 is unused rn.
BRICKS: # 2 words / 8 bytes per brick struct
#Walls
.word 0x19010500
.word 0
.word 0x1901051f
.word 0
.word 0x011e0501
.word 0

.word 0x00030101:100  # Enough space for 50 Bricks. 


##############################################################################
# Code
##############################################################################
.text
.globl main

# Run the Brick Breaker game.
main:

# These save registers will act as cache, and store important addresses accessed throughout the code. DO NOT CHANGE OR USE FOR ANYTHING ELSE!!!
la $s1, PADDLE
la $s2, BALL
lw $s6, ADDR_KBRD
la $s7, STATS
# Note that this is not clean code and will not be reproducable on a massive scale. I did this for convenience purposes.

j draw_menu

initialize_game:
lb $t0, 1($s7)
beq $t0, 0, setup_1
beq $t0, 1, setup_2
beq $t0, 2, setup_3

setup_1: # ANY COLOUR YOU LIKE :)
li $t0, 27
sw $t0, NUM_BRICKS
la $s0, BRICKS
addi $s0, $s0, 24 # Skip the pre-defined walls
li $t2, 8 # Starting y
li $t3, 3 # Width of each brick
li $t4, 2 # Height of each brick
li $t7, 2 # Width of each gap
li $t8, 1 # Height of each gap

li $t5, 0
init_outer_1:
beq $t5, 4, init_finish_1
li $t6, 0
li $t1, 0 # Starting x
addi $t5, $t5, 1
init_inner_1:
beq $t6, 6, init_inner_finish_1
addi $t6, $t6, 1
add $t1, $t1, $t7
sb $t1, 0($s0) # Store brick x
sb $t2, 1($s0) # Store brick y
sb $t3, 2($s0) # Store brick width
sb $t4, 3($s0) # Store brick height
li $t9, 1
sb $t9, 4($s0) # Store brick type
add $t1, $t1, $t3
sb $t6, 5($s0) # Store color
li $t9, 3
sb $t9, 6($s0) # Store health
addi $s0, $s0, 8
j init_inner_1
init_inner_finish_1:
add $t2, $t2, $t4
add $t2, $t2, $t8
j init_outer_1
init_finish_1:
j draw_bricks



setup_2: # SHINE YOU DIAMOND
li $t0, 41
sw $t0, NUM_BRICKS
la $s0, BRICKS
addi $s0, $s0, 24 # Skip the pre-defined walls
li $t5, 0x01141706
sw $t5, 0($s0)
sw $zero, 4($s0) # Extra wall

addi $s0, $s0, 8
li $t6, 2
li $t5, 11
li $t4, 9
li $s5, 0x00010801
diamond_init_1:
beq $t5, 21, diamond_init_1_end
sb $t5, 0($s0) # Store brick x
sb $t4, 1($s0) # Store brick y
sb $t6, 2($s0) # Store brick width
sb $t6, 3($s0) # Store brick height
sw $s5, 4($s0)
addi $s0, $s0, 8
addi $t5, $t5, 2
j diamond_init_1
diamond_init_1_end:
li $t5, 7
li $t4, 13
diamond_init_2:
beq $t5, 17, diamond_init_2_end
sb $t5, 0($s0) # Store brick x
sb $t4, 1($s0) # Store brick y
sb $t6, 2($s0) # Store brick width
sb $t6, 3($s0) # Store brick height
sw $s5, 4($s0)
addi $s0, $s0, 8
addi $t5, $t5, 2
addi $t4, $t4, 2
j diamond_init_2
diamond_init_2_end:
li $t5, 23
li $t4, 13
diamond_init_3:
beq $t5, 15, diamond_init_3_end
sb $t5, 0($s0) # Store brick x
sb $t4, 1($s0) # Store brick y
sb $t6, 2($s0) # Store brick width
sb $t6, 3($s0) # Store brick height
sw $s5, 4($s0)
addi $s0, $s0, 8
addi $t5, $t5, -2
addi $t4, $t4, 2
j diamond_init_3
diamond_init_3_end:
li $t5, 0x02020b09
sw $t5, 0($s0)
sw $s5, 4($s0)
addi $s0, $s0, 8
li $t5, 21
li $t4, 11
li $t5, 0x02020b15
sw $t5, 0($s0)
sw $s5, 4($s0)
addi $s0, $s0, 8
li $s5, 0x00010901
li $t5, 0x02020f0b
sw $t5, 0($s0)
sw $s5, 4($s0)
addi $s0, $s0, 8
li $t5, 0x02020f0d
sw $t5, 0($s0)
sw $s5, 4($s0)
addi $s0, $s0, 8
li $t5, 0x0202110d
sw $t5, 0($s0)
sw $s5, 4($s0)
addi $s0, $s0, 8
li $s5, 0x00010a01
li $t5, 0x02020d09
sw $t5, 0($s0)
sw $s5, 4($s0)
addi $s0, $s0, 8
li $t5, 0x02020d0b
sw $t5, 0($s0)
sw $s5, 4($s0)
addi $s0, $s0, 8
li $t5, 0x02020d0d
sw $t5, 0($s0)
sw $s5, 4($s0)
addi $s0, $s0, 8
li $t5, 0x02020b0b
sw $t5, 0($s0)
sw $s5, 4($s0)
addi $s0, $s0, 8
li $t5, 0x02020f0f
sw $t5, 0($s0)
sw $s5, 4($s0)
addi $s0, $s0, 8
li $t5, 0x0202110f
sw $t5, 0($s0)
sw $s5, 4($s0)
addi $s0, $s0, 8
li $t5, 0x0202130f
sw $t5, 0($s0)
sw $s5, 4($s0)
addi $s0, $s0, 8
li $s5, 0x00010b01
li $t5, 0x02020b0d
sw $t5, 0($s0)
sw $s5, 4($s0)
addi $s0, $s0, 8
li $t5, 0x02020b0f
sw $t5, 0($s0)
sw $s5, 4($s0)
addi $s0, $s0, 8
li $t5, 0x02020b11
sw $t5, 0($s0)
sw $s5, 4($s0)
addi $s0, $s0, 8
li $t5, 0x02020d0f
sw $t5, 0($s0)
sw $s5, 4($s0)
addi $s0, $s0, 8
li $t5, 0x02020f11
sw $t5, 0($s0)
sw $s5, 4($s0)
addi $s0, $s0, 8
li $t5, 0x02021111
sw $t5, 0($s0)
sw $s5, 4($s0)
addi $s0, $s0, 8
li $t5, 0x02020f13
sw $t5, 0($s0)
sw $s5, 4($s0)
addi $s0, $s0, 8
li $s5, 0x00010c01
li $t5, 0x02020d11
sw $t5, 0($s0)
sw $s5, 4($s0)
addi $s0, $s0, 8
li $t5, 0x02020d13
sw $t5, 0($s0)
sw $s5, 4($s0)
addi $s0, $s0, 8
li $t5, 0x02020d15
sw $t5, 0($s0)
sw $s5, 4($s0)
addi $s0, $s0, 8
li $t5, 0x02020b13
sw $t5, 0($s0)
sw $s5, 4($s0)
addi $s0, $s0, 8

j draw_bricks

setup_3: # ANOTHER BRICK IN THE WALL

li $t0, 36
sw $t0, NUM_BRICKS
la $s0, BRICKS
addi $s0, $s0, 24 # Skip the pre-defined walls

li $t9, 0x00010701 # Attributes of each brick
li $t3, 5 # Width of each brick
li $t4, 2 # Height of each brick
li $t7, 1 # Width of each gap
li $t8, 4 # Height of each gap

li $t2, 6 # Starting y
li $t5, 0
init_outer_3:
beq $t5, 3, init_finish_3
li $t6, 0
li $t1, 1
init_inner_3:
beq $t6, 5, init_inner_finish_3
sb $t1, 0($s0) # Store brick x
sb $t2, 1($s0) # Store brick y
sb $t3, 2($s0) # Store brick width
sb $t4, 3($s0) # Store brick height
sw $t9, 4($s0) # Store brick attributes
add $t1, $t1, $t3
add $t1, $t1, $t7
addi $t6, $t6, 1
addi $s0, $s0, 8
j init_inner_3
init_inner_finish_3:
add $t2, $t2, $t4
add $t2, $t2, $t8
addi $t5, $t5, 1
j init_outer_3
init_finish_3:

li $t2, 9 # Starting y
li $t5, 0
init_outer_4:
beq $t5, 3, init_finish_4
li $t6, 0
li $t1, 4
init_inner_4:
beq $t6, 4, init_inner_finish_4
sb $t1, 0($s0) # Store brick x
sb $t2, 1($s0) # Store brick y
sb $t3, 2($s0) # Store brick width
sb $t4, 3($s0) # Store brick height
sw $t9, 4($s0) # Store brick attributes
add $t1, $t1, $t3
add $t1, $t1, $t7
addi $t6, $t6, 1
addi $s0, $s0, 8
j init_inner_4
init_inner_finish_4:
add $t2, $t2, $t4
add $t2, $t2, $t8
addi $t5, $t5, 1
j init_outer_4
init_finish_4:

li $t2, 9
li $t1, 1
li $t3, 2
side_bricks_1:
beq $t2, 27, end_side_bricks_1
sb $t1, 0($s0) # Store brick x
sb $t2, 1($s0) # Store brick y
sb $t3, 2($s0) # Store brick width
sb $t3, 3($s0) # Store brick height
sw $t9, 4($s0) # Store brick attributes
addi $s0, $s0, 8
addi $t2, $t2, 6
j side_bricks_1
end_side_bricks_1:

li $t2, 9
li $t1, 28
li $t3, 3
li $t4, 2
side_bricks_2:
beq $t2, 27, end_side_bricks_2
sb $t1, 0($s0) # Store brick x
sb $t2, 1($s0) # Store brick y
sb $t3, 2($s0) # Store brick width
sb $t4, 3($s0) # Store brick height
sw $t9, 4($s0) # Store brick attributes
addi $s0, $s0, 8
addi $t2, $t2, 6
j side_bricks_2
end_side_bricks_2:

li $v0 , 42
li $a0 , 0
li $a1 , 14
syscall

beq $a0, 3, set_14_instead
beq $a0, 4, set_15_instead
beq $a0, 8, set_16_instead
j random_brick
set_14_instead:
li $a0, 14
j random_brick
set_15_instead:
li $a0, 15
j random_brick
set_16_instead:
li $a0, 16
random_brick:
sll $a0, $a0, 3
la $s0, BRICKS
addi $s0, $s0, 72
add $s0, $s0, $a0
li $t9, 0x01030101
sw $t9, 4($s0)

j draw_bricks

##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##
##################################################################################################################################
##################################################### THE GREAT WALL OF CHINA ####################################################
##################################################################################################################################

draw_bricks:
# Draw Bricks
la $s0, BRICKS
li $t2, 0
lw $t3, NUM_BRICKS
draw_bricks_loop:
beq $t2, $t3, end_draw_bricks
lb $a0, 5($s0)
lb $a1, 6($s0)
jal set_color # Set CURR_COLOR to the desired COLOR for the brick
lb $a0, 0($s0)
lb $a1, 1($s0)
lb $a2, 2($s0)
lb $a3, 3($s0)

addi $s0, $s0, 8
addi $t2, $t2, 1
jal draw_rect

j draw_bricks_loop
end_draw_bricks:

# Draw score (Should be all 0)
jal draw_score

# Draw Hearts
li $a0, 1
li $a1, 3
jal set_color # Set color to red (change $a0 to 5 if you want a blue heart)

li $t3, 20
heart_loop_1:
bge $t3, 31, heart_loop_1_end
move $a0, $t3
li $a1, 1
li $a2, 1
li $a3, 2
jal draw_rect
addi $t3, $t3, 2
j heart_loop_1
heart_loop_1_end:

li $t3, 21
heart_loop_2:
bge $t3, 31, heart_loop_2_end
move $a0, $t3
li $a1, 2
li $a2, 1
li $a3, 2
jal draw_rect
addi $t3, $t3, 4
j heart_loop_2
heart_loop_2_end:

j game_loop

############################### GAME LOOP ####################################

game_loop:

lb $t1, 0($s7)
beqz $t1, in_game
beq $t1, 1, in_menu
beq $t1, 2, pause
j end_screen

pause:
lw $t8, 0($s6)
bne $t8, 1, game_loop
lw $a0, 4($s6)
bne $a0, 0x70, game_loop
# P is pressed and we can unpause
sw $zero, CURR_COLOR
li $a0, 14
li $a1, 1
li $a2, 3
li $a3, 3
jal draw_rect
sb $zero, 0($s7)
j game_loop

in_menu:
lw $t8, 0($s6)
beq $t8, 1, menu_keyboard_input
j game_loop
menu_keyboard_input:
lw $a0, 4($s6)
beq $a0, 0x61, menu_left
beq $a0, 0x64, menu_right
beq $a0, 0x20, menu_space_bar
beq $a0, 0x71, exit
j game_loop

menu_left:
lb $t1, 1($s7)
beqz $t1, game_loop # Already leftmost menu option.
addi $t1, $t1, -1
sb $t1, 1($s7)
j draw_menu_options

menu_right:
lb $t1, 1($s7)
beq $t1, 2, game_loop # Already rightmost menu option.
addi $t1, $t1, 1
sb $t1, 1($s7)
j draw_menu_options

menu_space_bar:
sb $zero, 0($s7)
li $a0, 0
li $a1, 0
li $a2, 32
li $a3, 32
sw $zero, CURR_COLOR
jal draw_rect

j initialize_game

in_game:
# Check if key has been pressed
lw $t8, 0($s6)                  # Load first word from keyboard
beq $t8, 1, keyboard_input      # If first word 1, key is pressed
j end_input


# Process pressed key
keyboard_input:          # A key is pressed
lw $a0, 4($s6)           # Load second word from keyboard
beq $a0, 0x61, a_pressed # Check if the key a was pressed
beq $a0, 0x64, d_pressed # :(
beq $a0, 0x20, space_bar
beq $a0, 0x71, q_pressed
beq $a0, 0x70, p_pressed
j end_input


# Functions for different keyboard inputs
a_pressed:
lb $t0, 0($s1)
lb $t1, 1($s1)
ble $t0, 2, end_input # if paddle already on leftmost position
addi $a0, $t0, 2
addi $a1, $t1, 0
jal draw_black_pixel
addi $t0, $t0, -1
sb $t0, 0($s1)
j end_input

d_pressed:
lb $t0, 0($s1)
lb $t1, 1($s1)
bge $t0, 29, end_input # if paddle already on rightmost position
addi $a0, $t0, -2
addi $a1, $t1, 0
jal draw_black_pixel
addi $t0, $t0, 1
sb $t0, 0($s1)
j end_input

space_bar:
li $t0, 0
sb $t0, 3($s1)
sw $zero, COUNTER
j end_input

q_pressed:
sb $zero, 0($s7)
li $a0, 0
li $a1, 0
li $a2, 32
li $a3, 32
sw $zero, CURR_COLOR
jal draw_rect

li $t0, 0x01031e10
sw $t0, PADDLE
li $t0, 0xfe00001f
sw $t0, BALL
li $t0, 1
sb $t0, STATS
sh $zero, 2($s7)

j draw_menu

p_pressed:
lw $t0, GREY
sw $t0, CURR_COLOR
li $a0, 14
li $a1, 1
li $a2, 1
li $a3, 3
jal draw_rect
li $a0, 16
li $a1, 1
li $a2, 1
li $a3, 3
jal draw_rect
li $t0, 2
sb $t0, 0($s7)
j game_loop

end_input:
lw $t0, COUNTER
bne $t0, 0, ball_move_finish
li $t0, 6
sw $t0, COUNTER # Update ball every 6 frames

# Erase Previous Ball
lb $a0, 0($s2)
lb $a1, 1($s2)
srl $a0, $a0, 1
srl $a1, $a1, 1
jal draw_black_pixel

# Update Ball Location
lb $t1, 3($s1)
beqz $t1, ball_move # Move ball if it is launched
lb $t0, 0($s1)
lb $t1, 1($s1)
addi $t1, $t1, -2
sll $t0, $t0, 1
sll $t1, $t1, 1
sb $t0, 0($s2)
sb $t1, 1($s2)
j ball_move_finish

ball_move:

# Move Y & Collision Checks
lb $t1, 1($s2)
lb $t3, 3($s2)
add $t1, $t1, $t3
sb $t1, 1($s2)

recheck_y:
lb $t0, 0($s2)
sra $t0, $t0, 1
lb $t1, 1($s2)
sra $t1, $t1, 1
lb $t3, 3($s2)
la $s0, BRICKS
li $t6, 0
lb $t7, NUM_BRICKS

# Check & Process collisions in x direction

check_y:
beq $t6, $t7, end_check_y
lb $t4, 4($s0)
beqz $t4, is_wall_y
lb $a1, 6($s0)
beq $a1, $zero, no_collision_y # This Block has 0 health, go to next block
is_wall_y:
lb $t4, 0($s0)
blt $t0, $t4, no_collision_y # ball x is less than brick x
lb $t5, 2($s0)
add $t5, $t4, $t5
bge $t0, $t5, no_collision_y # ball x is greater than brick x + width of brick
lb $t4, 1($s0)
blt $t1, $t4, no_collision_y # ball y is less than brick y
lb $t5, 3($s0)
add $t4, $t4, $t5
bge $t1, $t4, no_collision_y # ball y is greater than brick y + width of brick
j collision_y # otherwise, a collision occurred!

no_collision_y:
addi $s0, $s0, 8
addi $t6, $t6, 1
j check_y

collision_y:
# Flip y velocity, and move ball in other direction instead
neg $t3, $t3
sb $t3, 3($s2)
lb $t1, 1($s2)
add $t1, $t1, $t3
add $t1, $t1, $t3
sb $t1, 1($s2)

# Check if brick is wall, if so skip the following part
lb $t1, 4($s0)
beqz $t1, recheck_y

# Update Brick Health
addi $a1, $a1, -1
sb $a1, 6($s0)
# Re-Draw Brick
lb $a0, 5($s0)
jal set_color
lb $a0, 0($s0)
lb $a1, 1($s0)
lb $a2, 2($s0)
lb $a3, 3($s0)
jal draw_rect

jal increase_score

j recheck_y  # Re-check collisions with all the bricks

end_check_y:

# Move X & Collision Checks
lb $t0, 0($s2)
lb $t2, 2($s2)
add $t0, $t0, $t2
sb $t0, 0($s2)

recheck_x:
lb $t0, 0($s2)
sra $t0, $t0, 1
lb $t1, 1($s2)
sra $t1, $t1, 1
lb $t2, 2($s2)
la $s0, BRICKS
li $t6, 0
lb $t7, NUM_BRICKS

# Check & Process collisions in x direction

check_x:
beq $t6, $t7, end_check_x
lb $t4, 4($s0)
beqz $t4, is_wall_x
lb $a1, 6($s0)
beq $a1, $zero, no_collision_x # This Block has 0 health, go to next block
is_wall_x:
lb $t4, 0($s0)
blt $t0, $t4, no_collision_x # ball x is less than brick x
lb $t5, 2($s0)
add $t5, $t4, $t5
bge $t0, $t5, no_collision_x # ball x is greater than brick x + width of brick
lb $t4, 1($s0)
blt $t1, $t4, no_collision_x # ball y is less than brick y
lb $t5, 3($s0)
add $t4, $t4, $t5
bge $t1, $t4, no_collision_x # ball y is greater than brick y + width of brick
j collision_x # otherwise, a collision occurred!

no_collision_x:
addi $s0, $s0, 8
addi $t6, $t6, 1
j check_x

collision_x:
# Flip x velocity, and move ball in other direction instead
neg $t2, $t2
sb $t2, 2($s2)
lb $t0, 0($s2)
add $t0, $t0, $t2
add $t0, $t0, $t2
sb $t0, 0($s2)

# Check if brick is wall, if so skip the following part
lb $t1, 4($s0)
beqz $t1, recheck_x

# Update Brick Health
addi $a1, $a1, -1
sb $a1, 6($s0)

# Re-Draw Brick
lb $a0, 5($s0)
jal set_color
lb $a0, 0($s0)
lb $a1, 1($s0)
lb $a2, 2($s0)
lb $a3, 3($s0)
jal draw_rect

jal increase_score

j recheck_x  # Re-check collisions with all the bricks
end_check_x:

# Paddle Collision Check
lb $t2, 3($s2)
blez $t2, ball_move_finish # Ball is moving up, dont care about paddle collision
lb $t1, 1($s2)
sra $t1, $t1, 1
lb $t0, 1($s1)
addi $t0, $t0, -1
bne $t0, $t1, win_check # Ball is not right above paddle y level, dont care about paddle collision
lb $t0, 0($s1)
lb $t1, 0($s2)
sra $t1, $t1, 1
sub $t0, $t1, $t0
beq $t0, -2, bounce_30
beq $t0, -1, bounce_60
beq $t0, 0, bounce_r
beq $t0, 1, bounce_120
beq $t0, 2, bounce_150
j ball_move_finish

bounce_30:
li $t0, -2
sb $t0, 2($s2)
li $t0, -1
sb $t0, 3($s2)
j ball_move_finish
bounce_60:
li $t0, -1
sb $t0, 2($s2)
bounce_r:
li $t0, -2
sb $t0, 3($s2)
j ball_move_finish
bounce_120:
li $t0, 1
sb $t0, 2($s2)
j bounce_r
bounce_150:
li $t0, 2
sb $t0, 2($s2)
li $t0, -1
sb $t0, 3($s2)
j ball_move_finish

win_check:
la $s0, BRICKS
li $t2, 0
lb $t3, NUM_BRICKS
win_check_loop:
beq $t2, $t3, victory
lb $t0, 6($s0)
bnez $t0, ball_out_check  # There exists a brick with non-zero health
addi $s0, $s0, 8
addi $t2, $t2, 1
j win_check_loop

ball_out_check:
lb $t0, 1($s2)
ble $t0, 70, ball_move_finish # Ball is not out

# Ball is out
li $t0, 1
sb $t0, 3($s1) # Set ball to unlaunched
lb $t0, 2($s1)
addi $t0, $t0, -1
sb $t0, 2($s1) # Update health

beqz $t0, game_over

sll $t0, $t0, 2
li $a0, 28
sub $a0, $a0, $t0
li $a1, 1
li $a2, 3
li $a3, 3
sw $zero, CURR_COLOR
jal draw_rect # Cover a heart with black rectangle

li $t0, 0
sb $t0, 2($s2)
li $t0, -2
sb $t0, 3($s2)

ball_move_finish:

# Draw Paddle
lw $t1, WHITE
sw $t1, CURR_COLOR
lb $a0, 0($s1)
addi $a0, $a0, -2
lb $a1, 1($s1)
li $a2, 5
li $a3, 1
jal draw_rect

# Draw Ball
lw $t0, WHITE
sw $t0, CURR_COLOR
lb $a0, 0($s2)
lb $a1, 1($s2)
sra $a0, $a0, 1
sra $a1, $a1, 1
jal draw_pixel

# Decrease counter
lw $t0, COUNTER
addi $t0, $t0, -1
sw $t0, COUNTER

# Sleep Call
li $v0, 32
li $a0, 17 # Kinda 60 FPS
syscall

j game_loop

##################################################################################################################################

game_over:
sb $zero, 0($s7)
li $a0, 0
li $a1, 0
li $a2, 32
li $a3, 32
sw $zero, CURR_COLOR
jal draw_rect
li $t0, 3
sb $t0, STATS
lw $t0, WHITE
sw $t0, CURR_COLOR

li $a0, 6
li $a1, 4
li $a2, 3
li $a3, 1
jal draw_rect
li $a0, 6
li $a1, 6
li $a2, 3
li $a3, 1
jal draw_rect
li $a0, 6
li $a1, 8
li $a2, 3
li $a3, 1
jal draw_rect
li $a0, 6
li $a1, 5
jal draw_pixel
li $a0, 8
li $a1, 7
jal draw_pixel
li $a0, 10
li $a1, 4
li $a2, 1
li $a3, 5
jal draw_rect

li $a0, 15
li $a1, 4
li $a2, 1
li $a3, 5
jal draw_rect
li $a0, 17
li $a1, 4
li $a2, 1
li $a3, 5
jal draw_rect
li $a0, 21
li $a1, 4
li $a2, 1
li $a3, 5
jal draw_rect
li $a0, 13
li $a1, 4
jal draw_pixel
li $a0, 12
li $a1, 5
jal draw_pixel
li $a0, 11
li $a1, 6
jal draw_pixel
li $a0, 12
li $a1, 7
jal draw_pixel
li $a0, 13
li $a1, 8
jal draw_pixel
li $a0, 18
li $a1, 8
jal draw_pixel
li $a0, 19
li $a1, 8
jal draw_pixel
li $a0, 22
li $a1, 8
jal draw_pixel
li $a0, 23
li $a1, 8
jal draw_pixel
li $a0, 6
li $a1, 11
li $a2, 1
li $a3, 5
jal draw_rect
li $a0, 16
li $a1, 11
li $a2, 1
li $a3, 5
jal draw_rect
li $a0, 18
li $a1, 11
li $a2, 1
li $a3, 5
jal draw_rect
#using loop to save some work
li $t3, 11
outer_issue:
beq $t3, 17, end_outer_issue
li $t2, 8
inner_issue:
beq $t2, 24, end_inner_issue
move $a0, $t2
move $a1, $t3
li $a2, 3
li $a3, 1
addi $t2, $t2, 4
jal draw_rect
j inner_issue
end_inner_issue:
addi $t3, $t3, 2
j outer_issue
end_outer_issue:
li $a0, 8
li $a1, 12
jal draw_pixel
li $a0, 10
li $a1, 14
jal draw_pixel
li $a0, 12
li $a1, 12
jal draw_pixel
li $a0, 14
li $a1, 14
jal draw_pixel
li $a0, 20
li $a1, 12
jal draw_pixel
li $a0, 20
li $a1, 14
jal draw_pixel
li $a0, 24
li $a1, 11
li $a2, 3
li $a3, 1
jal draw_rect
li $a0, 26
li $a1, 12
jal draw_pixel
li $a0, 25
li $a1, 13
jal draw_pixel
li $a0, 25
li $a1, 15
jal draw_pixel
li $a0, 17
li $a1, 11
jal draw_black_pixel
li $a0, 17
li $a1, 13
jal draw_black_pixel
j draw_endscreen_options

victory:
sb $zero, 0($s7)
li $a0, 0
li $a1, 0
li $a2, 32
li $a3, 32
sw $zero, CURR_COLOR
jal draw_rect
li $t0, 3
sb $t0, STATS
li $t0, 0xffc30e
sw $t0, CURR_COLOR
li $a0, 13
li $a1, 3
li $a2, 6
li $a3, 5
jal draw_rect
li $a0, 11
li $a1, 4
li $a2, 10
li $a3, 1
jal draw_rect
li $a0, 11
li $a1, 6
li $a2, 10
li $a3, 1
jal draw_rect
li $a0, 11
li $a1, 5
jal draw_pixel
li $a0, 20
li $a1, 5
jal draw_pixel
li $a0, 14
li $a1, 8
li $a2, 4
li $a3, 1
jal draw_rect
li $a0, 15
li $a1, 9
li $a2, 2
li $a3, 2
jal draw_rect
li $a0, 13
li $a1, 11
li $a2, 6
li $a3, 1
jal draw_rect
lw $t0, WHITE
sw $t0, CURR_COLOR
li $a0, 17
li $a1, 4
jal draw_pixel
li $a0, 17
li $a1, 5
jal draw_pixel
li $a0, 4
li $a1, 13
li $a2, 1
li $a3, 3
jal draw_rect
li $a0, 6
li $a1, 13
li $a2, 1
li $a3, 3
jal draw_rect
li $a0, 5
li $a1, 16
jal draw_pixel
li $a0, 8
li $a1, 13
li $a2, 1
li $a3, 4
jal draw_rect
li $a0, 10
li $a1, 13
li $a2, 1
li $a3, 4
jal draw_rect
li $a0, 11
li $a1, 16
jal draw_pixel
li $a0, 11
li $a1, 13
jal draw_pixel
li $a0, 14
li $a1, 13
li $a2, 1
li $a3, 4
jal draw_rect
li $a0, 13
li $a1, 13
jal draw_pixel
li $a0, 15
li $a1, 13
jal draw_pixel
li $a0, 17
li $a1, 13
li $a2, 1
li $a3, 4
jal draw_rect
li $a0, 19
li $a1, 13
li $a2, 1
li $a3, 4
jal draw_rect
li $a0, 18
li $a1, 13
jal draw_pixel
li $a0, 18
li $a1, 16
jal draw_pixel
li $a0, 21
li $a1, 13
li $a2, 1
li $a3, 4
jal draw_rect
li $a0, 22
li $a1, 13
jal draw_pixel
li $a0, 23
li $a1, 13
jal draw_pixel
li $a0, 23
li $a1, 14
jal draw_pixel
li $a0, 22
li $a1, 15
jal draw_pixel
li $a0, 23
li $a1, 16
jal draw_pixel
li $a0, 25
li $a1, 13
li $a2, 1
li $a3, 3
jal draw_rect
li $a0, 27
li $a1, 13
li $a2, 1
li $a3, 3
jal draw_rect
li $a0, 26
li $a1, 15
jal draw_pixel
li $a0, 26
li $a1, 16
jal draw_pixel
j draw_endscreen_options

end_screen:
lw $t8, 0($s6)
beq $t8, 1, endscreen_keyboard_input
j game_loop

endscreen_keyboard_input:
lw $a0, 4($s6)
beq $a0, 0x61, endscreen_left
beq $a0, 0x64, endscreen_right
beq $a0, 0x20, endscreen_space_bar
beq $a0, 0x71, exit
j game_loop

endscreen_left:
li $t1, 0
sb $t1, 3($s1)
j draw_endscreen_options

endscreen_right:
li $t1, 1
sb $t1, 3($s1)
j draw_endscreen_options

endscreen_space_bar:
li $a0, 0
li $a1, 0
li $a2, 32
li $a3, 32
sw $zero, CURR_COLOR
jal draw_rect
lb $t1, 3($s1)
li $t0, 0x01031e10
sw $t0, PADDLE
li $t0, 0xfe00001f
sw $t0, BALL
sh $zero, 2($s7)
beqz $t1, retry
li $t0, 1
sb $t0, STATS
j draw_menu

retry:
sb $zero, 0($s7)
j initialize_game

draw_endscreen_options:
li $t0, 0x666666
sw $t0, CURR_COLOR
lb $t0, 3($s1)
beq $t0, 1, draw_retry_button
lw $t0, WHITE
sw $t0, CURR_COLOR    
draw_retry_button:
li $a0, 5
li $a1, 20
li $a2, 9
li $a3, 1
jal draw_rect
li $a0, 5
li $a1, 20
li $a2, 1
li $a3, 9
jal draw_rect
li $a0, 5
li $a1, 28
li $a2, 9
li $a3, 1
jal draw_rect
li $a0, 13
li $a1, 20
li $a2, 1
li $a3, 9
jal draw_rect
li $a0, 7
li $a1, 23
li $a2, 5
li $a3, 1
jal draw_rect
li $a0, 8
li $a1, 26
li $a2, 4
li $a3, 1
jal draw_rect
li $a0, 8
li $a1, 22
li $a2, 1
li $a3, 3
jal draw_rect
li $a0, 11
li $a1, 24
li $a2, 1
li $a3, 2
jal draw_rect

li $t0, 0x666666
sw $t0, CURR_COLOR
lb $t0, 3($s1)
beqz $t0, draw_menu_button
lw $t0, WHITE
sw $t0, CURR_COLOR
draw_menu_button:
li $a0, 18
li $a1, 20
li $a2, 9
li $a3, 1
jal draw_rect
li $a0, 18
li $a1, 20
li $a2, 1
li $a3, 9
jal draw_rect
li $a0, 18
li $a1, 28
li $a2, 9
li $a3, 1
jal draw_rect
li $a0, 26
li $a1, 20
li $a2, 1
li $a3, 9
jal draw_rect
li $a0, 21
li $a1, 23
li $a2, 3
li $a3, 4
jal draw_rect
li $a0, 20
li $a1, 24
jal draw_pixel
li $a0, 24
li $a1, 24
jal draw_pixel
li $a0, 22
li $a1, 22
jal draw_pixel
li $a0, 22
li $a1, 25
jal draw_black_pixel
j game_loop

################################ FUNCTIONS ###################################
increase_score:
lh $t9, 2($s7)
addi $t9, $t9, 7
# Add random integer to the score to keep things interesting
li $v0 , 42
li $a0 , 0
li $a1 , 10
syscall
add $t9, $t9, $a0
sh $t9, 2($s7)
draw_score:
move $s5, $ra
sw $zero, CURR_COLOR
li $a0, 0
li $a1, 0
li $a2, 11
li $a3, 5
jal draw_rect
lh $t9, 2($s7)
li $t2, 0
draw_score_loop:
beq $t2, 3, end_draw_score
addi $t2, $t2, 1
li $t8, 10
div $t9, $t8
mflo $t9
mfhi $t8
sll $t3, $t2, 2
neg $t3, $t3
addi $t3, $t3, 12
lw $a0, WHITE
sw $a0, CURR_COLOR
beq $t8, 0, draw_0
beq $t8, 1, draw_1
beq $t8, 2, draw_2
beq $t8, 3, draw_3
beq $t8, 4, draw_4
beq $t8, 5, draw_5
beq $t8, 6, draw_6
beq $t8, 7, draw_7
beq $t8, 8, draw_8
beq $t8, 9, draw_9
# Shouldn't get here. Draws 0 anyway if something goes wrong with division
draw_0:
move $a0, $t3
li $a1, 0
li $a2, 1
li $a3, 5
jal draw_rect
addi $a0, $t3, 2
li $a1, 0
li $a2, 1
li $a3, 5
jal draw_rect
addi $a0, $t3, 1
li $a1, 0
jal draw_pixel
addi $a0, $t3, 1
li $a1, 4
jal draw_pixel
j draw_score_loop

draw_1:
addi $a0, $t3, 1
li $a1, 0
li $a2, 1
li $a3, 5
jal draw_rect
move $a0, $t3
li $a1, 1
jal draw_pixel
move $a0, $t3
li $a1, 4
jal draw_pixel
addi $a0, $t3, 2
li $a1, 4
jal draw_pixel
j draw_score_loop

draw_2:
move $a0, $t3
li $a1, 0
li $a2, 3
li $a3, 1
jal draw_rect
move $a0, $t3
li $a1, 2
li $a2, 3
li $a3, 1
jal draw_rect
move $a0, $t3
li $a1, 4
li $a2, 3
li $a3, 1
jal draw_rect
move $a0, $t3
li $a1, 3
jal draw_pixel
add $a0, $t3, 2
li $a1, 1
jal draw_pixel
j draw_score_loop

draw_3:
move $a0, $t3
li $a1, 0
li $a2, 3
li $a3, 1
jal draw_rect
move $a0, $t3
li $a1, 2
li $a2, 3
li $a3, 1
jal draw_rect
move $a0, $t3
li $a1, 4
li $a2, 3
li $a3, 1
jal draw_rect
add $a0, $t3, 2
li $a1, 3
jal draw_pixel
add $a0, $t3, 2
li $a1, 1
jal draw_pixel
j draw_score_loop

draw_4:
move $a0, $t3
li $a1, 0
li $a2, 1
li $a3, 3
jal draw_rect
addi $a0, $t3, 2
li $a1, 0
li $a2, 1
li $a3, 5
jal draw_rect
addi $a0, $t3, 1
li $a1, 2
jal draw_pixel
j draw_score_loop

draw_5:
move $a0, $t3
li $a1, 0
li $a2, 3
li $a3, 1
jal draw_rect
move $a0, $t3
li $a1, 2
li $a2, 3
li $a3, 1
jal draw_rect
move $a0, $t3
li $a1, 4
li $a2, 3
li $a3, 1
jal draw_rect
move $a0, $t3
li $a1, 1
jal draw_pixel
add $a0, $t3, 2
li $a1, 3
jal draw_pixel
j draw_score_loop

draw_6:
move $a0, $t3
li $a1, 0
li $a2, 3
li $a3, 1
jal draw_rect
move $a0, $t3
li $a1, 2
li $a2, 3
li $a3, 1
jal draw_rect
move $a0, $t3
li $a1, 4
li $a2, 3
li $a3, 1
jal draw_rect
move $a0, $t3
li $a1, 1
jal draw_pixel
move $a0, $t3
li $a1, 3
jal draw_pixel
add $a0, $t3, 2
li $a1, 3
jal draw_pixel
j draw_score_loop

draw_7:
move $a0, $t3
li $a1, 0
li $a2, 3
li $a3, 1
jal draw_rect
addi $a0, $t3, 2
li $a1, 1
li $a2, 1
li $a3, 4
jal draw_rect
j draw_score_loop

draw_8:
move $a0, $t3
li $a1, 0
li $a2, 1
li $a3, 5
jal draw_rect
addi $a0, $t3, 2
li $a1, 0
li $a2, 1
li $a3, 5
jal draw_rect
addi $a0, $t3, 1
li $a1, 0
jal draw_pixel
addi $a0, $t3, 1
li $a1, 2
jal draw_pixel
addi $a0, $t3, 1
li $a1, 4
jal draw_pixel
j draw_score_loop

draw_9:
move $a0, $t3
li $a1, 0
li $a2, 1
li $a3, 3
jal draw_rect
addi $a0, $t3, 2
li $a1, 0
li $a2, 1
li $a3, 5
jal draw_rect
addi $a0, $t3, 1
li $a1, 0
jal draw_pixel
addi $a0, $t3, 1
li $a1, 2
jal draw_pixel
j draw_score_loop

end_draw_score:
move $ra, $s5
jr $ra

draw_black_pixel: # sets color to black first
sw $zero, CURR_COLOR
draw_pixel:	  # draws a pixel at (a0, a1)
lw $t1, CURR_COLOR
sll $a1, $a1, 7
sll $a0, $a0, 2
add $a0, $a0, $a1
lw $a1, ADDR_DSPL
add $a0, $a0, $a1
sw $t1, 0($a0)
jr $ra

set_color: # set color based on a0 and a1. 
beq $a0, 1, set_red
beq $a0, 2, set_orange
beq $a0, 3, set_yellow
beq $a0, 4, set_green
beq $a0, 5, set_blue
beq $a0, 6, set_purple
beq $a0, 7, set_white

beq $a0, 8, set_d1
beq $a0, 9, set_d2
beq $a0, 10, set_d3
beq $a0, 11, set_d4
beq $a0, 12, set_d5

lw $t1, GREY
sw $t1, CURR_COLOR
jr $ra

set_red:
lw $t1, RED
j set_color_finish

set_orange:
lw $t1, ORANGE
j set_color_finish

set_yellow:
lw $t1, YELLOW
j set_color_finish

set_green:
lw $t1, GREEN
j set_color_finish

set_blue:
lw $t1, BLUE
j set_color_finish

set_purple:
lw $t1, PURPLE
j set_color_finish

set_white:
lw $t1, WHITE
j set_color_finish

set_d1:
lw $t1, DIAMOND1
j set_color_finish
set_d2:
lw $t1, DIAMOND2
j set_color_finish
set_d3:
lw $t1, DIAMOND3
j set_color_finish
set_d4:
lw $t1, DIAMOND4
j set_color_finish
set_d5:
lw $t1, DIAMOND5
j set_color_finish

set_color_finish:
mult $t1, $a1
mflo $t1
sw $t1, CURR_COLOR
jr $ra

draw_menu:
li $t2, 1
# Draw a triangular prism turning white ray into rainbow, because why not
rainbow_loop:
beq $t2, 7, end_rainbow_loop
move $a0, $t2
li $a1, 3
jal set_color
li $t3, 0
inner_rainbow_loop:
beq $t3, 4, end_inner_rainbow
addi $a1, $t2, 5
add $a1, $a1, $t3
sll $t3, $t3, 2
addi $a0, $t3, 17
li $a2, 4
li $a3, 1
jal draw_rect
sra $t3, $t3, 2
addi $t3, $t3, 1
j inner_rainbow_loop
end_inner_rainbow:
addi $t2, $t2, 1
j rainbow_loop
end_rainbow_loop:
sw $zero, CURR_COLOR
li $a0, 0
li $a1, 10
li $a2, 1
li $a3, 6
jal draw_rect
li $a0, 17
li $a1, 9
li $a2, 2
li $a3, 3
jal draw_rect

lw $t0, WHITE
sw $t0, CURR_COLOR
li $a0, 0
li $a1, 12
jal draw_pixel
li $t3, 0
draw_ray_loop:
beq $t3, 4, end_draw_ray_loop
li $a0, 3
mult $a0, $t3
mflo $a0
addi $a0, $a0, 1
li $a1, 11
sub $a1, $a1, $t3
li $a2, 3
li $a3, 1
jal draw_rect
addi $t3, $t3, 1
j draw_ray_loop
end_draw_ray_loop:

jal draw_rect
li $t0, 0xcccccc
sw $t0, CURR_COLOR
li $a0, 9
li $a1, 14
li $a2, 13
li $a3, 1
jal draw_rect

li $t3, 0
draw_sides_loop:
beq $t3, 6, end_draw_sides_loop
addi $a0, $t3, 15
sll $t3, $t3, 1
addi $a1, $t3, 2
li $a2, 1
li $a3, 3
jal draw_rect
sra $t3, $t3, 1
li $a0, 15
sub $a0, $a0, $t3
sll $t3, $t3, 1
addi $a1, $t3, 2
li $a2, 1
li $a3, 3
jal draw_rect
sra $t3, $t3, 1
addi $t3, $t3, 1
j draw_sides_loop
end_draw_sides_loop:

li $a0, 15
li $a1, 5
jal draw_pixel
li $a0, 15
li $a1, 2
jal draw_black_pixel
li $a0, 14
li $a1, 4
jal draw_black_pixel
li $a0, 16
li $a1, 4
jal draw_black_pixel

li $a0, 0x999999
sw $a0, CURR_COLOR
li $a0, 14
li $a1, 8
jal draw_pixel

li $a0, 0x666666
sw $a0, CURR_COLOR
li $a0, 15
li $a1, 8
jal draw_pixel
li $a0, 14
li $a1, 9
jal draw_pixel
li $a0, 14
li $a1, 7
jal draw_pixel

li $a0, 0x333333
sw $a0, CURR_COLOR
li $a0, 16
li $a1, 8
jal draw_pixel
li $a0, 15
li $a1, 9
jal draw_pixel
li $a0, 15
li $a1, 7
jal draw_pixel

# Level 1 Icon: Pyramid
li $a0, 6
li $a1, 3
jal set_color
li $a0, 3
li $a1, 23
li $a2, 6
li $a3, 4
jal draw_rect
lw $t0, DARK_BLUE
sw $t0, CURR_COLOR
li $a0, 5
li $a1, 26
li $a2, 3
li $a3, 3
jal draw_rect
li $a0, 6
li $a1, 25
jal draw_pixel
li $a0, 4
li $a1, 28
jal draw_pixel
li $a0, 8
li $a1, 27
jal draw_pixel
li $a0, 8
li $a1, 28
jal draw_pixel
li $a0, 5
li $a1, 25
jal draw_black_pixel
li $a0, 4
li $a1, 26
jal draw_black_pixel

# Level 2 Icon: Handshake
li $t0, 0x71bfde
sw $t0, CURR_COLOR
li $a0, 13
li $a1, 23
li $a2, 6
li $a3, 1
jal draw_rect
li $a0, 15
li $a1, 24
jal draw_pixel
li $a0, 15
li $a1, 25
jal draw_pixel
li $t0, 0xff8000
sw $t0, CURR_COLOR
li $a0, 17
li $a1, 24
jal draw_pixel
li $a0, 18
li $a1, 24
jal draw_pixel
li $a0, 18
li $a1, 26
jal draw_pixel
li $a0, 17
li $a1, 27
jal draw_pixel
li $t0, 0xe5aa7a
sw $t0, CURR_COLOR
li $a0, 18
li $a1, 25
jal draw_pixel
li $t0, 0x777777
sw $t0, CURR_COLOR
li $a0, 18
li $a1, 27
jal draw_pixel
li $a0, 18
li $a1, 28
jal draw_pixel
li $a0, 14
li $a1, 26
li $a2, 3
li $a3, 1
jal draw_rect
li $a0, 14
li $a1, 28
li $a2, 3
li $a3, 1
jal draw_rect

# Level 3 Icon: Megaphone
li $t0, 0x990030
sw $t0, CURR_COLOR
li $a0, 23
li $a1, 23
li $a2, 6
li $a3, 6
jal draw_rect
lw $t0, WHITE
sw $t0, CURR_COLOR
li $a0, 25
li $a1, 24
li $a2, 1
li $a3, 3
jal draw_rect
li $a0, 24
li $a1, 24
jal draw_pixel
li $a0, 24
li $a1, 26
jal draw_pixel
li $a0, 26
li $a1, 25
jal draw_pixel
li $t0, 0xed1c23
sw $t0, CURR_COLOR
li $a0, 24
li $a1, 25
jal draw_pixel
li $a0, 26
li $a1, 26
jal draw_pixel
li $a0, 26
li $a1, 27
jal draw_pixel
li $a0, 27
li $a1, 25
jal draw_pixel

draw_menu_options:
li $t7, 0
dmo_loop:
beq $t7, 3, end_dmo_loop
lb $t0, 1($s7)
lw $t1, GREY
sw $t1, CURR_COLOR
beq $t0, $t7, white_frame
j draw_frame
white_frame:
lw $t0, WHITE
sw $t0, CURR_COLOR
li $a0, 0
draw_frame:
# Draw the selector frame
li $t0, 10
mult $t7, $t0
mflo $t3
addi $t3, $t3, 2
move $a0, $t3
li $a1, 22
li $a2, 8
li $a3, 1
jal draw_rect
move $a0, $t3
li $a1, 29
li $a2, 8
li $a3, 1
jal draw_rect
move $a0, $t3
li $a1, 22
li $a2, 1
li $a3, 8
jal draw_rect
addi $t3, $t3, 7
move $a0, $t3
li $a1, 22
li $a2, 1
li $a3, 8
jal draw_rect
addi $t7, $t7, 1
j dmo_loop
end_dmo_loop:
j game_loop

########################################## THE MOST IMPORTANT FUNCTION ######################################

draw_rect: # arguments a0, a1 represent x, y coordinates. a2, a3 represent width and height.
lw $t1, CURR_COLOR

sll $a1, $a1, 7
sll $a0, $a0, 2
add $a0, $a0, $a1
lw $a1, ADDR_DSPL
add $a0, $a0, $a1
# a0 now stores starting pixel location (top left)

addi $a1, $zero, 4
mult $a1, $a2
mflo $a1
neg $a1, $a1
# a1 now stores negative width offset (to return the pixel location to beginning of a row)

# outer loop, iterates through height amount of rows
outer_rect:
beq $a3, $zero, end_draw_rect
move $t0, $a2
# inner loop, iterates through width amount of pixels
inner_rect:
beq $t0, $zero, end_inner_rect
sw $t1, 0($a0)
addi $a0, $a0, 4 # Go to next pixel
addi $t0, $t0, -1
j inner_rect
end_inner_rect:
# inner loop finished

add $a0, $a0, $a1 # Go back to first pixel of this row
addi $a0, $a0, 128 # Go to same pixel on next row
addi $a3, $a3, -1
j outer_rect

end_draw_rect:
jr $ra

exit:
li $v0, 10  # terminate the program gracefully~
syscall

# (c) 2003 , Bad Computer Ltd.
# Unauthorized use may cause your computer to explode.