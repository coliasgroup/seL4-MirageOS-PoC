# Just for cross-compiling OCaml libraries

{ runCommandCC
, musl
, writeText
}:

let
  hack = writeText "hack.c" ''
    int sigsetjmp(void) {
        return 0;
    }
  '';
in

runCommandCC "libc" {} ''
  mkdir -p $out/lib
  ln -s ${musl}/include $out
  cp --no-preserve=mode ${musl}/lib/lib{c,m,pthread}.a $out/lib
  ln -s libc.a $out/lib/libg.a

  $CC -c ${hack} -o hack.o
  $AR r $out/lib/libc.a hack.o

  touch empty.s
  $AS empty.s -o empty.o

  cp empty.o $out/lib/crt0.o
  cp empty.o $out/lib/crti.o
  cp empty.o $out/lib/crtn.o
''
