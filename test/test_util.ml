(* Copyright (c) 2026, Cargocut and the Virtfs developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

let dump_option f x =
  let s =
    match x with
    | None -> "None"
    | Some x -> "Some (" ^ f x ^ ")"
  in
  print_endline s
;;

let dump_bool = function
  | true -> print_endline "true"
  | false -> print_endline "false"
;;

let dump_path path = path |> Path.to_string |> print_endline
