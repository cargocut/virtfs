(* Copyright (c) 2026, Cargocut and the Virtfs developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

type 'a t = 'a item list

and 'a elt =
  { name : string
  ; content : 'a
  }

and 'a item =
  | File of 'a elt
  | Directory of 'a t elt

let content = function
  | File { content; _ } -> `Content content
  | Directory { content; _ } -> `Tree content
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
  | Directory { content; _ } -> content
  | File _ -> []
;;

let compare_item a b =
  match a, b with
  | File { name = a; _ }, File { name = b; _ }
  | Directory { name = a; _ }, Directory { name = b; _ } -> String.compare a b
  | File _, Directory _ -> 1
  | Directory _, File _ -> -1
;;

(* HACK: To ensure that trees are ordered consistently.*)
let sort_items xs = List.sort_uniq compare_item xs

let dir ~name children =
  let content = sort_items children in
  Directory { name; content }
;;

let path_to_list p =
  let prefix = if Path.is_absolute p then "" else "."
  and fragments = Path.to_list p in
  prefix :: fragments
;;

let file ~name content = File { name; content }

let make ?scope list =
  match scope with
  | None -> list
  | Some scope ->
    let rec aux = function
      | [] -> list
      | name :: xs -> [ dir ~name (aux xs) ]
    in
    aux (path_to_list scope)
;;

let from_root list = make ~scope:Path.root list
let from_cwd list = make ~scope:Path.cwd list

let name_to_string = function
  | File { name; _ } -> name
  | Directory { name; _ } -> name ^ "/"
;;

let has_name ~name:given = function
  | File { name; _ } | Directory { name; _ } -> String.equal name given
;;

let fetch fs path =
  let path = path_to_list path in
  let rec aux fs path =
    match fs, path with
    | x :: xs, [ name ] ->
      (* We are on the [basename] of the path; if the names are
         equivalent, we return the item. *)
      if has_name ~name x
      then Some x
      else
        (* Otherwise, we continue to traverse the tree. *)
        aux xs path
    | (Directory { content; _ } as x) :: xs, name :: ps ->
      (* In a directory case, if the nases are equivalent, we traverse
         into the directory. *)
      if has_name ~name x
      then aux content ps
      else
        (* Otherwise, we continue to traverse the tree. *)
        aux xs path
    | _ :: xs, path -> aux xs path
    | [], _ -> None
  in
  aux fs path
;;

(* OKAY: [ls], [nested_print] and [tree] are essentially the testing
   tool. One could argue that this is leaky abstraction, but since the
   purpose of [Tree] is essentially to provide tools for building unit
   tests, I'm not bothered by it. *)

let ls fs = fs |> List.map name_to_string

let nested_print level term =
  let c = String.make (level * 2) ' ' in
  c ^ "└─" ^ name_to_string term
;;

let tree fs =
  let rec aux level acc = function
    | [] -> acc
    | (File _ as term) :: xs ->
      let f = nested_print level term in
      aux level (acc ^ "\n" ^ f) xs
    | (Directory { content; _ } as term) :: xs ->
      let f = nested_print level term in
      let a = aux (succ level) (acc ^ "\n" ^ f) content in
      aux level a xs
  in
  aux 0 "" fs
;;
