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

let%expect_test "rm_file on a directory" =
  let path = Path.abs [ "1-foo" ] in
  U.run ~finalizer (fun () -> U.rm_file ~path fs);
  [%expect {| rm: cannot remove '/1-foo': Is a directory |}]
;;

let%expect_test "rm_file on absent" =
  let path = Path.abs [ "1-foo"; "foo.md" ] in
  U.run ~finalizer (fun () -> U.rm_file ~path fs);
  [%expect {| rm: cannot remove '/1-foo/foo.md': No such file or directory |}]
;;

let%expect_test "rm_file on a file" =
  let path = Path.abs [ "1-foo"; "bar"; "index.md" ] in
  U.run ~finalizer (fun () -> U.rm_file ~path fs);
  [%expect
    {|
    └─/
      └─1-foo/
        └─bar/
      └─2-foo/
        └─bar/
          └─baz/
            └─index.md
      └─3-foo/
        └─bar/
    |}]
;;

let%expect_test "rm_dir on a file" =
  let path = Path.abs [ "1-foo"; "bar"; "index.md" ] in
  U.run ~finalizer (fun () -> U.rm_dir ~path fs);
  [%expect
    {| read_dir: cannot read directory '/1-foo/bar/index.md': Is a file |}]
;;

let%expect_test "rm_dir on absent" =
  let path = Path.abs [ "1-foo"; "baz" ] in
  U.run ~finalizer (fun () -> U.rm_dir ~path fs);
  [%expect
    {| read_dir: cannot read directory '/1-foo/baz': No such file or directory |}]
;;

let%expect_test "rm_dir on an non-empty directory" =
  let path = Path.abs [ "1-foo" ] in
  U.run ~finalizer (fun () -> U.rm_dir ~path fs);
  [%expect {| rm: cannot remove '/1-foo': Directory not empty |}]
;;

let%expect_test "rm_dir on an empty directory" =
  let path = Path.abs [ "3-foo"; "bar" ] in
  U.run ~finalizer (fun () -> U.rm_dir ~path fs);
  [%expect
    {|
    └─/
      └─1-foo/
        └─bar/
          └─index.md
      └─2-foo/
        └─bar/
          └─baz/
            └─index.md
      └─3-foo/
    |}]
;;

let%expect_test "rm on absent" =
  let path = Path.abs [ "3-foo"; "baz" ] in
  U.run ~finalizer (fun () -> U.rm ~path fs);
  [%expect {| rm: cannot remove '/3-foo/baz': No such file or directory |}]
;;

let%expect_test "rm on non-empty directory" =
  let path = Path.abs [ "3-foo" ] in
  U.run ~finalizer (fun () -> U.rm ~path fs);
  [%expect {| rm: cannot remove '/3-foo': Directory not empty |}]
;;

let%expect_test "rm on an empty directory" =
  let path = Path.abs [ "3-foo"; "bar" ] in
  U.run ~finalizer (fun () -> U.rm ~path fs);
  [%expect
    {|
    └─/
      └─1-foo/
        └─bar/
          └─index.md
      └─2-foo/
        └─bar/
          └─baz/
            └─index.md
      └─3-foo/
    |}]
;;

let%expect_test "rm on a file" =
  let path = Path.abs [ "1-foo"; "bar"; "index.md" ] in
  U.run ~finalizer (fun () -> U.rm ~path fs);
  [%expect
    {|
    └─/
      └─1-foo/
        └─bar/
      └─2-foo/
        └─bar/
          └─baz/
            └─index.md
      └─3-foo/
        └─bar/
    |}]
;;

let%expect_test "rm-dir recursive" =
  let path = Path.abs [ "1-foo" ] in
  U.run ~finalizer (fun () -> U.rm_dir ~recursive:true ~path fs);
  [%expect
    {|
    └─/
      └─2-foo/
        └─bar/
          └─baz/
            └─index.md
      └─3-foo/
        └─bar/
    |}]
;;

let%expect_test "rm-dir recursive" =
  let path = Path.root in
  U.run ~finalizer (fun () -> U.rm_dir ~recursive:true ~path fs);
  [%expect {| |}]
;;
