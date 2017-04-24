// Copyright ©2017 The gonum Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// +build go1.7

package f64

import (
	"fmt"
	"testing"
)

func BenchmarkMulInc(t *testing.B) {
	naiveMulInc := func(dst, src []float64, n, incSrc, incDst, iSrc, iDst int) {
		for i := 0; i < n; i++ {
			dst[iDst] *= src[iSrc]
			iDst += incDst
			iSrc += incSrc
		}
	}
	tests := []struct {
		name string
		f    func(x, y []float64, n, incX, incY, ix, iy int)
	}{
		{"MulInc", MulInc},
		{"NaiveMulInc", naiveMulInc},
	}
	for _, tst := range tests {
		for _, ln := range []int{1, 2, 3, 4, 5, 10, 100, 1e3, 5e3, 1e4, 5e4} {
			for _, tstInc := range []int{1, 2, 4, 10, -1, -2, -4, -10} {
				t.Run(fmt.Sprintf("%s-%d-inc(%d)", tst.name, ln, tstInc), func(b *testing.B) {
					b.SetBytes(int64(64 * ln))
					var idx int
					if tstInc < 0 {
						idx = (-ln + 1) * tstInc
					}
					for i := 0; i < b.N; i++ {
						tst.f(x, y, ln, tstInc, tstInc, idx, idx)
					}
				})
			}
		}
	}
}

func BenchmarkMulIncTo(t *testing.B) {
	naiveMulIncTo := func(dst, x, y []float64, n, incDst, incX, incY, iDst, ix, iy int) []float64 {
		for i := 0; i < n; i++ {
			dst[iDst] = x[ix] * y[iy]
			iDst += incDst
			ix += incX
			iy += incY
		}
		return dst
	}
	tests := []struct {
		name string
		f    func(dst, x, y []float64, n, incDst, incX, incY, iDst, ix, iy int) []float64
	}{
		{"MulIncTo", MulIncTo},
		{"NaiveMulIncTo", naiveMulIncTo},
	}
	for _, tst := range tests {
		for _, ln := range []int{1, 2, 3, 4, 5, 10, 100, 1e3, 5e3, 1e4, 5e4} {
			for _, tstInc := range []int{1, 2, 4, 10, -1, -2, -4, -10} {
				t.Run(fmt.Sprintf("%s-%d-inc(%d)", tst.name, ln, tstInc), func(b *testing.B) {
					b.SetBytes(int64(64 * ln))
					var idx int
					if tstInc < 0 {
						idx = (-ln + 1) * tstInc
					}
					for i := 0; i < b.N; i++ {
						tst.f(z, x, y, ln, tstInc, tstInc, tstInc, idx, idx, idx)
					}
				})
			}
		}
	}
}
