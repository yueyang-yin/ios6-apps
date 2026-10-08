# 验证记录

验证日期：2026-10-08。最低支持 iOS 17。入口：集合根目录 `iOS6Apps.xcworkspace`，scheme 为 `WeatherSix`。

| 检查 | 环境 | 结果 |
| --- | --- | --- |
| 默认摄氏度与旧偏好迁移 | 单元测试、iPhone 17 UI | 通过；旧华氏度偏好迁移一次，后续手动选择仍可保存 |
| 图标与温度数字 | 资源生成、实际 UI | App 图标改为 23°；当前、最高／最低、每日及小时预报按当前温标显示 |
| 完整核心回归 | iPhone 17 / iOS 26.2 | 22 项通过 |
| 系统定位与权限恢复 | iPhone 17 / iOS 26.2 | 拒绝权限、显示提示、打开 App 设置、重新允许、模拟 GPS、真实天气加载通过 |
| 迁移后的完整回归 | iPhone SE / iOS 17.5，共享 workspace | 24 项通过；含原生定位及天气／搜索在线联调 |
| 真机安装与启动 | iPhone Air / iOS 27.0.1，Personal Team | Xcode 主界面完成签名、构建、安装；用户信任开发者证书后成功启动 |
| 真机当前定位 | iPhone Air / iOS 27.0.1 | 用户手动测试后反馈“没问题”；未采集定位精度及软件模拟来源标记 |
| 顶部图标遮挡修复完整核心回归 | iPhone Air / iOS 26.2 | 24 项通过：19 项单元测试及 5 项常规 UI 测试；无失败、跳过或编译警告 |
| 顶部图标遮挡修复小屏回归 | iPhone SE 第三代 / iOS 17.5 | 5 项常规 UI 测试全部通过；无失败、跳过或编译警告 |
| 修复版真机更新 | iPhone Air / iOS 27.0.1 | Xcode 重新构建、安装并显示 Running WeatherSix；用户尚未反馈更新后的视觉复测 |
| 天气主体大小及完整闪电回归 | iPhone Air / iOS 26.2 | 25 项核心测试通过；包含新增的闪电顶部及底部轮廓测试，无失败、跳过或编译警告 |
| 天气主体大小及完整闪电小屏回归 | iPhone SE 第三代 / iOS 17.5 | 5 项常规 UI 测试通过，无失败、跳过或编译警告 |
| 最终放大的主天气图标 | iPhone Air / iOS 26.2 | 两项头部回归通过，覆盖 9 种昼夜图标以及 −42°C 和 118°F；无文字交叠，无编译警告 |
| 最终放大的主天气图标与小屏排版 | iPhone SE 第三代 / iOS 17.5 | 三项头部／小屏回归通过，完整保留预报、小时列表、About 与底部按钮；无编译警告 |
| 最终放大版真机启动 | iPhone Air / iOS 27.0.1 | 用户解锁设备后，Xcode 显示 Running WeatherSix on Max’s iPhone Air |
| App 图标数字居中 | 1024 × 1024 AppIcon.png | 按可见字形边界居中“23”，度数符号独立定位；像素中心距太阳中心不超过 1 像素，图标完全不透明 |
| README 语言与项目指令 | 集合根目录与天气 App | 两份 README 全部使用英文；项目 AGENTS.md 明确所有现有及未来 App 的 README 使用英文 |
| Add City 完整回归及区县在线联调 | iPhone Air / iOS 26.2 | 37 项通过；30 项核心单元测试、5 项常规 UI 及 2 项新在线测试，无失败、跳过或编译警告 |
| Add City 兼容性及小屏在线联调 | iPhone SE 第三代 / iOS 17.5 | 34 项相关测试通过；包含完整单元测试、城市操作、小屏 About 及真实泉山区搜索／添加／预报加载 |
| 搜索修复版真机更新 | iPhone Air / iOS 27.0.1 | Xcode 完成构建、安装并显示 Running WeatherSix on Max’s iPhone Air；用户尚未反馈本版的手动搜索复测 |
| 经典开关界面回归 | iPhone Air / iOS 26.2、iPhone SE 第三代 / iOS 17.5 | Air 的 3 项相关 UI 测试及 SE 的 2 项通过，无失败、跳过或编译警告；两种尺寸截图已检查 |
| 经典开关交互与语义 | iPhone Air / iOS 26.2，Codex 内置浏览器镜像 | 滑块点击、整行点击及双向拖动成功；无障碍树保持 switch 角色、Demo Weather 标签及 0/1 状态，开启后显示 23°C Demo 预报 |
| 经典开关真机更新与独立运行 | iPhone Air / iOS 27.0.1，Personal Team | Xcode 完成构建、安装并显示 Running WeatherSix；随后 LLDB 正常 detach，退出 Xcode 后确认手机 WeatherSix 进程仍在运行 |
| 中英文完整回归 | iPhone Air / iOS 26.2 | 50 项通过；启用全部 4 项可选在线／定位测试，无失败、跳过或编译警告 |
| 最终地名来源保护回归 | iPhone Air / iOS 26.2 | 18 项定位语言／搜索测试通过，含新增的外国名称保护和真实泉山区联调，无失败、跳过或编译警告 |
| 最终中英文小屏兼容性回归 | iPhone SE 第三代 / iOS 17.5 | 最终 51 项全部通过；启用全部可选测试，无失败、跳过或编译警告 |
| 中英文版真机更新与独立运行 | iPhone Air / iOS 27.0.1，Personal Team | 用户解锁后 Xcode 显示 Running WeatherSix；正常 detach 并退出 Xcode，设备进程列表确认 WeatherSix（PID 5181）仍在运行；真机语言切换的手动复测尚未反馈 |
| Swift 格式与编译 | Xcode 自带 swift-format、XcodeBuildMCP | strict lint、编译通过；最终检查无警告或错误 |
| 顶层重命名 | weather-ios6 → ios6-apps | 111 个文件的 SHA-256 在重命名前后相同，包含 Git 元数据 |

