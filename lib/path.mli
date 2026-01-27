(* Copyright (c) 2026, Cargocut and the Virtfs developpers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(** A path {!type:Path.t} is a {i lax} representation of a file path in
    an abstract file system. It can be used to describe, abstractly,
    operations on file paths and to mock file systems.

    The library does not focus on the {i correctness} of paths, but aims
    to provide a simple and composable API for quickly expressing file
    paths in systems that abstract the execution target (e.g. in
    {{:https://yocaml.github.io/tutorial} YOCaml}).

    Unlike {{:https://erratique.ch/software/fpath} Fpath}, there is no
    distinction (in terms of representation) between directories and
    files. *)

(** {1 Representation} *)

(** The type describing a file path, which can be
    {{!val:Path.is_absolute} absolute} or {{!val:Path.is_relative}
    relative}. *)
type t

(** [abs ["foo"; "bar"]] builds the path ["/foo/bar"]. *)
val abs : string list -> t

(** [rel ["foo"; "bar"]] builds the path ["./foo/bar"]. *)
val rel : string list -> t

(** {1 Predicates}

    Predicates on file paths. *)

(** [is_absolute p] returns [true] if [p] is defined as an absolute
    path, [false] otherwise. *)
val is_absolute : t -> bool

(** [is_relative p] returns [true] if [p] is defined as a relative
    path, [false] otherwise. *)
val is_relative : t -> bool

(** [equal p1 p2] returns [true] if [p1 = p2], [false] otherwise. *)
val equal : t -> t -> bool

(** [compare p1 p2] returns [0] if [p1] is equal to [p2], a negative
    integer if [p1] is less than [p2], and a positive integer if [p1]
    is greater than [p2]. {b It is always assumed that a relative path
    is shorter than an absolute path} then the lexicographical order
    is chosen. *)
val compare : t -> t -> int
