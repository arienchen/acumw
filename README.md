# acumw
AcuCOBOL IPC Library for AIX

This is a simple project, which bind C IPC calls to runcbl of AcuCOBOL v9.x for AIX.

## Tables Contents

- [Platforms](#platform)
- [Features](#features)
- [Environments](#environments)
- [Samples](#samples)

## Platform:
IBM/AIX 64bits
* AIX5.3
* AIX6.1
* AIX7.1

Compiler
* GNU/gcc 4.8.5 
* Microfocus AcuCOBOL v9

## Features:
Supported:
* SYS/V Message Queue (msg_xxx)
* POSIX Message Queue (mq_xxx)

Not Supported yet:
* Semaphore
* Shared Memory
* Memory Mapped File

## Environments

### Install AcuRuntime Libraries
* Assume ACU COBOL installed at /opt/acucorp/900
  
* Create Diectory for acumw

  for example: /opt/acucorp/mw
  
  ``` shell 
  /opt/acucorp/mw
                  ./bin/
                  ./lib/
                  ./cpy/
  ```
  
* Deploy Libraries for Runtime 
  ``` shell
  /opt/acucorp/mw/lib/libruncbl64.so 
  /opt/acucorp/mw/lib/libmwapi64.so 
  ```

* Deploy Copybook for COBOL Developmet 
  ``` shell
  /opt/acucorp/mw/cpy/MWAPI.DEF
  ``` 
  
* Enviroment Vaiables
  ``` shell
  # AcuCOBOL Home 
  acu=/opt/acucorp/900
  
  # API Home 
  mw=/opt/acucorp/mw
  
  # RUNCBL Specific, could differ 
  # set for your own 
  export A_CONFIG=${your_conf}/ACUUNIX.CFG
  export A_TERMCAP=${your_conf}/TERMCAP.ACU
  export A_TERM=vt220
  export TERM=vt220 
  
  # Path, append yours 
  export PATH=${mw}/bin:${acu}/bin:${your_path}
  export COPYPATH=${mw}/cpy:${your_copypath}
  # ${mw}/lib must before ${acu}/lib
  export LD_LIBRARY_PATH=${mw}/lib:${acu}/lib:${your_libpath}
  
  # acumw use ZLOG library
  export ZLOG_CONF=${mw}/conf/acumw.zlog 
  
  
  ```
  
  ZLOG CONF sample:
 
  Please refer https://hardysimpson.github.io/zlog/UsersGuide-EN.html for detail 

  ``` shell 
  
  [global]
  strict init = false
  reload conf period = 1M
  file perms = 660
  fsync period = 1K

  #buffer min = 1024
  #buffer max = 2MB
  #rotate lock file = /tmp/zlog.lock
  #default format = "%d.%ms %-6V (%c:%F:%L) - %m%n"
  default format = "%d(%T).%us %-6V [%c] %m%n"

  [formats]
  # %d.%ms %-6V %m%n        -> 2015-03-02 19:01:23.123 INFO   MSG
  # %d(%Y%m%d %T) %-6V %m%n -> 20150302 19:01:23 INFO   MSG 
  # %d(%T).%us %-6V %m%n    -> 19:01:23.123456 INFO   MSG 
  #ts = "%d(%T).%us %m%n"

  [rules]
  #*.* "/opt/acucorp/mw/log/acumw.log" , 100M * 5
  ipcmsg.* "/tmp/acumw.log" , 10M * 5
  *.ERROR > stderr 

  ```
  
  when environment variable been set.
  
  run `ldd` command to verify 
  ``` shell
  ldd ${acu}/bin/runcbl 
  ``` 
  
  it should refere to ${mw}/lib/libruncbl64.so and libmwapi64.so 
  
  if not, or found any unknow references. 
  please check the environment again. 
  
  
## Samples 


  
