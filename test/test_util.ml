(* Copyright (c) 2026, Cargocut and the Virtfs developers. All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

let dump_option f x =
  let s = match x with None -> "None" | Some x -> "Some (" ^ f x ^ ")" in
  print_endline s

let dump_bool = function
  | true -> print_endline "true"
  | false -> print_endline "false"

let metadata_to_string f = function None -> "<>" | Some x -> "<" ^ f x ^ ">"
let dump_path path = path |> Path.to_string |> print_endline
let dump_path_set set = set |> Path.Set.to_list |> List.iter dump_path

let dump_path_map m map =
  map
  |> Path.Map.to_list
  |> List.iter (fun (path, subject) ->
      match subject with
      | Item.Directory { metadata; _ } ->
          print_endline
            (Path.to_string path ^ "/ " ^ metadata_to_string m metadata)
      | File { metadata; content; _ } ->
          print_endline
            (Path.to_string path
            ^ " "
            ^ metadata_to_string m metadata
            ^ ": "
            ^ content))

let dump_tpath tpath =
  let is_v = if Tpath.is_virtual tpath then "[v]" else "[x]"
  and is_r = if Tpath.is_readable tpath then "[x]" else "[ ]"
  and is_w = if Tpath.is_writable tpath then "[x]" else "[ ]"
  and p = Tpath.path tpath in
  print_endline (is_v ^ is_r ^ is_w ^ Path.to_filename p)
