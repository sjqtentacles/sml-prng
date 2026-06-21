(* support.sml -- shared helpers for prng tests. *)

structure Support =
struct
  (* Collect the first n outputs of a generator's `next` from a seeded state. *)
  fun takeWords next n s0 =
    let
      fun loop (0, _, acc) = List.rev acc
        | loop (k, s, acc) =
            let val (w, s') = next s in loop (k - 1, s', w :: acc) end
    in
      loop (n, s0, [])
    end

  fun hexList ws = List.map (fn w => Word64.fmt StringCvt.HEX w) ws

  fun checkWords name (expected, actual) =
    Harness.checkStringList name (hexList expected, hexList actual)
end
