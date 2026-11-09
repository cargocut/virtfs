(* Copyright (c) 2026, Cargocut and the Virtfs developers. All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(** Describes path that can hold capabilities. *)

(** {1 Types}

    A Path can be virtual, or holding [readable] or [writable] capabilites:
    - Virtual path are just path computed {i virtually}, like for representing
      the path located on a server. So it can't be [readable] nor [writable]
      (because it does not exists).
    - Concrete path are non-virtual path that can hold [readable] or [writable]
      capabilities.

    Concrete files are, in effect, {i statable}; one can query them for
    information such as, for example, their modification date. *)

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
(** [c ~readable ~writable path] build a {b concrete path} on top of
    {!type:Path.t} with specific given [readable] and [writable] capabilities.
*)

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

(** {2 Attenuation}

    Functions to {i attenuate} the capabilities of a path. An attenuation can
    only remove capabilities, never grant them, so it is always safe to give an
    attenuated path to code that should be less privileged. *)

val revoke_read : ('readable, 'writable) c -> (Tbool.no, 'writable) c
(** [revoke_read path] removes the [readable] capability of the given concrete
    [path], preserving its other capabilities. The resulting path can still be
    observed (see {!val:is_concrete}) and written if it was writable. *)

val revoke_write : ('readable, 'writable) c -> ('readable, Tbool.no) c
(** [revoke_write path] removes the [writable] capability of the given concrete
    [path], preserving its other capabilities. The resulting path can still be
    observed and read if it was readable. *)

val observe_only : ('readable, 'writable) c -> (Tbool.no, Tbool.no) c
(** [observe_only path] removes both [readable] and [writable] capabilities of
    the given concrete [path]. The resulting path remains concrete: it can only
    be observed (existence, modification time, kind) but neither read nor
    written. Useful to track a dependency without being able to read its
    content. *)

val virtualize : ('concrete, 'readable, 'writable) t -> v
(** [virtualize path] forgets every capability of the given [path], including
    its concreteness. The resulting path is purely {i virtual}: it can still be
    manipulated as a path (see {!val:map}) but no longer refers to anything that
    can be observed, read or written. Useful to compute, for example, a target
    URL from a source file. *)

(** {1 Misc} *)

val equal :
     ('concrete, 'readable, 'writable) t
  -> ('concrete, 'readable, 'writable) t
  -> bool
(** [equal a b] equality between {!type:t}. *)
