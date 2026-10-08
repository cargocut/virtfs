(* Copyright (c) 2026, Cargocut and the Virtfs developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

let dump_option f x =
  let s =
    match x with
    | None -> "None"
    | Some x -> "Some (" ^ f x ^ ")"
  in
  print_endline s
;;

let dump_bool = function
  | true -> print_endline "true"
  | false -> print_endline "false"
;;

let metadata_to_string f = function
  | None -> "<>"
  | Some x -> "<" ^ f x ^ ">"
;;

let dump_path path = path |> Path.to_string |> print_endline
let dump_path_set set = set |> Path.Set.to_list |> List.iter dump_path

let dump_path_map m map =
  map
  |> Path.Map.to_list
  |> List.iter (fun (path, subject) ->
    match subject with
    | `Directory meta ->
      print_endline (Path.to_string path ^ "/ " ^ metadata_to_string m meta)
    | `File (meta, content) ->
      print_endline
        (Path.to_string path ^ " " ^ metadata_to_string m meta ^ ": " ^ content))
;;
