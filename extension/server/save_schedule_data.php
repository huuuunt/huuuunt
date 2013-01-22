<?php

# 允许跨域访问
header("Access-Control-Allow-Origin: *"); 

# 获取足球赛程数据
$schedule = $_POST["schedule"];
$match = $_POST["match"];
$season = $_POST["season"];
$phase = $_POST["phase"];

/*
$logFileHandle = fopen("/usr/share/nginx/www/visitLog.log", "w+");
fwrite($logFileHandle, $schedule);
fclose($logFileHandle);
*/

//$datafile = "/home/liuf/github/huuuunt/app/data/schedule/gooooal/2007/1/" . $phase;
$datafile = "/home/liuf/github/huuuunt/app/data/schedule/gooooal/" . $season . "/" . $match . "/" . $phase;
$logFileHandle = fopen($datafile, "w+");
fwrite($logFileHandle, $schedule);
fclose($logFileHandle);

?>

