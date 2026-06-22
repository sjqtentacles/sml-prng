(* demo.sml - seedable, pure pseudo-random generators. Each generator is seeded
   with a FIXED constant, so the streams are reproducible: the same words come
   out on every run and (since all arithmetic is masked Word64) on both
   compilers. Output is raw words in hex plus a couple of derived helpers
   (integer dice rolls, a shuffle), all integers/strings -- no reals printed. *)

structure SM = SplitMix64
structure XO = Xoshiro256ss
structure PC = Pcg32

fun hex width w = StringCvt.padLeft #"0" width (Word64.toString w)

val (sm, _) = SM.words 5 (SM.seed 0w0)
val () = print ("SplitMix64 (seed 0):   "
                ^ String.concatWith " " (List.map (hex 16) sm) ^ "\n")

val (xo, _) = XO.words 5 (XO.seed 0w0)
val () = print ("Xoshiro256** (seed 0): "
                ^ String.concatWith " " (List.map (hex 16) xo) ^ "\n")

val (pc, _) = PC.words 6 (PC.seed 0w42)
val () = print ("Pcg32 (seed 42):       "
                ^ String.concatWith " " (List.map (hex 8) pc) ^ "\n")

(* Unbiased integers in [1, 6], threading the pure state through ten draws. *)
fun roll 0 _ acc = List.rev acc
  | roll k st acc =
      let val (r, st') = SM.intRange (1, 6) st
      in roll (k - 1) st' (r :: acc) end
val dice = roll 10 (SM.seed 0w12345) []
val () = print ("10 dice rolls (seed 12345): "
                ^ String.concatWith " " (List.map Int.toString dice) ^ "\n")

(* Fisher-Yates shuffle of a fixed list. *)
val (perm, _) = SM.shuffle [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] (SM.seed 0w777)
val () = print ("shuffle 1..10 (seed 777):   "
                ^ String.concatWith " " (List.map Int.toString perm) ^ "\n")
