// Copyright ©2015 The gonum Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//+build !noasm,!appengine

#include "textflag.h"

#define SRC SI
#define DST DX
#define DST_W DI
#define IDX CX
#define LEN BX
#define TAIL BX
#define INC_SRC R8
#define INCx3_SRC R9
#define INC_DST R10
#define INCx3_DST R11

// func MulInc(dst, src []float64, n, incDst, incSrc, iDst, iSrc int)
TEXT ·MulInc(SB), NOSPLIT, $0
	MOVQ dst_base+0(FP), DST    // DST = &dst
	MOVQ src_base+24(FP), SRC   // SRC = &src
	MOVQ n+48(FP), LEN          // LEN = n
	CMPQ IDX, $0                // if n==0 { return }
	JE   mul_end
	MOVQ iDst+72(FP), INC_DST   // INC_DST = idst
	MOVQ iSrc+80(FP), INC_SRC   // INC_SRC = isrc
	LEAQ (DST)(INC_DST*8), DST  // DST = &(dst[iDst])
	LEAQ (SRC)(INC_SRC*8), SRC  // SRC = &(src[iSrc])
	MOVQ DST, DST_W             // DST_Write = DST    // Read/Write pointers
	MOVQ incDst+56(FP), INC_DST // INC_DST = incDst
	SHLQ $3, INC_DST            // INC_DST *= sizeof(float64)
	MOVQ incSrc+64(FP), INC_SRC // INC_SRC = incSrc
	SHLQ $3, INC_SRC            // INC_SRC *= sizeof(float64)

	MOVQ LEN, IDX
	ANDQ $3, TAIL // TAIL = LEN % 4
	SHRQ $2, IDX  // IDX = floor( LEN / 4 )
	JZ   mul_tail // if IDX == 0 { goto mul_tail }

	LEAQ (INC_DST)(INC_DST*2), INCx3_DST // INCx3_DST = 3 * INC_DST
	LEAQ (INC_SRC)(INC_SRC*2), INCx3_SRC // INCx3_SRC = 3 * INC_SRC

mul_loop: // do {
	MOVSD (SRC), X0              // X_i = src[i*incSrc]
	MOVSD (SRC)(INC_SRC*1), X1
	MOVSD (SRC)(INC_SRC*2), X2
	MOVSD (SRC)(INCx3_SRC*1), X3

	//	LEAQ (SRC)(INC_SRC*4), SRC
	//	MOVSD (SRC), X0
	//	MOVSD (SRC)(INC_SRC*1), X1
	//	MOVSD (SRC)(INC_SRC*2), X2
	//	MOVSD (SRC)(INCx3_SRC*1), X3

	MULSD (DST), X0              // X_i *= dst[i*incDst]
	MULSD (DST)(INC_DST*1), X1
	MULSD (DST)(INC_DST*2), X2
	MULSD (DST)(INCx3_DST*1), X3

	MOVSD X0, (DST_W)              // dst[i*incDst] = X_i
	MOVSD X1, (DST_W)(INC_DST*1)
	MOVSD X2, (DST_W)(INC_DST*2)
	MOVSD X3, (DST_W)(INCx3_DST*1)

	LEAQ (SRC)(INC_SRC*4), SRC     // SRC = &(SRC[ incSrc*4 ])
	LEAQ (DST)(INC_DST*4), DST     // DST = &(DST[ incDst*4 ])
	LEAQ (DST_W)(INC_DST*4), DST_W // DST_W = &(DST_W[ incDst*4 ])

	DECQ IDX
	JNZ  mul_loop
	CMPQ TAIL, $0
	JE   mul_end

mul_tail:
	MOVQ TAIL, IDX
	SHRQ $1, IDX      // IDX = floor( TAIL / 2 )
	JZ   mul_tail_one

mul_tail_two:
	MOVSD (SRC), X0                 // X_i = src[i*incSrc]
	MOVSD (SRC)(INC_SRC*1), X1
	MULSD (DST), X0                 // X_i *= dst[i*incDst]
	MULSD (DST)(INC_DST*1), X1
	MOVSD X0, (DST_W)               // dst[i*incDst] = X_i
	MOVSD X1, (DST_W)(INC_DST*1)
	LEAQ  (SRC)(INC_SRC*2), SRC
	LEAQ  (DST)(INC_DST*2), DST
	LEAQ  (DST_W)(INC_DST*2), DST_W
	DECQ  IDX
	JNZ   mul_tail_two

	ANDQ $1, TAIL
	JZ   mul_end

mul_tail_one:
	MOVSD (SRC), X0   // X_i = src[i*incSrc]
	MULSD (DST), X0   // X_i *= dst[i*incDst]
	MOVSD X0, (DST_W) // dst[i*incDst] = X_i

mul_end:
	RET
