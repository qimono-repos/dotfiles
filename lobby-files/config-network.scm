;; QIMONO-LOBBY-CONFIG-VERSION: v1.1.0
;; Flavor: network-libre
;; Change: NetworkManager + WPA supplicant; preserve qi-keydrive boot layout.
;; Source: qimono-repos/dotfiles/lobby-files/

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

  (services (append (list (service network-manager-service-type)
                          (service wpa-supplicant-service-type)
                          (service openssh-service-type))
                    %base-services)))
