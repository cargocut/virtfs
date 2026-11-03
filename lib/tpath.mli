(* Copyright (c) 2026, Cargocut and the Virtfs developers. All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(* Describes path that can hold capabilities. *)

(** {1 Types}

    A Path quand be virtual, or holding [readable] or [writable]
    capabilites.contents
    - Virtual path are just path computed {i virtually}, like for representing
      the path located on a server. So it can't be [readable] nor [writable]
      (because it does not exists).
    - Concrete path are non-virtual path that can hold [readable] or [writable]
      capabilities. *)

type (!'concrete, !'readable, !'writable) t
(** A type that held capabilities. Capabilities are materialized by
    {!type:Tbool.yes} and {!type:Tbool.no}. *)

type ('readable, 'writable) c = (Tbool.yes, 'readable, 'writable) t
(** Describe {b concrete path} (or non-virtual). Since the path is not virtual,
    it can hold [readable] and [writable] capabilities. *)

type v = (Tbool.no, Tbool.no, Tbool.no) t
(** Describe a {b virtual path} where every capabilities are closed. *)

type packed =
  | Packed : ('concrete, 'readable, 'writable) t -> packed
      (** A type for packing path, hidding all type parameters (for dealing with
          batch on path). *)

(** {1 Building path} *)

val c :
     readable:'readable Tbool.t
  -> writable:'writable Tbool.t
  -> Path.t
  -> ('readable, 'writable) c
(** [c path] build a {b concrete path} on top of {!type:Path.t} with specific
    given [readable] and [writable] capabilities. *)

val v : Path.t -> v
(** [v path] build a {b virtual path} on top of {!type:Path.t}. *)

val as_concrete :
     readable:'readable Tbool.t
  -> writable:'writable Tbool.t
  -> bool * bool * Path.t
  -> ('readable, 'writable) c option
(** [as_concrete ~readable ~writable (should_be_readable, should_be_writable,
     path)] attempts to construct a concrete path where the first two Boolean
    values of the pair are used to validate whether a path meets the expected
    capabilities. Useful for constructing paths that have been dumped to disk.
*)

val as_virtual : bool * bool * Path.t -> v option
(** [as_virtual (should_be_readable, should_be_writable, path)] attempts to
    construct a virtual path where both flags must be set to [false]. Useful for
    constructing paths that have been dumped to disk. *)

val pack : ('concrete, 'readable, 'writable) t -> packed
(** [pack path] hide every type parameters. *)

(** {1 Info of path} *)

val is_concrete : ('concrete, 'readable, 'writable) t -> bool
(** [is_concrete path] returns [true] if the given [path] is concrete, [false]
    otherwise. *)

val is_virtual : ('concrete, 'readable, 'writable) t -> bool
(** [is_virtual path] returns [true] if the given [path] is virtual, [false]
    otherwise. *)

val is_readable : ('concrete, 'readable, 'writable) t -> bool
(** [is_readable path] returns [true] if the given [path] is readable, [false]
    otherwise. *)

val is_writable : ('concrete, 'readable, 'writable) t -> bool
(** [is_writable path] returns [true] if the given [path] is writable, [false]
    otherwise. *)

val path : ('concrete, 'readable, 'writable) t -> Path.t
(** [path p] returns the raw {!type:Path.t} for the given path [p]. *)

(** {1 Operation on path} *)

val map :
     (Path.t -> Path.t)
  -> ('concrete, 'readable, 'writable) t
  -> ('concrete, 'readable, 'writable) t
(** [map f path] apply [f] of the underlying {!type:Path.t} representation and
    preserve the original capabilities of the given [path]. *)

val from :
     ('concrete, 'readable, 'writable) t
  -> string list
  -> ('concrete, 'readable, 'writable) t
(** [from path fragments] calculate a new path (whilst preserving its
    capabilities) by adding the list of given [fragments] to the given [path].
*)

(** {1 Misc} *)

val equal :
     ('concrete, 'readable, 'writable) t
  -> ('concrete, 'readable, 'writable) t
  -> bool
(** [equal a b] equality between {!val:t}. *)
