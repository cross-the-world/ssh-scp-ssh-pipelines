# SSH SCP SSH Pipelines

Credit to [SSH SCP Action of Ali Najafizadeh](https://github.com/alinz/ssh-scp-action)

This action allows doing 
1. ssh
2. scp
3. ssh

## Inputs
see the [action.yml](./action.yml) file for more detail imformation.

### `host`

**Required** ssh remote host.

### `port`

**NOT Required** ssh remote port. Default 22

### `user`

**Required** ssh remote user.

### `pass`

**NOT Required** ssh remote pass.

### `key`

**NOT Required** ssh remote key as string.

### `connect_timeout`

**NOT Required** connection timeout to remote host. Default 30s

### `first_ssh`

**NOT Required** execute pre-commands before scp.

### `scp`

**NOT Required** scp from local to remote.

**Syntax**
local_path => remote_path
e.g.
/opt/test/* => /home/github/test

### `last_ssh`

**NOT Required** execute pre-commands after scp.


## Usages

#### ssh scp ssh pipelines
```yaml
- name: ssh scp ssh pipelines
  uses: cross-the-world/ssh-scp-ssh-pipelines@v1.0.1
  env:
    WELCOME: "ssh scp ssh pipelines"
    LASTSSH: "Doing something after copying"
  with:
    host: ${{ secrets.DC_HOST }}
    user: ${{ secrets.DC_USER }}
    pass: ${{ secrets.DC_PASS }}
    port: ${{ secrets.DC_PORT }}
    connect_timeout: 10s
    first_ssh: |
      rm -rf /home/github/test
      ls -la  \necho $WELCOME 
      mkdir -p /home/github/test/test1 && 
      mkdir -p /home/github/test/test2 &&
    scp: |
      './test/*' => /home/github/test/
      ./test/test1* => /home/github/test/test1/
      ./test/test*.csv => "/home/github/test/test2/"
    last_ssh: |
      echo $LASTSSH && 
      (mkdir test1/test || true)
      || ls -la
```

#### scp ssh pipelines
```yaml
- name: scp ssh pipelines
  uses: cross-the-world/ssh-scp-ssh-pipelines@v1.0.1
  env:
    LASTSSH: "Doing something after copying"
  with:
    host: ${{ secrets.DC_HOST }}
    user: ${{ secrets.DC_USER }}
    pass: ${{ secrets.DC_PASS }}
    scp: |
      ./test/test1* => /home/github/test/test1/
      ./test/test*.csv => "/home/github/test/test2/"
    last_ssh: |
      echo $LASTSSH 
      ls -la
```

#### scp pipelines
```yaml
- name: scp pipelines
  uses: cross-the-world/ssh-scp-ssh-pipelines@v1.0.1
  with:
    host: ${{ secrets.DC_HOST }}
    user: ${{ secrets.DC_USER }}
    pass: ${{ secrets.DC_PASS }}
    scp: |
      './test/*' => /home/github/test/
```

  
