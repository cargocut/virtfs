(* Copyright (c) 2026, Cargocut and the Virtfs developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

module T = Tree
module U = T.Dummy

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

let%expect_test "mkdir when nested path does not exists" =
  let clock _ = 2.0 in
  let path = Path.abs [ "1-foo"; "bar"; "baz"; "a-directory" ] in
  let f () =
    try fs |> U.mkdir ~clock ~path |> T.tree |> print_endline with
    | U.Dummy_tree err -> err |> U.error_to_string |> print_endline
  in
  f ();
  [%expect
    {| mkdir: cannot create directory '/1-foo/bar/baz/a-directory': No such file or directory |}]
;;

let%expect_test "mkdir when target exists" =
  let clock _ = 2.0 in
  let path = Path.abs [ "1-foo"; "bar" ] in
  let f () =
    try fs |> U.mkdir ~clock ~path |> T.tree |> print_endline with
    | U.Dummy_tree err -> err |> U.error_to_string |> print_endline
  in
  f ();
  [%expect {| mkdir: cannot create directory '/1-foo/bar': File exists |}]
;;

let%expect_test "mkdir" =
  let clock _ = 2.0 in
  let path = Path.abs [ "1-foo"; "bar"; "storage" ] in
  let f () =
    try
      let fs = fs |> U.mkdir ~clock ~path in
      let tm = U.mtime ~path fs in
      tm |> Float.to_string |> print_endline;
      fs |> T.tree |> print_endline
    with
    | U.Dummy_tree err -> err |> U.error_to_string |> print_endline
  in
  f ();
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

let%expect_test "mkdir_p" =
  let clock _ = 5.0 in
  let path = Path.abs [ "1-foo"; "bar"; "index.md" ] in
  let f () =
    try
      let fs = fs |> U.mkdir_p ~clock ~path in
      let tm = U.mtime ~path fs in
      tm |> Float.to_string |> print_endline;
      fs |> T.tree |> print_endline
    with
    | U.Dummy_tree err -> err |> U.error_to_string |> print_endline
  in
  f ();
  [%expect
    {| mkdir: cannot create directory '/1-foo/bar/index.md': File exists |}]
;;

let%expect_test "mkdir_p" =
  let clock _ = 5.0 in
  let path = Path.abs [ "1-foo"; "bar" ] in
  let f () =
    try
      let fs = fs |> U.mkdir_p ~clock ~path in
      let tm = U.mtime ~path fs in
      tm |> Float.to_string |> print_endline;
      fs |> T.tree |> print_endline
    with
    | U.Dummy_tree err -> err |> U.error_to_string |> print_endline
  in
  f ();
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

let%expect_test "mkdir_p" =
  let clock _ = 5.0 in
  let path = Path.abs [ "4-foo"; "bar"; "baz"; "storage" ] in
  let f () =
    try
      let fs = fs |> U.mkdir_p ~clock ~path in
      let tm = U.mtime ~path fs in
      tm |> Float.to_string |> print_endline;
      fs |> T.tree |> print_endline
    with
    | U.Dummy_tree err -> err |> U.error_to_string |> print_endline
  in
  f ();
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
