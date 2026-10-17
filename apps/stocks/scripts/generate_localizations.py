#!/usr/bin/env python3
"""Generate matching English and Simplified Chinese resources."""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parent.parent / "StocksSix"
TEXT = {
    "Stocks": "股市", "Done": "完成", "Cancel": "取消", "Add Stock": "添加股票",
    "No Stocks": "没有自选股票", "Add Stocks Hint": "轻点左上角的 + 添加股票或指数。",
    "Reorder Hint": "按住股票行上下拖动以调整顺序。",
    "Price Change": "价格涨跌", "Percentage Change": "涨跌幅", "Market Cap": "市值",
    "Summary": "摘要", "Chart": "图表", "News": "新闻", "Open": "开盘",
    "High": "最高", "Low": "最低", "Volume": "成交量", "Previous Close": "昨收",
    "52W High": "52周最高", "52W Low": "52周最低", "Market Open": "交易中",
    "Market Closed": "已收盘", "Select a Stock": "选择一只股票",
    "Loading": "正在加载…", "Loading Chart": "正在加载图表…", "Loading News": "正在加载新闻…",
    "Updating": "正在更新…", "Unavailable": "暂不可用", "Retry": "重试",
    "No Chart Data": "暂无图表数据", "Chart Unavailable": "图表更新失败 · 轻点重试",
    "Quote Unavailable": "暂时无法获取行情", "News Unavailable": "暂时无法获取新闻",
    "No News": "暂无相关新闻", "Refresh Quotes": "刷新行情", "Manage Stocks": "管理自选股票",
    "Open Yahoo Finance": "在雅虎财经中查看", "Quotes May Be Delayed": "行情可能存在延迟",
    "Cached or Unavailable": "部分行情为缓存或暂不可用", "Demo Data": "演示数据",
    "Change Display Hint": "轻点切换价格涨跌、涨跌幅和市值。",
    "Chart Hint": "按住图表查看价格，双指拖动比较区间。上下轻扫可逐步查看数据。",
    "Show %@ Chart": "显示%@图表", "Chart for %@": "%@走势图", "%@, %@": "%@，%@",
    "Delete %@": "删除%@", "Move Up": "上移", "Move Down": "下移",
    "Missing Metrics": "— 表示数据源未提供此项数据。",
    "Data Attribution": "行情与新闻来源：Yahoo Finance",
    "Data Notice": "行情可能延迟；数据源不可用时保留上次行情及其时间。",
    "Local Watchlist Notice": "自选列表保存在此设备。",
    "Language Notice": "界面跟随系统或 App 语言，支持英文与简体中文。其他语言默认使用英文。",
    "Search Placeholder": "股票代码或公司名称", "Clear Search": "清除搜索", "Searching": "正在搜索…",
    "Search Hint": "输入公司、基金、指数名称或股票代码，例如 AAPL、苹果、000001.SS。",
    "No Results": "未找到匹配的股票", "Search Unavailable": "搜索暂不可用，请稍后再试。",
    "Local Search Notice": "在线搜索不可用，以上为本地匹配结果。", "Added": "已添加",
    "Open Article": "打开文章", "Share Article": "分享文章",
    "News Language Notice": "新闻保留来源的原始语言。", "Demo News": "演示新闻",
    "Demo News Notice": "以下为功能演示标题，非真实报道。",
    "Demo Headline 1": "探索公司的最新市场动态",
    "Demo Headline 2": "查看公司财报与关键业务指标",
    "Demo Headline 3": "了解全球主要指数的市场表现",
    "1d": "1天", "1w": "1周", "1m": "1月", "3m": "3月", "6m": "6月", "1y": "1年", "2y": "2年",
    "K": "千", "M": "百万", "B": "十亿", "T": "万亿",
    "^IXIC": "纳斯达克综合指数", "^GSPC": "标普500指数", "^DJI": "道琼斯工业平均指数",
    "AAPL": "苹果公司", "GOOG": "Alphabet 公司", "^FTSE": "富时100指数",
    "^GDAXI": "德国DAX指数", "^N225": "日经225指数", "MSFT": "微软公司",
    "NVDA": "英伟达公司", "AMZN": "亚马逊公司", "TSLA": "特斯拉公司",
    "META": "Meta 平台公司", "000001.SS": "上证综合指数", "0700.HK": "腾讯控股有限公司", "EURUSD=X": "欧元 / 美元",
}
ENGLISH = {
    "Data Attribution": "Quotes and news by Yahoo Finance",
    "Data Notice": "Quotes may be delayed. Last available quotes and their timestamps remain visible if the provider is unavailable.",
    "Local Watchlist Notice": "Your watchlist is stored on this device.",
    "Language Notice": "Follows your system or per-app language. English and Simplified Chinese are supported; other languages use English.",
    "Reorder Hint": "Touch and hold a stock row, then drag to reorder.",
    "Add Stocks Hint": "Tap + to add stocks or indices.",
    "Missing Metrics": "— means this metric was not supplied by the data provider.",
    "Change Display Hint": "Tap to cycle price change, percentage change, and market capitalization.",
    "Chart Hint": "Hold to inspect prices. Drag with two fingers to compare. Swipe up or down to step through data.",
    "Search Placeholder": "Symbol or company name",
    "Search Hint": "Enter a company, fund, index, or ticker symbol, such as AAPL or 000001.SS.",
    "Local Search Notice": "Online search is unavailable. Showing local matches.",
    "Search Unavailable": "Search is unavailable. Please try again later.",
    "News Language Notice": "News is shown in its original language.",
    "Demo News Notice": "Sample headlines for demonstration; these are not news reports.",
    "Demo Headline 1": "Explore the latest market updates for this company",
    "Demo Headline 2": "Review company earnings and key business figures",
    "Demo Headline 3": "Follow the performance of major global indices",
    "Cached or Unavailable": "Some quotes cached or unavailable",
    "Chart Unavailable": "Chart update failed · Tap to retry",
}
for language in ["en", "zh-Hans"]:
    folder = ROOT / f"{language}.lproj"
    folder.mkdir(parents=True, exist_ok=True)
    def quoted(s): return json.dumps(s, ensure_ascii=False)
    (folder / "Localizable.strings").write_text("\n".join(f"{quoted(key)} = {quoted(value if language == 'zh-Hans' else ENGLISH.get(key, key))};" for key, value in TEXT.items()) + "\n")
    (folder / "InfoPlist.strings").write_text('"CFBundleDisplayName" = "' + ("股市" if language == "zh-Hans" else "Stocks") + '";\n')
print(f"Generated {len(TEXT)} keys in both languages")
