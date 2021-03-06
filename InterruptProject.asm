.data
bufferExp: .space 30
bufferExpLen: .word 0
asciiZero: .byte '0'

.text #MAIN PROGRAM START

#Turn on the transmitter control ready bit
lui $t0, 0xFFFF
lw $t1, 8($t0)
ori $t1, $t1, 0x0001
sw $t1, 8($t0)

#Turn on the receiver control interrupt-enable bit
lui $t0, 0xFFFF
lw $t1, 0($t0)
ori $t1, $t1, 0x0002
sw $t1, 0($t0)

main: #MAIN - Begin

mainLoop:
lw $t5, bufferExpLen
addi $s0, $s0, 1
addi $s0, $s0, -1
beq $t5, 4, Terminate
j mainLoop
#MAIN -End

#MAIN PROGRAM END
Terminate:
li $v0, 10
syscall

################################################################# HANDLER Main - Begin
myHandler:
#save to stack
sw $ra, 0($sp)
addi $sp, $sp, -4
sw $t0, 0($sp)
addi $sp, $sp, -4
sw $t1, 0($sp)
addi $sp, $sp, -4

#store char in buffer
jal StoreChar

#add 1 to the buffer length
lw $t0, bufferExpLen
addi $t0, $t0, 1
sw $t0, bufferExpLen


#send every character in the buffer to the display by polling the buffer
jal SendToDisplay #If bufferExpLen == 4, we will skip printing because evaluate will print the integer value

bne $t0, 4, Branch1
jal Evaluate
Branch1:

#recover stack
addi $sp, $sp, 4
lw $t1, 0($sp)
addi $sp, $sp, 4
lw $t0, 0($sp)
addi $sp, $sp, 4
lw $ra, 0($sp)

jr $ra

################################################################# Handler Main - End
################################################################# Handler functions - Begin

StoreChar:
#save to stack
sw $ra, 0($sp)
addi $sp, $sp, -4
sw $t5, 0($sp)
addi $sp, $sp, -4
sw $t3, 0($sp)
addi $sp, $sp, -4
lw $t3, 0xFFFF0004 #word to be loaded in $t3
la $t5, bufferExp

sw $t3, 0($t5)

addi $t5, $t5, 4

#recover stack
addi $sp, $sp, 4
lw $t3, 0($sp)
addi $sp, $sp, 4
lw $t5, 0($sp)
addi $sp, $sp, 4
lw $ra, 0($sp)

jr $ra

Evaluate:
#save to stack
sw $ra, 0($sp)
addi $sp, $sp, -4
sw $t0, 0($sp)
addi $sp, $sp, -4
sw $t1, 0($sp)
addi $sp, $sp, -4
sw $t2, 0($sp)
addi $sp, $sp, -4
sw $t3, 0($sp)
addi $sp, $sp, -4

la $t1, bufferExp
lw $t0, 4($t1) # loads first acii value
lw $t2, 8($t1)

addi $t0, $t0, -48 #contains integer value of first number
addi $t2, $t2, -48 #contains integer value of second number

add $t3, $t0, $t2
add $t3, $t3, 48

sw $t3, 0xFFFF000c


#recover stack
addi $sp, $sp, 4
lw $t3, 0($sp)
addi $sp, $sp, 4
lw $t2, 0($sp)
addi $sp, $sp, 4
lw $t1, 0($sp)
addi $sp, $sp, 4
lw $t0, 0($sp)
addi $sp, $sp, 4
lw $ra, 0($sp)

jr $ra

SendToDisplay:
#save to stack
sw $ra, 0($sp)
addi $sp, $sp, -4
sw $t0, 0($sp)
addi $sp, $sp, -4
sw $t1, 0($sp)
addi $sp, $sp, -4

la $t0, bufferExp
addi $t0, $t0, -4
lw $t1, bufferExp
#send this to transmitter
sw $t1, 0xFFFF000c

addi $t0, $t0, 4

#recover stack
addi $sp, $sp, 4
lw $t1, 0($sp)
addi $sp, $sp, 4
lw $t0, 0($sp)
addi $sp, $sp, 4
lw $ra, 0($sp)

jr $ra

################################################################# HANDLER FUNCTIONS - End

################################################################# KERNEL CODE - Begin
.kdata
_k_save_s0: .word 0
_k_save_ra: .word 0
_k_save_t0: .word 0
_k_save_t1: .word 0
_k_save_t5: .word 0

.ktext 0x80000180 #INTERRUPT MAIN START
#save all program data registers into k registers
#t1 t0 t5
sw $t0, _k_save_t0
sw $t1, _k_save_t1
sw $t5, _k_save_t5
sw $s0, _k_save_s0
sw $ra, _k_save_ra
#Check the cause, ensure keyboard input caused exception
#mfc0 $t0, $13
#andi $t1, $t0, 0x007c
#bnez $t1, APPLE

#andi $t1, $t0, 0x0100
#beqz $t1, APPLE
#If cause is keyboard, Jump to Interrupt Handler
la $k0, myHandler
jalr $k0

APPLE: 
#Returned back from handler, or interrupt cause was not keyboard
#Clear cause register and reset ready bit on status register
mtc0 $zero, $13
mfc0 $t0, $12
andi $t0, 0x111D
ori $t0, 0x0001
mtc0 $t0, $12

#recover all program data registers
lw $t0, _k_save_t0
lw $t1, _k_save_t1
lw $t5, _k_save_t5
lw $s0, _k_save_s0
lw $ra, _k_save_ra 
eret
#INTERRUPT HANDLER END
################################################################## KERNEL CODE - End
