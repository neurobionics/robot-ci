<p align="center">
  <img src="/assets/banner.png" width="100%">
</p>

<p align="center">
  <a href="https://www.raspberrypi.com/products/"><img src="https://img.shields.io/badge/Tested%20on-Raspberry%20Pi%20-c51a4a" alt="Raspi"></a>
  <a href="https://www.raspberrypi.com/software/"><img src="https://img.shields.io/badge/supports-raspbian-red" alt="raspbian"></a>
  <a href="https://www.raspberrypi.com/software/"><img src="https://img.shields.io/badge/kernel-64bit-blue" alt="kernel"></a>  
  <a href="https://ubuntu.com/download/raspberry-pi"><img src="https://img.shields.io/badge/supports-ubuntu%20RT-orange" alt="ubuntu"></a>
  <a href="https://github.com/neurobionics/robot-ci/actions/workflows/build.yml"><img src="https://github.com/neurobionics/robot-ci/actions/workflows/build.yml/badge.svg" alt="build"></a>
</p>

**Robot CI**: Effortless building, testing, and deploying customized robot operating systems at scale. This tool lets you **version control your entire robot OS configuration and makes remote development a breeze**.

### 🧠 What It Does
Robot CI builds a custom Raspberry Pi OS image. You download that image, flash it onto an SD card, and boot your RPi. On startup, the Pi automatically connects to WiFi and emails you its IP address. You can then connect to the Pi from your laptop and start developing immediately!

## 🎯 Key Features

This tool solves common challenges in robotics development:

| Feature | Description |
|---------|-------------|
| **Version-Controlled OS** | Track and manage your robot environment in code, enabling reproducible builds with GitHub Actions, and allowing for easy rollbacks and collaboration. |
| **Remote Development** | Provides optimized headless server images with automatic IP notifications via email, facilitating seamless remote development. |
| **Customizable Environment** | Allows for the pre-installation of drivers and custom packages, and the configuration of services and boot sequences to tailor the environment to specific needs. |
| **Network Auto-Config** | Automatically connects to WiFi networks and establishes a fallback access point when no WiFi networks are available, ensuring continuous connectivity. |

## 👥 Ideal for Developers Who
- Want to **streamline the RPi setup process** for students, teams, interns, etc.
- Desire a **version-controlled robot environment**.
- Require **reproducible** development setups.
- Prefer **remote development** over manual RPi configuration.
- **Manage multiple robots** with similar configurations.

## 🛠️ Example Use Cases
- **Research labs** managing multiple test platforms or robots
- Robotics companies **deploying a fleet of robots**
- Educational institutions maintaining **student robots for course projects**
- Development teams needing **consistent robot environments** across multiple robots

> [!NOTE]
> Currently tested on Raspberry Pi 4 and 5. May not be compatible with Raspberry Pi Zero.

## 🚀 Getting Started
Please follow the steps below to get started with creating your own customized OS, deploying it to your Raspberry Pi, and connecting to it from your workstation.

<details>
<summary>1. Prepare Your Repository</summary>
You have two options to use this repository:

1. **Fork the Repository** (Recommended)
   - Click the "Fork" button at the top of this repository
   - Maintains connection to the original repository
   - Useful if you want to receive future updates and contribute back

2. **Use as a Template**
   - Click the green "Use this template" button at the top of this repository
   - This creates a new repository with a clean history
   - Best for starting your own customized version

Choose the option that best suits your needs:
- Choose **Fork** if you want to stay updated with the original repository's changes
- Choose **Template** if you want a clean slate for your own project
</details>

<details>
<summary>2. Configure Secrets</summary>

The next step is to create the secrets that securely handle sensitive information. These secrets will be added to the image configuration when running the workflow. To add secrets, navigate to the Settings tab, select **Secrets and variables**, select **Actions**, and select click “**New repository secret**”, then enter the name and value.

⚠️**IMPORTANT** : 
  - Variable names must match exactly (e.g., EMAIL_ADDRESS, not email_address)
  - Type values exactly as shown. Extra spaces (especially at the start or end) can break the build.
  - Common mistake: EMAIL_ADDRESS = johndoe@gmail.com␣  ← Invisible trailing space

Required secrets:

| Secret | Purpose |
|--------|---------|
| `EMAIL_ADDRESS` | Email address(es) to send notifications to; separate multiple addresses with commas **("," and not ", ")** |
| `ENTNETWORK_SSID` | Enterprise (e.g. university) wifi network name. Use your normal WiFi name if not on enterprise|
| `ENTNETWORK_IDENTITY` | Network username. For home WiFi, this is usually the same as your WiFi name (SSID).|
| `ENTNETWORK_PASSWORD` | Network password |
| `ENTNETWORK_PRIORITY` | A number that sets connection priority (higher = preferred). Use 10 unless you have multiple networks. |
| `WIFI_COUNTRY_CODE` | WiFi country code, defaults to US if not set |

