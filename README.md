# sml-prng

Seedable, deterministic, **byte-identical** pseudo-random number generators in
pure Standard ML — no FFI, no external dependencies, identical streams under
both [MLton](http://mlton.org/) and [Poly/ML](https://www.polyml.org/).

Three generators, all behind one `RANDOM` signature:

- **SplitMix64** — fast, single-word state; also used to seed the others.
- **xoshiro256\*\*** — Blackman & Vigna, four-word state, excellent quality.
- **pcg32** — O'Neill's PCG XSH-RR 64/32.

Each one reproduces its **published reference output vectors exactly**, so a
seed pins the same stream everywhere — across runs, machines, and both
compilers. All arithmetic is on masked `Word64.word`, which is why MLton and
Poly/ML (with its 63-bit native int) agree bit-for-bit.

## Status

- 33 assertions (including golden-vector tests), green on MLton and Poly/ML.
- Basis-library only; deterministic across compilers.

## Install

With [`smlpkg`](https://github.com/diku-dk/smlpkg):

```
smlpkg add github.com/sjqtentacles/sml-prng
smlpkg sync
```

Include the MLB from your own:

```
local
  $(SML_LIB)/basis/basis.mlb
  lib/github.com/sjqtentacles/sml-prng/prng.mlb
in
  ...
end
```

This brings `signature RANDOM` and structures `SplitMix64`, `Xoshiro256ss`,
`Pcg32` into scope.

## Quick start

```sml
(* Generators are pure: thread the returned state. *)
val s0 = Xoshiro256ss.seed 0w12345
val (w1, s1) = Xoshiro256ss.next s0      (* a Word64 *)
val (r,  s2) = Xoshiro256ss.real01 s1    (* a real in [0,1) *)
val (n,  s3) = Xoshiro256ss.intRange (1, 6) s2   (* a dice roll, unbiased *)
val (b,  s4) = Xoshiro256ss.bool s3

(* Shuffle a list reproducibly. *)
val (deck, _) = Pcg32.shuffle (List.tabulate (52, fn i => i)) (Pcg32.seed 0w7)
```

Because everything is pure, the same seed always yields the same stream:

```sml
val (a, _) = SplitMix64.words 5 (SplitMix64.seed 0w0)
val (b, _) = SplitMix64.words 5 (SplitMix64.seed 0w0)
(* a = b *)
```

## The `RANDOM` signature

| Function | Meaning |
| --- | --- |
| `seed : Word64.word -> state` | seed a generator |
| `next : state -> word * state` | core step: output word + next state |
| `real01 : state -> real * state` | a real in `[0, 1)` (top 53 bits) |
| `bool : state -> bool * state` | a boolean (top bit) |
| `intRange : int * int -> state -> int * state` | unbiased int in `[lo, hi]` |
| `words : int -> state -> word list * state` | first `n` outputs |
| `shuffle : 'a list -> state -> 'a list * state` | Fisher–Yates permutation |

### Conventions

- Generators are **pure functions**; there is no hidden mutable state. Thread
  the returned `state` to advance the stream.
- `intRange` uses rejection sampling, so the distribution is unbiased; it
  raises `Domain` if `lo > hi` and handles `lo = hi` without dividing by zero.
- xoshiro256\*\* and pcg32 are seeded through SplitMix64, so even an all-zero
  seed yields a healthy, non-degenerate stream.
- pcg32 uses the canonical reference stream selector (`seq = 54`), matching the
  official C demo's output for a given seed.

## Build & test

```
make test        # MLton
make test-poly   # Poly/ML
make all-tests   # both
make example     # build + run the demo
make clean
```

## Example

[`examples/demo.sml`](examples/demo.sml) seeds each generator with a fixed
constant and prints the first words in hex, followed by ten unbiased dice rolls
and a Fisher–Yates shuffle. Because the generators are pure and masked to
`Word64`, the output is identical on every run and on both compilers (the hex
words match each generator's published reference vectors). Run it with:

```
$ make example
SplitMix64 (seed 0):   E220A8397B1DCDAF 6E789E6AA1B965F4 06C45D188009454F F88BB8A8724C81EC 1B39896A51A8749B
Xoshiro256** (seed 0): 99EC5F36CB75F2B4 BF6E1F784956452A 1A5F849D4933E6E0 6AA594F1262D2D2C BBA5AD4A1F842E59
Pcg32 (seed 42):       A15C02B7 7B47F409 BA1D3330 83D2F293 BFA4784B CBED606E
10 dice rolls (seed 12345): 3 4 4 1 4 5 3 3 2 2
shuffle 1..10 (seed 777):   8 6 4 2 1 7 3 9 10 5
```

## License

MIT — see [LICENSE](LICENSE).
