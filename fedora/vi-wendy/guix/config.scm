;; QIMONO-VI-WENDY-CONFIG-VERSION: v1.1.2
;; Change: Set qi as SLiM default user and StumpWM as X session fallback.
;; Base: Nonguix Linux, Realtek firmware, UEFI, swap and ext4.
;; Machine: EXO Smart E16Plus / Atom x5-Z8350 / 29.1 GiB HBG4a2 eMMC.
;; Installed by: fedora/vi-wendy/guix/install-guix.sh
;;
;; Filesystem labels are created by the matching installer script.
;; This file deliberately contains no Wi-Fi credentials or passwords.

(use-modules (gnu)
             (gnu system nss)
             (nongnu packages linux)
             (nongnu system linux-initrd))
(use-service-modules desktop xorg)
(use-package-modules certs nss version-control wget curl
                     wm xorg vim)

(operating-system
  (host-name "vi-wendy")
  (timezone "America/Argentina/Cordoba")
  (locale "en_US.utf8")

  ;; The original Guix ISO used Linux-libre and blocked this laptop's
  ;; nonfree Realtek RTL8723BS firmware. The Nonguix installer proved
  ;; wlan0 connectivity using rtlwifi/rtl8723bs_nic.bin.
  (kernel linux)
  (initrd microcode-initrd)
  (firmware (list linux-firmware))

  ;; EFI fallback path for the laptop's UEFI firmware.
  (bootloader
    (bootloader-configuration
      (bootloader grub-efi-removable-bootloader)
      (targets '("/boot/efi"))))

  (file-systems
    (append
      (list (file-system
              (mount-point "/")
              (device (file-system-label "vi-wendy-root"))
              (type "ext4"))
            (file-system
              (mount-point "/boot/efi")
              (device (file-system-label "VIWENDYEFI"))
              (type "vfat")))
      %base-file-systems))

  (swap-devices
    (list (swap-space
            (target (file-system-label "vi-wendy-swap")))))

  (users
    (cons (user-account
            (name "qi")
            (comment "Qimono regular user on vi-wendy")
            (group "users")
            (supplementary-groups
              '("wheel" "netdev" "audio" "video" "lp")))
          %base-user-accounts))

  ;; StumpWM is a Common Lisp X11 window manager, not a desktop environment.
  ;; SLiM starts StumpWM directly, without an imperative ~/.xsession file.
  (packages
    (append
      (list nss-certs git wget curl vim xterm stumpwm)
      %base-packages))

  ;; Desktop services include NetworkManager, WPA supplicant, D-Bus,
  ;; elogind, polkit and Bluetooth. Replace GDM with lightweight SLiM.
  (services
    (cons (service slim-service-type
                   (slim-configuration
                     (default-user "qi")
                     (auto-login-session
                       (file-append stumpwm "/bin/stumpwm"))))
          (modify-services %desktop-services
            (delete gdm-service-type))))

  (name-service-switch %mdns-host-lookup-nss))
