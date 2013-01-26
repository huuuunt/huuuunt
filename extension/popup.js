/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

// 根据输入参数检查未处理的赛程并打开
function checkAndOpenSchedule(match, season, phases) {
    phases = Number(phases);
    match = Number(match);
    alert(phases + "," + season + "," + match);
    // 检查指定参数中未处理的赛程
    $.get("http://localhost:8080/check_schedule_data.php", {match: match, phases: phases, season: season}, function(data){
        var json = eval('(' + data + ')');
        if (json.schedule.length > 0) {
            alert(json.schedule.join('|'));
        } else {
            alert("no schedule!");
        }
        for (i=0; i<json.schedule.length; i++) {
            //alert(json.schedule[i]);
            chrome.tabs.create(
            {
                'url': 'http://app.gooooal.com/resultschedule.do?lid=' + match + '&sid=' + season + '&roundNum=' + json.schedule[i] + '&lang=tr'
            }
            );
        }
    });
}

function getHistorySchedule() {
        // 访问服务器，读取待获取的赛事数据信息，并生成相应的label和button
    $.get("http://localhost:8080/get_history_schedule.php", {}, function(data){
        // data数据案例:
        // {"match":
        //    [
        //      {"match_id":"1","name":"%E8%8B%B1%E8%B6%85","phases":"38","gooooal_id":"4","phases_ex":null},
        //      {"match_id":"19","name":"%E8%A5%BF%E4%B9%99","phases":"42","gooooal_id":"31","phases_ex":null},
        //      {"match_id":"24","name":"%E5%BE%B7%E7%94%B2","phases":"34","gooooal_id":"3","phases_ex":null},
        //      {"match_id":"39","name":"%E8%8D%B7%E4%B9%99","phases":"34","gooooal_id":"113","phases_ex":"2009:20:38"},
        //      {"match_id":"40","name":"%E6%AF%94%E7%94%B2","phases":"30","gooooal_id":"33","phases_ex":"2008:18:34"},
        //      {"match_id":"41","name":"%E6%AF%94%E4%B9%99","phases":"34","gooooal_id":"78","phases_ex":"2009:19:38"}
        //    ]
        //  }
        var json = eval('(' + data + ')');
        //alert(json.match.length);
        var html_code = "";
        for (i=0; i<json.match.length; i++) {
            //alert(decodeURI(json.match[i].name));
            html_code += "<label>" + decodeURI(json.match[i].name) + "</label> :";
            var phases = json.match[i].phases;
            var gooooal_id = json.match[i].gooooal_id;
            var phase_ex = json.match[i].phases_ex;
            if (phase_ex==null) {
                for (season=2012; season>=2007; season--) {
                    html_code += "<input type=\"button\" value=\"" + season + "\" onclick=\"checkAndOpenSchedule("+gooooal_id+", "+ season+", "+phases+")\" />";
                }
            } else {
                // phase_ex数据结构，"赛季:球队数量:轮次"，如"2011:16:34;2008:16:30;2007:18:34"，
                var a_phase = phase_ex.split(";");
                var new_phases = phases;
                for (season=2012; season>=2007; season--) {
                    for (j=0; j<a_phase.length; j++) {
                        var tmp_season = Number(a_phase[j].split(":")[0]);
                        var tmp_phases = Number(a_phase[j].split(":")[2]);
                        if (season === tmp_season) {
                            new_phases = tmp_phases;
                        }
                    }
                    html_code += "<input type=\"button\" value=\"" + season + "\" onclick=\"checkAndOpenSchedule("+gooooal_id+", "+ season+", "+new_phases+")\" />";
                }
            }

            if (i%2 != 0) {
                html_code += "<br/>";
            } else {
                html_code += "&nbsp &nbsp &nbsp";
            }
        }

        $('#match').html(html_code);
    })
}

// 实现一次获取指定数量的赛程，下一次从上一次结束的地方开始
function getNewSchedule() {
    var amount = Number($.cookie('gooooal'));
    alert(amount);
    $.get("http://localhost:8080/get_new_schedule.php", {}, function(data){
        // data数据案例:
        // {"match":
        //    [
        //      {"match_id":"1","name":"%E8%8B%B1%E8%B6%85","phases":[2,4,38]},
        //      {"match_id":"19","name":"%E8%A5%BF%E4%B9%99","phases":[2,4,38]},
        //      {"match_id":"24","name":"%E5%BE%B7%E7%94%B2","phases":[2,4,38]},
        //      {"match_id":"39","name":"%E8%8D%B7%E4%B9%99","phases":[2,4,38]},
        //      {"match_id":"40","name":"%E6%AF%94%E7%94%B2","phases":[2,4,38]},
        //      {"match_id":"41","name":"%E6%AF%94%E4%B9%99","phases":[2,4,38]},
        //    ]
        //  }
        //alert(data);
        var json = eval('(' + data + ')');
        //alert(json.match.length);
        var start = amount; 
        var end = amount+15;
        var count_history = 0   // 用于计算已获取的赛程情况
        var count_new = 0 // 用于计算正在获取的赛程情况
        for (i=0; i<json.match.length; i++) {
            //alert(json.match[i].phases.length);
            for (j=0; j<json.match[i].phases.length; j++) {
                if (count_history < start) {
                    count_history++;
                    continue;
                }
                match = json.match[i].match_id;
                season = 2012;
                roundNum = json.match[i].phases[j];
                //alert(match + " " + season + " " + roundNum);
                chrome.tabs.create(
                {
                    'url': 'http://app.gooooal.com/resultschedule.do?lid=' + match + '&sid=' + season + '&roundNum=' + roundNum + '&lang=tr'
                }
                );
                count_new++;
                if ( (start+count_new) >= end ) {
                    $.cookie('gooooal', end);
                    return;
                }
            } // for j
        } // for i
        $.cookie('gooooal', start+count_new);
    });
}

function writeUpdateScheduleLog() {
    $.get("http://localhost:8080/save_get_new_schedule_log.php", {}, null);
}

$(document).ready(function() {

    $('#new_season_schedule').click(function() {
        
    });

    $('#update_schedule').click(function() {
        getNewSchedule();
    });

    $('#cookie_reset').click(function() {
        $.cookie('gooooal', 0);
    });

    $('#update_schedule_log').click(function() {
        writeUpdateScheduleLog();
    });
});

