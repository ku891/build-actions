#!/bin/bash
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
# DIY鎵╁睍浜屽悎涓€浜嗭紝鍦ㄦ澶勫彲浠ュ鍔犳彃浠?
# 鑷鎷夊彇鎻掍欢涔嬪墠璇稴SH杩炴帴杩涘叆鍥轰欢閰嶇疆閲岄潰纭杩囨病鏈変綘瑕佺殑鎻掍欢鍐嶅崟鐙媺鍙栦綘闇€瑕佺殑鎻掍欢
# 涓嶈涓€涓嬪氨鎷夊彇鍒汉涓€涓彃浠跺寘N澶氭彃浠剁殑锛屽浜嗘病鐢紝澧炲姞缂栬瘧閿欒锛岃嚜宸遍渶瑕佺殑鎵嶅ソ
# ===== 娣诲姞feeds =====
echo 'src-git fileshare https://github.com/ku891/fileshare-openwrt.git;main' >> feeds.conf.default

# Node prebuilt for fileshare (avoid compiling node from source on cloud CI)
install_node_prebuilt() {
  local owrt="${HOME_PATH:-${GITHUB_WORKSPACE}/openwrt}}"
  [[ -d "$owrt/feeds/packages/lang" ]] || return 0
  rm -rf "$owrt/feeds/packages/lang/node"
  if git clone --depth=1 -b packages-24.10 https://github.com/sbwml/feeds_packages_lang_node \
      "$owrt/feeds/packages/lang/node" 2>/dev/null; then
    return 0
  fi
  git clone --depth=1 https://github.com/sbwml/feeds_packages_lang_node-prebuilt \
    "$owrt/feeds/packages/lang/node" 2>/dev/null || true
}
install_node_prebuilt


# 鍚庡彴IP璁剧疆
export Ipv4_ipaddr="192.168.5.5"            # 淇敼openwrt鍚庡彴鍦板潃(濉?涓哄叧闂?
export Netmask_netm="255.255.255.0"         # IPv4 瀛愮綉鎺╃爜锛堥粯璁わ細255.255.255.0锛?濉?涓轰笉浣滀慨鏀?
export Op_name="OPMini-Roman"                # 淇敼涓绘満鍚嶇О涓篛penWrt-123(濉?涓轰笉浣滀慨鏀?

# 鍐呮牳鍜岀郴缁熷垎鍖哄ぇ灏?涓嶆槸姣忎釜鏈哄瀷閮藉彲鐢?
export Kernel_partition_size="256"            # 鍐呮牳鍒嗗尯澶у皬,姣忎釜鏈哄瀷榛樿鍊间笉涓€鏍?(濉啓鎮ㄦ兂瑕佺殑鏁板€?榛樿涓€鑸?6,鏁板€间互MB璁＄畻锛屽～0涓轰笉浣滀慨鏀?,濡傛灉浣犱笉鎳傚氨濉?
export Rootfs_partition_size="950"            # 绯荤粺鍒嗗尯澶у皬,姣忎釜鏈哄瀷榛樿鍊间笉涓€鏍?(濉啓鎮ㄦ兂瑕佺殑鏁板€?榛樿涓€鑸?00宸﹀彸,鏁板€间互MB璁＄畻锛屽～0涓轰笉浣滀慨鏀?,濡傛灉浣犱笉鎳傚氨濉?

# 榛樿涓婚璁剧疆
export Mandatory_theme="argon"              # 灏哹ootstrap鏇挎崲鎮ㄩ渶瑕佺殑涓婚涓哄繀閫変富棰?鍙嚜琛屾洿鏀规偍瑕佺殑,婧愮爜瑕佸甫姝や富棰樺氨琛?濉啓鍚嶇О涔熻鍐欏) (濉啓涓婚鍚嶇О,濉?涓轰笉浣滀慨鏀?
export Default_theme="argon"                # 澶氫富棰樻椂,閫夋嫨鏌愪富棰樹负榛樿绗竴涓婚 (濉啓涓婚鍚嶇О,濉?涓轰笉浣滀慨鏀?

