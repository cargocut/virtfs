(* Copyright (c) 2026, Cargocut and the Virtfs developers. All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(** Describes the contents of a file system, which may be files or directories.
*)

(** {1 Representation} *)

(** Describes an element of the file system. *)
type ('a, 'metadata) t = private
  | File of { name : string; content : 'a; metadata : 'metadata option }
  | Directory of {
        name : string
      ; children : ('a, 'metadata) t list
      ; metadata : 'metadata option
    }

(** {1 Building items}

    The core of a tree is its items. [Tree] allows you to describe files and
    directories, abstracting away the contents of the files as well as the
    metadata of the directories or files. *)

val dir :
     ?metadata:'metadata
  -> name:string
  -> ('a, 'metadata) t list
  -> ('a, 'metadata) t
(** [dir ?metadata ~name children] creates a directory and takes a list of
    children. *)

val file : ?metadata:'metadata -> name:string -> 'a -> ('a, 'metadata) t
(** [file ?metadata ~name content] creates a file and takes a content. *)

(** {1 On Items}

    Information about items. *)

val sort : ('a, 'metadata) t list -> ('a, 'metadata) t list
(** [sort items] apply [sort_uniq] on a list of items. *)

val is_file : ('a, 'metadata) t -> bool
(** [is_file item] returns [true] if the given [item] is a file. [false]
    otherwise. *)

val is_directory : ('a, 'metadata) t -> bool
(** [is_directory item] returns [true] if the given [item] is a directory.
    [false] otherwise. *)

val name : ('a, 'metadata) t -> string
(** [name item] returns the name of the given [item]. *)

val name_to_string : ('a, 'metadata) t -> string
(** Same of {!val:name} but add a trailing slash if the item is a directory. *)

val has_name : name:string -> ('a, 'metadata) t -> bool
(** [has_name ~name item] returns [true] if the given [item] as the given
    [name]. *)

val rename : string -> ('a, 'metadata) t -> ('a, 'metadata) t
(** [rename new_name item] change the name of the given [item] by [new_name]. *)

val children : ('a, 'metadata) t -> ('a, 'metadata) t list
(** [children item] returns the children of the given [item]. If [item] is a
    file, it returns an empty list. *)

val content :
  ('a, 'metadata) t -> [ `File of 'a | `Directory of ('a, 'metadata) t list ]
(** [content item] returns the content of the given [item]. Since the content of
    a directory is a [tree], it use a polymorphic variant to manage the
    different kind of content. *)

val map_content : ('a -> 'b) -> ('a, 'metadata) t -> ('b, 'metadata) t
(** [map_content f item] map [f] on every nested information of the given
    [item]. *)

val metadata : ('a, 'metadata) t -> 'metadata option
(** [metadata item] returns the metadata associated to the given [item]. *)

val on_metadata :
     ('metadata option -> 'metadata option)
  -> ('a, 'metadata) t
  -> ('a, 'metadata) t
(** [on_metadata f item] apply [f] on [item] metadata. *)

(** {1 Misc} *)

val equal :
     ('content -> 'content -> bool)
  -> ('metadata -> 'metadata -> bool)
  -> ('content, 'metadata) t
  -> ('content, 'metadata) t
  -> bool
(** [equal a b] returns [true] if [a] and [b] are equal, [false] otherwise. *)
