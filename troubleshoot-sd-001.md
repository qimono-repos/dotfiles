qi@qimono-localhost:~% sudo dd if=/dev/urandom of=/tmp/pat bs=1M count=1                                                                              07:52:32

1+0 records in
1+0 records out
1048576 bytes (1.0 MB, 1.0 MiB) copied, 0.00321756 s, 350 MB/s
qi@qimono-localhost:~% sudo dd if=/tmp/pat of=/dev/mmcblk0 bs=1M seek=60000 count=1                                                                   07:52:36
dd: IO error: No space left on device
qi@qimono-localhost:~% sync && sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'                                                                         07:52:52
qi@qimono-localhost:~% sudo dd if=/dev/mmcblk0 bs=1M skip=60000 count=1 | cmp - /tmp/pat && echo PERSISTS || echo LOST                                07:53:08

0+0 records in
0+0 records out
0 bytes copied, 0.000713563 s, 0.0 B/s
cmp: EOF on ‘-’ which is empty
LOST

qi@qimono-localhost:~% for M in 1000 30720 45000 59800; do                                                                                            08:13:09
  sudo dd if=/dev/urandom of=/tmp/pat bs=1M count=1 status=none
  sudo dd if=/tmp/pat of=/dev/mmcblk0 bs=1M seek=$M count=1 status=none
  sync && sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'
  if sudo dd if=/dev/mmcblk0 bs=1M skip=$M count=1 status=none 2>/dev/null | cmp -s - /tmp/pat; then
    echo "offset ${M} MiB: PERSISTS"
  else
    echo "offset ${M} MiB: LOST or refused"
  fi
done
[sudo: authenticate] Password:     
offset 1000 MiB: PERSISTS
offset 30720 MiB: LOST or refused
offset 45000 MiB: LOST or refused
offset 59800 MiB: LOST or refused
qi@qimono-localhost:~%     