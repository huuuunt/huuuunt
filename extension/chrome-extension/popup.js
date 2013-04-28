/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

// 根据输入参数（联赛ID、赛季、轮次总数）检查指定联赛在指定赛季还未处理的赛程，并打开这些赛程以便获取数据
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

// 展示各联赛各赛季信息，用于赛程获取操作
function getSchedule() {
    // 在此指定赛季
    start_season = 2013;
    end_season = 2013;
    // 访问服务器，读取待获取的赛事数据信息，并生成相应的label和button
    $.get("http://localhost:8080/get_schedule.php", {}, function(data){
        // data数据案例:
        // {"match":
        //    [
        //      {"match_id":"1","name":"%E8%8B%B1%E8%B6%85","type":"1","phases":"38","gooooal_id":"4","phases_ex":null},
        //      {"match_id":"19","name":"%E8%A5%BF%E4%B9%99","type":"1","phases":"42","gooooal_id":"31","phases_ex":null},
        //      {"match_id":"24","name":"%E5%BE%B7%E7%94%B2","type":"1","phases":"34","gooooal_id":"3","phases_ex":null},
        //      {"match_id":"39","name":"%E8%8D%B7%E4%B9%99","type":"1","phases":"34","gooooal_id":"113","phases_ex":"2009:20:38"},
        //      {"match_id":"40","name":"%E6%AF%94%E7%94%B2","type":"2","phases":"30","gooooal_id":"33","phases_ex":"2008:18:34"},
        //      {"match_id":"41","name":"%E6%AF%94%E4%B9%99","type":"2","phases":"34","gooooal_id":"78","phases_ex":"2009:19:38"}
        //    ]
        //  }
        var json = eval('(' + data + ')');
        //alert(json.match.length);
        var html_code = "";
        for (i=0; i<json.match.length; i++) {
            //alert(decodeURI(json.match[i].name));
            html_code += decodeURI(json.match[i].name);
            var phases = json.match[i].phases;
            var gooooal_id = json.match[i].gooooal_id;
            var phase_ex = json.match[i].phases_ex;
            if (phase_ex==null) {
                for (season=end_season; season>=start_season; season--) {
                    if (json.match[i].type == "1") {
                        html_code += "<input class=\"btn btn-success\" type=\"button\" value=\"" + season + "\" onclick=\"checkAndOpenSchedule("+gooooal_id+", "+ season+", "+phases+")\" />";
                    } else {
                        html_code += "<input class=\"btn btn-primary\" type=\"button\" value=\"" + season + "\" onclick=\"checkAndOpenSchedule("+gooooal_id+", "+ season+", "+phases+")\" />";
                    }
                }
            } else {
                // phase_ex数据结构，"赛季:球队数量:轮次"，如"2011:16:34;2008:16:30;2007:18:34"，
                var a_phase = phase_ex.split(";");
                var new_phases = phases;
                for (season=end_season; season>=start_season; season--) {
                    for (j=0; j<a_phase.length; j++) {
                        var tmp_season = Number(a_phase[j].split(":")[0]);
                        var tmp_phases = Number(a_phase[j].split(":")[2]);
                        if (season === tmp_season) {
                            new_phases = tmp_phases;
                        }
                    }
                    if (json.match[i].type == "1") {
                        html_code += "<input class=\"btn btn-success\" type=\"button\" value=\"" + season + "\" onclick=\"checkAndOpenSchedule("+gooooal_id+", "+ season+", "+phases+")\" />";
                    } else {
                        html_code += "<input class=\"btn btn-primary\" type=\"button\" value=\"" + season + "\" onclick=\"checkAndOpenSchedule("+gooooal_id+", "+ season+", "+phases+")\" />";
                    }
                }
            }

            if ((i+1)%5 == 0) {
                html_code += "<br/>";
            } else {
                html_code += "&nbsp &nbsp &nbsp";
            }
        }

        $('#match').html(html_code);
    })
}

