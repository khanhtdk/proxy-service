## Instruction

```text
Use command: sudo make install [params]
Parameters:  save-url=/path/to/file    where to save generated proxy URL
             user=username             specify proxy user, or use random
             passwd=password           specify proxy password, or use random
Uninstall:   sudo make uninstall
Reconfigure: sudo make reconf [params]
```

## Example

Use generated random username and password:
```bash
$ sudo make install save-url=/home/user/proxy.txt
```

Specify username and password:

```bash
$ sudo make install save-url=/home/user/proxy.txt user=proxy passwd=testing123
```
