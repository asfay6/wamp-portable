@ECHO OFF
SETLOCAL EnableDelayedExpansion

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::                                                                                ::
::  Wamp Portable                                                                 ::
::                                                                                ::
::  A DOS Batch script to make WampServer portable.                               ::
::                                                                                ::
::  Copyright (C) 2012-2013 Cr@zy <webmaster@crazyws.fr>                          ::
::                                                                                ::
::  Wamp-Portable is free software; you can redistribute it and/or modify         ::
::  it under the terms of the GNU Lesser General Public License as published by   ::
::  the Free Software Foundation, either version 3 of the License, or             ::
::  (at your option) any later version.                                           ::
::                                                                                ::
::  Wamp-Portable is distributed in the hope that it will be useful,              ::
::  but WITHOUT ANY WARRANTY; without even the implied warranty of                ::
::  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the                  ::
::  GNU Lesser General Public License for more details.                           ::
::                                                                                ::
::  You should have received a copy of the GNU Lesser General Public License      ::
::  along with this program. If not, see http://www.gnu.org/licenses/.            ::
::                                                                                ::
::  Related post: http://goo.gl/g0rWG                                             ::
::  Usage: Just launch wamp-portable.bat in the same folder as wampmanager.exe    ::
::                                                                                ::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

CLS
TITLE Wamp Portable v1.6

ECHO.
ECHO.
ECHO    #########################################################################
ECHO    #                                                                       #
ECHO    #   @   @ @@@@@ @   @ @@@@@ @@@@@ @@@@@ @@@@@ @@@@@ @@@@@ @     @@@@@   #
ECHO    #   @   @ @   @ @@ @@ @   @ @   @ @   @   @   @   @ @   @ @     @       #
ECHO    #   @   @ @@@@@ @ @ @ @@@@@ @   @ @@@@@   @   @@@@@ @@@@@ @     @@@@    #
ECHO    #    @@@  @   @ @   @ @     @   @ @  @    @   @   @ @   @ @     @       #
ECHO    #    @ @  @   @ @   @ @     @@@@@ @   @   @   @   @ @@@@@ @@@@@ @@@@@   #
ECHO    #                                                                       #
ECHO    #   Author : Cr@zy                               Date    : 09/25/2013   #
ECHO    #   Email  : webmaster@crazyws.fr                Version : 1.6          #
ECHO    #                                                                       #
ECHO    #########################################################################

:: Wamp launcher
SET wampLauncher=%TEMP%\wampLauncher.vbs
SET wampLauncherScript=%TEMP%\wampLauncher.bat
SET wampmanagerDaemon=%~dp0wampmanager.exe

:: Get the latest version of PHP on Wamp
FOR /R bin\php %%v IN (php.*exe) DO (
    SET PHP=%%v
)

:: Run PHP
%PHP% -n -d output_buffering=1 -f "%~f0"
ENDLOCAL
EXIT /b

:: wampserver-portable PHP script
<?php

while(@ob_end_clean());

////////////////////////////////////////////////
// Properties
////////////////////////////////////////////////

$timezone = 'Europe/Paris';
$enableLogs = true;
$autoLaunch = false;
$purgeWampLogs = false;
$maxBackups = 10;
$verbose = 0;

////////////////////////////////////////////////
// No edits necessary beyond this line
////////////////////////////////////////////////

date_default_timezone_set($timezone);

$scriptName = basename(__FILE__);
$wampConfigPath = getcwd() . '\\wampmanager.conf';
$wampIniPath = getcwd() . '\\wampmanager.ini';
$wampTplPath = getcwd() . '\\wampmanager.tpl';
$wampLogsPath = getcwd() . '\\logs\\';
$rootBackupPath = getcwd() . '\\backups\\';
$backupsPath = $rootBackupPath . date('YmdHis');
$logsPath = getcwd() . '\\wamp-portable.log';
$tmpStdout = getcwd() . '\\wamp-portable.tmp';

if ($enableLogs) file_put_contents($logsPath, "@@@\n@@@ START WAMP-PORTABLE " . date('YmdHis') . "\n@@@", FILE_APPEND);

