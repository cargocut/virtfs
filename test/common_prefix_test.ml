(* Copyright (c) 2026, Cargocut and the Virtfs developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

open Test_util

let%expect_test "common prefix" =
  dump_option
    Path.to_string
    Path.(
      common_prefix (rel [ "foo"; "bar"; "baz" ]) (rel [ "foo"; "bar"; "boz" ]));
  [%expect {| Some (./foo/bar) |}]
;;

let%expect_test "common prefix" =
  dump_option
    Path.to_string
    Path.(common_prefix (rel []) (rel [ "foo"; "bar"; "boz" ]));
  [%expect {| Some (./) |}]
;;

let%expect_test "common prefix" =
  dump_option
    Path.to_string
    Path.(common_prefix (rel [ "foo"; "foo" ]) (rel [ "foo"; "bar"; "boz" ]));
  [%expect {| Some (./foo) |}]
;;

let%expect_test "common prefix" =
  dump_option
    Path.to_string
    Path.(
      common_prefix (rel [ "foo"; "bar"; "baz" ]) (abs [ "foo"; "bar"; "boz" ]));
  [%expect {| None |}]
;;
