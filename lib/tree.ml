(* Copyright (c) 2026, Cargocut and the Virtfs developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

let path_to_list p =
  let prefix, f = if Path.is_absolute p then "", Path.abs else ".", Path.rel
  and fragments = Path.to_list p in
  f, prefix :: fragments
;;

type ('a, 'metadata) t =
  { children : ('a, 'metadata) Item.t list
  ; scope : Path.t
  }

let scope { scope; _ } = scope

let equal eq_content eq_metadata { children; scope } other =
  Path.equal scope other.scope
  && List.equal (Item.equal eq_content eq_metadata) children other.children
;;

let dir = Item.dir
let file = Item.file

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

let from_root ?scope_metadata list = make ?scope_metadata ~scope:Path.root list
let from_cwd ?scope_metadata list = make ?scope_metadata ~scope:Path.cwd list

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
      if Item.has_name ~name x
      then Some x
      else
        (* Otherwise, we continue to traverse the tree. *)
        aux xs path
    | (Item.Directory { children; _ } as x) :: xs, name :: ps ->
      (* In a directory case, if the nases are equivalent, we traverse
         into the directory. *)
      if Item.has_name ~name x
      then aux children ps
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
  | Some (Item.File _ as f) -> make ~scope [ f ]
  | Some (Directory { children; _ }) -> make ~scope children
;;

let fold_callback acc
  =
  (* HACK: Ensure the order preservation after inserting an
     element. *)
  function
  | None -> Item.sort acc
  | Some x -> Item.sort (x :: acc)
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
      if Item.has_name ~name item
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
    | ( (Item.Directory { metadata; children; name = dirname } as cdir) :: fs_xs
      , name :: xs ) ->
      (* We arrive in a directory and the path is not complete. *)
      if Item.has_name ~name cdir
      then (
        (* The item has the right name, so we can dive into the
           crossing. *)
        let new_dir = dir ?metadata ~name:dirname (aux [] children xs) in
        new_dir :: (acc @ fs_xs) |> Item.sort)
      else
        (* The name is invalid, so we continue browsing the current
           directory. *)
        aux (cdir :: acc) fs_xs path
    | [], name :: path_xs ->
      (* We need continue to create a tree structure. *)
      let new_dir = dir ~name (aux [] [] path_xs) in
      new_dir :: acc |> Item.sort
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
      (fun ~previous:_ ~path:_ -> Some (Item.rename name item))
      new_fs
;;

let unfold_aux
      empty
      add
      remove
      singleton
      ?scope
      ?(keep = `All)
      ?(keep_root = true)
      ({ scope = default_scope; _ } as fs)
  =
  let current_scope =
    Option.fold ~none:default_scope ~some:(resolve_path default_scope) scope
  in
  match fetch ~path:current_scope fs with
  | Some (Item.Directory { children; metadata; name = base_name }) ->
    let rec aux current_scope acc children =
      match keep, children with
      | (`All | `Files), (Item.File { name; _ } as item) :: xs ->
        aux current_scope (add (Path.(current_scope / name), item) acc) xs
      | ( (`All | `Files | `Directories)
        , (Item.Directory { name; children; _ } as item) :: xs ) ->
        let current_path = Path.(current_scope / name) in
        let new_acc = aux current_path acc children in
        let new_acc =
          match keep with
          | `All | `Directories -> add (current_path, item) new_acc
          | `Files -> new_acc
        in
        aux current_scope new_acc xs
      | `Directories, Item.File _ :: xs -> aux current_scope acc xs
      | _, [] -> acc
    in
    let res =
      match keep with
      | `All | `Directories ->
        singleton (current_scope, Item.dir ~name:base_name ?metadata [])
      | `Files -> empty
    in
    let res = children |> aux current_scope res in
    if keep_root then res else remove current_scope res
  | Some (Item.File _ as item) ->
    (* NOTE: the file is the root of the unfolding, so it obeys [keep]
       and [keep_root] like any other item. *)
    (match keep, keep_root with
     | (`All | `Files), true -> singleton (current_scope, item)
     | (`All | `Files), false | `Directories, _ -> empty)
  | None ->
    (* NOTE: If the scope does not exists, it return an empty result. *)
    empty
;;

let unfold ?scope ?keep ?keep_root fs =
  unfold_aux
    Path.Set.empty
    (fun (path, _) xs -> Path.Set.add path xs)
    Path.Set.remove
    (fun (path, _) -> Path.Set.singleton path)
    ?scope
    ?keep
    ?keep_root
    fs
