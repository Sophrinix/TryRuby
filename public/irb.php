<?php

$line = $_GET["cmd"];

// $descriptorspec = array(
//    0 => array("pipe", "r"),  // stdin is a pipe that the child will read from
//    1 => array("pipe", "w"),  // stdout is a pipe that the child will write to
//    2 => array("pipe", "w") // stderr is a file to write to
// );

$rcmd['"Jimmy"'] = '=> "Jimmy"';
$rcmd['"Jimmy".reverse'] = '=> "ymmiJ"';
$rcmd['"Jimmy".length'] = '=> 5';
$rcmd['"Jimmy" * 5'] = '=> "JimmyJimmyJimmyJimmyJimmy"';
$rcmd['40.reverse'] = "= NoMethodError: undefined method `reverse' for 40:Fixnum =";

if (array_key_exists($line, $rcmd)) {
  echo $rcmd[$line];
} else {
  switch ($line) {
  case "class":
    echo "..";
  case "alert":
    echo "\033[1;JSmalert('hello')\033[m";
  default:
    echo "=> " . eval("return " . $line . ";");
  }
}

// $cwd = '/tmp';
// $env = array('some_option' => 'aeiou');
// 
// $process = proc_open('irb', $descriptorspec, $pipes, $cwd, $env);
// 
// if (is_resource($process)) {
//     // $pipes now looks like this:
//     // 0 => writeable handle connected to child stdin
//     // 1 => readable handle connected to child stdout
//     // Any error output will be appended to /tmp/error-output.txt
// 
//     fwrite($pipes[0], $script);
//     fclose($pipes[0]);
// 
//     echo stream_get_contents($pipes[1]);
//     fclose($pipes[1]);
// 
//     // It is important that you close any pipes before calling
//     // proc_close in order to avoid a deadlock
//     $return_value = proc_close($process);
// }

?>