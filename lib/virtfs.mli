(* Copyright (c) 2026, Cargocut and the Virtfs developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(** [Virtfs] provides primitives for describing paths in a file system
    in an {i abstract} (platform-independent) and {i relatively
    portable} manner, while allowing virtual file systems to be easily
    mounted to facilitate the writing of unit tests in programmes that
    abstract effects and rely on the file system.*)

(** {1 Abstraction over Path}

    Describes resolvable, portable, and platform-independent file
    paths. *)

module Path = Path

(** {1 Virtual File System}

    Implementation of an {i in-memory} file system based on
    {!module:Path}, which abstracts file contents and metadata. The
    module also exposes {!module:Tree.Simple}, which is an opinionated
    implementation of a very limited version of a system that mimics
    (somewhat) the behaviour of Unix file systems. *)

module Tree = Tree
