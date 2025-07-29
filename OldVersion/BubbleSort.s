.section .data
	separator: .byte 44, 1

.section .bss
	.comm inputFile, 4, 4
	.comm outputFile, 4, 4
	.comm arrayLength, 4, 4
	.comm array, 4000, 4
	.comm readBuffer, 1, 1
	.comm writeBuffer, 12, 1

# Read Logic
readIntegers:
	push %ecx                   # <<< CORREÇÃO: Salva o %ecx
	xorl %eax, %eax
	movl $1, %esi
	movl $0, %edx

skipWhiteSpace:
	movl $3, %eax
	movl inputFile, %ebx
	movl $readBuffer, %ecx
	movl $1, %edx
	int $0x80

	cmpl $0, %eax
	je .finished

	movb readBuffer, %cl

	cmpb $' ', %cl
	je skipWhiteSpace
	cmpb $10, %cl
	je skipWhiteSpace
	cmpb $9, %cl
	je skipWhiteSpace

	cmpb $'-', %cl
	jne .startConversion
	movl $-1, %esi
	jmp skipWhiteSpace

.startConversion:
	movl $1, %edx

.conversion:
	cmpb $'0', %cl
	jl .applySign
	cmpb $'9', %cl
	jg .applySign

	subb $'0', %cl
	movzbl %cl, %ecx
	imull $10, %eax
	addl %ecx, %eax

	movl $3, %eax
	movl inputFile, %ebx
	movl $readBuffer, %ecx
	movl $1, %edx
	int $0x80
	cmpl $0, %eax
	je .applySign
	movb readBuffer, %cl
	jmp .conversion

.applySign:
	imull %esi, %eax

.finished:
	pop %ecx                    # <<< CORREÇÃO: Restaura o %ecx
	ret

# Bubble Sort
bubbleSort:
	movl arrayLength, %ecx
	decl %ecx

.arrayIterationLoop:
	push %ecx
	movl $array, %edi

.sortLoop:
	movl (%edi), %eax
	movl 4(%edi), %ebx

	cmpl %ebx, %eax
	jle .noChange

	movl %ebx, (%edi)
	movl %eax, 4(%edi)

.noChange:
	addl $4, %edi
	decl %ecx
	jnz .sortLoop
	pop %ecx
	loop .arrayIterationLoop
	ret

# Write Logic
writeIntegers:
	push %ecx                   # <<< CORREÇÃO: Salva o %ecx
	movl $writeBuffer + 10, %edi
	testl %eax, %eax
	jns .setupDivisor
	negl %eax
	push %eax
	movl $4, %eax
	movl outputFile, %ebx
	movb $'-', (%edi)
	movl %edi, %ecx
	movl $1, %edx
	int $0x80
	pop %eax
	movl $10, %ebx

.setupDivisor:
	movl $10, %ebx

.convertLoop:
	xorl %edx, %edx
	divl %ebx
	addb $'0', %dl
	decl %edi
	movb %dl, (%edi)
	testl %eax, %eax
	jnz .convertLoop

	movl %edi, %ecx
	movl $writeBuffer + 11, %edx
	subl %ecx, %edx
	movl $4, %eax
	movl outputFile, %ebx
	int $0x80
	pop %ecx                    # <<< CORREÇÃO: Restaura o %ecx
	ret

# Error Handling
exitError:
	movl $1, %eax
	movl $1, %ebx
	int $0x80

.section .text
	.globl _start

_start:
	# movl (%esp), %eax # This check is for argc
	# cmpl $3, %eax
	# error handler

	# opens the input file
	movl $5, %eax
	movl 8(%esp), %ebx
	xorl %ecx, %ecx
	xorl %edx, %edx
	int $0x80
	cmpl $0, %eax
	jl exitError
	movl %eax, inputFile

	# opens the output file
	movl $5, %eax
	movl 12(%esp), %ebx
	movl $65, %ecx
	movl $0644, %edx
	int $0x80
	cmpl $0, %eax
	jl exitError
	movl %eax, outputFile

	xorl %ecx, %ecx

readLoop:
	call readIntegers
	cmpl $1, %edx
	jne .endReadLoop

	movl %eax, array(,%ecx,4)
	incl %ecx
	jmp readLoop

.endReadLoop:
	movl %ecx, arrayLength

# Sorting
	call bubbleSort

# Setup the writing logic
	movl arrayLength, %ecx
	movl $array, %esi

writeToOutputFile:
	push %ecx
	movl (%esi), %eax
	call writeIntegers
	addl $4, %esi
	pop %ecx
	loop .checkSeparator
	jmp .closeFiles

.checkSeparator:
	cmpl $1, %ecx
	je writeToOutputFile
	movl $4, %eax
	movl outputFile, %ebx
	movl $separator, %ecx
	movl $1, %edx
	int $0x80
	jmp writeToOutputFile

.closeFiles:
	# close input file
	movl $6, %eax
	movl inputFile, %ebx
	int $0x80

	# close output file
	movl $6, %eax
	movl outputFile, %ebx
	int $0x80

exitSuccess:
	movl $1, %eax
	movl $0, %ebx
	int $0x80
