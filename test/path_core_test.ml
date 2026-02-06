(* Copyright (c) 2026, Cargocut and the Virtfs developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

open Test_util

let%expect_test "to_string for [cwd]" =
  Path.cwd |> dump_path;
  [%expect {| ./ |}]
;;

let%expect_test "to_string for [root]" =
  Path.root |> dump_path;
  [%expect {| / |}]
;;

let%expect_test "to_string for a relative path" =
  Path.rel [ "foo"; "bar"; "baz" ] |> dump_path;
  [%expect {| ./foo/bar/baz |}]
;;

let%expect_test "to_string for an absolute path" =
  Path.abs [ "foo"; "bar"; "baz" ] |> dump_path;
  [%expect {| /foo/bar/baz |}]
;;

let%expect_test "to_string for a relative path with strange segments" =
  Path.rel [ "foo/bar"; "baz"; "foobar\\eod" ] |> dump_path;
  [%expect {| ./foo/bar/baz/foobar/eod |}]
;;

let%expect_test "to_string for an absolute path with strange segments" =
  Path.abs [ "foo/bar"; "baz"; "foobar\\eod" ] |> dump_path;
  [%expect {| /foo/bar/baz/foobar/eod |}]
;;

let%expect_test "from_string" =
  Path.("" |> from_string) |> dump_path;
  [%expect {| / |}]
;;

let%expect_test "from_string" =
  Path.("./" |> from_string) |> dump_path;
  [%expect {| ./ |}]
;;

let%expect_test "from_string" =
  Path.("foo/bar" |> from_string) |> dump_path;
  [%expect {| ./foo/bar |}]
;;

let%expect_test "from_string" =
  Path.("foo/bar/../../index.html" |> from_string) |> dump_path;
  [%expect {| ./index.html |}]
;;

let%expect_test "from_string" =
  Path.("/foo/bar/../../../index.html" |> from_string) |> dump_path;
  [%expect {| /index.html |}]
;;

let%expect_test "is_relative for [cwd]" =
  Path.(cwd |> is_relative) |> dump_bool;
  [%expect {| true |}]
;;

let%expect_test "is_relative for [root]" =
  Path.(root |> is_relative) |> dump_bool;
  [%expect {| false |}]
;;

let%expect_test "is_relative for a relative path" =
  Path.(rel [ "foo"; "bar" ] |> is_relative) |> dump_bool;
  [%expect {| true |}]
;;

let%expect_test "is_relative for an absolute path" =
  Path.(abs [ "foo"; "bar" ] |> is_relative) |> dump_bool;
  [%expect {| false |}]
;;

let%expect_test "is_absolute for [cwd]" =
  Path.(cwd |> is_absolute) |> dump_bool;
  [%expect {| false |}]
;;

let%expect_test "is_absolute for [root]" =
  Path.(root |> is_absolute) |> dump_bool;
  [%expect {| true |}]
;;

let%expect_test "is_absolute for a relative path" =
  Path.(rel [ "foo"; "bar" ] |> is_absolute) |> dump_bool;
  [%expect {| false |}]
;;

let%expect_test "is_absolute for an absolute path" =
  Path.(abs [ "foo"; "bar" ] |> is_absolute) |> dump_bool;
  [%expect {| true |}]
;;

let%expect_test "is_cwd for [cwd]" =
  Path.(cwd |> is_cwd) |> dump_bool;
  [%expect {| true |}]
;;

let%expect_test "is_cwd for [root]" =
  Path.(root |> is_cwd) |> dump_bool;
  [%expect {| false |}]
;;

let%expect_test "is_cwd for [rel []]" =
  Path.(rel [] |> is_cwd) |> dump_bool;
  [%expect {| true |}]
;;

let%expect_test "is_cwd for [abs []]" =
  Path.(abs [] |> is_cwd) |> dump_bool;
  [%expect {| false |}]
;;

let%expect_test "is_cwd for an arbitrary relative path" =
  Path.(rel [ "foo"; "bar" ] |> is_cwd) |> dump_bool;
  [%expect {| false |}]
;;

let%expect_test "is_cwd for an arbitrary absolute path" =
  Path.(abs [ "foo"; "bar" ] |> is_cwd) |> dump_bool;
  [%expect {| false |}]
;;

let%expect_test "is_root for [cwd]" =
  Path.(cwd |> is_root) |> dump_bool;
  [%expect {| false |}]
;;

let%expect_test "is_root for [root]" =
  Path.(root |> is_root) |> dump_bool;
  [%expect {| true |}]
;;

let%expect_test "is_root for [rel []]" =
  Path.(rel [] |> is_root) |> dump_bool;
  [%expect {| false |}]
;;

let%expect_test "is_root for [abs []]" =
  Path.(abs [] |> is_root) |> dump_bool;
  [%expect {| true |}]
;;

let%expect_test "is_root for an arbitrary relative path" =
  Path.(rel [ "foo"; "bar" ] |> is_root) |> dump_bool;
  [%expect {| false |}]
;;

let%expect_test "is_root for an arbitrary absolute path" =
  Path.(abs [ "foo"; "bar" ] |> is_root) |> dump_bool;
  [%expect {| false |}]
;;

let%expect_test "to_string with relative resolution" =
  Path.(rel [ "foo"; ".."; "bar"; "."; "baz" ]) |> dump_path;
  [%expect {| ./bar/baz |}]
;;

let%expect_test "to_string with relative resolution" =
  Path.(rel [ "foo"; "fooo"; "../.."; "bar"; ".\\foo"; "baz" ]) |> dump_path;
  [%expect {| ./bar/foo/baz |}]
;;

let%expect_test "to_string with relative resolution at the origin of [cwd]" =
  Path.(rel [ ".."; ".."; "baz" ]) |> dump_path;
  [%expect {| ./../../baz |}]
;;

let%expect_test "to_string with relative resolution at the origin of [cwd]" =
  Path.(rel [ ".."; "foo"; ".."; "baz" ]) |> dump_path;
  [%expect {| ./../baz |}]
;;

let%expect_test "to_string with relative resolution" =
  Path.(rel [ "foo"; "bar"; ".."; "foobar"; ".."; ".."; ".."; ".."; "baz" ])
  |> dump_path;
  [%expect {| ./../../baz |}]
;;

let%expect_test "to_string with absolute resolution" =
  Path.(abs [ "foo"; "bar"; ".."; "foobar"; ".."; ".."; ".."; ".."; "baz" ])
  |> dump_path;
  [%expect {| /baz |}]
;;

let%expect_test "is_cwd with resolution" =
  Path.(rel [ "foo"; "bar"; ".."; ".." ] |> is_cwd) |> dump_bool;
  [%expect {| true |}]
;;

let%expect_test "is_cwd with resolution" =
  Path.(rel [ "foo"; "bar"; ".."; ".."; ".." ] |> is_cwd) |> dump_bool;
  [%expect {| false |}]
;;

let%expect_test "is_root with resolution" =
  Path.(abs [ "foo"; "bar"; ".."; ".." ] |> is_root) |> dump_bool;
  [%expect {| true |}]
;;

let%expect_test "is_root with resolution" =
  Path.(abs [ "foo"; "bar"; ".."; ".."; ".." ] |> is_root) |> dump_bool;
  [%expect {| true |}]
;;

let%expect_test "dirname of cwd" =
  Path.(cwd |> dirname) |> dump_path;
  [%expect {| ./.. |}]
;;

let%expect_test "dirname of root" =
  Path.(root |> dirname) |> dump_path;
  [%expect {| / |}]
;;

let%expect_test "dirname of an absolute path" =
  Path.(abs [ "foo"; "bar" ] |> dirname) |> dump_path;
  [%expect {| /foo |}]
;;

let%expect_test "dirname of a relative path" =
  Path.(rel [ "foo"; "bar" ] |> dirname) |> dump_path;
  [%expect {| ./foo |}]
;;

let%expect_test "dirname of a relative path with resolution" =
  Path.(rel [ ".."; ".." ] |> dirname) |> dump_path;
  [%expect {| ./.. |}]
;;

let%expect_test "basename of cwd" =
  Path.(cwd |> basename) |> print_endline;
  [%expect {| . |}]
;;

let%expect_test "basename of root" =
  Path.(root |> basename) |> print_endline;
  [%expect {| / |}]
;;

let%expect_test "basename of an absolute path" =
  Path.(abs [ "foo"; "bar" ] |> basename) |> print_endline;
  [%expect {| bar |}]
;;

let%expect_test "basename of a relative path" =
  Path.(rel [ "foo"; "bar" ] |> basename) |> print_endline;
  [%expect {| bar |}]
;;

let%expect_test "basename of a relative path with resolution" =
  Path.(rel [ ".."; ".." ] |> basename) |> print_endline;
  [%expect {| .. |}]
;;

let%expect_test "append" =
  let a = Path.rel [ "foo"; "bar"; "baz" ] in
  [] |> Path.append a |> dump_path;
  [%expect {| ./foo/bar/baz |}]
;;

let%expect_test "append" =
  let a = Path.rel [ "foo"; "bar"; "baz" ] in
  [ "foobar"; "foobaz" ] |> Path.append a |> dump_path;
  [%expect {| ./foo/bar/baz/foobar/foobaz |}]
;;

let%expect_test "append with shared resolution" =
  let a = Path.rel [ "foo"; "bar"; "baz" ] in
  [ ".."; "foo"; ".."; ".." ] |> Path.append a |> dump_path;
  [%expect {| ./foo |}]
;;

let%expect_test "to_filename" =
  Path.rel [ "foo"; ".."; ".."; "baz" ] |> Path.to_filename |> print_endline;
  [%expect {| ./../baz |}]
;;

let%expect_test "to_filename - 2" =
  Path.rel [ "foo"; ".."; ".."; "baz\\index.png" ]
  |> Path.to_filename
  |> print_endline;
  [%expect {| ./../baz/index.png |}]
;;

let%expect_test "Some annoying behaviour" =
  Path.of_string "./foo/bar/" |> dump_path;
  [%expect {| ./foo/bar |}]
;;

let%expect_test "Some annoying behaviour" =
  Path.rel [ "./foo/bar/"; ""; "."; "foo/" ] |> dump_path;
  [%expect {| ./foo/bar/foo |}]
;;
