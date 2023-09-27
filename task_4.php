<?php
function averageGrades($studentGrades) {
   
    foreach ($studentGrades as $student => $grades) {
        $total = array_sum($grades);
        $count = count($grades);
        $average = $total / $count;
        $result[$student] = $average;
    }

    print_r($result) ;
}

$studentGrades = array(
    "Student A" => array("Math" => 75, "English" => 88, "Science" => 98),
    "Student B" => array("Math" => 88, "English" => 95, "Science" => 90),
    "Student C" => array("Math" => 75, "English" => 70, "Science" => 68)
);
$averageGrades = averageGrades($studentGrades);

