(* Copyright (c) 2026, Cargocut and the Virtfs developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(** Utilities for dumping information on standard output for use with,
    among other things, {{:https://ocaml.org/p/ppx_expect/latest}
    ppx_expect}. *)

(** [dump_option] dump ["None"] or ["Some (f x)"]. *)
val dump_option : ('a -> string) -> 'a option -> unit

(** [dump_path p] uses {!val:Virtfs.Path.to_string} for dumping a
    path. *)
val dump_path : Path.t -> unit

(** [dump_bool b] dump the given bool [b]. *)
val dump_bool : bool -> unit

(** [dump_path_set ps] dump the given [ps]. *)
val dump_path_set : Path.Set.t -> unit

(** [dump_path_map ps] dump the given [ps]. *)
val dump_path_map
  :  ('metadata -> string)
  -> (string, 'metadata) Item.t Path.Map.t
  -> unit
