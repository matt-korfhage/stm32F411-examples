# ###################################
# Name: Matthew Korfhage
# Number to ASCII subroutine
# 10/5/2022
# ###################################

.global num_to_ASCII

  .syntax unified
  .cpu cortex-m4
  .thumb

  num_to_ASCII:
  # Num to ASCII using double dabble algorithm
  	PUSH {R1, R2, R5, R8, R12, LR}
  	MOVW R5, #0x0000
  	MOVT R5, #0x8000
  	MOV R8, #0
  	MOV R12, #0
  1:
  	ADD R8, #1
  	# Analyze ones place
  	MOV R2, #0
  	AND R2, R12, #0xF
  	# If greater than 5, add three to output in ones
  	CMP R2, #5
  	BLT 2f
  	ADD R12, #0x3
  2:
  	# Analyze tens place
  	MOV R2, #0
  	AND R2, R12, #0xF0
  	LSR R2, #4
  	# If greater than 5, add three to output in tens
  	CMP R2, #5
  	BLT 3f
  	ADD R12, #0x30
  3:
  	# Analyze hundreds place
  	MOV R2, #0
  	AND R2, R12, #0xF00
  	# If greater than 5, add three to output in hundreds
  	LSR R2, #8
  	CMP R2, #5
  	BLT 4f
  	ADD R12, 0x300
  4:
  	# Analyze thousands place
  	MOV R2, #0
  	AND R2, R12, #0xF000
  	# If greater than 5, add three to output in thousands
  	LSR R2, #12
  	CMP R2, #5
  	BLT 5f
  	ADD R12, 0x3000
  5:
  	MOV R2, #0
  	# If R0 is 0 then stop

  	# Get most significant bit in R0
  	AND R2, R0, R5
  	CMP R2, #0
  	BEQ 6f
  	MOVW R2, #1
  	MOVT R2, #0
  6:
  	# Shift R0 left one place
  	LSL R0, #1
  	# Shift scratch one place
  	LSL R12, #1
  	# Add most significant bit to scratch
  	ADD R12, R2
  	CMP R8, #32
  	BEQ 8f
  	# Go back to beginning
  7:
  	BAL 1b
  8:
  # Regular coded decimal to ASCII conversion (adding 30 & expanding number left)
  	MOV R1, #0
  	AND R1, R12, #0xF
  	ADD R0, R1, 0x30
  	MOV R1, #0
  	AND R1, R12, #0xF0
  	LSL R1, #4
  	ADD R1, #0x3000
  	ADD R0, R1
  	MOV R1, #0
  	AND R1, R12, #0xF00
  	LSL R1, #8
  	ADD R1, #0x300000
  	ADD R0, R1
  	MOV R1, #0
  	AND R1, R12, #0xF000
  	LSL R1, #12
  	ADD R1, #0x30000000
  	ADD R0, R1
  	POP {R1, R2, R5, R8, R12, PC}
