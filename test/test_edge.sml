(* test_edge.sml -- seeding and arithmetic edge cases *)

structure EdgeTests =
struct
  open Support

  fun run () =
    let
      val _ = Harness.section "all-zero seed handling"
      (* xoshiro must NOT be seeded all-zero; the splitmix seeding path means
         seed 0 still yields a non-degenerate (non-constant) stream. *)
      val xo = takeWords Xoshiro256ss.next 4 (Xoshiro256ss.seed 0w0)
      val () = Harness.check "xoshiro seed 0 is not all-zero output"
                 (List.exists (fn w => w <> 0w0) xo)
      val () = Harness.check "xoshiro seed 0 not constant"
                 (case xo of a::b::_ => a <> b | _ => false)
      (* splitmix64 seed 0 first output is the known nonzero constant *)
      val (sm0, _) = SplitMix64.next (SplitMix64.seed 0w0)
      val () = Harness.check "splitmix64 seed 0 nonzero" (sm0 <> 0w0)

      val _ = Harness.section "intRange full-width / no overflow"
      (* a very large span must not overflow or loop forever *)
      val (big, _) = SplitMix64.intRange (0, valOf Int.maxInt - 1) (SplitMix64.seed 0w1)
      val () = Harness.check "intRange large span in bounds"
                 (big >= 0 andalso big <= valOf Int.maxInt - 1)
      (* range of width 1 (lo,lo+1) only yields lo or lo+1 *)
      fun draw2 (0,_,acc)=acc | draw2 (k,s,acc) =
        let val (n,s') = SplitMix64.intRange (0,1) s in draw2 (k-1, s', n::acc) end
      val twos = draw2 (200, SplitMix64.seed 0w5, [])
      val () = Harness.check "intRange width-2 only {0,1}"
                 (List.all (fn n => n = 0 orelse n = 1) twos)
      val () = Harness.check "intRange width-2 hits 0" (List.exists (fn n=>n=0) twos)
      val () = Harness.check "intRange width-2 hits 1" (List.exists (fn n=>n=1) twos)

      val _ = Harness.section "Word64 masking parity"
      (* High-bit shifts and multiplies must wrap mod 2^64 identically on
         both compilers; the golden vectors above already pin this, but assert
         a direct wrap here too. *)
      val hi = Word64.<< (0w1, 0w63)
      val () = Harness.check "1<<63 has only the top bit set"
                 (Word64.fmt StringCvt.HEX hi = "8000000000000000")
      val () = Harness.check "(1<<63)*2 wraps to 0"
                 (Word64.* (hi, 0w2) = 0w0)
      val () = Harness.check "maxWord + 1 wraps to 0"
                 (Word64.+ (0wxFFFFFFFFFFFFFFFF, 0w1) = 0w0)
    in
      ()
    end
end
