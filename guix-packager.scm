(define-module (guix-packager)
  #:use-module (guix)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages)
  #:use-module (guix build-system gnu)
  #:use-module (guix git-download)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages flex)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages admin))

(define-public nfdump
  (package
   (name "nfdump")
   (version "1.7.4")
   (source
    (origin
     (method git-fetch)
     (uri (git-reference
           (url "https://github.com/phaag/nfdump")
           (commit (string-append "v" version))))
     (file-name (git-file-name name version))
     (sha256 (base32 "1ih1h1ankcm9a4pqlqs1jv163himckzhf6q9ssyl3p03q38sfpnx"))))
   (native-inputs
    (list autoconf automake flex libtool pkg-config bison))
   (inputs
    (list bzip2 libpcap))
   (build-system gnu-build-system)
   (arguments (list #:configure-flags #~(list
                                         "--enable-nsel"
                                         "--enable-sflow"
                                         "--enable-readpcap"
                                         "--enable-nfpcapd")
                    #:phases
                    #~(modify-phases %standard-phases
                                     (delete 'check)
                                     ;; (add-before 'configure 'autogen
                                     ;;             (lambda* (#:key inputs #:allow-other-keys)
                                     ;;                      (system* "sh" "autogen.sh")))
                                     )))
   (home-page "https://github.com/phaag/nfdump")
   (synopsis "Tools for working with netflow data")
   (description "Tools for working with netflow data")
   (license license:bsd-3)))

(define-public libcdata
  (package
   (name "libcdata")
   (version "0.5.2")
   (source
    (origin
     (method git-fetch)
     (uri (git-reference
           (url "https://github.com/msune/libcdata")
           (commit (string-append "v" version))))
     (file-name (git-file-name name version))
     (sha256 (base32 "0ifygw8saszanrmzshicx2ii9mlvadx59m7gzsgzddjsf2qndc5f"))))
   (native-inputs
    (list autoconf libtool pkg-config automake libcap))
   (build-system gnu-build-system)
   (arguments (list #:configure-flags #~(list
                                         "--without-tests"
                                         "--without-exmples")))
   (home-page "")
   (synopsis "Library for basic data structures in C")
   (description "Basic data structures in C: list, set, map/hashtable, queue... (libstdc++ wrapper)")
   (license license:bsd-2)))

(define-public pmacct
  (package
   (name "pmacct")
   (version "1.7.8")
   (source
    (origin
     (method git-fetch)
     (uri (git-reference
           (url "https://github.com/pmacct/pmacct")
           (commit (string-append "v" version))))
     (file-name (git-file-name name version))
     (sha256 (base32 "0kalp21pzvpmpxa0pslns2vbp54i43lph46f3brlzm8xzzkikj01"))))
   (native-inputs
    (list autoconf libtool pkg-config automake libcap libcdata))
   (inputs
    (list bzip2 libpcap))
   (build-system gnu-build-system)
   (arguments (list ;; #:make-flags
                    ;; #~(list (string-append "--with-pcap-includes="
                    ;;                        (assoc-ref %build-inputs "libcap") "/include"))
                    #:phases
                    #~(modify-phases %standard-phases
                        (add-before 'bootstrap 'change-shebang
                          (lambda _
                            (patch-shebang "bin/configure-help-replace.sh")
                            #t)))))
   (home-page "http://www.pmacct.net/")
   (synopsis "A small set of multi-purpose passive network monitoring tools")
   (description "pmacct is a small set of multi-purpose passive network monitoring tools
      [NetFlow IPFIX sFlow libpcap BGP BMP RPKI IGP Streaming Telemetry]")
   (license license:gpl2)))

(define-public softflowd
  (package
   (name "softlowd")
   (version "1.1.0")
   (source
    (origin
     (method git-fetch)
     (uri (git-reference
           (url "https://github.com/irino/softflowd")
           (commit (string-append "softflowd-v" version))))
     (file-name (git-file-name name version))
     (sha256 (base32 "1mn27sicnjl9cldaja9vdy5nl5lj2lblpl9nwicgvflh6d39sjs0"))))
   (native-inputs
    (list autoconf libtool pkg-config automake libcap))
   (inputs
    (list bzip2 libpcap libbpf))
   (build-system gnu-build-system)
   ;; (arguments (list #:configure-flags #~(list
   ;;                                       "--without-tests"
   ;;                                       "--without-exmples")))
   (home-page "")
   (synopsis "")
   (description "")
   (license license:bsd-2)))

;; This allows you to run guix shell -f guix-packager.scm.
;; Remove this line if you just want to define a package.
;; nfdump

(list softflowd nfdump)

;; TODO
;; set up export and add tcp dump for testing
