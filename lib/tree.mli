(* Copyright (c) 2026, Cargocut and the Virtfs developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(** Describes a file tree containing files or directories (a directory
    being a file tree). Unlike {!module:Path}, which can be used in an
    application to abstract paths, [Tree] is mainly used to mount
    virtual file systems, which are particularly useful for writing
    unit tests. *)

(** {1 Representation}

    The tree module is quite rigid and imposes the [File] vs
    [Directory] structure, but makes no assumptions whatsoever about
    the contents of files and the metadata associated with [files] and
    [directories]. *)

(** Describes a tree (a directory or file list). *)
type ('a, 'metadata) t

(** A tree is a list of items, where an item can be a file or a
    directory (which is a list of files). *)

(** {1 Building Trees}

    Building a tree generally involves lifting a list of {{!type:Item.t}
    items}. *)

(** [make ?scope_metadata ?scope items] builds a tree. The [scope]
    parameter allows you to define the tree in a given path. The
    [scope_metadata] function allows you to attach metadata to each
    intermediate directory in the scope.*)
val make
  :  ?scope_metadata:(Path.t -> 'metadata option)
  -> scope:Path.t
  -> ('a, 'metadata) Item.t list
  -> ('a, 'metadata) t

(** [from_root] is like {!val:make} but using {!val:Path.root} as {i scope}. *)
val from_root : ('a, 'metadata) Item.t list -> ('a, 'metadata) t

(** [from_cwd] is like {!val:make} but using {!val:Path.cwd} as {i scope}. *)
val from_cwd : ('a, 'metadata) Item.t list -> ('a, 'metadata) t

(** See {!val:Item.dir} *)
val dir
  :  ?metadata:'metadata
  -> name:string
  -> ('a, 'metadata) Item.t list
  -> ('a, 'metadata) Item.t

(** See {!val:Item.file} *)
val file : ?metadata:'metadata -> name:string -> 'a -> ('a, 'metadata) Item.t

(** {1 Operation on Trees} *)

(** [fetch ~path fs] try to reach the [item] at the position [path]. *)
val fetch : path:Path.t -> ('a, 'metadata) t -> ('a, 'metadata) Item.t option

(** [prism ~scope fs ] returns a sub-tree based on a path ([scope]).*)
val prism : scope:Path.t -> ('a, 'metadata) t -> ('a, 'metadata) t

(** [expand ?scope ?keep ?keep_root fs] expand all child paths of a given
    [fs] starting from a given scope (if no scope is specified, the
    function uses the root of the tree). It is possible to collect
    only files, only directories, or all paths by using [keep]
    (default: [`All]. By default, the toplevel result (the first
    element) is the [scope], if you set [keep_root] to [false], the
    toplevel scope is removed. *)
val unfold
  :  ?scope:Path.t
  -> ?keep:[ `All | `Directories | `Files ]
  -> ?keep_root:bool
  -> ('a, 'metadata) t
  -> Path.Set.t

(** [update ~path callback fs] generic function to modify the filetree,
    it is the [callback] function (returning an option) that describes
    whether the file should be created or deleted. *)
val update
  :  path:Path.t
  -> (previous:('a, 'metadata) Item.t option
      -> path:Path.t
      -> ('a, 'metadata) Item.t option)
  -> ('a, 'metadata) t
  -> ('a, 'metadata) t

(** [touch ~path ?metadata content fs] returns a new filesystem where,
    if the target exists, [if_exists] is applied; otherwise, a file is
    created. *)
val touch
  :  path:Path.t
  -> ?if_exists:(('a, 'metadata) Item.t -> ('a, 'metadata) Item.t)
  -> ?metadata:'metadata
  -> 'a
  -> ('a, 'metadata) t
  -> ('a, 'metadata) t

(** [rm ~path fs] remove the item by a given [path]. *)
val rm : path:Path.t -> ('a, 'metadata) t -> ('a, 'metadata) t

(** [rm_file ~path fs] remove the file by a given [path]. *)
val rm_file : path:Path.t -> ('a, 'metadata) t -> ('a, 'metadata) t

(** [rm_dir ~path fs] remove the directory by a given [path]. *)
val rm_dir : path:Path.t -> ('a, 'metadata) t -> ('a, 'metadata) t

(** [mv fs ~target ~source] move [source] as [target]. If the [target]
    exists, or the given [source] does not exists, [fs] remains
    unchanged. *)
val mv
  :  target:Path.t
  -> source:Path.t
  -> ('a, 'metadata) t
  -> ('a, 'metadata) t

(** [insert_items ?scope ?on_metadata ?on_conflict ?give_up items fs] adds
    [items] to an existing tree, at the {i scope} of [fs] (or at
    [scope], resolved against it).  [on_conflict] describes what
    happens when an item is already present, and defaults to
    {!val:Conflict.rename_current} with the [".rej"]
    suffix. [on_metadata] allows you to decide arbitrarily how to
    merge metadata when merging directories. [give_up] is the dreadful
    function that is called when conflict resolution results in
    something sadly ambiguous, allowing an arbitrary decision to be
    made as to which segment to drop. By default, the element that was
    already present in the tree is retained. *)
val insert_items
  :  ?scope:Path.t
  -> ?on_metadata:
       (Path.t -> 'metadata option -> 'metadata option -> 'metadata option)
  -> ?on_conflict:('a, 'metadata) Conflict.resolution
  -> ?give_up:('a, 'metadata) Conflict.give_up
  -> ('a, 'metadata) Item.t list
  -> ('a, 'metadata) t
  -> ('a, 'metadata) t

(** {1 Misc}

    As the purpose of the virtual file system is primarily for
    testing, the API provides a collection of inspection tools. *)

(** [ls fs] returns a flat list of strings, equivalent to applying
    the Unix [ls] command. *)
val ls : ?scope:Path.t -> ('a, 'metadata) t -> string list

(** [tree fs] returns a character string that prints the given tree
    [fs] in tree form, similar to the [tree] command (in [Unix]). *)
val tree : ('a, 'metadata) t -> string

(** [cat ~to_string fs path] Returns a string that resembles the
    output of the [cat] command in [Unix] (without concatenation). *)
val cat : to_string:('a -> string) -> ('a, 'metadata) t -> Path.t -> string

(** {1 A Dummy File System Implementation}

    The implementation is not abstract, which allows generic functions
    to be used on a [Simple] tree (mostly used for tests). *)

module Simple : sig
  (** A truly {b very naive} implementation of a file system where the
      contents of files are strings and their metadata only associates
      modification dates.

      The API throws {!exception:Simple_error} exceptions to mimic
      Unix behaviour. *)

  (** {1 Types} *)

  (** The [float] type is used to represent time, in the same way as
      the Unix module. *)
  type time = float

  (** A clock is simply a function that produces a value of type
      {!type:time}. *)
  type 'a clock = 'a -> time

  (** The metadata type is deliberately left abstract to simplify its
      potential extension. *)
  type metadata

  (** The contents of the files are simple strings. *)
  type content = string

  (** Items of the file system. *)
  type nonrec item = (content, metadata) Item.t

  (** Items of the file system. *)
  type nonrec t = (content, metadata) t

  (** {2 Error handling}

      The API relies on exceptions to describe failures. Each function
      that may fail throws the [Dummy_tree] exception. *)

  (** Set of all possible errors. *)
  type error

  exception Simple_error of error

  (** Render an error as an Unix-like error message. *)
  val error_to_string : error -> string

  (** {1 Tree construction} *)

  (** [const_clock f] creates a constant clock, always returning
      [f]. *)
  val const_clock : float -> 'a clock

  (** [mount ?clock ~scope children] creates a tree using {!val:make}. *)
  val mount : ?clock:Path.t clock -> scope:Path.t -> item list -> t

  (** [file ?clock ~name content] creates a file. The [clock] is
      parametrized by the couple of [name, content]. *)
  val file : ?clock:(string * content) clock -> name:string -> content -> item

  (** [dir ?clock ~name children] creates a directory. The [clock] is
      parametrized by the [name] of the directory. *)
  val dir : ?clock:string clock -> name:string -> item list -> item

  (** {1 Tree operation} *)

  (** [mtime ~path fs] returns the {i modification time} of the given
      {!type:item} located at the given [path]. *)
  val mtime : path:Path.t -> t -> float

  (* [file_exists ~path fs] returns [true] if the file/directory
     exists at the given [path] for the given [fs], [false]
     otherwise. *)
  val file_exists : path:Path.t -> t -> bool

  (* [is_directory ~path fs] returns [true] if the directory
     exists at the given [path] for the given [fs], [false]
     otherwise (even if the target does not exists). *)
  val is_directory : path:Path.t -> t -> bool

  (* [is_file ~path fs] returns [true] if the file
     exists at the given [path] for the given [fs], [false]
     otherwise (even if the target does not exists). *)
  val is_file : path:Path.t -> t -> bool

  (** [is_empty_dir ~path fs] returns [true] if the directory located
      at [path] for the given [fs] is an empty directory. *)
  val is_empty_dir : path:Path.t -> t -> bool

  (** [mkdir ?recursive ?clock ~path] creates the directory referenced
      by the given [path] with behaviour similar to the Unix command
      [mkdir] (the [recursive] flag is for [mkdir -p], default is
      [false]). *)
  val mkdir
    :  ?recursive:bool
    -> ?clock:(content -> time)
    -> path:Path.t
    -> t
    -> t

  (** [rm ~path fs] remove the item by a given [path] (like
      {!val:Tree.rm} but raising exception). *)
  val rm : ?recursive:bool -> path:Path.t -> t -> t

  (** [rm_file fs path] remove the file by a given [path] (like
      {!val:Tree.rm_file} but raising exception). *)
  val rm_file : path:Path.t -> t -> t

  (** [rm_dir fs path] remove the directory by a given [path] (like
      {!val:Tree.rm_dir} but raising exception). *)
  val rm_dir : ?recursive:bool -> path:Path.t -> t -> t

  (** [write_file ?overwrite ?clock ~path content fs] creates (or
      overwrites, depending on the [overwrite] flag, default [false])
      the file [path] with content [content] on the given [fs].*)
  val write_file
    :  ?overwrite:bool
    -> ?clock:(string * content -> time)
    -> path:Path.t
    -> string
    -> t
    -> t

  (** [read_file ~path fs] Reads the contents of the file referenced
      by its [path] for a given [fs]. *)
  val read_file : path:Path.t -> t -> string

  (** [read_dir ~path fs] returns the direct children of the directory
      passed as an argument (in the form of a map of {{!type:item}
      items} indexed by {{!type:Path.t} Paths}).*)
  val read_dir : path:Path.t -> t -> item Path.Map.t

  (** {1 Misc} *)

  (** [run ?finalizer callback] runs [callback] and print errors on
      [stderr]. *)
  val run : ?finalizer:('a -> unit) -> (unit -> 'a) -> unit
end
