#include <stdio.h>
#include <stdint.h>

int64_t unsign32_mul (int32_t a, int32_t b)
{
  int32_t LSB = 1;
  int64_t multiplican = (int64_t) a;

  int64_t result = 0;
  int loopCounter = 32;
  while (loopCounter > 0)
    {
      int32_t lsb = b & LSB;
      if (lsb)
	{
	  result = result + multiplican;
	}
      multiplican = multiplican << 1;
      b = b >> 1;
      loopCounter--;
    }
  return result;
}



float float_mul (float *a, float *b)
{
  int32_t *aa = (int *) a;
  int32_t *bb = (int *) b;

  /*  sign bit    */
  int32_t sign = 0x80000000;
  int32_t a_sign = *aa & sign;
  int32_t b_sign = *bb & sign;
  int32_t r_sign = a_sign ^ b_sign;

  /* exp bit  */
  int32_t expo = 0x7F800000;
  int32_t a_exp = *aa & expo;
  int32_t b_exp = *bb & expo;
  int32_t bias = 0x3F800000;
  int32_t r_exp = a_exp + b_exp - bias;

  /*  mantisa */
  int32_t man = 0x007FFFFF;
  int32_t a_man = *aa & man;
  a_man = a_man | 0x00800000;
  int32_t b_man = *bb & man;
  b_man = b_man | 0x00800000;
  int64_t r = unsign32_mul (a_man, b_man);

  /*  normalization   */
  int64_t needNorm = r & 0x800000000000;
  r = r >> 23;
  int64_t r_man = r & 0x7FFFFF;
  if (needNorm)
    {
      r_exp = r_exp + 0x00800000;
      r = r >> 1;
      r_man = r & 0x7FFFFF;
    }

  int32_t result = r_sign + r_exp + (int32_t) r_man;
  float *ptr = (float *) &result;

  return *ptr;
}

int main ()
{

  int32_t a = 0x42488000;
  int32_t b = 0xc2930000;


  float *ptrA = (float *) &(a);
  float *ptrB = (float *) &(b);

  float t = float_mul (ptrA, ptrB);

  printf ("Correct answer : %f\n", *ptrA * *ptrB);
  printf ("float_mul : %f", t);

  return 0;
}
