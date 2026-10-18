#!/usr/bin/env python3
"""Generate paired English and Simplified Chinese resources."""
from pathlib import Path
import json
import plistlib

ROOT = Path(__file__).resolve().parent.parent / "PassbookSix"
TEXT = {
    "Passbook": "票据夹", "Boarding Passes": "登机牌", "Tickets": "门票",
    "Store Cards": "商店会员卡", "Coupons": "优惠券", "Other Passes": "其他票据",
    "Boarding Pass": "登机牌", "Coffee Card": "咖啡会员卡", "Your stay": "您的住宿",
    "A Night at the Cinema": "影院之夜", "A little something for you.": "送给您的一点心意。",
    "Welcome headline": "票据夹，\n装下口袋里的大小事。",
    "Welcome explanation": "把登机牌、门票、会员卡和优惠券，\n随身放在同一个地方。",
    "Add Passes": "添加票据", "Cancel": "取消", "Done": "完成", "Add": "添加",
    "All Passes": "所有票据", "Information": "票据信息", "Delete Pass": "删除票据",
    "Delete": "删除", "OK": "好", "About Passbook": "关于票据夹",
    "Pass information": "票据信息", "Open this pass": "打开这张票据",
    "Pass barcode": "票据条码", "Barcode unavailable": "无法显示条码",
    "Keep it all in your pocket.": "把需要的，都装进口袋。",
    "Catalog explanation": "导入发行方提供的票据，或体验经典的彩色票据。",
    "Import a .pkpass file": "导入 .pkpass 文件", "Create a local pass": "创建本地票据",
    "SAMPLE PASSES": "示例票据", "Try a sample pass": "体验一张示例票据",
    "Add sample collection": "添加整套示例票据", "DEMO PASS": "示例票据", "EXPIRED": "已过期",
    "Sample pass explanation": "这是用于展示设计和交互的示例，不能用于登机、入场或消费。",
    "Sample coupon terms": "仅用于演示。没有现金价值，不可兑换任何商品或服务。",
    "Wallet integration explanation": "可把发行方签名的票据添加到 Apple 钱包。锁屏提醒和票据更新由系统钱包与发行方管理。",
    "Local pass explanation": "本地票据只保存在本 App 中。条码会编码您输入的内容；能否使用取决于接收方。本地创建的票据不能添加到系统钱包。",
    "About explanation": "以 iOS 6 票据夹为灵感的独立复刻。点击票据展开，点击 i 翻面。示例票据没有实际用途。系统钱包、锁屏提醒和发行方更新通过 Apple 钱包提供。",
    "Delete confirmation": "从本 App 删除这张票据？这不会删除 Apple 钱包中的票据。",
    "Could not load passes": "无法读取已保存的票据。原始文件仍保留，请检查设备储存空间后重新打开 App。",
    "Could not save passes": "无法保存更改。请检查设备储存空间后重试。",
    "Could not import pass": "无法导入票据。请选择有效的发行方签名 .pkpass 文件（不超过 20 MB）。",
    "%ld passes": "%ld 张票据", "New Pass": "新票据", "Pass type": "票据类型",
    "Organization": "发行方", "Title": "标题", "Details": "详细信息", "Barcode message": "条码内容",
    "Expiration date": "有效期", "Expires": "到期日期", "Notes": "备注",
    "Organization and title are required.": "请填写发行方和标题。",
    "Move Up": "向上移动", "Move Down": "向下移动", "Share Pass": "分享票据",
    "Add to Apple Wallet": "添加到 Apple 钱包", "About this pass": "关于这张票据",
    "Terms and conditions": "条款与条件", "FLIGHT": "航班", "London Heathrow": "伦敦希思罗",
    "San Francisco": "旧金山", "PASSENGER": "乘客", "BOARDING": "登机时间",
    "GATE": "登机口", "SEAT": "座位", "GROUP": "组别", "DISCOUNT": "折扣", "10% off": "九折优惠", "3 NIGHTS": "3 晚", "Jun 12 - 15": "6月12–15日", "Sep 22 - 25": "9月22–25日", "Sept 27": "9月27日", "1:10 PM": "下午 1:10", "BASEBALL": "棒球", "STARPOINTS": "积分", "ADMIT": "入场人数", "ONE": "一位",
    "FEATURE PRESENTATION": "即将上映", "The Grand Adventure": "奇妙冒险",
    "SHOWTIME": "放映时间", "7:00 PM": "晚上 7:00", "SCREEN": "影厅", "ROW": "排",
    "VENUE": "地点", "Grand Cinema": "大剧院电影院", "BALANCE": "余额", "NICKNAME": "昵称",
    "Alex’s Coffee Card": "Alex 的咖啡卡", "REWARDS": "奖励", "12 STARS": "12 颗星",
    "MEMBER SINCE": "加入年份", "YOUR NEXT PURCHASE": "下次购物", "50% OFF": "五折优惠",
    "PROMO CODE": "优惠码", "VALID AT": "适用门店", "All stores": "所有门店", "GUEST": "宾客",
    "ROOM": "房间", "NIGHTS": "晚数", "Pittsburgh vs. New York": "匹兹堡对阵纽约",
}
ENGLISH = {
    "Welcome headline": "Passbook is for\nthe stuff in your pocket.",
    "Welcome explanation": "Your boarding passes, tickets, store cards,\nand coupons. All in one place.",
    "Catalog explanation": "Import a pass from its issuer, or explore the classic collection below.",
    "Sample pass explanation": "This sample demonstrates the design and interactions. It cannot be used for travel, admission, or purchases.",
    "Sample coupon terms": "For demonstration only. No cash value. Not redeemable for goods or services.",
    "Wallet integration explanation": "Add issuer-signed passes to Apple Wallet for system-managed Lock Screen reminders and issuer updates.",
    "Local pass explanation": "Local passes stay in this app. The barcode encodes your text; acceptance depends on the recipient. Locally created passes cannot be added to Apple Wallet.",
    "About explanation": "An independent recreation inspired by iOS 6 Passbook. Tap a pass to open it; tap i to turn it over. Samples have no real-world value. Apple Wallet provides system Lock Screen reminders and issuer updates.",
    "Delete confirmation": "Delete this pass from this app? This does not remove it from Apple Wallet.",
    "Could not load passes": "Saved passes could not be read. The original file is preserved. Check device storage and reopen the app.",
    "Could not save passes": "Changes could not be saved. Check device storage and try again.",
    "Could not import pass": "This pass could not be imported. Choose a valid issuer-signed .pkpass file no larger than 20 MB.",
}
for language in ["en", "zh-Hans", "zh", "zh-Hant"]:
    directory = ROOT / f"{language}.lproj"
    directory.mkdir(parents=True, exist_ok=True)
    values = {key: (TEXT[key] if language != "en" else ENGLISH.get(key, key)) for key in TEXT}
    (directory / "Localizable.strings").write_text("\n".join(
        f"{json.dumps(key, ensure_ascii=False)} = {json.dumps(value, ensure_ascii=False)};"
        for key, value in values.items()) + "\n")
    (directory / "InfoPlist.strings").write_text('"CFBundleDisplayName" = "' +
        ("票据夹" if language != "en" else "Passbook") + '";\n')

info = {
    "CFBundleDocumentTypes": [{"CFBundleTypeName": "Wallet Pass", "CFBundleTypeRole": "Viewer",
        "LSHandlerRank": "Alternate", "LSItemContentTypes": ["com.apple.pkpass"]}],
    "LSSupportsOpeningDocumentsInPlace": True,
    "UTImportedTypeDeclarations": [{"UTTypeIdentifier": "com.apple.pkpass", "UTTypeDescription": "Wallet Pass",
        "UTTypeConformsTo": ["public.data"], "UTTypeTagSpecification": {
            "public.filename-extension": ["pkpass"], "public.mime-type": "application/vnd.apple.pkpass"}}],
}
(ROOT / "Info.plist").write_bytes(plistlib.dumps(info))
print(f"Generated {len(TEXT)} paired strings and document registration")