function echoListener($str) {
    global $logsPath, $enableLogs;
    if ($enableLogs) {
        file_put_contents($logsPath, $str, FILE_APPEND);
    }
    echo $str;
}

function startWith($string, $search) {
    $length = strlen($search);
    return (substr($string, 0, $length) === $search);
}

function endWith($string, $search) {
    $length = strlen($search);
    $start  = $length * -1;
    return (substr($string, $start) === $search);
}

function exitApp() {
    echoListener("\n\An error occurred during the operation, exit...");
    echoListener("\n");
    exit();
}

function logInfo($str, $status, $values=array(), $withKey=true, $withValue=true, $customError=false) {
    global $verbose;
    $count = strlen($str);
    $dots = "";
    for ($i=$count; $i<=50; $i++) {
        $dots .= ".";
    }
    if ($verbose >= 1) {
        echoListener(logTitle($str . " " . $dots . " " . ($status ? "OK" : ($customError === false ? "KO" : $customError))));
        if (!empty($values) && is_array($values)) {
            foreach ($values as $key => $value) {
                $count = strlen($key);
                $spaces = "";
                for ($i=$count; $i<=7; $i++) {
                    $spaces .= " ";
                }
                echoListener("\n" . ($withKey ? $key : "") . ($withKey && $withValue ? $spaces . " : " : "") . ($withValue ? $value : ""));
            }
        }
    } else {
        echoListener("\n" . $str . " " . $dots . " " . ($status ? "OK" : ($customError === false ? "KO" : $customError)));
    }
    
    if (!$status && $customError === false) {
        exitApp();
    }
}

function logTitle($title) {
    $logTitle = "\n\n\n\n======================================================================\n";
    $logTitle .= $title;
    $logTitle .= "\n======================================================================";
    return $logTitle;
}

function execCommand($cmds, $echoStdout=true) {
    global $verbose, $tmpStdout;
    $logs = array();
    $cmds = is_array($cmds) ? $cmds : array($cmds);
    $stdout = " >\"" . $tmpStdout . "\" 2>&1";
    foreach($cmds as $cmd) {
        $log = "";
        if ($verbose >= 1) echoListener("\n> " . $cmd);
        `$cmd$stdout`;
        if (file_exists($tmpStdout)) {
            $lines = file($tmpStdout, FILE_IGNORE_NEW_LINES);
            foreach ($lines as $line) {
                $line = trim($line);
                if (!empty($line)) {
                    $log .= $line . "\n";
                    if ($verbose == 2 && $echoStdout) {
                        echoListener("\n" . $line);
                    }
                }
            }
            if (!empty($log)) {
                $logs[] = $log;
            }
            @unlink($tmpStdout);
        }
    }
    return $logs;
}

function versionsAppList($dir, $substr, $bins) {
    $appArr = array();
    if (is_dir($dir) && $appDirHandle = opendir($dir)) {
        while (false !== ($appDirName = readdir($appDirHandle))) {
            $appPath = getcwd() . "\\" . str_replace("/", "\\", $dir) . "\\" . $appDirName;
            if ($appDirName != '.' && $appDirName != '..' && is_dir($appPath) ) {
                $appVersion = substr($appDirName, $substr);
                foreach ($bins as $bin) {
                    $appBin = str_replace("/", "\\", $bin);
                    if (is_file($appPath . '\\' . $appBin)) {
                        $appArr[$appVersion] = array(
                            'path'  =>  $appPath,
                            'bin'   =>  $appBin
                        );
                    }
                }
            }
        }
        ksort($appArr, SORT_NUMERIC);
    }
    return $appArr;
}

function versionsAppPaths($list, $type) {
    $paths = array();
    foreach ($list as $versions => $value) {
        if (count(array_keys($paths, $type . ';' . $value['path'])) == 0) {
            $paths[] = $type . ';' . $value['path'];
        }
    }
    return $paths;
}

