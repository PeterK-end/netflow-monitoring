# NetFlow monitoring on local interface with nfcapd and softflowd

To start monitoring issue (super user privileges are required for softflowd to sniff the interface):

- `sudo guix time-machine -C channels.scm -- shell -m manifest.scm -f guix-packager.scm -- guile start-tooling.scm`

After collecting the flows:

- `guix time-machine -C channels.scm -- shell -m manifest.scm -f guix-packager.scm`

- `sudo chown -r packets ${whoami}:users`
- `nfdump -R packets/ -o "fmt: %sa, %da, %ts, %td, %pr, %sp, %dp, %pkt, %byt, %bps, %pps" -q > aggregated_capture.csv`
