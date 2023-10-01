.data
    nextLine: .string "\n"

.text
main: 
    li a0, 0x40b40000    # 5.630000
    li a1, 0x405d0000    # 3.460000
    jal bfloat16_mul
    
    li a7,34
    ecall
    j End
    
#############################################################
# /*    bfloat 16bit multiplier    */
# Input:
# a0: bfloat a
# a1: bfloat b
# Outpu:
# a0: bfloat result

bfloat16_mul:
    addi sp, sp, -16
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    
    # load float a & float b
    mv s0, a0
    mv s1, a1
    li s2, 0         # init result
    
    # /*    1. deal with Sign    */
    li t0, 0x80000000
    # extract sign bit from a and b 
    and t1, s0, t0    # sign bit of float a
    and t2, s1, t0    # sign bit of float b
    xor t0, t1, t2    # t0 = 0 => positive,t0 = 0x80000000 => negative
    add s2, s2, t0    # result = 0bx000...00000
    
    # /*    2. deal with Exponent    */
    li t0, 0x7F800000
    and t1, s0, t0    # exp bit of float a
    and t2, s1, t0    # exp bit of float b
    srli t1, t1, 23   # right shift 23bits
    srli t2, t2, 23   # right shift 23bits
    addi t1, t1, -127 # actual exp = exp - bias
    addi t2, t2, -127 # actual exp = exp - bias
    li t0, 127        # bias
    add t1, t1, t2    # t1 = exp of a + exp of b
    add t0, t0, t1    # t0 = t1 + bias
    slli t0, t0, 23   # left shift 23 bits
    add s2, s2, t0    # result = reseult + exp bit
    
    # /*    3. deal with Mantissa
    li t0, 0x007F0000
    and t1, s0, t0    # man bit of float a
    and t2, s1, t0    # man bit of float b
    li t0, 0x00800000
    or t1, t1, t0     # t1 = 1 + mantisa (7 bits)
    or t2, t2, t0     # t2 = 1 + mantisa (7 bits)
    srli t1, t1, 16   # t1 = 0b000000001xxxxxxx
    srli t2, t2, 16   # t2 = 0b000000001xxxxxxx
    
    mv a0, t1
    mv a1, t2
    jal unsign8_mul  # t1 * t2
    
    
    # /*    4. Normalize & Adjust exp    */
    # idea: if 48th bit is 1  
    # need to normaliz & adjust exp
    
    li t0, 0x00008000
    and t1, a0, t0    # extract 16th bit 
    beqz t1, no_exp   # if 16th bit = 0, no need to adjust exp
    li t2, 0          # if t2 = 1, already adjust exp, so need to normalize
    # Adjust exp
    li t0, 0x00800000 # exp + 1
    add s2, s2, t0    # the exp bit of result ++
    addi t2, t2, 1

    no_exp:
    # Extract mantisa from a0
    li t0, 0x00003F80    # extract 7 bits from result 32bits
    li t3, 9             # the number of bits need to left shit 
    beqz t2, no_take_one
    addi t3, t3, -1      # left shift 8bits
    li t0, 0x00007F00    # extract right 7 bits from upper 32bits
    
    no_take_one:
    and t1, a0, t0       # t1= 00..0(7)000000
    sll t1, t1, t3       # t1= 00..0(7)000000
    
    
    add s2, s2, t1       # result = sign | exp | frac(7) | 0000
    
    # return val
    mv a0, s2
    
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    addi sp, sp, 16

    ret
#############################################################
# /*    unsign 32bit multiplier    */
# Input:
# a0 : unsign num a 8bits
# a1 : unsign num b 8bits 
# Output:
# a0 : result 32bits   

unsign8_mul:
    # s0 = a
    # s1 = b
    addi sp, sp, -8
    sw s0, 0(sp)
    sw s1, 4(sp)
    
    # Load the unsign 32bit number a and b
    mv s0, a0
    mv s1, a1
    
    # Initialize the result to 0
    li t0, 0   # result 32 bits

    # Initialize loop counter
    li t2, 8  # loop counter
    li t6, 0   # shift counter

    # Loop to perform multiplication
    loop:
        mv t3, s0        # multiplicand
        mv t4, s1        # multiplier

        andi t5, t4, 1   # extract LSB from multiplier
        
        beqz t5, no_add  # if LSB=0, skip addition
        
        sll t5, t3, t6   # left shift multiplicand with n bits (t6)
        add t0, t0, t5   # lower 32bits = lower 32bits + left shifted multiplicand
        
        no_add:
        srli s1, s1, 1   # right shift multiplier
        addi t6, t6, 1   # shift counter++
        addi t2, t2, -1  # Decrement the loop counter
        bnez t2, loop    # Continue the loop until all bits are processed

    # Store the final result in a0
    mv a0, t0
  
    
    lw s0, 0(sp)
    lw s1, 4(sp)
    addi sp, sp, 8
    
    ret
End:    
    # Exit the program
    li a7, 10
    ecall