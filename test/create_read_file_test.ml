(* Copyright (c) 2026, Cargocut and the Virtfs developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

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
  [%expect
    {| Hello World |}]
;;
