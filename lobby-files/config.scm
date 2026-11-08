;; QIMONO-LOBBY-CONFIG-REVISION: 2026-11-08.1
;; Change: Import nss-certs from (gnu packages nss); use dhcpcd; add revision stamp.
;; Source: qimono-repos/dotfiles/lobby-files/config.scm

(use-modules (gnu) (gnu system nss))
(use-service-modules networking ssh)
(use-package-modules bootloaders certs nss screen ssh)

(operating-system
  (host-name "qimono-lobby")
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

  (services (append (list (service dhcpcd-service-type)
                          (service openssh-service-type))
                    %base-services)))
