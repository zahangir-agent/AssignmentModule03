<?php
function ConvertString($orginalstring){
    $lowercase = strtolower($orginalstring);

    $newText = str_replace("brown","red", $lowercase);
    echo 'Lowercase  string:'.$lowercase.PHP_EOL;
     echo 'Converted string:'.$newText;
}

$text="The quick brown fox jumps over the lazy dog.";
ConvertString($text);
