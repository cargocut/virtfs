(* Copyright (c) 2026, Cargocut and the Virtfs developers. All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

type (!'concrete, !'readable, !'writable) t =
  | Virtual : Path.t -> (Tbool.no, Tbool.no, Tbool.no) t
  | Concrete :
      'readable Tbool.t * 'writable Tbool.t * Path.t
      -> (Tbool.yes, 'readable, 'writable) t

type packed = Packed : ('concrete, 'readable, 'writable) t -> packed
type v = (Tbool.no, Tbool.no, Tbool.no) t
type ('readable, 'writable) c = (Tbool.yes, 'readable, 'writable) t

let v path = Virtual path
let c ~readable ~writable path = Concrete (readable, writable, path)
let pack p = Packed p

let as_concrete ~readable ~writable (a, b, p) =
  let x = Tbool.to_bool readable and y = Tbool.to_bool writable in
  if Bool.equal x a && Bool.equal y b then Some (c ~readable ~writable p)
  else None

let as_virtual (a, b, p) = if (not a) && not b then Some (v p) else None

let path (type c r w) : (c, r, w) t -> Path.t = function
  | Virtual p | Concrete (_, _, p) -> p

let is_virtual (type c r w) : (c, r, w) t -> bool = function
  | Virtual _ -> true
  | Concrete _ -> false

let is_concrete p = not (is_virtual p)

let is_readable (type c r w) : (c, r, w) t -> bool = function
  | Virtual _ -> false
  | Concrete (x, _, _) -> Tbool.to_bool x

let is_writable (type c r w) : (c, r, w) t -> bool = function
  | Virtual _ -> false
  | Concrete (_, x, _) -> Tbool.to_bool x

let equal (type c r w) (a : (c, r, w) t) (b : (c, r, w) t) =
  match (a, b) with
  | Virtual a, Virtual b | Concrete (_, _, a), Concrete (_, _, b) ->
      Path.equal a b

let map : type c r w. (Path.t -> Path.t) -> (c, r, w) t -> (c, r, w) t =
 fun f -> function
  | Virtual p -> Virtual (f p)
  | Concrete (r, w, p) -> Concrete (r, w, f p)

let from path xs = map (fun p -> Path.append p xs) path
let revoke_read (Concrete (_, w, p)) = Concrete (Tbool.no, w, p)
let revoke_write (Concrete (r, _, p)) = Concrete (r, Tbool.no, p)
let observe_only (Concrete (_, _, p)) = Concrete (Tbool.no, Tbool.no, p)
let virtualize p = Virtual (path p)
