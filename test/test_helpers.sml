(* test_helpers.sml -- real01 / intRange / bool / shuffle *)

structure HelperTests =
struct
  open Support

  structure R = SplitMix64

  fun run () =
    let
      val _ = Harness.section "real01 range"
      (* draw a batch; all in [0,1) *)
      fun drawReals (0, _, acc) = List.rev acc
        | drawReals (k, s, acc) =
            let val (r, s') = R.real01 s in drawReals (k-1, s', r::acc) end
      val reals = drawReals (1000, R.seed 0w12345, [])
      val () = Harness.check "real01 in [0,1)"
                 (List.all (fn r => r >= 0.0 andalso r < 1.0) reals)
      (* reproducible *)
      val (r1, _) = R.real01 (R.seed 0w7)
      val (r2, _) = R.real01 (R.seed 0w7)
      val () = Harness.check "real01 reproducible" (Real.== (r1, r2))

      val _ = Harness.section "intRange bounds"
      fun drawInts (lo, hi) (0, _, acc) = List.rev acc
        | drawInts (lo, hi) (k, s, acc) =
            let val (n, s') = R.intRange (lo, hi) s
            in drawInts (lo, hi) (k-1, s', n::acc) end
      val ns = drawInts (10, 20) (2000, R.seed 0w99, [])
      val () = Harness.check "intRange within [lo,hi]"
                 (List.all (fn n => n >= 10 andalso n <= 20) ns)
      (* hits both endpoints over enough draws *)
      val () = Harness.check "intRange hits lo" (List.exists (fn n => n = 10) ns)
      val () = Harness.check "intRange hits hi" (List.exists (fn n => n = 20) ns)
      (* reproducible *)
      val (i1, _) = R.intRange (0, 1000000) (R.seed 0w3)
      val (i2, _) = R.intRange (0, 1000000) (R.seed 0w3)
      val () = Harness.checkInt "intRange reproducible" (i1, i2)

      val _ = Harness.section "intRange edge cases"
      (* lo = hi -> single value, no modulo-by-zero *)
      val (single, _) = R.intRange (5, 5) (R.seed 0w0)
      val () = Harness.checkInt "intRange lo=hi" (5, single)
      (* negative ranges work *)
      val negs = drawInts (~5, 5) (500, R.seed 0w77, [])
      val () = Harness.check "intRange negative span within bounds"
                 (List.all (fn n => n >= ~5 andalso n <= 5) negs)
      (* lo > hi raises Domain *)
      val () = Harness.checkRaises "intRange lo>hi raises"
                 (fn () => R.intRange (5, 4) (R.seed 0w0))

      val _ = Harness.section "bool"
      fun drawBools (0, _, t, f) = (t, f)
        | drawBools (k, s, t, f) =
            let val (b, s') = R.bool s
            in drawBools (k-1, s', (if b then t+1 else t), (if b then f else f+1)) end
      val (trues, falses) = drawBools (10000, R.seed 0w555, 0, 0)
      val () = Harness.check "bool produces both values"
                 (trues > 0 andalso falses > 0)
      (* roughly balanced: within 10% of 50/50 over 10k draws (deterministic) *)
      val () = Harness.check "bool ~ balanced"
                 (Int.abs (trues - falses) < 1000)

      val _ = Harness.section "shuffle"
      val input = List.tabulate (20, fn i => i)
      val (shuffled, _) = R.shuffle input (R.seed 0w2024)
      (* same multiset (sorting both gives the original) *)
      fun insert (x, []) = [x]
        | insert (x, y::ys) = if x <= y then x::y::ys else y :: insert (x, ys)
      val sortedShuffle = List.foldr insert [] shuffled
      val () = Harness.checkIntList "shuffle is a permutation"
                 (input, sortedShuffle)
      (* reproducible for fixed seed *)
      val (sh2, _) = R.shuffle input (R.seed 0w2024)
      val () = Harness.checkIntList "shuffle reproducible" (shuffled, sh2)
      (* empty and singleton are no-ops *)
      val (e, _) = R.shuffle ([] : int list) (R.seed 0w1)
      val () = Harness.checkIntList "shuffle empty" ([], e)
      val (sgl, _) = R.shuffle [42] (R.seed 0w1)
      val () = Harness.checkIntList "shuffle singleton" ([42], sgl)
    in
      ()
    end
end