// 获取近期刚比赛完的赛程赛果数据
// 通过cookie实现一次仅获取15个赛程赛果页面，下一次从上一次结束的地方开始
function getRecentFinishedSchedule(season, type) {
    // amount表示当前已经获取的赛程个数
    var amount = Number($.cookie('gooooal'));
    alert(amount);
    $.get("http://localhost:8080/get_recent_finished_schedule.php", {spec_season: season, season_type: type}, function(data){
        // data数据案例:
        // {"match":
        //    [
        //      {"match_id":"1","gooooal_match_id":"4","phases":[2,4,38]},
        //      {"match_id":"2","gooooal_match_id":"21","phases":[2,4,38]},
        //      {"match_id":"4","gooooal_match_id":"22","phases":[2,4,38]},
        //      {"match_id":"9","gooooal_match_id":"1","phases":[2,4,38]},
        //      {"match_id":"24","gooooal_match_id":"3","phases":[2,4,38]},
        //      {"match_id":"34","gooooal_match_id":"12","phases":[2,4,38]},
        //    ]
        //  }
        //alert(data);
        var json = eval('(' + data + ')');
        //alert(json.match.length);

        var start = amount; 
        var end = amount+30;   // 30表示可以一次打开获取的赛程个数
        var count_history = 0; // 用于计算已经获取的赛程个数
        var count_new = 0; // 用于计算正在获取的赛程个数
        for (i=0; i<json.match.length; i++) {
            //alert(json.match[i].phases.length);
            for (j=0; j<json.match[i].phases.length; j++) {
                // 从上一次获取完成的地方重新开始，如果还没到，就直接下一个。
                if (count_history < start) {
                    count_history++;
                    continue;
                }
                match = json.match[i].gooooal_match_id;
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
                    $.cookie('gooooal', start+count_new);
                    return;
                }
            } // for j
        } // for i
        $.cookie('gooooal', start+count_new);
        alert("赛程获取结束");
    });
}

// 检查近期赛事赛程是否获取完整，如果不完整，则补充完整。
function checkRecentFinishedSchedule(season, type) {
    $.get("http://localhost:8080/get_recent_finished_schedule.php", {spec_season: season, season_type: type}, function(data){
        // data数据案例:
        // {"match":
        //    [
        //      {"match_id":"1","gooooal_match_id":"4","phases":[2,4,38]},
        //      {"match_id":"2","gooooal_match_id":"21","phases":[2,4,38]},
        //      {"match_id":"4","gooooal_match_id":"22","phases":[2,4,38]},
        //      {"match_id":"9","gooooal_match_id":"1","phases":[2,4,38]},
        //      {"match_id":"24","gooooal_match_id":"3","phases":[2,4,38]},
        //      {"match_id":"34","gooooal_match_id":"12","phases":[2,4,38]},
        //    ]
        //  }
        alert(data);
        var json = eval('(' + data + ')');
        //alert(json.match.length);
        for (i=0; i<json.match.length; i++) {
            for (j=0; j<json.match[i].phases.length; j++) {
                match = json.match[i].gooooal_match_id;
                season = 2012;
                roundNum = json.match[i].phases[j];
                //alert(match + " " + season + " " + roundNum);
                $.get("http://localhost:8080/check_update_schedule.php", {match: match, phase: roundNum, season: season}, function(data){
                    alert(data);
                    if (data == "true") {
                        continue;
                    }
                    chrome.tabs.create(
                        {
                            'url': 'http://app.gooooal.com/resultschedule.do?lid=' + match + '&sid=' + season + '&roundNum=' + roundNum + '&lang=tr'
                        }
                    );
                });

            } // for j
        } // for i
    });
}


$(document).ready(function() {

    $('#schedule').click(function() {
        getSchedule();
    });

    $('#update_schedule_1').click(function() {
        getRecentFinishedSchedule(2012, 1);
    });

    $('#check_update_schedule_1').click(function() {
        checkRecentFinishedSchedule(2012, 1);
    });

    $('#update_schedule_2').click(function() {
        getRecentFinishedSchedule(2013, 2);
    });

    $('#check_update_schedule_2').click(function() {
        checkRecentFinishedSchedule(2013, 2);
    });

    $('#cookie_reset').click(function() {
        $.cookie('gooooal', 0);
    });

    // ============================================ //
    $('#match_id_034_30').click(function() {
        checkAndOpenSchedule(34, 2013, 30);
    });// 瑞典超
    $('#match_id_435_30').click(function() {
        checkAndOpenSchedule(435, 2013, 30);
    });// 瑞典甲
    $('#match_id_037_33').click(function() {
        checkAndOpenSchedule(37, 2013, 33);
    });// 芬超
    $('#match_id_441_27').click(function() {
        checkAndOpenSchedule(441, 2013, 27);
    });// 芬甲
    $('#match_id_035_30').click(function() {
        checkAndOpenSchedule(35, 2013, 30);
    });// 挪超
    $('#match_id_438_30').click(function() {
        checkAndOpenSchedule(438, 2013, 30);
    });// 挪甲
    $('#match_id_056_38').click(function() {
        checkAndOpenSchedule(56, 2013, 38);
    });// 巴西甲
    $('#match_id_564_38').click(function() {
        checkAndOpenSchedule(564, 2013, 38);
    });// 巴西乙
    $('#match_id_138_34').click(function() {
        checkAndOpenSchedule(138, 2013, 34);
    });// 日职联
    $('#match_id_533_42').click(function() {
        checkAndOpenSchedule(533, 2013, 42);
    });// 日职乙
    // ============================================ //
});

