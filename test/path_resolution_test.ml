(* Copyright (c) 2026, Cargocut and the Virtfs developpers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(* Accurate and described path resolution tests. *)

open Test_util

let%expect_test
    {|
   `./foo/bar/../baz/./index.md`
     \_ ./foo/bar
              \_ ../ remove bar
                     |_ add baz
                     |_ remove dot
                     \_ `./foo/baz/index.md`
|}
  =
  let computed = Path.rel [ "foo"; "bar"; ".."; "baz"; "."; "index.md" ]
  and expected = Path.rel [ "foo"; "baz"; "index.md" ] in
  let () = assert (Path.equal expected computed) in
  dump_path computed;
  [%expect {| ./foo/baz/index.md |}]
;;

let%expect_test
    {|
    `../../../bar/../index.md
    \_______/
        |_ ../../../
                   \_ add bar
                    |_ remove bar
                     \_ `../../../index.md`
|}
  =
  let computed = Path.rel [ "."; "../../../bar/../index.md" ]
  and expected = Path.rel [ ".."; ".."; ".."; "index.md" ] in
  let () = assert (Path.equal expected computed) in
  dump_path computed;
  [%expect {| ./../../../index.md |}]
;;

let%expect_test
    {|
    `../../../bar/../foobar/baz/bar/../index.md
    \_______/
        |_ ../../../
                   \_ add bar
                    |_ remove bar
                    |_ add foobar/baz/bar
                    |_ remove bar
                    |_ `../../../foobar/baz/index.md`
|}
  =
  let computed =
    Path.rel
      [ "."; "../../../bar/.."; "foobar"; "baz"; "bar"; ".."; "index.md" ]
  and expected = Path.rel [ ".."; ".."; ".."; "foobar"; "baz"; "index.md" ] in
  let () = assert (Path.equal expected computed) in
  dump_path computed;
  [%expect {| ./../../../foobar/baz/index.md |}]
;;

let%expect_test
    {|
    `../../../bar/../foobar/baz/bar/../../../../index.md
    \_______/
        |_ ../../../
                   \_ add bar
                    |_ remove bar
                    |_ add foobar/baz/bar
                    |_ remove bar baz foobar
                    |_ add ..
                    |_ `../../../../index.md`
|}
  =
  let computed =
    Path.rel
      [ "."
      ; "../../../bar/.."
      ; "foobar"
      ; "baz"
      ; "bar"
      ; ".."
      ; ".."
      ; ".."
      ; ".."
      ; "index.md"
      ]
  and expected = Path.rel [ ".."; ".."; ".."; ".."; "index.md" ] in
  let () = assert (Path.equal expected computed) in
  dump_path computed;
  [%expect {| ./../../../../index.md |}]
;;

let%expect_test
    {|
    `/../../../bar/../foobar/baz/bar/../../../../index.md
    \_______/
        |_ ../../../
                   \_ add bar
                    |_ remove bar
                    |_ add foobar/baz/bar
                    |_ remove bar baz foobar
                    |_ add ..
                    |_ `../../../../index.md`
                    |_ remove leading ..
|}
  =
  let computed =
    Path.abs
      [ "../../../bar/.."
      ; "foobar"
      ; "baz"
      ; "bar"
      ; ".."
      ; ".."
      ; ".."
      ; ".."
      ; "index.md"
      ]
  and expected = Path.abs [ "index.md" ] in
  let () = assert (Path.equal expected computed) in
  dump_path computed;
  [%expect {| /index.md |}]
;;
