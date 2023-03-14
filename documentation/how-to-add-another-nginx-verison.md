## How to add another Nginx version

#### Table of Contents  
[Step 1: Downloading Nginx](#downloading-nginx)  
[Step 2: Adding new Nginx version to Laragon](#adding-nginx-version-to-laragon)  
[Step 3: Switching to the new Nginx version](#switching-nginx-version)  

<a name="downloading-nginx"/>

### Step 1: Downloading Nginx

Visit https://nginx.org/en/download.html for the latest version of Nginx.

Download your desired version of Nginx, for example the **Mainline version**.

In this case we'll download `nginx/Windows-1.23.3`

<a name="adding-nginx-version-to-laragon"/>

### Step 2: Adding new Nginx version to Laragon

Go to the `/bin/nginx` folder inside your Laragon installation and extract the `nginx-1.23.3.zip` you've just downloaded inside this folder.

![image](https://user-images.githubusercontent.com/25492573/225001814-484d61e3-c30c-4630-89cc-6dbf38bd44ca.png)

_Example of how it might look_

<a name="switching-nginx-version"/>

### Step 3: Switching to the new Nginx version
To switch your Nginx version in Laragon is really simple.

First you have to make sure you're actually using the Nginx service. To do this, go to your `Preferences` inside Laragon and go to the `Services & Ports` tab.
Uncheck the Apache checkbox and check the Nginx checkbox. I personally switch my port from `8080` to `80` and enable SSL with port `443`.

After this is done, Nginx will be visible in your dropdown.

All you have to do is go to:
 _Laragon > Menu > Nginx > Version [current verison] > Select your desired version from this list_

![image](https://user-images.githubusercontent.com/25492573/225002962-abf692fc-729b-404b-a643-ba28fafd90f6.png)