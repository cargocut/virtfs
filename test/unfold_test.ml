(* Copyright (c) 2026, Cargocut and the Virtfs developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

let base_fs =
  let open Tree in
  from_cwd
    [ dir
        ~metadata:0
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

let%expect_test "expand with all" =
  Tree.unfold base_fs |> Test_util.dump_path_set;
  [%expect
    {|
    ./
    ./a
    ./a/a1
    ./a/a1/article-a1-1.md
    ./a/a1/article-a1-2.md
    ./a/a2
    ./a/a2/article-a2-1.md
    ./a/a2/article-a2-2.md
    ./a/a2/article-a2-3.md
    ./a/a2/article-a2-4.md
    ./a/a3
    ./a/a3/article-a3-1.md
    ./a/a3/article-a3-2.md
    ./a/a3/article-a3-3.md
    ./a/a3/article-a3-4.md
    ./a/a4
    ./a/a4/foo
    ./a/a4/foo/bar.md
    ./a/a4/foo/foobar.md
    ./b
    ./b/b1
    ./b/b1/article-b1-1.md
    ./b/b2
    ./b/b2/article-b2-1.md
    ./b/b3
    ./b/b4
    ./b/b4/article-b4-1.md
    ./c
    ./c/c1
    ./c/c2
    ./c/c3
    ./c/c4
    |}]
;;

let%expect_test "expand with files" =
  Tree.unfold ~keep:`Files base_fs |> Test_util.dump_path_set;
  [%expect
    {|
    ./a/a1/article-a1-1.md
    ./a/a1/article-a1-2.md
    ./a/a2/article-a2-1.md
    ./a/a2/article-a2-2.md
    ./a/a2/article-a2-3.md
    ./a/a2/article-a2-4.md
    ./a/a3/article-a3-1.md
    ./a/a3/article-a3-2.md
    ./a/a3/article-a3-3.md
    ./a/a3/article-a3-4.md
    ./a/a4/foo/bar.md
    ./a/a4/foo/foobar.md
    ./b/b1/article-b1-1.md
    ./b/b2/article-b2-1.md
    ./b/b4/article-b4-1.md
    |}]
;;

let%expect_test "expand with directories" =
  Tree.unfold ~keep:`Directories base_fs |> Test_util.dump_path_set;
  [%expect
    {|
    ./
    ./a
    ./a/a1
    ./a/a2
    ./a/a3
    ./a/a4
    ./a/a4/foo
    ./b
    ./b/b1
    ./b/b2
    ./b/b3
    ./b/b4
    ./c
    ./c/c1
    ./c/c2
    ./c/c3
    ./c/c4
    |}]
;;

let%expect_test "expand with all - drop root" =
  Tree.unfold ~keep_root:false base_fs |> Test_util.dump_path_set;
  [%expect
    {|
    ./a
    ./a/a1
    ./a/a1/article-a1-1.md
    ./a/a1/article-a1-2.md
    ./a/a2
    ./a/a2/article-a2-1.md
    ./a/a2/article-a2-2.md
    ./a/a2/article-a2-3.md
    ./a/a2/article-a2-4.md
    ./a/a3
    ./a/a3/article-a3-1.md
    ./a/a3/article-a3-2.md
    ./a/a3/article-a3-3.md
    ./a/a3/article-a3-4.md
    ./a/a4
    ./a/a4/foo
    ./a/a4/foo/bar.md
    ./a/a4/foo/foobar.md
    ./b
    ./b/b1
    ./b/b1/article-b1-1.md
    ./b/b2
    ./b/b2/article-b2-1.md
    ./b/b3
    ./b/b4
    ./b/b4/article-b4-1.md
    ./c
    ./c/c1
    ./c/c2
    ./c/c3
    ./c/c4
    |}]
;;

let%expect_test "expand with files - drop root" =
  Tree.unfold ~keep_root:false ~keep:`Files base_fs |> Test_util.dump_path_set;
  [%expect
    {|
    ./a/a1/article-a1-1.md
    ./a/a1/article-a1-2.md
    ./a/a2/article-a2-1.md
    ./a/a2/article-a2-2.md
    ./a/a2/article-a2-3.md
    ./a/a2/article-a2-4.md
    ./a/a3/article-a3-1.md
    ./a/a3/article-a3-2.md
    ./a/a3/article-a3-3.md
    ./a/a3/article-a3-4.md
    ./a/a4/foo/bar.md
    ./a/a4/foo/foobar.md
    ./b/b1/article-b1-1.md
    ./b/b2/article-b2-1.md
    ./b/b4/article-b4-1.md
    |}]
;;

let%expect_test "expand with directories - drop root" =
  Tree.unfold ~keep_root:false ~keep:`Directories base_fs
  |> Test_util.dump_path_set;
  [%expect
    {|
    ./a
    ./a/a1
    ./a/a2
    ./a/a3
    ./a/a4
    ./a/a4/foo
    ./b
    ./b/b1
    ./b/b2
    ./b/b3
    ./b/b4
    ./c
    ./c/c1
    ./c/c2
    ./c/c3
    ./c/c4
    |}]
;;

let%expect_test "expand all on a prism" =
  Tree.unfold ~scope:(Path.rel [ "a"; "a3" ]) base_fs |> Test_util.dump_path_set;
  [%expect
    {|
    ./a/a3
    ./a/a3/article-a3-1.md
    ./a/a3/article-a3-2.md
    ./a/a3/article-a3-3.md
    ./a/a3/article-a3-4.md
    |}]
;;

let%expect_test "expand all on a prism" =
  Tree.unfold ~keep:`Files ~scope:(Path.rel [ "a"; "a3" ]) base_fs
  |> Test_util.dump_path_set;
  [%expect
    {|
    ./a/a3/article-a3-1.md
    ./a/a3/article-a3-2.md
    ./a/a3/article-a3-3.md
    ./a/a3/article-a3-4.md
    |}]
;;

let%expect_test "expand all on a prism" =
  Tree.unfold ~keep:`Directories ~scope:(Path.rel [ "a"; "a3" ]) base_fs
  |> Test_util.dump_path_set;
  [%expect {| ./a/a3 |}]
;;

let%expect_test "expand all on a prism" =
  Tree.unfold ~keep_root:false ~scope:(Path.rel [ "a"; "a3" ]) base_fs
  |> Test_util.dump_path_set;
  [%expect
    {|
    ./a/a3/article-a3-1.md
    ./a/a3/article-a3-2.md
    ./a/a3/article-a3-3.md
    ./a/a3/article-a3-4.md
    |}]
;;

let nested_fs =
  let open Tree in
  make
    ~scope:(Path.rel [ "x" ])
    [ dir ~metadata:(Some 0) ~name:"d" [ file ~name:"h.md" "h" ]
    ; file ~name:"f.md" "f"
    ]
;;

let%expect_test
    "unfold with a relative scope is resolved against the tree scope"
  =
  Tree.unfold ~scope:(Path.rel [ "d" ]) nested_fs |> Test_util.dump_path_set;
  [%expect
    {|
    ./x/d
    ./x/d/h.md
    |}]
;;

let%expect_test "unfold with a missing scope" =
  Tree.unfold ~scope:(Path.rel [ "missing" ]) nested_fs
  |> Test_util.dump_path_set;
  [%expect {| ./x/missing |}]
;;

let%expect_test "unfold with a file as scope" =
  Tree.unfold ~scope:(Path.rel [ "f.md" ]) nested_fs |> Test_util.dump_path_set;
  Tree.unfold ~keep:`Files ~scope:(Path.rel [ "f.md" ]) nested_fs
  |> Test_util.dump_path_set;
  [%expect {| ./x/f.md |}]
;;

let%expect_test "expand content with content" =
  Tree.unfold_with_content base_fs |> Test_util.dump_path_map string_of_int;
  [%expect
    {|
    ./a/a1/article-a1-1.md <>: 0
    ./a/a1/article-a1-2.md <>: 1
    ./a/a2/article-a2-1.md <>: 3
    ./a/a2/article-a2-2.md <>: 4
    ./a/a2/article-a2-3.md <>: 5
    ./a/a2/article-a2-4.md <>: 6
    ./a/a3/article-a3-1.md <>: 7
    ./a/a3/article-a3-2.md <>: 8
    ./a/a3/article-a3-3.md <>: 9
    ./a/a3/article-a3-4.md <>: 10
    ./a/a4/foo/bar.md <>: Hello World from A
    ./a/a4/foo/foobar.md <>: Hello World
    ./b/b1/article-b1-1.md <>: b1
    ./b/b2/article-b2-1.md <>: b2
    ./b/b4/article-b4-1.md <>: b4
    |}]
;;

let%expect_test "expand content including directories" =
  Tree.unfold_with_content ~keep:`All base_fs
  |> Test_util.dump_path_map string_of_int;
  [%expect
    {|
    .// <>
    ./a/ <0>
    ./a/a1/ <>
    ./a/a1/article-a1-1.md <>: 0
    ./a/a1/article-a1-2.md <>: 1
    ./a/a2/ <>
    ./a/a2/article-a2-1.md <>: 3
    ./a/a2/article-a2-2.md <>: 4
    ./a/a2/article-a2-3.md <>: 5
    ./a/a2/article-a2-4.md <>: 6
    ./a/a3/ <>
    ./a/a3/article-a3-1.md <>: 7
    ./a/a3/article-a3-2.md <>: 8
    ./a/a3/article-a3-3.md <>: 9
    ./a/a3/article-a3-4.md <>: 10
    ./a/a4/ <>
    ./a/a4/foo/ <>
    ./a/a4/foo/bar.md <>: Hello World from A
    ./a/a4/foo/foobar.md <>: Hello World
    ./b/ <>
    ./b/b1/ <>
    ./b/b1/article-b1-1.md <>: b1
    ./b/b2/ <>
    ./b/b2/article-b2-1.md <>: b2
    ./b/b3/ <>
    ./b/b4/ <>
    ./b/b4/article-b4-1.md <>: b4
    ./c/ <>
    ./c/c1/ <>
    ./c/c2/ <>
    ./c/c3/ <>
    ./c/c4/ <>
    |}]
;;

let%expect_test "expand content with only directories" =
  Tree.unfold_with_content ~keep:`Directories base_fs
  |> Test_util.dump_path_map string_of_int;
  [%expect
    {|
    .// <>
    ./a/ <0>
    ./a/a1/ <>
    ./a/a2/ <>
    ./a/a3/ <>
    ./a/a4/ <>
    ./a/a4/foo/ <>
    ./b/ <>
    ./b/b1/ <>
    ./b/b2/ <>
    ./b/b3/ <>
    ./b/b4/ <>
    ./c/ <>
    ./c/c1/ <>
    ./c/c2/ <>
    ./c/c3/ <>
    ./c/c4/ <>
    |}]
;;

let%expect_test "expand content with only directories without root" =
  Tree.unfold_with_content ~keep_root:false ~keep:`Directories base_fs
  |> Test_util.dump_path_map string_of_int;
  [%expect
    {|
    ./a/ <0>
    ./a/a1/ <>
    ./a/a2/ <>
    ./a/a3/ <>
    ./a/a4/ <>
    ./a/a4/foo/ <>
    ./b/ <>
    ./b/b1/ <>
    ./b/b2/ <>
    ./b/b3/ <>
    ./b/b4/ <>
    ./c/ <>
    ./c/c1/ <>
    ./c/c2/ <>
    ./c/c3/ <>
    ./c/c4/ <>
    |}]
;;

let%expect_test "expand content including directories without root" =
  Tree.unfold_with_content ~keep_root:false ~keep:`All base_fs
  |> Test_util.dump_path_map string_of_int;
  [%expect
    {|
    ./a/ <0>
    ./a/a1/ <>
    ./a/a1/article-a1-1.md <>: 0
    ./a/a1/article-a1-2.md <>: 1
    ./a/a2/ <>
    ./a/a2/article-a2-1.md <>: 3
    ./a/a2/article-a2-2.md <>: 4
    ./a/a2/article-a2-3.md <>: 5
    ./a/a2/article-a2-4.md <>: 6
    ./a/a3/ <>
    ./a/a3/article-a3-1.md <>: 7
    ./a/a3/article-a3-2.md <>: 8
    ./a/a3/article-a3-3.md <>: 9
    ./a/a3/article-a3-4.md <>: 10
    ./a/a4/ <>
    ./a/a4/foo/ <>
    ./a/a4/foo/bar.md <>: Hello World from A
    ./a/a4/foo/foobar.md <>: Hello World
    ./b/ <>
    ./b/b1/ <>
    ./b/b1/article-b1-1.md <>: b1
    ./b/b2/ <>
    ./b/b2/article-b2-1.md <>: b2
    ./b/b3/ <>
    ./b/b4/ <>
    ./b/b4/article-b4-1.md <>: b4
    ./c/ <>
    ./c/c1/ <>
    ./c/c2/ <>
    ./c/c3/ <>
    ./c/c4/ <>
    |}]
;;

let%expect_test "expand content including directories on a specific scope" =
  Tree.unfold_with_content ~scope:(Path.rel [ "a"; "a2" ]) ~keep:`All base_fs
  |> Test_util.dump_path_map string_of_int;
  [%expect
    {|
    ./a/a2/ <>
    ./a/a2/article-a2-1.md <>: 3
    ./a/a2/article-a2-2.md <>: 4
    ./a/a2/article-a2-3.md <>: 5
    ./a/a2/article-a2-4.md <>: 6
    |}]
;;
