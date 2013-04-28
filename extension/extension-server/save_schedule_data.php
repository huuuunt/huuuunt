<?php

/*
 * 保存指定联赛指定赛季指定赛程的数据，到指定目录文件
 */

include "variables.php";

# 允许跨域访问
header("Access-Control-Allow-Origin: *"); 

# 获取足球赛程数据
$schedule = $_POST["schedule"];
$match = $_POST["match"];
$season = $_POST["season"];
$phase = $_POST["phase"];

// /home/liuf/github/huuuunt/app/data/schedule/gooooal/2007/1/38  2007赛季英超联赛第38轮次赛程数据文件
$datafile = $data_root . $season . "/" . $match . "/" . $phase;
$dataFileHandle = fopen($datafile, "w+");
fwrite($dataFileHandle, $schedule);
fclose($dataFileHandle);

?>

