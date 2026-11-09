(* Copyright (c) 2026, Cargocut and the Virtfs developers. All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

module Scoped () = struct
  type (!'concrete, !'readable, !'writable) scope =
    ('concrete, 'readable, 'writable) Tscope.t

  let check_scope ~scope path = Tscope.check ~scope path
  let make_scope ?exclusions scope = Tscope.make ?exclusions scope
end
