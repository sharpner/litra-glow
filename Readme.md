# Litra Glow App

Inspired by <https://github.com/kharyam/go-litra-driver> I ported the code to a native swiftui app.


## Introduction

To control [Logitech Litra Glow](https://www.logitech.com/en-us/products/lighting/litra-glow.946-000001.html) I wanted a native macos app that just works, without drivers - so that we can control it from the menu tray without using the physical buttons on the device. 

<img width="243" alt="image" src="https://github.com/user-attachments/assets/f27b9982-be7f-4bad-93cb-2edc679c44a7" />
<img width="290" alt="image" src="https://github.com/user-attachments/assets/e88ea6ee-ceec-4efc-96e7-53430e5b4f93" />

# Features

- Can listen to webcam and auto-activate / deactivate. 
- Manually set brightness and temperature
- Manually activate/inactivate
  
# Build instructions

`xcodebuild -configuration Release`