# 鏃佽矾鐢遍€夐」
export Gateway_Settings="192.168.5.10"                 # 鏃佽矾鐢辫缃?IPv4 缃戝叧(濉叆鎮ㄧ殑缃戝叧IP涓哄惎鐢?(濉?涓轰笉浣滀慨鏀?
export DNS_Settings="192.168.5.10"                     # 鏃佽矾鐢辫缃?DNS(濉叆DNS锛屽涓狣NS瑕佺敤绌烘牸鍒嗗紑)(濉?涓轰笉浣滀慨鏀?
export Broadcast_Ipv4="192.168.5.255"                   # 璁剧疆 IPv4 骞挎挱(濉叆鎮ㄧ殑IP涓哄惎鐢?(濉?涓轰笉浣滀慨鏀?
export Disable_DHCP="1"                     # 鏃佽矾鐢卞叧闂璂HCP鍔熻兘(1涓哄惎鐢ㄥ懡浠?濉?涓轰笉浣滀慨鏀?
export Disable_Bridge="1"                   # 鏃佽矾鐢卞幓鎺夋ˉ鎺ユā寮?1涓哄惎鐢ㄥ懡浠?濉?涓轰笉浣滀慨鏀?
export Create_Ipv6_Lan="0"                  # 鐖卞揩+OP鍙岀郴缁熸椂,鐖卞揩鎺ョIPV6,鍦∣P鍒涘缓IPV6鐨刲an鍙ｆ帴鏀禝PV6淇℃伅(1涓哄惎鐢ㄥ懡浠?濉?涓轰笉浣滀慨鏀?

# IPV6銆両PV4 閫夋嫨
export Enable_IPV6_function="0"             # 缂栬瘧IPV6鍥轰欢(1涓哄惎鐢ㄥ懡浠?濉?涓轰笉浣滀慨鏀?(濡傛灉璺烠reate_Ipv6_Lan涓€璧峰惎鐢ㄥ懡浠ょ殑璇?Create_Ipv6_Lan鍛戒护浼氳嚜鍔ㄥ叧闂?
export Enable_IPV4_function="0"             # 缂栬瘧IPV4鍥轰欢(1涓哄惎鐢ㄥ懡浠?濉?涓轰笉浣滀慨鏀?(濡傛灉璺烢nable_IPV6_function涓€璧峰惎鐢ㄥ懡浠ょ殑璇?姝ゅ懡浠や細鑷姩鍏抽棴)

# 鏇挎崲OpenClash鐨勬簮鐮?榛樿master鍒嗘敮)
export OpenClash_branch="1"                 # OpenClash鐨勬簮鐮佸垎鍒湁銆恗aster鍒嗘敮銆戝拰銆恉ev鍒嗘敮銆?濉?涓哄叧闂?濉?涓轰娇鐢╩aster鍒嗘敮,濉?涓轰娇鐢╠ev鍒嗘敮,濉叆1鎴?鐨勬椂鍊欏浐浠惰嚜鍔ㄥ鍔犳鎻掍欢)

# 涓€х鍚?榛樿澧炲姞骞存湀鏃$(TZ=UTC-8 date "+%Y.%m.%d")]
export Customized_Information="$(TZ=UTC-8 date "+%Y.%m.%d")"  # 涓€х鍚?浣犳兂鍐欏暐灏卞啓鍟ワ紝(濉?涓轰笉浣滀慨鏀?

# 鏇存崲鍥轰欢鍐呮牳
export Replace_Kernel="0"                    # 鏇存崲鍐呮牳鐗堟湰,鍦ㄥ搴旀簮鐮佺殑[target/linux/鏋舵瀯]鏌ョ湅patches-x.x,鐪嬬湅x.x鏈夊暐灏辨湁鍟ュ唴鏍镐簡(濉叆鍐呮牳x.x鐗堟湰鍙?濉?涓轰笉浣滀慨鏀?

# 璁剧疆鍏嶅瘑鐮佺櫥褰?涓埆婧愮爜鏈韩灏辨病瀵嗙爜鐨?
export Password_free_login="1"               # 璁剧疆棣栨鐧诲綍鍚庡彴瀵嗙爜涓虹┖锛堣繘鍏penwrt鍚庤嚜琛屼慨鏀瑰瘑鐮侊級(1涓哄惎鐢ㄥ懡浠?濉?涓轰笉浣滀慨鏀?

# 澧炲姞AdGuardHome鎻掍欢鍜屾牳蹇?
export AdGuardHome_Core="0"                  # 缂栬瘧鍥轰欢鏃惰嚜鍔ㄥ鍔燗dGuardHome鎻掍欢鍜孉dGuardHome鎻掍欢鏍稿績,闇€瑕佹敞鎰忕殑鏄竴涓牳蹇?0澶歁B鐨?灏忛棯瀛樻満瀛愭悶涓嶆潵(1涓哄惎鐢ㄥ懡浠?濉?涓轰笉浣滀慨鏀?

# 寮€鍚疦TFS鏍煎紡鐩樻寕杞?
export Automatic_Mount_Settings="0"          # 缂栬瘧鏃跺姞鍏ュ紑鍚疦TFS鏍煎紡鐩樻寕杞界殑鎵€闇€渚濊禆(1涓哄惎鐢ㄥ懡浠?濉?涓轰笉浣滀慨鏀?

