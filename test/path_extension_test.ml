(* Copyright (c) 2026, Cargocut and the Virtfs developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

open Test_util

let%expect_test "regular [extension] usage" =
  Path.rel [ "foo"; "index.md" ] |> Path.extension |> print_endline;
  [%expect {| .md |}]
;;

let%expect_test "regular [extension] usage - without extension" =
  Path.rel [ "foo"; "index" ] |> Path.extension |> print_endline;
  [%expect {| |}]
;;

let%expect_test "regular [extension] usage - without extension" =
  Path.rel [ ".."; ".." ] |> Path.extension |> print_endline;
  [%expect {| |}]
;;

let%expect_test "regular [extension] usage - without extension" =
  Path.cwd |> Path.extension |> print_endline;
  [%expect {| |}]
;;

let%expect_test "regular [extension_opt] usage" =
  Path.rel [ "foo"; "index.md" ] |> Path.extension_opt |> dump_option Fun.id;
  [%expect {| Some (.md) |}]
;;

let%expect_test "regular [extension_opt] usage - without extension" =
  Path.rel [ "foo"; "index" ] |> Path.extension_opt |> dump_option Fun.id;
  [%expect {| None |}]
;;

let%expect_test "compound_extension" =
  Path.rel [ "foo"; "index" ]
  |> Path.compound_extension
  |> String.concat ""
  |> print_endline
;;

let%expect_test "compound_extension" =
  Path.rel [ "foo"; "index.md" ]
  |> Path.compound_extension
  |> String.concat ""
  |> print_endline;
  [%expect {| .md |}]
;;

let%expect_test "compound_extension" =
  Path.rel [ "foo"; "index.tpl.md" ]
  |> Path.compound_extension
  |> String.concat ""
  |> print_endline;
  [%expect {| .tpl.md |}]
;;

let%expect_test "compound_extension" =
  Path.rel [ "foo"; "index.tpl.md.html" ]
  |> Path.compound_extension
  |> String.concat ""
  |> print_endline;
  [%expect {| .tpl.md.html |}]
;;

let%expect_test "has_extension - regular case" =
  Path.abs [ "foo.html" ] |> Path.has_extension "html" |> dump_bool;
  [%expect {| true |}]
;;

let%expect_test "has_extension - regular case" =
  Path.abs [ "foo.html" ] |> Path.has_extension ".html" |> dump_bool;
  [%expect {| true |}]
;;

let%expect_test "has_extension - regular case" =
  Path.abs [ "foo.htmd" ] |> Path.has_extension ".html" |> dump_bool;
  [%expect {| false |}]
;;

let%expect_test "has_extension - using compound" =
  Path.abs [ "foo.html" ] |> Path.has_extension ".tpl.html" |> dump_bool;
  [%expect {| false |}]
;;

let%expect_test "has_extension - using compound" =
  Path.abs [ "foo.tpl.html" ] |> Path.has_extension ".tpl.html" |> dump_bool;
  [%expect {| true |}]
;;

let%expect_test "has_extension - using compound" =
  Path.abs [ "foo.tpl.bar.html" ] |> Path.has_extension ".bar.html" |> dump_bool;
  [%expect {| true |}]
;;

let%expect_test "has_any_extension - using compound" =
  Path.abs [ "foo.tpl.bar.md" ]
  |> Path.has_any_extension [ "md"; "markdown"; "page.mdown" ]
  |> dump_bool;
  [%expect {| true |}]
;;

let%expect_test "has_any_extension - using compound" =
  Path.abs [ "foo.tpl.bar.markdown" ]
  |> Path.has_any_extension [ "md"; "markdown"; "page.mdown" ]
  |> dump_bool;
  [%expect {| true |}]
;;

let%expect_test "has_any_extension - using compound" =
  Path.abs [ "foo.tpl.bar.markdown.page.mdown" ]
  |> Path.has_any_extension [ "md"; "markdown"; "page.mdown" ]
  |> dump_bool;
  [%expect {| true |}]
;;

let%expect_test "has_any_extension - using compound" =
  Path.abs [ "foo.tpl.bar.markdown.page.mdowns" ]
  |> Path.has_any_extension [ "md"; "markdown"; "page.mdown" ]
  |> dump_bool;
  [%expect {| false |}]
;;

let%expect_test "remove_extension - regular case" =
  Path.abs [ "foo.md" ] |> Path.remove_extension |> dump_path;
  [%expect {| /foo |}]
;;

let%expect_test "remove_extension - regular case" =
  Path.abs [ "foobar" ] |> Path.remove_extension |> dump_path;
  [%expect {| /foobar |}]
;;

let%expect_test "remove_extension - regular case" =
  Path.abs [ "foobar.tpl.html" ] |> Path.remove_extension |> dump_path;
  [%expect {| /foobar.tpl |}]
;;

let%expect_test "remove_extension - compound case" =
  Path.abs [ "foobar.tpl.html" ]
  |> Path.remove_extension ~kind:`Compound
  |> dump_path;
  [%expect {| /foobar |}]
;;

let%expect_test "remove_extension - ext case" =
  Path.abs [ "foobar.tpl.html" ]
  |> Path.remove_extension ~kind:(`Ext "fobar.barbaz")
  |> dump_path;
  [%expect {| /foobar.tpl.html |}]
;;

let%expect_test "remove_extension - ext case" =
  Path.abs [ "foobar.fobar.barbaz" ]
  |> Path.remove_extension ~kind:(`Ext "fobar.barbaz")
  |> dump_path;
  [%expect {| /foobar |}]
;;

let%expect_test "remove_extension - ext case" =
  Path.abs [ "foobar.fobar.barbaz.htm" ]
  |> Path.remove_extension ~kind:(`Ext ".barbaz.htm")
  |> dump_path;
  [%expect {| /foobar.fobar |}]
;;

let%expect_test "add_extension" =
  Path.abs [ "foobar.fobar.barbaz.htm" ]
  |> Path.add_extension "tpl.html"
  |> dump_path;
  [%expect {| /foobar.fobar.barbaz.htm.tpl.html |}]
;;

let%expect_test "add_extension" =
  Path.abs [ "foobar.fobar.barbaz.htm" ]
  |> Path.add_extension ".tpl.html"
  |> dump_path;
  [%expect {| /foobar.fobar.barbaz.htm.tpl.html |}]
;;

let%expect_test "add_extension - on root it should return root" =
  Path.abs [] |> Path.add_extension "tpl.html" |> dump_path;
  [%expect {| / |}]
;;

let%expect_test "add_extension - on cwd it should return cwd" =
  Path.rel [] |> Path.add_extension "tpl.html" |> dump_path;
  [%expect {| ./ |}]
;;

let%expect_test "change_extension" =
  Path.rel [ "index.php" ] |> Path.change_extension "ml" |> dump_path;
  [%expect {| ./index.ml |}]
;;
