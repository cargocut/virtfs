(* Copyright (c) 2026, Cargocut and the Virtfs developers.
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
    files.

    The API is generally pure, which explains why when we talk about
    "changing a path", moving it, etc., we are referring to
    calculating a new path; {b no operations are performed on the
    disk}. *)

(** {1 Representation} *)

(** The type describing a file path, which can be
    {{!val:Path.is_absolute} absolute} or {{!val:Path.is_relative}
    relative}. *)
type t

(** [abs ["foo"; "bar"]] builds the path ["/foo/bar"]. *)
val abs : string list -> t

(** [rel ["foo"; "bar"]] builds the path ["./foo/bar"]. *)
val rel : string list -> t

(** [root] is the root of the file system ["/"]. *)
val root : t

(** [cwd] is the current working directory ["./"]. *)
val cwd : t

(** {1 Manipulation of path} *)

(** [dirname p] returns the parent of [p]. The parent of [root] is
    [root] and the parent of [cwd] is ["../"]. *)
val dirname : t -> t

(** [basename p] returns the basename of [p]. The basename of [root]
    is ["/"] and the basename of [cwd] is ["."]. *)
val basename : t -> string

(** [basename_opt p] returns the basename of [p]. The basename of
    [root] and [cwd] is [None]. *)
val basename_opt : t -> string option

(** {1 Path relocation}

    Set of functions that enable the description of path movements. *)

(** [append p xs] append [xs] at the end of the given path [p]. *)
val append : t -> string list -> t

(** [move ~into source] calculate the path corresponding to the
    movement from path [source] to path [into].*)
val move : into:t -> t -> t

(** [relocate ?strategy ?ignore_kind ~into source] is like {!val:move},
    but relocates the full [source] path instead of only its basename.

    With [`Merge] (default), overlapping suffixes are merged:

    {@ocaml[
      # open Virtfs.Path ;;

      # (rel [ "bar"; "index.md" ])
        |> relocate ~into:(rel [ "foo"; "bar"; "baz" ])
        |> to_string ;;
      - : string = "./foo/bar/index.md"
    ]}

    With [`Force], [source] is appended as-is into [into].

    If [into] and [source] have different kinds ([Relative] vs [Absolute]),
    [`Force] is applied unless [ignore_kind] is [true]. *)
val relocate
  :  ?strategy:[ `Merge | `Force ]
  -> ?ignore_kind:bool
  -> into:t
  -> t
  -> t

(** [concat] is {!val:relocate} with [force] strategy. *)
val concat : into:t -> t -> t

(** [graft] is {!val:relocate} with [merge] strategy. *)
val graft : ?ignore_kind:bool -> into:t -> t -> t

(** [rename ?preserve_extension ~new_name p] calculate a new name for
    the given path [p]. The flag [preserve_extension] describes a
    strategy for preserving the extension of the source [p]. If it is
    not passed, the extension is ignored.

    - [`Ext] preserves the extension of the source (see
      {!val:extension})

    - [`Compound] preserves the extension of the source (see
      {!val:compound_extension}) *)
val rename
  :  ?preserve_extension:[ `Compound | `Ext ]
  -> new_name:string
  -> t
  -> t

(** {1 Extension}

    Dealing with file extensions. Since the library does not assume
    whether a file is a file or a directory, the functions generally
    work.

    An extension (returned) is always prefixed with a ["."]. *)

(** [extension p] returns the extension for the given path [p]. If the
    path has no extension, it returns an empty string. *)
val extension : t -> string

(** [extension_opt p] is like {!val:extension} but wrap the result
    into an option. So if a path has no extension, it returns
    [None]. *)
val extension_opt : t -> string option

(** [compound_extension p] returns the list of {i compound extension}
    for the given path [p]. *)
val compound_extension : t -> string list

(** [has_extension ext p] returns [true] if the path [p] has the
    extension [ext]. (It works on {b compound extension})*)
val has_extension : string -> t -> bool

(** [has_any_extension exts p] returns [true] if the path [p] has one of the
    extensions in [exts]. (It works on {b compound extension})*)
val has_any_extension : string list -> t -> bool

(** [remove_extension ?kind p] remove the extension of the given
    [p]. The [kind] can change the extension removal strategy:

    - [`Compound] Removes the compound extension.
    - [`Ext str] Remove the given extension. *)
val remove_extension : ?kind:[ `Compound | `Ext of string ] -> t -> t

(** [add_extension ext p] add the [ext] to the given path [p]. *)
val add_extension : string -> t -> t

(** [replace_extension ?kind ext p] replace the extension of [p] by
    [ext] (the previous extension is removed using
    {!val:remove_extension}) using the given [kind]). *)
val replace_extension : ?kind:[ `Compound | `Ext of string ] -> string -> t -> t

(** [change_extension] is {!val:replace_extension}. *)
val change_extension : ?kind:[ `Compound | `Ext of string ] -> string -> t -> t

(** {1 Predicates}

    Predicates on file paths. *)

(** [is_absolute p] returns [true] if [p] is defined as an absolute
    path, [false] otherwise. *)
val is_absolute : t -> bool

(** [is_relative p] returns [true] if [p] is defined as a relative
    path, [false] otherwise. *)
val is_relative : t -> bool

(** [is_root p] returns [true] if the path [p] {i seems to point} ["/"]. *)
val is_root : t -> bool

(** [is_cwd p] returns [true] if the path [p] {i seems to point} ["./"]. *)
val is_cwd : t -> bool

(** {1 Comparison} *)

(** [equal p1 p2] returns [true] if [p1 = p2], [false] otherwise. *)
val equal : t -> t -> bool

(** [compare p1 p2] returns [0] if [p1] is equal to [p2], a negative
    integer if [p1] is less than [p2], and a positive integer if [p1]
    is greater than [p2]. {b It is always assumed that a relative path
    is shorter than an absolute path} then the lexicographical order
    is chosen. *)
val compare : t -> t -> int

(** {1 Conversion} *)

(** [to_string p] returns the representation of the path [p]. *)
val to_string : t -> string

(** [from_string s] returns a path from the given string [s]. *)
val from_string : string -> t

(** [of_string] is {!val:from_string} - consistent with the OCaml
    ecosystem. *)
val of_string : string -> t

(** [fragments p] returns the list of segments/fragments for a given
    path [p]. *)
val fragments : t -> string list

(** [to_list p] is {!val:fragments}*)
val to_list : t -> string list

(** {1 Infix Operators}

    A set of infix operators. *)

module Infix : sig
  (** [p ++ xs] is an infix version of {!val:append}. *)
  val ( ++ ) : t -> string list -> t

  (** [p / s] adds [s] at the end of [p]. *)
  val ( / ) : t -> string -> t

  (** [~/["foo"; "bar"]] is [rel ["foo"; "bar"]]. See {!val:rel}. *)
  val ( ~/ ) : string list -> t

  (** [^/["foo"; "bar"]] is [abs ["foo"; "bar"]]. See {!val:abs}. *)
  val ( ^/ ) : string list -> t
end

include module type of Infix (** @inline *)