Optional secrets:

| Secret | Purpose |
|--------|---------|
| `TIMEZONE` | Timezone for the device, defaults to America/New_York if not set |
| `KEYBOARD_LAYOUT` | Keyboard layout, defaults to us if not set |
| `KEYBOARD_MODEL` | Keyboard model, defaults to pc105 if not set |
| `SMTP_SERVER` | SMTP server for email notifications, defaults to `smtp.gmail.com` |
| `SMTP_USERNAME` | Username for the email account that will send notifications, defaults to opensourceleg@gmail.com|
| `SMTP_PASSWORD` | Password for the email account that will send notifications, default to our app password |

#### Optional: Configuring SMTP

Skip this unless you want to use your own email account.

If you prefer to use your own gmail account to send email notification with the IP address of your robot instead of using the default opensourceleg@gmail.com account, you can configure your own Gmail account to work with SMTP (Simple Mail Transfer Protocol). This is easiest with a personal Gmail account, because certain organization or university accounts may have restrictions on creating an app password (a requirement for SMTP configuration).

> *Note: For non-Gmail accounts, more guidelines on SMTP configuration can be found [here](https://support.google.com/a/answer/176600?hl=en).*

1. Go to your [Google Account Settings](https://myaccount.google.com/security).
2. Enable [2-Step Verification](https://support.google.com/accounts/answer/185839?hl=en&co=GENIE.Platform%3DDesktop) if it's not already turned on.
3. Generate an App Password:
   - In your Google Account Settings, go to `Security`, and click `App Passwords`. You can also navigate to your App Passwords by clicking [here](https://myaccount.google.com/apppasswords).
   - Select **Mail** as the app.
   - Choose any name for the device.
   - Click **Generate**.
   - Copy the 16-character code (including the spaces).
4. Add the following values to your secret variables:
   - `SMTP_PASSWORD`: the App Password you just generated
   - `SMTP_USERNAME`: your full Gmail address (e.g. `[your-username]@gmail.com`)
   - `SMTP_SERVER`: `smtp.gmail.com`
</details>

<details>
<summary>3. Build Your Image</summary>
  
In this step, you will generate a custom OS image for your Raspberry Pi.

1. Navigate to the **Actions** tab, enable workflows by clicking on the green button, and then select **Build** from the left hand side
2. Click the **Run Workflow** button and select your build options:
   - Choose between `raspbian` (default) or `ubuntu`
      > *Note: ubuntu is NOT compatible with Raspberry Pi 4*
   - Provide your `admin password` and `user password`. Users are created based on the `EMAIL_ADDRESS` secret, for example, if `EMAIL_ADDRESS` secret is set to "user1@example.com,user2@example.com", two users will be created: "user1" and "user2" and the first user will be considered the admin and all other users will be considered regular users.
   - Configure WiFi settings for additional home networks
   - **Be sure to record this information--you will need it (e.g. access point login info)**
   - ☕ Grab a cup of coffee. This process takes about ten minutes
3. When the workflow finishes, click the completed Build run in the Actions tab. Scroll down to Artifacts and download the .zip file.
4. If the build fails, check your secrets for typos or missing values.
</details>

<details>
<summary>4. Deploy & Connect</summary>

1. Download and flash the image to an SD card using [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
   - Select your RPi hardware version number in the Raspberry Pi Imager
   - Choose the Operating System, scroll to the last option, and select **Use custom**
   - Choose the custom image you recently downloaded from your image build
   - Select the SD card as the storage medium
   - When prompted “Apply OS customization options?”, select **No** (Robot CI already configures everything).
2. Boot your RPi. Use a proper power supply (15–25W). Do not power the Pi from a laptop USB port. 

> [!NOTE]
> **First Boot**: On first boot, the Pi configures itself (this takes ~5 minutes). Do not unplug the Pi during this process. Then reboot once to activate networking and email notifications. 
3. Connect via: 
   - Enterprise or Home network: Check your email, you should have received an IP address from the RPI.
   If you haven't received an email:
   - Fallback Access-Point (AP) mode: Connect to RPi's network (IP: 10.0.0.200)

If you encounter any issues, please follow the debugging steps below. 
</details>

<details>
<summary>5. Connect from Workstation to your Raspberry Pi</summary>
1. Download VS Code for your local machine. You can select the link below for your respective operating system and follow the tutorial: [macOS](https://code.visualstudio.com/), [Linux](https://code.visualstudio.com/), [Windows](https://code.visualstudio.com/). 

2. Once VS Code is downloaded, open the application and navigate to the Extensions tab on the upper left side of the window. Click the Extensions icon on the sidebar (or press <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>X</kbd>). Once in the Extensions tab, search for “Remote Development” and install the ssh extension published by Microsoft.

3. Connect to Raspberry Pi via SSH in VS Code
   - Press <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>P</kbd> (Mac) or <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>P</kbd> (Windows) to open Command Palette.
   - Type and select <kbd>Remote-SSH: Connect to Host...</kbd>
   - Enter the SSH connection string: <kbd>ssh &lt;user&gt;@&lt;IP Address&gt;</kbd>, where <kbd>IP</kbd> is the IP address of the raspberry pi you get via email notification or the local internet. <kbd>user</kbd> is the name previously configured when adding your email address to send notifications to: <kbd>[user]@[domain].com</kbd>
   - Use the password you set during the build step when prompted. If you are logging in as the first user (first email), use the admin password.
   - After connecting, VS Code will prompt you to open a folder from your Pi. You can now edit files, run terminals, and develop just like local, but on your Raspberry Pi!
4. If connection fails, double-check:
   - your username (from email)
   - your IP address
   - that your Pi is powered on
  </details>


## 🐞 Debugging

If you haven't received an IP address email within **10 minutes** of powering on your Raspberry Pi, follow these troubleshooting steps:

<details>
<summary>1. Check for Access Point Broadcast</summary>

- Your RPi should create an access point if it couldn't connect to known networks or send the IP email

- Look for the access point SSID you configured during setup in your available networks

- If you can connect to this access point, SSH into the RPi:

  ```
  ssh <username>@10.0.0.200
  ```

- If no access point is visible:
  - Connect a monitor and keyboard directly to your Raspberry Pi
  - Continue with the following diagnostic steps
</details>

<details>
<summary>2. Verify Network Connection</summary>

Check your network interfaces with:

```
ifconfig
```

Look for:

- `eth#` for Ethernet connections
- `wlan#` for Wi-Fi connections

Note: `#` indicates the interface number (typically `wlan0` for the primary Wi-Fi interface)

A successful connection shows an IP address next to `wlan0`. If missing, your network configuration needs attention.
</details>

<details>
<summary>3. Inspect Environment Variables</summary>

Environment variables control network, email, and SMTP server configuration:

```
cat /etc/environment
```

To modify any incorrect values:

```
sudo nano /etc/environment
```

Save changes with `Ctrl + O`, exit with `Ctrl + X`, then reboot:

```
sudo reboot
```

</details>

<details>
<summary>4. Examine Network Configurations</summary>

Network connection files are stored in:

```
cd /etc/NetworkManager/system-connections
```

View a specific network configuration:

```
sudo cat <network_SSID>.nmconnection
```

For enterprise networks, verify:
- `ssid` matches your target network
- `identity` contains the correct username
- `password` contains the correct credentials

For home networks, verify:
- `ssid` matches your home network name
- `psk` contains the correct password

To edit a configuration:

```
sudo nano <network_SSID>.nmconnection
```

After making changes, reboot your Raspberry Pi:

```
sudo reboot
```

If problems persist, please [open an issue](https://github.com/neurobionics/robot-ci/issues). Note that networking issues can be complex and specific to your environment, but we'll do our best to assist.
</details>

## 🌐 Network Behavior

Network management is streamlined by [Robonet](https://github.com/neurobionics/robonet), our custom CLI tool designed to simplify network configuration and management.

Here's a brief overview of its functionality:

- **Primary Connection**: Automatically connects to prioritized WiFi networks.
- **Fallback Mode**: Establishes an access point with a static IP of `10.0.0.200` when no preferred networks are available. Keeping 
- **IP Notification**: Sends an email notification with the device's IP address upon successful connection.

Read more about Robonet [here](https://github.com/neurobionics/robonet).

## Additional Configuration

1. Edit the `motd` file to customize the message of the day. This is displayed when the user logs in.
2. Edit the `packages.Pifile` file to install additional packages, services, and boot sequences.
3. Edit the `ssh.Pifile` file to configure SSH access for users.
4. Edit the `source.Pifile` file to build from a custom source that is not a default raspbian or ubuntu image.

## 🤝 Contributing

All contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## 📜 License

This project is licensed under [Apache 2.0](LICENSE).

## 🐛 Issues

Found a bug or have a suggestion? Please [open an issue](https://github.com/neurobionics/robot-ci/issues).
