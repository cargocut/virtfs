(* Copyright (c) 2026, Cargocut and the Virtfs developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(** Describe a Conflict resolution and arbitrage (for merging
    {!module:Tree}). *)

(** Adding an item where one already exists is a conflict. Two directories
    sharing a name are {b not} a conflict: they denote the same
    directory, so they are merged and the conflicts are looked for
    among their children. *)

(** {1 Types} *)

(** Describe a conflict resolution *)
type ('a, 'metadata) resolution =
  previous:('a, 'metadata) Item.t
  -> current:('a, 'metadata) Item.t
  -> Path.t
  -> ('a, 'metadata) Item.t list

(** Describes the dramatic abandonment (give up) of conflict resolution
    (to avoid having to wrap things up should the resolution fail). *)
type ('a, 'metadata) give_up =
  previous:('a, 'metadata) Item.t
  -> current:('a, 'metadata) Item.t
  -> Path.t
  -> [ `Previous | `Current | `Neither ]

(** {1 Predefined resolutions} *)

(** Keep the incomming file. *)
val keep_current : ('a, 'metadata) resolution

(** Keep the already present file. *)
val keep_previous : ('a, 'metadata) resolution

(** Discard both files. *)
val discard : ('a, 'metadata) resolution

(** Keep the previous, rename the current. *)
val rename_current : (string -> string) -> ('a, 'metadata) resolution

(** Keep the current, rename the previous. *)
val rename_previous : (string -> string) -> ('a, 'metadata) resolution

(** Rename both files. *)
val rename_both
  :  on_previous:(string -> string)
  -> on_current:(string -> string)
  -> ('a, 'metadata) resolution

(** {1 Predefined way to give up} *)

val retain : [ `Previous | `Current | `Neither ] -> ('a, 'metadata) give_up
