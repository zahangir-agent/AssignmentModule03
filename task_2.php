<?php
$numbers = [1, 2, 3, 4, 5,6,7,8,9,10];
function oddnumber($oddnumber){
foreach($oddnumber as $getoddnumber){
if ($getoddnumber%2!==0){
echo $getoddnumber.PHP_EOL;
    }
  }
}
oddnumber($numbers);