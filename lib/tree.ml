(* Copyright (c) 2026, Cargocut and the Virtfs developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

type ('a, 'metadata) t = ('a, 'metadata) item list

and ('a, 'metadata) elt =
  { name : string
  ; content : 'a
  ; metadata : 'metadata option
  }

and ('a, 'metadata) item =
  | File of ('a, 'metadata) elt
  | Directory of (('a, 'metadata) t, 'metadata) elt

let content = function
  | File { content; _ } -> `File content
  | Directory { content; _ } -> `Directory content
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

let dir ?metadata ~name children =
  let content = sort_items children in
  Directory { name; content; metadata }
;;

let path_to_list p =
  let prefix, f = if Path.is_absolute p then "", Path.abs else ".", Path.rel
  and fragments = Path.to_list p in
  f, prefix :: fragments
;;

let file ?metadata ~name content = File { name; content; metadata }

let make ?(scope_metadata = fun _ -> None) ?scope list =
  match scope with
  | None -> list
  | Some scope ->
    let rec aux s = function
      | [] -> list
      | name :: xs ->
        let s = Path.(s / name) in
        let metadata = scope_metadata s in
        [ dir ?metadata ~name (aux s xs) ]
    in
    let p_root, l = path_to_list scope in
    aux (p_root []) l
;;

let from_root list = make ~scope:Path.root list
let from_cwd list = make ~scope:Path.cwd list

let name_to_string = function
  | File { name; _ } -> name
  | Directory { name; _ } -> name ^ "/"
;;

let name = name_to_string

let has_name ~name:given = function
  | File { name; _ } | Directory { name; _ } -> String.equal name given
;;

let fetch fs path =
  let _, path = path_to_list path in
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

let fold_callback acc
  =
  (* HACK: Ensure the order preservation after inserting an
     element. *)
  function
  | None -> sort_items acc
  | Some x -> sort_items (x :: acc)
;;

(* TODO: msp, expand tree in a "valid way" for dealing with parent. *)
let _expand_tree fs path =
  (* Expands a tree based on a path, if the path is relative *)
  if Path.is_absolute path
  then
    (* If the path is absolute, we can't expand the tree. *)
    fs, snd (path_to_list path)
  else assert false
;;

let update fs in_path callback =
  (* NOTE: The function essentially comes from the implementation of
     [Kohai] with support for ... tree expansion.*)
  let _, path = path_to_list in_path in
  let rec aux acc fs path =
    match fs, path with
    | [], [] ->
      (* We have gone through the entire tree, and the target does not
         exist, so we can create it where we are (maintained by
         [acc]). *)
      callback ~previous:None ~path:in_path |> fold_callback acc
    | item :: fs_xs, [ name ] ->
      (* We crossed the path. *)
      if has_name ~name item
      then (
        (* If the item has the correct name, we apply the callback. *)
        let new_acc = acc @ fs_xs in
        callback
          ~previous:(Some item)
            (* KLUDGE: surprinsingly, [~previous:item] does not
               works. (For high order reason I guess) *)
          ~path:in_path
        |> fold_callback new_acc)
      else
        (* The file does not have the correct name; we must continue
           traversing. *)
        aux (item :: acc) fs_xs [ name ]
    | ( (Directory { metadata; content; name = dirname } as cdir) :: fs_xs
      , name :: xs ) ->
      (* We arrive in a directory and the path is not complete. *)
      if has_name ~name cdir
      then (
        (* The item has the right name, so we can dive into the
           crossing. *)
        let new_dir = dir ?metadata ~name:dirname (aux [] content xs) in
        new_dir :: (acc @ fs_xs) |> sort_items)
      else
        (* The name is invalid, so we continue browsing the current
           directory. *)
        aux (cdir :: acc) fs_xs path
    | [], name :: path_xs ->
      (* We need continue to create a tree structure. *)
      let new_dir = dir ~name (aux [] [] path_xs) in
      new_dir :: acc |> sort_items
    | x :: fs_xs, path ->
      (* Not in the right position, let's continue the iteration. *)
      aux (x :: acc) fs_xs path
  in
  aux [] fs path
;;

let touch fs path ?(if_exists = Fun.id) ?metadata content =
  update fs path (fun ~previous ~path ->
    match previous with
    | Some item -> Some (if_exists item)
    | None ->
      let name = Path.basename path in
      Some (file ?metadata ~name content))
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

let cat ~to_string fs path =
  match fetch fs path with
  | None ->
    let s = Path.to_string path in
    "cat: " ^ s ^ ": No such file or directory"
  | Some (Directory _) ->
    let s = Path.to_string path in
    "cat: " ^ s ^ ": Is a directory"
  | Some (File { content; _ }) -> to_string content
;;