;;

let unfold_with_content ?scope ?(keep = `Files) ?keep_root fs =
  unfold_aux
    Path.Map.empty
    (fun (k, v) m -> Path.Map.add k v m)
    Path.Map.remove
    (fun (k, v) -> Path.Map.singleton k v)
    ?scope
    ~keep
    ?keep_root
    fs
;;

(* OKAY: [ls], [nested_print] and [tree] are essentially the testing
   tool. One could argue that this is leaky abstraction, but since the
   purpose of [Tree] is essentially to provide tools for building unit
   tests, I'm not bothered by it. *)

let ls ?scope fs =
  match Option.bind scope (fun path -> fetch ~path fs) with
  | None -> fs.children |> List.map Item.name_to_string
  | Some (Item.File _ as f) -> [ Item.name_to_string f ]
  | Some (Directory { children; _ }) -> List.map Item.name_to_string children
;;

let nested_print level term =
  let c = String.make (level * 2) ' ' in
  c ^ "└─" ^ Item.name_to_string term
;;

let tree fs =
  let rec aux level acc = function
    | [] -> acc
    | (Item.File _ as term) :: xs ->
      let f = nested_print level term in
      aux level (acc ^ "\n" ^ f) xs
    | (Directory { children; _ } as term) :: xs ->
      let f = nested_print level term in
      let a = aux (succ level) (acc ^ "\n" ^ f) children in
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

let mix_metadata _ meta1 meta2 =
  (* NOTE: Keep the defined metadata by default. *)
  match meta1, meta2 with
  | Some x, None | _, Some x -> Some x
  | None, None -> None
;;

let rec insert_aux
          ?(seen = [])
          ?(give_up = Conflict.retain `Previous)
          ?(on_metadata = mix_metadata)
          ?(on_conflict = Conflict.rename_current (fun x -> x ^ ".rej"))
          eq
          path
          children
          item
  =
  let name = Item.name item in
  let parent_path = path in
  let path = Path.(path / name) in
  let perform_give_up acc previous xs =
    match give_up ~previous ~current:item path with
    | `Neither -> Item.sort (List.rev_append acc xs)
    | `Previous -> Item.sort (List.rev_append acc (previous :: xs))
    | `Current -> Item.sort (List.rev_append acc (item :: xs))
  in
  let rec aux acc = function
    | [] -> Item.sort (item :: children)
    | x :: xs when Item.has_name ~name x ->
      if List.exists (String.equal name) seen
      then
        (* NOTE: renaming is cyclic, let's give up! *)
        perform_give_up acc x xs
      else (
        let resolved =
          resolve_aux eq on_metadata give_up on_conflict path x item
        in
        (* NOTE: the items keeping the conflicting name settle here, the renamed
           ones are inserted again, so that a collision introduced by
           the resolution is a conflict like any other. *)
        match List.partition (Item.has_name ~name) resolved with
        | _ :: _ :: _, _ ->
          (* NOTE: The resolution is ambiguous. *)
          perform_give_up acc x xs
        | s, r ->
          List.fold_left
            (insert_aux
               ~seen:(name :: seen)
               ~on_metadata
               ~on_conflict
               ~give_up
               eq
               parent_path)
            (Item.sort (List.rev_append acc (s @ xs)))
            r)
    | x :: xs -> aux (x :: acc) xs
  in
  aux [] children

and resolve_aux eq on_metadata give_up on_conflict path previous current =
  match previous, current with
  | (Item.File _ as a), (Item.File _ as b) when eq a b ->
    (* NOTE: on two same files theres is no concrete conflict. *)
    [ a ]
  | ( Item.Directory { name; children = previous_children; metadata }
    , Item.Directory { children; metadata = new_metadata; _ } ) ->
    (* NOTE: on two directory, there is no concrete conflict. *)
    let metadata = on_metadata path metadata new_metadata in
    let children =
      List.fold_left
        (insert_aux ~on_metadata ~give_up ~on_conflict eq path)
        previous_children
        children
    in
    [ Item.dir ?metadata ~name children ]
  | _, _ -> on_conflict ~previous ~current path
;;

let insert_items ?scope ?on_metadata ?on_conflict ?give_up eq items fs =
  (* NOTE: the items are first lifted into a tree sharing the scope of
     [fs] (or the given [scope], resolved against it), so that merging
     the two lists of children positions them at the right place. *)
  let scope =
    match scope with
    | None -> fs.scope
    | Some scope -> resolve_path fs.scope scope
  in
  let { children; _ } = make ~scope items
  and path = if Path.is_absolute scope then Path.root else Path.cwd in
  { fs with
    children =
      List.fold_left
        (insert_aux ?on_metadata ?give_up ?on_conflict eq path)
        fs.children
        children
  }
;;

let merge ?on_metadata ?on_conflict ?give_up eq fs_a fs_b =
  (* NOTE: the children are already absolute from the root, so they are
     merged as they are: lifting them through [insert_items] would wrap
     them into the scope a second time. *)
  let scope_a = scope fs_a
  and scope_b = scope fs_b in
  let scope =
    match Path.common_prefix scope_a scope_b with
    | None ->
      (* KLUDGE: Can reach to a two-branch scope. *)
      scope_a
    | Some scope -> scope
  in
  let path = if Path.is_absolute scope then Path.root else Path.cwd in
  { scope
  ; children =
      List.fold_left
        (insert_aux ?on_metadata ?give_up ?on_conflict eq path)
        fs_a.children
        fs_b.children
  }
;;

module Simple = struct
  (* NOTE: A very minimal implementation of a file system that shares
     some naive characteristics with Unix. As the purpose is to be
     used primarily for testing, its support is fairly basic. *)

  module Metadata = struct
    type time = float
    type t = { mtime : time }
    type 'a clock = 'a -> time

    let const_clock x _ = x
    let make ~mtime () = { mtime }
    let equal { mtime = a } { mtime = b } = Float.equal a b

    let from_clock clock x =
      let mtime = clock x in
      make ~mtime ()
    ;;
  end

  type content = string
  type nonrec item = (content, Metadata.t) Item.t
  type nonrec t = (content, Metadata.t) t

  let equal = equal String.equal Metadata.equal
  let equal_item = Item.equal String.equal Metadata.equal

  type error =
    | Mkdir of Path.t * string
    | Stat of Path.t * string
    | Write_file of Path.t * string
    | Read_file of Path.t * string
    | Read_dir of Path.t * string
    | Remove of Path.t * string

  exception Simple_error of error

  let err_file_exists = "File exists"
  let err_no_such_target = "No such file or directory"
  let err_is_file = "Is a file"
  let err_is_directory = "Is a directory"
  let err_overriden = "Cannot be overridden"
  let err_not_empty = "Directory not empty"

  let error_s path prim err reason =
    prim ^ ": " ^ err ^ " '" ^ Path.to_string path ^ "': " ^ reason
  ;;

  let raise_error error = raise (Simple_error error)

  let mount ?(clock = Metadata.const_clock 1.0) ~scope children =
    make
      ~scope_metadata:(fun path -> Some (Metadata.make ~mtime:(clock path) ()))
      ~scope
      children
  ;;

  let from_root ?clock children = mount ?clock ~scope:Path.root children
  let from_cwd ?clock children = mount ?clock ~scope:Path.cwd children

  let file ?(clock = Metadata.const_clock 1.0) ~name content =
    file
      ~metadata:(Metadata.make ~mtime:(clock (name, content)) ())
      ~name
      content
  ;;

  let dir ?(clock = Metadata.const_clock 1.0) ~name children =
    dir ~metadata:(Metadata.make ~mtime:(clock name) ()) ~name children
  ;;

  let error_to_string = function
    | Mkdir (p, reason) -> error_s p "mkdir" "cannot create directory" reason
    | Stat (p, reason) -> error_s p "stat" "cannot statx" reason
    | Write_file (p, reason) ->
      error_s p "create_file" "cannot create file" reason
    | Read_file (p, reason) -> error_s p "read_file" "cannot read file" reason
    | Read_dir (p, reason) ->
      error_s p "read_dir" "cannot read directory" reason
    | Remove (p, reason) -> error_s p "rm" "cannot remove" reason
  ;;

  let run ?(finalizer = fun _ -> ()) callback =
    try finalizer (callback ()) with
    | Simple_error err -> err |> error_to_string |> prerr_endline
  ;;

  let create_dir ?(clock = Metadata.const_clock 1.0) ~path fs =
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
    | _, Some _ -> raise_error (Mkdir (path, err_file_exists))
    | None, _ -> raise_error (Mkdir (path, err_no_such_target))
  ;;

  let create_dir_rec ?(clock = Metadata.const_clock 1.0) ~path fs =
    let rec aux path fs =
      let file = fetch ~path fs in
      match file with
      | Some (File _) -> raise_error (Mkdir (path, err_file_exists))
      | Some (Directory _) -> fs
      | None ->
        let p = Path.dirname path in
        let fs = aux p fs in
        create_dir ~clock ~path fs
    in
    aux path fs
  ;;

  let mkdir ?(recursive = false) ?(clock = Metadata.const_clock 1.0) ~path fs =
    if recursive
    then create_dir_rec ~clock ~path fs
    else create_dir ~clock ~path fs
  ;;

  let mtime_from_metadata metadata =
    metadata
    |> Option.fold
         ~none:0.0 (* OKAY: having [0.0] as a default result seems ok. *)
         ~some:(fun Metadata.{ mtime } -> mtime)
  ;;

  let mtime_from_item item = item |> Item.metadata |> mtime_from_metadata

  let mtime ~path fs =
    match fetch ~path fs with
    | Some item -> mtime_from_item item
    | _ -> raise_error (Stat (path, err_no_such_target))
  ;;

  let write_file
        ?(overwrite = false)
        ?(clock = Metadata.const_clock 1.0)
        ~path
        content
        fs
    =
    let parent = Path.dirname path in
    match fetch ~path:parent fs, fetch ~path fs with
    | None, _ -> raise_error (Write_file (path, err_no_such_target))
    | Some _, Some (Directory _) ->
      raise_error (Write_file (path, err_is_directory))
    | Some _, Some (File _) when not overwrite ->
      raise_error (Write_file (path, err_overriden))
    | Some _, (Some _ | None) ->
      update
        ~path
        (fun ~previous:_ ~path ->
           let name = Path.basename path in
           Some (file ~clock ~name content))
        fs
  ;;

  let read_file ~path fs =
    match fetch ~path fs with
    | None -> raise_error (Read_file (path, err_no_such_target))
    | Some (Directory _) -> raise_error (Read_file (path, err_is_directory))
    | Some (File { content; _ }) -> content
  ;;

  let file_exists ~path fs =
    match fetch ~path fs with
    | None -> false
    | Some _ -> true
  ;;

  let is_directory ~path fs =
    match fetch ~path fs with
    | None -> false
    | Some item -> Item.is_directory item
  ;;

  let is_file ~path fs =
    match fetch ~path fs with
    | None -> false
    | Some item -> Item.is_file item
  ;;

  let read_dir ~path fs =
    match fetch ~path fs with
    | None -> raise_error (Read_dir (path, err_no_such_target))
    | Some (File _) -> raise_error (Read_dir (path, err_is_file))
    | Some (Directory { children; _ }) ->
      List.fold_left
        (fun map elt ->
           let key = Path.(path / Item.name elt) in
           Path.Map.add key elt map)
        Path.Map.empty
        children
  ;;

  let is_empty_dir ~path fs =
    match fetch ~path fs with
    | None -> raise_error (Read_dir (path, err_no_such_target))
    | Some (File _) -> raise_error (Read_dir (path, err_is_file))
    | Some (Directory { children = []; _ }) -> true
    | Some (Directory _) -> false
  ;;

  let rm_file ~path fs =
    match fetch ~path fs with
    | None -> raise_error (Remove (path, err_no_such_target))
    | Some (Directory _) -> raise_error (Remove (path, err_is_directory))
    | Some (File _) -> rm_file ~path fs
  ;;

  let generic_rm_dir = rm_dir

  let rec rm_dir ?(recursive = false) ~path fs =
    if recursive
    then (
      let rec aux path fs =
        if is_file ~path fs
        then rm_file ~path fs
        else if is_empty_dir ~path fs
        then rm_dir ~path fs
        else (
          let fs =
            Path.Map.fold (fun path _ fs -> aux path fs) (read_dir ~path fs) fs
          in
          rm_dir ~path fs)
      in
      aux path fs)
    else if is_empty_dir ~path fs
    then generic_rm_dir ~path fs
    else raise_error (Remove (path, err_not_empty))
  ;;

  let rm ?(recursive = false) ~path fs =
    if is_file ~path fs
    then rm_file ~path fs
    else if is_directory ~path fs
    then rm_dir ~recursive ~path fs
    else raise_error (Remove (path, err_no_such_target))
  ;;

  let insert_items ?scope ?on_metadata ?on_conflict ?give_up items fs =
    insert_items ?scope ?on_metadata ?on_conflict ?give_up equal_item items fs
  ;;

  let merge ?on_metadata ?on_conflict ?give_up items fs =
    merge ?on_metadata ?on_conflict ?give_up equal_item items fs
  ;;

  let unfold = unfold
  let unfold_with_content = unfold_with_content
end
