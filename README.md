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
