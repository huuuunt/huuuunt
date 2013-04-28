<?php

/*
 * 用于判断指定联赛指定赛季指定轮次的赛程数据是否已经被更新
 * （比如，判断英超联赛2007赛季24轮次的赛程数据是否已经被更新）
 */

include 'variables.php';

// 允许跨域访问
header("Access-Control-Allow-Origin: *"); 

// 获取要检查的赛程信息
$match = $_GET["match"];
$season = $_GET["season"];
$phase = $_GET["phase"];

// 判断指定phase文件是否存在、更新日期是否是当天。
$filepath = $data_root . $season . "/" . $match . "/" . $phase;

if (file_exists($filepath)) {
    // 获取当前日期，格式 2007-12-12
    $date = getdate();
    $current_date = "$date[year]-$date[mon]-$date[mday]";
    // 获取指定数据文件的更新日期，格式 2007-12-12
    $mtime = getdate(filemtime($filepath));
    $modify_date = "$mtime[year]-$mtime[mon]-$mtime[mday]";
    
    if ($current_date == $modify_date) {
        echo "true";
        return;
    }
} 

echo "false";

?>

