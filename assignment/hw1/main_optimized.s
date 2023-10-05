.data
Zero:        .word 0x00000000
NaN:         .word 0x7FC00000
testArray:   .word 0x3f99999a, 0x4013d70a, 0x405d70a4, 0x40b428f6
testAnswer:  .word 0x3f9a0000, 0x40140000, 0x405d0000, 0x40b40000
testNum:     .word 4
exp_mask:    .word 0x7F800000
man_mask:    .word 0x007FFFFF
nan_mask:    .word 0x7F800000
div_mask:    .word 0x00008000
result_mask: .word 0xFFFF0000

FP32:        .string "The value of FP32 is "
BF16:        .string "The value of BF16 is "
nextLine:    .string "\n"
fail:        .string "Fail Test!\n"
pass:        .string "Pass Test!\n"
fp32mul:     .string "The value of Float32  mul is "
bf16mul:     .string "The value of BFloat16 mul is "


.text
#############################################################
# /*    main    */
main:
   
    # Convert same valuse from fp32 to bf16
    li a0, 0x42488000    # 50.125
    jal fp32_to_bf16
    mv s0, a0
    li a0, 0xc2930000    # -73.5
    jal fp32_to_bf16
    mv s1, a0
    
    # bfloat16 mul
    la a0, bf16mul
    li a7, 4
    ecall 
    mv a0, s0    # 50.125
    mv a1, s1    # -73.5
    jal bfloat16_mul
    li a7,34
    ecall
    la a0, nextLine      # 0xc5660000 = -3680.0
    li a7, 4
    ecall 
    
    # Exit 
    j End

#############################################################
# /*    fp32_to_bf16    */
# Input
# a0 : 32 bit float but saved in 2's complement
# Output
# a0 : bf16

fp32_to_bf16:
    # s0 = y = x
    # s1 = exp
    # s2 = man
    
    addi sp, sp, -20
    sw ra, 0(sp)
    sw a0, 4(sp)
    sw s0, 8(sp)
    sw s1, 12(sp)
    sw s2, 16(sp)
    
    # Load y = x in s0
    mv s0, a0

    # Get actuall exp bit in s1
    # Load exp mask
    la s1 exp_mask
    lw s1, 0(s1)
    # Get exp bit
    and s1, s1, s0
    
    # Get actuall man bit in s2
    # Load man mask
    la s2 man_mask
    lw s2, 0(s2)
    # Get man bit
    and s2, s2, s0
    
    # /*     zero     */
    or t0, s1, s2
    beqz t0, returnX
    
    
    # /*     infinity or NaN     */
    la t0, nan_mask
    lw t0, 0(t0)
    beq s1, t0, returnX
    
    # /*     Normalized number    */
    # /*     round to nearest    */
    # r = r / 256
    la t0, div_mask
    lw t0, 0(t0)
    # y = x + r
    add s0, s0, t0  
    # result
    la t0, result_mask
    lw t0, 0(t0)
    and s0, s0, t0
    
    mv a0, s0    # return val
    
    lw s0, 8(sp)
    lw s1, 12(sp)
    lw s2, 16(sp)
    lw ra, 0(sp)
    addi sp, sp, 20 
    ret

#############################################################
# /*    return the origin float number x    */ 
# /*    When x= 0 or NaN    */ 

returnX:
    lw ra, 0(sp)
    lw a0, 4(sp)
    lw s0, 8(sp)
    lw s1, 12(sp)
    lw s2, 16(sp)
    addi sp, sp, 20
    ret

#############################################################
# /*    print the  bf16 number    */ 
# Input
# a0 : number

printBF16:
    mv t0, a0
    la a0, BF16
    li a7, 4
    ecall
    mv a0, t0
    li a7, 34
    ecall
    la a0, nextLine
    li a7, 4
    ecall
    li a7, 4
    ecall
    ret

#############################################################
# /*    bfloat 16bit multiplier    */
# Input:
# a0: bfloat a
# a1: bfloat b
# Output:
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
    li s2, 0          # init result
    
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
    beqz t1, bf16_no_exp   # if 16th bit = 0, no need to adjust exp
    li t2, 0          # if t2 = 1, already adjust exp, so need to normalize
    # Adjust exp
    li t0, 0x00800000 # exp + 1
    add s2, s2, t0    # the exp bit of result ++
    addi t2, t2, 1

    bf16_no_exp:
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
    bf16_mul_loop:
        mv t3, s0        # multiplicand
        mv t4, s1        # multiplier

        andi t5, t4, 1   # extract LSB from multiplier
        
        beqz t5, bf16_no_add  # if LSB=0, skip addition
        
        sll t5, t3, t6   # left shift multiplicand with n bits (t6)
        add t0, t0, t5   # lower 32bits = lower 32bits + left shifted multiplicand
        
        bf16_no_add:
        srli s1, s1, 1   # right shift multiplier
        addi t6, t6, 1   # shift counter++
        addi t2, t2, -1  # Decrement the loop counter
        bnez t2, bf16_mul_loop    # Continue the loop until all bits are processed

    # Store the final result in a0
    mv a0, t0
  
    
    lw s0, 0(sp)
    lw s1, 4(sp)
    addi sp, sp, 8
    
    ret

#############################################################

End:
    # Exit program
    li a7, 10
    ecall
    