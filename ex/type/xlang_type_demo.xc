/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

include "xlang_type_demo.xh"
include "config"
include "io"
include "standard"

routine main() -> int {
  myWestie westie
  westieReader = config.reader(westie)
  using fi as io.file.reader("westie.toml") {
    ok, myWestie = westieReader.read(fi)
  }
  if not ok {
    standard.println("Couldn't read westie from file!") 
    standard.println(westieReader.read.errlookup(ok))
  } else {
    myWestie.bark()
  }

  using fi as io.file.reader("corgi.toml") {
    ok, myWestie = westieReader.read(fi)
  }
  if not ok {
    standard.println("Couldn't read westie from file!") 
    standard.println(westieReader.read.errlookup(ok))
  } else {
    myWestie.bark() 
  }
}

