# companion-satellite-armbian
A build of Companion Satellite that uses Armbian to run on several SBC's

## Using this on your own:
This repo uses Github Actions to build Armbian, and then install Companion Satellite. It then saves the resulting image file as an artifact for you to write to an SD card. To do this process on your own:

 1. Fork this repository.
 2. Navigate to the `Actions` tab on your fork, and select the action `Build armbian + build companion satellite` on the left pane.
 3. Click `Run Workflow`, and select your board and version of Companion Satellite.
 4. Run the workflow
After the workflow completes, navigate to the `Summary` tab of that execution, and your image file will be attached as `Armbian_firmware.zip`
