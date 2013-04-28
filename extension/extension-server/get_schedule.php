<?php

/*
 * 获取纳入统计范围的联赛信息，用于后续获取各联赛指定赛季的赛程数据
 */

include 'variables.php';

# 允许跨域访问
header("Access-Control-Allow-Origin: *"); 

$conn = mysql_connect("localhost","root","mysql");
if (!$conn) {
	die('Could not connect mysql: ' . mysql_error());
}

mysql_select_db("huuuunt",$conn);

$sql = "SELECT match_id,name_cn,season_type,phases,gooooal_match_id_1,gooooal_match_id_2,teams,phases_ex FROM matches c where gooooal_match_id_1<>0 order by match_id;";

$match_info = array();

mysql_query("set names utf8");
$result = mysql_query($sql, $conn);
while ($row = mysql_fetch_row($result)) {
	$match_info[] = array ( "match_id"=>$row[0], "name"=>urlencode($row[1]), "type"=>$row[2], "phases"=>$row[3], "gooooal_id"=>$row[4], "phases_ex"=>$row[7] );
	//echo $row[0].",".$row[1];
	//echo "<br/>";
}

/*
foreach ($match_info as $value) {
	echo $value["match_id"] . ":" . $value["name"] . "," . $value["phases"] . "," . $value["gooooal_id"] . "," . $value["phases_ex"];
	echo "<br/>";
}
*/

mysql_close($conn);

$json = array ("match" => $match_info);

echo json_encode($json);

?>

