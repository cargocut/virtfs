(* Copyright (c) 2026, Cargocut and the Virtfs developers. All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

type yes = Yes
type no = No
type _ t = TYes : yes t | TNo : no t

let yes = TYes
let no = TNo
let to_bool (type k) : k t -> bool = function TYes -> true | TNo -> false

let equal (type k) (a : k t) (b : k t) =
  match (a, b) with TYes, TYes | TNo, TNo -> true
