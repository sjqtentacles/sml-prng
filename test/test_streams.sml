(* test_streams.sml -- golden-vector tests against published references.

   These are the load-bearing tests: they pin determinism AND cross-compiler
   identity. The expected values are the canonical reference outputs for each
   generator. *)

structure StreamTests =
struct
  open Support

  (* splitmix64, seed = 0: the widely-published reference sequence. *)
  val splitmix64_seed0 : Word64.word list =
    [ 0wxE220A8397B1DCDAF
    , 0wx6E789E6AA1B965F4
    , 0wx06C45D188009454F
    , 0wxF88BB8A8724C81EC
    , 0wx1B39896A51A8749B ]

  (* xoshiro256**, state seeded from splitmix64(0). *)
  val xoshiro_seed0 : Word64.word list =
    [ 0wx99EC5F36CB75F2B4
    , 0wxBF6E1F784956452A
    , 0wx1A5F849D4933E6E0
    , 0wx6AA594F1262D2D2C
    , 0wxBBA5AD4A1F842E59 ]

  (* pcg32, seed = 42, default stream selector seq = 54: official C demo. *)
  val pcg32_seed42 : Word64.word list =
    [ 0wxA15C02B7
    , 0wx7B47F409
    , 0wxBA1D3330
    , 0wx83D2F293
    , 0wxBFA4784B
    , 0wxCBED606E ]

  fun run () =
    let
      val _ = Harness.section "SplitMix64 golden (seed 0)"
      val sm = takeWords SplitMix64.next 8 (SplitMix64.seed 0w0)
      val () = checkWords "splitmix64 first 5"
                 (splitmix64_seed0, List.take (sm, 5))

      val _ = Harness.section "Xoshiro256** golden (seed 0)"
      val xo = takeWords Xoshiro256ss.next 5 (Xoshiro256ss.seed 0w0)
      val () = checkWords "xoshiro256** first 5" (xoshiro_seed0, xo)

      val _ = Harness.section "Pcg32 golden (seed 42, seq 54)"
      val pc = takeWords Pcg32.next 6 (Pcg32.seed 0w42)
      val () = checkWords "pcg32 first 6" (pcg32_seed42, pc)

      val _ = Harness.section "determinism / reproducibility"
      (* same seed -> same stream *)
      val () = checkWords "splitmix64 reproducible"
                 (takeWords SplitMix64.next 8 (SplitMix64.seed 0wx1234),
                  takeWords SplitMix64.next 8 (SplitMix64.seed 0wx1234))
      val () = checkWords "xoshiro reproducible"
                 (takeWords Xoshiro256ss.next 8 (Xoshiro256ss.seed 0wx1234),
                  takeWords Xoshiro256ss.next 8 (Xoshiro256ss.seed 0wx1234))
      val () = checkWords "pcg32 reproducible"
                 (takeWords Pcg32.next 8 (Pcg32.seed 0wx1234),
                  takeWords Pcg32.next 8 (Pcg32.seed 0wx1234))
      (* different seeds -> different streams *)
      val a = takeWords SplitMix64.next 4 (SplitMix64.seed 0w1)
      val b = takeWords SplitMix64.next 4 (SplitMix64.seed 0w2)
      val () = Harness.check "different seeds differ" (a <> b)

      val _ = Harness.section "words helper matches next"
      val (ws, _) = SplitMix64.words 5 (SplitMix64.seed 0w0)
      val () = checkWords "words n = first n nexts"
                 (List.take (sm, 5), ws)
    in
      ()
    end
end