目前 39 项核心单元测试覆盖温标迁移、预报、持久化、8 项定位状态、闪电轮廓、区县与行政层级、邮编、缓存、取消、服务降级及中英语言资源与名称身份。8 项常规 UI 测试覆盖城市管理、温标、小时列表、About、翻面、9 种昼夜图标、负数及三位数温度，以及中文界面双语搜索和英文界面中文搜索。另有 4 项可选在线／定位测试，本次在 Air 与 SE 上全部启用。最终 SE 完整运行 51 项；Air 完整运行 50 项后，最后一项地名来源保护通过 18 项相关回归验证。

中英文适配覆盖 92 条界面资源：控制按钮、演示开关、天气状况、星期与时间、加载和错误提示、定位权限说明、桌面名称与无障碍标签。界面遵循系统／每 App 语言，中文使用简体和 24 小时显示，英文保留原有 12 小时样式；其他语言回退英文。测试通过 AppleLanguages 启动参数切换语言，没有修改模拟器系统偏好。

搜索语言独立于界面语言：汉字查询获取中文／原生名称，拉丁字母查询获取英文名称，数字邮编使用当前界面语言。Photon 不支持 lang=zh，按原生和英文请求配对同一地点，GeoNames 降级请求支持 zh/en，并按 ISO 国家代码翻译国家名。中文名称统一为简体；服务缺失译名时保留来源名称，中国地名缺失英文时可回退拼音，外国地名不转成汉语拼音。实际服务验证泉山区两种名称及徐州／江苏层级对应同一坐标和地点 ID。

保存城市新增可选双语名称字段，旧存储格式仍可读取；切换语言后补齐缺失的名称，城市坐标、时区和预报缓存保持有效。翻译后不重复添加相同地点；邮编缺少上游 ID 时采用与语言无关的类型／坐标／邮编作为身份。并发获取名称和预报时，名称更新不会导致已返回的有效预报被丢弃。

中英文截图位于 screenshots/localization/iphone-air/ 和 screenshots/localization/iphone-se/，每种设备 7 张，覆盖中文天气、城市管理、About、中文界面英／中搜索以及英文界面中文搜索与英文天气。已人工检查中文控件、小屏排版和查询语言独立显示。

经典开关修复将 Demo Weather 的系统默认 Toggle 外观替换为 ClassicToggleStyle：不透明蓝色 ON 槽、灰色 OFF 槽、带高光与阴影的白色滑块。绘制不使用系统玻璃材质，支持点击与拖动，保留 44 点点击区域，并遵守 Reduce Motion。通过仅用于无障碍的原生 Toggle 表示保留开关语义。本次按界面改动范围运行已有城市／温标／搜索、翻面及小屏 About 流程，未重复运行无关天气服务和定位测试。Air 镜像已更新并保留在城市管理页；恢复了检查前的关闭 Demo 状态。

