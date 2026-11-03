(* Copyright (c) 2026, Cargocut and the Virtfs developers. All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(** Describes a scope, to prevent operations on paths that do not comply with
    the scope. *)

(** The idea behind scopes is that they are specialised by modules (to prevent
    arbitrary scopes from being created and to enforce existing scopes). Here,
    we only provide the {i low-level} API to validate that paths comply with
    scopes. *)

(** {1 Types}

    A scope consists of a main path and a list of excluded paths. (For example,
    if my main path is the [cwd], and I have certain scopes within the [cwd],
    those scopes should be excluded.) *)

type (!'concrete, !'readable, !'writable) t
(** Describes the type of a scope (that should share capabilities with a path.
    This is why capabilities are reflected into the type definition). *)

(** {2 Errors} *)

(** Errors that may occur whilst validating a path for a scope. There are two
    possible scenarios:
    - the path is not a child of the given scope
    - the path is scoped by one of the paths in the exclusion list *)
type error =
  | Unscoped_by of { scope : Path.t; path : Path.t }
  | Overlap_with of { path : Path.t; overlapping : Path.t }

(** {1 Working with scopes} *)

val make :
     ?exclusions:Path.t list
  -> ('concrete, 'readable, 'writable) Tpath.t
  -> ('concrete, 'readable, 'writable) t
(** [make ?exclusions path] creates a scope for a given [path], whilst
    preserving its capabilities (scopes and paths must share their capabilities)
    and with an optional list of excluded paths ([exclusions]). *)

val check :
     scope:('concrete, 'readable, 'writable) t
  -> ('concrete, 'readable, 'writable) Tpath.t
  -> (unit, error) result
(** [check ~scope path] ensures that the specified [path] complies with the
    specified [scope]. Since a scope should be a parent, we assume that scoping
    toa path that is the scope fail. *)
