// Copyright ©2017 The gonum Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//+build !noasm,!appengine

#include "textflag.h"

#define X_PTR SI
#define Y_PTR DX
#define DST DI
#define IDX CX
#define LEN BX
#define TAIL BX
#define INC_X R8
#define INCx3_X R9
#define INC_Y R10
#define INCx3_Y R11
#define INC_DST R12
#define INCx3_DST R13

// func MulIncTo(dst, x, y []float64, n, incDst, incX, incY, iDst, ix, iy int) []float64 {
TEXT ·MulIncTo(SB), NOSPLIT, $0
	MOVQ dst_base+0(FP), DST   // DST = &dst
	MOVQ DST, ret_base+128(FP)
	MOVQ x_base+24(FP), X_PTR  // X_PTR = &src
	MOVQ y_base+48(FP), Y_PTR  // Y_PTR = &y
	MOVQ n+72(FP), LEN         // LEN = n
	CMPQ IDX, $0               // if n==0 { return }
	JE   mul_end

	MOVQ iDst+104(FP), INC_DST // INC_DST = iDst
	MOVQ iy+120(FP), INC_Y     // INC_Y = iy
	MOVQ ix+112(FP), INC_X     // INC_X = ix

	LEAQ (DST)(INC_DST*8), DST   // DST = &(dst[iDst])
	LEAQ (Y_PTR)(INC_Y*8), Y_PTR // Y_PTR = &(y[iy])
	LEAQ (X_PTR)(INC_X*8), X_PTR // X_PTR = &(x[ix])

	MOVQ incDst+80(FP), INC_DST // INC_DST = incDst
	SHLQ $3, INC_DST            // INC_DST *= sizeof(float64)
	MOVQ incX+88(FP), INC_X     // INC_X = incX
	SHLQ $3, INC_X              // INC_X *= sizeof(float64)
	MOVQ incY+96(FP), INC_Y     // INC_Y = incY
	SHLQ $3, INC_Y              // INC_Y *= sizeof(float64)

	MOVQ LEN, IDX
	ANDQ $3, TAIL // TAIL = LEN % 4
	SHRQ $2, IDX  // IDX = floor( LEN / 4 )
	JZ   mul_tail // if IDX == 0 { goto mul_tail }

	LEAQ (INC_Y)(INC_Y*2), INCx3_Y       // INCx3_Y = 3 * INC_Y
	LEAQ (INC_X)(INC_X*2), INCx3_X       // INCx3_X = 3 * INC_X
	LEAQ (INC_DST)(INC_DST*2), INCx3_DST // INCx3_DST = 3 * INC_DST

mul_loop: // do {
	MOVSD (X_PTR), X0            // X_i = src[i*incSrc]
	MOVSD (X_PTR)(INC_X*1), X1
	MOVSD (X_PTR)(INC_X*2), X2
	MOVSD (X_PTR)(INCx3_X*1), X3

	MULSD (Y_PTR), X0            // X_i *= dst[i*incDst]
	MULSD (Y_PTR)(INC_Y*1), X1
	MULSD (Y_PTR)(INC_Y*2), X2
	MULSD (Y_PTR)(INCx3_Y*1), X3

	MOVSD X0, (DST)              // dst[i*incDst] = X_i
	MOVSD X1, (DST)(INC_DST*1)
	MOVSD X2, (DST)(INC_DST*2)
	MOVSD X3, (DST)(INCx3_DST*1)

	LEAQ (X_PTR)(INC_X*4), X_PTR // X_PTR = &(X_PTR[ incX*4 ])
	LEAQ (Y_PTR)(INC_Y*4), Y_PTR // Y_PTR = &(Y_PTR[ incY*4 ])
	LEAQ (DST)(INC_DST*4), DST   // DST = &(DST[ incDst*4 ])

	DECQ IDX
	JNZ  mul_loop
	CMPQ TAIL, $0
	JE   mul_end

mul_tail:
	MOVQ TAIL, IDX
	SHRQ $1, IDX      // IDX = floor( TAIL / 2 )
	JZ   mul_tail_one

mul_tail_two:
	MOVSD (X_PTR), X0             // X_i = x[i*incX]
	MOVSD (X_PTR)(INC_X*1), X1
	MULSD (Y_PTR), X0             // X_i *= y[i*incY]
	MULSD (Y_PTR)(INC_Y*1), X1
	MOVSD X0, (DST)               // dst[i*incDst] = X_i
	MOVSD X1, (DST)(INC_DST*1)
	LEAQ  (X_PTR)(INC_X*2), X_PTR
	LEAQ  (Y_PTR)(INC_Y*2), Y_PTR
	LEAQ  (DST)(INC_DST*2), DST
	DECQ  IDX
	JNZ   mul_tail_two

	ANDQ $1, TAIL
	JZ   mul_end

mul_tail_one:
	MOVSD (X_PTR), X0 // X_i = src[i*incSrc]
	MULSD (Y_PTR), X0 // X_i *= dst[i*incDst]
	MOVSD X0, (DST)   // dst[i*incDst] = X_i

mul_end:
	MOVQ dst_len+8(FP), R8
	MOVQ dst_cap+16(FP), R9
	MOVQ R8, ret_len+136(FP)
	MOVQ R9, ret_cap+144(FP)
	RET
