(* Copyright (c) 2026, Cargocut and the Virtfs developpers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

type t =
  | Absolute of string list
  | Relative of string list

let equal a b =
  match a, b with
  | Relative a, Relative b | Absolute a, Absolute b ->
    List.equal String.equal a b
  | Relative _, Absolute _ | Absolute _, Relative _ -> false
;;

let to_string = function
  | Relative [] -> "./"
  | Absolute [] -> "/"
  | Relative xs -> String.concat Filename.dir_sep ("." :: xs)
  | Absolute xs -> String.concat Filename.dir_sep ("" :: xs)
;;

let compare a b =
  match a, b with
  | Relative _, Absolute _ -> -1
  | Absolute _, Relative _ -> 1
  | Absolute a, Absolute b | Relative a, Relative b ->
    (* OKAY: It seems fine to me to use a lexicographical order and
       not take into account the length of lists and segments to
       obtain an acceptable order in Sets or Maps. *)
    List.compare String.compare a b
;;

let split_on_chars pred s =
  (* NOTE: Like in [Stdlib] but using a predicate ([char -> bool])
     instead of a simple char. *)
  let r = ref [] in
  let j = ref (String.length s) in
  for i = String.length s - 1 downto 0 do
    if pred (String.unsafe_get s i)
    then (
      r := String.sub s (i + 1) (!j - i - 1) :: !r;
      j := i)
  done;
  String.sub s 0 !j :: !r
;;

let list_has_suffix ~equal ~suffix list =
  let rec aux suffix list =
    match suffix, list with
    | [], _ -> true
    | _, [] -> false
    | sx :: sxs, lx :: lxs -> if equal sx lx then aux sxs lxs else false
  in
  aux (List.rev suffix) (List.rev list)
;;

let remove_string_suffix ~suffix str =
  if String.ends_with ~suffix str
  then String.sub str 0 (String.length str - String.length suffix)
  else str
;;

let split_separator =
  split_on_chars (function
    | '/' | '\\' ->
      (* KLUDGE: Experience has shown that in YOCaml, being a
         little lax about path management is quite acceptable. By
         not using [Filename.dir_sep], we can ‘potentially’ support
         more cases. *)
      true
    | _ -> false)
;;

let split_dot = split_on_chars (Char.equal '.')

let from_fragment_list ?(prefix = []) fragments =
  (* NOTE: In other experiments, paths are stored in reverse order to
     facilitate queue processing: however, it would appear that more
     paths are created than are manipulated. In order to simplify the
     resolution of paths such as [‘../../f’], I have decided to keep
     the paths in the correct order. *)
  let rec aux from curr fragments =
    (* NOTE: Remove [".."] and ["."]  where possible.*)
    match from, curr, fragments with
    | (([] | ".." :: _) as fs), ".." :: ps, xs ->
      (* Deal with sequence of leading [".."]*)
      aux (".." :: fs) ps xs
    | fs, "." :: ps, xs | _ :: fs, ".." :: ps, xs ->
      (* Remove ["."] or [".."] (and collapse). *)
      aux fs ps xs
    | fs, x :: xs, ps ->
      (* Move the segment to the analyzed part. *)
      aux (x :: fs) xs ps
    | fs, [], x :: xs ->
      (* Split by potential separators inside the observable part. *)
      aux fs (split_separator x) xs
    | fs, [], [] ->
      (* Works done. *)
      List.rev fs
  in
  aux (List.rev prefix) [] fragments
;;

let abs fragments =
  Absolute
    (fragments
     |> from_fragment_list
     |> List.drop_while (String.equal "..")
        (* OKAY: When you [cd ..] to the root (["/"]) of a Unix file
           system, you remain at the root. Therefore, ["/.."] =
           ["/"]. Hence the removal of the prefixes [".."]. *))
;;

let rel fragments = Relative (from_fragment_list fragments)

let append p fragments =
  (* NOTE: We apply [from_fragment_list] on the cat of [xs] and
     [fragment] for takind advantage of resolution. *)
  match p with
  | Relative prefix -> Relative (from_fragment_list ~prefix fragments)
  | Absolute prefix -> Absolute (from_fragment_list ~prefix fragments)
;;

let cwd = Relative []
let root = Absolute []

let from_string s =
  match split_separator s with
  | "." :: xs -> rel xs
  | "" :: xs -> abs xs
  | xs -> rel xs
;;

let of_string = from_string

let fragments = function
  | Relative xs | Absolute xs -> xs
;;

let to_list = fragments

let is_relative = function
  | Relative _ -> true
  | Absolute _ -> false
;;

let is_absolute = function
  | Relative _ -> false
  | Absolute _ -> true
;;

let is_cwd = function
  | Relative [] ->
    (* MAYBE: In the case of resolutions (e.g. switching from
       ["foo/.."]), the test is not sufficient. To be corrected when
       the resolution takes effect.*)
    true
  | _ -> false
;;

let is_root = function
  | Absolute [] -> true
  | _ ->
    (* KLUDGE: Some root opportunities may be missed if [cwd] = [root]
       or if the resolution of [cwd] points to the root. However, I do
       not believe there is a straightforward way to fix this while
       remaining abstract. *)
    false
;;

let dirname p =
  let xs = fragments p in
  (* NOTE: How does it behave in the presence of leading ".."?  In
     the parent implementation, the parent of ["../.."] is [".."],
     which is strange, but it follows the convention of the Unix
     [dirname] implementation. *)
  let rec aux acc = function
    | [] -> if is_relative p then rel [ ".." ] else root
    | [ _ ] ->
      let xs = List.rev acc in
      if is_relative p then rel xs else abs xs
    | x :: xs -> aux (x :: acc) xs
  in
  aux [] xs
;;

let basename_opt p =
  let xs = fragments p in
  let rec aux = function
    | [] -> None
    | [ x ] -> Some x
    | _ :: xs -> aux xs
  in
  aux xs
;;

let basename p =
  (* NOTE: It follows the convention of the Unix [basename]
     implementation. Returning [.] for basename of [cwd] and [/] for
     basename of [root]. *)
  match basename_opt p with
  | Some x -> x
  | None -> if is_relative p then "." else "/"
;;

let extension p =
  match basename_opt p with
  | Some x -> Filename.extension x
  | None -> ""
;;

let extension_opt p =
  match extension p with
  | "" -> None
  | ext -> Some ext
;;

let basename_compound_extension bname =
  match split_dot bname with
  | [] -> []
  | _ :: extensions ->
    (* NOTE: Mimics the behaviour of Python's
          {{:https://docs.python.org/3/library/pathlib.html} pathlib}}
          library.*)
    List.map (fun x -> "." ^ x) extensions
;;

let compound_extension p =
  match basename_opt p with
  | Some name -> basename_compound_extension name
  | None -> []
;;

let make_extension
  =
  (* MAYBE: I am replicating the behaviour of Yocaml.Path, which
     allows you to add {if necessary} the missing leading
     dot. However, I am not sure that this is really the right
     approach. *)
  function
  | "" -> ""
  | "." -> ""
  | ext when String.length ext > 1 && Char.equal ext.[0] '.' -> ext
  | ext -> "." ^ ext
;;

let has_extension ext path =
  let ext = make_extension ext in
  match split_dot ext with
  | [] ->
    (* HACK: In fact, this case is probably never reached because
       split enforces a non-empty list invariant.*)
    true
  | [ ""; _ ] | [ _ ] ->
    (* We take turns on a function that ONLY observes the
       extension. *)
    let path_ext = extension path in
    String.equal path_ext ext
  | "" :: ext | ext ->
    (* We relay on compound_extension for checking extension inclusion
       (and we need to remove the first empty slot). *)
    let path_ext = compound_extension path in
    list_has_suffix
      ~equal:(fun s x ->
        (* KLUDGE: We need to rebuild the extension, adding a
           leading dot. *)
        let s = "." ^ s in
        String.equal s x)
      ~suffix:ext
      path_ext
;;

let has_any_extension exts p =
  (* NOTE: In YOCaml, this function was named [one_of_extension]. *)
  List.exists (fun ext -> has_extension ext p) exts
;;

let update_basename callback path =
  (* KLUDGE: Coming up with a good proposal for updating [basename] in
     the case of a root/cwd seems complicated.*)
  let f, fragments =
    match path with
    | Relative xs -> rel, xs
    | Absolute xs -> abs, xs
  in
  let rec aux acc = function
    | [] -> path
    | [ x ] -> f (List.rev (callback x :: acc))
    | x :: xs -> aux (x :: acc) xs
  in
  aux [] fragments
;;

let basename_remove_extension ?kind bname =
  match kind with
  | None ->
    (* Just remove the extension. *)
    Filename.remove_extension bname
  | Some (`Ext ext) ->
    (* Remove the given extension. *)
    let suffix = make_extension ext in
    remove_string_suffix ~suffix bname
  | Some `Compound ->
    (* Remove the compound extension. *)
    let suffix = bname |> basename_compound_extension |> String.concat "" in
    remove_string_suffix ~suffix bname
;;

let basename_add_extension ext bname =
  let ext = make_extension ext in
  bname ^ ext
;;

let remove_extension ?kind = update_basename (basename_remove_extension ?kind)
let add_extension ext = update_basename (basename_add_extension ext)

let replace_extension ?kind ext =
  update_basename (fun bname ->
    bname |> basename_remove_extension ?kind |> basename_add_extension ext)
;;

let change_extension = replace_extension

let move ~into source =
  match basename_opt source with
  | None ->
    (* KLUDGE: Urg, YOCaml's behaviour of returning the target if the
       source cannot be moved ([root] or [cwd]) seems strange to me,
       so I prefer to send the source.*)
    source
  | Some x -> append into [ x ]
;;
