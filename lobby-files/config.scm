;; QIMONO-LOBBY-CONFIG-VERSION: v1.0.2
;; Change: Switch to SemVer for rapid TTY install iterations.
;; Previous fix (v1.0.1): Import nss-certs from (gnu packages nss); use dhcpcd.
;; Versioning: MAJOR = breaking, MINOR = new feature/service, PATCH = fixes/docs.
;; Rule: Increment version and update Change for EVERY edit to this file.
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
