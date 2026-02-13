> [!WARNING]  
> This project is still **highly experimental**, but we would be
> delighted to receive feedback (but please be careful with
> production).

# virtfs

> Abstract on file paths to enable easy embedding of unit tests
> dependent on a file system.

It is very common to have software that depends on the file system,
which can be interpreted as a programme dependency, to make their unit
tests easier. In many projects, we have reimplemented this concept of
abstract file systems to write tests with a high degree of confidence:
[YOCaml](https://github.com/xhtmlboi/yocaml/blob/main/test/lib/fs.mli),
[Mini_yocaml](https://github.com/xvw/mini_yocaml/blob/main/test/fake_file_system.mli)
and
[Kohai](https://github.com/xvw/kohai/blob/main/test/server/virtfs.mli)

The purpose of the library is to _centralise these features_ into a
single compact dependency, without dependencies (and without using the
[Format module](https://ocaml.org/manual/5.4/api/Format.html), making
it easy to use in a
[Js_of_ocaml](https://ocsigen.org/js_of_ocaml/latest/manual/overview)
programme).

The library offers a `Path` module for constructing globally portable
and resolvable file paths. A `Tree` module for describing a file tree,
and `Tree.Simple`, which mimics (approximately) the behaviour of a
very limited Unix file system (with only the modification date,
`mtime`, as metadata).

The library works quite well with the [Primavera
library](https://github.com/cargocut/primavera) (and other effect
abstraction systems) to make applications that use the file system as
a mutable database easily testable.

## Example

```ocaml
open Virtfs
```

Let's imagine that we want to create a small piece of software that
writes, for example, tasks to a file, to make a... to-do list!
However, we would like to have a consistent and comprehensive set of
unit tests that is as exhaustive as possible.

In order to use `virtfs`, we will abstract interactions with the file
system. In OCaml, there are **many different ways to do this**, but I
will indulge in using modules... the _standard_ approach (and we don't
need to control continuation here, so using effects is a bit of
overkill).

> [!NOTE]  
> This is just an example, so error handling is not very
> sophisticated.

First, let us define the abstract interface for the interactions that
may occur.

```ocaml
module type handler = sig
  val write_file : Path.t -> string -> unit
  val read_file : Path.t -> string
  val file_exists : Path.t -> bool
end
```

Now we can write our high-level API:

```ocaml
let ( let* ) = Result.bind
let ( let+ ) x f = Result.map f x
```

First, we will write a function to write a file, with error handling
that is rather disappointing, I grant you:

```ocaml
let write_file (module Fs : handler) path content = 
  try Ok (Fs.write_file path content) with
  | exn ->
    (* Yes, this is an example so the error handling is not very
       advanced. *)
    Error exn
```

Now we're going to write a hook to write a file, still with our rather
poor error handling:

```ocaml
let read_file (module Fs : handler) path =
  try 
     Ok (
        if Fs.file_exists path 
        then Some (Fs.read_file path) 
        else None
  ) with exn -> Error exn
```

Now, we will write a function to _add content to a file_ (Since our
tasks will only be a list of character strings where each task is
separated by a line break):

```ocaml
let append_to_file (module Fs : handler) path new_content =
  let new_content =
    String.trim (
      new_content 
      |> String.split_on_char '\n' 
      |> String.concat " ")
  in
  let* old_content = read_file (module Fs) path in
  let total_content =
    Option.fold
      ~none:new_content
      ~some:(fun old_content -> 
          String.trim old_content ^ "\n" 
          ^ new_content)
      old_content
  in
  write_file (module Fs) path total_content
```

And now we can write a _higher-level API_ that will list the tasks or
write them:

```ocaml
module Task = struct
  type t = string

  let from_string_to_list str =
    str 
    |> String.split_on_char '\n' 
    |> List.map String.trim

  let list (module Fs : handler) path =
    match
      let+ str = read_file (module Fs) path in
      match str with
      | None -> []
      | Some x -> from_string_to_list x
    with
    | Ok l -> l
    | Error _ ->
      let () = prerr_endline "list: An error is occurend" in
      []

  let save (module Fs : handler) path task =
    match append_to_file (module Fs) path task with
    | Ok () -> ()
    | Error _ -> prerr_endline "save: An error is occurend"

  let display (module Fs : handler) path =
    List.iter print_endline (list (module Fs) path)
end
```

Now that we have a (really poor) application for storing and
displaying our tasks, we can write a handler that will use a virtual
file system. To do this, we will use an implementation exposed by the
`Tree` module: `Tree.Simple`, which roughly mimics a very minimalist
Unix-like file system. We store the tree in a mutable reference so
that it changes as we write to it:

```ocaml
module Handler = struct
  let fs = ref Tree.Simple.(mount ~scope:Path.cwd [ dir ~name:"tasks" [] ])
  let file_exists path = Tree.Simple.is_file ~path !fs

  let write_file path content =
    let new_fs = Tree.Simple.write_file ~overwrite:true ~path content !fs in
    fs := new_fs

  let read_file path = Tree.Simple.read_file ~path !fs
end
```

Now that all the bricks are assembled, we can experiment with our
application using our mock virtual file system!

First, we define the path where our tasks will be stored:

```ocaml
let target = Path.rel ["tasks"; "list"]
```

Next, we can inspect our virtual system:

```ocaml
# !Handler.fs |> Tree.tree |> print_endline ;;
└─./
  └─tasks/
- : unit = ()
```

Our system contains only one directory, `tasks`, which is
empty. That's perfect. Normally, displaying tasks should show nothing.

```ocaml
# Task.display (module Handler) target ;;
- : unit = ()
```

Let's add some tasks!

```ocaml
Task.save (module Handler) target "task a"; 
Task.save (module Handler) target "task b";
Task.save (module Handler) target "task c"
```

Now let's display the list of tasks:

```ocaml
# Task.display (module Handler) target ;;
task a
task b
task c
- : unit = ()
```

_And voila_, this example is relatively simplistic, but it clearly
shows how to make an application that relies heavily on the use of the
file system as a mutable database easily testable in a unit testing
environment.
