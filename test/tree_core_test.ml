(* Copyright (c) 2026, Cargocut and the Virtfs developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

let fetch fs path =
  match Tree.fetch fs path with
  | None -> print_endline (Path.to_filename path ^ ": Not found")
  | Some item ->
    let name = Tree.name item in
    (match Tree.content item with
     | `File s -> name ^ ": " ^ s
     | `Directory xs -> Tree.tree (Tree.make ~scope:path xs))
    |> print_endline
;;

let%expect_test "a simple ls" =
  let fs =
    let open Tree in
    make
      [ dir ~name:"foo" []
      ; dir ~name:"bar" []
      ; file ~name:"config.ini" "config file"
      ]
  in
  fs |> Tree.ls |> List.iter print_endline;
  [%expect
    {|
    foo/
    bar/
    config.ini
    |}]
;;

let%expect_test "a simple ls from root" =
  let fs =
    let open Tree in
    from_root
      [ dir ~name:"foo" []
      ; dir ~name:"bar" []
      ; file ~name:"config.ini" "config file"
      ]
  in
  fs |> Tree.ls |> List.iter print_endline;
  [%expect {| / |}]
;;

let%expect_test "a simple ls from cwd" =
  let fs =
    let open Tree in
    from_cwd
      [ dir ~name:"foo" []
      ; dir ~name:"bar" []
      ; file ~name:"config.ini" "config file"
      ]
  in
  fs |> Tree.ls |> List.iter print_endline;
  [%expect {| ./ |}]
;;

let%expect_test "a simple tree" =
  let fs =
    let open Tree in
    make
      [ dir ~name:"foo" []
      ; dir
          ~name:"bar"
          [ dir ~name:"baz" [ file ~name:"index.md" "Hello World" ] ]
      ; file ~name:"config.ini" "config file"
      ]
  in
  fs |> Tree.tree |> print_endline;
  [%expect
    {|
    └─foo/
    └─bar/
      └─baz/
        └─index.md
    └─config.ini
    |}]
;;

let%expect_test "a simple tree with scope" =
  let fs =
    let open Tree in
    make
      ~scope:Path.(~/[ "a"; "b"; "c"; "d" ])
      [ dir ~name:"foo" []
      ; dir
          ~name:"bar"
          [ dir ~name:"baz" [ file ~name:"index.md" "Hello World" ] ]
      ; file ~name:"config.ini" "config file"
      ]
  in
  fs |> Tree.tree |> print_endline;
  [%expect
    {|
    └─./
      └─a/
        └─b/
          └─c/
            └─d/
              └─bar/
                └─baz/
                  └─index.md
              └─foo/
              └─config.ini
    |}]
;;

let%expect_test "fetch" =
  let fs =
    let open Tree in
    make
      ~scope:Path.(~/[ "a"; "b"; "c"; "d" ])
      [ dir ~name:"foo" []
      ; dir
          ~name:"bar"
          [ dir ~name:"baz" [ file ~name:"index.md" "Hello World" ] ]
      ; file ~name:"config.ini" "config file"
      ]
  in
  Path.(rel [ "a"; "b"; "c"; "d"; "config.ini" ]) |> fetch fs;
  [%expect {| config.ini: config file |}]
;;

let%expect_test "fetch" =
  let fs =
    let open Tree in
    make
      ~scope:Path.(~/[ "a"; "b"; "c"; "d" ])
      [ dir ~name:"foo" []
      ; dir
          ~name:"bar"
          [ dir ~name:"baz" [ file ~name:"index.md" "Hello World" ] ]
      ; file ~name:"config.ini" "config file"
      ]
  in
  Path.(rel [ "a"; "b"; "c"; "d"; "bar" ]) |> fetch fs;
  [%expect
    {|
    └─./
      └─a/
        └─b/
          └─c/
            └─d/
              └─bar/
                └─baz/
                  └─index.md
    |}]
;;

let%expect_test "fetch" =
  let fs =
    let open Tree in
    make
      ~scope:Path.(~/[ "a"; "b"; "c"; "e" ])
      [ dir ~name:"foo" []
      ; dir
          ~name:"bar"
          [ dir ~name:"baz" [ file ~name:"index.md" "Hello World" ] ]
      ; file ~name:"config.ini" "config file"
      ]
  in
  Path.(rel [ "a"; "b"; "c"; "d"; "bar" ]) |> fetch fs;
  [%expect {| ./a/b/c/d/bar: Not found |}]
;;

let%expect_test "cat on file" =
  let fs =
    let open Tree in
    make
      ~scope:Path.(~/[ "a"; "b"; "c"; "d" ])
      [ dir ~name:"foo" []
      ; dir
          ~name:"bar"
          [ dir ~name:"baz" [ file ~name:"index.md" "Hello World" ] ]
      ; file ~name:"config.ini" "config file"
      ]
  in
  Path.rel [ "a"; "b"; "c"; "d"; "bar"; "baz"; "index.md" ]
  |> Tree.cat ~to_string:Fun.id fs
  |> print_endline;
  [%expect {| Hello World |}]
;;

let%expect_test "cat on folder" =
  let fs =
    let open Tree in
    make
      ~scope:Path.(~/[ "a"; "b"; "c"; "d" ])
      [ dir ~name:"foo" []
      ; dir
          ~name:"bar"
          [ dir ~name:"baz" [ file ~name:"index.md" "Hello World" ] ]
      ; file ~name:"config.ini" "config file"
      ]
  in
  Path.rel [ "a"; "b"; "c"; "d"; "bar"; "baz" ]
  |> Tree.cat ~to_string:Fun.id fs
  |> print_endline;
  [%expect {| cat: ./a/b/c/d/bar/baz: Is a directory |}]
;;

let%expect_test "cat on missing element" =
  let fs =
    let open Tree in
    make
      ~scope:Path.(~/[ "a"; "b"; "c"; "d" ])
      [ dir ~name:"foo" []
      ; dir
          ~name:"bar"
          [ dir ~name:"baz" [ file ~name:"index.md" "Hello World" ] ]
      ; file ~name:"config.ini" "config file"
      ]
  in
  Path.rel [ "a"; "b"; "c"; "d"; "bar"; "not-present" ]
  |> Tree.cat ~to_string:Fun.id fs
  |> print_endline;
  [%expect {| cat: ./a/b/c/d/bar/not-present: No such file or directory |}]
;;
