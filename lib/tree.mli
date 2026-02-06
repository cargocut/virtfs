(* Copyright (c) 2026, Cargocut and the Virtfs developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

type 'a item
type 'a t

val dir : name:string -> 'a item list -> 'a item
val file : name:string -> 'a -> 'a item
val make : ?scope:Path.t -> 'a item list -> 'a t
val from_root : 'a item list -> 'a t
val from_cwd : 'a item list -> 'a t
val ls : 'a t -> string list
val tree : 'a t -> string
val is_file : 'a item -> bool
val is_directory : 'a item -> bool
val children : 'a item -> 'a item list
val fetch : 'a t -> Path.t -> 'a item option

(* TODO: Probably to be removed (when the API will be completed). *)
val content : 'a item -> [ `Content of 'a | `Tree of 'a item list ]
val name : 'a item -> string
