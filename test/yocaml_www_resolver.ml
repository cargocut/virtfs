(* Copyright (c) 2026, Cargocut and the Virtfs developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

open Test_util

module Resolver : sig
  (* Replicates the behaviour of a simple resolver, inspired by the
     YOCaml website. *)

  type t

  val make : ?source:Path.t -> ?target:Path.t -> ?server:Path.t -> unit -> t
  val binary : Path.t

  module Source : sig
    val config : t -> Path.t
    val articles : t -> Path.t
    val article : t -> int -> Path.t
  end

  module Target : sig
    val assets : t -> Path.t
    val article : t -> Path.t -> Path.t
  end

  module Server : sig
    val from_target : t -> Path.t -> Path.t
  end
end = struct
  type t =
    { source : Path.t
    ; target : Path.t
    ; server : Path.t
    }

  let make
        ?(source = Path.cwd)
        ?(target = Path.rel [ "_www" ])
        ?(server = Path.root)
        ()
    =
    { source; target; server }
  ;;

  let binary = Path.from_string Sys.executable_name

  module Source = struct
    let source { source; _ } = source
    let config r = Path.(source r / "configuration.toml")
    let articles r = Path.(source r / "articles")

    let article r i =
      Path.(articles r / ("an-article-" ^ string_of_int i ^ ".md"))
    ;;
  end

  module Target = struct
    let target { target; server; _ } = Path.concat ~into:target server
    let assets r = Path.(target r / "static")
    let articles r = Path.(target r / "posts")

    let article r path =
      path |> Path.move ~into:(articles r) |> Path.change_extension "html"
    ;;
  end

  module Server = struct
    let server { server; _ } = server

    let from_target r p =
      p |> Path.trim ~prefix:(Target.target r) |> Path.relocate ~into:(server r)
    ;;
  end
end

let%expect_test "binary name" =
  Resolver.binary |> Path.basename |> print_endline;
  [%expect {| inline-test-runner.exe |}]
;;

let%expect_test "server resolver from target" =
  let resolver = Resolver.make () in
  let assets = Resolver.Target.assets resolver in
  Resolver.Server.from_target resolver assets |> dump_path;
  [%expect {| /static |}]
;;

let%expect_test "server resolver from target" =
  let resolver =
    Resolver.make
      ~target:(Path.rel [ "_www" ])
      ~server:(Path.abs [ "my-project"; "my-server" ])
      ()
  in
  let assets = Resolver.Target.assets resolver in
  Resolver.Server.from_target resolver assets |> dump_path;
  [%expect {| /my-project/my-server/static |}]
;;

let%expect_test "server resolver from target for articles" =
  let resolver =
    Resolver.make
      ~target:(Path.rel [ "_www" ])
      ~server:(Path.abs [ "my-project"; "my-server" ])
      ()
  in
  let articles =
    List.init 15 (fun i -> Resolver.Source.article resolver (succ i))
  in
  List.iter
    (fun path ->
       let target = path |> Resolver.Target.article resolver in
       let on_web = target |> Resolver.Server.from_target resolver in
       dump_path target;
       dump_path on_web)
    articles;
  [%expect {|
    ./_www/my-project/my-server/posts/an-article-1.html
    /my-project/my-server/posts/an-article-1.html
    ./_www/my-project/my-server/posts/an-article-2.html
    /my-project/my-server/posts/an-article-2.html
    ./_www/my-project/my-server/posts/an-article-3.html
    /my-project/my-server/posts/an-article-3.html
    ./_www/my-project/my-server/posts/an-article-4.html
    /my-project/my-server/posts/an-article-4.html
    ./_www/my-project/my-server/posts/an-article-5.html
    /my-project/my-server/posts/an-article-5.html
    ./_www/my-project/my-server/posts/an-article-6.html
    /my-project/my-server/posts/an-article-6.html
    ./_www/my-project/my-server/posts/an-article-7.html
    /my-project/my-server/posts/an-article-7.html
    ./_www/my-project/my-server/posts/an-article-8.html
    /my-project/my-server/posts/an-article-8.html
    ./_www/my-project/my-server/posts/an-article-9.html
    /my-project/my-server/posts/an-article-9.html
    ./_www/my-project/my-server/posts/an-article-10.html
    /my-project/my-server/posts/an-article-10.html
    ./_www/my-project/my-server/posts/an-article-11.html
    /my-project/my-server/posts/an-article-11.html
    ./_www/my-project/my-server/posts/an-article-12.html
    /my-project/my-server/posts/an-article-12.html
    ./_www/my-project/my-server/posts/an-article-13.html
    /my-project/my-server/posts/an-article-13.html
    ./_www/my-project/my-server/posts/an-article-14.html
    /my-project/my-server/posts/an-article-14.html
    ./_www/my-project/my-server/posts/an-article-15.html
    /my-project/my-server/posts/an-article-15.html
    |}]
;;
