(* Copyright (c) 2026, Cargocut and the Virtfs developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

type ('a, 'metadata) t =
  { children : ('a, 'metadata) item list
  ; scope : Path.t
  }

and ('a, 'metadata) elt =
  { name : string
  ; content : 'a
  ; metadata : 'metadata option
  }

and ('a, 'metadata) item =
  | File of ('a, 'metadata) elt
  | Directory of (('a, 'metadata) item list, 'metadata) elt

let content = function
  | File { content; _ } -> `File content
  | Directory { content; _ } -> `Directory content
;;

let set_name name = function
  | File elt -> File { elt with name }
  | Directory elt -> Directory { elt with name }
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

let make ?(scope_metadata = fun _ -> None) ~scope list =
  let rec aux s = function
    | [] -> list
    | name :: xs ->
      let s = Path.(s / name) in
      let metadata = scope_metadata s in
      [ dir ?metadata ~name (aux s xs) ]
  in
  let p_root, l = path_to_list scope in
  let children = aux (p_root []) l in
  { scope; children }
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

let resolve_path scope path =
  if Path.is_absolute scope
  then Path.resolve ~from:scope path
  else Path.graft ~into:scope path
;;

let fetch ~path fs =
  let path = resolve_path fs.scope path in
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
  aux fs.children path
;;

let prism ~scope fs =
  match fetch fs ~path:scope with
  | None -> make ~scope []
  | Some (File _ as f) -> make ~scope [ f ]
  | Some (Directory { content; _ }) -> make ~scope content
;;

let fold_callback acc
  =
  (* HACK: Ensure the order preservation after inserting an
     element. *)
  function
  | None -> sort_items acc
  | Some x -> sort_items (x :: acc)
;;

let update ~path:in_path callback fs =
  (* NOTE: The function essentially comes from the implementation of
     [Kohai] with support for ... tree expansion.*)
  let in_path = resolve_path fs.scope in_path in
  let _, path = path_to_list in_path in
  let rec aux acc fs path =
    match fs, path with
    | [], ([] | [ _ ]) ->
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
  let children = aux [] fs.children path in
  let scope = fs.scope in
  { scope; children }
;;

let touch ~path ?(if_exists = Fun.id) ?metadata content =
  update ~path (fun ~previous ~path ->
    match previous with
    | Some item -> Some (if_exists item)
    | None ->
      let name = Path.basename path in
      Some (file ?metadata ~name content))
;;

let rm_file ~path =
  update ~path (fun ~previous ~path:_ ->
    match previous with
    | None | Some (File _) -> None
    | item -> item)
;;

let rm_dir ~path =
  update ~path (fun ~previous ~path:_ ->
    match previous with
    | None | Some (Directory _) -> None
    | item -> item)
;;

let rm ~path = update ~path (fun ~previous:_ ~path:_ -> None)

let mv ~target ~source fs =
  match fetch fs ~path:target, fetch fs ~path:source with
  | Some _, _ (* The new path already exists. *)
  | _, None (* The target does not exists. *) -> fs
  | None, Some item ->
    let new_fs = rm ~path:source fs
    and name = Path.basename target in
    update
      ~path:target
      (fun ~previous:_ ~path:_ -> Some (set_name name item))
      new_fs
;;

(* OKAY: [ls], [nested_print] and [tree] are essentially the testing
   tool. One could argue that this is leaky abstraction, but since the
   purpose of [Tree] is essentially to provide tools for building unit
   tests, I'm not bothered by it. *)

let ls ?scope fs =
  match Option.bind scope (fun path -> fetch ~path fs) with
  | None -> fs.children |> List.map name_to_string
  | Some (File _ as f) -> [ name_to_string f ]
  | Some (Directory { content; _ }) -> List.map name_to_string content
;;

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
  aux 0 "" fs.children
;;

let cat ~to_string fs path =
  match fetch fs ~path with
  | None ->
    let s = Path.to_string path in
    "cat: " ^ s ^ ": No such file or directory"
  | Some (Directory _) ->
    let s = Path.to_string path in
    "cat: " ^ s ^ ": Is a directory"
  | Some (File { content; _ }) -> to_string content
;;

module Dummy = struct
  (* NOTE: A very minimal implementation of a file system that shares
     some naive characteristics with Unix. As the purpose is to be
     used primarily for testing, its support is fairly basic. *)

  type time = float
  type 'a clock = 'a -> time
  type metadata = { mtime : time }
  type content = string
  type nonrec item = (content, metadata) item
  type nonrec t = (content, metadata) t
  type error = Mkdir of Path.t * string

  exception Dummy_tree of error

  let dummy_clock x _ = x

  let mount ?(clock = dummy_clock 1.0) ~scope children =
    make
      ~scope_metadata:(fun path -> Some { mtime = clock path })
      ~scope
      children
  ;;

  let file ?(clock = dummy_clock 1.0) ~name content =
    file ~metadata:{ mtime = clock (name, content) } ~name content
  ;;

  let dir ?(clock = dummy_clock 1.0) ~name children =
    dir ~metadata:{ mtime = clock name } ~name children
  ;;

  let error_s path prim err reason =
    prim ^ ": " ^ err ^ " '" ^ Path.to_string path ^ "': " ^ reason
  ;;

  let error_to_string = function
    | Mkdir (p, reason) -> error_s p "mkdir" "cannot create directory" reason
  ;;

  let raise_error error = raise (Dummy_tree error)

  let mkdir ?(clock = dummy_clock 1.0) ~path fs =
    let dname = Path.dirname path in
    match fetch ~path:dname fs, fetch ~path fs with
    | Some _, None ->
      update
        ~path
        (fun ~previous:_ ~path ->
           let bname = Path.basename path in
           let item = dir ~clock ~name:bname [] in
           Some item)
        fs
    | _, Some _ -> raise_error (Mkdir (path, "File exists"))
    | None, _ -> raise_error (Mkdir (path, "No such file or directory"))
  ;;

  let mkdir_p ?(clock = dummy_clock 1.0) ~path fs =
    let rec aux path fs =
      let file = fetch ~path fs in
      match file with
      | Some (File _) -> raise_error (Mkdir (path, "File exists"))
      | Some (Directory _) -> fs
      | None ->
        let p = Path.dirname path in
        let fs = aux p fs in
        mkdir ~clock ~path fs
    in
    aux path fs
  ;;

  let mtime item =
    item
    |> metadata
    |> Option.fold
         ~none:0.0 (* OKAY: having [0.0] as a default result seems ok. *)
         ~some:(fun { mtime } -> mtime)
  ;;
end
