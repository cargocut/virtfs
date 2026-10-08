### Unreleased

- Addd `Tree.scope` for retreiving the scope of a `tree` (by [gr-im](https://github.com/gr-im))
- Add helpers for retreiving mtime for item and metadata of `Tree.Simple` (by [gr-im](https://github.com/gr-im))
- Add `Tree.merge` (by [mspwn](https://github.com/mspwn))
- Add equality functions for `Tree.t`, `Tree.Simple.t` and `Item.t` (by [mspwn](https://github.com/mspwn))
- Add `Tree.insert_items` + Conflict policies and externalize `Item` module ([gr-im](https://github.com/gr-im) and [mspwn](https://github.com/mspwn))
- Add `Tree.unfold` and `Tree.unfold_with_content` to produce a flat list of all the children of a filesystem tree ([gr-im](https://github.com/gr-im)  and [mspwn](https://github.com/mspwn))

### 1.1.0

- Add an implementation for `Virtfs` ([gr-im](https://github.com/gr-im))

### v1.0.0

- First release of `virtfs`, exposing the modules `Path`, for
  abstracting file paths, `Tree` for describing an abstract file tree,
  and `Tree.Simple`, which is a very simple version of a file system
  (where the contents of files are strings) (by
  [mspwn](https://github.com/mspwn),
  [xhtmlboi](https://github.com/xhtmlboi),
  [gr-im](https://github.com/gr-im),
  [d-plaindoux](https://github.com/d-plaindoux)).
