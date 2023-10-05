# [homework01_hackmd](https://hackmd.io/CUReqwpORbGml9qyYOxr8g)

# About my homework

- BFloatMul.s / BFloatMul.c
    - Implement bfloat16 multiplication.
- FloatMul.s / FloatMul.c
    - Implement float32 multiplication.
- main.s
    - Implement fp32_to_bf16 function ( [C code from Quiz1.B problem](https://hackmd.io/@sysprog/arch2023-quiz1) )
    - Implement test function to test fp32_to_bf16
    - Add float32 mutiplication from FloatMul.s
    - Add bfloat16 mutiplication from BFloatMul.s
- main_optimized.s
    - optimize fp32_to_bf16 function(reduce jump instructions)
    - optimize bfloat16 mutiplication(loop unrolling)

# About my branch

- [Implemente float32 multiplication (predefined data) in main.s](https://github.com/jimmylu890303/2023_Computer_Architecture/blob/float32-mul-branch/assignment/hw1/main.s)

- [Implemente bfloat16 multiplication (predefined data) in main.s](https://github.com/jimmylu890303/2023_Computer_Architecture/blob/bfloat16-mul/assignment/hw1/main.s)

- [Implemente bfloat16 multiplication (using fp32_to_bf16 to convert fp32 to bf16) in main.s](https://github.com/jimmylu890303/2023_Computer_Architecture/blob/convert-float-and-bloat16-mul/assignment/hw1/main.s)