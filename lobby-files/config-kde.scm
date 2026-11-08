;; QIMONO-LOBBY-CONFIG-VERSION: v1.3.0
;; Flavor: plasma-bluetooth-nonguix
;; Change: Add Plasma, SDDM and BlueZ on the firmware-enabled lobby.
;; Source: qimono-repos/dotfiles/lobby-files/

(use-modules (gnu) (gnu system nss) (srfi srfi-1)
             (nongnu packages linux)
             (nongnu system linux-initrd))
(use-service-modules networking ssh desktop sddm)
(use-package-modules bootloaders certs nss screen ssh bluetooth)

(operating-system
  (host-name "qimono-lobby")
  (kernel linux)
  (initrd microcode-initrd)
  (firmware (list linux-firmware))
  (timezone "Etc/UTC")
  (locale "en_US.utf8")

  ;; Portable UEFI removable bootloader for the lobby.
  (bootloader (bootloader-configuration
                (bootloader grub-efi-removable-bootloader)
                (targets '("/boot/efi"))))

  (file-systems (append
                  (list (file-system
                          (mount-point "/")
                          (device (file-system-label "qi-keydrive"))
                          (type "ext4"))
                        (file-system
                          (mount-point "/boot/efi")
                          (device (file-system-label "EFI"))
                          (type "vfat")))
                  %base-file-systems))

  (users (cons (user-account
                 (name "qi")
                 (group "users")
                 (supplementary-groups '("wheel" "netdev" "audio" "video")))
               %base-user-accounts))

  (packages (append (list screen openssh nss-certs) %base-packages))

  ;; %desktop-services already provides NetworkManager, Wi-Fi support, D-Bus,
  ;; elogind, polkit and power services. Replace GDM with SDDM.
  (services
   (append
    (list (service plasma-desktop-service-type)
          (service sddm-service-type
                   (sddm-configuration (theme "breeze")))
          (service bluetooth-service-type
                   (bluetooth-configuration (auto-enable? #t)))
          (service openssh-service-type))
    (remove (lambda (svc)
              (memq (service-kind svc)
                    (list gdm-service-type bluetooth-service-type)))
            %desktop-services))))
