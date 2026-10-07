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

module Item : sig
  (** Describes the contents of a file system, which may be files or
      directories. *)

  (** {1 Representation} *)

  (** Describes an element of the file system. *)
  type ('a, 'metadata) t = private
    | File of
        { name : string
        ; content : 'a
        ; metadata : 'metadata option
        }
    | Directory of
        { name : string
        ; children : ('a, 'metadata) t list
        ; metadata : 'metadata option
        }

  (** {1 Building items}

      The core of a tree is its items. [Tree] allows you to describe
      files and directories, abstracting away the contents of the files
      as well as the metadata of the directories or files. *)

  (** [dir ?metadata ~name children] creates a directory and takes a
      list of children. *)
  val dir
    :  ?metadata:'metadata
    -> name:string
    -> ('a, 'metadata) t list
    -> ('a, 'metadata) t

  (** [file ?metadata ~name content] creates a file and takes a content. *)
  val file : ?metadata:'metadata -> name:string -> 'a -> ('a, 'metadata) t

  (** {1 On Items}

      Information about items. *)

  (** [is_file item] returns [true] if the given [item] is a
      file. [false] otherwise. *)
  val is_file : ('a, 'metadata) t -> bool

  (** [is_directory item] returns [true] if the given [item] is a
      directory. [false] otherwise. *)
  val is_directory : ('a, 'metadata) t -> bool

  (** [name item] returns the name of the given [item]. *)
  val name : ('a, 'metadata) t -> string

  (** Same of {!val:name} but add a trailing slash if the item is a
      directory. *)
  val name_to_string : ('a, 'metadata) t -> string

  (** [has_name ~name item] returns [true] if the given [item] as the
      given [name]. *)
  val has_name : name:string -> ('a, 'metadata) t -> bool

  (** [rename new_name item] change the name of the given [item] by
      [new_name]. *)
  val rename : string -> ('a, 'metadata) t -> ('a, 'metadata) t

  (** [children item] returns the children of the given [item]. If
      [item] is a file, it returns an empty list. *)
  val children : ('a, 'metadata) t -> ('a, 'metadata) t list

  (** [content item] returns the content of the given [item]. Since the
      content of a directory is a [tree], it use a polymorphic variant
      to manage the different kind of content. *)
  val content
    :  ('a, 'metadata) t
    -> [ `File of 'a | `Directory of ('a, 'metadata) t list ]

  (** [map_content f item] map [f] on every nested information of the
      given [item]. *)
  val map_content : ('a -> 'b) -> ('a, 'metadata) t -> ('b, 'metadata) t

  (** [metadata item] returns the metadata associated to the given
      [item]. *)
  val metadata : ('a, 'metadata) t -> 'metadata option

  (** [on_metadata f item] apply [f] on [item] metadata. *)
  val on_metadata
    :  ('metadata option -> 'metadata option)
    -> ('a, 'metadata) t
    -> ('a, 'metadata) t
end

(** {1 Building Trees}

    Building a tree generally involves lifting a list of {{!type:item}
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
