(* Copyright (c) 2026, Cargocut and the Virtfs developers. All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(** Express a kind of boolean ([yes] or [no]) at the typelevel. *)

(** The main idea of this module is to have typelevel markers to express
    {i capabilites}. *)

(** {1 Types} *)

(** Describes [yes] at the type level, [true]. *)
type yes = Yes

(** Describes [no] at the type level, [false]. *)
type no = No

(** both [yes] or [no]. *)
type _ t = TYes : yes t | TNo : no t

(** {1 Building} *)

val yes : yes t
(** Build a value of {!type:t} as {!type:yes} *)

val no : no t
(** Build a value of {!type:t} as {!type:no} *)

(** {1 Conversion} *)

val to_bool : 'a t -> bool
(** [to_bool tbool] converts the given [tbool] to a regular [bool]. *)

(** {1 Misc} *)

val equal : 'a t -> 'a t -> bool
(** [equal a b] is the equality between {!type:t}. *)
