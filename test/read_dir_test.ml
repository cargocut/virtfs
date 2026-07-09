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
        [ dir
            ~name:"bar"
            [ file ~name:"index.md" "Hello World"
            ; file ~name:"index-2.md" "Hello World"
            ; file ~name:"index-3.md" "Hello World"
            ; file ~name:"index-4.md" "Hello World"
            ; file ~name:"index-5-final-version.md" "Hello World"
            ]
        ]
    ; dir
        ~name:"2-foo"
        [ dir
            ~name:"bar"
            [ dir ~name:"baz" [ file ~name:"index.md" "Hello World 2" ] ]
        ]
    ; dir ~name:"3-foo" [ dir ~name:"bar" [] ]
    ]
;;

let finalizer p =
  Path.Map.iter (fun path elt ->
    let ps = Path.to_string path in
    let es = T.Item.name_to_string elt in
    ps ^ " -> " ^ es |> print_endline) p
;;

let%expect_test "read_directory without target" =
  let path = Path.abs [ "4-foo" ] in
  U.run (fun () -> U.read_dir ~path fs) ~finalizer;
  [%expect
    {| read_dir: cannot read directory '/4-foo': No such file or directory |}]
;;

let%expect_test "read_directory on a file" =
  let path = Path.abs [ "2-foo"; "bar"; "baz"; "index.md" ] in
  U.run (fun () -> U.read_dir ~path fs) ~finalizer;
  [%expect
    {| read_dir: cannot read directory '/2-foo/bar/baz/index.md': Is a file |}]
;;

let%expect_test "read_directory" =
  let path = Path.root in
  U.run (fun () -> U.read_dir ~path fs) ~finalizer;
  [%expect
    {|
    /1-foo -> 1-foo/
    /2-foo -> 2-foo/
    /3-foo -> 3-foo/
    |}]
;;

let%expect_test "read_directory" =
  let path = Path.abs [ "1-foo" ] in
  U.run (fun () -> U.read_dir ~path fs) ~finalizer;
  [%expect {| /1-foo/bar -> bar/ |}]
;;

let%expect_test "read_directory" =
  let path = Path.abs [ "1-foo"; "bar" ] in
  U.run (fun () -> U.read_dir ~path fs) ~finalizer;
  [%expect
    {|
    /1-foo/bar/index-2.md -> index-2.md
    /1-foo/bar/index-3.md -> index-3.md
    /1-foo/bar/index-4.md -> index-4.md
    /1-foo/bar/index-5-final-version.md -> index-5-final-version.md
    /1-foo/bar/index.md -> index.md
    |}]
;;

let%expect_test "is_empty_dir on absent target" =
  let path = Path.abs [ "0-foo" ] in
  U.run
    (fun () -> U.is_empty_dir ~path fs)
    ~finalizer:(fun x -> x |> string_of_bool |> print_endline);
  [%expect
    {| read_dir: cannot read directory '/0-foo': No such file or directory |}]
;;

let%expect_test "is_empty_dir on file" =
  let path = Path.abs [ "1-foo"; "bar"; "index.md" ] in
  U.run
    (fun () -> U.is_empty_dir ~path fs)
    ~finalizer:(fun x -> x |> string_of_bool |> print_endline);
  [%expect
    {| read_dir: cannot read directory '/1-foo/bar/index.md': Is a file |}]
;;

let%expect_test "is_empty_dir on empty dir" =
  let path = Path.abs [ "3-foo"; "bar" ] in
  U.run
    (fun () -> U.is_empty_dir ~path fs)
    ~finalizer:(fun x -> x |> string_of_bool |> print_endline);
  [%expect {| true |}]
;;

let%expect_test "is_empty_dir on dir" =
  let path = Path.abs [ "1-foo"; "bar" ] in
  U.run
    (fun () -> U.is_empty_dir ~path fs)
    ~finalizer:(fun x -> x |> string_of_bool |> print_endline);
  [%expect {| false |}]
;;
