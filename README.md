# Usage

First, place (or symlink) the template file `PKGBUILD.template` on `~/.local/share/cran2arch`
```bash
> ls ~/.local/share/cran2arch
PKGBUILD.template
```

Run below to generate PKGBUILD.
```bash
/path/to/cran2arch tidyverse > PKGBUILD
```

If you want to add checksums, 
```bash
/path/to/cran2arch tidyverse > PKGBUILD && updpkgsums
```