function foundFiles($path, $toFound) {
    $files = array();
    if ($handle = opendir($path)) {
        while (false !== ($file = readdir($handle))) {
            if ($file != "." && $file != ".." && is_file($path . '\\' . $file)) {
                foreach($toFound as $elt) {
                    if (endWith($file, $elt) || empty($elt)) {
                        $files[] = $path . '\\' . $file;
                    }
                }
            } elseif ($file != "." && $file != ".." && is_dir($path . '\\' . $file)) {
                $tmpFiles = foundFiles($path . '\\' . $file, $toFound);
                foreach($tmpFiles as $tmpFile) {
                    $files[] = $tmpFile;
                }
            }
        }
    }
    return $files;
}

function writeToFile($file, $string) {
    $handle = fopen($file, 'w');
    fwrite($handle, $string);
    fclose($handle);
}

function getAltPath($path) {
    $pathAlt[] = ucfirst($path);
    $pathAlt[] = str_replace('/', '\\', ucfirst($path));
    $pathAlt[] = lcfirst($path);
    $pathAlt[] = str_replace('/', '\\', lcfirst($path));
    return $pathAlt;
}

function replaceWithNewPath($oldPath, $newPath, $filePath) {
    $fileContent = file_get_contents($filePath);
    $oldPathAlt = getAltPath($oldPath);
    $newPathAlt = getAltPath($newPath);
    $count = 0;
    foreach($oldPathAlt as $key => $rpcPath) {
        if (preg_match("#" . str_replace('\\', '\\\\', $rpcPath) . "#", $fileContent)) {
            if ($key == 0 || $key == 2) {
                $fileContent = str_replace($rpcPath, $newPathAlt[0], $fileContent, $countRpc);
                $count += $countRpc;
            } else {
                $fileContent = str_replace($rpcPath, $newPathAlt[1], $fileContent);
                $count += $countRpc;
            }
        }
    }
    writeToFile($filePath, $fileContent);
    return $count;
}

function deleteFolder($folderpath) {
    if (is_dir($folderpath)) {
        $dir_handle = opendir($folderpath);
    }
    if (!$dir_handle) {
        return false;
    }
    while ($file = readdir( $dir_handle )) {
        if ($file != '.' && $file != '..') {
            if (!is_dir($folderpath . '/' . $file)) {
                unlink($folderpath . '/' . $file);
            } else {
                deleteFolder($folderpath . '/' . $file);
            }
        }
    }
    closedir($dir_handle);
    rmdir($folderpath);
    return true;
}

function get_extension($file) {
    if (is_file($file) && preg_match('/^[^\x00]+\.([a-z0-9]+)$/i', $file, $matchResult)) {
        return strtolower($matchResult[1]);
    }
}

////////////////////////////////////////////////
// Start process
////////////////////////////////////////////////

// Get wamp config
$wampConfig = parse_ini_file($wampConfigPath, true);
logInfo("Parse wampmanager.conf", isset($wampConfig['main']['installDir']));

// Get oldPath and newPath
$oldPath = $wampConfig['main']['installDir'];
$newPath = str_replace('\\', '/', getcwd());
logInfo("Paths", !empty($oldPath) && !empty($newPath), array(
    "oldPath"   =>  $oldPath,
    "newPath"   =>  $newPath,
));

// Get php versions list
$phpArr = versionsAppList("bin/php", 3, array("php.exe"));
logInfo("PHP versions", !empty($phpArr), $phpArr, true, false);

// Get apache versions list
$apacheArr = versionsAppList("bin/apache", 6, array("bin/apache.exe", "bin/httpd.exe"));
logInfo("Apache versions", !empty($apacheArr), $apacheArr, true, false);

// Get mysql versions list
$mysqlArr = versionsAppList("bin/mysql", 5, array("bin/mysqld.exe", "bin/mysqld-nt.exe"));
logInfo("MySQL versions", !empty($mysqlArr), $mysqlArr, true, false);

// Get mariadb versions list
$mariadbArr = versionsAppList("bin/mariadb", 7, array("bin/mysqld.exe", "bin/mysqld-nt.exe"));
logInfo("MariaDB versions", !empty($mariadbArr), $mariadbArr, true, false, 'NOT FOUND');

