(* Copyright (c) 2026, Cargocut and the Virtfs developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

let base_fs =
  let open Tree in
  from_cwd
    [ dir
        ~metadata:(Some 0)
        ~name:"a"
        [ dir
            ~name:"a1"
            [ file ~name:"article-a1-1.md" "0"
            ; file ~name:"article-a1-2.md" "1"
            ]
        ; dir
            ~name:"a2"
            [ file ~name:"article-a2-1.md" "3"
            ; file ~name:"article-a2-2.md" "4"
            ; file ~name:"article-a2-3.md" "5"
            ; file ~name:"article-a2-4.md" "6"
            ]
        ; dir
            ~name:"a3"
            [ file ~name:"article-a3-1.md" "7"
            ; file ~name:"article-a3-2.md" "8"
            ; file ~name:"article-a3-3.md" "9"
            ; file ~name:"article-a3-4.md" "10"
            ]
        ; dir
            ~name:"a4"
            [ dir
                ~name:"foo"
                [ file ~name:"foobar.md" "Hello World"
                ; file ~name:"bar.md" "Hello World from A"
                ]
            ]
        ]
    ; dir
        ~name:"b"
        [ dir ~name:"b1" [ file ~name:"article-b1-1.md" "b1" ]
        ; dir ~name:"b2" [ file ~name:"article-b2-1.md" "b2" ]
        ; dir ~name:"b3" []
        ; dir ~name:"b4" [ file ~name:"article-b4-1.md" "b4" ]
        ]
    ; dir
        ~name:"c"
        [ dir ~name:"c1" []
        ; dir ~name:"c2" []
        ; dir ~name:"c3" []
        ; dir ~name:"c4" []
        ]
    ]
;;

let%expect_test "A complicated tree" =
  base_fs |> Tree.tree |> print_endline;
  [%expect
    {|
    └─./
      └─a/
        └─a1/
          └─article-a1-1.md
          └─article-a1-2.md
        └─a2/
          └─article-a2-1.md
          └─article-a2-2.md
          └─article-a2-3.md
          └─article-a2-4.md
        └─a3/
          └─article-a3-1.md
          └─article-a3-2.md
          └─article-a3-3.md
          └─article-a3-4.md
        └─a4/
          └─foo/
            └─bar.md
            └─foobar.md
      └─b/
        └─b1/
          └─article-b1-1.md
        └─b2/
          └─article-b2-1.md
        └─b3/
        └─b4/
          └─article-b4-1.md
      └─c/
        └─c1/
        └─c2/
        └─c3/
        └─c4/
    |}]
;;

let%expect_test "touch" =
  base_fs
  |> Tree.touch ~path:(Path.rel [ "c"; "c3"; "a-c-file.md" ]) "CONTENT"
  |> Tree.tree
  |> print_endline;
  [%expect
    {|
    └─./
      └─a/
        └─a1/
          └─article-a1-1.md
          └─article-a1-2.md
        └─a2/
          └─article-a2-1.md
          └─article-a2-2.md
          └─article-a2-3.md
          └─article-a2-4.md
        └─a3/
          └─article-a3-1.md
          └─article-a3-2.md
          └─article-a3-3.md
          └─article-a3-4.md
        └─a4/
          └─foo/
            └─bar.md
            └─foobar.md
      └─b/
        └─b1/
          └─article-b1-1.md
        └─b2/
          └─article-b2-1.md
        └─b3/
        └─b4/
          └─article-b4-1.md
      └─c/
        └─c1/
        └─c2/
        └─c3/
          └─a-c-file.md
        └─c4/
    |}]
;;

let%expect_test "rm_file should not impact the file system on directory" =
  base_fs
  |> Tree.rm_file ~path:(Path.rel [ "a"; "a1" ])
  |> Tree.tree
  |> print_endline;
  [%expect
    {|
    └─./
      └─a/
        └─a1/
          └─article-a1-1.md
          └─article-a1-2.md
        └─a2/
          └─article-a2-1.md
          └─article-a2-2.md
          └─article-a2-3.md
          └─article-a2-4.md
        └─a3/
          └─article-a3-1.md
          └─article-a3-2.md
          └─article-a3-3.md
          └─article-a3-4.md
        └─a4/
          └─foo/
            └─bar.md
            └─foobar.md
      └─b/
        └─b1/
          └─article-b1-1.md
        └─b2/
          └─article-b2-1.md
        └─b3/
        └─b4/
          └─article-b4-1.md
      └─c/
        └─c1/
        └─c2/
        └─c3/
        └─c4/
    |}]
;;

let%expect_test "rm_dir should not impact the file system on file" =
  base_fs
  |> Tree.rm_dir ~path:(Path.rel [ "a"; "a1"; "article-a1-1.md" ])
  |> Tree.tree
  |> print_endline;
  [%expect
    {|
    └─./
      └─a/
        └─a1/
          └─article-a1-1.md
          └─article-a1-2.md
        └─a2/
          └─article-a2-1.md
          └─article-a2-2.md
          └─article-a2-3.md
          └─article-a2-4.md
        └─a3/
          └─article-a3-1.md
          └─article-a3-2.md
          └─article-a3-3.md
          └─article-a3-4.md
        └─a4/
          └─foo/
            └─bar.md
            └─foobar.md
      └─b/
        └─b1/
          └─article-b1-1.md
        └─b2/
          └─article-b2-1.md
        └─b3/
        └─b4/
          └─article-b4-1.md
      └─c/
        └─c1/
        └─c2/
        └─c3/
        └─c4/
    |}]
;;

let%expect_test "rm_file should impact the file system on file" =
  base_fs
  |> Tree.rm_file ~path:(Path.rel [ "a"; "a1"; "article-a1-1.md" ])
  |> Tree.tree
  |> print_endline;
  [%expect
    {|
    └─./
      └─a/
        └─a1/
          └─article-a1-2.md
        └─a2/
          └─article-a2-1.md
          └─article-a2-2.md
          └─article-a2-3.md
          └─article-a2-4.md
        └─a3/
          └─article-a3-1.md
          └─article-a3-2.md
          └─article-a3-3.md
          └─article-a3-4.md
        └─a4/
          └─foo/
            └─bar.md
            └─foobar.md
      └─b/
        └─b1/
          └─article-b1-1.md
        └─b2/
          └─article-b2-1.md
        └─b3/
        └─b4/
          └─article-b4-1.md
      └─c/
        └─c1/
        └─c2/
        └─c3/
        └─c4/
    |}]
;;

let%expect_test "rm_dir should impact the file system on directory" =
  base_fs |> Tree.rm_dir ~path:(Path.rel [ "c" ]) |> Tree.tree |> print_endline;
  [%expect
    {|
    └─./
      └─a/
        └─a1/
          └─article-a1-1.md
          └─article-a1-2.md
        └─a2/
          └─article-a2-1.md
          └─article-a2-2.md
          └─article-a2-3.md
          └─article-a2-4.md
        └─a3/
          └─article-a3-1.md
          └─article-a3-2.md
          └─article-a3-3.md
          └─article-a3-4.md
        └─a4/
          └─foo/
            └─bar.md
            └─foobar.md
      └─b/
        └─b1/
          └─article-b1-1.md
        └─b2/
          └─article-b2-1.md
        └─b3/
        └─b4/
          └─article-b4-1.md
    |}]
;;

let%expect_test "rm should impact the file system on directory" =
  base_fs
  |> Tree.rm ~path:(Path.rel [ "a"; "a2" ])
  |> Tree.tree
  |> print_endline;
  [%expect
    {|
    └─./
      └─a/
        └─a1/
          └─article-a1-1.md
          └─article-a1-2.md
        └─a3/
          └─article-a3-1.md
          └─article-a3-2.md
          └─article-a3-3.md
          └─article-a3-4.md
        └─a4/
          └─foo/
            └─bar.md
            └─foobar.md
      └─b/
        └─b1/
          └─article-b1-1.md
        └─b2/
          └─article-b2-1.md
        └─b3/
        └─b4/
          └─article-b4-1.md
      └─c/
        └─c1/
        └─c2/
        └─c3/
        └─c4/
    |}]
;;

let%expect_test "rm should impact the file system on directory" =
  base_fs |> Tree.rm ~path:(Path.rel [ "a" ]) |> Tree.tree |> print_endline;
  [%expect
    {|
    └─./
      └─b/
        └─b1/
          └─article-b1-1.md
        └─b2/
          └─article-b2-1.md
        └─b3/
        └─b4/
          └─article-b4-1.md
      └─c/
        └─c1/
        └─c2/
        └─c3/
        └─c4/
    |}]
;;

let%expect_test "rm should impact the file system on file" =
  base_fs
  |> Tree.rm ~path:(Path.rel [ "b"; "b2"; "article-b2-1.md" ])
  |> Tree.tree
  |> print_endline;
  [%expect
    {|
    └─./
      └─a/
        └─a1/
          └─article-a1-1.md
          └─article-a1-2.md
        └─a2/
          └─article-a2-1.md
          └─article-a2-2.md
          └─article-a2-3.md
          └─article-a2-4.md
        └─a3/
          └─article-a3-1.md
          └─article-a3-2.md
          └─article-a3-3.md
          └─article-a3-4.md
        └─a4/
          └─foo/
            └─bar.md
            └─foobar.md
      └─b/
        └─b1/
          └─article-b1-1.md
        └─b2/
        └─b3/
        └─b4/
          └─article-b4-1.md
      └─c/
        └─c1/
        └─c2/
        └─c3/
        └─c4/
    |}]
;;

let%expect_test
    "mv should not impact the filesystem if the source does not exists"
  =
  base_fs
  |> Tree.mv ~target:(Path.rel []) ~source:(Path.rel [ "d"; "d2" ])
  |> Tree.tree
  |> print_endline;
  [%expect
    {|
    └─./
      └─a/
        └─a1/
          └─article-a1-1.md
          └─article-a1-2.md
        └─a2/
          └─article-a2-1.md
          └─article-a2-2.md
          └─article-a2-3.md
          └─article-a2-4.md
        └─a3/
          └─article-a3-1.md
          └─article-a3-2.md
          └─article-a3-3.md
          └─article-a3-4.md
        └─a4/
          └─foo/
            └─bar.md
            └─foobar.md
      └─b/
        └─b1/
          └─article-b1-1.md
        └─b2/
          └─article-b2-1.md
        └─b3/
        └─b4/
          └─article-b4-1.md
      └─c/
        └─c1/
        └─c2/
        └─c3/
        └─c4/
    |}]
;;

let%expect_test "mv should not impact the filesystem if the target exists" =
  base_fs
  |> Tree.mv
       ~target:(Path.rel [ "b"; "b2"; "article-b2-1.md" ])
       ~source:(Path.rel [ "b"; "b1"; "article-b1-1.md" ])
  |> Tree.tree
  |> print_endline;
  [%expect
    {|
    └─./
      └─a/
        └─a1/
          └─article-a1-1.md
          └─article-a1-2.md
        └─a2/
          └─article-a2-1.md
          └─article-a2-2.md
          └─article-a2-3.md
          └─article-a2-4.md
        └─a3/
          └─article-a3-1.md
          └─article-a3-2.md
          └─article-a3-3.md
          └─article-a3-4.md
        └─a4/
          └─foo/
            └─bar.md
            └─foobar.md
      └─b/
        └─b1/
          └─article-b1-1.md
        └─b2/
          └─article-b2-1.md
        └─b3/
        └─b4/
          └─article-b4-1.md
      └─c/
        └─c1/
        └─c2/
        └─c3/
        └─c4/
    |}]
;;

let%expect_test "mv" =
  base_fs
  |> Tree.mv
       ~target:(Path.rel [ "c"; "c2"; "article-b2-1.md" ])
       ~source:(Path.rel [ "b"; "b1"; "article-b1-1.md" ])
  |> Tree.tree
  |> print_endline;
  [%expect
    {|
    └─./
      └─a/
        └─a1/
          └─article-a1-1.md
          └─article-a1-2.md
        └─a2/
          └─article-a2-1.md
          └─article-a2-2.md
          └─article-a2-3.md
          └─article-a2-4.md
        └─a3/
          └─article-a3-1.md
          └─article-a3-2.md
          └─article-a3-3.md
          └─article-a3-4.md
        └─a4/
          └─foo/
            └─bar.md
            └─foobar.md
      └─b/
        └─b1/
        └─b2/
          └─article-b2-1.md
        └─b3/
        └─b4/
          └─article-b4-1.md
      └─c/
        └─c1/
        └─c2/
          └─article-b2-1.md
        └─c3/
        └─c4/
    |}]
;;

let%expect_test "mv" =
  base_fs
  |> Tree.mv
       ~target:(Path.rel [ "d"; "d2"; "d3"; "d4"; "article-b2-1.md" ])
       ~source:(Path.rel [ "b"; "b1"; "article-b1-1.md" ])
  |> Tree.tree
  |> print_endline;
  [%expect
    {|
    └─./
      └─a/
        └─a1/
          └─article-a1-1.md
          └─article-a1-2.md
        └─a2/
          └─article-a2-1.md
          └─article-a2-2.md
          └─article-a2-3.md
          └─article-a2-4.md
        └─a3/
          └─article-a3-1.md
          └─article-a3-2.md
          └─article-a3-3.md
          └─article-a3-4.md
        └─a4/
          └─foo/
            └─bar.md
            └─foobar.md
      └─b/
        └─b1/
        └─b2/
          └─article-b2-1.md
        └─b3/
        └─b4/
          └─article-b4-1.md
      └─c/
        └─c1/
        └─c2/
        └─c3/
        └─c4/
      └─d/
        └─d2/
          └─d3/
            └─d4/
              └─article-b2-1.md
    |}]
;;

let%expect_test "mv" =
  base_fs
  |> Tree.mv
       ~target:(Path.rel [ "article-b2-1.md" ])
       ~source:(Path.rel [ "b"; "b1"; "article-b1-1.md" ])
  |> Tree.tree
  |> print_endline;
  [%expect
    {|
    └─./
      └─a/
        └─a1/
          └─article-a1-1.md
          └─article-a1-2.md
        └─a2/
          └─article-a2-1.md
          └─article-a2-2.md
          └─article-a2-3.md
          └─article-a2-4.md
        └─a3/
          └─article-a3-1.md
          └─article-a3-2.md
          └─article-a3-3.md
          └─article-a3-4.md
        └─a4/
          └─foo/
            └─bar.md
            └─foobar.md
      └─b/
        └─b1/
        └─b2/
          └─article-b2-1.md
        └─b3/
        └─b4/
          └─article-b4-1.md
      └─c/
        └─c1/
        └─c2/
        └─c3/
        └─c4/
      └─article-b2-1.md
    |}]
;;

let%expect_test "mv" =
  base_fs
  |> Tree.mv
       ~target:(Path.rel [ ".."; ".."; ".."; "expansion" ])
       ~source:(Path.rel [ "b"; "b1"; "article-b1-1.md" ])
  |> Tree.tree
  |> print_endline;
  [%expect
    {|
    └─./
      └─../
        └─../
          └─../
            └─expansion
      └─a/
        └─a1/
          └─article-a1-1.md
          └─article-a1-2.md
        └─a2/
          └─article-a2-1.md
          └─article-a2-2.md
          └─article-a2-3.md
          └─article-a2-4.md
        └─a3/
          └─article-a3-1.md
          └─article-a3-2.md
          └─article-a3-3.md
          └─article-a3-4.md
        └─a4/
          └─foo/
            └─bar.md
            └─foobar.md
      └─b/
        └─b1/
        └─b2/
          └─article-b2-1.md
        └─b3/
        └─b4/
          └─article-b4-1.md
      └─c/
        └─c1/
        └─c2/
        └─c3/
        └─c4/
    |}]
;;

let%expect_test "mv" =
  base_fs
  |> Tree.mv
       ~target:(Path.rel [ ".."; ".."; ".."; "expansion" ])
       ~source:(Path.rel [ "b"; "b1"; "article-b1-1.md" ])
  |> Tree.tree
  |> print_endline;
  [%expect
    {|
    └─./
      └─../
        └─../
          └─../
            └─expansion
      └─a/
        └─a1/
          └─article-a1-1.md
          └─article-a1-2.md
        └─a2/
          └─article-a2-1.md
          └─article-a2-2.md
          └─article-a2-3.md
          └─article-a2-4.md
        └─a3/
          └─article-a3-1.md
          └─article-a3-2.md
          └─article-a3-3.md
          └─article-a3-4.md
        └─a4/
          └─foo/
            └─bar.md
            └─foobar.md
      └─b/
        └─b1/
        └─b2/
          └─article-b2-1.md
        └─b3/
        └─b4/
          └─article-b4-1.md
      └─c/
        └─c1/
        └─c2/
        └─c3/
        └─c4/
    |}]
;;
