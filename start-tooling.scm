(use-modules (ice-9 textual-ports)
             (ice-9 rdelim)
             (ice-9 popen))

;; helper functions
(define (shutdown-after-delay process-name delay)
  (sleep delay) ; Sleep for the specified delay (in seconds)
  (let* ((pipe (open-pipe* OPEN_READ "pidof" process-name))
         (pid (read-line pipe)))
    (close-port pipe) ; Close the pipe
    (system* "kill" "-15" pid))) ; Send SIGTERM to the process

;; netflow monitoring setup
(system* "nfcapd" "-D" "-p 2055" "-w" "packets" "-S" "1")
(system* "sh" "-c" "softflowd  -i wlp5s0 -n 127.0.0.1:2055 -v 9 -t maxlife=30" "&")

;; terminate after given time
(shutdown-after-delay "nfcapd" (* 2 24 60 60)) ;; 2 days
(shutdown-after-delay "softflowd" (* 2 24 60 60)) ;; 2 days
