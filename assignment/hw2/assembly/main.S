.org 0
.global main


/* newlib system calls */
.set SYSEXIT,  93
.set SYSWRITE, 64

.section .rodata
space: .ascii " "
       .set space_size, .-space



.data
    # will not overflow, and will predict as false
    cmp_data_1: .dword 0x0000000000000000, 0x0000000000000000
    # will not overflow, and will predict as false
    cmp_data_2: .dword 0x0000000000000001, 0x0000000000000010
    # will not overflow, but will predict as true
    cmp_data_3: .dword 0x0000000000000002, 0x4000000000000000
    # will overflow, and will predict as true
    cmp_data_4: .dword 0x0000000000000003, 0x7FFFFFFFFFFFFFFF
    buffer:     .byte 0, 0, 0, 0, 0
    cycle_str:  .ascii "\ncycle count: "
    .set cycle_str_size, .-cycle_str
    nextline:   .ascii "\n"
    .set nextline_size, .-nextline

.text
# assume little endian
main:
    # Compute cycles
    jal get_cycles
    addi sp, sp, -4
    sw a0, 0(sp)

    addi sp, sp, -20
    # Compute cycles
    jal get_cycles
    sw a0, 16(sp)

    # push four pointers of test data onto the stack
    la t0, cmp_data_1
    sw t0, 0(sp)
    la t0, cmp_data_2
    sw t0, 4(sp)
    la t0, cmp_data_3
    sw t0, 8(sp)
    la t0, cmp_data_4
    sw t0, 12(sp)
    
    # for testing
    #li a0, 0
    #li a1, 0x00
    #jal ra clz
    #jal ra print_dec
    #j exit
 
    addi s0, zero, 4    # s0 is the goal iteration count
    addi s1, zero, 0    # s1 is the counter
    addi s2, sp, 0      # s2 now points to cmp_data_1
main_loop:
    lw a0, 0(s2)        # a0 stores the pointer to first data in cmp_data_x
    addi a1, a0, 8      # a1 stores the pointer to second data in cmp_data_x
    jal ra, pimo
    
    addi a0, a0, 48
    la t0, buffer
    sb zero, 1(t0)
    sb a0, 0(t0)
    li a0, 1
    la a1, buffer
    li a2, 2
    li a7, SYSWRITE            # tell ecall to print decimal
    ecall               # print result of pimo (which is in a0)
    
    
    li a0, 1          
    la a1, space
    la a2, space_size
    lw a2, 0(a2)
    li a7, SYSWRITE
    ecall               # print space
    
    addi s2, s2, 4      # s2 points to next cmp_data_x
    addi s1, s1, 1      # counter++
    bne s1, s0, main_loop
 
    # Compute cycles
    jal get_cycles
    lw t0, 16(sp)        # old cycle
    sub a0, a0, t0     # cycle num = new cycle - old cycle
    li a1, 3
    jal ra, convert_ascii

    # print cycle str
    li a0, 1
    la a1, cycle_str
    la a2, cycle_str_size
    lw a2, 0(a2)
    li a7, SYSWRITE
    ecall
    # print cycle
    li a0, 1
    la a1, buffer
    la a2, 5
    li a7, SYSWRITE
    ecall

   
    addi sp, sp, 20

    j exit
    
# get cycles
get_cycles:
    csrr a1, cycleh
    csrr a0, cycle
    csrr a2, cycleh
    bne a1, a2, get_cycles
    ret

# convert number to ascii code
# Input:
# a0: number
# a1: number of bits
convert_ascii:
    addi sp, sp, -8
    sw a0, 0(sp)  # save dividend
    sw a1, 4(sp)  # save counter

convert_loop:
    lw t0, 0(sp)  # load dividend
    li t1, 0      # t1 = quotient
    li t2, 0      # t2 = reminder
    lw t3, 4(sp)  # load counter
    li t4, 10     # divisor
divide_loop:
    # if x > 10 => go x-=10
    bge t0, t4, divide_subtract

    # else reminder be found
    mv t2, t0
    j divide_loop_done

divide_subtract:
    # x = x - 10
    sub t0, t0, t4
    # quotient += 1
    addi t1, t1, 1
    j divide_loop

divide_loop_done:
    # save quotient to stack
    sw t1, 0(sp)
    # convert ascii code this round and save to buffer
    addi t2, t2, 48
    la a0, buffer
    add a0, a0, t3
    addi a0, a0, -1
    sb t2, 0(a0)

    # counter = 0 => exit
    addi t3, t3, -1
    sw t3, 4(sp)
    beqz t3, convert_loop_done
    j convert_loop
convert_loop_done:
    addi sp, sp, 8
    ret 

# predict if multiplication overflow:
pimo:
    addi sp, sp, -20
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)
    
    mv s0, a0       # s0 is address of x0
    mv s1, a1       # s1 is address of x1
    
    lw a0, 0(s0)
    lw a1, 4(s0)    # a0 a1 is now the value of x0
    jal ra, clz
    li s2, 63
    sub s2, s2, a0  # s2 is now exp_x0
    
    lw a0, 0(s1)
    lw a1, 4(s1)    # a1 a0 is now the value of x1
    jal ra, clz
    li s3, 63
    sub s3, s3, a0  # s3 is now exp_x1
 
    add s2, s2, s3
    addi s2, s2, 2  # s2 is (exp_x0 + 1) + (exp_x1 + 1)
    li t0, 64
    bge s2, t0, pimo_ret_t
    li a0, 0        # return false
    j pimo_end
