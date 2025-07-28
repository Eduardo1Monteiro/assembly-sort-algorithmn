section .data 
  separator db ',', 1

section .bss
  inputFile resd 1
  outputFile resd 1
  arrayLength resd 1
  array resd 1000
  readBuffer resb 1

readIntegers:
  xor eax, eax
  mov esi, 1
  mov edx, 0 

skipWhiteSpace:
  mov eax, 3
  mov ebx, [inputFile]
  mov ecx, readBuffer 
  mov edx, 1
  int 0x80 

  cmp eax, 0 
  je .finished 

  mov cl, [readBuffer]

  cmp cl, ' '
  je skipWhiteSpace
  cmp cl, 10
  je skipWhiteSpace
  cmp cl, 9
  je skipWhiteSpace

  cmp cl, '-'
  jne .startConversion  
  mov esi, -1 
  jmp skipWhiteSpace

.startConversion: 
  mov edx, 1

.conversion: 
    cmp cl, '0'
    jl .applySign
    cmp cl, '9'
    jg .applySign

    sub cl, '0' 
    imul eax, 10 
    add eax, ecx 

    mov eax, 3
    mov ebx, [inputFile]
    mov ecx, readBuffer
    mov edx, 1
    int 0x80
    cmp eax, 0   
    je .applySign
    mov cl, [readBuffer]  
    jmp .conversion 

.applySign:
    imul esi

.finished: 
  ret

exitError:
    mov eax, 1
    mov ebx, 1
    int 0x80

section .text 
  global _start


_start:
  mov eax, [esp]
  cmp eax, 3
  // error handler

  // opens the input file 
  mov eax, 5
  mov ebx, [esp + 8]
  xor ecx, ecx 
  xor edx, edx 
  int 0x80
  cmp eax, 0
  jl exitError 
  mov [inputFile], eax

  // opens the output file 
  mov eax, 5
  mov ebx, [esp + 12]
  mov ecx, 65
  mov edx, 0644o 
  int 0x80
  cmp eax, 0 
  jl exitError 
  mov [outputFile], eax

  xor ecx, ecx 

readLoop: 
  call readIntegers
  cmp edx, 1 
  jne .endReadLoop 
  
  mov [array + ecx * 4], eax 
  inc ecx 
  jmp readLoop 

.endReadLoop: 
  mov [arrayLength], ecx 

  // close input file 
  mov eax, 6
  mov ebx, [inputFile]
  int 0x80 

  // close output file 
  mov eax, 6 
  mov ebx, [outputFile]
  int 0x80 

exitSuccess: 
  mov eax, 1
  mov ebx, 0 
  int 0x80
