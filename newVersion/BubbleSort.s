.data
	separator: .byte ','

.bss
	arrayLength: .space 4
	array: .space 4000

.text

.global main
main:
	addi sp, sp, -16
	sw   ra, 12(sp)

	la s4, array

	jal ra, readIntegers

	lw   ra, 12(sp)
	addi sp, sp, 16
	ret

readIntegers:
	# --- Prólogo Corrigido ---
	# Aloca 32 bytes (múltiplo de 16) para salvar 7 registradores (28 bytes).
	addi sp, sp, -32
	sw   ra, 28(sp)
	sw   s2, 24(sp) # current_number
	sw   s3, 20(sp) # is_negative_flag
	sw   s4, 16(sp) # array_pointer
	sw   s5, 12(sp) # digit_seen_flag (NOVO)
	sw   s6, 8(sp)  # N (a contagem)
	sw   s7, 4(sp)  # i (o contador)

	# =================================================================
	# FASE 1: LER O PRIMEIRO NÚMERO (A CONTAGEM N)
	# =================================================================
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
	mv s6, s2 # Salva a contagem de números em s6 (N)
	
	# =================================================================
	# FASE 2: LER OS N NÚMEROS DO ARRAY
	# =================================================================
	li s7, 0 # Inicializa o contador do loop (i = 0)
	
.main_loop_start:
	blt s7, s6, .loopToRead # Se i < N, continua.
	j .endReadIntegers      # Se i >= N, termina.

.loopToRead:
	li s2, 0 # Reinicia acumulador
	li s3, 0 # Reinicia flag de negativo
	li s5, 0 # Reinicia flag "vimos um dígito"

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
	li s5, 1 # Ativa a flag: "vimos um dígito"
	addi t0, t0, -48
	li t1, 10
	mul s2, s2, t1
	add s2, s2, t0
	j .read_char_loop

.handle_separator:
	beqz s5, .read_char_loop # Se não vimos dígitos, ignora o separador.
	beqz s3, .saveNumber
	neg s2, s2

.saveNumber:
	sw s2, 0(s4)
	addi s4, s4, 4
	addi s7, s7, 1 # Incrementa o contador de números lidos (i++)
	j .main_loop_start # Volta para verificar a condição (i < N)

.handle_negative:
	li s5, 1 # Ativa a flag: "vimos um sinal"
	li s3, 1
	j .read_char_loop

.endReadIntegers:
	# --- Epílogo Corrigido ---
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
# Sub-rotina para ler um único caractere da UART via MMIO
# =================================================================
readCharUART:
	li   t1, 0x10000000
	li   t2, 0x10000005
	li   t3, 0b1

.poll_loop_uart:
	lb   t4, 0(t2)
	and  t4, t4, t3
	beqz t4, .poll_loop_uart

	lw   a0, 0(t1)
	ret
