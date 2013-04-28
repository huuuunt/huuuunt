<?php

$date = getdate();

$d1 = "$date[year]-$date[mon]-$date[mday]";

$file = "/home/liuf/github/huuuunt/app/data/schedule/gooooal/2012/1/32";

if (file_exists($file)) {
    echo "$file is exist.<br/>";
} else {
    echo "$file is not exist.";
}

$mtime = getdate(filemtime($file));
$d2 = "$mtime[year]-$mtime[mon]-$mtime[mday]";

if ($d1 == $d2) {
    echo "date is same";
}

?>