// Stop wampmanager
logInfo("Stop wampmanager", true);
$logsStopWampmanager = execCommand("TASKLIST /FI \"IMAGENAME eq wampmanager.exe\" /FO LIST | find \"wampmanager.exe\"");
if (!empty($logsStopWampmanager)) {
    execCommand("TASKKILL /IM wampmanager.exe /F");
    execCommand("TIMEOUT /T 3 /NOBREAK", false);
} elseif ($verbose == 2) {
    echoListener("\nNot launched.");
}

// Stop wampapache service
logInfo("Stop wampapache service", true);
execCommand("NET STOP wampapache");

// Uninstall wampapache service
logInfo("Uninstall wampapache service", true);
$apachePath = end($apacheArr);
$apachePath = $apachePath['path'] . '\\' . $apachePath['bin'];
$apacheScript = $apachePath . " -k uninstall -n wampapache";
execCommand(array($apacheScript, "SC delete wampapache"));

// Stop wampmysqld service
logInfo("Stop wampmysqld service", true);
execCommand("NET STOP wampmysqld");

// Uninstall wampmysqld service
logInfo("Uninstall wampmysqld service", true);
$mysqlPath = end($mysqlArr);
$mysqlPath = $mysqlPath['path'] . '\\' . $mysqlPath['bin'];
$mysqlScript = $mysqlPath . " --remove wampmysqld";
execCommand(array($mysqlScript, "SC delete wampmysqld"));

// Stop wampmariadb service
logInfo("Stop wampmariadb service", true);
execCommand("NET STOP wampmariadb");

// Uninstall wampmariadb service
if (!empty($mariadbArr)) {
    logInfo("Uninstall wampmariadb service", true);
    $mariadbPath = end($mariadbArr);
    $mariadbPath = $mariadbPath['path'] . '\\' . $mariadbPath['bin'];
    $mariadbScript = $mariadbPath . " --remove wampmariadb";
    execCommand(array($mariadbScript, "SC delete wampmariadb"));
}

// First launch ?
if (!is_dir($rootBackupPath)) {
    $backupsPath = $rootBackupPath . "#original";
}

// Create backups directory
if (!is_dir($backupsPath)) {
    mkdir($backupsPath, null, true);
}
logInfo("Create backups directory", is_dir($backupsPath));

// Get files to scan
$eltToScan = array(
    'alias'     =>  array(''),
    'apache'    =>  array('.ini', '.conf'),
    'mysql'     =>  array('my.ini'),
    'php'       =>  array('.ini'),
);

$pathsToScan = array();
foreach ($eltToScan as $type => $elt) {
    if ($type == 'alias') {
        $pathsToScan[] = $type . ';' . getcwd() . '\\alias';
    } elseif ($type == 'apache') {
        $versionsAppPaths = versionsAppPaths($apacheArr, $type);
        foreach ($versionsAppPaths as $value) {
            $pathsToScan[] = $value;
        }
    } elseif ($type == 'mysql') {
        $versionsAppPaths = versionsAppPaths($mysqlArr, $type);
        foreach ($versionsAppPaths as $value) {
            $pathsToScan[] = $value;
        }
    } elseif ($type == 'mariadb' && !empty($mariadbArr)) {
        $versionsAppPaths = versionsAppPaths($mariadbArr, $type);
        foreach ($versionsAppPaths as $value) {
            $pathsToScan[] = $value;
        }
    } elseif ($type == 'php') {
        $versionsAppPaths = versionsAppPaths($phpArr, $type);
        foreach ($versionsAppPaths as $value) {
            $pathsToScan[] = $value;
        }
    }
}

$filesToScan[] = $wampConfigPath;
$filesToScan[] = $wampTplPath;
$filesToScan[] = $wampIniPath;
foreach ($pathsToScan as $elt) {
    $path = explode(";", $elt);
    $type = $path[0];
    $path = $path[1];
    $foundFiles = foundFiles($path, $eltToScan[$type]);
    foreach ($foundFiles as $value) {
        $filesToScan[] = $value;
    }
}

