# Author: Gal Levi	Date:16.08.23
# Description: Prints the input string in staggered format
# Input: String to be printed
# Output: The string in staggered manner
################# Data segment #####################

.data
# memory allocation
input:	.space 32

# strings
msg1:	.asciiz "please enter a string:\n"
msg2:	.asciiz "\nthe output is:\n"

################# Code segment #####################

.text
.globl main
main: # main program entry

li $t3, 0xa # $t3 = '\n' character (used later)

######################################
# first phase
# reads a string from the user
######################################
	li $v0, 4
	la $a0, msg1 # msg1 = "please enter a string\n"
	syscall
	
	la $a0, input
	li $a1, 31
	li $v0, 8
	syscall
######################################


######################################
# second phase
# counts the entered characters
######################################
	li $t0, 0 # characters counter
	la $t2, input # $t2 = input
	lb $t1, 0($t2) # $t1 = input[0]
CountLoop: # counter loop - stops if new line or null characters detected
	beq $t1, 0xa, print # if $t1 = '\n' jumps to print
	addi $t0, $t0, 1 # $t0++
	addi $t2, $t2, 1 # $t2++ (increases pointer)
	lb $t1, 0($t2)
	bnez $t1, CountLoop
######################################
	


# if entered exactly 30 characters (if null detected in CountLoop)
# inserts new line after the last character in the string
	sb $t3, 30($a0)


#######################################
# third phase
# prints the string in staggered manner
#######################################
print:
	li $v0, 4
	la $a0, msg2
	syscall # prints "the output is:"
	la $a0, input
PrintLoop:
	lb $t1, 0($a0) # $t1 = input[0]
	beq $t1, $t3, exit # if $a0 = '\n'(the whole input) jumps to exit
	syscall # prints the current string
	add $t2, $a0, $t0 # $t2 points to the current input[$t0]
	sb $zero, 0($t2)
	addi $t2, $t2, -1 # $t2-- (decreases pointer)
	sb $t3, 0($t2)
	addi $t0, $t0, -1 # character counter--
	j PrintLoop
#######################################
	

# end of program
exit:	
	li $v0, 10
	syscall
	
	
	
