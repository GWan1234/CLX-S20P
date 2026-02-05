

- [Source Code](https://github.com/hanwckf/immortalwrt-mt798x)
- End sync commit `20251224` `ba55419`
- 详情参见[hanwckf's blog](https://cmi.hanwckf.top/p/immortalwrt-mt798x/)
- 基于immortalwrt 21.02分支，内核版本5.4
- 使用mtwifi原厂无线驱动（目前默认使用7.6.6.3版本），默认开启802.11k，支持warp在内的所有加速特性
- `openssl`已更新到`3.5.4`,以支持http3/quic
- S20P的2.5G口存在*假联机*的情况,普遍反馈是`v21.02-k5.4`对`2.5G PHY`支持不完善
- S20P支持`dsa`和`gsw`两种`Switch`模式


  ### Quickstart
  1. 参考immortalwrt的[README](https://github.com/immortalwrt/immortalwrt/blob/openwrt-21.02/README.md)配置编译环境，并更新feeds
  2. 使用defconfig目录内预置的配置文件作为配置模板，

      ```bash
      # defconfig/luci-app-mtk-deprecated目录里的配置文件使用旧版luci-app-mtk作为无线配置工具

      # 对于mt7981，使用mt7981-ax3000.config
      cp -f defconfig/mt7981-ax3000.config .config

      # 对于mt7986，使用mt7986-ax6000.config
      #cp -f defconfig/mt7986-ax6000.config .config

      # 对于256M内存的mt7986（如磊科N60），使用mt7986-ax6000-256m.config
      #cp -f defconfig/mt7986-ax6000-256m.config .config

      # 对于AX4200方案的mt7986（如BPI-R3 MINI），使用mt7986-ax4200.config
      #cp -f defconfig/mt7986-ax4200.config .config

      # s20p文件夹中为自用的一些配置
      ```
  3. 运行make menuconfig定制固件
  4. 运行make V=s开始编译固件，为了加快编译速度，可以使用make V=s -j$(nproc)