pimo_ret_t:
    li a0, 1        # return true
pimo_end:
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    addi sp, sp, 20
    ret


# count leading zeros
clz:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    # a0 a1 = x

    bne a1, zero, clz_fill_ones_upper
clz_fill_ones_lower:
    srli t0, a0, 1
    or a0, a0, t0
    srli t0, a0, 2
    or a0, a0, t0
    srli t0, a0, 4
    or a0, a0, t0
    srli t0, a0, 8
    or a0, a0, t0
    srli t0, a0, 16
    or a0, a0, t0
    j clz_fill_ones_end
clz_fill_ones_upper:
    srli t1, a1, 1
    or a1, a1, t1
    srli t1, a1, 2
    or a1, a1, t1
    srli t1, a1, 4
    or a1, a1, t1
    srli t1, a1, 8
    or a1, a1, t1
    srli t1, a1, 16
    or a1, a1, t1
    li a0, 0xffffffff
clz_fill_ones_end:
    
    
    # x -= ((x >> 1) & 0x5555555555555555);
    srli t0, a0, 1
    slli t1, a1, 31
    or t0, t0, t1
    srli t1, a1, 1      # t0 t1 = x >> 1
    
    li t2, 0x55555555   # t2 is the mask
    and t0, t0, t2
    and t1, t1, t2      # t0 t1 = (x >> 1) & 0x5555555555555555
 
    sltu t3, a0, t0     # t3 is the borrow bit
    sub a0, a0, t0
    sub a1, a1, t1
    sub a1, a1, t3      # a0 a1 = x - (t0 t1)
    
    
    # x = ((x >> 2) & 0x3333333333333333) + (x & 0x3333333333333333);
    srli t0, a0, 2
    slli t1, a1, 30
    or t0, t0, t1
    srli t1, a1, 2      # t0 t1 = x >> 2
    
    li t2, 0x33333333   # t2 is the mask
    and t0, t0, t2
    and t1, t1, t2      # t0 t1 = (x >> 2) & 0x3333333333333333
    and t4, a0, t2
    and t5, a1, t2      # t4 t5 = x & 0x3333333333333333
    
    add a0, t0, t4
    sltu t3, a0, t0     # t3 is the carry bit
    add a1, t1, t5
    add a1, a1, t3      # a0 a1 = (t0 t1) + (t4 t5)
    
    
    # x = ((x >> 4) + x) & 0x0f0f0f0f0f0f0f0f;
    srli t0, a0, 4
    slli t1, a1, 28
    or t0, t0, t1
    srli t1, a1, 4      # t0 t1 = x >> 4
    
    add t0, t0, a0
    sltu t3, t0, a0     # t3 is the carry bit
    add t1, t1, a1
    add t1, t1, t3      # t0 t1 = (x >> 4) + x
    
    li t2, 0x0f0f0f0f   # t2 is the mask
    and a0, t0, t2
    and a1, t1, t2      # a0 a1 = (t0 t1) & 0x0f0f0f0f0f0f0f0f
    
    
    # x += (x >> 8);
    srli t0, a0, 8
    slli t1, a1, 24
    or t0, t0, t1
    srli t1, a1, 8      # t0 t1 = x >> 8
    
    add a0, a0, t0
    sltu t3, a0, t0     # t3 is the carry bit
    add a1, a1, t1
    add a1, a1, t3      # a0 a1 = x + (x >> 8)
    
    
    # x += (x >> 16);
    srli t0, a0, 16
    slli t1, a1, 16
    or t0, t0, t1
    srli t1, a1, 16     # t0 t1 = x >> 16
    
    add a0, a0, t0
    sltu t3, a0, t0     # t3 is the carry bit
    add a1, a1, t1
    add a1, a1, t3      # a0 a1 = x + (x >> 16)
    
    
    # x += (x >> 32);
    mv t0, a1
    mv t1, zero         # t0 t1 = x >> 32
    
    add a0, a0, t0
    sltu t3, a0, t0     # t3 is the carry bit
    add a1, a1, t1
    add a1, a1, t3      # a0 a1 = x + (x >> 32)
    
    
    # return (64 - (x & 0x7f));
    andi a0, a0, 0x7f   # a0 = (x & 0x7f)
    li t0, 64
    sub a0, t0, a0      # a0 = (64 - (x & 0x7f))
    
    
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# util func
print_hex:
    addi sp, sp, -4
    sw ra, 0(sp)
    li a7, 34
    ecall       # print value
    li a0, 32   # 32 is " " in ASCII
    li a7, 11
    ecall       # print space
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

print_dec:
    addi sp, sp, -4
    sw ra, 0(sp)
    li a7, 1
    ecall       # print value
    li a0, 32   # 32 is " " in ASCII
    li a7, 11
    ecall       # print space
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

exit:
    li a0, 1
    la a1, nextline
    la a2, nextline_size
    li a7, SYSWRITE
    ecall

    li a7, SYSEXIT
    li a0, 0
    ecall 
