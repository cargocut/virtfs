(* Copyright (c) 2026, Cargocut and the Virtfs developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

type ('a, 'metadata) t =
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

let compare a b =
  match a, b with
  | File { name = a; _ }, File { name = b; _ }
  | Directory { name = a; _ }, Directory { name = b; _ } -> String.compare a b
  | File _, Directory _ -> 1
  | Directory _, File _ -> -1
;;

let rec equal eq_content eq_metadata a b =
  match a, b with
  | ( File { name = name_a; content = content_a; metadata = meta_a }
    , File { name = name_b; content = content_b; metadata = meta_b } ) ->
    String.equal name_a name_b
    && eq_content content_a content_b
    && Option.equal eq_metadata meta_a meta_b
  | ( Directory { name = name_a; children = children_a; metadata = meta_a }
    , Directory { name = name_b; children = children_b; metadata = meta_b } ) ->
    String.equal name_a name_b
    && List.equal (equal eq_content eq_metadata) children_a children_b
    && Option.equal eq_metadata meta_a meta_b
  | File _, _ | Directory _, _ -> false
;;

(* HACK: To ensure that trees are ordered consistently.*)
let sort xs = List.sort_uniq compare xs

let dir ?metadata ~name children =
  let children = sort children in
  Directory { name; children; metadata }
;;

let file ?metadata ~name content = File { name; content; metadata }

let name_to_string = function
  | File { name; _ } -> name
  | Directory { name; _ } -> name ^ "/"
;;

let name = function
  | File { name; _ } -> name
  | Directory { name; _ } -> name
;;

let has_name ~name:given = function
  | File { name; _ } | Directory { name; _ } -> String.equal name given
;;

let content = function
  | File { content; _ } -> `File content
  | Directory { children; _ } -> `Directory children
;;

let rename name = function
  | File elt -> File { elt with name }
  | Directory elt -> Directory { elt with name }
;;

let rec map_content on_file = function
  | File elt -> File { elt with content = on_file elt.content }
  | Directory elt ->
    Directory
      { elt with children = List.map (map_content on_file) elt.children }
;;

let on_metadata f = function
  | File elt -> File { elt with metadata = f elt.metadata }
  | Directory elt -> Directory { elt with metadata = f elt.metadata }
;;

let metadata = function
  | File { metadata; _ } | Directory { metadata; _ } -> metadata
;;

let is_file = function
  | File _ -> true
  | Directory _ -> false
;;

let is_directory = function
  | Directory _ -> true
  | File _ -> false
;;

let children = function
  | Directory { children; _ } -> children
  | File _ -> []
;;
