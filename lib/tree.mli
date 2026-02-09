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

(** A tree is a list of items, where an item can be a file or a
    directory (which is a list of files). *)
type ('a, 'metadata) item

(** Describes a tree (a directory or file list). *)
type ('a, 'metadata) t

(** {1 Building Trees}

    Building a tree generally involves lifting a list of {{!type:item}
    items}. *)

(** [make ?scope_metadata ?scope items] builds a tree. The [scope]
    parameter allows you to define the tree in a given path. The
    [scope_metadata] function allows you to attach metadata to each
    intermediate directory in the scope.*)
val make
  :  ?scope_metadata:(Path.t -> 'metadata option)
  -> ?scope:Path.t
  -> ('a, 'metadata) item list
  -> ('a, 'metadata) t

(** [from_root] is like {!val:make} but using {!val:Path.root} as {i scope}. *)
val from_root : ('a, 'metadata) item list -> ('a, 'metadata) t

(** [from_cwd] is like {!val:make} but using {!val:Path.cwd} as {i scope}. *)
val from_cwd : ('a, 'metadata) item list -> ('a, 'metadata) t

(** {2 Building Items}

    The core of a tree is its items. [Tree] allows you to describe
    files and directories, abstracting away the contents of the files
    as well as the metadata of the directories or files. *)

(** [dir ?metadata ~name children] creates a directory and takes a
    list of children. *)
val dir
  :  ?metadata:'metadata
  -> name:string
  -> ('a, 'metadata) item list
  -> ('a, 'metadata) item

(** [file ?metadata ~name content] creates a file and takes a content. *)
val file : ?metadata:'metadata -> name:string -> 'a -> ('a, 'metadata) item

(** {1 On items}

    Information about items. *)

(** [is_file item] returns [true] if the given [item] is a
    file. [false] otherwise. *)
val is_file : ('a, 'metadata) item -> bool

(** [is_directory item] returns [true] if the given [item] is a
    directory. [false] otherwise. *)
val is_directory : ('a, 'metadata) item -> bool

(** [name item] returns the name of the given [item]. *)
val name : ('a, 'metadata) item -> string

(** [children item] returns the children of the given [item]. If
    [item] is a file, it returns an empty list. *)
val children : ('a, 'metadata) item -> ('a, 'metadata) item list

(** [content item] returns the content of the given [item]. Since the
    content of a directory is a [tree], it use a polymorphic variant
    to manage the different kind of content. *)
val content
  :  ('a, 'metadata) item
  -> [ `File of 'a | `Directory of ('a, 'metadata) item list ]

(** [metadata item] returns the metadata associated to the given
    [item]. *)
val metadata : ('a, 'metadata) item -> 'metadata option

(** {1 Operation on Trees} *)

val fetch : ('a, 'metadata) t -> Path.t -> ('a, 'metadata) item option

(** [update fs path callback] generic function to modify the filetree,
    it is the [callback] function (returning an option) that describes
    whether the file should be created or deleted. *)
val update
  :  ('a, 'metadata) t
  -> Path.t
  -> (previous:('a, 'metadata) item option
      -> path:Path.t
      -> ('a, 'metadata) item option)
  -> ('a, 'metadata) t

(** [touch fs path ?metadata content] returns a new filesystem where,
    if the target exists, [if_exists] is applied; otherwise, a file is
    created. *)
val touch
  :  ('a, 'metadata) t
  -> Path.t
  -> ?if_exists:(('a, 'metadata) item -> ('a, 'metadata) item)
  -> ?metadata:'metadata
  -> 'a
  -> ('a, 'metadata) t

(** {1 Misc}

    As the purpose of the virtual file system is primarily for
    testing, the API provides a collection of inspection tools. *)

(** [ls fs] returns a flat list of strings, equivalent to applying
    the Unix [ls] command. *)
val ls : ('a, 'metadata) t -> string list

(** [tree fs] returns a character string that prints the given tree
    [fs] in tree form, similar to the [tree] command (in [Unix]). *)
val tree : ('a, 'metadata) t -> string

(** [cat ~to_string fs path] Returns a string that resembles the
    output of the [cat] command in [Unix] (without concatenation). *)
val cat : to_string:('a -> string) -> ('a, 'metadata) t -> Path.t -> string
