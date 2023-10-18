.org 0
.global main


/* newlib system calls */
.set SYSEXIT,  93
.set SYSWRITE, 64

.section .rodata
nextline: .ascii "\n"
       .set nextline_size, .-nextline
cycle_str: .ascii "cycle count: "
       .set cycle_size, .-cycle_str

.data
    # will not overflow
    cmp_data_1: .dword 0x0000000000000000, 0x0000000000000000
    # will not overflow
    cmp_data_2: .dword 0x0000000000000001, 0x0000000000000010
    # will not overflow
    cmp_data_3: .dword 0x0000000000000002, 0x4000000000000000
    # will overflow
    cmp_data_4: .dword 0x0000000000000003, 0x7FFFFFFFFFFFFFFF
    buffer:     .byte 0, 0, 0, 0 

.text
# assume little endian
main:
    jal get_cycles      # get cycles before execution

    addi sp, sp, -20
    # push four pointers of test data onto the stack
    la t0, cmp_data_1
    sw t0, 0(sp)
    la t0, cmp_data_2
    sw t0, 4(sp)
    la t0, cmp_data_3
    sw t0, 8(sp)
    la t0, cmp_data_4
    sw t0, 12(sp)
    sw a0, 16(sp)
    
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
    jal ra, cimo
    
    addi a0, a0, 48     # convert result into ascii code
    la t0, buffer  
    sb a0, 0(t0)        # store ascii result to buffer
    li a0, 1
    la a1, buffer
    li a2, 1
    li a7, SYSWRITE     # print result in ascii
    ecall               


    li a0, 1            # print "\n" in ascii
    la a1, nextline
    la a2, nextline_size
    lw a2, 0(a2)
    li a7, SYSWRITE       
    ecall             
    
    addi s2, s2, 4      # s2 points to next cmp_data_x
    addi s1, s1, 1      # counter++
    bne s1, s0, main_loop
    
    lw t0, 16(sp)       # get old cycle 
  
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
        
# check if multiplication overflow:
cimo:
    addi sp, sp, -36
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)
    sw s4, 20(sp)
    sw s5, 24(sp)
    sw s6, 28(sp)
    sw s7, 32(sp)
    
    lw s0, 0(a0)
    lw s1, 4(a0)
    li s2, 0
    li s3, 0            # s0 s1 s2 s3 is now the value of x0

    lw s4, 0(a1)
    lw s5, 4(a1)        # s4 s5 is now the value of x1

    add t0, zero, zero
    add t1, zero, zero
    add t2, zero, zero
    add t3, zero, zero  # t0 t1 t2 t3 is now the value of sum

    add s7, zero, zero  # s7 is now the value of cnt
    li s6, 64

cimo_loop:

    bne t2, zero, cimo_ret_t
    bne t3, zero, cimo_ret_t
    beq s7, s6, cimo_ret_f

    andi t4, s4, 1      # t4 is now the LSB of x1
    beq t4, zero, cimo_is_zero  # skip (sum = sum + x0)

cimo_add_sum:
    add t0, t0, s0
    sltu t4, t0, s0     # t4 is now the carry bit
    add t1, t1, s1
    sltu t5, t1, s1     # t5 is now the carry bit
    add t1, t1, t4
    add t2, t2, s2
    sltu t6, t2, s2     # t6 is now the carry bit
    add t2, t2, t5
    add t3, t3, s3
    add t3, t3, t6      # sum = sum + x0

cimo_is_zero:
    srli s4, s4, 1
    slli t4, s5, 31
    or s4, s4, t4
    srli s5, s5, 1      # x1 = x1 >> 1

    slli s3, s3, 1
    srli t4, s2, 31
    or s3, s3, t4
    slli s2, s2, 1
    srli t4, s1, 31
    or s2, s2, t4
    slli s1, s1, 1
    srli t4, s0, 31
    or s1, s1, t4
    slli s0, s0, 1      # x0 = x0 << 1

    addi s7, s7, 1      # cnt++

    j cimo_loop

cimo_ret_t:
    addi a0, zero, 1
    j cimo_end

cimo_ret_f:
    add a0, zero, zero

cimo_end:
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    lw s4, 20(sp)
    lw s5, 24(sp)
    lw s6, 28(sp)
    lw s7, 32(sp)
    addi sp, sp, 36
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
    jal get_cycles  # get new cycle
    sub a0, a0, t0  # total = new -old
    la a1, 4
    jal convert_ascii
    mv t0, a0

    # cycle str
    li a0, 1
    la a1, cycle_str
    la a2, cycle_size
    lw a2, 0(a2)
    li a7, SYSWRITE
    ecall
    # cycle count
    li a0, 1
    la a1, buffer
    li a2, 4
    li a7, SYSWRITE
    ecall

    li a0, 1            # print "\n" in ascii
    la a1, nextline
    la a2, nextline_size
    lw a2, 0(a2)
    li a7, SYSWRITE
    ecall      


    li a0, 0
    li a7, SYSEXIT
    ecall
