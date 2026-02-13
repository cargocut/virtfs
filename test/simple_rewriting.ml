(* Copyright (c) 2026, Cargocut and the Virtfs developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(* Ensure that the [Tree] (and [Item]) module is not too abstract. *)

module Simple = struct
  type time = float
  type 'a clock = 'a -> time
  type metadata = { mtime : time }
  type content = string
  type nonrec item = (content, metadata) Tree.Item.t
  type nonrec t = (content, metadata) Tree.t

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
  let const_clock x _ = x

  let mount ?(clock = const_clock 1.0) ~scope children =
    Tree.make
      ~scope_metadata:(fun path -> Some { mtime = clock path })
      ~scope
      children
  ;;

  let file ?(clock = const_clock 1.0) ~name content =
    Tree.file ~metadata:{ mtime = clock (name, content) } ~name content
  ;;

  let dir ?(clock = const_clock 1.0) ~name children =
    Tree.dir ~metadata:{ mtime = clock name } ~name children
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

  let create_dir ?(clock = const_clock 1.0) ~path fs =
    let dname = Path.dirname path in
    match Tree.fetch ~path:dname fs, Tree.fetch ~path fs with
    | Some _, None ->
      Tree.update
        ~path
        (fun ~previous:_ ~path ->
           let bname = Path.basename path in
           let item = dir ~clock ~name:bname [] in
           Some item)
        fs
    | _, Some _ -> raise_error (Mkdir (path, err_file_exists))
    | None, _ -> raise_error (Mkdir (path, err_no_such_target))
  ;;

  let create_dir_rec ?(clock = const_clock 1.0) ~path fs =
    let rec aux path fs =
      let file = Tree.fetch ~path fs in
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

  let mkdir ?(recursive = false) ?(clock = const_clock 1.0) ~path fs =
    if recursive
    then create_dir_rec ~clock ~path fs
    else create_dir ~clock ~path fs
  ;;

  let mtime ~path fs =
    match Tree.fetch ~path fs with
    | Some item ->
      item
      |> Tree.Item.metadata
      |> Option.fold
           ~none:0.0 (* OKAY: having [0.0] as a default result seems ok. *)
           ~some:(fun { mtime } -> mtime)
    | _ -> raise_error (Stat (path, err_no_such_target))
  ;;

  let write_file
        ?(overwrite = false)
        ?(clock = const_clock 1.0)
        ~path
        content
        fs
    =
    let parent = Path.dirname path in
    match Tree.fetch ~path:parent fs, Tree.fetch ~path fs with
    | None, _ -> raise_error (Write_file (path, err_no_such_target))
    | Some _, Some (Directory _) ->
      raise_error (Write_file (path, err_is_directory))
    | Some _, Some (File _) when not overwrite ->
      raise_error (Write_file (path, err_overriden))
    | Some _, (Some _ | None) ->
      Tree.update
        ~path
        (fun ~previous:_ ~path ->
           let name = Path.basename path in
           Some (file ~clock ~name content))
        fs
  ;;

  let read_file ~path fs =
    match Tree.fetch ~path fs with
    | None -> raise_error (Read_file (path, err_no_such_target))
    | Some (Directory _) -> raise_error (Read_file (path, err_is_directory))
    | Some (File { content; _ }) -> content
  ;;

  let file_exists ~path fs =
    match Tree.fetch ~path fs with
    | None -> false
    | Some _ -> true
  ;;

  let is_directory ~path fs =
    match Tree.fetch ~path fs with
    | None -> false
    | Some item -> Tree.Item.is_directory item
  ;;

  let is_file ~path fs =
    match Tree.fetch ~path fs with
    | None -> false
    | Some item -> Tree.Item.is_file item
  ;;

  let read_dir ~path fs =
    match Tree.fetch ~path fs with
    | None -> raise_error (Read_dir (path, err_no_such_target))
    | Some (File _) -> raise_error (Read_dir (path, err_is_file))
    | Some (Directory { children; _ }) ->
      List.fold_left
        (fun map elt ->
           let key = Path.(path / Tree.Item.name elt) in
           Path.Map.add key elt map)
        Path.Map.empty
        children
  ;;

  let is_empty_dir ~path fs =
    match Tree.fetch ~path fs with
    | None -> raise_error (Read_dir (path, err_no_such_target))
    | Some (File _) -> raise_error (Read_dir (path, err_is_file))
    | Some (Directory { children = []; _ }) -> true
    | Some (Directory _) -> false
  ;;

  let rm_file ~path fs =
    match Tree.fetch ~path fs with
    | None -> raise_error (Remove (path, err_no_such_target))
    | Some (Directory _) -> raise_error (Remove (path, err_is_directory))
    | Some (File _) -> Tree.rm_file ~path fs
  ;;

  let generic_rm_dir = Tree.rm_dir

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
end

module T = Tree
module U = T.Simple

let fs =
  let open U in
  mount
    ~scope:Path.root
    [ dir
        ~name:"1-foo"
        [ dir ~name:"bar" [ file ~name:"index.md" "Hello World" ] ]
    ; dir
        ~name:"2-foo"
        [ dir
            ~name:"bar"
            [ dir ~name:"baz" [ file ~name:"index.md" "Hello World 2" ] ]
        ]
    ; dir ~name:"3-foo" [ dir ~name:"bar" [] ]
    ]
;;

let finalizer (fs, tm, ct) =
  print_endline ("mtime: " ^ Float.to_string tm);
  print_endline ct;
  fs |> T.tree |> print_endline
;;

let%expect_test "writing on a directory" =
  let clock _ = 5.0
  and path = Path.abs [ "1-foo"; "bar" ] in
  U.run
    (fun () ->
       let fs = fs |> U.write_file ~clock ~path "My new content" in
       let tm = U.mtime ~path fs
       and ct = U.read_file ~path fs in
       fs, tm, ct)
    ~finalizer;
  [%expect {| create_file: cannot create file '/1-foo/bar': Is a directory |}]
;;

let%expect_test "writing a file in an invalid path" =
  let clock _ = 5.0
  and path = Path.abs [ "4-foo"; "index.md" ] in
  U.run
    (fun () ->
       let fs = fs |> U.write_file ~clock ~path "My new content" in
       let tm = U.mtime ~path fs
       and ct = U.read_file ~path fs in
       fs, tm, ct)
    ~finalizer;
  [%expect
    {| create_file: cannot create file '/4-foo/index.md': No such file or directory |}]
;;

let%expect_test "writing on an existing file (without overwrite flag)" =
  let clock _ = 5.0
  and path = Path.abs [ "1-foo"; "bar"; "index.md" ] in
  U.run
    (fun () ->
       let fs = fs |> U.write_file ~clock ~path "My new content" in
       let tm = U.mtime ~path fs
       and ct = U.read_file ~path fs in
       fs, tm, ct)
    ~finalizer;
  [%expect
    {| create_file: cannot create file '/1-foo/bar/index.md': Cannot be overridden |}]
;;

let%expect_test "writing on an existing file (with overwrite flag)" =
  let clock _ = 5.0
  and path = Path.abs [ "1-foo"; "bar"; "index.md" ] in
  U.run
    (fun () ->
       let fs =
         fs |> U.write_file ~overwrite:true ~clock ~path "My new content"
       in
       let tm = U.mtime ~path fs
       and ct = U.read_file ~path fs in
       fs, tm, ct)
    ~finalizer;
  [%expect
    {|
    mtime: 5.
    My new content

    └─/
      └─1-foo/
        └─bar/
          └─index.md
      └─2-foo/
        └─bar/
          └─baz/
            └─index.md
      └─3-foo/
        └─bar/
    |}]
;;

let%expect_test "writing on a new file" =
  let clock _ = 5.0
  and path = Path.abs [ "1-foo"; "bar"; "index-2.md" ] in
  U.run
    (fun () ->
       let fs = fs |> U.write_file ~clock ~path "My new content" in
       let tm = U.mtime ~path fs
       and ct = U.read_file ~path fs in
       fs, tm, ct)
    ~finalizer;
  [%expect
    {|
    mtime: 5.
    My new content

    └─/
      └─1-foo/
        └─bar/
          └─index-2.md
          └─index.md
      └─2-foo/
        └─bar/
          └─baz/
            └─index.md
      └─3-foo/
        └─bar/
    |}]
;;

let%expect_test "read_file on a directory" =
  let path = Path.abs [ "1-foo"; "bar" ] in
  U.run (fun () -> U.read_file ~path fs) ~finalizer:print_endline;
  [%expect {| read_file: cannot read file '/1-foo/bar': Is a directory |}]
;;

let%expect_test "read_file when not exists" =
  let path = Path.abs [ "1-foo"; "bar.md" ] in
  U.run (fun () -> U.read_file ~path fs) ~finalizer:print_endline;
  [%expect
    {| read_file: cannot read file '/1-foo/bar.md': No such file or directory |}]
;;

let%expect_test "read_file" =
  let path = Path.abs [ "1-foo"; "bar"; "index.md" ] in
  U.run (fun () -> U.read_file ~path fs) ~finalizer:print_endline;
  [%expect {| Hello World |}]
;;
