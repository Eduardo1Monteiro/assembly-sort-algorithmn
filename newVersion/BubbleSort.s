.equ uartBasicAddress, 0x10000000

.bss
    array: .space 4000

.text
.global main

main:
    addi sp, sp, -16
    sw ra, 12(sp)

    la s4, array
    jal ra, readIntegers

    mv s6, a0

    mv a0, s4
    mv a1, s6
    jal ra, bubbleSort

    la a0, array
    mv a1, s6
    jal ra, printArray

    lw ra, 12(sp)
    addi sp, sp, 16
    ret

readIntegers:
    addi sp, sp, -32
    sw ra, 28(sp)
    sw s2, 24(sp)
    sw s3, 20(sp)
    sw s4, 16(sp)
    sw s5, 12(sp)
    sw s6, 8(sp)
    sw s7, 4(sp)

    li s2, 0
countLoop:
    jal ra, readCharUART
    mv t0, a0
    li t2, ' '
    beq t0, t2, countDone
    li t2, '\n'
    beq t0, t2, countDone
    addi t0, t0, -48
    li t1, 10
    mul s2, s2, t1
    add s2, s2, t0
    j countLoop

countDone:
    mv s6, s2

    li s7, 0
mainLoopStart:
    blt s7, s6, loopToRead
    j endReadIntegers

loopToRead:
    li s2, 0
    li s3, 0
    li s5, 0
readCharLoop:
    jal ra, readCharUART
    mv t0, a0
    li t5, -1
    beq t0, t5, handleSeparator
    li t2, ' '
    beq t0, t2, handleSeparator
    li t2, '\n'
    beq t0, t2, handleSeparator
    li t2, '-'
    beq t0, t2, handleNegative
conversor:
    li s5, 1
    addi t0, t0, -48
    li t1, 10
    mul s2, s2, t1
    add s2, s2, t0
    j readCharLoop
handleSeparator:
    beqz s5, readCharLoop
    beqz s3, saveNumber
    neg s2, s2
saveNumber:
    sw s2, 0(s4)
    addi s4, s4, 4
    addi s7, s7, 1
    j mainLoopStart
handleNegative:
    li s5, 1
    li s3, 1
    j readCharLoop

endReadIntegers:
    mv a0, s6

    lw ra, 28(sp)
    lw s2, 24(sp)
    lw s3, 20(sp)
    lw s4, 16(sp)
    lw s5, 12(sp)
    lw s6, 8(sp)
    lw s7, 4(sp)
    addi sp, sp, 32
    ret

bubbleSort:
    addi sp, sp, -28
    sw ra, 24(sp)
    sw s0, 20(sp)
    sw s1, 16(sp)
    sw s2, 12(sp)
    sw s3, 8(sp)
    sw s4, 4(sp)

    mv s0, a0
    mv s1, a1

    li s2, 0
outerLoopStart:
    addi t0, s1, -1
    bge s2, t0, outerLoopEnd

    li s4, 0

    li s3, 0
innerLoopStart:
    sub t0, s1, s2
    addi t0, t0, -1
    bge s3, t0, innerLoopEnd

    slli t1, s3, 2
    add t2, s0, t1

    lw t3, 0(t2)
    lw t4, 4(t2)

    ble t3, t4, noSwap
    sw t4, 0(t2)
    sw t3, 4(t2)
    li s4, 1

noSwap:
    addi s3, s3, 1
    j innerLoopStart

innerLoopEnd:
    beqz s4, outerLoopEnd
    addi s2, s2, 1
    j outerLoopStart

outerLoopEnd:
    lw ra, 24(sp)
    lw s0, 20(sp)
    lw s1, 16(sp)
    lw s2, 12(sp)
    lw s3, 8(sp)
    lw s4, 4(sp)
    addi sp, sp, 28
    ret

printArray:
    addi sp, sp, -20
    sw ra, 16(sp)
    sw s0, 12(sp)
    sw s1, 8(sp)
    sw s2, 4(sp)

    mv s1, a0
    mv s2, a1
    li s0, 0

printArrayLoop:
    bge s0, s2, endPrintArray

    lw a0, 0(s1)
    jal ra, printInteger

    addi t0, s2, -1
    blt s0, t0, printComma
    j afterComma

printComma:
    li a0, ','
    jal ra, uartWriteChar

afterComma:
    addi s1, s1, 4
    addi s0, s0, 1
    j printArrayLoop

endPrintArray:
    lw ra, 16(sp)
    lw s0, 12(sp)
    lw s1, 8(sp)
    lw s2, 4(sp)
    addi sp, sp, 20
    ret

printInteger:
    addi sp, sp, -48
    sw ra, 44(sp)
    sw s0, 40(sp)
    sw s1, 36(sp)

    mv s0, a0
    li s1, 0

    bne s0, zero, notZero
    li a0, '0'
    jal ra, uartWriteChar
    j endPrintInteger

notZero:
    li t3, 0
    bge s0, zero, isPositive
    li a0, '-'
    jal ra, uartWriteChar
    neg s0, s0

isPositive:
    li t0, 10
convertLoop:
    beqz s0, endConvertLoop
    div t1, s0, t0
    rem t2, s0, t0
    addi t2, t2, '0'
    addi sp, sp, -4
    sw t2, 0(sp)
    addi s1, s1, 1
    mv s0, t1
    j convertLoop

endConvertLoop:
printDigitsLoop:
    beqz s1, endPrintInteger
    lw a0, 0(sp)
    addi sp, sp, 4
    jal ra, uartWriteChar
    addi s1, s1, -1
    j printDigitsLoop

endPrintInteger:
    lw ra, 44(sp)
    lw s0, 40(sp)
    lw s1, 36(sp)
    addi sp, sp, 48
    ret

readCharUART:
    li t1, uartBasicAddress
    li t2, uartBasicAddress + 5
    li t3, 0b1
pollLoopUart:
    lb t4, 0(t2)
    and t4, t4, t3
    beqz t4, pollLoopUart
    lb a0, 0(t1)
    ret

uartWriteChar:
    li t1, uartBasicAddress + 5
writePoll:
    lbu t0, 0(t1)
    andi t0, t0, 0x20
    beq t0, zero, writePoll
    li t0, uartBasicAddress
    sb a0, 0(t0)
    ret
