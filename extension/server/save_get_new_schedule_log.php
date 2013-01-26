<?php

# 允许跨域访问
header("Access-Control-Allow-Origin: *");

$conn = mysql_connect("localhost","root","mysql");
if (!$conn) {
	die('Could not connect mysql: ' . mysql_error());
}

mysql_select_db("huuuunt",$conn);

#$sql = "SELECT matchno, phase FROM cms_data_schedule where matchdt < curdate() and goal1 is null and goal2 is null and (season=2012 or season=2013) order by matchno,matchdt;";
$sql = "SELECT c.matchno, m.gooooal_match_id_1, c.phase FROM huuuunt.cms_data_schedule c
inner join huuuunt.cms_data_matches m
where c.matchdt < date_add(curdate(), interval 5 day) and c.goal1 is null and c.goal2 is null and (c.season=2012 or c.season=2013) and c.matchno=m.match_id
order by c.matchno,c.matchdt
";

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

/*
foreach ($match_info as $value) {
	echo $value["match_id"] . ":" . $value["name"] . "," . $value["phases"] . "," . $value["gooooal_id"] . "," . $value["phases_ex"];
	echo "<br/>";
}
*/

mysql_close($conn);

//$json = array ("match" => $match_info);

//echo json_encode($json);

$datalogfile = "/home/liuf/github/huuuunt/extension/server/gooooal/schedule.log";
$logFileHandle = fopen($datalogfile, "w+");
fwrite($logFileHandle, json_encode($match_info));
fclose($logFileHandle);

?>

