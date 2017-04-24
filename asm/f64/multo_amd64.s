// Copyright ©2017 The gonum Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//+build !noasm,!appengine

#include "textflag.h"

// func MulTo(dst, x, y []float64)
TEXT ·MulTo(SB), NOSPLIT, $0
	MOVQ    dst_base+0(FP), DI // DI = &dst
	MOVQ    dst_len+8(FP), CX  // CX = len(dst)
	MOVQ    x_base+24(FP), SI  // SI = &x
	MOVQ    y_base+48(FP), DX  // DX = &y
	CMPQ    x_len+32(FP), CX   // CX = max( len(dst), len(x), len(y) )
	CMOVQLE x_len+32(FP), CX
	CMPQ    y_len+56(FP), CX
	CMOVQLE y_len+56(FP), CX
	MOVQ    CX, ret_len+80(FP) // len(ret) = CX
	CMPQ    CX, $0             // if CX == 0 { return }
	JE      mul_end
	XORQ    AX, AX             // i = 0
	MOVQ    DX, BX
	ANDQ    $15, BX            // BX = &dst & OxF
	JZ      mul_no_trim        // if BX == 0 { goto div_no_trim }

	// Align on 16-bit boundary
	MOVSD (SI)(AX*8), X0 // X0 = s[i]
	MULSD (DX)(AX*8), X0 // X0 *= t[i]
	MOVSD X0, (DI)(AX*8) // dst[i] = X0
	INCQ  AX             // i++
	DECQ  CX             // --CX
	JZ    mul_end        // if CX == 0 { return }

mul_no_trim:
	MOVQ CX, BX
	ANDQ $7, BX         // BX = len(dst) % 8
	SHRQ $3, CX         // CX = floor( len(dst) / 8 )
	JZ   mul_tail_start // if CX == 0 { goto div_tail_start }

mul_loop: // Loop unrolled 8x   do {
	MOVUPS (SI)(AX*8), X0   // X0 = x[i:i+1]
	MOVUPS 16(SI)(AX*8), X1
	MOVUPS 32(SI)(AX*8), X2
	MOVUPS 48(SI)(AX*8), X3
	MULPD  (DX)(AX*8), X0   // X0 *= y[i:i+1]
	MULPD  16(DX)(AX*8), X1
	MULPD  32(DX)(AX*8), X2
	MULPD  48(DX)(AX*8), X3
	MOVUPS X0, (DI)(AX*8)   // dst[i:i+1] = X0
	MOVUPS X1, 16(DI)(AX*8)
	MOVUPS X2, 32(DI)(AX*8)
	MOVUPS X3, 48(DI)(AX*8)
	ADDQ   $8, AX           // i += 8
	DECQ   CX
	JNZ    mul_loop         // } while --CX > 0
	CMPQ   BX, $0           // if BX == 0 { return }
	JE     mul_end

mul_tail_start: // Reset loop registers
	MOVQ BX, CX       // Loop counter: CX = BX
	SHRQ $1, CX       // CX = floor( CX / 2 )
	JZ   mul_tail_one // if CX == 0 { goto mul_tail_one }

mul_tail_two: // do {
	MOVUPS (SI)(AX*8), X0 // X0 = x[i:i+1]
	MULPD  (DX)(AX*8), X0 // X0 *= y[i:i+1]
	MOVUPS X0, (DI)(AX*8) // dst[i:i+1] = X0
	ADDQ   $2, AX         // i++
	DECQ   CX
	JNZ    mul_tail_two   // } while --CX > 0

	ANDQ $1, BX  // BX &= 1
	JZ   mul_end // if BX == 0 { goto mul_end }

mul_tail_one:
	MOVSD (SI)(AX*8), X0 // X0  = x[i]
	MULSD (DX)(AX*8), X0 // X0 *= y[i]
	MOVSD X0, (DI)(AX*8)

mul_end:
	MOVQ DI, ret_base+72(FP) // &ret = &dst
	MOVQ dst_cap+16(FP), DI  // cap(ret) = cap(dst)
	MOVQ DI, ret_cap+88(FP)
	RET
