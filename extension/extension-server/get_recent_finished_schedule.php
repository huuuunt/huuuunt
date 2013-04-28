<?php

/*
 * 读取近期刚结束的赛程赛果数据
 * 两种联赛类型（当年度/跨年度）需要区分处理，根据输入的参数来区分。
*/

include 'variables.php';

# 允许跨域访问
header("Access-Control-Allow-Origin: *");

$season_type = $_GET["season_type"];
$spec_season = $_GET["spec_season"];

// 两个参数都不能为空，并且spec_season必须是1或者2
if ($season_type=="" || $spec_season=="") {
    return;
} else {
    if ($season_type=="1" || $season_type=="2") {
        // no error
    } else {
        return;
    }
}

$conn = mysql_connect("localhost","root","mysql");
if (!$conn) {
	die('Could not connect mysql: ' . mysql_error());
}

mysql_select_db("huuuunt",$conn);

$sql = "SELECT s.matchno, m.gooooal_match_id_1, s.phase FROM huuuunt.schedule s
        inner join huuuunt.matches m
        where s.matchdt < date_add(curdate(), interval 5 day) and s.goal1 is null and s.goal2 is null
            and s.season=" . $spec_season . " and s.matchno=m.match_id and 
            m.season_type=" . $season_type ."  
        order by s.matchno,s.matchdt";

$match_info = array();
$tmp_match_info = array();

mysql_query("set names utf8");
$result = mysql_query($sql, $conn);
while ($row = mysql_fetch_row($result)) {
    $tmp_match_info[$row[0]."-".$row[1]][] = $row[2];
	//echo $row[0].",".$row[1];
	//echo "<br/>";
}

//$match_info = array_uniqure($match_info);

foreach($tmp_match_info as $key => $value) {
    //print_r($value);
    //print_r(array_unique($value));
    $tmp = array_unique($value);
    $tmp_match_info[$key] = array();
    foreach($tmp as $val) {
        $tmp_match_info[$key][] = $val;
        //$match_info[] = array( "matchno" => $key, "phases" => $val );
    }
}

foreach($tmp_match_info as $key => $value) {
    list($match_id, $gooooal_match_id) = split('-', $key);
    $match_info[] = array( "match_id" => $match_id, 'gooooal_match_id' => $gooooal_match_id, "phases" => $value );
}

mysql_close($conn);

// 将待获取赛程的联赛/轮次数据写入文件，便于数据分析导入程序理解应该对哪些数据进行处理。

$datalogfile = $data_root . "schedule.log";
$logFileHandle = fopen($datalogfile, "w+");
fwrite($logFileHandle, json_encode($match_info));
fclose($logFileHandle);


// 返回待获取赛程的联赛/轮次数据
$json = array ("match" => $match_info);
echo json_encode($json);

?>

