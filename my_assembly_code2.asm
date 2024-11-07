# Author: Gal Levi	Date:17.08.23
# Description: The program receives from the user a formatted string which 
#              represents pairs of octal numbers and then prints it in the same order
#              they got in and right after prints it in a sorted order
# Input: Pairs of ocatal numbers seperated by '$' character
# Output: The pairs in decimal base in the same order they has been received and in sorted order
################# Data segment #####################

.data
# memory allocations
stringocta:	.space 31
NUM:	.space 10
sortarray:	.space 10

# strings
msg1:	.asciiz "\nPlease enter a string in the right format:\n"
spaces:	.asciiz "  "
msg2:	.asciiz "\nThe numbers you have entered in decimal base:\n"
msg3:	.asciiz "\nThe numbers in sorted order:\n"
errormsg:	.asciiz "\nWrong input\n"

################# Code segment #####################

.text
.globl main
main: # main program entry

li $s0, 0xa # $s0 = '\n' character (global)
li $s1, 0x24 # $s1 = '$' character (global)
li $s2, 8 # $s2 = 8 (global)

ProgLoop:
######################################
# reads a string from the user
######################################
	li $v0, 4
	la $a0, msg1 # msg1 = "\nPlease enter a string in the right format:\n"
	syscall
	
	la $a0, stringocta # the target string
	li $a1, 31
	li $v0, 8
	syscall
######################################

###########################################
# first phase
# calls is_valid procedure on stringocta
###########################################
	
# $a0 is the argument of is_valid and already points to the string
	jal is_valid
	bne $v0, 0, SecondPhase # if there is not an error goes to the next phase
	# there is an error - prints the error and restarts the program
	li $v0, 4
	la $a0, errormsg # errormsg = "\nWrong input\n"
	syscall
	j ProgLoop
###########################################


######################################################
# second phase
# calls convert procedure on stringocta and NUM arrays
######################################################

SecondPhase:
# $a0 still points to stringocta
	move $s3, $v0 # stores the counter in $s3
	la $a1, NUM
	move $a2, $s3
	jal convert
	
######################################################

######################################################
# third phase
# prints the numbers in NUM array in decimal base
######################################################
	
	# prints the headline
	la $a0, msg2 # msg2 = "\nThe numbers you have entered in decimal base:\n"
	li $v0, 4
	syscall
	
	la $a0, NUM
	move $a1, $s3
	jal print
	
######################################################



#############################################################
# fourth phase
# sorts NUM array (the sorted output will be in sortedarray)
#############################################################

	la $a0, sortarray
	la $a1, NUM
	move $a2, $s3
	jal sort
	
	
#############################################################


#############################################################
# fifth phase
# prints the sorted array
#############################################################
	
	# prints the headline
	la $a0, msg3 # msg3 = "\nThe numbers in sorted order:\n"
	li $v0, 4
	syscall
	
	la $a0, sortarray
	move $a1, $s3
	jal print
	
#############################################################


# end of program
exit:	
	li $v0, 10
	syscall
	

############################################################################
# is_valid procedure
# Checks if the input string is valid in accordance to assignment demands
# arguments: $a0 - Pointer to stringocta
# returns: If valid - the number of the octal numbers pairs, otherwise 0
############################################################################
is_valid:
	li $v0, 0 # pairs counter
	li $t0, 0 # octal numbers counter
	li $t1, 0 # '$' character counter
	move $t2, $a0 # $t2 = $a0 (pointer to the argument string)
	
	# checks if the first chearcter is '$', null, new line
	lb $t3, 0($t2) # $t3 is the first char of the string
	beq $t3, $s1, error # if the first char is '$'
	beq $t3, $zero, error # if the first char is null
	beq $t3, $s0, error # if first char is new line
	
CheckStringLoop:

first: # checks if current character is 0-7
	sge $t4, $t3, 0x30
	sle $t5, $t3, 0x37
	and $t5, $t4, $t5 # if $t4 = 1 && $t5 = 1 (if '0' <= $t3 <= '7')
	bne $t5, 1, second # else - goes to the second check
	# current char is 0-7
	li $t1, 0 # resets '$' counter
	addi $t0, $t0, 1 # numbers counter++
	blt $t0, 2, NextIter # if counter is less than 2
	bgt $t0, 2, error # if there is 3 numbers in a row is an error
	# else - if we got here the counter is 2
	addi $v0, $v0, 1 # pairs counter++
	j NextIter
	

second: # checks if current character is '$'
	bne $t3, $s1, third # if the char is not '$'
	beq $t1, 1, error # if the last character was '$' too
	blt $t0, 2, error # if it is not an octal pair before '$' is an error
	li $t0, 0 # resets numbers counter
	addi $t1, $t1, 1
	j NextIter
	
