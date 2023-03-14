## How to add another PHP version

#### Table of Contents  
[Step 1: Downloading PHP binaries](#downloading-php-binaries)  
[Step 2: Adding new PHP version to Laragon](#adding-php-version-to-laragon)  
[Step 3: Switching to the new PHP version](#switching-php-version)  
[Step 4: Updating PHP Environment Variable Path](#updating-environment-variable-path)  

<a name="downloading-php-binaries"/>

### Step 1: Downloading PHP binaries

Visit https://windows.php.net/download/ for the latest versions of PHP or go to https://windows.php.net/downloads/releases/archives/ for older versions of PHP.

Download the **Thread Safe** version of the PHP version you need.

For example: [php-8.2.3-Win32-vs16-x64.zip](https://windows.php.net/downloads/releases/php-8.2.3-Win32-vs16-x64.zip)


<a name="adding-php-version-to-laragon"/>

### Step 2: Adding new PHP version to Laragon

Go to the `/bin/php` folder inside your Laragon installation and extract the `php-8.2.3-Win32-vs16-x64.zip` you've just downloaded inside it's own folder.

![image](https://user-images.githubusercontent.com/25492573/224986199-cf6340b3-a456-4760-a11d-5552cdff9ed0.png)

_Example of how it might look_

<a name="switching-php-version"/>

### Step 3: Switching to the new PHP version
To switch your PHP version in Laragon is really simple.
All you have to do is go to:
 _Laragon > Menu > PHP > Version [current verison] > Select your desired version from this list_

![image](https://user-images.githubusercontent.com/25492573/224986903-1d57e8ae-4cc3-4cae-a242-f51519d318b9.png)


<a name="updating-environment-variable-path"/>

### Step 4: Updating PHP Environment Variable Path
_You have to do this step every time you switch between PHP versions._
If you use PHP through the CLI (for example `php artisan serve` with Laravel) it's important that you also change the PATH in your environment variables.

Laragon allows you to quickly do this by going to:

![image](https://user-images.githubusercontent.com/25492573/224987455-fb6c998e-915b-4f1f-a102-da62a7aa9a3c.png)

 _Laragon > Menu > Tools > Path > Add Laragon to Path_

This will automatically add everything from your Laragon installation to the PATH

![image](https://user-images.githubusercontent.com/25492573/224990138-26b717cd-98aa-48c0-adc0-1ddd3ce8be5c.png)

Make sure that you restart your terminal for these changes to take place. Run the command `php -v` to make sure you're on the correct version.