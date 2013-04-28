/*
 * 对于已经打开的赛程数据页面，读取需要的数据，并发送到服务器保存
 */

// 获取当前URL信息，从中解析出需要的数据，包括：赛季、赛事、轮次
var url = $.url();
var season = url.param("sid");              // 赛季
var match = url.param("lid");               // 赛事
var phase = url.param("roundNum");          // 轮次

//alert(season + " " + match + " " + phase);
//alert($("table.dataSheet")[0].innerText);

var requestData = {
                        "season":       season,
                        "match":        match,
                        "phase":        phase,
                        "schedule":     $("table.dataSheet")[0].innerText
                  };

$.post('http://localhost:8080/save_schedule_data.php', requestData, null);



