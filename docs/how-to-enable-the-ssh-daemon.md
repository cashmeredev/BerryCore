# Table of Contents

1.  [Introduction](#org80abdac)
2.  [Enabling the SSH daemon](#org1ca98dc)
3.  [Generating a SSH key](#org2864fa3)
4.  [Copy your public key to your Blackberry device](#org1c0b975)
5.  [Adding the public key to your Blackberry](#org1296e08)
6.  [Accessing your Blackberry device](#org9d1fc4d)
7.  [Troubleshooting](#orge8c1c73)
    1.  [`id-rsa` could or could not be deprecated](#orgab67504)


<a id="org80abdac"></a>

# Introduction

As the BerryCore environment supports the SSH daemon it's notably to consider to enable it. 

Enabling the SSH daemon allows you features like accessing the QNX environment from any Terminal. This is especially useful when you need to copy paste a lot of commands, you want to develop applications from your workstation or even copy files over SSH with `scp` or `rsync`.


<a id="org1ca98dc"></a>

# Enabling the SSH daemon

If you have never runned the SSH daemon before, you will need to run the following command:

    sshd -Dd

The `-Dd` will run the SSH daemon in verbose mode, so that if any errors occur you may see them.

The command may take some time the first time. So be patient and do not interrupt it.


<a id="org2864fa3"></a>

# Generating a SSH key

Now on your device from where you want to access the Blackberry device you want to generate yourself a SSH key:

    ssh-keygen -t rsa -b 2048 -C "your_name@your_hostname"

I do recommend to annotate the `"your_name@your_hostname"` with recognizable identifiers as it often helps if you have many public keys on your Blackberry device and you want to differiate and edit them for various reasons.


<a id="org1c0b975"></a>

# Copy your public key to your Blackberry device

Once you have generated the key, you need now to copy it over to your Blackberry device.

<div class="NOTE" id="org9ac6387">
<p>
The public key is usually a long chain of random characters. So I would definetly note it down somewhere, where you only have to paste it then on your Blackberry.
</p>

<p>
Two examples are to copy it over through a SD-Card or paste it to <a href="https://pastebin.com">pastebin</a> and then accessing the URL through your browser to copy its content.
</p>

</div>

The public key of your SSH Key should be now located in your home directory under `.ssh/id_rsa.pub`

The content of the public key can be accessed through any text editor.

One convenient way to quickly access it is to run:

    cat .ssh/id_rsa.pub


<a id="org1296e08"></a>

# Adding the public key to your Blackberry

To add the public key open Term49 and then edit the `authorized_keys` file in the `.ssh` directory and save it.

    nano .ssh/authorized_keys


<a id="org9d1fc4d"></a>

# Accessing your Blackberry device

To access the Blackberry device you now just need to run this command:

    ssh App@target.ip:2022

Change the `target.ip` accordingly to the IP-address of your Blackberry device in your local network.


<a id="orge8c1c73"></a>

# Troubleshooting


<a id="orgab67504"></a>

## `id-rsa` could or could not be deprecated

If you were able to SSH then you did it!

If you experience some errors from your laptop/workstation, when trying to access your Blackberry then follow this:

Add the following snippet on your host machine into the `.ssh/config`. You may change the `blackberry` in the first line to whatever name you like! For the sake of the demonstration, I will keep it as is, and take care to adjust the **CHANGE<sub>ME</sub>** to your path and host. I will keep the port on 2022, as it's preconfigured already on the Blackberry devices. If you changed it, then of course adjust it:

    Host blackberry
        Port 2022
        IdentitiesOnly yes
        User App
        HostName CHANGE_ME
        IdentityFile /home/CHANGE_ME/.ssh/CHANGE_ME
        HostKeyAlgorithms +ssh-rsa
        PubkeyAcceptedKeyTypes +ssh-rsa
