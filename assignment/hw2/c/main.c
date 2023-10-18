#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>

// statics
extern uint64_t get_cycles();
// test case a: no overflow, predict result is false
uint64_t a_x0 = 0x0000000000000000;
uint64_t a_x1 = 0x0000000000000000;
// test case b: no overflow, predict result is false
uint64_t b_x0 = 0x0000000000000001;
uint64_t b_x1 = 0x0000000000000010;
// test case c: no overflow, but predict result is true
uint64_t c_x0 = 0x0000000000000002;
uint64_t c_x1 = 0x4000000000000000;
// test case d: overflow, and predict result is true
uint64_t d_x0 = 0x0000000000000003;
uint64_t d_x1 = 0x7FFFFFFFFFFFFFFF;


uint16_t count_leading_zeros(uint64_t x)
{
    x |= (x >> 1);
    x |= (x >> 2);
    x |= (x >> 4);
    x |= (x >> 8);
    x |= (x >> 16);
    x |= (x >> 32);

    /* count ones (population count) */
    x -= ((x >> 1) & 0x5555555555555555);
    x = ((x >> 2) & 0x3333333333333333) + (x & 0x3333333333333333);
    x = ((x >> 4) + x) & 0x0f0f0f0f0f0f0f0f;
    x += (x >> 8);
    x += (x >> 16);
    x += (x >> 32);

    return (64 - (x & 0x7f));
}

bool predict_if_mul_overflow(uint64_t *x0, uint64_t *x1)
{
    int32_t exp_x0 = 63 - (int32_t)count_leading_zeros(*x0);
    int32_t exp_x1 = 63 - (int32_t)count_leading_zeros(*x1);
    if ((exp_x0 + 1) + (exp_x1 + 1) >= 64)
        return true;
    else
        return false;
}

int main()
{
    uint64_t oldcount = get_cycles();
    printf("%d\n", predict_if_mul_overflow(&a_x0, &a_x1));
    printf("%d\n", predict_if_mul_overflow(&b_x0, &b_x1));
    printf("%d\n", predict_if_mul_overflow(&c_x0, &c_x1));
    printf("%d\n", predict_if_mul_overflow(&d_x0, &d_x1));
    uint64_t cyclecount = get_cycles() - oldcount;
    printf("cycle count: %u\n", (unsigned int) cyclecount);
    return 0;
}
