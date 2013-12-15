# Wamp Portable

A DOS Batch script to make [WampServer](http://www.wampserver.com/) portable.

Tested on :
* Windows XP Pro SP2 32-bits
* Windows XP Pro SP3 32-bits
* Windows Vista Pro SP1 64-bits
* Windows 7 Pro SP1 64-bits
* Windows 8 Pro 64-bits
* Windows 8.1 Pro 64-bits

## Requirements

* [WampServer](http://www.wampserver.com/) minimal version 2.0 and 32-bit.
* PHP minimal version 5.2.x
* [WSH (Windows Script Host)](http://support.microsoft.com/kb/232211) : Open a command prompt and type ``wscript`` to check.
* Be [Admin user](http://windows.microsoft.com/en-US/windows7/How-do-I-log-on-as-an-administrator).
* Add ``%WAMPPORTABLE%`` string to the [system environment variable](http://support.microsoft.com/kb/310519/en) ``PATH``.

## Installation

Before running the script, you can edit the configuration file ``wamp-portable.ini``.

* **timezone** - The default timezone used by all date/time functions. Default : ``Europe/Paris``
* **enableLogs** - Enable wamp-portable log file. Generate ``wamp-portable.log`` file. Default : ``true``
* **autoLaunch** - Automatically closes the wamp-portable window. Default : ``false``
* **purgeWampLogs** - Purge logs from Wamp logs folder. Default ``false``;
* **maxBackups** - Maximum number of backups to keep (0 = unlimited). Default : ``10``
* **verbose** - Control the debug output (0=simple, 1=report, 2=debug). Default ``0``

Next,

* Download and install [WampServer](http://www.wampserver.com/) 32-bit >= 2.0.
* Copy wamp folder where ever you want.
* Remove WampServer from [Programs and Features](http://windows.microsoft.com/en-US/windows7/Uninstall-or-change-a-program).
* Delete ``unins000.dat`` and ``unins000.exe`` from the copied folder.
* Put the ``wamp-portable.bat`` and ``wamp-portable.ini`` files in the same directory as ``wampmanager.exe``.

## Usage

* Just launch ``wamp-portable.bat`` to start WampServer (do not launch wampmanager.exe).
* A backup folder is created each time you launch wamp-portable in the ``backups`` directory. This folder contains all files edited by the wamp-portable script.

## Reporting an issue

Before [reporting an issue](https://github.com/crazy-max/wamp-portable/issues), please :
* Tell me what is your operating system and platform (eg. Windows 7 64-bits).
* Tell me your WampServer version (eg. 2.2e).
* Change these variables in the ``wamp-portable.ini`` file ``enableLogs = true`` ; ``verbose = 2`` and paste the content of the ``wamp-portable.log`` file.

## License

LGPL. See ``LICENSE`` for more details.

## More infos

http://www.crazyws.fr/dev/applis-et-scripts/wamportable-mettre-wampserver-sur-cle-usb-G5980.html
