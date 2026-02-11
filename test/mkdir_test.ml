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

let finalizer fs = fs |> T.tree |> print_endline

let%expect_test "mkdir when nested path does not exists" =
  let clock _ = 2.0 in
  let path = Path.abs [ "1-foo"; "bar"; "baz"; "a-directory" ] in
  U.run ~finalizer (fun () -> fs |> U.mkdir ~clock ~path);
  [%expect
    {| mkdir: cannot create directory '/1-foo/bar/baz/a-directory': No such file or directory |}]
;;

let%expect_test "mkdir when target exists" =
  let clock _ = 2.0 in
  let path = Path.abs [ "1-foo"; "bar" ] in
  U.run (fun () -> fs |> U.mkdir ~clock ~path);
  [%expect {| mkdir: cannot create directory '/1-foo/bar': File exists |}]
;;

let%expect_test "mkdir" =
  let clock _ = 2.0 in
  let path = Path.abs [ "1-foo"; "bar"; "storage" ] in
  U.run
    (fun () ->
       let fs = fs |> U.mkdir ~clock ~path in
       let tm = U.mtime ~path fs in
       fs, tm)
    ~finalizer:(fun (fs, tm) ->
      tm |> Float.to_string |> print_endline;
      fs |> T.tree |> print_endline);
  [%expect
    {|
    2.

    └─/
      └─1-foo/
        └─bar/
          └─storage/
          └─index.md
      └─2-foo/
        └─bar/
          └─baz/
            └─index.md
      └─3-foo/
        └─bar/
    |}]
;;

let%expect_test "mkdir recursive" =
  let clock _ = 5.0 in
  let path = Path.abs [ "1-foo"; "bar"; "index.md" ] in
  U.run
    (fun () ->
       let fs = fs |> U.mkdir ~recursive:true ~clock ~path in
       let tm = U.mtime ~path fs in
       fs, tm)
    ~finalizer:(fun (fs, tm) ->
      tm |> Float.to_string |> print_endline;
      fs |> T.tree |> print_endline);
  [%expect
    {| mkdir: cannot create directory '/1-foo/bar/index.md': File exists |}]
;;

let%expect_test "mkdir recursive" =
  let clock _ = 5.0 in
  let path = Path.abs [ "1-foo"; "bar" ] in
  U.run
    (fun () ->
       let fs = fs |> U.mkdir ~recursive:true ~clock ~path in
       let tm = U.mtime ~path fs in
       fs, tm)
    ~finalizer:(fun (fs, tm) ->
      tm |> Float.to_string |> print_endline;
      fs |> T.tree |> print_endline);
  [%expect
    {|
    1.

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

let%expect_test "mkdir recursive" =
  let clock _ = 5.0 in
  let path = Path.abs [ "4-foo"; "bar"; "baz"; "storage" ] in
  U.run
    (fun () ->
       let fs = fs |> U.mkdir ~recursive:true ~clock ~path in
       let tm = U.mtime ~path fs in
       fs, tm)
    ~finalizer:(fun (fs, tm) ->
      tm |> Float.to_string |> print_endline;
      fs |> T.tree |> print_endline);
  [%expect
    {|
    5.

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
      └─4-foo/
        └─bar/
          └─baz/
            └─storage/
    |}]
;;
