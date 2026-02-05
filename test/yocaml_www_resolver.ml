(* Copyright (c) 2026, Cargocut and the Virtfs developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(* open Test_util *)

(* module Resolver : sig *)
(*   (\* Replicates the behaviour of a simple resolver, inspired by the *)
(*      YOCaml website. *\) *)

(*   type t *)

(*   val make : ?source:Path.t -> ?target:Path.t -> ?server:Path.t -> unit -> t *)
(*   val binary : Path.t *)

(*   module Source : sig *)
(*     val config : t -> Path.t *)
(*   end *)

(*   module Target : sig *)
(*     val assets : t -> Path.t *)
(*   end *)

(*   module Server : sig *)
(*     val from_target : t -> Path.t -> Path.t *)
(*   end *)
(* end = struct *)
(*   type t = *)
(*     { source : Path.t *)
(*     ; target : Path.t *)
(*     ; server : Path.t *)
(*     } *)

(*   let make *)
(*         ?(source = Path.cwd) *)
(*         ?(target = Path.rel [ "_www" ]) *)
(*         ?(server = Path.root) *)
(*         () *)
(*     = *)
(*     { source; target; server } *)
(*   ;; *)

(*   let binary = Path.from_string Sys.executable_name *)

(*   module Source = struct *)
(*     let source { source; _ } = source *)
(*     let config r = Path.(source r / "configuration.toml") *)
(*   end *)

(*   module Target = struct *)
(*     let target { target; server; _ } = Path.concat ~into:target server *)
(*     let assets r = Path.(target r / "static") *)
(*   end *)

(*   module Server = struct *)
(*     let server { server; _ } = server *)
(*     let from_target _r _p = assert false *)
(*   end *)
(* end *)

(* let%expect_test "Test binary name" = *)
(*   Resolver.binary |> Path.basename |> print_endline; *)
(*   [%expect {| inline-test-runner.exe |}] *)
(* ;; *)
