.data
# 0x00000000 => zero
# 0x7FC00000 => NAN
# 0x3f99999a =>  0x3f9a0000
# 0x4013d70a =>  0x40140000
# 0x405d70a4 =>  0x405d0000
# 0x40b428f6 =>  0x40b40000
Zero:        .word 0x00000000
NaN:         .word 0x7FC00000
testList:    .word 0x3f99999a
testAnswer:  .word 0x3f9a0000
exp_mask:    .word 0x7F800000
man_mask:    .word 0x007FFFFF
nan_mask:    .word 0x7F800000
div_mask:    .word 0x00008000
result_mask: .word 0xFFFF0000

FP32:        .string "The value of FP32 is "
BF16:        .string "The value of BF16 is "
nextLine:        .string "\n"

.text
#############################################################
# /*    main    */
main:
    
    # Test Zero 
    la t0, Zero
    lw a0, 0(t0)
    jal ra, printFP32
    la t0, Zero
    lw a0, 0(t0)
    jal ra, fp32_to_bf16
    jal ra, printBF16
    
    # Test NaN
    la t0, NaN
    lw a0, 0(t0)
    jal ra, printFP32
    la t0, NaN
    lw a0, 0(t0)
    jal ra, fp32_to_bf16
    jal ra, printBF16
    
    # Test other
    la t0, testList
    lw a0, 0(t0)
    jal ra, printFP32
    la t0, testList
    lw a0, 0(t0)
    jal ra, fp32_to_bf16
    jal ra, printBF16
    
    # Exit program
    li a7, 10
    ecall


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
    
    addi sp, sp, -8
    sw ra, 0(sp)
    sw a0, 4(sp)
    
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
    # Check if exp==0 , t0 = 1, else t0 = 0
    mv a0, s1
    jal ra, checkZero
    mv t0, a0
    # Check if man==0 , t1 = 1, else t1 = 0
    mv a0, s2
    jal ra, checkZero
    mv t1, a0
    # Check if (exp==0 and man ==0) return X
    and t2, t0, t1
    bnez t2, returnX
    
    # /*     infinity or NaN     */
    la t0, nan_mask
    lw t0, 0(t0)
    beq s2, t0, returnX
    
    # /*    Normalized number    */
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
    

    lw ra, 0(sp)
    addi sp, sp, 8
    mv a0, s0
    
    ret
#############################################################
# /*    Check Input eql to Zero    */
# Input 
# a0 : number
# Output 
# a0 : 1 if eql to zero ,else 0
checkZero:
    # if a0 == 0 go set flag
    beqz a0, setFlagtoOne
    # else 
    li a0, 0
    ret 
setFlagtoOne:
    li a0, 1
    ret     

#############################################################
# /*    return the origin float number x    */ 
# /*    When x= 0 or NaN    */ 
returnX:
    lw ra, 0(sp)
    lw a0, 4(sp)
    addi sp, sp, 8
    ret
    
#############################################################
# /*    print the number    */ 
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
    ret
#############################################################
# /*    print the 32 float number    */ 
# Input
# a0 : number
printFP32:
    mv t0, a0
    la a0, FP32
    li a7, 4
    ecall
    mv a0, t0
    li a7, 34
    ecall
    la a0, nextLine
    li a7, 4
    ecall
    ret