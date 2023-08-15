# Usage

First, you must create a template file like below.

```bash
# Maintainer: Haruo <haruo-mtok [at] outlook [dot] com>

_cranname=
_cranver=
pkgname=r-${_cranname,,}
pkgver=${_cranver//[:-]/.}
pkgrel=1
pkgdesc=
arch=(i686 x86_64)
url="https://cran.r-project.org/package=${_cranname}"
license=
depends=
optdepends=
source=("https://cran.r-project.org/src/contrib/${_cranname}_${_cranver}.tar.gz")
sha512sums=('xxx')

build() {
    R CMD INSTALL ${_cranname}_${_cranver}.tar.gz -l "${srcdir}"
}

package() {
    install -dm0755 "${pkgdir}/usr/lib/R/library"
    cp -a --no-preserve=ownership "${_cranname}" "${pkgdir}/usr/lib/R/library"
}
```

Place the template file named `~/.local/share/cran2arch/PKGBUILD.template`.
```bash
> ls ~/.local/share/cran2arch
PKGBUILD.template
```

Run below to generate PKGBUILD (`tidyverse` for example).
```bash
/path/to/cran2arch tidyverse > PKGBUILD
```

If you want to add checksums, 
```bash
/path/to/cran2arch tidyverse > PKGBUILD && updpkgsums
```


# About `PKGBUILD.template`
The basic format is as shown above.

Feel free to modify any part of this file. Especially the signature at the head ought to be changed.

The lines which consist of specific keywords and end with "=" will be replaced.


# Options

- `--update` forces re-downloading the package database.
- `--clean` removes the downloaded database.
- `--info [packages ...]` shows raw databases (tibble) of specified packages.
