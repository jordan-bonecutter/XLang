/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

include "standard"
include "media"
include "machine"
include "time"
include "array"

routine main() -> int {
  cameraStream |&media.video.frame
  
  // Open the machine's default video capture
  success, capture = media.video.capture(media.video.capture.builtIn, nil)
  if not success {
    standard.println("Couldn't start video capture!")
    standard.println(media.video.capture.errlookup(success))
    return 1 
  }

  launch effect_broker(machine.hardwareCores, &cameraStream)

  timer = time.timer(10)
  using timer, cameraStream {
    stream = media.video.streamer.stream(&capture, &cameraStream, nil)
  }

  return 0
}

routine effect_broker(int numberOfWorkers, cameraStream &|&media.video.frame) {
  frameReady = [numberOfWorker]|signal
  outgoing = [numberOfWorkers]media.video.frame

  using cameraStream {
    for {
      // Setup outputstreamer to stream new content to
      captureOpts = media.video.capture.virtual.options {
        bufferSize = 10 
      }
      virtualCapture = media.video.capture(media.video.capture.virtual, &captureOpts)
      outputStreamer = media.video.streamer.bind(&virtualCapture, "tcp://localhost:8081", nil)

      // Launch workers to process new frames
      for workerNo in range(numberOfWorkers) {
        launch worker(cameraStream, outgoing + workerNo, frameReady + workerNo, &done)
      }

      // Wait for a new frame from any worker
      // Once one is received, pass it on to the
      // virtualCapture and signal the worker that
      // it can can use its memory again
      workerReadyNo <- array.mux(frameReady)
      virtualCapture <- outgoing[workerReadyNo] 
      frameReady[workerReadyNo] <- @
    }
  }
  outputstreamer.close()
}

routine worker(incoming &|&media.video.frame, outgoing &media.video.frame, frameReady &|signal) {
  for frame in incoming {
    outgoing = media.filter.boxBlur(10, 10, <- incoming)
    frameReady <- @
    _ <- frameReady
  }
}