Add City 修复已复现并在线确认：原 GeoNames 搜索返回浙江、辽宁等省份的同名 Quanshan 地点，却查不到徐州泉山区；原结果仅显示省份与国家，缺少上级城市。新搜索使用 Photon／OpenStreetMap 的行政地点索引，保留 GeoNames 作为备用，优先筛选城市、区县、乡镇等地点并排除电站等土地使用对象。结果保留上级市／县、省／州及国家，重复行政地点合并显示，缺失的层级不编造补全。

实际服务联调在 Air 与 SE 上均验证“泉山区”“徐州市泉山区”“QuanShan”返回相同地点（OSM R3218567）：纬度 34.2273368，经度 117.1884578。中文结果归属为“徐州市, 江苏省, 中国”，拼音结果为“Xuzhou, Jiangsu Province, China”；真实天气接口返回 Asia/Shanghai 时区、6 天与 12 小时预报。真实 UI 输入 QuanShan 后点击泉山区结果、确认城市已加入，并成功显示未标记 Demo 的实时摄氏度天气。英国 GU1 4TY 邮编也正确解析为 Guildford。

中文复合行政名称自动加入分隔，未维护针对泉山区的专用目录；“市中区”“新市区”等名称保持完整。搜索输入延迟、每秒至多一次请求及短期缓存减少重复访问；取消后不降级请求，旧查询结果不覆盖新输入。附近但名称不同的地点不再仅因坐标接近而合并。未知时区在真实预报返回后更新并保存。Demo Weather 的离线预设搜索目录保持相同地点，并已支持中英名称查询；实时区县搜索需关闭 Demo Weather。

顶部修复保留居中的悬浮图标，为图标完整高度预留文字布局空间。各天气图标按包含光晕、阴影、降水及闪电的绘图边界统一缩放并限制绘制范围。两个新增 UI 回归在 Air 与 SE 上分别覆盖 7 种日间天气、2 种夜间图标、−42°C 及 118°F，验证图标与当前温度／城市名称无交叠、图标与温度完整位于屏幕内，以及底部按钮仍可点击。每种设备保存 11 张真实 XCTest 截图；另已人工查看 Air 的太阳、月亮、雷雨和 SE 的三位数雷雨画面。

后续视觉修正改为按太阳、月亮和云朵的实体面积校准大小，再放入共用画布；光晕、降水和闪电不再影响主体缩放。雨、雪、雷暴的云朵使用相同缩放和锚点。顶部主图标按用户反馈进一步放大，头部文字区域同步增加留白；较小屏幕减少预报行留白以保留底部按钮。

最终主图标区域在 Air 上约为 224 × 182 点，比最初的 170 × 138 点扩大约 32%；SE 上约为 192 × 156 点。常规尺寸随可用高度调整，头部为图标预留完整高度及文字间距；每日、小时预报的小图标继续使用校准后的原有尺寸。已人工查看最终 Air 雷暴、9 种图标对比和 SE 的 118°F 雷暴页面。

闪电不完整的原因已复现：原代码先 move 到顶部，再调用 addLines；addLines 从数组首点开始新的子路径，导致上端没有进入闭合轮廓。原可见范围为 y = 88…123；修正后的完整范围为 y = 73…123，顶部实体点及底部实体点检查均通过。光晕半径收紧为 3，避免下端的光晕碰到绘图边界。

App 图标使用 Core Text 的可见字形边界将数字“23”对齐太阳中心，度数符号单独作为上标绘制，避免整串“23°”的文字宽度把数字推向左侧。

定位修复包含：服务关闭与权限拒绝分别提示、Open Settings 入口、临时 locationUnknown 重试、GPS 与反向地理编码独立超时、取消后的旧回调忽略、城市查询超时使用有效坐标继续获取天气。成功定位会退出演示模式并清理旧定位预报，始终刷新真实数据。系统定位可用性检查在后台执行。

iOS 26+ 使用 MKReverseGeocodingRequest，iOS 17 使用 CLGeocoder。原生定位测试通过 XCTest 设定公开的伦敦模拟坐标，结束后恢复原来的模拟位置；这些结果不等同于真实设备 GPS 验证。