logInfo("Files to scan", count($filesToScan) > 2, $filesToScan, false);

// Backup files before edit
$backupFiles = array();
foreach ($filesToScan as $file) {
    $infofile = pathinfo($file);
    $backupFileFolder = $backupsPath . str_replace(str_replace('/', '\\', $newPath), '', $infofile['dirname']);
    $backupFile = $backupFileFolder . "\\" . $infofile['basename'];
    if (!is_dir($backupFileFolder)) {
        mkdir($backupFileFolder, null, true);
    }
    if (copy($file, $backupFile)) {
        $backupFiles[] = $backupFile;
    }
}

logInfo("Backup files", count($backupFiles) > 2, $backupFiles, false);

// Replace old path in files
$rpcFiles = array();
foreach ($filesToScan as $file) {
    $echoStr = $file;
    $dots = "";
    for ($i=strlen($echoStr); $i<=90; $i++) $dots .= ".";
    $countRpc = replaceWithNewPath($oldPath, $newPath, $file);
    $rpcFiles[] = $echoStr . " " . $dots . " " . ($countRpc > 0 ? $countRpc . " found" : "none");
}

logInfo("Replace old path in files", count($rpcFiles) > 2, $rpcFiles, false);

// Purge logs
if ($purgeWampLogs) {
    $purgeLogs = array();
    if (is_dir($wampLogsPath)) {
        $dir_handle = opendir($wampLogsPath);
        if ($dir_handle) {
            while ($file = readdir( $dir_handle )) {
                $ext = get_extension($wampLogsPath . $file);
                if ($file != '.' && $file != '..' && $ext == 'log') {
                    $purgeLogs[] = $wampLogsPath . $file;
                    @unlink($wampLogsPath . $file);
                }
            }
            closedir($dir_handle);
        }
    }
    logInfo("Purge logs", true, $purgeLogs, false);
}

// Install wampmysqld service
$mysqlVersion = $wampConfig['mysql']['mysqlVersion'];
$mysqlVersion = str_replace('"', '', $mysqlVersion);
$mysqlPath = $mysqlArr[$mysqlVersion]['path'] . '\\' . $mysqlArr[$mysqlVersion]['bin'];
$mysqlInstallParams = $wampConfig['mysql']['mysqlServiceInstallParams'];
$mysqlInstallParams = str_replace('"', '', $mysqlInstallParams);
$mysqlService = $mysqlPath . " " . $mysqlInstallParams;

logInfo("Install wampmysqld service", true);
execCommand($mysqlService);
execCommand("TIMEOUT /T 1 /NOBREAK", false);
execCommand("NET START wampmysqld");

if (!empty($mariadbArr)) {
    // Install wampmariadb service
    $mariadbVersion = $wampConfig['mariadb']['mariadbVersion'];
    $mariadbVersion = str_replace('"', '', $mariadbVersion);
    $mariadbPath = $mariadbArr[$mariadbVersion]['path'] . '\\' . $mariadbArr[$mariadbVersion]['bin'];
    $mariadbInstallParams = $wampConfig['mariadb']['mariadbServiceInstallParams'];
    $mariadbInstallParams = str_replace('"', '', $mariadbInstallParams);
    $mariadbService = $mariadbPath . " " . $mariadbInstallParams;

    logInfo("Install wampmariadb service", true);
    execCommand($mariadbService);
    execCommand("TIMEOUT /T 1 /NOBREAK", false);
    execCommand("NET START wampmariadb");
}

// Install wampapache service
$apacheVersion = $wampConfig['apache']['apacheVersion'];
$apacheVersion = str_replace('"', '', $apacheVersion);
$apachePath = $apacheArr[$apacheVersion]['path'] . '\\' . $apacheArr[$apacheVersion]['bin'];
$apacheInstallParams = $wampConfig['apache']['apacheServiceInstallParams'];
$apacheInstallParams = str_replace('"', '', $apacheInstallParams);
$apacheService = $apachePath . " " . $apacheInstallParams;

