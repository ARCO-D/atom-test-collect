[TOC]

# 依赖安装

```bash
apt install clang-15
# 这个其实不用装，会先编译出头文件等依赖到.output路径下
apt install libbpf-dev
# 下面这三个可选
apt install binutils-dev
apt install llvm-dev
apt install libcap-dev

ln -s /usr/bin/clang-15 /usr/bin/clang
# 如果libbpf引用了别的仓库，需要加--recurse-submodules递归clone
git clone https://github.com/libbpf/libbpf-bootstrap --recurse-submodules
# 或者已经clone了主仓的话
git pull --recurse-submodules
```

- 需要安装libbpf-dev来提供头文件，但注意，这里安装的是本机架构的，如果配置了ARCH和CROSS_COMPILE来进行交叉编译，工具链仍然会报错缺乏bpf头文件



___

（这依赖恶心坏我了，bootstrap依赖的libbpf和作为子仓的bpftool依赖的libbpf版本还不一样。而且git --recurse-submodules还拉不下来。最后我用git clone单独拉了bpftool里依赖的libbpf的最新版本，可以编译了。）



# 编译分析

直接make，或者make minimal来执行一个app编译

- make -n，只打印不执行；make -p，打印内部数据库

- 使用sed -i 's/\$(Q)//g' Makefile移除$(Q),可以分析Makefile输出

- 安装完clang之后，需要给clang-15创建软链接，不然Makefile找不到clang，还是会用gcc编译——而默认的minimal里用了一些gcc不支持的语法。会编译失败。（或者直接make CC=clang来指定）





# 本地使用测试

直接使用刚编译出的minimal，在本地主机上进行测试

本地ubuntu主机一般有挂载debugfs，如果没有就执行mount debugfs -t debugfs /sys/kernel/debug

同时以root权限执行./minimal

参照输出的提示，cat /sys/kernel/debug/tracing/trace_pipe; 就可以看到输出了





# 交叉编译

emmm...

似乎是因为依赖的子仓会编译出所需的bpf系列头文件的原因，交叉编译也可以直接编

```c
export PATH=$PATH:/home/arco/x-tools/gcc-linaro-11.3.1-2022.06-x86_64_arm-linux-gnueabihf/bin/
export ARCH=arm
export CROSS_COMPILE="arm-linux-gnueabihf-"
```



但是他妈的，还缺少其他依赖项，要么重新编译工具链，要么就自己编了install进去吧

## 编译依赖项

### 编译libz

```bash
wget https://www.zlib.net/zlib-1.3.2.tar.gz
```

这个configure有点low
无语了，直接开干吧

```bash
./configure --prefix=/home/arco/x-tools/gcc-linaro-11.3.1-2022.06-x86_64_arm-linux-gnueabihf/arm-linux-gnueabihf/
```

执行configure的构建出Makefile，然后把CC和LDSHARED修改成自己的

```bash
CC=arm-linux-gnueabihf-gcc
LDSHARED=arm-linux-gnueabihf-gcc -shared -Wl,-soname,libz.so.1,--version-script,zlib.map
```

然后make; make install



### 编译elfutils

- 真他妈傻逼

```bash
# 下载(ubuntu上不明原因很慢)
git clone git://sourceware.org/git/elfutils.git
# 安装构建工具的依赖项
apt-get install autopoint gettext git
# 狗屎
cd elfutils/
autopoint
# 狗屎2
autoreconf -i -f

# configure
./configure --build=arm --host=x86_64 --prefix=/home/arco/x-tools/gcc-linaro-11.3.1-2022.06-x86_64_arm-linux-gnueabihf/arm-linux-gnueabihf/ --with-zlib CC=arm-linux-gnueabihf-gcc --enable-maintainer-mode

# 两种编译安装的方法
# 1) 全部编译
make -j8
make install
# 如果有报错，忽略，因为x86架构执行不了arm的编译件

# 2) 只编译libelf (如果有部分组件编译不过可以试试)
cd lib
# 因为libelf依赖这里的libeu.a
make
cd ../libelf
make -j8
make install
```



## 回到ebpf上来

妈的，真尼玛折腾

```bash
make clean;make minimal CC=arm-linux-gnueabihf-gcc -j8
```

我们就得到了minial，记得file检查下是不是目标架构的

## 交叉编译环境使用

```bash
mount debugfs -t debugfs /sys/kernel/debug
```

## 报错说明

如果出现这样的加载报错，说明我们编译的minimal本身架构是没问题的，就是执行不了

- 没挂载debugfs

```bash
libbpf: failed to open '/sys/kernel/tracing/events/syscalls/sys_enter_write/id': -ENOENT
libbpf: failed to determine tracepoint 'syscalls/sys_enter_write' perf event ID: -ENOENT
libbpf: prog 'handle_tp': failed to create tracepoint 'syscalls/sys_enter_write' perf event: -ENOENT
libbpf: prog 'handle_tp': failed to auto-attach: -ENOENT
Failed to attach BPF skeleton
```

- 可能是内核没配ftrace

```bash
libbpf: object 'minimal_bpf': failed (-22) to create BPF token from '/sys/fs/bpf', skipping optional step...
libbpf: map 'minimal_.bss': created successfully, fd=3
libbpf: map 'minimal_.rodata': created successfully, fd=4
libbpf: prog 'handle_tp': BPF program load failed: -EINVAL
libbpf: prog 'handle_tp': failed to load: -EINVAL
libbpf: failed to load object 'minimal_bpf'
libbpf: failed to load BPF skeleton 'minimal_bpf': -EINVAL
Failed to load and verify BPF skeleton
```

### 重新编译内核



排查下内核编译选项，arm32可能不像arm64那样默认打开了开关

```bash
# 这个需要开
zcat /proc/config.gz |grep BPF
# CONFIG_BPF_JIT is not set

# 这个需要关
zcat /proc/config.gz |grep DEBUG_INFO
CONFIG_DEBUG_INFO_NONE=y

# 关于FTRACE的也需要开启，不然/sys/kernel/debug/tracing/没挂载
CONFIG_FTRACE=y
CONFIG_FTRACE_SYSCALLS=y
```

- 把BPF_JIT打开
- 如果开启了CONFIG_DEBUG_INFO_NONE，那么不会有调试信息（kdump也不能用），需要先关闭，然后CONFIG_DEBUG_INFO_BTF的选项才会出现
- 把CONFIG_DEBUG_INFO_BTF=y打开
- 需要先开启CONFIG_FTRACE，才能开启CONFIG_FTRACE_SYSCALLS

```bash
# 编译CONFIG_DEBUG_INFO_BTF需要安装这个
apt install dwarves
```



## 启动成功

```bash
libbpf: object 'minimal_bpf': failed (-22) to create BPF token from '/sys/fs/bpf', skipping optional step...
# 上面这个报错是没挂在bpf文件系统，这里不影响使用
libbpf: map 'minimal_.bss': created successfully, fd=3
libbpf: map 'minimal_.rodata': created successfully, fd=4
Successfully started! Please run `sudo cat /sys/kernel/debug/tracing/trace_pipe` to see output of the BPF programs.

# 执行...可以看到这样的输出
cat /sys/kernel/debug/tracing/trace_pipe 

         minimal-130     [000] ....1   247.097990: bpf_trace_printk: BPF triggered from PID 130.

         minimal-130     [000] ....1   248.101160: bpf_trace_printk: BPF triggered from PID 130.
```



