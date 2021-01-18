/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

include "standard"
include "network"
include "time"
include "random"
include "string"

routine main() -> int {
  // Create a random number generator
  generator = random.twister(uint64(time.now()))

  // Create a pipe to let the server know when it's
  // time to shutdown
  shutdown |@

  // Launch the server on a new thread
  launch server(&shutdown)
  for i in [0, 10) { 
    client(&generator)
  }

  // Tell the server it's time to shutdown and 
  // wait for it to confim
  shutdown <- @
  _ <- shutdown
  return 0
}

function foo(number int) -> int {
  number = number * 1103515245 + 12345
  return (int(number / 65536) % 32768)
}

routine server(shutdown &|signal) -> (int) {
  conn = network.bind("tcp://localhost:8081")
  using conn {
    for {
      select {
        case conn.listen():
          client <- conn.listen()
          launch () => {
            receipt <- client.read()
            success, number = string.toInt(receipt)
            if not success {
              client.disconnect()
            }
            conn.write(string.fromInt(foo(number)))
          }()
        case shutdown:
          _ <- shutdown
      }
    }
  }
  conn.close()
  shutdown <- @
}

routine client(generator &random.generator) -> (int, time.duration) {
  conn = network.connect("tcp://localhost:8081", nil)

  // Do server things and automatically clean up client
  using conn {
    timer = time.stopWatch()
    myNumber = random.NextInt()
    expected = foo(myNumber)

    using timer {
      conn.write(string.fromInt(myNumber))
      receipt <- conn.read()
    }
  }

  success, value = string.toInt(receipt)
  if success {
    return 0 if value is expected else 1, timer.duration
  } else {
    return 1, timer.duration 
  }
}


