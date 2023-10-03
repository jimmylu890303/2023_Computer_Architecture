#include <stdio.h>
#include <stdint.h>

int32_t unsign8_mul(int32_t a, int32_t b){
    int32_t LSB = 1;
    int32_t multiplican = a;
    
    int32_t result = 0;
    int loopCounter = 8;
    while(loopCounter>0){
        int32_t lsb = b & LSB;
        if(lsb){
            result = result + multiplican;
        }
        multiplican = multiplican << 1;
        b = b >> 1;
        loopCounter--;
    }
    return result;
}



float bfloat_mul(float *a, float *b){
    int32_t* aa = (int *)a;
    int32_t* bb = (int *)b;
    
    /*  sign bit    */
    int32_t sign = 0x80000000;
    int32_t a_sign = *aa&sign;
    int32_t b_sign = *bb&sign;
    int32_t r_sign = a_sign^b_sign;
    
    /* exp bit  */
    int32_t expo = 0x7F800000;
    int32_t a_exp = *aa&expo;
    int32_t b_exp = *bb&expo;
    int32_t bias = 0x3F800000;
    int32_t r_exp = a_exp+b_exp-bias;
    
    /*  mantisa */
    int32_t man = 0x007F0000;
    int32_t a_man = *aa&man;
    a_man = a_man | 0x00800000;
    a_man = a_man >> 16;
    int32_t b_man = *bb&man;
    b_man = b_man | 0x00800000;
    b_man = b_man >> 16;
    int32_t r = unsign8_mul(a_man,b_man);

    /*  normalization   */
    int32_t needNorm = r & 0x00008000;
    r = r >> 7;
    int32_t r_man = r & 0x7F;
    if(needNorm){
        r_exp = r_exp + 0x00800000;
        r = r >> 1;
        r_man = r & 0x7F;
    }
    r_man = r_man << 16;
    int32_t result = r_sign+r_exp + r_man;
    float * ptr = (float * )&result;
    
    return *ptr;
}

int main()
{
    
    int32_t a = 0x40b40000;
    int32_t b = 0x405d0000;


    float* ptrA = (float*)&(a);
    float* ptrB = (float*)&(b);
    
    float t = bfloat_mul(ptrA,ptrB);
    
    printf("Correct answer : %f\n",*ptrA * *ptrB);
    printf("float_mul : %f",t);

    return 0;
}