# 鍘婚櫎缃戠粶鍏变韩(autosamba)
export Disable_autosamba="0"                 # 鍘绘帀婧愮爜榛樿鑷€夌殑luci-app-samba鎴杔uci-app-samba4(1涓哄惎鐢ㄥ懡浠?濉?涓轰笉浣滀慨鏀?

# 鍏朵粬
export Ttyd_account_free_login="0"           # 璁剧疆ttyd鍏嶅瘑鐧诲綍(1涓哄惎鐢ㄥ懡浠?濉?涓轰笉浣滀慨鏀?
export Delete_unnecessary_items="0"          # 涓埆鏈哄瀷鍐呬竴鍫嗗叾浠栨満鍨嬪浐浠?鍒犻櫎鍏朵粬鏈哄瀷鐨?鍙繚鐣欏綋鍓嶄富鏈哄瀷鍥轰欢(1涓哄惎鐢ㄥ懡浠?濉?涓轰笉浣滀慨鏀?
export Disable_53_redirection="0"            # 鍒犻櫎DNS寮哄埗閲嶅畾鍚?3绔彛闃茬伀澧欒鍒?涓埆婧愮爜鏈韩涓嶅甫姝ゅ姛鑳?(1涓哄惎鐢ㄥ懡浠?濉?涓轰笉浣滀慨鏀?
export Cancel_running="0"                    # 鍙栨秷璺敱鍣ㄦ瘡澶╄窇鍒嗕换鍔?涓埆婧愮爜鏈韩涓嶅甫姝ゅ姛鑳?(1涓哄惎鐢ㄥ懡浠?濉?涓轰笉浣滀慨鏀?


# 鏅舵櫒CPU绯诲垪鎵撳寘鍥轰欢璁剧疆(涓嶆噦璇风湅璇存槑)
export amlogic_model="s905d"
export amlogic_kernel="6.1.120_6.12.15"
export auto_kernel="true"
export rootfs_size="512/2560"
export kernel_usage="stable"


# 淇敼鎻掍欢鍚嶅瓧
grep -rl '"缁堢"' . | xargs -r sed -i 's?"缁堢"?"TTYD"?g'
grep -rl '"TTYD 缁堢"' . | xargs -r sed -i 's?"TTYD 缁堢"?"TTYD"?g'
grep -rl '"缃戠粶瀛樺偍"' . | xargs -r sed -i 's?"缃戠粶瀛樺偍"?"NAS"?g'
grep -rl '"瀹炴椂娴侀噺鐩戞祴"' . | xargs -r sed -i 's?"瀹炴椂娴侀噺鐩戞祴"?"娴侀噺"?g'
grep -rl '"KMS 鏈嶅姟鍣?' . | xargs -r sed -i 's?"KMS 鏈嶅姟鍣??"KMS婵€娲??g'
grep -rl '"USB 鎵撳嵃鏈嶅姟鍣?' . | xargs -r sed -i 's?"USB 鎵撳嵃鏈嶅姟鍣??"鎵撳嵃鏈嶅姟"?g'
grep -rl '"Web 绠＄悊"' . | xargs -r sed -i 's?"Web 绠＄悊"?"Web绠＄悊"?g'
grep -rl '"绠＄悊鏉?' . | xargs -r sed -i 's?"绠＄悊鏉??"鏀瑰瘑鐮??g'
grep -rl '"甯﹀鐩戞帶"' . | xargs -r sed -i 's?"甯﹀鐩戞帶"?"鐩戞帶"?g'


# 鏁寸悊鍥轰欢鍖呮椂鍊?鍒犻櫎鎮ㄤ笉鎯宠鐨勫浐浠舵垨鑰呮枃浠?璁╁畠涓嶉渶瑕佷笂浼犲埌Actions绌洪棿(鏍规嵁缂栬瘧鏈哄瀷鍙樺寲,鑷璋冩暣鍒犻櫎鍚嶇О)
cat >"$CLEAR_PATH" <<-EOF
packages
config.buildinfo
feeds.buildinfo
sha256sums
version.buildinfo
profiles.json
openwrt-x86-64-generic-kernel.bin
openwrt-x86-64-generic.manifest
openwrt-x86-64-generic-squashfs-rootfs.img.gz
EOF

# 鍦ㄧ嚎鏇存柊鏃讹紝鍒犻櫎涓嶆兂淇濈暀鍥轰欢鐨勬煇涓枃浠讹紝鍦‥OF璺烢OF涔嬮棿鍔犲叆鍒犻櫎浠ｇ爜锛岃浣忚繖閲屽搴旂殑鏄浐浠剁殑鏂囦欢璺緞锛屾瘮濡傦細 rm -rf /etc/config/luci
cat >>$DELETE <<-EOF
EOF
