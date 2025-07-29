.equ uartBasicAddress, 0x10000000

.bss
    array: .space 4000

.text
.global main

# =================================================================
# ROTINA PRINCIPAL
# =================================================================
main:
    addi sp, sp, -16
    sw   ra, 12(sp)

    # Prepara para ler os inteiros. s4 e s6 serão preenchidos em readIntegers.
    la s4, array
    jal ra, readIntegers

    mv s6, a0

    la   a0, array
    mv   a1, s6          # s6 foi definido em readIntegers
    jal  ra, printArray

    lw   ra, 12(sp)
    addi sp, sp, 16
    ret

# =================================================================
# LÓGICA DE LEITURA
# =================================================================
readIntegers:
    # --- Prólogo ---
    addi sp, sp, -32
    sw   ra, 28(sp)
    sw   s2, 24(sp)
    sw   s3, 20(sp)
    sw   s4, 16(sp)
    sw   s5, 12(sp)
    sw   s6, 8(sp)
    sw   s7, 4(sp)

    # --- FASE 1: LER N ---
    li s2, 0
.count_loop:
    jal ra, readCharUART
    mv t0, a0
    li t2, ' '
    beq t0, t2, .count_done
    li t2, '\n'
    beq t0, t2, .count_done
    addi t0, t0, -48
    li t1, 10
    mul s2, s2, t1
    add s2, s2, t0
    j .count_loop

.count_done:
    mv s6, s2 # Salva N em s6

    # --- FASE 2: LER OS N NÚMEROS ---
    li s7, 0 # i = 0
.main_loop_start:
    blt s7, s6, .loopToRead
    j .endReadIntegers

.loopToRead:
    li s2, 0
    li s3, 0
    li s5, 0
.read_char_loop:
    jal ra, readCharUART
    mv t0, a0
    li t5, -1
    beq t0, t5, .handle_separator
    li t2, ' '
    beq t0, t2, .handle_separator
    li t2, '\n'
    beq t0, t2, .handle_separator
    li t2, '-'
    beq t0, t2, .handle_negative
.conversor:
    li s5, 1
    addi t0, t0, -48
    li t1, 10
    mul s2, s2, t1
    add s2, s2, t0
    j .read_char_loop
.handle_separator:
    beqz s5, .read_char_loop
    beqz s3, .saveNumber
    neg s2, s2
.saveNumber:
    sw s2, 0(s4)
    addi s4, s4, 4
    addi s7, s7, 1
    j .main_loop_start
.handle_negative:
    li s5, 1
    li s3, 1
    j .read_char_loop

.endReadIntegers:
    mv a0, s6

    # --- Epílogo ---
    lw   ra, 28(sp)
    lw   s2, 24(sp)
    lw   s3, 20(sp)
    lw   s4, 16(sp)
    lw   s5, 12(sp)
    lw   s6, 8(sp)
    lw   s7, 4(sp)
    addi sp, sp, 32
    ret

# =================================================================
# SUB-ROTINAS DE IMPRESSÃO
# =================================================================

# printArray: Imprime N inteiros de um array no formato "n1,n2,n3..."
# Argumentos:
#   a0: endereço do início do array
#   a1: número de elementos a imprimir (N)
printArray:
    # Prólogo
    addi sp, sp, -20
    sw ra, 16(sp)
    sw s0, 12(sp)  # contador do loop (i)
    sw s1, 8(sp)   # endereço do array
    sw s2, 4(sp)   # N

    mv s1, a0
    mv s2, a1
    li s0, 0       # i = 0

print_array_loop:
    bge s0, s2, end_print_array  # Se i >= N, termina

    # Carrega o número do array e imprime
    lw a0, 0(s1)
    jal ra, printInteger

    # Lógica do separador: imprime vírgula se não for o último elemento
    addi t0, s2, -1
    blt s0, t0, print_comma
    j after_comma

print_comma:
    li a0, ','
    jal ra, uart_write_char

after_comma:
    addi s1, s1, 4  # Avança o ponteiro do array
    addi s0, s0, 1  # i++
    j print_array_loop

end_print_array:
    # Epílogo
    lw ra, 16(sp)
    lw s0, 12(sp)
    lw s1, 8(sp)
    lw s2, 4(sp)
    addi sp, sp, 20
    ret

# printInteger: Converte um inteiro para string e imprime na UART.
# Argumento:
#   a0: o número inteiro a ser impresso
printInteger:
    # Prólogo
    addi sp, sp, -48
    sw ra, 44(sp)
    sw s0, 40(sp)  # O número
    sw s1, 36(sp)  # Contador de dígitos

    mv s0, a0
    li s1, 0

    # Caso especial: 0
    bne s0, zero, not_zero
    li a0, '0'
    jal ra, uart_write_char
    j end_print_integer

not_zero:
    # Caso especial: negativo
    bge s0, zero, is_positive
    li a0, '-'
    jal ra, uart_write_char
    neg s0, s0

is_positive:
    # Loop de conversão: divide por 10 e empilha os restos
    li t0, 10
convert_loop:
    beqz s0, end_convert_loop
    div t1, s0, t0
    rem t2, s0, t0
    addi t2, t2, '0'
    addi sp, sp, -4
    sw t2, 0(sp)
    addi s1, s1, 1
    mv s0, t1
    j convert_loop

end_convert_loop:
    # Loop de impressão: desempilha e imprime
print_digits_loop:
    beqz s1, end_print_integer
    lw a0, 0(sp)
    addi sp, sp, 4
    jal ra, uart_write_char
    addi s1, s1, -1
    j print_digits_loop

end_print_integer:
    # Epílogo
    lw ra, 44(sp)
    lw s0, 40(sp)
    lw s1, 36(sp)
    addi sp, sp, 48
    ret

# =================================================================
# SUB-ROTINAS DE I/O DA UART
# =================================================================
readCharUART:
    li   t1, uartBasicAddress
    li   t2, uartBasicAddress + 5
    li   t3, 0b1
.poll_loop_uart:
    lb   t4, 0(t2)
    and  t4, t4, t3
    beqz t4, .poll_loop_uart
    lb   a0, 0(t1)
    ret

uart_write_char:
    li   t1, uartBasicAddress + 5
write_poll:
    lbu  t0, 0(t1)
    andi t0, t0, 0x20
    beq  t0, zero, write_poll
    li   t0, uartBasicAddress
    sb   a0, 0(t0)
    ret
