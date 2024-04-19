# NetFlow monitoring on local interface with nfcapd and softflowd

Prerequisites:

- running GNU Guix daemon: https://guix.gnu.org/en/manual/en/html_node/Binary-Installation.html
- adjust script to the name of your Network Interface Card

To start monitoring issue (super user privileges are required for softflowd to sniff the interface):

- `sudo guix time-machine -C channels.scm -- shell -m manifest.scm -f guix-packager.scm -- guile start-tooling.scm`

After collecting the flows (data preparation):

- `guix time-machine -C channels.scm -- shell -m manifest.scm -f guix-packager.scm`

- `sudo chown -r packets ${whoami}:users`
- `nfdump -R packets/ -o "fmt: %sa, %da, %ts, %td, %pr, %sp, %dp, %pkt, %ibyt, %obyt, %bps, %pps" -q > aggregated_capture.csv`

Produce graphics and tables:

- `guix time-machine -C channels.scm -- shell -m manifest.scm -- Rscript analysis.R`