logInfo("Install wampapache service", true);
execCommand($apacheService);
execCommand("TIMEOUT /T 1 /NOBREAK", false);
execCommand("NET START wampapache");

// Delete old backups
if ($maxBackups > 0) {
    $listBackups = array();
    if ($handle = opendir($rootBackupPath)) {
        while (false !== ($file = readdir($handle))) {
            if ($file != "." && $file != ".." && is_dir($rootBackupPath . $file) && is_numeric($file)) {
                $listBackups[] = $rootBackupPath . $file;
            }
        }
    }
    if (!empty($listBackups) && count($listBackups) > $maxBackups) {
        sort($listBackups);
        $toDelete = count($listBackups) - $maxBackups;
        $listBackupsDelete = array();
        for ($i=0; $i<$toDelete; $i++) {
            $listBackupsDelete[] = $listBackups[$i];
            deleteFolder($listBackups[$i]);
        }
        logInfo("Delete old backups", count($listBackupsDelete) > 0, $listBackupsDelete, false);
    }
}

// Now ready to use
echoListener("\n\n");
echoListener("Operation completed successfully!\nWamp is now ready to use!");
echoListener("\n\n");
if (!$autoLaunch) {
    echoListener("Press any key to launch Wamp...");
    `pause`;
}

// Launch wampmanager
echoListener("\n\nLaunch wampmanager\n\n");
`ECHO set args = WScript.Arguments >%wampLauncher%`;
`ECHO num = args.Count >>%wampLauncher%`;
`ECHO. >>%wampLauncher%`;
`ECHO if num = 0 then >>%wampLauncher%`;
`ECHO   WScript.Quit 1 >>%wampLauncher%`;
`ECHO end if >>%wampLauncher%`;
`ECHO. >>%wampLauncher%`;
`ECHO sargs = "" >>%wampLauncher%`;
`ECHO if num ^> 1 then >>%wampLauncher%`;
`ECHO   sargs = " " >>%wampLauncher%`;
`ECHO   for k = 1 to num - 1 >>%wampLauncher%`;
`ECHO       anArg = args.Item(k) >>%wampLauncher%`;
`ECHO       sargs = sargs ^& anArg ^& " " >>%wampLauncher%`;
`ECHO   next >>%wampLauncher%`;
`ECHO end if >>%wampLauncher%`;
`ECHO. >>%wampLauncher%`;
`ECHO Set WshShell = WScript.CreateObject("WScript.Shell") >>%wampLauncher%`;
`ECHO. >>%wampLauncher%`;
`ECHO WshShell.Run """" ^& WScript.Arguments(0) ^& """" ^& sargs, 0, False >>%wampLauncher%`;

`ECHO @ECHO OFF>%wampLauncherScript%`;
`ECHO SETLOCAL EnableDelayedExpansion>>%wampLauncherScript%`;
`ECHO.>>%wampLauncherScript%`;
`ECHO start /w %wampmanagerDaemon%>>%wampLauncherScript%`;
`ECHO.>>%wampLauncherScript%`;
`ECHO NET STOP wampapache>>%wampLauncherScript%`;
`ECHO $apacheScript>>%wampLauncherScript%`;
`ECHO TIMEOUT /T 4 /NOBREAK>>%wampLauncherScript%`;
`ECHO SC delete wampapache>>%wampLauncherScript%`;
`ECHO.>>%wampLauncherScript%`;
`ECHO NET STOP wampmysqld>>%wampLauncherScript%`;
`ECHO $mysqlScript>>%wampLauncherScript%`;
`ECHO TIMEOUT /T 4 /NOBREAK>>%wampLauncherScript%`;
`ECHO SC delete wampmysqld>>%wampLauncherScript%`;
`ECHO.>>%wampLauncherScript%`;
`ECHO ENDLOCAL>>%wampLauncherScript%`;

`wscript.exe %wampLauncher% %wampLauncherScript%`;

if ($enableLogs) file_put_contents($logsPath, "@@@\n@@@ END WAMP-PORTABLE " . date('YmdHis') . "\n@@@\n\n\n\n\n\n\n\n\n\n\n\n", FILE_APPEND);

?>