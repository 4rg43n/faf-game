# faf-game — Architecture

This is for notes on how the game is programmed

## 1. Player
- player_capsule_controller.gd is the player controller, attached to the CharacterBody3D node. It handles player input and movement/jumping
- player_capsule.tscn is the scene its implemented in

## 2. Third Player Camera
- tps_cam.gd is the camera controller, attached to a Camera3D node. It handles updating the cameras follow position and rotates (camera pitch, player yaw) according to mouse input
- tps_cam.tscn is the scene its implemented in