最终测试产物：

- `/private/tmp/weather-six-celsius-location-unit.xcresult`：22 项核心回归。
- `/private/tmp/weather-six-location-final.xcresult`：iOS 26 的 8 项定位状态测试与原生权限／定位联调。
- `/private/tmp/ios6-apps-weather-final.xcresult`：目录迁移后，在 iOS 17.5 上完整运行 24 项测试。
- `/private/tmp/ios6-apps-header-air.xcresult`：顶部修复后，iPhone Air / iOS 26.2 的 24 项核心回归。
- `/private/tmp/ios6-apps-header-se.xcresult`：顶部修复后，iPhone SE 第三代 / iOS 17.5 的 5 项常规 UI 回归。
- `/private/tmp/ios6-apps-artwork-final-air.xcresult`：主体大小及完整闪电修复后的 25 项核心回归。
- `/private/tmp/ios6-apps-artwork-final-se.xcresult`：主体大小及完整闪电修复后的 5 项小屏 UI 回归。
- `/private/tmp/ios6-apps-large-artwork-air.xcresult`：最终放大后的两项头部回归。
- `/private/tmp/ios6-apps-large-artwork-se.xcresult`：最终放大后的三项头部／小屏回归。
- `/private/tmp/ios6-apps-place-search-air.xcresult`：Add City 修复后，Air 的 37 项测试及两项新区县在线联调。
- `/private/tmp/ios6-apps-place-search-se.xcresult`：Add City 修复后，SE 的 34 项兼容性／界面与在线验证。
- `/private/tmp/ios6-apps-classic-switch-air.xcresult`：经典开关修复后，Air 的 3 项相关 UI 回归。
- `/private/tmp/ios6-apps-classic-switch-se.xcresult`：经典开关修复后，SE 的 2 项城市管理及小屏回归。
- `/private/tmp/ios6-apps-localization-air-final.xcresult`：中英文更新后，Air 的 50 项完整回归。
- `/private/tmp/ios6-apps-localization-air-names.xcresult`：最终名称来源保护后的 18 项相关回归。
- `/private/tmp/ios6-apps-localization-se.xcresult`：最终 SE 的 51 项完整回归。

截图保存在本目录的 `screenshots/`。`screenshots/header/` 保留最初的遮挡修复记录；最新放大版分别位于 `screenshots/optical/iphone-air/` 与 `screenshots/optical/iphone-se/`，每种设备 11 张截图。9 种昼夜图标对比图为 `screenshots/optical/comparison-air.png`。实际文件与新的开发入口都位于 `ios6-apps`。旧路径的临时符号链接因不受 Codex 文件沙箱支持已移除；已有 Codex 项目需要重新选择新目录。

新区县搜索及真实天气截图位于 `screenshots/place-search/iphone-air/` 与 `screenshots/place-search/iphone-se/`，每种设备各两张。地名解析回归使用实际 Photon 响应样本：`photon-quanshan-chinese.json`、`photon-quanshan-pinyin.json`、`photon-baiyun.json` 及 `photon-uk-postcode.json`。数据来源与 OpenStreetMap／ODbL 署名已在 Add City 及 About 中显示；公共地名服务覆盖和可用性由上游数据决定。

经典开关截图位于 `screenshots/classic-switch/`：Air 的 ON/OFF 实际状态及 Air、SE 的 XCTest 原始城市管理截图。当前开关外观修复已在模拟器验证，且已在真机构建、安装和启动。退出 Xcode 前正常解除调试器连接，退出后通过设备进程列表确认 App 继续独立运行；用户尚未反馈本版的真机视觉复测。

中英文适配版已在同一真机构建、安装并启动。退出 Xcode 后通过 devicectl 确认 WeatherSix 继续独立运行，同时确认 Xcode 主程序已退出。尚未收到用户对本版中英文界面与搜索的手动真机复测反馈。

真机测试使用正常 Run，未运行会设置伦敦模拟坐标的定位 UI 测试；Run 的模拟定位配置已关闭。安装及启动结果由 Xcode 界面确认，真机定位通过来自用户的手动实测反馈，未采集自动化真机定位结果。

发布签名和 iCloud 同步尚未验证或配置。用户曾拒绝过定位时，需要通过 App 内 Open Settings 恢复授权；模拟器需要配置模拟位置。
