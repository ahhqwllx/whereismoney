import Foundation

/// ECharts HTML 模板 —— 内嵌 ECharts CDN，支持三种图表类型
/// 配色与 App 深色主题一致，支持 tooltip、十字线、dataZoom 缩放
enum EChartsHTML {
    static let template = """
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<script src="https://cdn.jsdelivr.net/npm/echarts@5.5.0/dist/echarts.min.js"></script>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body, html { background: transparent; width: 100%; height: 100%; overflow: hidden; }
  #chart { width: 100%; height: 100%; }
</style>
</head>
<body>
<div id="chart"></div>
<script>
const ASSET_COLORS = ["#60a5fa","#a78bfa","#34d399","#fbbf24","#f472b6","#22d3ee","#fb923c","#818cf8","#94a3b8"];
const LIAB_COLORS = ["#f87171","#ef4444","#fb923c","#f59e0b","#a78bfa"];
const TEXT_DIM = "#8b98a5";
const BORDER = "#2a333d";

let chart = echarts.init(document.getElementById('chart'));
chart.setOption({ backgroundColor: 'transparent' });

// 是否全屏模式（影响边距和 dataZoom 显示比例）
let isFullscreen = false;

// 监听窗口大小变化
window.addEventListener('resize', () => chart.resize());

function renderChart(type, data, fullscreen) {
    isFullscreen = !!fullscreen;
    if (type === 'netAsset') renderNetAsset(data);
    else if (type === 'assetStack') renderStack(data, 'asset');
    else if (type === 'liabStack') renderStack(data, 'liab');
}

// 计算默认显示范围：非全屏显示最近 40%，全屏显示全部
function defaultRange(count) {
    if (isFullscreen || count <= 8) return [0, 100];
    let showCount = Math.max(5, Math.ceil(count * 0.4));
    let start = Math.max(0, ((count - showCount) / count) * 100);
    return [start, 100];
}

// 净资产趋势 & 环比
function renderNetAsset(data) {
    const changes = data.changes.map(v => v === null ? null : v);
    const range = defaultRange(data.dates.length);
    chart.setOption({
        backgroundColor: 'transparent',
        tooltip: {
            trigger: 'axis',
            axisPointer: { type: 'cross' },
            backgroundColor: '#1a2027',
            borderColor: '#2a333d',
            textStyle: { color: '#e6edf3' },
            formatter: function(params) {
                let s = params[0].axisValue + '<br/>';
                params.forEach(p => {
                    let val = p.value;
                    if (val == null || val === '-') return;
                    let sign = val >= 0 ? '+' : '';
                    s += p.marker + p.seriesName + ': ' + sign + formatMoney(val) + '<br/>';
                });
                return s;
            }
        },
        legend: { data: ['净资产', '环比变化'], textStyle: { color: TEXT_DIM }, top: 0, itemWidth: 12, itemHeight: 8 },
        grid: { left: 48, right: 38, top: 30, bottom: 45 },
        xAxis: {
            type: 'category', data: data.dates,
            axisLabel: { color: TEXT_DIM, fontSize: 10 },
            axisLine: { lineStyle: { color: BORDER } }
        },
        yAxis: [
            {
                type: 'value', name: '',
                axisLabel: { color: TEXT_DIM, fontSize: 10, formatter: v => (v/10000).toFixed(0) + '万' },
                splitLine: { lineStyle: { color: BORDER } },
                axisLine: { show: false }
            },
            {
                type: 'value', name: '',
                axisLabel: { color: TEXT_DIM, fontSize: 10, formatter: v => (v/1000).toFixed(0) + 'k' },
                splitLine: { show: false },
                axisLine: { show: false }
            }
        ],
        dataZoom: [
            { type: 'inside', start: range[0], end: range[1] },
            { type: 'slider', start: range[0], end: range[1], height: 18, bottom: 8, borderColor: BORDER, fillerColor: 'rgba(74,222,128,0.15)', handleStyle: { color: '#4ade80' }, textStyle: { color: TEXT_DIM, fontSize: 9 } }
        ],
        series: [
            {
                name: '净资产', type: 'line', smooth: true, symbol: 'circle', symbolSize: 6,
                data: data.net,
                lineStyle: { width: 3, color: '#4ade80' },
                itemStyle: { color: '#4ade80' },
                areaStyle: { color: new echarts.graphic.LinearGradient(0,0,0,1,[{offset:0,color:'rgba(74,222,128,0.25)'},{offset:1,color:'rgba(74,222,128,0)'}]) }
            },
            {
                name: '环比变化', type: 'bar', yAxisIndex: 1,
                data: changes.map(v => ({
                    value: v,
                    itemStyle: { color: v == null ? 'transparent' : (v >= 0 ? 'rgba(34,197,94,0.6)' : 'rgba(248,113,113,0.6)') }
                }))
            }
        ]
    }, true);
}

// 资产/负债堆叠图
function renderStack(data, kind) {
    const names = kind === 'asset' ? data.assetNames : data.liabNames;
    const allValues = kind === 'asset' ? data.assetValues : data.liabValues;
    const colors = kind === 'asset' ? ASSET_COLORS : LIAB_COLORS;
    const range = defaultRange(data.dates.length);

    const series = names.map((name, i) => ({
        name: name, type: 'line', stack: 'total', smooth: true, symbol: 'none',
        areaStyle: { opacity: 0.85 },
        lineStyle: { width: 0 },
        data: allValues[i],
        itemStyle: { color: colors[i % colors.length] }
    }));

    chart.setOption({
        backgroundColor: 'transparent',
        tooltip: {
            trigger: 'axis',
            axisPointer: { type: 'cross' },
            backgroundColor: '#1a2027',
            borderColor: '#2a333d',
            textStyle: { color: '#e6edf3' },
            formatter: function(params) {
                let s = params[0].axisValue + '<br/>';
                let total = 0;
                params.forEach(p => {
                    s += p.marker + p.seriesName + ': ' + formatMoney(p.value) + '<br/>';
                    total += p.value;
                });
                s += '<b>合计: ' + formatMoney(total) + '</b>';
                return s;
            }
        },
        legend: { data: names, textStyle: { color: TEXT_DIM, fontSize: 10 }, top: 0, type: 'scroll', itemWidth: 10, itemHeight: 7 },
        grid: { left: 48, right: 20, top: 45, bottom: 45 },
        xAxis: {
            type: 'category', data: data.dates,
            axisLabel: { color: TEXT_DIM, fontSize: 10 },
            axisLine: { lineStyle: { color: BORDER } }
        },
        yAxis: {
            type: 'value',
            axisLabel: { color: TEXT_DIM, fontSize: 10, formatter: v => (v/10000).toFixed(0) + '万' },
            splitLine: { lineStyle: { color: BORDER } },
            axisLine: { show: false }
        },
        dataZoom: [
            { type: 'inside', start: range[0], end: range[1] },
            { type: 'slider', start: range[0], end: range[1], height: 18, bottom: 8, borderColor: BORDER, fillerColor: 'rgba(96,165,250,0.15)', handleStyle: { color: '#60a5fa' }, textStyle: { color: TEXT_DIM, fontSize: 9 } }
        ],
        series: series
    }, true);
}

function formatMoney(v) {
    if (v == null) return '-';
    let sign = v < 0 ? '-' : '';
    return sign + '\\u00A5' + Math.abs(v).toLocaleString('zh-CN', {maximumFractionDigits: 0});
}
</script>
</body>
</html>
"""
}
