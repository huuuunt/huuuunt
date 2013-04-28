<?php

/*
 * 仅用在历史赛程数据采集中
 * 用于判断指定联赛指定赛季的赛程数据还剩下哪些赛程未获取数据
 * （比如，判断2007赛季英超联赛的38个轮次的赛程数据是否已经都存在了）
 * 通过保存的赛程文件记录来判断
 */

include 'variables.php';

// 允许跨域访问
header("Access-Control-Allow-Origin: *"); 

// 获取要检查的赛程信息
$match = $_GET["match"];
$season = $_GET["season"];
$phases = $_GET["phases"];

$phases = intval($phases);

// $arr存放指定赛事、赛季中已经保存的赛程文件
$arr = array();
// $schedule存放指定赛事、赛季中未读取的赛程轮次
$schedule = array();

$filepath = $data_root . $season . "/" . $match . "/";

if (file_exists($filepath)) {
    //echo "$filepath exists.<br/>";
    if (is_dir($filepath)) {
        //echo "$filepath is dir.<br/>";
        if ($dh = opendir($filepath)) {
        // 读取赛程文件列表信息
            while (($file = readdir($dh))!==false) {
                if ($file!="." && $file!="..") {
                    //echo "$file <br/>";	//$file is string.
                    $arr[] = intval($file);
                }
            }
        }
    }

        // 判断哪些赛程数据还未获取，并存放到$schdule数组中
    $i=1;
    for ($i=1; $i<=$phases; $i++) {
        if (array_search($i, $arr) === false) {
            //echo "$i not exist <br/>";
            $schedule[] = $i;
        }
    }
} else {
	//echo "$filepath not exists.<br/>";
}

//sort($arr);
//print_r($arr);

$json = array ("schedule" => $schedule);

echo json_encode($json);

?>

