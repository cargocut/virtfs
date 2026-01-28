(* Copyright (c) 2026, Cargocut and the Virtfs developpers.
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