third:
	bne $t1, 1, error # if '$' is not the last character
	beq $t3, $zero, return # if current char is null
	beq $t3, $s0, return # if current char is new line
	
NextIter:
	addi $t2, $t2, 1 # pointer increment
	lb $t3, 0($t2) # $t3 = current char
	j CheckStringLoop

error: # if found an error
	li $v0, 0
return:	
	jr $ra # returns to caller

############################################################################




############################################################################
# convert procedure
# Converts the valid octal pairs into bits and assigns them in NUM array
# arguments: $a0 - Pointer to stringocta, $a1 - Pointer to NUM array
# arguments: $a2 - Pairs counter
# returns: void
############################################################################

convert:
	# stores the arguments in temporary registers
	move $t0, $a0 # stringocta
	move $t1, $a1 # NUM
	move $t2, $a2 # pairs counter
	
ConvertLoop:
	lb $t3, 0($t0) # current char
	sub $t4, $t3, 0x30 # $t4 = the digit in decimal base (tens digit)
	multu $t4, $s2 # multiplication by 8
	mflo $t4 # the result is always between 0-63 (last 6 bits)
	lb $t3, 1($t0) # next char
	sub $t5, $t3, 0x30 # next digit (unity digit)
	add $t4, $t4, $t5 # $t4 is now the number in 10 base
	sb $t4, 0($t1)
	addi $t1, $t1, 1 # NUM pointer increment
	addi $t0, $t0, 3 # stringocta pointer increment (skips '$')
	addi $t2, $t2, -1 # pairs counter decrement
	bgtz $t2, ConvertLoop # if the counter > 0, goes to the next iteration
	
	
	jr $ra # returns to caller


############################################################################


############################################################################
# print procedure
# Prints the numbers of the array in 10 base
# arguments: $a0 - Pointer to numbers array, $a1 - numbers counter
# returns: void
############################################################################

print:
	# stores the arguments in temporary registers
	move $t0, $a0 # number array pointer
	move $t1, $a1 # numbers counter

PrintLoop:
	# prints the number
	lbu $a0, 0($t0) # $a0 = the number to print
	li $v0, 1
	syscall
	# prints the spaces after the number
	la $a0, spaces
	li $v0, 4
	syscall
	
	addi $t0, $t0, 1 # increases numbers array pointer
	addi $t1, $t1, -1 # decreases counter
	bgtz $t1, PrintLoop
	
	jr $ra # returns to caller


############################################################################



############################################################################
# sort procedure
# Sorts the numbers of the second argument and stores them in the first argument.
# arguments: $a0 - Pointer to sortarray, $a1 - Pointer to NUM array
# arguments: $a2 - array size(not capacity)
# returns: void
############################################################################

sort:
	# stores the arguments in temporary registers
	move $t0, $a0 # sortarray pointer
	move $t1, $a1 # NUM pointer
	move $t2, $a2 # array size(numbers counter)

	# copies NUM array to sortarray array
	li $t3, 0 # initializes loop index to 0
CopyLoop:
	beq $t3, $t2, ToTheSort   # if index = array size, moves to sorting
	lb $t4, 0($t1) # loads number into $t4 from NUM array
	sb $t4, 0($t0) # stores current number in sortarray array
	addi $t1, $t1, 1 # moves to next index of NUM array
	addi $t0, $t0, 1 # moves to next index of sortarray array
	addi $t3, $t3, 1 # increases loop index
	j CopyLoop
	
# the sort begins here
ToTheSort:
	li $t3, 0 # resets external loop index to 0
	move $t0, $a0 # resets sortarray pointer
	
ExtSortLoop:# external loop
	beq $t3, $a2, done # if index = array size, exits loop
	
	li $t4, 1 # initializes internal loop index to 1
	
IntSortLoop: # internal loop
	
	beq $t4, $t2, NextExtItr # if internal index = current array size, moves to next external loop iteration
	
	lbu $t5, 0($t0) # loads the current number
    	lbu $t6, 1($t0) # loads the next number
    	
	bge $t6, $t5, NoSwap # if next number >= current number, no swap needed
	
	# swaps current number and next number
	sb $t6, 0($t0)        
	sb $t5, 1($t0) 
	
NoSwap:
	addi $t0, $t0, 1 # moves to the next number
	addi $t4, $t4, 1 # increases internal loop index
	j IntSortLoop
	
	
NextExtItr:
	addi $t2, $t2, -1 # decreases array size for each iteration
	addi $t3, $t3, 1 # increases external loop index
	move $t0, $a0 # resets sortarray array pointer to the beginning
	j ExtSortLoop

done:
	jr $ra # returns to caller


############################################################################
