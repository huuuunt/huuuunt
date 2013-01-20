<?php

# 允许跨域访问
header("Access-Control-Allow-Origin: *"); 

# 获取要检查的赛程信息
$match = $_GET["match"];
$season = $_GET["season"];
$phases = $_GET["phases"];

$phases = intval($phases);

// $arr存放指定赛事、赛季中已经保存的赛程文件
$arr = array();
// $schedule存放指定赛事、赛季中未读取的赛程轮次
$schedule = array();

$filepath = "/var/www/gooooal/" . $season . "/" . $match . "/";

if (file_exists($filepath)) {
	//echo "$filepath exists.<br/>";
	if (is_dir($filepath)) {
		//echo "$filepath is dir.<br/>";
		if ($dh = opendir($filepath)) {
			while (($file = readdir($dh))!==false) {
				if ($file!="." && $file!="..") {
					//echo "$file <br/>";	//$file is string.
					$arr[] = intval($file);
				}
			}
		}
	}

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

